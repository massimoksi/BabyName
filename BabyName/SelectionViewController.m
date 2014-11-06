//
//  SelectionViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SelectionViewController.h"

#import "Constants.h"


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
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Gesture must be disarded if:
        //  * Panning vertically (vy > vx).
        //  * Panning is disabled (a previous pan is still animating).
        CGPoint velocity = [recognizer velocityInView:self.view];
        if ((fabs(velocity.y) > fabs(velocity.x)) || !self.panningEnabled) {
            // Discard gesture.
            return;
        }

        [self.delegate selectionViewDidBeginPanning];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint origin = self.nameLabel.center;
        self.nameLabel.center = CGPointMake(origin.x + [recognizer translationInView:self.view].x, origin.y);

        [recognizer setTranslation:CGPointZero
                            inView:self.view];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        self.panningState = [self endStateForGesture:recognizer];

        switch (self.panningState) {
            case kPanningStateAccept:
                [self.itemBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.view].x, 0.0)
                                             forItem:self.nameLabel];
                [self.animator addBehavior:self.itemBehavior];

                self.gravityBehavior.gravityDirection = CGVectorMake(1.0, 0.0);
                [self.animator addBehavior:self.gravityBehavior];

                [self.collisionBehavior removeAllBoundaries];
                [self.collisionBehavior addBoundaryWithIdentifier:@"AcceptBoundary"
                                                        fromPoint:CGPointMake(CGRectGetWidth(self.view.frame) * 2.0, CGRectGetMinY(self.view.frame))
                                                          toPoint:CGPointMake(CGRectGetWidth(self.view.frame) * 2.0, CGRectGetMaxY(self.view.frame))];
                [self.animator addBehavior:self.collisionBehavior];

                [self.delegate acceptName];
                break;

            case kPanningStateReject:
                [self.itemBehavior addLinearVelocity:CGPointMake([recognizer velocityInView:self.view].x, 0.0)
                                             forItem:self.nameLabel];
                [self.animator addBehavior:self.itemBehavior];

                self.gravityBehavior.gravityDirection = CGVectorMake(-1.0, 0.0);
                [self.animator addBehavior:self.gravityBehavior];

                [self.collisionBehavior removeAllBoundaries];
                [self.collisionBehavior addBoundaryWithIdentifier:@"RejectBoundary"
                                                        fromPoint:CGPointMake(-CGRectGetWidth(self.view.frame), CGRectGetMinY(self.view.frame))
                                                          toPoint:CGPointMake(-CGRectGetWidth(self.view.frame), CGRectGetMaxY(self.view.frame))];
                [self.animator addBehavior:self.collisionBehavior];

                [self.delegate rejectName];
                break;

            default:
            case kPanningStateIdle:
                self.snapBehavior.damping = 1.0;
                [self.animator addBehavior:self.snapBehavior];
                
                self.itemBehavior.allowsRotation = NO;
                [self.animator addBehavior:self.itemBehavior];
                break;
        }

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

- (PanningState)endStateForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint location = [recognizer locationInView:self.view];
    
    if (velocity.x >= kPanningVelocityThreshold) {
        return kPanningStateAccept;
    }
    else if (velocity.x <= -kPanningVelocityThreshold) {
        return kPanningStateReject;
    }
    else {
        if (location.x >= CGRectGetWidth(self.view.frame) * 0.9) {
            return kPanningStateAccept;
        }
        else if (location.x <= CGRectGetWidth(self.view.frame) * 0.1) {
            return kPanningStateReject;
        }
        else {
            return kPanningStateIdle;
        }
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
        // TODO: check if adjustment is necessary also with snap behavior.
        self.nameLabel.center = self.panningOrigin;
    }
    else {
        [self configureNameLabel];
    }
}

@end
