//
//  LanguagesViewController.m
//  BabyName
//
//  Created by Massimo Peri on 17/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "LanguagesViewController.h"

#import "Settings.h"


@interface LanguagesViewController ()

@property (nonatomic) NSInteger selectedLanguages;

@property (nonatomic, strong) NSArray *possibleLanguages;

@end


@implementation LanguagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.possibleLanguages = @[@"Italian", @"English", @"German", @"French"];
    self.selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LanguageCell"];
    
//    cell.textLabel.text = [self.possibleLanguages sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:<#(NSString *)#> ascending:<#(BOOL)#>]]];
//    
    // Configure the cell...
//    NSInteger languageBitmask = 1 << indexPath.row;
//    cell.accessoryType = ([self.possibleLanguages objectAtIndex:indexPath.row] & languageBitmask) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Update user settings.
//    if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryNone) {
//        // Select language (OR).
//        self.possibleLanguages |= 1 << indexPath.row;
//    }
//    else {
//        // Deselect language (XOR).
//        self.possibleLanguages ^= 1 << indexPath.row;
//    }
//    [[NSUserDefaults standardUserDefaults] setInteger:self.possibleLanguages
//                                               forKey:kSettingsSelectedLanguagesKey];
//    
//    [self.tableView reloadData];
//}

@end
