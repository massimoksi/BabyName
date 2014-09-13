//
//  NameViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "NameViewController.h"


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
    kPanningStateReject,
    kPanningStateMaybe
};


static const CGFloat kNameLabelPadding = 10.0; // TODO: replace with a calculation.
static const CGFloat kPanningVelocityThreshold = 100.0;
static const CGFloat kPanningTranslationThreshold = 80.0;


@interface NameViewController () <UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) PanningState panningState;

@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;

@property (nonatomic) BOOL nameLabelVisible;

@property (nonatomic, strong) NSMutableArray *suggestions;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) Suggestion *currentSuggestion;

@end


@implementation NameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.panningEnabled = YES;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    self.gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.nameLabel]];
    
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.nameLabel]];
    self.collisionBehavior.collisionDelegate = self;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Fetch all suggestions with state "maybe".
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state == %d", kSuggestionStateMaybe];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    self.suggestions = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest
                                                                                               error:&error]];
    if (!self.suggestions) {
        // TODO: handle the error.
    }
    else {
        self.nameLabelVisible = NO;
        self.nameLabel.alpha = 0.0;
        
        [self updateNameLabel];
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
        [self.animator removeAllBehaviors];
        
        panningDirection = [self directionForGesture:recognizer];
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
        self.gravityBehavior.gravityDirection = [self gravityDirectionForPanningDirection:panningDirection];
        
        [self.collisionBehavior setTranslatesReferenceBoundsIntoBoundaryWithInsets:[self edgeInsetsForPanningDirection:panningDirection]];
        
        [self.animator addBehavior:self.gravityBehavior];
        [self.animator addBehavior:self.collisionBehavior];
        
        // Disable panning until animation is finished.
        self.panningEnabled = NO;
    }
}

#pragma mark - Private methods

- (void)fetchRandomSuggestion
{
#if DEBUG
    NSLog(@"%tu suggestions to be evaluated.", [self.suggestions count]);
#endif
    
    self.currentIndex = arc4random() % [self.suggestions count];
    self.currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
}

- (void)updateNameLabel
{
    // Fetch a new random suggestion.
    [self fetchRandomSuggestion];
    
    self.nameLabel.text = self.currentSuggestion.name;
    self.nameLabel.center = self.view.center;
    
    self.nameLabelVisible = YES;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.nameLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                         self.panningState = kPanningStateIdle;
                     }];
}

- (PanningDirection)directionForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
    
    if (fabs(velocity.x) > fabs(velocity.y)) {
        if (velocity.x > 0.0) {
            return kPanningDirectionRight;
        }
        else {
            return kPanningDirectionLeft;
        }
    }
    else if (fabs(velocity.x) < fabs(velocity.y)) {
        if (velocity.y < 0.0) {
            return kPanningDirectionUp;
        }
        else {
            return kPanningDirectionDown;
        }
    }
    else {
        return kPanningDirectionNone;
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

        case kPanningDirectionUp:
            if (velocity.y <= -kPanningVelocityThreshold) {
                return kPanningStateMaybe;
            }
            else {
                if (newCenter.y <= self.view.center.y - kPanningTranslationThreshold) {
                    return kPanningStateMaybe;
                }
                else {
                    return kPanningStateIdle;
                }
            }
            break;
            
        default:
        case kPanningDirectionNone:
        case kPanningDirectionDown:
            return kPanningStateIdle;
            break;
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
            
        case kPanningDirectionUp:
            if (center.y + translation.y < self.view.center.y) {
                return CGPointMake(center.x,
                                   center.y + translation.y);
            }
            else {
                return self.view.center;
            }
            
        default:
        case kPanningDirectionNone:
        case kPanningDirectionDown:
            return center;
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
                return CGVectorMake(0.0, 1.0);
            }
            break;
            
        case kPanningStateAccept:
            return CGVectorMake(1.0, 0.0);
            break;

        case kPanningStateReject:
            return CGVectorMake(-1.0, 0.0);
            break;

        case kPanningStateMaybe:
            return CGVectorMake(0.0, -1.0);
            
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

        case kPanningStateMaybe:
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
    suggestion.state = kSuggestionStateYes;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];

        [self updateNameLabel];
    }
}

- (void)rejectSuggestion:(Suggestion *)suggestion
{
    suggestion.state = kSuggestionStateNo;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
        
        [self updateNameLabel];
    }
}

- (void)rethinkSuggestion:(Suggestion *)suggestion
{
    [self updateNameLabel];
}

#pragma mark - Dynamics animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    // Enable panning when animation is finished.
    self.panningEnabled = YES;
    
    // Adjust misalignment to center.
    if (self.panningState == kPanningStateIdle) {
        self.nameLabel.center = self.view.center;
    }
}

#pragma mark - Collision behavior delegate

- (void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier
{
    if (self.nameLabelVisible && (self.panningState != kPanningStateIdle)) {
        // Hide the name label.
        self.nameLabelVisible = NO;
        self.nameLabel.alpha = 0.0;
        
        switch (self.panningState) {
            case kPanningStateAccept:
                [self acceptSuggestion:self.currentSuggestion];
                break;
                
            case kPanningStateReject:
                [self rejectSuggestion:self.currentSuggestion];
                break;
                
            case kPanningStateMaybe:
                [self rethinkSuggestion:self.currentSuggestion];
                break;
                
            default:
            case kPanningStateIdle:
                break;
        }
    }
}

@end
