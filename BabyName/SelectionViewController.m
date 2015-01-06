//
//  SelectionViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SelectionViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Constants.h"
#import "SuggestionsManager.h"
#import "StatusView.h"


typedef NS_ENUM(NSUInteger, PanningState) {
    kPanningStateIdle = 0,
    kPanningStateAccept,
    kPanningStateReject
};


static const CGFloat kPanningVelocityThreshold = 100.0;
static const CGFloat kPanningPositionThreshold = 150.0;


@interface SelectionViewController () <UIDynamicAnimatorDelegate>

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *surnameLabel;

@property (nonatomic) BOOL panningEnabled;
@property (nonatomic) CGPoint panningOrigin;
@property (nonatomic) PanningState panningState;

@property (nonatomic, strong) Suggestion *currentSuggestion;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@end


@implementation SelectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleNotification:)
                               name:kFetchingPreferencesChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleNotification:)
                               name:kPreferredSuggestionChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleNotification:)
                               name:kCurrentSuggestionChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleNotification:)
                               name:kAcceptedSuggestionChangedNotification
                             object:nil];
    
    // It's not possible to make the view transparent in Storyboard because of the use of white labels.
    self.view.backgroundColor = [UIColor clearColor];
    
    [self configureNameLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.surnameLabel.alpha = ([userDefaults boolForKey:kSettingsShowSurnameKey]) ? 1.0 : 0.0;
    self.surnameLabel.text = [userDefaults stringForKey:kSettingsSurnameKey];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.panningOrigin = self.nameLabel.center;
    
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.nameLabel]];
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:kFetchingPreferencesChangedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kPreferredSuggestionChangedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kCurrentSuggestionChangedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kAcceptedSuggestionChangedNotification
                                object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.animator = nil;
    self.itemBehavior = nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - Accessors

