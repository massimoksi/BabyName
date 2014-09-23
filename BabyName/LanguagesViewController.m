//
//  LanguagesViewController.m
//  BabyName
//
//  Created by Massimo Peri on 17/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "LanguagesViewController.h"

#import "SettingsManager.h"
#import "Language.h"


@interface LanguagesViewController ()

@property (nonatomic, strong) NSArray *sortedLanguages;

@end


@implementation LanguagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self updateCachedLanguages];
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
    return self.sortedLanguages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LanguageCell"];
    
    Language *language = (Language *)[self.sortedLanguages objectAtIndex:indexPath.row];
    cell.textLabel.text = language.localizedName;
    cell.accessoryType = language.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Language *language = (Language *)[self.sortedLanguages objectAtIndex:indexPath.row];
    
    NSInteger selectedBitmask = 1 << language.index;
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey] ^ selectedBitmask;
    if (selectedLanguages) {
        // Update user defaults.
        [[NSUserDefaults standardUserDefaults] setInteger:selectedLanguages
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

#pragma mark - Private methods

- (void)updateCachedLanguages
{
    // Refresh the array of available languages.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"localizedName"
                                                                     ascending:YES];
    self.sortedLanguages = [[SettingsManager availableLanguages] sortedArrayUsingDescriptors:@[sortDescriptor]];
}

@end
