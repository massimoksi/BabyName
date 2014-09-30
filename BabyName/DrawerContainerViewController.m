//
//  DrawerContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 30/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "DrawerContainerViewController.h"

#import "Constants.h"


@interface DrawerContainerViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end


@implementation DrawerContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self performSegueWithIdentifier:@"EmptyNamesSegue"
                              sender:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Get new preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

    // Fetch all suggestions with state "accepted" and  matching the criteria from preferences.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateAccepted, genders, languages];
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
#if DEBUG
        NSLog(@"[AcceptedNamesViewController] Error:");
        NSLog(@"    Error while fetching %@, %@", error, [error userInfo]);
#endif
        // TODO: handle error.
    }
    else {
        if (self.fetchedResultsController.fetchedObjects.count == 0) {
            [self performSegueWithIdentifier:@"EmptyNamesSegue"
                                      sender:self];
        }
        else {
            [self performSegueWithIdentifier:@"AcceptedNamesSegue"
                                      sender:self];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setFetchBatchSize:20];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"EmptyNamesSegue"]) {
        [self addChildViewController:segue.destinationViewController];
        UIView* destView = ((UIViewController *)segue.destinationViewController).view;
        destView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        destView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view addSubview:destView];
        [segue.destinationViewController didMoveToParentViewController:self];
    }
    else if ([[segue identifier] isEqualToString:@"AcceptedNamesSegue"]) {
        [self addChildViewController:segue.destinationViewController];
        UIView* destView = ((UIViewController *)segue.destinationViewController).view;
        destView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        destView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view addSubview:destView];
        [segue.destinationViewController didMoveToParentViewController:self];
    }
}

@end
