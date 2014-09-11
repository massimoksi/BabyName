//
//  NameViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "NameViewController.h"


typedef NS_ENUM(NSUInteger, PanDirection) {
    kPanDirectionNone = 0,
    kPanDirectionUp,
    kPanDirectionRight,
    kPanDirectionDown,
    kPanDirectionLeft
};

typedef NS_ENUM(NSUInteger, PanState) {
    kPanStateIdle = 0,
    kPanStateAccept,
    kPanStateReject,
    kPanStateMaybe
};


static const CGFloat kNameLabelPadding = 10.0;
static const CGFloat kPanVelocityThreshold = 100.0;
static const CGFloat kPanTranslationThreshold = 80.0;


@interface NameViewController () <UIDynamicAnimatorDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) PanState panState;

@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;

@property (nonatomic, copy) NSMutableArray *suggestions;
@property (nonatomic, strong) Suggestion *currentSuggestion;

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
    self.panState = kPanStateIdle;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.nameLabel]];
    
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.nameLabel]];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    
    // Fetch all suggestions with state "maybe".
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.state == %d", kSuggestionStateMaybe];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    self.suggestions = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest
                                                                                               error:&error]];
    if (!self.suggestions) {
        // TODO: handle the error.
    }
    else {
#if DEBUG
        NSLog(@"Fetched %tu suggestions to be evaluated.", [self.suggestions count]);
#endif
        
        // Get a random suggestion.
        self.currentSuggestion = [self randomSuggestion];
        
        // Set the name on the label.
        self.nameLabel.text = self.currentSuggestion.name;
    }
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

#pragma mark - Actions

- (IBAction)showSettings:(id)sender
{
    [self.drawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen
                                inDirection:MSDynamicsDrawerDirectionBottom
                                   animated:YES
                      allowUserInterruption:YES
                                 completion:nil];
}

#pragma mark - Gesture handlers

- (IBAction)panName:(UIPanGestureRecognizer *)recognizer
{
    static PanDirection panDirection = kPanDirectionNone;
    
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

- (Suggestion *)randomSuggestion
{
    return [self.suggestions objectAtIndex:(arc4random() % [self.suggestions count])];
}

- (PanDirection)directionForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
    
    if (fabs(velocity.x) > fabs(velocity.y)) {
        if (velocity.x > 0.0) {
            return kPanDirectionRight;
        }
        else {
            return kPanDirectionLeft;
        }
    }
    else if (fabs(velocity.x) < fabs(velocity.y)) {
        if (velocity.y < 0.0) {
            return kPanDirectionUp;
        }
        else {
            return kPanDirectionDown;
        }
    }
    else {
        return kPanDirectionNone;
    }
}

- (PanState)endStateForGesture:(UIPanGestureRecognizer *)recognizer withDirection:(PanDirection)direction
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint newCenter = [self calculatedCenterForGesture:recognizer
                                           withDirection:direction];
    
    switch (direction) {
        case kPanDirectionRight:
            if (velocity.x >= kPanVelocityThreshold) {
                return kPanStateAccept;
            }
            else if (velocity.x <= -kPanVelocityThreshold) {
                return kPanStateReject;
            }
            else {
                if (newCenter.x >= self.view.center.x + kPanTranslationThreshold) {
                    return kPanStateAccept;
                }
                else if (newCenter.x <= self.view.center.x - kPanTranslationThreshold) {
                    return kPanStateReject;
                }
                else {
                    return kPanStateIdle;
                }
            }
            break;

        case kPanDirectionLeft:
            if (velocity.x >= kPanVelocityThreshold) {
                return kPanStateAccept;
            }
            else if (velocity.x <= -kPanVelocityThreshold) {
                return kPanStateReject;
            }
            else {
                if (newCenter.x >= self.view.center.x + kPanTranslationThreshold) {
                    return kPanStateAccept;
                }
                else if (newCenter.x <= self.view.center.x - kPanTranslationThreshold) {
                    return kPanStateReject;
                }
                else {
                    return kPanStateIdle;
                }
            }
            break;

        case kPanDirectionUp:
            if (velocity.y <= -kPanVelocityThreshold) {
                return kPanStateMaybe;
            }
            else {
                if (newCenter.y <= self.view.center.y - kPanTranslationThreshold) {
                    return kPanStateMaybe;
                }
                else {
                    return kPanStateIdle;
                }
            }
            break;
            
        default:
        case kPanDirectionNone:
        case kPanDirectionDown:
            return kPanStateIdle;
            break;
    }
}

