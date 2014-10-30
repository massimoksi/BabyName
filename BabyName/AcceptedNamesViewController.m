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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource preferAcceptedNameAtIndex:indexPath.row]) {
        // Update table view.
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
        [tableView reloadData];
    }
}

#pragma mark - Swipe table cell delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction
{
    return (direction == MGSwipeDirectionRightToLeft);
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionRightToLeft) {
        // Check index and perform action.
        if (index == 0) {
            NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
            
            if ([self.dataSource removeAcceptedNameAtIndex:swipedIndexPath.row]) {
                [self.tableView deleteRowsAtIndexPaths:@[swipedIndexPath]
                                      withRowAnimation:UITableViewRowAnimationLeft];
                
                [cell refreshContentView];

                // Switch to the view controller to handle empty state, if the array for accepted names is now empty.
                if ([self.dataSource numberOfAcceptedNames] == 0) {
                    DrawerContainerViewController *containerViewController = (DrawerContainerViewController *)self.parentViewController;
                    [containerViewController selectChildViewController];
                }
            }
        }
    }

    // NOTE: return YES to autohide the current swipe buttons.
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
{
    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
    if (direction == MGSwipeDirectionRightToLeft) {
        // Configure swipe settings.
        swipeSettings.transition = MGSwipeTransitionStatic;

        // Configure expansions settings.
        expansionSettings.buttonIndex = 0;
        expansionSettings.fillOnTrigger = YES;

        // Create swipe buttons.
        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@""
                                                                icon:[UIImage imageNamed:@"Rejected"]
                                                     backgroundColor:[UIColor redColor]
                                                             padding:14];

        return @[deleteButton];
    }
    else {
        return nil;
    }
}

@end
