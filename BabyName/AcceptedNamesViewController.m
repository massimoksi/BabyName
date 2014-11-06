//
//  AcceptedNamesViewController.m
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AcceptedNamesViewController.h"

#import "MGSwipeButton.h"

#import "Constants.h"
#import "Suggestion.h"
#import "SearchTableViewCell.h"
#import "DrawerContainerViewController.h"


@interface AcceptedNamesViewController () <UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end


@implementation AcceptedNamesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfAcceptedNames];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AcceptedNameCell"];

    Suggestion *suggestion = [self.dataSource acceptedNameAtIndex:indexPath.row];

    cell.nameLabel.text = suggestion.name;
    cell.stateImageView.image = (suggestion.state == kSelectionStatePreferred) ? [UIImage imageNamed:@"Preferred"] : nil;
    cell.delegate = self;
    
    return cell;
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
    return YES;
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];

    if (direction == MGSwipeDirectionRightToLeft) {
        if (index == 0) {
            if ([self.delegate removeAcceptedNameAtIndex:swipedIndexPath.row]) {
                [self.tableView deleteRowsAtIndexPaths:@[swipedIndexPath]
                                      withRowAnimation:UITableViewRowAnimationLeft];
                
                [cell refreshContentView];
            }
        }
    }
    else {
        if (index == 0) {
            Suggestion *swipedSuggestion = [self.dataSource acceptedNameAtIndex:swipedIndexPath.row];

            if (swipedSuggestion.state != kSelectionStatePreferred) {
                if ([self.dataSource hasPreferredName]) {
                    // Prefer the currently selected name.
                    if ([self.delegate preferAcceptedNameAtIndex:swipedIndexPath.row]) {
                        [self.tableView reloadData];
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
                                                                             if ([self.delegate preferAcceptedNameAtIndex:swipedIndexPath.row]) {
                                                                                 [self.tableView reloadData];
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
                if ([self.delegate unpreferAcceptedNameAtIndex:swipedIndexPath.row]) {
                    [self.tableView reloadData];
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

    // Configure expansions settings.
    expansionSettings.buttonIndex = 0;
    expansionSettings.fillOnTrigger = YES;

    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
    if (direction == MGSwipeDirectionRightToLeft) {
        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@""
                                                                icon:[UIImage imageNamed:@"Rejected"]
                                                     backgroundColor:[UIColor colorWithRed:0.962
                                                                                     green:0.388
                                                                                      blue:0.434
                                                                                     alpha:1.0]
                                                             padding:14];

        return @[deleteButton];
    }
    else {
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [self.dataSource acceptedNameAtIndex:swipedIndexPath.row];

        MGSwipeButton *preferButton = [MGSwipeButton buttonWithTitle:@""
                                                                icon:(swipedSuggestion.state == kSelectionStatePreferred) ? [UIImage imageNamed:@"Unprefer"] : [UIImage imageNamed:@"Prefer"]
                                                     backgroundColor:[UIColor colorWithRed:0.144
                                                                                     green:0.652
                                                                                      blue:1.000
                                                                                     alpha:1.0]
                                                             padding:14];

        return @[preferButton];
    }
}

@end
