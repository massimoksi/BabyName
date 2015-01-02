//
//  FinishedViewController.m
//  BabyName
//
//  Created by Massimo Peri on 04/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "FinishedViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"


@implementation FinishedViewController

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
    
    // It's not possible to make the view transparent in Storyboard due to white labels.
    self.view.backgroundColor = [UIColor clearColor];
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
}

//#pragma mark - Navigation
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    // Get the new view controller using [segue destinationViewController].
//    // Pass the selected object to the new view controller.
//    
//    if ([segue.identifier isEqualToString:@"ShowSettingsSegue"]) {
//        UINavigationController *settingsNavController = [segue destinationViewController];
//        settingsNavController.navigationBar.barStyle = UIStatusBarStyleLightContent;
//    }
//}

#pragma mark - Actions

- (IBAction)reviewNames:(id)sender
{
    [self.drawerViewController setPaneState:MSDynamicsDrawerPaneStateOpen
                                inDirection:MSDynamicsDrawerDirectionRight
                                   animated:YES
                      allowUserInterruption:YES
                                 completion:nil];
}

- (IBAction)restartSelection:(id)sender
{
    if ([[SuggestionsManager sharedManager] shuffle]) {
        [self.containerViewController loadChildViewController];
    }
}

#pragma mark - Notification handlers

- (void)updateSelection:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kFetchingPreferencesChangedNotification]) {
        [[SuggestionsManager sharedManager] update];
    }
    
    [self.containerViewController loadChildViewController];
}

#pragma mark - Embedded view controller

@synthesize containerViewController;

@end
