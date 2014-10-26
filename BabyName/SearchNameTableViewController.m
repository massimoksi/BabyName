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


@interface SearchNameTableViewController () <NSFetchedResultsControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, MGSwipeTableCellDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UISearchController *searchController;

@property (nonatomic) NSInteger selectedGenders;
@property (nonatomic) NSInteger selectedLanguages;

@property (nonatomic) BOOL searchControllerActive;
@property (nonatomic) BOOL fetchedObjectsChanged;

@property (nonatomic, readonly) UITableView *activeTableView;

@end


@implementation SearchNameTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.searchControllerActive = NO;
    self.fetchedObjectsChanged = NO;
    
    // Fetch search criteria from preferences.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.selectedGenders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    self.selectedLanguages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    
    [self configurePredicateWithSearchString:@""];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
    }
    
    [self configureSearchController];
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

#pragma mark - Accessors

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.fetchBatchSize = 20;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                     ascending:YES
                                                                      selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:@"initial"
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;
}

- (UITableView *)activeTableView
{
    if (self.searchControllerActive) {
        return ((UITableViewController *)self.searchController.searchResultsController).tableView;
    }
    else {
        return self.tableView;
    }
}

#pragma mark - Actions

- (IBAction)closeSearch:(id)sender
{
    [self.presentingDelegate presentedViewControllerWillClose:self.fetchedObjectsChanged];
}

#pragma mark - Private methods

- (void)configurePredicateWithSearchString:(NSString *)searchString
{
    NSPredicate *searchPredicate;
    if (![searchString isEqualToString:@""]) {
        searchPredicate = [NSPredicate predicateWithFormat:@"((gender & %d) != 0) AND ((language & %d) != 0) AND (name BEGINSWITH[cd] %@)", self.selectedGenders, self.selectedLanguages, searchString];
    }
    else {
        searchPredicate = [NSPredicate predicateWithFormat:@"((gender & %d) != 0) AND ((language & %d) != 0)", self.selectedGenders, self.selectedLanguages];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = searchPredicate;
}

- (void)configureSearchController
{
    UITableViewController *searchResultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    searchResultsController.tableView.dataSource = self;
    searchResultsController.tableView.delegate = self;
    searchResultsController.tableView.allowsSelection = NO;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x,
                                                       self.searchController.searchBar.frame.origin.y,
                                                       self.searchController.searchBar.frame.size.width,
                                                       44.0);
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:240.0/255.0
                                                                green:74.0/255.0
                                                                 blue:92.0/255.0
                                                                alpha:1.0];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    self.definesPresentationContext = YES;
}

- (void)configureCell:(SearchNameTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
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
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
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
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];

        [alertView show];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchControllerActive) {
        return 1;
    }
    else {
        return [self.fetchedResultsController sections].count;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (self.searchControllerActive) {
        return nil;
    }
    else {
        return [self.fetchedResultsController sectionIndexTitles];
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.fetchedResultsController sectionForSectionIndexTitle:title
                                                              atIndex:index];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchController) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return sectionInfo.name;
    }
    else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchControllerActive) {
        return self.fetchedResultsController.fetchedObjects.count;
    }
    else {
        NSArray *sections = [self.fetchedResultsController sections];
        id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
        return [sectionInfo numberOfObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchNameTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SearchNameCell"];
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
    [self.activeTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	if (type == NSFetchedResultsChangeUpdate) {
        SearchNameTableViewCell *swipedCell = (SearchNameTableViewCell *)[self.activeTableView cellForRowAtIndexPath:indexPath];
        
		[self configureCell:swipedCell
			    atIndexPath:indexPath];
        swipedCell.rightButtons = @[];
        [swipedCell refreshContentView];
        [swipedCell setSwipeOffset:0.0
                          animated:YES
                        completion:^{
                            [self.activeTableView reloadData];
                        }];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.activeTableView endUpdates];
}

#pragma mark - Search controller delegate

- (void)didPresentSearchController:(UISearchController *)searchController
{
    self.searchControllerActive = YES;

    [self.activeTableView reloadSectionIndexTitles];
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    // Reset the predicate for the fetch request.
    [self configurePredicateWithSearchString:@""];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
    }
    else {
        // Reload table view in case some object has been changed.
        if (self.fetchedObjectsChanged) {
            [self.tableView reloadData];
        }
    }
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.searchControllerActive = NO;

    [self.activeTableView reloadSectionIndexTitles];
}

#pragma mark - Search results updating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self configurePredicateWithSearchString:searchString];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
    }
    else {
        // Update the table view displayed by the search results controller.
        UITableViewController *searchResultsController = (UITableViewController *)searchController.searchResultsController;
        [searchResultsController.tableView reloadData];
    }
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
        NSIndexPath *swipedIndexPath = [self.activeTableView indexPathForCell:cell];
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
            [self showAlertWithMessage:NSLocalizedString(@"Ooops, there was an error.", nil)];
        }
        else {
            self.fetchedObjectsChanged = YES;
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

        MGSwipeButton *rejectButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Rejected"]
        	                                         backgroundColor:[UIColor redColor]
                                                             padding:14];

        MGSwipeButton *maybeButton = [MGSwipeButton buttonWithTitle:@""
        	                                                   icon:[UIImage imageNamed:@"Refresh"]
        	                                        backgroundColor:[UIColor yellowColor]
                                                            padding:14];

        MGSwipeButton *acceptButton = [MGSwipeButton buttonWithTitle:@""
        	                                                    icon:[UIImage imageNamed:@"Accepted"]
        	                                         backgroundColor:[UIColor greenColor]
                                                             padding:14];

        NSIndexPath *swipedIndexPath = [self.activeTableView indexPathForCell:cell];
        Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:swipedIndexPath];
        NSArray *swipeButtons;

        switch (swipedSuggestion.state) {
        	case kSelectionStateMaybe:
        		swipeButtons = @[rejectButton, acceptButton];
        		break;

        	case kSelectionStateRejected:
        		swipeButtons = @[maybeButton, acceptButton];
        		break;

            case kSelectionStateAccepted:
            case kSelectionStatePreferred:
                swipeButtons = @[rejectButton, maybeButton];
                break;
        }

        return swipeButtons;
    }
    else {
        return @[];
    }
}

@end
