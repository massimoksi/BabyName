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
#import "Suggestion.h"
#import "SearchTableViewCell.h"


typedef NS_ENUM(NSInteger, FilterSegment) {
    kFilterSegmentAll = 0,
    kFilterSegmentAccepted,
    kFilterSegmentRejected
};


@interface SearchTableViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, MGSwipeTableCellDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic) NSInteger selectedGenders;
@property (nonatomic) NSInteger selectedLanguages;
@property (nonatomic, copy) NSString *searchString;
@property (nonatomic) FilterSegment searchFilter;

@end


@implementation SearchTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    [self.searchBar sizeToFit];
    self.searchBar.tintColor = [UIColor bbn_tintColor];
    self.searchBar.placeholder = NSLocalizedString(@"Search", @"Search bar: placeholder text.");
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

    self.searchBar = nil;
    self.searchString = nil;
    self.fetchedResultsController = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Accessors

- (NSFetchedResultsController *)fetchedResultsController
{
    // Lazily load the fetched results controller.
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSManagedObjectContext *context = self.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.entity = [NSEntityDescription entityForName:@"Suggestion"
                                      inManagedObjectContext:context];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                     ascending:YES
                                                                      selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:context
                                                                      sectionNameKeyPath:@"initial"
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;
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
    NSString *searchFormat;

    if (![self.searchString isEqualToString:@""]) {
        searchFormat = @"((gender & %ld) != 0) AND ((language & %ld) != 0) AND (name BEGINSWITH[cd] %@)";

        if (self.searchFilter == kFilterSegmentRejected) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state == %ld)"];

            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    self.searchString,
                                                                    (long)kSelectionStateRejected];
        }
        else if (self.searchFilter == kFilterSegmentAccepted) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state >= %ld)"];

            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    self.searchString,
                                                                    (long)kSelectionStateAccepted];
        }
        else {
            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    self.searchString];
        }
    }
    else {
        searchFormat = @"((gender & %ld) != 0) AND ((language & %ld) != 0)";

        if (self.searchFilter == kFilterSegmentRejected) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state == %ld)"];
            
            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    (long)kSelectionStateRejected];
        }
        else if (self.searchFilter == kFilterSegmentAccepted) {
            searchFormat = [searchFormat stringByAppendingString:@" AND (state >= %ld)"];
            
            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    (long)kSelectionStateAccepted];
        }
        else {
            self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:searchFormat,
                                                                    (long)self.selectedGenders,
                                                                    (long)self.selectedLanguages,
                                                                    self.searchString];
        }
    }

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)configureCell:(SearchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Suggestion *suggestion = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
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
                                                        handler:^(UIAlertAction *action){
                                                            // Dismiss alert controller.
                                                            [alertController dismissViewControllerAnimated:YES
                                                                                                completion:nil]; 
                                                        }];
    [alertController addAction:acceptAction];

    [self presentViewController:alertController
                       animated:YES
                     completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController sections].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return sectionInfo.name;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.fetchedResultsController sectionForSectionIndexTitle:title
                                                              atIndex:index];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sections = [self.fetchedResultsController sections];
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
    self.searchString = searchBar.text;

    [self fetchResults];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchString = @"";

    [self fetchResults];
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
        Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
    
    	switch (swipedSuggestion.state) {
    		case kSelectionStateMaybe:
    			swipedSuggestion.state = (index == 0) ? kSelectionStateRejected : kSelectionStateAccepted;
    			break;

    		case kSelectionStateRejected:
    			swipedSuggestion.state = (index == 0) ? kSelectionStateMaybe : kSelectionStateAccepted;
    			break;

            case kSelectionStateAccepted:
            case kSelectionStatePreferred:
                swipedSuggestion.state = (index == 0) ? kSelectionStateRejected : kSelectionStateMaybe;
                break;
    	}

        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFetchedObjectsOutdatedNotification
                                                                object:self];
        }
    }
    
    // NOTE: return YES to autohide the current swipe buttons.
    return NO;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
{
    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
    if (direction == MGSwipeDirectionRightToLeft) {
        // Configure swipe settings.
        swipeSettings.transition = MGSwipeTransitionStatic;
        swipeSettings.offset = 15.0;

        MGSwipeButton *rejectButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Rejected"]
                                                     backgroundColor:[UIColor bbn_rejectColor]
                                                             padding:14];

        MGSwipeButton *refreshButton = [MGSwipeButton buttonWithTitle:@""
        	                                                     icon:[UIImage imageNamed:@"Refresh"]
        	                                          backgroundColor:[UIColor bbn_refreshColor]
                                                              padding:14];

        MGSwipeButton *acceptButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Accepted"]
        	                                         backgroundColor:[UIColor bbn_acceptColor]
                                                             padding:14];

        NSIndexPath *swipedIndexPath = [self.tableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSArray *swipeButtons;

        switch (swipedSuggestion.state) {
        	case kSelectionStateMaybe:
        		swipeButtons = @[rejectButton, acceptButton];
        		break;

        	case kSelectionStateRejected:
        		swipeButtons = @[refreshButton, acceptButton];
        		break;

            case kSelectionStateAccepted:
            case kSelectionStatePreferred:
                swipeButtons = @[rejectButton, refreshButton];
                break;
        }

        return swipeButtons;
    }
    else {
        return @[];
    }
}

@end
