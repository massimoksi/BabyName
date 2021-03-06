//
//  LanguagesTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 17/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "LanguagesTableViewController.h"

#import "Constants.h"
#import "Language.h"
#import "SettingsTableViewController.h"


@interface LanguagesTableViewController ()

@property (nonatomic) BOOL languagesChanged;

@property (nonatomic, strong) NSArray *sortedLanguages;

@end


@implementation LanguagesTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.languagesChanged = NO;
    
    [self updateCachedLanguages];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.languagesChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kFetchingPreferencesChangedNotification
                                                            object:self];
    }
}

#pragma mark - Private methods

- (void)updateCachedLanguages
{
    // Get settings from user defaults.
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    
    // Create the array containing the list of available languages.
    Language *langIT = [[Language alloc] initWithName:@"Italian" index:kLanguageIndexIT andSelected:(selectedLanguages & kLanguageBitmaskIT)];
    Language *langEN = [[Language alloc] initWithName:@"English" index:kLanguageIndexEN andSelected:(selectedLanguages & kLanguageBitmaskEN)];
    Language *langDE = [[Language alloc] initWithName:@"German"  index:kLanguageIndexDE andSelected:(selectedLanguages & kLanguageBitmaskDE)];
    Language *langFR = [[Language alloc] initWithName:@"French"  index:kLanguageIndexFR andSelected:(selectedLanguages & kLanguageBitmaskFR)];
    NSArray *availableLanguages = @[langIT, langEN, langDE, langFR];
    
    // Alphabetically sort the array of available languages.
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                         ascending:YES
                                                                          selector:@selector(localizedStandardCompare:)];
    self.sortedLanguages = [availableLanguages sortedArrayUsingDescriptors:@[nameSortDescriptor]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedLanguages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LanguageCell"];
    
    Language *language = [self.sortedLanguages objectAtIndex:indexPath.row];
    cell.textLabel.text = NSLocalizedString(language.name, nil);
    cell.accessoryType = language.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"At least one language must be selected.", @"Table view: footer.");
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Language *language = [self.sortedLanguages objectAtIndex:indexPath.row];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger selectedBitmask = 1 << language.index;
    NSInteger selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey] ^ selectedBitmask;
    if (selectedLanguages) {
        self.languagesChanged = YES;
        
        // Update user defaults.
        [userDefaults setInteger:selectedLanguages
                          forKey:kSettingsSelectedLanguagesKey];
        
        // Update table view.
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
        [self updateCachedLanguages];
        [tableView reloadData];
    }
    else {
        // Discard request because at least 1 language must always be selected.
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

@end