- (CGPoint)calculatedCenterForGesture:(UIPanGestureRecognizer *)recognizer withDirection:(PanDirection)direction
{
    CGPoint center = self.nameLabel.center;
    CGPoint translation = [recognizer translationInView:self.view];
    
    switch (direction) {
        case kPanDirectionLeft:
        case kPanDirectionRight:
            return CGPointMake(center.x + translation.x,
                               center.y);
            break;
            
        case kPanDirectionUp:
            if (center.y + translation.y < self.view.center.y) {
                return CGPointMake(center.x,
                                   center.y + translation.y);
            }
            else {
                return self.view.center;
            }
            
        default:
        case kPanDirectionNone:
        case kPanDirectionDown:
            return center;
            break;
    }
}

- (CGVector)gravityDirectionForPanDirection:(PanDirection)panDirection
{
    switch (self.panState) {
        case kPanStateIdle:
            if (panDirection == kPanDirectionLeft) {
                return CGVectorMake(1.0, 0.0);
            }
            else if (panDirection == kPanDirectionUp) {
                return CGVectorMake(0.0, 1.0);
            }
            else if (panDirection == kPanDirectionRight) {
                return CGVectorMake(-1.0, 0.0);
            }
            else {
                return CGVectorMake(0.0, 1.0);
            }
            break;
            
        case kPanStateAccept:
            return CGVectorMake(1.0, 0.0);
            break;

        case kPanStateReject:
            return CGVectorMake(-1.0, 0.0);
            break;

        case kPanStateMaybe:
            return CGVectorMake(0.0, -1.0);
            
        default:
            return CGVectorMake(1.0, 0.0);
            break;
    }
}

- (UIEdgeInsets)edgeInsetsForPanDirection:(PanDirection)panDirection
{
    switch (self.panState) {
        case kPanStateIdle:
            if (panDirection == kPanDirectionLeft) {
                return UIEdgeInsetsMake(0.0,
                                        -self.nameLabel.frame.size.width,
                                        0.0,
                                        kNameLabelPadding);
            }
            else if (panDirection == kPanDirectionUp) {
                return UIEdgeInsetsMake(-self.nameLabel.frame.size.height,
                                        0.0,
                                        (self.view.frame.size.height - self.nameLabel.frame.size.height) / 2,
                                        0.0);
            }
            else if (panDirection == kPanDirectionRight) {
                return UIEdgeInsetsMake(0.0,
                                        kNameLabelPadding,
                                        0.0,
                                        -self.nameLabel.frame.size.width);
            }
            else {
                return UIEdgeInsetsZero;
            }
            break;
        
        case kPanStateAccept:
            return UIEdgeInsetsMake(0.0,
                                    0.0,
                                    0.0,
                                    -self.nameLabel.frame.size.width);
            break;

        case kPanStateReject:
            return UIEdgeInsetsMake(0.0,
                                    -self.nameLabel.frame.size.width,
                                    0.0,
                                    0.0);
            break;

        case kPanStateMaybe:
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

- (void)acceptSuggestion:(Suggestion *)suggestion
{
    // TODO: implement.
    NSLog(@"YES!!!!!!!!!!!!!!!!");
}

- (void)rejectSuggestion:(Suggestion *)suggestion
{
    // TODO: implement.
    NSLog(@"NOOOOOOOOOOOOOOOOOOO");
}

- (void)rethinkSuggestion:(Suggestion *)suggestion
{
    // TODO: implement.
    NSLog(@"Boooooooooooooh");
}

#pragma mark - Dynamics animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    // Enable panning when animation is finished.
    self.panningEnabled = YES;
    
    // Adjust misalignment to center.
    if (self.panState == kPanStateIdle) {
        self.nameLabel.center = self.view.center;
    }
    
    switch (self.panState) {
        case kPanStateAccept:
            [self acceptSuggestion:self.currentSuggestion];
            break;

        case kPanStateReject:
            [self rejectSuggestion:self.currentSuggestion];
            break;
            
        default:
        case kPanStateIdle:
        case kPanStateMaybe:
            [self rethinkSuggestion:self.currentSuggestion];
            break;
    }
    
    // TODO: move where a label with a new name is displayed.
    self.panState = kPanStateIdle;
}

@end
