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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    // Get new preferences from user defaults.
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
//    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
//
//#if DEBUG
//    NSLog(@"[AcceptedNamesViewController] User settings:");
//    NSLog(@"    Gender: %zd", genders);
//    NSLog(@"    Languages: %zd", languages);
//#endif
//    
//    // Fetch all suggestions with state "accepted" and  matching the criteria from preferences.
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(state == %d) AND ((gender & %d) != 0) AND ((language & %d) != 0)", kSelectionStateAccepted, genders, languages];
//    self.fetchedResultsController.fetchRequest.predicate = predicate;
//    
//    NSError *error;
//    if (![self.fetchedResultsController performFetch:&error]) {
//#if DEBUG
//        NSLog(@"[AcceptedNamesViewController] Error:");
//        NSLog(@"    Error while fetching %@, %@", error, [error userInfo]);
//#endif
//        // TODO: handle error.
//    }
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

//- (NSFetchedResultsController *)fetchedResultsController
//{
//    if (_fetchedResultsController) {
//        return _fetchedResultsController;
//    }
//
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    [fetchRequest setFetchBatchSize:20];
//
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
//                                              inManagedObjectContext:self.managedObjectContext];
//    fetchRequest.entity = entity;
//
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
//                                                                   ascending:YES];
//    [fetchRequest setSortDescriptors:@[sortDescriptor]];
//
//    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
//                                                                    managedObjectContext:self.managedObjectContext
//                                                                      sectionNameKeyPath:nil
//                                                                               cacheName:nil];
//    _fetchedResultsController.delegate = self;
//
//    return _fetchedResultsController;
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.fetchedResultsController.sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MGSwipeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AcceptedNameCell"];
    
    Suggestion *suggestion = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = suggestion.name;
    cell.delegate = self;
    
    return cell;
}

#pragma mark - Fetched results controller delegate

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView beginUpdates];
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    [self.tableView endUpdates];
//}

//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
//{
//    if (type == NSFetchedResultsChangeUpdate) {
//        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
//                              withRowAnimation:UITableViewRowAnimationRight];
//    }
//}

#pragma mark - Swipe table cell delegate

//- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction
//{
//    return (direction == MGSwipeDirectionRightToLeft);
//}
//
//- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(MGSwipeDirection)direction fromExpansion:(BOOL)fromExpansion
//{
//    if (direction == MGSwipeDirectionRightToLeft) {
//        // TODO: check index and perform action.
//        if (index == 0) {
//            Suggestion *swipedSuggestion = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]];
//            swipedSuggestion.state = kSelectionStateRejected;
//
//            NSError *error;
//            if (![self.managedObjectContext save:&error]) {
//#if DEBUG
//                NSLog(@"[AcceptedNamesViewController] Error:");
//                NSLog(@"    Error while saving %@, %@", error, [error userInfo]);
//#endif
//                // TODO: handle error.
//            }
//            
//            [self.tableView reloadData];
//        }
//    }
//
//    // NOTE: return YES to autohide the current swipe buttons.
//    return YES;
//}
//
//- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
//{
//    // NOTE: setting up buttons with this delegate instead of using cell properties improves memory usage because buttons are only created in demand.
//    if (direction == MGSwipeDirectionRightToLeft) {
//        // Configure swipe settings.
//        swipeSettings.transition = MGSwipeTransitionStatic;
//
//        // Configure expansions settings.
//        expansionSettings.buttonIndex = 0;
//        expansionSettings.fillOnTrigger = YES;
//
//        // Create swipe buttons.
//        // TODO: replace title with an icon.
//        MGSwipeButton *deleteButton = [MGSwipeButton buttonWithTitle:@"Delete"
//                                                     backgroundColor:[UIColor redColor]];
//
//        return @[deleteButton];
//    }
//    else {
//        return nil;
//    }
//}

@end
