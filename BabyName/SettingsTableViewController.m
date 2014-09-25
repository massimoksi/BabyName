//
//  SettingsTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SettingsTableViewController.h"

#import "Constants.h"
#import "Language.h"


typedef NS_ENUM(NSInteger, SettingsSection) {
    kSettingsSectionGeneral = 0
};

typedef NS_ENUM(NSInteger, SectionGeneralRow) {
    kSectionGeneralRowGenders = 0,
    kSectionGeneralRowLanguages
};


@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger selectedGenders;
    NSInteger selectedLanguages;
    NSUInteger numberOfSelectedLanguages;
    
    switch (section) {
        case kSettingsSectionGeneral:
            if (row == kSectionGeneralRowGenders) {
                selectedGenders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
                switch (selectedGenders) {
                    case 1:
                        cell.detailTextLabel.text = NSLocalizedString(@"Male", nil);
                        break;
                        
                    case 2:
                        cell.detailTextLabel.text = NSLocalizedString(@"Female", nil);
                        break;
                        
                    case 3:
                        cell.detailTextLabel.text = NSLocalizedString(@"Both", nil);
                        break;
                }
            }
            else if (row == kSectionGeneralRowLanguages) {
                numberOfSelectedLanguages = [self numberOfSelectedLanguages];
                if (numberOfSelectedLanguages == 1) {
                    selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
                    if (selectedLanguages == kLanguageBitmaskIT) {
                        cell.detailTextLabel.text = NSLocalizedString(@"Italian", nil);
                    }
                    else if (selectedLanguages == kLanguageBitmaskEN) {
                        cell.detailTextLabel.text = NSLocalizedString(@"English", nil);
                    }
                    else if (selectedLanguages == kLanguageBitmaskDE) {
                        cell.detailTextLabel.text = NSLocalizedString(@"German", nil);
                    }
                    else if (selectedLanguages == kLanguageBitmaskFR) {
                        cell.detailTextLabel.text = NSLocalizedString(@"French", nil);
                    }
                }
                else {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%tu", numberOfSelectedLanguages];
                }
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

#pragma mark - Actions

- (IBAction)closeSettings:(id)sender
{
    
    
    [self.delegate settingsViewControllerWillClose:self];
}

#pragma mark - Private methods

- (NSUInteger)numberOfSelectedLanguages
{
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    NSUInteger count = ((selectedLanguages >> 3) & 1) + ((selectedLanguages >> 2) & 1) + ((selectedLanguages >> 1) & 1) + (selectedLanguages & 1);
    
    return count;
}

@end
