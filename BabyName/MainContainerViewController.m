//
//  MainContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainContainerViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "SelectionViewController.h"
#import "FinishedViewController.h"


static NSString * const kShowSelectionSegueID = @"ShowSelectionSegue";
static NSString * const kShowFinishedSegueID  = @"ShowFinishedSegue";


@interface MainContainerViewController ()

@property (nonatomic, strong) NSMutableArray *suggestions;

@end


@implementation MainContainerViewController

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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kShowSelectionSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[SelectionViewController class]]) {
                SelectionViewController *viewController = segue.destinationViewController;
                viewController.containerViewController = self;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            SelectionViewController *viewController = segue.destinationViewController;
            viewController.containerViewController = self;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:kShowFinishedSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[FinishedViewController class]]) {
                FinishedViewController *viewController = segue.destinationViewController;
                
                [self swapFromViewController:self.childViewControllers.firstObject
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
    if ([[SuggestionsManager sharedManager] fetchedSuggestions].count) {
        [self performSegueWithIdentifier:kShowSelectionSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kShowFinishedSegueID
                                  sender:self];
    }
}

@end
