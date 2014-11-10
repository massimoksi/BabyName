//
//  MainContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainContainerViewController.h"

#import "Constants.h"
#import "Suggestion.h"
#import "SelectionViewController.h"
#import "FinishedViewController.h"


static NSString * const kShowSelectionSegueID = @"ShowSelectionSegue";
static NSString * const kShowFinishedSegueID  = @"ShowFinishedSegue";


@interface MainContainerViewController () <SelectionViewDataSource, SelectionViewDelegate>

@property (nonatomic, strong) NSMutableArray *suggestions;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) BOOL updateSelection;

@end


@implementation MainContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.panningEnabled = YES;
    
    [self fetchSuggestions];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(updateSuggestions:)
                               name:kFetchedObjectsOutdatedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(updateSuggestions:)
                               name:kFetchedObjectWasPreferredNotification
                             object:nil];
    [notificationCenter addObserver:self
                       selector:@selector(updateSuggestions:)
                           name:kFetchedObjectWasUnpreferredNotification
                         object:nil];
    [notificationCenter addObserver:self
                       selector:@selector(updateSuggestions:)
                           name:kFetchingPreferencesChangedNotification
                         object:nil];
}

- (void)dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:kFetchedObjectsOutdatedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kFetchedObjectWasPreferredNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kFetchedObjectWasUnpreferredNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:kFetchingPreferencesChangedNotification
                                object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:kShowSelectionSegueID]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[SelectionViewController class]]) {
                SelectionViewController *viewController = segue.destinationViewController;
                viewController.dataSource = self;
                viewController.delegate = self;

                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
                            toViewController:viewController];
            }
            else {
                SelectionViewController *viewController = [self.childViewControllers objectAtIndex:0];
                if (self.updateSelection) {
                    [viewController configureNameLabel];
                }
            }
        }
        else {
            SelectionViewController *viewController = segue.destinationViewController;
            viewController.dataSource = self;
            viewController.delegate = self;

            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:kShowFinishedSegueID]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[FinishedViewController class]]) {
                FinishedViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
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

#pragma mark - Notification handlers

- (void)updateSuggestions:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kFetchingPreferencesChangedNotification]) {
        [self validatePreferredSuggestion];
    }

    [self fetchSuggestions];
}

#pragma mark - Private methods

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
        }
    }
}

- (void)fetchSuggestions
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSError *error;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:@"Suggestion"
                                      inManagedObjectContext:context];

    // Check if a preferred name already exists.
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"state == %d", kSelectionStatePreferred];
    NSArray *fetchedSuggestions = [context executeFetchRequest:fetchRequest
                                                         error:&error];
    if (fetchedSuggestions) {
        // The database contains a preferred suggestion.
        //  -> Create the array of suggestions with only the preferred one.
        if (fetchedSuggestions.count == 1) {
            self.suggestions = [NSMutableArray arrayWithArray:fetchedSuggestions];
        }
        // The database doesn't contain a preferred suggestion.
        //  -> Fetch all available suggestions for selection.
        else {
            // Get search criteria from user defaults.
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
            NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

            // Fetch all available suggestions for selection.
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateMaybe, genders, languages];
            fetchedSuggestions = [context executeFetchRequest:fetchRequest
                                                        error:&error];
            if (!fetchedSuggestions) {
                [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
            }
            else {
                // Filter suggestions by initials from user defaults.
                NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
                if (initials.count) {
                    NSString *initialsRegex = [NSString stringWithFormat:@"^[%@].*", [initials componentsJoinedByString:@""]];
                    NSPredicate *initialsPredicate = [NSPredicate predicateWithFormat:@"name MATCHES[cd] %@", initialsRegex];
                    
                    self.suggestions = [NSMutableArray arrayWithArray:[fetchedSuggestions filteredArrayUsingPredicate:initialsPredicate]];
                }
                else {
                    self.suggestions = [NSMutableArray arrayWithArray:fetchedSuggestions];
                }
            }
        }

#if DEBUG
        NSLog(@"Available names: %tu", self.suggestions.count);
#endif
        
        self.updateSelection = YES;
        [self loadChildViewController];
    }
    else {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
}

- (void)loadChildViewController
{
    if (self.suggestions.count) {
        [self performSegueWithIdentifier:kShowSelectionSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kShowFinishedSegueID
                                  sender:self];
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
                                                        handler:^(UIAlertAction *action){
                                                            // Dismiss alert controller.
                                                            [alertController dismissViewControllerAnimated:YES
                                                                                                completion:nil]; 
                                                        }];
    [alertController addAction:acceptAction];

    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark - Selection view data source

- (BOOL)shouldReloadName
{
    return self.updateSelection;
}

- (Suggestion *)randomSuggestion
{
    if (self.suggestions.count == 1) {
        self.currentIndex = 0;
    }
    else {
        self.currentIndex = arc4random() % self.suggestions.count;
    }
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
#ifdef DEBUG
    NSLog(@"Current name: %@", currentSuggestion.name);
#endif
    
    self.updateSelection = NO;
    
    return currentSuggestion;
}

#pragma mark - Selection view delegate

- (void)selectionViewDidBeginPanning
{
    self.panningEnabled = NO;
}

- (void)selectionViewDidEndPanning
{
    self.panningEnabled = YES;
}

- (void)acceptName
{
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    currentSuggestion.state = kSelectionStateAccepted;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
    else {
#if DEBUG
        NSLog(@"Accepted: %@", currentSuggestion.name);
#endif
        
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
        if (self.suggestions.count == 0) {
            [self performSegueWithIdentifier:kShowFinishedSegueID
                                      sender:self];
        }
    }
}

- (void)rejectName
{
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    currentSuggestion.state = kSelectionStateRejected;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
    else {
#if DEBUG
        NSLog(@"Rejected: %@", currentSuggestion.name);
#endif
        
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
        if (self.suggestions.count == 0) {
            [self performSegueWithIdentifier:kShowFinishedSegueID
                                      sender:self];
        }
    }
}

@end
