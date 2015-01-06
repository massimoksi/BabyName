//
//  SearchTableViewController.m
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SearchTableViewController.h"

#import "MGSwipeButton.h"

#import "Constants.h"
#import "SuggestionsManager.h"
#import "SearchTableViewCell.h"


typedef NS_ENUM(NSInteger, FilterSegment) {
    kFilterSegmentAll = 0,
    kFilterSegmentAccepted,
    kFilterSegmentRejected
};


@interface SearchTableViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, MGSwipeTableCellDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic) NSInteger selectedGenders;
@property (nonatomic) NSInteger selectedLanguages;
@property (nonatomic, copy) NSString *searchString;
@property (nonatomic) FilterSegment searchFilter;
@property (nonatomic) BOOL currentSuggestionValid;

@end


@implementation SearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [SuggestionsManager sharedManager].fetchedResultsController.delegate = self;

    self.currentSuggestionValid = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.searchBar.tintColor = [UIColor bbn_tintColor];
    self.searchBar.placeholder = NSLocalizedString(@"Search", @"Placeholder text for the search bar.");
    self.navigationItem.titleView = self.searchBar;
    self.navigationItem.titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;    

    // Get preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.selectedGenders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    self.selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

    // Initialize search criteria.
    self.searchString = @"";
    self.searchFilter = kFilterSegmentAll;
    
    [self fetchResults];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (!self.currentSuggestionValid) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCurrentSuggestionChangedNotification
                                                            object:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [SuggestionsManager sharedManager].fetchedResultsController = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    self.searchBar = nil;
    self.searchString = nil;

    [SuggestionsManager sharedManager].fetchedResultsController = nil;
}

#pragma mark - Actions

- (IBAction)cancelSearch:(id)sender
{
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
    
    self.searchString = @"";
    [self fetchResults];
}

- (IBAction)closeSearch:(id)sender
{
    [self performSegueWithIdentifier:@"CloseSearchSegue"
                              sender:self];
}

- (IBAction)filterSearch:(id)sender
{
    UISegmentedControl *filterSegmentedControl = sender;

    self.searchFilter = filterSegmentedControl.selectedSegmentIndex;
    [self fetchResults];
}

#pragma mark - Private methods

- (void)fetchResults
{
    NSFetchedResultsController *fetchedResultsController = [SuggestionsManager sharedManager].fetchedResultsController;

    NSString *searchFormat;

    if (![self.searchString isEqualToString:@""]) {
        searchFormat = @"((gender & %ld) != 0) AND ((language & %ld) != 0) AND (name BEGINSWITH[cd] %@)";

        if (self.searchFilter == kFilterSegmentRejected) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state == %ld)"];

            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               self.searchString,
                                                               (long)kSelectionStateRejected];
        }
        else if (self.searchFilter == kFilterSegmentAccepted) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state >= %ld)"];

            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               self.searchString,
                                                               (long)kSelectionStateAccepted];
        }
        else {
            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               self.searchString];
        }
    }
    else {
        searchFormat = @"((gender & %ld) != 0) AND ((language & %ld) != 0)";

        if (self.searchFilter == kFilterSegmentRejected) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state == %ld)"];
            
            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               (long)kSelectionStateRejected];
        }
        else if (self.searchFilter == kFilterSegmentAccepted) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state >= %ld)"];
            
            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               (long)kSelectionStateAccepted];
        }
        else {
            fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                               (long)self.selectedGenders,
                                                               (long)self.selectedLanguages,
                                                               self.searchString];
        }
    }

    NSError *error;
    if (![fetchedResultsController performFetch:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)configureCell:(SearchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Suggestion *suggestion = [[SuggestionsManager sharedManager].fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.nameLabel.text = suggestion.name;
    switch (suggestion.state) {
        case kSelectionStateMaybe:
            cell.stateImageView.image = nil;
            break;
            
        case kSelectionStateRejected:
            cell.stateImageView.image = [UIImage imageNamed:@"Rejected"];
            break;
            
        case kSelectionStateAccepted:
            cell.stateImageView.image = [UIImage imageNamed:@"Accepted"];
            break;
            
        case kSelectionStatePreferred:
            cell.stateImageView.image = [UIImage imageNamed:@"Preferred"];
            break;
    }
}

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[SuggestionsManager sharedManager].fetchedResultsController sections].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[[SuggestionsManager sharedManager].fetchedResultsController sections] objectAtIndex:section];
    return sectionInfo.name;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[SuggestionsManager sharedManager].fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[SuggestionsManager sharedManager].fetchedResultsController sectionForSectionIndexTitle:title
                                                                                            atIndex:index];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [[SuggestionsManager sharedManager].fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
    cell.delegate = self;
    
    [self configureCell:cell
            atIndexPath:indexPath];
    
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

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if (type == NSFetchedResultsChangeUpdate) {
        SearchTableViewCell *swipedCell = (SearchTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
		[self configureCell:swipedCell
			    atIndexPath:indexPath];
        swipedCell.rightButtons = @[];
        [swipedCell refreshContentView];
        [swipedCell setSwipeOffset:0.0
                          animated:YES
                        completion:^{
                            [self.tableView reloadData];
                        }];
	}
    else if (type == NSFetchedResultsChangeDelete) {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Search bar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelSearch:)];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // HACK: this methods is called twice when clear button is clicked.
    if (![self.searchString isEqualToString:searchText]) {
        self.searchString = searchText;
        
        [self fetchResults];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(closeSearch:)];
}

