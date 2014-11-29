//
//  TutorialPageViewController.m
//  BabyName
//
//  Created by Massimo Peri on 27/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "TutorialPageViewController.h"

#import "Constants.h"
#import "PageViewController.h"


@interface TutorialPageViewController ()

@property (nonatomic, strong) NSArray *pageIdentifiers;

@end


@implementation TutorialPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *backgroundGradientLayer = [CAGradientLayer layer];
    backgroundGradientLayer.frame = self.view.bounds;
    backgroundGradientLayer.colors = @[(id)[UIColor colorWithRed:163.0/255.0 green:216.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor,
                                       (id)[UIColor colorWithRed:56.0/255.0  green:171.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor,
                                       (id)[UIColor colorWithRed:134.0/255.0 green:37.0/255.0  blue:224.0/255.0 alpha:1.0].CGColor,
                                       (id)[UIColor colorWithRed:255.0/255.0 green:113.0/255.0 blue:149.0/255.0 alpha:1.0].CGColor,
                                       (id)[UIColor colorWithRed:255.0/255.0 green:186.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor];
    [self.view.layer insertSublayer:backgroundGradientLayer
                            atIndex:0];
    self.view.layer.masksToBounds = YES;

    
    self.dataSource = self;
    
    self.pageIdentifiers = @[@"Page1VC", @"Page2VC", @"Page3VC", @"Page4VC", @"Page5VC", @"Page6VC"];
    
    PageViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.pageIdentifiers.firstObject];
    [self setViewControllers:@[pageViewController]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:YES
                  completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)completeTutorial
{
    [[NSUserDefaults standardUserDefaults] setBool:YES
                                            forKey:kSettingsTutorialCompletedKey];
    
    [self.containerViewController loadChildViewController];
}

#pragma mark - Private methods

- (PageViewController *)viewControllerAtIndex:(NSUInteger)index
{
    PageViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:self.pageIdentifiers[index]];
    viewController.index = index;
    
    return viewController;
}

#pragma mark - Page view controller data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageViewController *)viewController).index;
    if (index == 0) {
        return nil;
    }
    
    index--;
    
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageViewController *)viewController).index;
    if (index == self.pageIdentifiers.count - 1) {
        return nil;
    }
    
    index++;
    
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.pageIdentifiers.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

#pragma mark - Embedded view controller

@synthesize containerViewController;

@end
