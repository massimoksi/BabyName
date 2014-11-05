//
//  GendersTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "GendersTableViewController.h"

#import "Constants.h"
#import "SettingsTableViewController.h"


@interface GendersTableViewController ()

@property (nonatomic) NSInteger gender;

@end


@implementation GendersTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.gender = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedGendersKey] - 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    
    cell.accessoryType = (indexPath.row == self.gender) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Update user settings.
    self.gender = indexPath.row;
    [[NSUserDefaults standardUserDefaults] setInteger:(self.gender + 1)
                                               forKey:kSettingsSelectedGendersKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectionPreferencesChangedNotification
                                                        object:self];
    
    // Update table view.
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    [tableView reloadData];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
