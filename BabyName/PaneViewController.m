//
//  PaneViewController.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "PaneViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Constants.h"
#import "SuggestionsManager.h"
#import "PaneContainerViewController.h"
#import "SettingsTableViewController.h"
#import "SearchTableViewController.h"


@interface PaneViewController ()

@property (nonatomic, strong) PaneContainerViewController *containerViewController;

@property (nonatomic, strong) CAGradientLayer *backgroundGradientLayer;

@property (nonatomic, weak) IBOutlet UIButton *listButton;

@end


@implementation PaneViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.backgroundGradientLayer = [CAGradientLayer layer];
    self.backgroundGradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.backgroundGradientLayer
                            atIndex:0];
    self.view.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateListButton:)
                                                 name:kPreferredSuggestionChangedNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateListButton:nil];
    
    // Update the background gradient according to the selected gender.
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
                                                (id)[UIColor colorWithRed:134.0/255.0 green:37.0/255.0  blue:224.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:255.0/255.0 green:113.0/255.0 blue:149.0/255.0 alpha:1.0].CGColor,
                                                (id)[UIColor colorWithRed:255.0/255.0 green:186.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPreferredSuggestionChangedNotification
                                                  object:nil];
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
    
    if ([segue.identifier isEqualToString:@"ShowSettingsSegue"]) {
        UINavigationController *settingsNavController = [segue destinationViewController];
        settingsNavController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    }
    else if ([segue.identifier isEqualToString:@"ShowSearchSegue"]) {
        UINavigationController *searchNavController = [segue destinationViewController];
        searchNavController.navigationBar.barStyle = UIStatusBarStyleLightContent;
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

- (IBAction)unwindToMain:(UIStoryboardSegue *)segue
{
    // Unwind.
}

#pragma mark - Notification handlers

- (void)updateListButton:(NSNotification *)notification
{
    if ([[SuggestionsManager sharedManager] preferredSuggestion]) {
        [self.listButton setImage:[UIImage imageNamed:@"ListPreferred"]
                         forState:UIControlStateNormal];
    }
    else {
        [self.listButton setImage:[UIImage imageNamed:@"List"]
                         forState:UIControlStateNormal];
    }
}

@end