#pragma mark - Swipe table cell delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction
{
    if (direction == MGSwipeDirectionRightToLeft) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
{
    if (direction == MGSwipeDirectionRightToLeft) {
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [[SuggestionsManager sharedManager].fetchedResultsController objectAtIndexPath:swipedIndexPath];
    
    	switch (swipedSuggestion.state) {
    		case kSelectionStateMaybe:
                if (index == 0) {
                    swipedSuggestion.state = kSelectionStateRejected;
                }
                else {
                    swipedSuggestion.state = kSelectionStateAccepted;
                }
    			break;

    		case kSelectionStateRejected:
                swipedSuggestion.state = kSelectionStateAccepted;
    			break;

            case kSelectionStateAccepted:
            case kSelectionStatePreferred:
                swipedSuggestion.state = kSelectionStateRejected;

                // In case the user is reviewing accepted names, it's necessary to send a notification because the current suggestion may have been rejected.
                if ([[NSUserDefaults standardUserDefaults] boolForKey:kStateReviewAcceptedNamesKey]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAcceptedSuggestionChangedNotification
                                                                        object:self];
                }
                break;
    	}

        if (![[SuggestionsManager sharedManager] save]) {
            [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
        }
        else {
            if ([swipedSuggestion.name isEqualToString:[SuggestionsManager sharedManager].currentSuggestion.name]) {
                self.currentSuggestionValid = NO;
            }
        }
    }
    
    // NOTE: return YES to autohide the current swipe buttons.
    return NO;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
{
    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
    if (direction == MGSwipeDirectionRightToLeft) {
        swipeSettings.transition = MGSwipeTransitionStatic;
        // Offset the swipe buttons by the width of the sections index list (15.0 pts).
        swipeSettings.offset = 15.0;

        MGSwipeButton *rejectButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Rejected"]
                                                     backgroundColor:[UIColor bbn_rejectColor]
                                                             padding:14];

        MGSwipeButton *acceptButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Accepted"]
        	                                         backgroundColor:[UIColor bbn_acceptColor]
                                                             padding:14];

        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [[SuggestionsManager sharedManager].fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSArray *swipeButtons;

        switch (swipedSuggestion.state) {
        	case kSelectionStateMaybe:
        		swipeButtons = @[rejectButton, acceptButton];
        		break;

        	case kSelectionStateRejected:
        		swipeButtons = @[acceptButton];
        		break;

            case kSelectionStateAccepted:
            case kSelectionStatePreferred:
                swipeButtons = @[rejectButton];
                break;
        }

        return swipeButtons;
    }
    else {
        return @[];
    }
}

@end
