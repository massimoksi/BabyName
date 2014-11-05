//
//  InitialsTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 25/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "InitialsTableViewController.h"

#import "Constants.h"
#import "SettingsTableViewController.h"


@interface InitialsTableViewController ()

@property (nonatomic, strong) NSArray *initials;
@property (nonatomic, strong) NSMutableArray *preferredInitials;

@end


@implementation InitialsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.initials = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    
    // Get preferred initials from user defaults.
    NSArray *prefInitials = [[NSUserDefaults standardUserDefaults] stringArrayForKey:kSettingsPreferredInitialsKey];
    if (prefInitials) {
        self.preferredInitials = [NSMutableArray arrayWithArray:prefInitials];
    }
    else {
        self.preferredInitials = [NSMutableArray array];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.initials.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InitialCell"];
    
    NSString *initial = [self.initials objectAtIndex:indexPath.row];
    cell.textLabel.text = initial;
    cell.accessoryType = ([self.preferredInitials containsObject:initial]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *selectedInitial = [self.initials objectAtIndex:indexPath.row];
    NSUInteger selectedIndex = [self.preferredInitials indexOfObject:selectedInitial];
    if (selectedIndex == NSNotFound) {
        // Add selected initial.
        [self.preferredInitials addObject:selectedInitial];
    }
    else {
        // Remove selected inital.
        [self.preferredInitials removeObjectAtIndex:selectedIndex];
    }
    
    // Update user defaults.
    [[NSUserDefaults standardUserDefaults] setObject:self.preferredInitials
                                              forKey:kSettingsPreferredInitialsKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectionPreferencesChangedNotification
                                                        object:self];
    
    // Update table view.
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    [tableView reloadData];
}

@end
