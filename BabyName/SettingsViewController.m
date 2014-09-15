//
//  SettingsViewController.m
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SettingsViewController.h"

#import "Settings.h"


typedef NS_ENUM(NSInteger, SettingsSection) {
    kSettingsSectionGeneral = 0
};

typedef NS_ENUM(NSInteger, SectionGeneralRow) {
    kSectionGeneralRowGender = 0,
    kSectionGeneralRowLanguage
};


@interface SettingsViewController ()

@property (nonatomic, strong) NSArray *genders;

@end


@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.genders = @[ @"Male", @"Female", @"Both" ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
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

    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    switch (section) {
        case kSettingsSectionGeneral:
            if (row == kSectionGeneralRowGender) {
                cell.detailTextLabel.text = [self.genders objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedGenderKey]];
            }
            else if (row == kSectionGeneralRowLanguage) {
                // TODO: implement.
            }
            break;
            
        default:
            break;
    }
    
    return cell;
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
