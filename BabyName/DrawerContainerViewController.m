//
//  DrawerContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 30/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "DrawerContainerViewController.h"

#import "Constants.h"
#import "EmptyNamesViewController.h"
#import "AcceptedNamesViewController.h"


static NSString * const kEmptyNamesSegueID    = @"EmptyNamesSegue";
static NSString * const kAcceptedNamesSegueID = @"AcceptedNamesSegue";


@interface DrawerContainerViewController ()

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

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    // Get new preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    
    // Fetch all suggestions with state "maybe" and  matching the criteria from preferences.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateAccepted, genders, languages];
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
            
            // Filter the found elements by preferred initials.
            self.acceptedNames = [NSMutableArray arrayWithArray:[fetchedSuggestions filteredArrayUsingPredicate:initialsPredicate]];
        }
        else {
            // No element meeting the request predicate, create a new empty array.
            self.acceptedNames = [NSMutableArray arrayWithArray:fetchedSuggestions];
        }
        
        if (self.acceptedNames.count == 0) {
            [self performSegueWithIdentifier:kEmptyNamesSegueID
                                      sender:self];
        }
        else {
            [self performSegueWithIdentifier:kAcceptedNamesSegueID
                                      sender:self];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if (self.childViewControllers.count != 0) {
        [[self.childViewControllers objectAtIndex:0] removeFromParentViewController];
    }
        
    if ([[segue identifier] isEqualToString:kEmptyNamesSegueID]) {
        EmptyNamesViewController *viewController = segue.destinationViewController;
        
        [self addChildViewController:viewController];
        [self.view addSubview:viewController.view];
        [viewController didMoveToParentViewController:self];
    }
    else if ([[segue identifier] isEqualToString:kAcceptedNamesSegueID]) {
        AcceptedNamesViewController *viewController = segue.destinationViewController;
        viewController.managedObjectContext = self.managedObjectContext;
        viewController.acceptedNames = self.acceptedNames;
        
        [self addChildViewController:viewController];
        [self.view addSubview:viewController.view];
        [viewController didMoveToParentViewController:self];
    }
}

@end
