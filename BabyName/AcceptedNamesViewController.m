//
//  AcceptedNamesViewController.m
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AcceptedNamesViewController.h"

#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"

#import "Constants.h"
#import "Suggestion.h"


@interface AcceptedNamesViewController () <UITableViewDataSource, NSFetchedResultsControllerDelegate, MGSwipeTableCellDelegate>

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.acceptedNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AcceptedNameCell"];
    
    Suggestion *suggestion = [self.acceptedNames objectAtIndex:indexPath.row];

    cell.textLabel.text = suggestion.name;
    cell.delegate = self;
    
    return cell;
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
            NSUInteger swipedCellIndex = [self.tableView indexPathForCell:cell].row;
            Suggestion *swipedSuggestion = [self.acceptedNames objectAtIndex:swipedCellIndex];
            swipedSuggestion.state = kSelectionStateRejected;

            NSError *error;
            if (![self.managedObjectContext save:&error]) {
#if DEBUG
                NSLog(@"[AcceptedNamesViewController] Error:");
                NSLog(@"    Error while saving %@, %@", error, [error userInfo]);
#endif
                // TODO: handle error.
            }
            else {
                [self.acceptedNames removeObjectAtIndex:swipedCellIndex];
            }
            
            [self.tableView reloadData];
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
        // TODO: replace title with an icon.
        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"Delete"
                                                     backgroundColor:[UIColor redColor]];

        return @[deleteButton];
    }
    else {
        return nil;
    }
}

@end
