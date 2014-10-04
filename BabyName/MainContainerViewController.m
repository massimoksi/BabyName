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


@interface MainContainerViewController () <SelectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *suggestions;
@property (nonatomic) NSUInteger currentIndex;

@end


@implementation MainContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self updateSuggestions];
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
    
    if ([segue.identifier isEqualToString:@"ShowSelectionSegue"]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[SelectionViewController class]]) {
                SelectionViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
                            toViewController:viewController];
            }
        }
        else {
            SelectionViewController *viewController = segue.destinationViewController;
            viewController.dataSource = self;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
}

#pragma mark - Actions

- (void)updateSuggestions
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Fetch all suggestions with state "maybe" and  matching the criteria from preferences.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateMaybe, genders, languages];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray *fetchedSuggestions = [NSMutableArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest
                                                                                                          error:&error]];
    if (!fetchedSuggestions) {
        // TODO: handle the error.
    }
    else {
        // Filter suggestions by preferred initials.
        NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
        if (initials.count) {
            NSString *initialsRegex = [NSString stringWithFormat:@"^[%@].*", [initials componentsJoinedByString:@""]];
            NSPredicate *initialsPredicate = [NSPredicate predicateWithFormat:@"name MATCHES[cd] %@", initialsRegex];
            
            self.suggestions = [NSMutableArray arrayWithArray:[fetchedSuggestions filteredArrayUsingPredicate:initialsPredicate]];
        }
        else {
            self.suggestions = [NSMutableArray arrayWithArray:fetchedSuggestions];
        }

        // TODO: move somewhere else.
        if (self.suggestions.count) {
            [self performSegueWithIdentifier:@"ShowSelectionSegue"
                                      sender:self];
        }
    }
}

#pragma mark - Private methods

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

#pragma mark - Selection view data source

- (NSString *)randomName
{
    self.currentIndex = arc4random() % self.suggestions.count;
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    
    return currentSuggestion.name;
}

- (void)acceptName
{
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    currentSuggestion.state = kSelectionStateAccepted;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
#if DEBUG
        NSLog(@"Accepted: %@", currentSuggestion.name);
#endif
        
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
    }
}

- (void)rejectName
{
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    currentSuggestion.state = kSelectionStateRejected;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // TODO: handle error.
    }
    else {
#if DEBUG
        NSLog(@"Rejected: %@", currentSuggestion.name);
#endif
        
        // Remove the current suggestion from the array.
        [self.suggestions removeObjectAtIndex:self.currentIndex];
    }
}

@end
