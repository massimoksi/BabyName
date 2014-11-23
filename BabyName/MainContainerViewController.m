//
//  MainContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainContainerViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "SelectionViewController.h"
#import "FinishedViewController.h"


static NSString * const kShowSelectionSegueID = @"ShowSelectionSegue";
static NSString * const kShowFinishedSegueID  = @"ShowFinishedSegue";


@interface MainContainerViewController ()

@property (nonatomic, strong) NSMutableArray *suggestions;

@end


@implementation MainContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.panningEnabled = YES;
    
    [self loadChildViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kShowSelectionSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[SelectionViewController class]]) {
                SelectionViewController *viewController = segue.destinationViewController;
                viewController.containerViewController = self;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            SelectionViewController *viewController = segue.destinationViewController;
            viewController.containerViewController = self;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:kShowFinishedSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[FinishedViewController class]]) {
                FinishedViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            FinishedViewController *viewController = segue.destinationViewController;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
}

#pragma mark - Private methods

// TODO: move to selection view controller.
- (void)validatePreferredSuggestion
{
    NSError *error;
    BOOL invalid = false;

    // If the array of fetched suggestions contains only 1 element, it is "safe enough" to consider it as the preferred one.
    //  1. Check gender and languages.
    //  2. Check initials if gender and languages are matching.
    //  3. Unprefer the suggestion if none at least one of the criteria is not matching.
    if (self.suggestions.count == 1) {
        Suggestion *preferredSuggestion = [self.suggestions objectAtIndex:0];

        // Get preferences from user defaults.
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
        NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

        if ((preferredSuggestion.gender & genders) && (preferredSuggestion.language & languages)) {
            NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
            if (initials) {
                for (NSString *initial in initials) {
                    if ([preferredSuggestion.initial isEqualToString:initial]) {
                        invalid = NO;
                        break;
                    }
                    else {
                        invalid = YES;
                    }
                }
            }
        }
        else {
            invalid = YES;
        }

        if (invalid) {
            preferredSuggestion.state = kSelectionStateAccepted;
            if (![self.managedObjectContext save:&error]) {
                [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectWasUnpreferredNotification
                                                                    object:self];
            }
        }
    }
}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    [self addChildViewController:toViewController];
    [fromViewController willMoveToParentViewController:nil];
    
    [self transitionFromViewController:fromViewController
                      toViewController:toViewController
                              duration:0.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:nil
                            completion:^(BOOL finished){
                                [toViewController didMoveToParentViewController:self];
                                [fromViewController removeFromParentViewController];
                            }];
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

#pragma mark - Container view controller

- (void)loadChildViewController
{
    if ([[SuggestionsManager sharedManager] fetchedSuggestions].count) {
        [self performSegueWithIdentifier:kShowSelectionSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kShowFinishedSegueID
                                  sender:self];
    }
}

@end
