//
//  RootViewController.m
//  BabyName
//
//  Created by Massimo Peri on 27/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "RootViewController.h"

#import "Constants.h"
#import "TutorialPageViewController.h"
#import "MainDynamicsDrawerViewController.h"


static NSString * const kShowTutorialSegueID = @"ShowTutorialSegue";
static NSString * const kShowMainSegueID     = @"ShowMainSegue";


@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self loadChildViewController];
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
    if ([segue.identifier isEqualToString:kShowMainSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[MainDynamicsDrawerViewController class]]) {
                MainDynamicsDrawerViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            MainDynamicsDrawerViewController *viewController = segue.destinationViewController;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:kShowTutorialSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[TutorialPageViewController class]]) {
                TutorialPageViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            TutorialPageViewController *viewController = segue.destinationViewController;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
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

#pragma mark - Container view controller

- (void)loadChildViewController
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kSettingsTutorialCompletedKey]) {
        [self performSegueWithIdentifier:kShowTutorialSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kShowMainSegueID
                                  sender:self];
    }
}

@end
