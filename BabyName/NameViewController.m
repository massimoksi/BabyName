//
//  NameViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "NameViewController.h"


typedef NS_ENUM(NSUInteger, BBNPanDirection) {
    BBNPanDirectionNone = 0,
    BBNPanDirectionUp,
    BBNPanDirectionRight,
    BBNPanDirectionDown,
    BBNPanDirectionLeft
};

typedef NS_ENUM(NSUInteger, BBNPanState) {
    BBNPanStateIdle = 0,
    BBNPanStateAccept,
    BBNPanStateReject,
    BBNPanStateMaybe
};


// TODO: adapt constants to iPad.
static const CGFloat BBNNameLabelPadding = 10.0;
static const CGFloat BBNPanVelocityThreshold = 100.0;
static const CGFloat BBNPanTranslationThreshold = 80.0;


@interface NameViewController () <UIDynamicAnimatorDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) BBNPanState panState;

@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;

@end


@implementation NameViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.panningEnabled = YES;
    self.panState = BBNPanStateIdle;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.nameLabel]];
    
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.nameLabel]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Gesture handlers

- (IBAction)panName:(UIPanGestureRecognizer *)recognizer
{
    static BBNPanDirection panDirection = BBNPanDirectionNone;
    
    // Discard gesture recognizer if panning is disabled.
    if (!self.panningEnabled) {
        recognizer.enabled = NO;
    }
    else {
        recognizer.enabled = YES;
    }
    
    // Handle panning.
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self.animator removeAllBehaviors];
        
        panDirection = [self directionForGesture:recognizer];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.nameLabel.center = [self calculatedCenterForGesture:recognizer
                                                   withDirection:panDirection];
        
        [recognizer setTranslation:CGPointZero
                            inView:self.view];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        self.panState = [self endStateForGesture:recognizer
                                   withDirection:panDirection];
        self.gravityBehavior.gravityDirection = [self gravityDirectionForPanDirection:panDirection];
        
        [self.collisionBehavior setTranslatesReferenceBoundsIntoBoundaryWithInsets:[self edgeInsetsForPanDirection:panDirection]];
        
        [self.animator addBehavior:self.gravityBehavior];
        [self.animator addBehavior:self.collisionBehavior];
        
        // Disable panning until animation is finished.
        self.panningEnabled = NO;
    }
}

#pragma mark - Private methods

- (BBNPanDirection)directionForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
    
    if (fabs(velocity.x) > fabs(velocity.y)) {
        if (velocity.x > 0.0) {
            return BBNPanDirectionRight;
        }
        else {
            return BBNPanDirectionLeft;
        }
    }
    else if (fabs(velocity.x) < fabs(velocity.y)) {
        if (velocity.y < 0.0) {
            return BBNPanDirectionUp;
        }
        else {
            return BBNPanDirectionDown;
        }
    }
    else {
        return BBNPanDirectionNone;
    }
}

- (BBNPanState)endStateForGesture:(UIPanGestureRecognizer *)recognizer withDirection:(BBNPanDirection)direction
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint newCenter = [self calculatedCenterForGesture:recognizer
                                           withDirection:direction];
    
    switch (direction) {
        case BBNPanDirectionRight:
            if (velocity.x >= BBNPanVelocityThreshold) {
                return BBNPanStateAccept;
            }
            else if (velocity.x <= -BBNPanVelocityThreshold) {
                return BBNPanStateReject;
            }
            else {
                if (newCenter.x >= self.view.center.x + BBNPanTranslationThreshold) {
                    return BBNPanStateAccept;
                }
                else if (newCenter.x <= self.view.center.x - BBNPanTranslationThreshold) {
                    return BBNPanStateReject;
                }
                else {
                    return BBNPanStateIdle;
                }
            }
            break;

        case BBNPanDirectionLeft:
            if (velocity.x >= BBNPanVelocityThreshold) {
                return BBNPanStateAccept;
            }
            else if (velocity.x <= -BBNPanVelocityThreshold) {
                return BBNPanStateReject;
            }
            else {
                if (newCenter.x >= self.view.center.x + BBNPanTranslationThreshold) {
                    return BBNPanStateAccept;
                }
                else if (newCenter.x <= self.view.center.x - BBNPanTranslationThreshold) {
                    return BBNPanStateReject;
                }
                else {
                    return BBNPanStateIdle;
                }
            }
            break;

        case BBNPanDirectionUp:
            if (velocity.y <= -BBNPanVelocityThreshold) {
                return BBNPanStateMaybe;
            }
            else {
                if (newCenter.y <= self.view.center.y - BBNPanTranslationThreshold) {
                    return BBNPanStateMaybe;
                }
                else {
                    return BBNPanStateIdle;
                }
            }
            break;
            
        default:
        case BBNPanDirectionNone:
        case BBNPanDirectionDown:
            return BBNPanStateIdle;
            break;
    }
}

