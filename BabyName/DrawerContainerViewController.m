//
//  DrawerContainerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 30/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "DrawerContainerViewController.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "EmptyViewController.h"
#import "AcceptedTableViewController.h"


static NSString * const kContainEmptySegueID    = @"ContainEmptySegue";
static NSString * const kContainAcceptedSegueID = @"ContainAcceptedSegue";


@interface DrawerContainerViewController ()

@property (nonatomic) BOOL visible;

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
    
    self.visible = YES;
    [self loadChildViewController];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    self.visible = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    if ([[segue identifier] isEqualToString:kContainEmptySegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[EmptyViewController class]]) {
                EmptyViewController *viewController = segue.destinationViewController;

                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            EmptyViewController *viewController = segue.destinationViewController;
        
            [self addChildViewController:viewController];
            [self.view addSubview:viewController.view];
            [viewController didMoveToParentViewController:self];
        }
    }
    else if ([[segue identifier] isEqualToString:kContainAcceptedSegueID]) {
        if (self.childViewControllers.count) {
            if (![self.childViewControllers.firstObject isKindOfClass:[AcceptedTableViewController class]]) {
                AcceptedTableViewController *viewController = segue.destinationViewController;
                viewController.containerViewController = self;
                
                [self swapFromViewController:self.childViewControllers.firstObject
                            toViewController:viewController];
            }
        }
        else {
            AcceptedTableViewController *viewController = segue.destinationViewController;
            viewController.containerViewController = self;

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
                               options:(self.visible) ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone
                            animations:nil
                            completion:^(BOOL finished){
                                [toViewController didMoveToParentViewController:self];
                                [fromViewController removeFromParentViewController];
                            }];
}

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Alert: title.")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert: accept button.")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil];
    [alertController addAction:acceptAction];

    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark - Container view controller

- (void)loadChildViewController
{
    // Load the contained view controller depending on the number of accepted suggestions.
    if ([[SuggestionsManager sharedManager] acceptedSuggestions].count) {
        [self performSegueWithIdentifier:kContainAcceptedSegueID
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:kContainEmptySegueID
                                  sender:self];
    }
}

@end