- (UIDynamicAnimator *)animator
{
    // Lazily initialize the dynamic animator.
    if (_animator) {
        return _animator;
    }

    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _animator.delegate = self;

    return _animator;
}

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
    static BOOL panningValid;
    
    // Discard gesture if panning is disabled.
    if (!self.panningEnabled) {
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Discard gesture if panning is vertical.
        CGPoint velocity = [recognizer velocityInView:self.view];
        if (fabs(velocity.y) > fabs(velocity.x)) {
            panningValid = NO;
        }
        else {
            panningValid = YES;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (panningValid) {
            CGPoint origin = self.nameLabel.center;
            self.nameLabel.center = CGPointMake(origin.x + [recognizer translationInView:self.view].x, origin.y);
            
            [recognizer setTranslation:CGPointZero
                                inView:self.view];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        if (panningValid) {
            self.panningState = [self endStateForGesture:recognizer];

            CGRect viewFrame = self.view.frame;
            __weak typeof(self) weakSelf = self;

            self.itemBehavior.action = ^{
                if ((weakSelf.panningState == kPanningStateAccept) && (weakSelf.nameLabel.center.x > CGRectGetMaxX(viewFrame) + kPanningPositionThreshold)) {
                    [weakSelf.animator removeAllBehaviors];
                }
                else if ((weakSelf.panningState == kPanningStateReject) && (weakSelf.nameLabel.center.x < CGRectGetMinX(viewFrame) - kPanningPositionThreshold)) {
                    [weakSelf.animator removeAllBehaviors];
                }
            };
            self.itemBehavior.allowsRotation = NO;
            [self.animator addBehavior:self.itemBehavior];
            
            UISnapBehavior *snapBehavior;
            switch (self.panningState) {
                case kPanningStateAccept:
                    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.nameLabel
                                                            snapToPoint:CGPointMake(CGRectGetMidX(viewFrame) + CGRectGetWidth(viewFrame), self.panningOrigin.y)];
                    snapBehavior.damping = 1.0;
                    [self.animator addBehavior:snapBehavior];
                    break;
                    
                case kPanningStateReject:
                    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.nameLabel
                                                            snapToPoint:CGPointMake(CGRectGetMidX(viewFrame) - CGRectGetWidth(viewFrame), self.panningOrigin.y)];
                    snapBehavior.damping = 1.0;
                    [self.animator addBehavior:snapBehavior];
                    break;
                    
                default:
                case kPanningStateIdle:
                    snapBehavior = [[UISnapBehavior alloc] initWithItem:self.nameLabel
                                                            snapToPoint:self.panningOrigin];
                    snapBehavior.damping = 1.0;
                    [self.animator addBehavior:snapBehavior];                
                    
                    break;
            }
            
            // Disable panning until animation is finished.
            self.panningEnabled = NO;

            StatusView *statusView;
            if (self.panningState == kPanningStateAccept) {
                self.nameLabel.alpha = 0.0;
                
                // If reviewing the last accepted name, accepting means preferring it.
                if (([[NSUserDefaults standardUserDefaults] boolForKey:kStateReviewAcceptedNamesKey]) && ([[SuggestionsManager sharedManager] acceptedSuggestions].count == 1)) {
                    statusView = [[StatusView alloc] initWithImage:[UIImage imageNamed:@"StatusPreferred"]];
                    [statusView showInView:self.view
                                  position:self.panningOrigin
                                completion:^(BOOL finished){
                                    if (finished) {
                                        if (![[SuggestionsManager sharedManager] preferSuggestion:self.currentSuggestion]) {
                                            [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                        }
                                        else {
                                            [self configureNameLabel];
                                            
                                            [[NSNotificationCenter defaultCenter] postNotificationName:kPreferredSuggestionChangedNotification
                                                                                                object:self];
                                        }
                                    }
                                }];
                }
                else {
                    statusView = [[StatusView alloc] initWithImage:[UIImage imageNamed:@"StatusAccepted"]];
                    [statusView showInView:self.view
                                  position:self.panningOrigin
                                completion:^(BOOL finished){
                                    if (finished) {
                                        if (![[SuggestionsManager sharedManager] acceptSuggestion:self.currentSuggestion]) {
                                            [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                        }
                                        else {
                                            [self.containerViewController loadChildViewController];
                                            
                                            [self configureNameLabel];
                                        }
                                    }
                                }];
                }
            }
            else if (self.panningState == kPanningStateReject) {
                self.nameLabel.alpha = 0.0;

                statusView = [[StatusView alloc] initWithImage:[UIImage imageNamed:@"StatusRejected"]];
                [statusView showInView:self.view
                              position:self.panningOrigin
                            completion:^(BOOL finished){
                                if (finished) {
                                    if (![[SuggestionsManager sharedManager] rejectSuggestion:self.currentSuggestion]) {
                                        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                    }
                                    else {
                                        // If reviewing accepted names and only one name remains, ask if the last one is the preferred.
                                        if (([[NSUserDefaults standardUserDefaults] boolForKey:kStateReviewAcceptedNamesKey]) && ([[SuggestionsManager sharedManager] acceptedSuggestions].count == 1)) {
                                            [self reviewLastSuggestion];
                                        }
                                        else {
                                            [self.containerViewController loadChildViewController];
                                            
                                            [self configureNameLabel];
                                        }
                                    }
                                }
                            }];
            }
        }
    }
}

#pragma mark - Notification handlers

- (void)handleNotification:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        SuggestionsManager *suggestionsManager = [SuggestionsManager sharedManager];
        NSString *notificationName = notification.name;
        
        if ([notificationName isEqualToString:kFetchingPreferencesChangedNotification]) {
            if ([suggestionsManager preferredSuggestion]) {
                if (![suggestionsManager validatePreferredSuggestion]) {
                    [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kPreferredSuggestionChangedNotification
                                                                        object:self];
                }
            }
            
            [suggestionsManager update];
            
            if ([suggestionsManager acceptedSuggestions].count == 0) {
                [[NSUserDefaults standardUserDefaults] setBool:NO
                                                        forKey:kStateReviewAcceptedNamesKey];
            }
            
            [self.containerViewController loadChildViewController];
        }
        else if ([notificationName isEqualToString:kPreferredSuggestionChangedNotification]) {
            [self.containerViewController loadChildViewController];
        }
        else if ([notificationName isEqualToString:kAcceptedSuggestionChangedNotification]) {
            [self.containerViewController loadChildViewController];
        }
        
        [self configureNameLabel];
    }
}

#pragma mark - Private methods

