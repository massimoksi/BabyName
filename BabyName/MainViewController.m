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
#import "SearchNameTableViewController.h"

// TODO: get rid of tweaks.
#if DEBUG
    #import "TweaksTableViewController.h"
#endif  


@interface MainViewController () <UIDynamicAnimatorDelegate, SettingsTableViewControllerDelegate, PresentingDelegate>

@property (nonatomic, strong) MainContainerViewController *containerViewController; // TODO: check if this property should be strong or weak.

@property (nonatomic, weak) IBOutlet UIButton *settingsButton;

@property (nonatomic, strong) CAGradientLayer *genericBackgroundLayer;

#if DEBUG
@property (nonatomic, strong) NSArray *cyanShades;
@property (nonatomic, strong) NSArray *pinkShades;
#endif

@end


@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.genericBackgroundLayer = [CAGradientLayer layer];
    
#if DEBUG
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(showTweaks:)];
    [self.settingsButton addGestureRecognizer:longPress];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

#if DEBUG
    self.cyanShades = @[
        [UIColor colorWithRed:163.0/255.0 green:216.0/255.0 blue:255.0/255.0 alpha:1.0],
        [UIColor colorWithRed:216.0/255.0 green:232.0/255.0 blue:255.0/255.0 alpha:1.0],
        [UIColor colorWithRed:211.0/255.0 green:217.0/255.0 blue:255.0/255.0 alpha:1.0],
        [UIColor colorWithRed:201.0/255.0 green:222.0/255.0 blue:255.0/255.0 alpha:1.0]
    ];
    
    self.pinkShades = @[
        [UIColor colorWithRed:255.0/255.0 green:221.0/255.0 blue:252.0/255.0 alpha:1.0],
        [UIColor colorWithRed:255.0/255.0 green:196.0/255.0 blue:224.0/255.0 alpha:1.0],
        [UIColor colorWithRed:255.0/255.0 green:186.0/255.0 blue:230.0/255.0 alpha:1.0],
        [UIColor colorWithRed:255.0/255.0 green:216.0/255.0 blue:251.0/255.0 alpha:1.0]
    ];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger gender = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger selectedCyan = [userDefaults integerForKey:kTweaksCyanShadeKey];
    NSInteger selectedPink = [userDefaults integerForKey:kTweaksPinkShadeKey];

    // Create the gradient layer for the background.
    self.genericBackgroundLayer.frame = self.view.bounds;
    self.genericBackgroundLayer.colors = @[
        (id)((UIColor *)self.cyanShades[selectedCyan]).CGColor,
        (id)((UIColor *)self.pinkShades[selectedPink]).CGColor
    ];
    // Remove the gradient layer if already present.
    if ([self.view.layer.sublayers objectAtIndex:0] == self.genericBackgroundLayer) {
        [self.genericBackgroundLayer removeFromSuperlayer];
    }

    if (gender == kGenderBitmaskMale) {
        self.view.backgroundColor = self.cyanShades[selectedCyan];
    }
    else if (gender == kGenderBitmaskFemale) {
        self.view.backgroundColor = self.pinkShades[selectedPink];
    }
    else {
        self.view.backgroundColor = [UIColor lightGrayColor];

        [self.view.layer insertSublayer:self.genericBackgroundLayer
                                atIndex:0];
        self.view.layer.masksToBounds = YES;
    }
#endif
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
    else if ([segue.identifier isEqualToString:@"SettingsSegue"]) {   // TODO: rename segue.
        UINavigationController *settingsNavController = [segue destinationViewController];
        SettingsTableViewController *settingsViewController = (SettingsTableViewController *)settingsNavController.topViewController;
        settingsViewController.delegate = self;
        settingsViewController.presentingDelegate = self;
    }
    else if ([segue.identifier isEqualToString:@"ShowSearchNameSegue"]) {
        UINavigationController *searchNameNavController = [segue destinationViewController];
        SearchNameTableViewController *searchNameViewController = (SearchNameTableViewController *)searchNameNavController.topViewController;
        searchNameViewController.managedObjectContext = self.managedObjectContext;
        searchNameViewController.presentingDelegate = self;
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

#if DEBUG
- (void)showTweaks:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        TweaksTableViewController *tweaksController = [[TweaksTableViewController alloc] init];
        tweaksController.presentingDelegate = self;

        UINavigationController *tweaksNavController = [[UINavigationController alloc] initWithRootViewController:tweaksController];
        [self presentViewController:tweaksNavController
                           animated:YES
                         completion:nil];
    }
}
#endif

#pragma mark - Private methods

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

#pragma mark - Dynamics drawer view controller delegate

- (BOOL)dynamicsDrawerViewController:(MSDynamicsDrawerViewController *)drawerViewController shouldBeginPanePan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    // Inhibit pane pan while animating selection.
    return self.containerViewController.panningEnabled;
}

#pragma mark - Settings view controller delegate

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
            [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
        }
        
        // Re-load the persistent store.
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                       configuration:nil
                                                 URL:storeURL
                                             options:nil
                                               error:&error]) {
            [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
        }
    }
    else {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
    }
}

#pragma mark - Presenting delegate

- (void)presentedViewControllerWillClose:(BOOL)updated
{
    if (updated) {
        [self.containerViewController updateSuggestions];
    }
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
