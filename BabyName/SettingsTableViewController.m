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
    kSettingsSectionAdvanced,
    kSettingsSectionRestart,
    kSettingsSectionAbout
};

typedef NS_ENUM(NSInteger, SectionGeneralRow) {
    kSectionGeneralRowGenders = 0,
    kSectionGeneralRowLanguages,
    kSectionGeneralRowInitials
};

typedef NS_ENUM(NSInteger, SectionAdvancedRow) {
    kSectionAdvancedRowShowSurname = 0,
    kSectionAdvancedRowSurname
};


@interface SettingsTableViewController ()

@property (nonatomic) BOOL fetchingPreferencesChanged;

@property (nonatomic, weak) IBOutlet UILabel *genderLabel;
@property (nonatomic, weak) IBOutlet UILabel *languageLabel;
@property (nonatomic, weak) IBOutlet UILabel *initialsLabel;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UISwitch *surnameSwitch;
@property (nonatomic, weak) IBOutlet UITableViewCell *surnameCell;

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
    
    self.insertTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.deleteTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.reloadTableViewRowAnimation = UITableViewRowAnimationMiddle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger selectedGenders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    switch (selectedGenders) {
        case 1:
            self.genderLabel.text = NSLocalizedString(@"Male", nil);
            break;
                        
        case 2:
            self.genderLabel.text = NSLocalizedString(@"Female", nil);
            break;
                        
        case 3:
            self.genderLabel.text = NSLocalizedString(@"Both", nil);
            break;
    }
    
    NSUInteger numberOfSelectedLanguages = [self numberOfSelectedLanguages];
    if (numberOfSelectedLanguages == 1) {
        NSInteger selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
        if (selectedLanguages == kLanguageBitmaskIT) {
            self.languageLabel.text = NSLocalizedString(@"Italian", nil);
        }
        else if (selectedLanguages == kLanguageBitmaskEN) {
            self.languageLabel.text = NSLocalizedString(@"English", nil);
        }
        else if (selectedLanguages == kLanguageBitmaskDE) {
            self.languageLabel.text = NSLocalizedString(@"German", nil);
        }
        else if (selectedLanguages == kLanguageBitmaskFR) {
            self.languageLabel.text = NSLocalizedString(@"French", nil);
        }
    }
    else {
        self.languageLabel.text = [NSString stringWithFormat:@"%tu", numberOfSelectedLanguages];
    }
    
    NSArray *preferredInitials = [[userDefaults stringArrayForKey:kSettingsPreferredInitialsKey] sortedArrayUsingSelector:@selector(compare:)];
    NSUInteger preferredInitialsCount = preferredInitials.count;
    if (preferredInitialsCount == 0) {
        self.initialsLabel.text = @" ";
    }
    else if (preferredInitialsCount == 1) {
        self.initialsLabel.text = [preferredInitials objectAtIndex:0];
    }
    else if (preferredInitialsCount > 8) {
        self.initialsLabel.text = [NSString stringWithFormat:@"%tu", preferredInitialsCount];
    }
    else {
        self.initialsLabel.text = [preferredInitials componentsJoinedByString:@" "];
    }
    
    BOOL surnameVisible = [userDefaults boolForKey:kSettingsShowSurnameKey];
    self.surnameSwitch.on = surnameVisible;
    [self cell:self.surnameCell
     setHidden:!surnameVisible];
    [self reloadDataAnimated:NO];
    
    self.versionLabel.text = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

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
    [self.presentingDelegate presentedViewControllerWillClose:self.fetchingPreferencesChanged];
}

- (IBAction)showSurname:(id)sender
{
    BOOL surnameVisible = self.surnameSwitch.isOn;
    
    [[NSUserDefaults standardUserDefaults] setBool:surnameVisible
                                            forKey:kSettingsShowSurnameKey];
    
    [self cell:self.surnameCell
     setHidden:!surnameVisible];
    [self reloadDataAnimated:YES];
}

#pragma mark - Private methods

- (NSUInteger)numberOfSelectedLanguages
{
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    // NOTE: in case a new language is introduced, the count calculation needs to be updated.
    NSUInteger count = ((selectedLanguages >> 3) & 1) + ((selectedLanguages >> 2) & 1) + ((selectedLanguages >> 1) & 1) + (selectedLanguages & 1);
    
    return count;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

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
                                                             handler:nil];
        [alertController addAction:cancelAction];

        [self presentViewController:alertController
                           animated:YES
                         completion:^{
                             self.fetchingPreferencesChanged = YES;
                         }];
    }
}

#pragma mark - Fetching preferences delegate

- (void)viewControllerDidChangeFetchingPreferences
{
    self.fetchingPreferencesChanged = YES;
}

@end
