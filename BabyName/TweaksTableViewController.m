//
//  TweaksTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 15/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "TweaksTableViewController.h"

#import "Constants.h"


@interface TweaksTableViewController ()

@end


@implementation TweaksTableViewController

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.title = @"Tweaks";

    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(closeSettings:)];
    self.navigationItem.rightBarButtonItem = closeBarButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Actions

- (IBAction)closeSettings:(id)sender
{
    [self.presentingDelegate presentedViewControllerWillClose:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Cyan";
    }
    else {
        return @"Pink";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TweaksCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
    }

    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger selectedCyan = [userDefaults integerForKey:kTweaksCyanShadeKey];
    NSInteger selectedPink = [userDefaults integerForKey:kTweaksPinkShadeKey];

    if (section == 0) {
        switch (row) {
            case 0:
                cell.textLabel.text = @"A3D8FF";
                break;

            case 1:
                cell.textLabel.text = @"D8E8FF";
                break;

            case 2:
                cell.textLabel.text = @"D3D9FF";
                break;

            case 3:
                cell.textLabel.text = @"C9DEFF";
                break;
        }

        cell.accessoryType = (row == selectedCyan) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        switch (row) {
            case 0:
                cell.textLabel.text = @"FFDDFC";
                break;

            case 1:
                cell.textLabel.text = @"FFC4E0";
                break;

            case 2:
                cell.textLabel.text = @"FFBAE6";
                break;

            case 3:
                cell.textLabel.text = @"FFD8FB";
                break;
        }

        cell.accessoryType = (row == selectedPink) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = indexPath.section;
    NSUInteger row = indexPath.row;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (section == 0) {
        [userDefaults setInteger:row
                          forKey:kTweaksCyanShadeKey];
    }
    else {
        [userDefaults setInteger:row
                          forKey:kTweaksPinkShadeKey];
    }

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    [tableView reloadData];
}

@end
