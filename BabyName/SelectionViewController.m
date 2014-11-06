//
//  SelectionViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SelectionViewController.h"

#import "Constants.h"


typedef NS_ENUM(NSUInteger, PanningDirection) {
    kPanningDirectionNone = 0,
    kPanningDirectionRight,
    kPanningDirectionLeft
};

typedef NS_ENUM(NSUInteger, PanningState) {
    kPanningStateIdle = 0,
    kPanningStateAccept,
    kPanningStateReject
};


static const CGFloat kPanningVelocityThreshold = 100.0;


@interface SelectionViewController () <UIDynamicAnimatorDelegate>

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *surnameLabel;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) CGPoint panningOrigin;
@property (nonatomic) PanningState panningState;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic, strong) UIGravityBehavior *gravityBehavior;
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@end


@implementation SelectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // It's not possible to make the view transparent in Storyboard because of the use of white labels.
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([self.dataSource shouldReloadName]) {
        [self configureNameLabel];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.surnameLabel.alpha = ([userDefaults boolForKey:kSettingsShowSurnameKey]) ? 1.0 : 0.0;
    self.surnameLabel.text = [userDefaults stringForKey:kSettingsSurnameKey];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.panningEnabled = YES;
    self.panningOrigin = self.nameLabel.center;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.nameLabel
                                                 snapToPoint:self.panningOrigin];
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.nameLabel]];
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.nameLabel]];
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.nameLabel]];
    
    self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.nameLabel
                                                        attachedToAnchor:self.panningOrigin];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.animator = nil;
    self.snapBehavior = nil;
    self.gravityBehavior = nil;
    self.collisionBehavior = nil;
    self.itemBehavior = nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Gesture handlers

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    // Refresh name when shaking.
    if (motion == UIEventSubtypeMotionShake) {
        [self configureNameLabel];
    }
}

- (IBAction)panName:(UIPanGestureRecognizer *)recognizer
{
    static PanningDirection panningDirection = kPanningDirectionNone;

    // Discard gesture recognizer if panning is disabled.
    if (!self.panningEnabled) {
        recognizer.enabled = NO;
    }
    else {
        recognizer.enabled = YES;
    }

    // Handle panning.
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        panningDirection = [self directionForGesture:recognizer];
        if (panningDirection == kPanningDirectionNone) {
            return;
        }
        
        [self.delegate selectionViewDidBeginPanning];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // TODO: simplify this method.
        self.nameLabel.center = [self calculatedCenterForGesture:recognizer
                                            withPanningDirection:panningDirection];

        [recognizer setTranslation:CGPointZero
                            inView:self.view];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        self.panningState = [self endStateForGesture:recognizer
                                withPanningDirection:panningDirection];

        switch (self.panningState) {
            case kPanningStateAccept:
                [self.itemBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.view].x, 0.0)
                                             forItem:self.nameLabel];

                self.gravityBehavior.gravityDirection = CGVectorMake(1.0, 0.0);

                [self.collisionBehavior removeAllBoundaries];
                [self.collisionBehavior addBoundaryWithIdentifier:@"AcceptBoundary"
                                                        fromPoint:CGPointMake(CGRectGetWidth(self.view.frame) * 2.0, CGRectGetMinY(self.view.frame))
                                                          toPoint:CGPointMake(CGRectGetWidth(self.view.frame) * 2.0, CGRectGetMaxY(self.view.frame))];

                [self.animator addBehavior:self.itemBehavior];
                [self.animator addBehavior:self.gravityBehavior];
                [self.animator addBehavior:self.collisionBehavior];
                break;

            case kPanningStateReject:
                [self.itemBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.view].x, 0.0)
                                             forItem:self.nameLabel];

                self.gravityBehavior.gravityDirection = CGVectorMake(-1.0, 0.0);

                [self.collisionBehavior removeAllBoundaries];
                [self.collisionBehavior addBoundaryWithIdentifier:@"RejectBoundary"
                                                        fromPoint:CGPointMake(-CGRectGetWidth(self.view.frame), CGRectGetMinY(self.view.frame))
                                                          toPoint:CGPointMake(-CGRectGetWidth(self.view.frame), CGRectGetMaxY(self.view.frame))];

                [self.animator addBehavior:self.itemBehavior];
                [self.animator addBehavior:self.gravityBehavior];
                [self.animator addBehavior:self.collisionBehavior];
                break;

            default:
            case kPanningStateIdle:
                self.snapBehavior.damping = 1.0;
                [self.animator addBehavior:self.snapBehavior];
                
                self.itemBehavior.allowsRotation = NO;
                [self.animator addBehavior:self.itemBehavior];
                break;
        }
        
        [self performEndingAction];

        // Disable panning until animation is finished.
        self.panningEnabled = NO;
    }
}

