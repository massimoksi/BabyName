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
#import "SuggestionsManager.h"
#import "GendersTableViewController.h"
#import "LanguagesTableViewController.h"
#import "InitialsTableViewController.h"


typedef NS_ENUM(NSInteger, SettingsSection) {
    kSettingsSectionGeneral = 0,
    kSettingsSectionAdvanced,
    kSettingsSectionRestart,
    kSettingsSectionInfo
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

typedef NS_ENUM(NSInteger, SectionInfoRow) {
    kSectionInfoRowAbout = 0
};

@interface SettingsTableViewController () <UITextFieldDelegate>

@property (nonatomic) BOOL surnameCellVisible;

@property (nonatomic, weak) IBOutlet UILabel *genderLabel;
@property (nonatomic, weak) IBOutlet UILabel *languageLabel;
@property (nonatomic, weak) IBOutlet UILabel *initialsLabel;
@property (nonatomic, weak) IBOutlet UISwitch *surnameSwitch;
@property (nonatomic, weak) IBOutlet UITableViewCell *surnameCell;
@property (nonatomic, weak) IBOutlet UITextField *surnameTextField;

@end


@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.insertTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.deleteTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.reloadTableViewRowAnimation = UITableViewRowAnimationMiddle;
    
    self.surnameTextField.tintColor = [UIColor bbn_tintColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Row: genders.
    NSInteger selectedGenders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    switch (selectedGenders) {
        case 1:
            self.genderLabel.text = NSLocalizedString(@"Male", @"Gender.");
            break;
                        
        case 2:
            self.genderLabel.text = NSLocalizedString(@"Female", @"Gender.");
            break;
                        
        case 3:
            self.genderLabel.text = NSLocalizedString(@"Both", @"Both genders.");
            break;
    }
    
    // Row: languages.
    NSUInteger numberOfSelectedLanguages = [self numberOfSelectedLanguages];
    if (numberOfSelectedLanguages == 1) {
        NSInteger selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
        if (selectedLanguages == kLanguageBitmaskIT) {
            self.languageLabel.text = NSLocalizedString(@"Italian", @"Language.");
        }
        else if (selectedLanguages == kLanguageBitmaskEN) {
            self.languageLabel.text = NSLocalizedString(@"English", @"Language.");
        }
        else if (selectedLanguages == kLanguageBitmaskDE) {
            self.languageLabel.text = NSLocalizedString(@"German", @"Language.");
        }
        else if (selectedLanguages == kLanguageBitmaskFR) {
            self.languageLabel.text = NSLocalizedString(@"French", @"Language.");
        }
    }
    else {
        self.languageLabel.text = [NSString stringWithFormat:@"%tu", numberOfSelectedLanguages];
    }
    
    // Row: initials.
    NSArray *preferredInitials = [[userDefaults stringArrayForKey:kSettingsPreferredInitialsKey] sortedArrayUsingSelector:@selector(compare:)];
    NSUInteger preferredInitialsCount = preferredInitials.count;
    if (preferredInitialsCount == 0) {
        self.initialsLabel.text = @" ";
    }
    else if (preferredInitialsCount == 1) {
        self.initialsLabel.text = preferredInitials.firstObject;
    }
    else if (preferredInitialsCount > 8) {
        self.initialsLabel.text = [NSString stringWithFormat:@"%tu", preferredInitialsCount];
    }
    else {
        self.initialsLabel.text = [preferredInitials componentsJoinedByString:@" "];
    }
    
    // Row: show surname.
    BOOL surnameVisible = [userDefaults boolForKey:kSettingsShowSurnameKey];
    NSString *surname = [userDefaults stringForKey:kSettingsSurnameKey];
    self.surnameCellVisible = (surnameVisible && surname);
    
    self.surnameCellVisible = [userDefaults boolForKey:kSettingsShowSurnameKey] && [userDefaults stringForKey:kSettingsSurnameKey];
    self.surnameSwitch.on = self.surnameCellVisible;
    
    // Row: surname.
    if (self.surnameCellVisible) {
        [self cell:self.surnameCell
         setHidden:NO];
        
        self.surnameTextField.text = [userDefaults stringForKey:kSettingsSurnameKey];
    }
    else {
        [self cell:self.surnameCell
         setHidden:YES];
    }

    // Show/hide dynamic cells.
    [self reloadDataAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (IBAction)toggleSurname:(id)sender
{
    self.surnameCellVisible = self.surnameSwitch.isOn;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // Toggled switch on.
    //  1. Set preference to user defaults.
    //  2. Show the surname cell.
    //  3. Start editing the surname (if not defined yet).
    if (self.surnameCellVisible) {
        [userDefaults setBool:YES
                       forKey:kSettingsShowSurnameKey];
        
        [self cell:self.surnameCell
         setHidden:NO];
        [self reloadDataAnimated:YES];

        NSString *surname = [userDefaults stringForKey:kSettingsSurnameKey];
        if (surname) {
            self.surnameTextField.text = surname;
        }
        else {
            [self.surnameTextField becomeFirstResponder];
        }
    }
    // Toggled switch off.
    //  1. Hide keyboard if editing the surname text field.
    //  2. Set preference to user default.
    //  3. Hide the surname cell.
    //  4. Remove surname from user default (if empty).
    else {
        [self.surnameTextField resignFirstResponder];
        
        [userDefaults setBool:NO
                       forKey:kSettingsShowSurnameKey];

        [self cell:self.surnameCell
         setHidden:YES];
        [self reloadDataAnimated:YES];

        if ([self.surnameTextField.text isEqualToString:@""]) {
            [userDefaults removeObjectForKey:kSettingsSurnameKey];

            self.surnameTextField.text = nil;
        }        
    }
}

#pragma mark - Private methods

- (NSUInteger)numberOfSelectedLanguages
{
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    
    // NOTE: in case a new language is introduced, the formula calculation needs to be updated.
    NSUInteger count = ((selectedLanguages >> 3) & 1) + ((selectedLanguages >> 2) & 1) + ((selectedLanguages >> 1) & 1) + (selectedLanguages & 1);
    
    return count;
}

- (void)resetAllSelections
{
    if (![[SuggestionsManager sharedManager] reset]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
}

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil];
    [alertController addAction:acceptAction];

    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
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
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == kSettingsSectionAdvanced) {
        if (self.surnameCellVisible) {
            if (row == kSectionAdvancedRowSurname) {
                [self.surnameTextField becomeFirstResponder];
            }
        }
    }
    else if (section == kSettingsSectionRestart) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Restart selection", @"Action: title.")
                                                                                 message:NSLocalizedString(@"All your current selections and rejections will be cancelled.", @"Action: ask confirmation if selection should restart from ground.")
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *restartAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Restart", @"Action: accept button.")
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction *action){
                                                                  // Inform the delegate to reset all selections.
                                                                  [self resetAllSelections];
                                                              }];
        [alertController addAction:restartAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Action: cancel button.")
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.surnameTextField) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        NSString *surname = textField.text;
        // Editing ends with a surname that needs to be saved to preferences.
        if (![surname isEqualToString:@""]) {
            [userDefaults setObject:textField.text
                             forKey:kSettingsSurnameKey];
        }
        // Editing ends without a surname.
        //  1. Remove any existing surname from preferences.
        //  2. Toggle the switch to disable surname visualization.
        //  3. Hide the cell with the text field to enter the surname.
        else {
            [userDefaults removeObjectForKey:kSettingsSurnameKey];

            self.surnameSwitch.on = NO;
            [self toggleSurname:self];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.surnameTextField) {
        [textField resignFirstResponder];
    }

    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

@end
