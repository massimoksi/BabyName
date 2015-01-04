//
//  PaneContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "PaneContainerViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "SelectionViewController.h"
#import "FinishedViewController.h"


static NSString * const kShowSelectionSegueID = @"ShowSelectionSegue";
static NSString * const kShowFinishedSegueID  = @"ShowFinishedSegue";


@interface PaneContainerViewController ()

@property (nonatomic, strong) NSMutableArray *suggestions;

@end


@implementation PaneContainerViewController

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
                viewController.view.frame = self.view.frame;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            SelectionViewController *viewController = segue.destinationViewController;
            viewController.containerViewController = self;
            viewController.view.frame = self.view.frame;
            
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([segue.identifier isEqualToString:kShowFinishedSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[FinishedViewController class]]) {
                FinishedViewController *viewController = segue.destinationViewController;
                viewController.containerViewController = self;
                viewController.drawerViewController = self.drawerViewController;
                viewController.view.frame = self.view.frame;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            FinishedViewController *viewController = segue.destinationViewController;
            viewController.containerViewController = self;
            viewController.drawerViewController = self.drawerViewController;
            viewController.view.frame = self.view.frame;
            
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
    SuggestionsManager *manager = [SuggestionsManager sharedManager];
    if (([manager availableSuggestions].count) ||
        ([manager preferredSuggestion]) ||
        (([[NSUserDefaults standardUserDefaults] boolForKey:kStateReviewAcceptedNamesKey]) && ([manager acceptedSuggestions].count))) {
        [self performSegueWithIdentifier:kShowSelectionSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kShowFinishedSegueID
                                  sender:self];
    }
}

@end
