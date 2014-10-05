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
    
    if ([segue.identifier isEqualToString:kShowSelectionSegueID]) {
        if (self.childViewControllers.count != 0) {
            if (![[self.childViewControllers objectAtIndex:0] isKindOfClass:[SelectionViewController class]]) {
                SelectionViewController *viewController = segue.destinationViewController;
                viewController.dataSource = self;
                viewController.delegate = self;
                
                [self swapFromViewController:[self.childViewControllers objectAtIndex:0]
                            toViewController:viewController];
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

        self.updateSelection = YES;
        [self loadChildViewController];
    }
}

#pragma mark - Private methods

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

#pragma mark - Selection view data source

- (BOOL)shouldReloadName
{
    return self.updateSelection;
}

- (NSString *)randomName
{
    self.currentIndex = arc4random() % self.suggestions.count;
    Suggestion *currentSuggestion = [self.suggestions objectAtIndex:self.currentIndex];
    
    self.updateSelection = NO;
    
    return currentSuggestion.name;
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
        // TODO: handle error.
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
        // TODO: handle error.
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