- (CGPoint)calculatedCenterForGesture:(UIPanGestureRecognizer *)recognizer withDirection:(BBNPanDirection)direction
{
    CGPoint center = self.nameLabel.center;
    CGPoint translation = [recognizer translationInView:self.view];
    
    switch (direction) {
        case BBNPanDirectionLeft:
        case BBNPanDirectionRight:
            return CGPointMake(center.x + translation.x,
                               center.y);
            break;
            
        case BBNPanDirectionUp:
            if (center.y + translation.y < self.view.center.y) {
                return CGPointMake(center.x,
                                   center.y + translation.y);
            }
            else {
                return self.view.center;
            }
            
        default:
        case BBNPanDirectionNone:
        case BBNPanDirectionDown:
            return center;
            break;
    }
}

- (CGVector)gravityDirectionForPanDirection:(BBNPanDirection)panDirection
{
    switch (self.panState) {
        case BBNPanStateIdle:
            if (panDirection == BBNPanDirectionLeft) {
                return CGVectorMake(1.0, 0.0);
            }
            else if (panDirection == BBNPanDirectionUp) {
                return CGVectorMake(0.0, 1.0);
            }
            else if (panDirection == BBNPanDirectionRight) {
                return CGVectorMake(-1.0, 0.0);
            }
            else {
                return CGVectorMake(0.0, 1.0);
            }
            break;
            
        case BBNPanStateAccept:
            return CGVectorMake(1.0, 0.0);
            break;

        case BBNPanStateReject:
            return CGVectorMake(-1.0, 0.0);
            break;

        case BBNPanStateMaybe:
            return CGVectorMake(0.0, -1.0);
            
        default:
            return CGVectorMake(1.0, 0.0);
            break;
    }
}

- (UIEdgeInsets)edgeInsetsForPanDirection:(BBNPanDirection)panDirection
{
    switch (self.panState) {
        case BBNPanStateIdle:
            if (panDirection == BBNPanDirectionLeft) {
                return UIEdgeInsetsMake(0.0,
                                        -self.nameLabel.frame.size.width,
                                        0.0,
                                        BBNNameLabelPadding);
            }
            else if (panDirection == BBNPanDirectionUp) {
                return UIEdgeInsetsMake(-self.nameLabel.frame.size.height,
                                        0.0,
                                        (self.view.frame.size.height - self.nameLabel.frame.size.height) / 2,
                                        0.0);
            }
            else if (panDirection == BBNPanDirectionRight) {
                return UIEdgeInsetsMake(0.0,
                                        BBNNameLabelPadding,
                                        0.0,
                                        -self.nameLabel.frame.size.width);
            }
            else {
                return UIEdgeInsetsZero;
            }
            break;
        
        case BBNPanStateAccept:
            return UIEdgeInsetsMake(0.0,
                                    0.0,
                                    0.0,
                                    -self.nameLabel.frame.size.width);
            break;

        case BBNPanStateReject:
            return UIEdgeInsetsMake(0.0,
                                    -self.nameLabel.frame.size.width,
                                    0.0,
                                    0.0);
            break;

        case BBNPanStateMaybe:
            return UIEdgeInsetsMake(-self.nameLabel.frame.size.height,
                                    0.0,
                                    0.0,
                                    0.0);
            break;
            
        default:
            return UIEdgeInsetsZero;
            break;
    }
}

#pragma mark - Dynamica animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    // Enable panning when animation is finished.
    self.panningEnabled = YES;
    
    // Adjust misalignment to center.
    if (self.panState == BBNPanStateIdle) {
        self.nameLabel.center = self.view.center;
    }
    
    // TODO: move where a label with a new name is displayed.
    self.panState = BBNPanStateIdle;
}

@end
