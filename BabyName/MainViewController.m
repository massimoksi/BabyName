//
//  MainViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainViewController.h"

#import "Constants.h"
#import "Suggestion.h"
#import "MainContainerViewController.h"
#import "SettingsTableViewController.h"
#import "SearchNameTableViewController.h"


@interface MainViewController () <UIDynamicAnimatorDelegate, SettingsTableViewControllerDelegate>

@property (nonatomic, strong) MainContainerViewController *containerViewController; // TODO: check if this property should be strong or weak.

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    
    if ([segue.identifier isEqualToString:@"EmbedContainerSegue"]) {
        self.containerViewController = [segue destinationViewController];
        self.containerViewController.managedObjectContext = self.managedObjectContext;
    }
    else if ([segue.identifier isEqualToString:@"SettingsSegue"]) {   // TODO: rename segue.
        UINavigationController *settingsNavController = [segue destinationViewController];
        SettingsTableViewController *settingsViewController = (SettingsTableViewController *)settingsNavController.topViewController;
        settingsViewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"ShowSearchNameSegue"]) {
        UINavigationController *searchNameNavController = [segue destinationViewController];
        SearchNameTableViewController *searchNameViewController = (SearchNameTableViewController *)searchNameNavController.topViewController;
        searchNameViewController.managedObjectContext = self.managedObjectContext;
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

#pragma mark - Dynamics drawer view controller delegate

- (BOOL)dynamicsDrawerViewController:(MSDynamicsDrawerViewController *)drawerViewController shouldBeginPanePan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    // Inhibit pane pan while animating selection.
    return self.containerViewController.panningEnabled;
}

#pragma mark - Settings view controller delegate

- (void)settingsViewControllerWillClose:(BOOL)updated
{
    if (updated) {
        [self.containerViewController updateSuggestions];
    }
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)resetAllSelections
{
    NSPersistentStoreCoordinator *coordinator = [self.managedObjectContext persistentStoreCoordinator];
    
    // Retrieve the address of the persistent store.
    NSURL *storeURL = [coordinator URLForPersistentStore:[[coordinator persistentStores] lastObject]];
    
    // Drop pending changes.
    [self.managedObjectContext reset];
    
    NSError *error;
    if ([coordinator removePersistentStore:[[[self.managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]
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
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
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
