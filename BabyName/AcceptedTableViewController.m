//
//  AcceptedTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AcceptedTableViewController.h"

#import "MGSwipeButton.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "SearchTableViewCell.h"


@interface AcceptedTableViewController () <MGSwipeTableCellDelegate>

@end


@implementation AcceptedTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // It's not possible to make the view transparent in Storyboard because of the use of white labels.
    self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - Private methods

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Alert: title.")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert: accept button.")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alertController addAction:acceptAction];
    
    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark - Embedded view controller

@synthesize containerViewController;

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[SuggestionsManager sharedManager] acceptedSuggestions].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AcceptedNameCell"];

    Suggestion *suggestion = [[[SuggestionsManager sharedManager] acceptedSuggestions] objectAtIndex:indexPath.row];

    cell.nameLabel.text = suggestion.name;
    cell.stateImageView.image = (suggestion.state == kSelectionStatePreferred) ? [UIImage imageNamed:@"Preferred"] : nil;
    cell.delegate = self;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(@"Swipe right to select your preferred name.\rSwipe left to reject a name.", @"Table view: footer.");
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

#pragma mark - Swipe table cell delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction
{
    if (direction == MGSwipeDirectionRightToLeft) {
        // Disable right-to-left swipe (deletion) for the preferred item.
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [[[SuggestionsManager sharedManager] acceptedSuggestions] objectAtIndex:swipedIndexPath.row];
        if (swipedSuggestion.state == kSelectionStatePreferred) {
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        return YES;
    }
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
    Suggestion *swipedSuggestion = [[[SuggestionsManager sharedManager] acceptedSuggestions] objectAtIndex:swipedIndexPath.row];

    if (direction == MGSwipeDirectionRightToLeft) {
        if (index == 0) {
            if ([[SuggestionsManager sharedManager] rejectSuggestion:swipedSuggestion]) {
                [self.tableView deleteRowsAtIndexPaths:@[swipedIndexPath]
                                      withRowAnimation:UITableViewRowAnimationLeft];
                
                [cell refreshContentView];
                
                [self.containerViewController loadChildViewController];
            }
        }
    }
    else {
        if (index == 0) {
            if (swipedSuggestion.state != kSelectionStatePreferred) {
                if ([[SuggestionsManager sharedManager] preferredSuggestion]) {
                    // Prefer the currently selected name.
                    if ([[SuggestionsManager sharedManager] preferSuggestion:swipedSuggestion]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectWasPreferredNotification
                                                                            object:self];
                        
                        [self.tableView reloadData];
                    }
                    else {
                        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                    }
                }
                else {
                    // TODO: change message.
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", swipedSuggestion.name]
                                                                                             message:NSLocalizedString(@"Choose name and end selection.", @"Alert: message.")
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Alert: cancel button.")
                                                                           style:UIAlertActionStyleCancel
                                                                         handler:nil];
                    [alertController addAction:cancelAction];
                    
                    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Select", @"Alert: confirm button.")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action){
                                                                             // Prefer the currently selected name.
                                                                             if ([[SuggestionsManager sharedManager] preferSuggestion:swipedSuggestion]) {
                                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectWasPreferredNotification
                                                                                                                                     object:self];
                                                                                 
                                                                                 [self.tableView reloadData];
                                                                             }
                                                                             else {
                                                                                 [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                                                                             }
                                                                         }];
                    [alertController addAction:selectAction];
                    
                    [self presentViewController:alertController
                                       animated:YES
                                     completion:nil];
                }
            }
            else {
                // Unprefer the currently preferred name.
                if ([[SuggestionsManager sharedManager] unpreferSuggestion:swipedSuggestion]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectWasUnpreferredNotification
                                                                        object:self];
                    
                    [self.tableView reloadData];
                }
                else {
                    [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
                }
            }
        }
    }
    
    // NOTE: return YES to autohide the current swipe buttons.
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
{
    // Configure swipe settings.
    swipeSettings.transition = MGSwipeTransitionStatic;

    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
    if (direction == MGSwipeDirectionRightToLeft) {
        // Configure expansions settings.
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = YES;

        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@""
                                                                icon:[UIImage imageNamed:@"Rejected"]
                                                     backgroundColor:[UIColor bbn_rejectColor]
                                                             padding:14];

        return @[deleteButton];
    }
    else {
        // Configure expansions settings.
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = NO;

        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [[[SuggestionsManager sharedManager] acceptedSuggestions] objectAtIndex:swipedIndexPath.row];

        MGSwipeButton *preferButton = [MGSwipeButton buttonWithTitle:@""
                                                                icon:(swipedSuggestion.state == kSelectionStatePreferred) ? [UIImage imageNamed:@"Unprefer"] : [UIImage imageNamed:@"Prefer"]
                                                     backgroundColor:[UIColor bbn_preferColor]
                                                             padding:14];

        return @[preferButton];
    }
}

@end