#pragma mark - Private methods

- (void)configureNameLabel
{
    self.nameLabel.text = [self.dataSource randomName];
    self.nameLabel.center = self.panningOrigin;
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.nameLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         self.panningState = kPanningStateIdle;
                     }];
}

- (void)performEndingAction
{
    switch (self.panningState) {
        case kPanningStateAccept:
            [self.delegate acceptName];
            break;
            
        case kPanningStateReject:
            [self.delegate rejectName];
            break;
            
        default:
        case kPanningStateIdle:
            break;
    }
}

- (PanningDirection)directionForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
    
    if (fabs(velocity.x) >= fabs(velocity.y)) {
        if (velocity.x > 0.0) {
            return kPanningDirectionRight;
        }
        else {
            return kPanningDirectionLeft;
        }
    }
    else {
        return kPanningDirectionNone;
    }
}

- (CGPoint)calculatedCenterForGesture:(UIPanGestureRecognizer *)recognizer withPanningDirection:(PanningDirection)direction
{
    CGPoint center = self.nameLabel.center;
    CGPoint translation = [recognizer translationInView:self.view];
    
    switch (direction) {
        case kPanningDirectionLeft:
        case kPanningDirectionRight:
            return CGPointMake(center.x + translation.x,
                               center.y);
            break;
            
        default:
        case kPanningDirectionNone:
            return center;
            break;
    }
}

- (PanningState)endStateForGesture:(UIPanGestureRecognizer *)recognizer withPanningDirection:(PanningDirection)direction
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint location = [recognizer locationInView:self.view];
    
    switch (direction) {
        case kPanningDirectionRight:
            if (velocity.x >= kPanningVelocityThreshold) {
                return kPanningStateAccept;
            }
            else if (velocity.x <= -kPanningVelocityThreshold) {
                return kPanningStateReject;
            }
            else {
                if (location.x >= CGRectGetWidth(self.view.frame) * 0.90) {
                    return kPanningStateAccept;
                }
                else if (location.x <= CGRectGetWidth(self.view.frame) * 0.10) {
                    return kPanningStateReject;
                }
                else {
                    return kPanningStateIdle;
                }
            }
            break;
            
        case kPanningDirectionLeft:
            if (velocity.x >= kPanningVelocityThreshold) {
                return kPanningStateAccept;
            }
            else if (velocity.x <= -kPanningVelocityThreshold) {
                return kPanningStateReject;
            }
            else {
                if (location.x >= CGRectGetWidth(self.view.frame) * 0.90) {
                    return kPanningStateAccept;
                }
                else if (location.x <= CGRectGetWidth(self.view.frame) * 0.10) {
                    return kPanningStateReject;
                }
                else {
                    return kPanningStateIdle;
                }
            }
            break;
            
        default:
        case kPanningDirectionNone:
            return kPanningStateIdle;
            break;
    }
}

#pragma mark - Dynamics animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    [self.animator removeAllBehaviors];

    // Enable panning when animation is finished.
    self.panningEnabled = YES;
    
    [self.delegate selectionViewDidEndPanning];

    if (self.panningState == kPanningStateIdle) {
        // Adjust misalignment to center.
        self.nameLabel.center = self.panningOrigin;
    }
    else {
        [self configureNameLabel];
    }
}

@end
