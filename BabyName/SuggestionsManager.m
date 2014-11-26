//
//  SuggestionsManager.m
//  BabyName
//
//  Created by Massimo Peri on 20/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SuggestionsManager.h"

#import "Constants.h"


@interface SuggestionsManager ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSArray *suggestions;
@property (nonatomic, strong) Suggestion *currentSuggestion;

@end


@implementation SuggestionsManager

+ (SuggestionsManager *)sharedManager
{
    static SuggestionsManager *_sharedManager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[SuggestionsManager alloc] init];
    });
 
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

#pragma mark -

- (NSArray *)fetchedSuggestions
{
	return self.suggestions;
}

- (NSArray *)acceptedSuggestions
{
    NSArray *acceptedSuggestions = [self.suggestions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state >= %d", kSelectionStateAccepted]];

    return acceptedSuggestions;
}

- (Suggestion *)randomSuggestion
{
    NSArray *availableSuggestions = [self.suggestions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state = %d", kSelectionStateMaybe]];

    if (availableSuggestions.count) {
        NSUInteger randomIndex = arc4random() % availableSuggestions.count;
        Suggestion *suggestion = [availableSuggestions objectAtIndex:randomIndex];
        self.currentSuggestion = suggestion;
        
        return suggestion;
    }
    else {
        return nil;
    }
}

- (Suggestion *)preferredSuggestion
{
    NSArray *preferredSuggestions = [self.suggestions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"state = %d", kSelectionStatePreferred]];

    if (preferredSuggestions.count) {
        Suggestion *suggestion = preferredSuggestions.firstObject;
        self.currentSuggestion = suggestion;
        
        return suggestion;
    }
    else {
        return nil;
    }
}

#pragma mark - Accessors

- (NSFetchedResultsController *)fetchedResultsController
{
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

    return _fetchedResultsController;
}

#pragma mark -

- (BOOL)acceptSuggestion:(Suggestion *)suggestion
{
    suggestion.state = kSelectionStateAccepted;

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
    NSLog(@"Accepted: %@", suggestion.name);
#endif

    return YES;        
}

- (BOOL)rejectSuggestion:(Suggestion *)suggestion
{
    suggestion.state = kSelectionStateRejected;

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
    NSLog(@"Rejected: %@", suggestion.name);
#endif

    return YES;        
}

- (BOOL)preferSuggestion:(Suggestion *)suggestion
{
    // Check if a preferred suggestion is already available.
    Suggestion *preferredSuggestion = [self preferredSuggestion];
    if (preferredSuggestion) {
        preferredSuggestion.state = kSelectionStateAccepted;
    }

    suggestion.state = kSelectionStatePreferred;

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
        NSLog(@"Preferred: %@", suggestion.name);
#endif

    return YES;
}

- (BOOL)unpreferSuggestion:(Suggestion *)suggestion
{
    suggestion.state = kSelectionStateAccepted;

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
    NSLog(@"Unpreferred: %@", suggestion.name);
#endif

    return YES;
}

#pragma mark -

- (BOOL)update
{
#if DEBUG
    NSLog(@"Database: start fetch request.");
#endif

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Get filtering criteria from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];

    // Specify criteria for filtering which objects to fetch.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((gender & %d) != 0) AND ((language & %d) != 0)", genders, languages];
    [fetchRequest setPredicate:predicate];
    
    // Sort items alphabetically.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    NSArray *fetchedItems = [self.managedObjectContext executeFetchRequest:fetchRequest
                                                                     error:&error];
    if (!fetchedItems) {
#if DEBUG
        NSLog(@"Error: %@", [error userInfo]);
#endif

        return NO;
    }

    // Filter fetched items by initials (if necessary).
    NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
    if (initials.count) {
        NSString *initialsRegex = [NSString stringWithFormat:@"^[%@].*", [initials componentsJoinedByString:@""]];

        self.suggestions = [fetchedItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name MATCHES[cd] %@", initialsRegex]];
    }
    else {
        self.suggestions = [NSArray arrayWithArray:fetchedItems];
    }

#if DEBUG
    NSLog(@"Database: %tu fetched suggestions.", self.suggestions.count);
#endif
    
    return YES;
}

