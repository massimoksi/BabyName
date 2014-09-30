//
//  NameViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "NameViewController.h"

#import "Constants.h"
#import "Suggestion.h"
#import "SettingsTableViewController.h"


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


@interface NameViewController () <UIDynamicAnimatorDelegate, SettingsTableViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) PanningState panningState;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIGravityBehavior *gravityBehavior;
@property (nonatomic, strong) UICollisionBehavior *collisionBehavior;

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

    [self updateSuggestions];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"SettingsSegue"]) {
        UINavigationController *settingsNavController = [segue destinationViewController];
        SettingsTableViewController *settingsViewController = (SettingsTableViewController *)settingsNavController.topViewController;
        settingsViewController.delegate = self;
    }
}

#pragma mark - Actions

- (IBAction)showAcceptedNames:(id)sender
{
    [self.drawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen
                                inDirection:MSDynamicsDrawerDirectionRight
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
        [self.animator addBehavior:self.gravityBehavior];
        
        [self.collisionBehavior setTranslatesReferenceBoundsIntoBoundaryWithInsets:[self edgeInsetsForPanningDirection:panningDirection]];        
        [self.animator addBehavior:self.collisionBehavior];

        [self performEndingAction];
        
        // Disable panning until animation is finished.
        self.panningEnabled = NO;
    }
}

#pragma mark - Private methods

- (void)updateSuggestions
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Get new preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

    // Fetch all suggestions with state "maybe" and  matching the criteria from preferences.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateMaybe, genders, languages];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray *fetchedSuggestions = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest
                                                                                                          error:&error]];
    // TODO: check if it's better to check for the existance of the array or the length.
    if (!fetchedSuggestions) {
        // TODO: handle the error.
    }
    else {
        // Filter suggestions by preferred initials.
        NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
        if (initials.count) {
#if DEBUG
            NSLog(@"[NameViewController] Settings:");
            NSLog(@"    Preferred initials %@", [initials componentsJoinedByString:@", "]);
#endif

            NSString *initialsRegex = [NSString stringWithFormat:@"^[%@].*", [initials componentsJoinedByString:@""]];
            NSPredicate *initialsPredicate = [NSPredicate predicateWithFormat:@"name MATCHES[cd] %@", initialsRegex];

            self.suggestions = [NSMutableArray arrayWithArray:[fetchedSuggestions filteredArrayUsingPredicate:initialsPredicate]];
        }
        else {
            self.suggestions = [NSMutableArray arrayWithArray:fetchedSuggestions];
        }

        self.nameLabelVisible = NO;
        self.nameLabel.alpha = 0.0;
        
        [self updateNameLabel];
    }
}

- (void)fetchRandomSuggestion
{
#if DEBUG
    NSLog(@"[NameViewController] Database:");
    NSLog(@"    Fetched suggestions %tu", self.suggestions.count);
#endif
    
    if (self.suggestions.count) {
        self.currentIndex = arc4random() % self.suggestions.count;
        self.currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    }
    else {
        // TODO: implement.
    }
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
                return CGVectorMake(0.0, 0.0);
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

- (void)performEndingAction
{
    switch (self.panningState) {
        case kPanningStateAccept:
            [self acceptCurrentSuggestion];
            break;

        case kPanningStateReject:
            [self rejectCurrentSuggestion];
            break;

        case kPanningStateMaybe:
            [self rethinkCurrentSuggestion];
            break;

        default:
        case kPanningStateIdle:
            break;
    }
}

- (void)acceptCurrentSuggestion
{
    self.currentSuggestion.state = kSelectionStateAccepted;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
#if DEBUG
        NSLog(@"[NameViewController] Accepted: %@", self.currentSuggestion.name);
#endif

        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
    }
}

- (void)rejectCurrentSuggestion
{
    self.currentSuggestion.state = kSelectionStateRejected;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
#if DEBUG
        NSLog(@"[NameViewController] Rejected: %@", self.currentSuggestion.name);
#endif

        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
    }
}

- (void)rethinkCurrentSuggestion
{
#if DEBUG
    NSLog(@"[NameViewController] Rethink: %@", self.currentSuggestion.name);
#endif
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
    else {
        [self updateNameLabel];
    }
}

#pragma mark - Dynamics drawer view controller delegate

- (BOOL)dynamicsDrawerViewController:(MSDynamicsDrawerViewController *)drawerViewController shouldBeginPanePan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    // Inhibit pane pan while animating selection.
    return self.panningEnabled;
}

#pragma mark - Settings view controller delegate

- (void)settingsViewControllerWillClose:(SettingsTableViewController *)viewController withUpdatedFetchingPreferences:(BOOL)updatedFetchingPreferences;
{
    if (updatedFetchingPreferences) {
        [self updateSuggestions];
    }
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)resetAllSelections
{
    // Retrieve the address of the persistent store.
    NSURL *storeURL = [[self.managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[self.managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
    
    // Drop pending changes.
    [self.managedObjectContext reset];
    
    NSError *error;
    if ([[self.managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[self.managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]
                                                                                error:&error]) {
        // Remove the persistent store.
        [[NSFileManager defaultManager] removeItemAtURL:storeURL
                                                  error:&error];

        // Copy the pre-populated database.
        NSURL *preloadURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"BabyName"
                                                                                   ofType:@"sqlite"]];
        if (![[NSFileManager defaultManager] copyItemAtURL:preloadURL
                                                     toURL:storeURL
                                                     error:&error]) {
            // TODO: handle error.
        }
        
        // Re-load the persistent store.
        if (![[self.managedObjectContext persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType
                                                                                  configuration:nil
                                                                                            URL:storeURL
                                                                                        options:nil
                                                                                          error:&error]) {
            // TODO: handle error.
        }
    }
    else {
        // TODO: handle error.
    }
}

@end
