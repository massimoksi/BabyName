//
//  SearchNameTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SearchNameTableViewController.h"

#import "MGSwipeButton.h"

#import "Constants.h"
#import "Suggestion.h"
#import "SearchNameTableViewCell.h"


@interface SearchNameTableViewController () <NSFetchedResultsControllerDelegate, MGSwipeTableCellDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end


@implementation SearchNameTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;

    // Fetch all suggestions matching the criteria from preferences.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((gender & %d) != 0) AND ((language & %d) != 0)", genders, languages];
    fetchRequest.predicate = predicate;
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                     ascending:YES
                                                                      selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
    	                                                                managedObjectContext:self.managedObjectContext
    	                                                                  sectionNameKeyPath:nil
    	                                                                           cacheName:nil];
    self.fetchedResultsController.delegate = self;

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
    	// TODO: handle error.
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Actions

- (IBAction)closeSearch:(id)sender
{
    [self.presentingDelegate closePresentedViewController:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
     
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchNameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchNameCell"];
    cell.delegate = self;
    
    [self configureCell:cell
    	    atIndexPath:indexPath];

    return cell;
}

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if (type == NSFetchedResultsChangeUpdate) {
        SearchNameTableViewCell *swipedCell = (SearchNameTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
		[self configureCell:swipedCell
			    atIndexPath:indexPath];
        swipedCell.rightButtons = @[];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Swipe table cell delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction
{
    return (direction == MGSwipeDirectionRightToLeft);
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionRightToLeft) {
    	NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
    	Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];

    	switch (swipedSuggestion.state) {
    		case kSelectionStateMaybe:
    			swipedSuggestion.state = (index == 0) ? kSelectionStateRejected : kSelectionStateAccepted;
    			break;

    		case kSelectionStateAccepted:
    			swipedSuggestion.state = (index == 0) ? kSelectionStateRejected : kSelectionStateMaybe;
    			break;

    		case kSelectionStateRejected:
    			swipedSuggestion.state = (index == 0) ? kSelectionStateMaybe : kSelectionStateAccepted;
    			break;
    	}

    	NSError *error;
    	if (![self.managedObjectContext save:&error]) {
    		// TODO: handle error.
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

        MGSwipeButton *rejectButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Rejected"]
        	                                         backgroundColor:[UIColor redColor]];

        MGSwipeButton *maybeButton = [MGSwipeButton buttonWithTitle:@""
        	                                                   icon:[UIImage imageNamed:@"Maybe"]
        	                                        backgroundColor:[UIColor yellowColor]];

        MGSwipeButton *acceptButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Accepted"]
        	                                         backgroundColor:[UIColor greenColor]];

        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSArray *swipeButtons;

        switch (swipedSuggestion.state) {
        	case kSelectionStateMaybe:
        		swipeButtons = @[rejectButton, acceptButton];
        		break;

        	case kSelectionStateAccepted:
        		swipeButtons = @[rejectButton, maybeButton];
        		break;

        	case kSelectionStateRejected:
        		swipeButtons = @[maybeButton, acceptButton];
        		break;
        }

        return swipeButtons;
    }
    else {
        return @[];
    }
}

#pragma mark - Private methods

- (void)configureCell:(SearchNameTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Suggestion *suggestion = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.nameLabel.text = suggestion.name;
    switch (suggestion.state) {
    	case kSelectionStateMaybe:
    		cell.stateImageView.image = nil;
    		break;

    	case kSelectionStateAccepted:
    		cell.stateImageView.image = [UIImage imageNamed:@"Accepted"];
    		break;

    	case kSelectionStateRejected:
    		cell.stateImageView.image = [UIImage imageNamed:@"Rejected"];
    		break;
    }
}

@end