- (BOOL)reset
{
#if DEBUG
    NSLog(@"Database: start resetting.");
#endif

    NSManagedObjectContext *context = self.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Suggestion"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    // Fetch all items with a modified state.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"state > %d", kSelectionStateMaybe];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSArray *modifiedSuggestions = [context executeFetchRequest:fetchRequest
                                                          error:&error];
    if (!modifiedSuggestions) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

    // Reset the state for all the fetched items.
    for (Suggestion *suggestion in modifiedSuggestions) {
        suggestion.state = kSelectionStateMaybe;
    }

    if (![context save:&error]) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
    NSLog(@"Database: %tu reset suggestions.", modifiedSuggestions.count);
#endif

    return YES;
}

- (BOOL)populate
{
#if DEBUG
    NSLog(@"Database: start populating.");
#endif

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"BabyName"
                                                         ofType:@"csv"];
    if (!filePath) {
#if DEBUG
        NSLog(@"Error: BabyName.csv not found.");
#endif

        return NO;
    }

    __block NSError *error;
    NSString *names = [[NSString alloc] initWithContentsOfFile:filePath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (!names) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

    __block NSUInteger count = 0;
    __block BOOL failure = NO;
    [names enumerateLinesUsingBlock:^(NSString *line, BOOL *stop){
        NSArray *lineComponents = [line componentsSeparatedByString:@","];
        if (lineComponents) {
            Suggestion *suggestion = [NSEntityDescription insertNewObjectForEntityForName:@"Suggestion"
                                                                   inManagedObjectContext:self.managedObjectContext];
            suggestion.name = lineComponents[0];
            suggestion.gender = [lineComponents[1] integerValue];
            suggestion.language = (int32_t)[lineComponents[2] integerValue];
            suggestion.state = kSelectionStateMaybe;

            count++;
            // Save context every 1000 items.
            if (count >= 1000) {
                if (![self.managedObjectContext save:&error]) {
                    failure = YES;
                }
                else {
                    count = 0;
                }
            }
        }
    }];

    // Importing is finished, save for the last time and exit function.
    if (!failure) {
        if (![self.managedObjectContext save:&error]) {
            failure = YES;
        }
    }

    if (failure) {
#if DEBUG
        NSLog(@"Error: %@", [error localizedDescription]);
#endif

        return NO;
    }

#if DEBUG
    NSLog(@"Database: populated.");
#endif

    return YES;
}

- (BOOL)save
{
#if DEBUG
    NSLog(@"Database: start saving.");
#endif

    NSManagedObjectContext *context = self.managedObjectContext;
    if (context) {
        NSError *error;
        if ([context hasChanges] && ![context save:&error]) {
#if DEBUG
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
#else
            return NO;
#endif
        } 
    }

#if DEBUG
    NSLog(@"Database: saved.");
#endif

    return YES;
}

- (BOOL)validatePreferredSuggestion
{
    Suggestion *preferredSuggestion = [self preferredSuggestion];
        
#if DEBUG
    NSLog(@"Database: validating %@.", preferredSuggestion.name);
#endif
          
    // Get preferences from user defaults.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger genders = [userDefaults integerForKey:kSettingsSelectedGendersKey];
    NSInteger languages = [userDefaults integerForKey:kSettingsSelectedLanguagesKey];
    
    BOOL invalid = NO;
    if ((preferredSuggestion.gender & genders) && (preferredSuggestion.language & languages)) {
        NSArray *initials = [userDefaults stringArrayForKey:kSettingsPreferredInitialsKey];
        if (initials) {
            for (NSString *initial in initials) {
                if ([preferredSuggestion.initial isEqualToString:initial]) {
                    invalid = NO;
                    break;
                }
                else {
                    invalid = YES;
                }
            }
        }
    }
    else {
        invalid = YES;
    }
    
    if (invalid) {
#if DEBUG
        NSLog(@"Database: %@ is not valid.", preferredSuggestion.name);
#endif
        
        NSError *error;
        preferredSuggestion.state = kSelectionStateAccepted;
        if (![self.managedObjectContext save:&error]) {
#if DEBUG
            NSLog(@"Error: %@", [error localizedDescription]);
#endif
            
            return NO;
        }
    }
    else {
#if DEBUG
        NSLog(@"Database: %@ not valid.", preferredSuggestion.name);
#endif
    }
    
    return YES;
}

#pragma mark - Private methods

- (void)setup
{
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                  inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"BabyName.sqlite"];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BabyName"
                                              withExtension:@"momd"];

    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    // Create the persistent store coordinator.
    NSError *error;
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:nil
                                                               error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
          
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
          
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
          
          
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
          
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
          
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
          
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
          
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
}

@end
