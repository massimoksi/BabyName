//
//  AboutTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 09/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AboutTableViewController.h"


@interface AboutTableViewController ()

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end


@implementation AboutTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"About: version."), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