- (void)configureNameLabel
{
    SuggestionsManager *manager = [SuggestionsManager sharedManager];
    
    // Check if there's a preferred suggestion.
    self.currentSuggestion = [manager preferredSuggestion];
    if (!self.currentSuggestion) {
        // If not, fetch a random suggestion.
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kStateReviewAcceptedNamesKey]) {
            self.currentSuggestion = [manager randomSuggestion];
        }
        else {
            self.currentSuggestion = [manager randomAcceptedSuggestion];
        }
    }
    
    // Configure name label.
    //  1. Text.
    //  2. Position.
    //  3. Visibility.
    //  4. Set panning state.
    self.nameLabel.text = self.currentSuggestion.name;
    self.nameLabel.center = self.panningOrigin;
    self.nameLabel.alpha = 1.0;
    self.panningState = kPanningStateIdle;
    
    if (self.currentSuggestion.state == kSelectionStatePreferred) {
        // Add glow effect.
        self.nameLabel.layer.shadowColor = [[UIColor whiteColor] CGColor];
        self.nameLabel.layer.shadowRadius = 4.0;
        self.nameLabel.layer.shadowOpacity = 0.9;
        self.nameLabel.layer.shadowOffset = CGSizeZero;
        self.nameLabel.layer.masksToBounds = NO;

        // Add glow animation.
        CABasicAnimation *glowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        glowAnimation.fromValue = @(0.9);
        glowAnimation.toValue = @(0.0);
        glowAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        glowAnimation.duration = 1.5;
        glowAnimation.repeatCount = HUGE_VALF;
        glowAnimation.autoreverses = YES;
        [self.nameLabel.layer addAnimation:glowAnimation
                                    forKey:@"glow"];
        
        // Disable panning.
        self.panningEnabled = NO;
    }
    else {
        // Remove glow effect.
        self.nameLabel.layer.shadowColor = nil;
        self.nameLabel.layer.shadowRadius = 0.0;
        self.nameLabel.layer.shadowOpacity = 0.0;

        // Remove glow animation.
        [self.nameLabel.layer removeAnimationForKey:@"glow"];
        
        // Enable panning.
        self.panningEnabled = YES;
    }
}

- (PanningState)endStateForGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint velocity = [recognizer velocityInView:self.view];
    CGPoint location = [recognizer locationInView:self.view];
    
    if ((velocity.x >= kPanningVelocityThreshold) && (fabs(velocity.x) >= fabs(velocity.y))) {
        return kPanningStateAccept;
    }
    else if ((velocity.x <= -kPanningVelocityThreshold) && (fabs(velocity.x) >= fabs(velocity.y))) {
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

- (void)reviewLastSuggestion
{
    SuggestionsManager *suggestionsManager = [SuggestionsManager sharedManager];
    Suggestion *lastSuggestion = [suggestionsManager randomAcceptedSuggestion];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:lastSuggestion.name
                                                                             message:NSLocalizedString(@"You only have one name to review. Is it your favourite name?", @"Question: confirm the favourite name.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *preferAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Answer: affirmative.")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){
                                                             StatusView *statusView = [[StatusView alloc] initWithImage:[UIImage imageNamed:@"StatusPreferred"]];
                                                             [statusView showInView:self.view
                                                                           position:self.panningOrigin
                                                                         completion:^(BOOL finished){
                                                                             if (finished) {
                                                                                 if (![[SuggestionsManager sharedManager] preferSuggestion:lastSuggestion]) {
                                                                                     [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                                                                 }
                                                                                 else {
                                                                                     [self configureNameLabel];
                                                                                     
                                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:kPreferredSuggestionChangedNotification
                                                                                                                                         object:self];
                                                                                 }
                                                                             }
                                                                         }];
                                                         }];
    [alertController addAction:preferAction];

    UIAlertAction *thinkAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"I still need to think", @"Answer: maybe.")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action){
                                                            [self configureNameLabel];
                                                        }];
    [alertController addAction:thinkAction];
    
    UIAlertAction *rejectAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"Answer: negative.")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action){
                                                             StatusView *statusView = [[StatusView alloc] initWithImage:[UIImage imageNamed:@"StatusRejected"]];
                                                             [statusView showInView:self.view
                                                                           position:self.panningOrigin
                                                                         completion:^(BOOL finished){
                                                                             if (finished) {
                                                                                 if (![[SuggestionsManager sharedManager] rejectSuggestion:lastSuggestion]) {
                                                                                     [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                                                                 }
                                                                                 else {
                                                                                     [self.containerViewController loadChildViewController];
                                                                                     
                                                                                     [self configureNameLabel];
                                                                                 }
                                                                             }
                                                                         }];
                                                         }];
    [alertController addAction:rejectAction];

    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Alert: title.")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert: accept button.")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alertController addAction:acceptAction];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark - Embedded view controller

@synthesize containerViewController;

#pragma mark - Dynamics animator delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    if ([self.animator behaviors].count) {
        [self.animator removeAllBehaviors];
    }

    self.panningEnabled = YES;
}

@end
