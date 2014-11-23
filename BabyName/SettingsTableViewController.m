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
    kSectionAdvancedRowSurname,
    kSectionAdvancedRowDueDate,
    kSectionAdvancedRowDatePicker
};

typedef NS_ENUM(NSInteger, SectionInfoRow) {
    kSectionInfoRowAbout = 0
};

@interface SettingsTableViewController () <UITextFieldDelegate>

@property (nonatomic) BOOL surnameCellVisible;
@property (nonatomic) BOOL datePickerVisible;
@property (nonatomic) BOOL datePickerClearing;

@property (nonatomic, weak) IBOutlet UILabel *genderLabel;
@property (nonatomic, weak) IBOutlet UILabel *languageLabel;
@property (nonatomic, weak) IBOutlet UILabel *initialsLabel;
@property (nonatomic, weak) IBOutlet UISwitch *surnameSwitch;
@property (nonatomic, weak) IBOutlet UITableViewCell *surnameCell;
@property (nonatomic, weak) IBOutlet UITextField *surnameTextField;
@property (nonatomic, weak) IBOutlet UITextField *dueDateTextField;
@property (nonatomic, weak) IBOutlet UIDatePicker *dueDatePicker;
@property (nonatomic, weak) IBOutlet UITableViewCell *datePickerCell;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end


@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.dueDatePicker.minimumDate = [NSDate date];
    
    self.insertTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.deleteTableViewRowAnimation = UITableViewRowAnimationMiddle;
    self.reloadTableViewRowAnimation = UITableViewRowAnimationMiddle;
    
    self.surnameTextField.tintColor = [UIColor bbn_tintColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.datePickerVisible = NO;
    self.datePickerClearing = NO;

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

    // Row: due date.
    NSDate *dueDate = [userDefaults objectForKey:kSettingsDueDateKey];
    if (dueDate) {
        self.dueDateTextField.text = [NSDateFormatter localizedStringFromDate:dueDate
                                                                    dateStyle:NSDateFormatterLongStyle
                                                                    timeStyle:NSDateFormatterNoStyle];
    }
    else {
        self.dueDateTextField.text = nil;
    }

    // Row: due date picker.
    [self cell:self.datePickerCell
     setHidden:YES];

    // Show/hide dynamic cells.
    [self reloadDataAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.datePickerVisible) {
        [self revealDatePickerAnimated:NO
                               andSave:YES];
    }
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
    //  1. Set preference to user default.
    //  2. Hide the surname cell.
    //  3. Remove surname from user default (if empty).
    else {
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

- (IBAction)changeDueDate:(id)sender
{
    UIDatePicker *datePicker = sender;

    // Update the due date label.
    self.dueDateTextField.text = [NSDateFormatter localizedStringFromDate:datePicker.date
                                                                dateStyle:NSDateFormatterLongStyle
                                                                timeStyle:NSDateFormatterNoStyle];
}

#pragma mark - Private methods

- (NSUInteger)numberOfSelectedLanguages
{
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    
    // NOTE: in case a new language is introduced, the formula calculation needs to be updated.
    NSUInteger count = ((selectedLanguages >> 3) & 1) + ((selectedLanguages >> 2) & 1) + ((selectedLanguages >> 1) & 1) + (selectedLanguages & 1);
    
    return count;
}

- (void)revealDatePickerAnimated:(BOOL)animated andSave:(BOOL)save
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Due date picker is visible.
    //  1. Save due date to user defaults (if changed).
    //  2. Configure due date text field.
    //      a. Set color to gray (detail text label).
    //      b. Hide clear button.
    //  3. Hide the cell containing the due date picker.
    if (self.datePickerVisible) {
        self.datePickerVisible = NO;

        if (save) {
            [userDefaults setObject:self.dueDatePicker.date
                             forKey:kSettingsDueDateKey];
        }

        self.dueDateTextField.textColor = [UIColor colorWithRed:159.0/255.0
                                                          green:160.0/255.0
                                                           blue:164.0/255.0
                                                          alpha:1.0];
        self.dueDateTextField.clearButtonMode = UITextFieldViewModeNever;

        [self cell:self.datePickerCell
         setHidden:YES];
        [self reloadDataAnimated:animated];
    }
    // Due date picker is not visible.
    //  1. Configure the due date picker with user defaults.
    //      a. Due date (if available).
    //      b. Today (if not available).
    //  2. Configure the due date text field.
    //      a. Set color to red.
    //      b. Show clear button.
    //  3. Reveal the cell containing the due date picker.
    //  4. Scroll table view to completely show the due date picker.
    else {
        self.datePickerVisible = YES;
        
        NSDate *dueDate = [userDefaults objectForKey:kSettingsDueDateKey];
        if (dueDate) {
            self.dueDatePicker.date = dueDate;
        }
        else {
            NSDate *today = [NSDate date];
            self.dueDatePicker.date = today;
            self.dueDateTextField.text = [NSDateFormatter localizedStringFromDate:today
                                                                        dateStyle:NSDateFormatterLongStyle
                                                                        timeStyle:NSDateFormatterNoStyle];
        }
        
        self.dueDateTextField.textColor = [UIColor bbn_tintColor];
        self.dueDateTextField.clearButtonMode = UITextFieldViewModeAlways;

        [self cell:self.datePickerCell
         setHidden:NO];
        [self reloadDataAnimated:animated];
        
        [self.tableView scrollRectToVisible:self.datePickerCell.frame
                                   animated:YES];
    }
    
    self.datePickerClearing = NO;
}

- (void)resetAllSelections
{
    if (![[SuggestionsManager sharedManager] reset]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectsOutdatedNotification
                                                            object:self];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if (section == kSettingsSectionAdvanced) {
        if (self.surnameCellVisible) {
            if (row == kSectionAdvancedRowSurname) {
                [self.surnameTextField becomeFirstResponder];
            }
            else if (row == kSectionAdvancedRowDueDate) {
                [self revealDatePickerAnimated:YES
                                       andSave:!self.datePickerClearing];
            }
        }
        else {
            if (row == kSectionAdvancedRowDueDate - 1) {
                [self revealDatePickerAnimated:YES
                                       andSave:!self.datePickerClearing];
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
    if (textField == self.surnameTextField) {
        return YES;
    }
    else {
        [self revealDatePickerAnimated:YES
                               andSave:!self.datePickerClearing];
        
        return NO;
    }
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
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    if (textField == self.dueDateTextField) {
        self.datePickerClearing = YES;
        
        [userDefaults removeObjectForKey:kSettingsDueDateKey];
    }

    return YES;
}

@end
