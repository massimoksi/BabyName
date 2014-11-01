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
    kPanningDirectionUp,
    kPanningDirectionRight,
    kPanningDirectionDown,
    kPanningDirectionLeft
};

typedef NS_ENUM(NSUInteger, PanningState) {
    kPanningStateIdle = 0,
    kPanningStateAccept,
    kPanningStateReject
};


static const CGFloat kNameLabelPadding = 10.0; // TODO: replace with a calculation.
static const CGFloat kPanningVelocityThreshold = 100.0;
static const CGFloat kPanningTranslationThreshold = 80.0;


@interface SelectionViewController () <UIDynamicAnimatorDelegate>

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *surnameLabel;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) CGPoint panningOrigin;
@property (nonatomic) PanningState panningState;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIGravityBehavior *gravityBehavior;
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@end


@implementation SelectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // It's not possible to make the view transparent in Storyboard due to white labels.
    self.view.backgroundColor = [UIColor clearColor];
    
    self.panningEnabled = YES;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.nameLabel]];
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.nameLabel]];
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.nameLabel]];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.panningOrigin = self.nameLabel.center;
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
        
        [self.delegate selectionViewDidBeginPanning];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.nameLabel.center = [self calculatedCenterForGesture:recognizer
                                            withPanningDirection:panningDirection];

        [recognizer setTranslation:CGPointZero
                            inView:self.view];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        self.panningState = [self endStateForGesture:recognizer
                                withPanningDirection:panningDirection];
        
        CGPoint linearVelocity;
        switch (self.panningState) {
            default:
            case kPanningStateIdle:
                linearVelocity = CGPointZero;
                break;
                
            case kPanningStateAccept:
            case kPanningStateReject:
                linearVelocity = CGPointMake([recognizer velocityInView:self.view].x, 0.0);
                break;
        }
        [self.itemBehavior addLinearVelocity:linearVelocity
                                     forItem:self.nameLabel];
        [self.animator addBehavior:self.itemBehavior];
        
        self.gravityBehavior.gravityDirection = [self gravityDirectionForPanningDirection:panningDirection];
        [self.animator addBehavior:self.gravityBehavior];

        [self.collisionBehavior setTranslatesReferenceBoundsIntoBoundaryWithInsets:[self edgeInsetsForPanningDirection:panningDirection]];
        [self.animator addBehavior:self.collisionBehavior];

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
        case kPanningDirectionUp:
        case kPanningDirectionNone:
        case kPanningDirectionDown:
            return center;
            break;
    }
}

- (PanningState)endStateForGesture:(UIPanGestureRecognizer *)recognizer withPanningDirection:(PanningDirection)direction
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint newCenter = [self calculatedCenterForGesture:recognizer
                                    withPanningDirection:direction];
    
    switch (direction) {
        case kPanningDirectionRight:
            if (velocity.x >= kPanningVelocityThreshold) {
                return kPanningStateAccept;
            }
            else if (velocity.x <= -kPanningVelocityThreshold) {
                return kPanningStateReject;
            }
            else {
                if (newCenter.x >= self.view.center.x + kPanningTranslationThreshold) {
                    return kPanningStateAccept;
                }
                else if (newCenter.x <= self.view.center.x - kPanningTranslationThreshold) {
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
                if (newCenter.x >= self.panningOrigin.x + kPanningTranslationThreshold) {
                    return kPanningStateAccept;
                }
                else if (newCenter.x <= self.panningOrigin.x - kPanningTranslationThreshold) {
                    return kPanningStateReject;
                }
                else {
                    return kPanningStateIdle;
                }
            }
            break;
            
        default:
        case kPanningDirectionNone:
        case kPanningDirectionUp:
        case kPanningDirectionDown:
            return kPanningStateIdle;
            break;
    }
}

- (CGVector)gravityDirectionForPanningDirection:(PanningDirection)direction
{
    switch (self.panningState) {
        case kPanningStateIdle:
            if (direction == kPanningDirectionLeft) {
                return CGVectorMake(1.0, 0.0);
            }
            else if (direction == kPanningDirectionUp) {
                return CGVectorMake(0.0, 1.0);
            }
            else if (direction == kPanningDirectionRight) {
                return CGVectorMake(-1.0, 0.0);
            }
            else {
                return CGVectorMake(0.0, 0.0);
            }
            break;
            
        case kPanningStateAccept:
            return CGVectorMake(1.0, 0.0);
            break;
            
        case kPanningStateReject:
            return CGVectorMake(-1.0, 0.0);
            break;
            
        default:
            return CGVectorMake(1.0, 0.0);
            break;
    }
}

- (UIEdgeInsets)edgeInsetsForPanningDirection:(PanningDirection)direction
{
    switch (self.panningState) {
        case kPanningStateIdle:
            if (direction == kPanningDirectionLeft) {
                return UIEdgeInsetsMake(0.0,
                                        -self.nameLabel.frame.size.width,
                                        0.0,
                                        kNameLabelPadding);
            }
            else if (direction == kPanningDirectionUp) {
                return UIEdgeInsetsMake(-self.nameLabel.frame.size.height,
                                        0.0,
                                        (self.view.frame.size.height - self.nameLabel.frame.size.height) / 2,
                                        0.0);
            }
            else if (direction == kPanningDirectionRight) {
                return UIEdgeInsetsMake(0.0,
                                        kNameLabelPadding,
                                        0.0,
                                        -self.nameLabel.frame.size.width);
            }
            else {
                return UIEdgeInsetsZero;
            }
            break;
            
        case kPanningStateAccept:
            return UIEdgeInsetsMake(0.0,
                                    0.0,
                                    0.0,
                                    -self.nameLabel.frame.size.width);
            break;
            
        case kPanningStateReject:
            return UIEdgeInsetsMake(0.0,
                                    -self.nameLabel.frame.size.width,
                                    0.0,
                                    0.0);
            break;
            
        default:
            return UIEdgeInsetsZero;
            break;
    }
}

#pragma mark - Dynamics animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
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
    
    [self.animator removeAllBehaviors];
}

@end
