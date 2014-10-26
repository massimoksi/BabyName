//
//  DrawerContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 30/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "DrawerContainerViewController.h"

#import "Constants.h"
#import "Suggestion.h"
#import "EmptyNamesViewController.h"
#import "AcceptedNamesViewController.h"


static NSString * const kShowEmptyNamesSegueID    = @"ShowEmptyNamesSegue";
static NSString * const kShowAcceptedNamesSegueID = @"ShowAcceptedNamesSegue";


@interface DrawerContainerViewController () <AcceptedNamesViewDataSource>

@property (nonatomic) BOOL visible;

@property (nonatomic, strong) NSMutableArray *acceptedNames;

@end


@implementation DrawerContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.visible = YES;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Get preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    
    // Fetch all suggestions with state "maybe" and  matching the criteria from preferences.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state >= %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateAccepted, genders, languages];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray *fetchedSuggestions = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                           error:&error];
    if (!fetchedSuggestions) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
    }
    else {
        // Filter suggestions by preferred initials.
        NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
        if (initials.count) {
            NSString *initialsRegex = [NSString stringWithFormat:@"^[%@].*", [initials componentsJoinedByString:@""]];
            NSPredicate *initialsPredicate = [NSPredicate predicateWithFormat:@"name MATCHES[cd] %@", initialsRegex];
            
            // Filter the found elements by preferred initials.
            self.acceptedNames = [NSMutableArray arrayWithArray:[[fetchedSuggestions filteredArrayUsingPredicate:initialsPredicate] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"                                                                                                                                            ascending:YES                                                                                                                                             selector:@selector(caseInsensitiveCompare:)]]]];
        }
        else {
            // No element meeting the request predicate, create a new empty array.
            self.acceptedNames = [NSMutableArray arrayWithArray:[fetchedSuggestions sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                                                                                ascending:YES
                                                                                                                                                 selector:@selector(caseInsensitiveCompare:)]]]];
        }

        [self selectChildViewController];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    self.visible = NO;
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

    if ([[segue identifier] isEqualToString:kShowEmptyNamesSegueID]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[EmptyNamesViewController class]]) {
                EmptyNamesViewController *viewController = segue.destinationViewController;

                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
                            toViewController:viewController];
            }
        }
        else {
            EmptyNamesViewController *viewController = segue.destinationViewController;
        
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([[segue identifier] isEqualToString:kShowAcceptedNamesSegueID]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[AcceptedNamesViewController class]]) {
                AcceptedNamesViewController *viewController = segue.destinationViewController;
                viewController.dataSource = self;

                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
                            toViewController:viewController];
            }
        }
        else {
            AcceptedNamesViewController *viewController = segue.destinationViewController;
            viewController.dataSource = self;
        
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
}

#pragma mark - Private methods

- (void)selectChildViewController
{
    if (self.acceptedNames.count == 0) {
        // Load the view controller to handle empty state.
        [self performSegueWithIdentifier:kShowEmptyNamesSegueID
                                  sender:self];
    }
    else {
        // Load the view controller to handle the list of accepted names.
        [self performSegueWithIdentifier:kShowAcceptedNamesSegueID
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
                               options:(self.visible) ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone
                            animations:nil
                            completion:^(BOOL finished){
                                [toViewController didMoveToParentViewController:self];
                                [fromViewController removeFromParentViewController];
                            }];
}

- (NSUInteger)indexOfPreferredName
{
    NSPredicate *preferredPredicate = [NSPredicate predicateWithFormat:@"(state >= %d)", kSelectionStatePreferred];
    NSArray *preferredNames = [self.acceptedNames filteredArrayUsingPredicate:preferredPredicate];

    if (preferredNames.count == 0) {
        return NSNotFound;
    }
    else {
        Suggestion *preferredSuggestion = [preferredNames objectAtIndex:0];

        return [self.acceptedNames indexOfObject:preferredSuggestion];
    }
}

- (void)showAlertWithMessage:(NSString *)message
{
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
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
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];

        [alertView show];
    }
}

#pragma mark - Accepted names view data source

- (NSInteger)numberOfAcceptedNames
{
    return self.acceptedNames.count;
}

- (id)acceptedNameAtIndex:(NSUInteger)index
{
    return [self.acceptedNames objectAtIndex:index];
}

- (BOOL)removeAcceptedNameAtIndex:(NSUInteger)index
{
    Suggestion *suggestion = [self.acceptedNames objectAtIndex:index];
    suggestion.state = kSelectionStateRejected;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];

        return NO;
    }
    else {
        [self.acceptedNames removeObjectAtIndex:index];
        
        return YES;
    }
}

- (BOOL)preferAcceptedNameAtIndex:(NSUInteger)index
{
    Suggestion *suggestion = [self.acceptedNames objectAtIndex:index];

    NSUInteger preferredIndex = [self indexOfPreferredName];
    if (preferredIndex == NSNotFound) {
        suggestion.state = kSelectionStatePreferred;
    }
    else {
        if (index == preferredIndex) {
            // Name is already preferred, so unprefer it.
            suggestion.state = kSelectionStateAccepted;
        }
        else {
            // There is already a preferred name, un prefer it and prefer the new one.
            Suggestion *preferredSuggestion = [self.acceptedNames objectAtIndex:preferredIndex];
            preferredSuggestion.state = kSelectionStateAccepted;

            suggestion.state = kSelectionStatePreferred;
        }
    }

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];

        return NO;
    }
    else {
        return YES;
    }
}

@end
