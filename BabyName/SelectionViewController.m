//
//  SelectionViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SelectionViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "StatusView.h"


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
                           selector:@selector(updateSelection:)
                               name:kFetchingPreferencesChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(updateSelection:)
                               name:kPreferredSuggestionChangedNotification
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

            self.itemBehavior.allowsRotation = NO;
            [self.animator addBehavior:self.itemBehavior];
            
            CGRect viewFrame = self.view.frame;
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
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     self.nameLabel.alpha = 0.0;
                                 }];
                
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
                                    }
                                }
                            }];
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
                                        [self.containerViewController loadChildViewController];
                                    }
                                }
                            }];
            }
        }
    }
}

#pragma mark - Notification handlers

- (void)updateSelection:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kFetchingPreferencesChangedNotification]) {
        [[SuggestionsManager sharedManager] update];
    }
    
    [self configureNameLabel];
}

#pragma mark - Private methods

- (void)configureNameLabel
{
    // Check if there's a preferred suggestion.
    // If not, fetch a random suggestion.
    self.currentSuggestion = [[SuggestionsManager sharedManager] preferredSuggestion];
    if (!self.currentSuggestion) {
        self.currentSuggestion = [[SuggestionsManager sharedManager] randomSuggestion];
    }
    
    self.nameLabel.text = self.currentSuggestion.name;
    self.nameLabel.center = self.panningOrigin;
    
    // Disable panning if the suggestion received by the data source is the preferred one.
    self.panningEnabled = (self.currentSuggestion.state == kSelectionStatePreferred) ? NO : YES;

    [UIView animateWithDuration:0.1
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
    [self.animator removeAllBehaviors];

    self.panningEnabled = YES;

    if (self.panningState != kPanningStateIdle) {
        [self configureNameLabel];
    }
}

@end
