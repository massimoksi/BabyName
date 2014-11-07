//
//  MainViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Constants.h"
#import "Suggestion.h"
#import "MainContainerViewController.h"
#import "SettingsTableViewController.h"
#import "SearchTableViewController.h"


@interface MainViewController ()

@property (nonatomic, strong) MainContainerViewController *containerViewController;

@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.backgroundGradientLayer = [CAGradientLayer layer];
    self.backgroundGradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.backgroundGradientLayer
                            atIndex:0];
    self.view.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSInteger gender = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedGendersKey];
    if (gender == kGenderBitmaskMale) {
        self.backgroundGradientLayer.colors = @[(id)[UIColor colorWithRed:163.0/255.0 green:216.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:56.0/255.0  green:171.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor];
    }
    else if (gender == kGenderBitmaskFemale) {
        self.backgroundGradientLayer.colors = @[(id)[UIColor colorWithRed:255.0/255.0 green:186.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:255.0/255.0 green:113.0/255.0 blue:149.0/255.0 alpha:1.0].CGColor];
    }
    else {
        self.backgroundGradientLayer.colors = @[(id)[UIColor colorWithRed:163.0/255.0 green:216.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:56.0/255.0  green:171.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:255.0/255.0 green:113.0/255.0 blue:149.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:255.0/255.0 green:186.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"EmbedContainerSegue"]) {
        self.containerViewController = [segue destinationViewController];
        self.containerViewController.managedObjectContext = self.managedObjectContext;
    }
    else if ([segue.identifier isEqualToString:@"ShowSettingsSegue"]) {
        UINavigationController *settingsNavController = [segue destinationViewController];
        settingsNavController.navigationBar.barStyle = UIStatusBarStyleLightContent;
        
        SettingsTableViewController *settingsViewController = (SettingsTableViewController *)settingsNavController.topViewController;
        settingsViewController.managedObjectContext = self.managedObjectContext;
    }
    else if ([segue.identifier isEqualToString:@"ShowSearchSegue"]) {
        UINavigationController *searchNavController = [segue destinationViewController];
        searchNavController.navigationBar.barStyle = UIStatusBarStyleLightContent;
        
        SearchTableViewController *searchViewController = (SearchTableViewController *)searchNavController.topViewController;
        searchViewController.managedObjectContext = self.managedObjectContext;
    }
}

- (IBAction)unwindToMain:(UIStoryboardSegue *)segue
{
    // Unwind.
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

@end
