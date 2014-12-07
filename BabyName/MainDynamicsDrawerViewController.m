//
//  MainDynamicsDrawerViewController.m
//  BabyName
//
//  Created by Massimo Peri on 27/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "MainDynamicsDrawerViewController.h"

#import "PaneViewController.h"
#import "ReviewViewController.h"


@implementation MainDynamicsDrawerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.shouldAlignStatusBarToPaneView = NO;
    self.paneDragRequiresScreenEdgePan = YES;
    [self registerTouchForwardingClass:[UILabel class]];

    PaneViewController *paneViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PaneVC"];
    paneViewController.drawerViewController = self;
    self.paneViewController = paneViewController;

    ReviewViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ReviewVC"];
    [self setDrawerViewController:viewController
                     forDirection:MSDynamicsDrawerDirectionRight];
    [self setRevealWidth:CGRectGetWidth(self.view.frame) - 44.0
            forDirection:MSDynamicsDrawerDirectionRight];
    [self addStylersFromArray:@[[MSDynamicsDrawerFadeStyler styler], [MSDynamicsDrawerParallaxStyler styler]]
                 forDirection:MSDynamicsDrawerDirectionRight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
