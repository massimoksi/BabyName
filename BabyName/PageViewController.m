//
//  PageViewController.m
//  BabyName
//
//  Created by Massimo Peri on 27/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "PageViewController.h"

#import "TutorialPageViewController.h"


@implementation PageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // It's not possible to make the view transparent in Storyboard because of the use of white labels.
    self.view.backgroundColor = [UIColor clearColor];
}

#pragma mark - Actions

- (IBAction)getStarted:(id)sender
{
    TutorialPageViewController *pageViewController = (TutorialPageViewController *)self.parentViewController;
    
    [pageViewController completeTutorial];
}

@end
