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
#import "GendersTableViewController.h"
#import "LanguagesTableViewController.h"
#import "InitialsTableViewController.h"


typedef NS_ENUM(NSInteger, SettingsSection) {
    kSettingsSectionGeneral = 0,
    kSettingsSectionRestart,
    kSettingsSectionAbout
};

typedef NS_ENUM(NSInteger, SectionGeneralRow) {
    kSectionGeneralRowGenders = 0,
    kSectionGeneralRowLanguages,
    kSectionGeneralRowInitials
};


@interface SettingsTableViewController ()

@property (nonatomic) BOOL fetchingPreferencesChanged;

@end


@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.fetchingPreferencesChanged = NO;
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
    NSArray *preferredInitials;
    NSUInteger preferredInitialsCount;
    
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
            else if (row == kSectionGeneralRowInitials) {
                preferredInitials = [[userDefaults stringArrayForKey:kSettingsPreferredInitialsKey] sortedArrayUsingSelector:@selector(compare:)];
                preferredInitialsCount = preferredInitials.count;
                if (preferredInitialsCount == 0) {
                    cell.detailTextLabel.text = @" ";
                }
                else if (preferredInitialsCount == 1) {
                    cell.detailTextLabel.text = [preferredInitials objectAtIndex:0];
                }
                else if (preferredInitialsCount > 8) {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%tu", preferredInitialsCount];
                }
                else {
                    cell.detailTextLabel.text = [preferredInitials componentsJoinedByString:@" "];
                }
            }
            break;
           
        case kSettingsSectionAbout:
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
            break;
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
    
    if (indexPath.section == kSettingsSectionRestart) {
        // NOTE: UIAlertController is iOS8 only, in case of backporting the app use UIActionSheet.
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Restart selection", nil)
                                                                                 message:NSLocalizedString(@"All your current selections and rejections will be cancelled.", nil)
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction *restartAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart", @"Restart button in the action sheet")
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction *action){
                                                                // Inform the delegate to reset all selections.
                                                                [self.delegate resetAllSelections];
                                                            }];
        [alertController addAction:restartAction];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button in the action sheet")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *action){
                                                                // TODO: discard the action sheet.
                                                             }];
        [alertController addAction:cancelAction];

        [self presentViewController:alertController
                           animated:YES
                         completion:^{
                             self.fetchingPreferencesChanged = YES;
                         }];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *segueIdentifier = segue.identifier;
    if ([segueIdentifier isEqualToString:@"ShowGendersSegue"]) {
        GendersTableViewController *viewController = [segue destinationViewController];
        viewController.fetchingPreferencesDelegate = self;
    }
    else if ([segueIdentifier isEqualToString:@"ShowLanguagesSegue"]) {
        LanguagesTableViewController *viewController = [segue destinationViewController];
        viewController.fetchingPreferencesDelegate = self;
    }
    else if ([segueIdentifier isEqualToString:@"ShowInitialsSegue"])  {
        InitialsTableViewController *viewController = [segue destinationViewController];
        viewController.fetchingPreferencesDelegate = self;
    }
}

#pragma mark - Actions

- (IBAction)closeSettings:(id)sender
{
    [self.delegate settingsViewControllerWillClose:self
                    withUpdatedFetchingPreferences:self.fetchingPreferencesChanged];
}

#pragma mark - Private methods

- (NSUInteger)numberOfSelectedLanguages
{
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    // NOTE: in case a new language is introduced, the count calculation needs to be updated.
    NSUInteger count = ((selectedLanguages >> 3) & 1) + ((selectedLanguages >> 2) & 1) + ((selectedLanguages >> 1) & 1) + (selectedLanguages & 1);
    
    return count;
}

#pragma mark - Fetching preferences delegate

- (void)viewControllerDidChangeFetchingPreferences
{
    self.fetchingPreferencesChanged = YES;
}

@end
