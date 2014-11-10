//
//  AppDelegate.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AppDelegate.h"

#import "MSDynamicsDrawerViewController.h"

#import "Constants.h"
#import "Suggestion.h"
#import "MainViewController.h"
#import "DrawerContainerViewController.h"


@interface AppDelegate () <MSDynamicsDrawerViewControllerDelegate>

@end


@implementation AppDelegate
            
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (void)initialize
{
    // Get current language from the system.
    NSInteger selectedLanguage;
    NSString *currentLanguageCode = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    if ([currentLanguageCode isEqualToString:@"it"]) {
        selectedLanguage = kLanguageBitmaskIT;
    }
    else if ([currentLanguageCode isEqualToString:@"en"]) {
        selectedLanguage = kLanguageBitmaskEN;
    }
    else if ([currentLanguageCode isEqualToString:@"de"]) {
        selectedLanguage = kLanguageBitmaskDE;
    }
    else if ([currentLanguageCode isEqualToString:@"fr"]) {
        selectedLanguage = kLanguageBitmaskFR;
    }
    else {
        selectedLanguage = kLanguageBitmaskEN;
    }
    
    NSDictionary *defaultSettingsDict = @{kSettingsSelectedGendersKey   : @(kGenderBitmaskMale | kGenderBitmaskFemale),
                                          kSettingsSelectedLanguagesKey : @(selectedLanguage)};

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettingsDict];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // Populate the database at first start.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kSettingsDBPopulatedKey]) {
#if DEBUG
        NSLog(@"Populating DB: start.");
#endif
        
        if ([self populateDB]) {
#if DEBUG
            NSLog(@"Populating DB: stop.");
#endif
            
            [userDefaults setBool:YES
                           forKey:kSettingsDBPopulatedKey];
        }
        else {
            // TODO: handle error.
        }
    }

#if DEBUG
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *reqEntity = [NSEntityDescription entityForName:@"Suggestion"
                                                 inManagedObjectContext:context];
    [fetchRequest setEntity:reqEntity];

    NSError *error;
    NSUInteger count = [context countForFetchRequest:fetchRequest
                                               error:&error];
    NSLog(@"Database contains %tu suggestions.", count);
#endif

    MSDynamicsDrawerViewController *drawerViewController = (MSDynamicsDrawerViewController *)self.window.rootViewController;
    drawerViewController.delegate = self;
    drawerViewController.shouldAlignStatusBarToPaneView = NO;
    [drawerViewController registerTouchForwardingClass:[UILabel class]];

    MainViewController *mainViewController = [[UIStoryboard storyboardWithName:@"Main"
                                                                        bundle:nil] instantiateViewControllerWithIdentifier:@"MainVC"];
    mainViewController.drawerViewController = drawerViewController;
    mainViewController.managedObjectContext = self.managedObjectContext;
    drawerViewController.paneViewController = mainViewController;
    drawerViewController.delegate = mainViewController;

    DrawerContainerViewController *containerViewController = [[UIStoryboard storyboardWithName:@"Main"
                                                                                        bundle:nil] instantiateViewControllerWithIdentifier:@"DrawerContainerVC"];
    containerViewController.managedObjectContext = self.managedObjectContext;
    [drawerViewController setDrawerViewController:containerViewController
                                     forDirection:MSDynamicsDrawerDirectionRight];
    [drawerViewController setRevealWidth:CGRectGetWidth([[UIScreen mainScreen] bounds]) - 44.0f
                            forDirection:MSDynamicsDrawerDirectionRight];
    [drawerViewController addStylersFromArray:@[[MSDynamicsDrawerShadowStyler styler]]
                                 forDirection:MSDynamicsDrawerDirectionRight];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Private methods

- (BOOL)populateDB
{
    NSManagedObjectContext *context = self.managedObjectContext;

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"BabyName"
                                                         ofType:@"csv"];
    if (filePath) {
        __block NSError *error;
        NSString *names = [[NSString alloc] initWithContentsOfFile:filePath
                                                          encoding:NSUTF8StringEncoding
                                                             error:&error];
        if (names) {
            __block NSUInteger count = 0;
            [names enumerateLinesUsingBlock:^(NSString *line, BOOL *stop){
                NSArray *lineComponents = [line componentsSeparatedByString:@","];
                if (lineComponents) {
                    NSString *name = lineComponents[0];
                    NSInteger gender = [lineComponents[1] integerValue];
                    NSInteger language = [lineComponents[2] integerValue];

                    Suggestion *suggestion = [NSEntityDescription insertNewObjectForEntityForName:@"Suggestion"
                                                                           inManagedObjectContext:context];
                    suggestion.name = name;
                    suggestion.gender = gender;
                    suggestion.language = language;
                    suggestion.state = kSelectionStateMaybe;

                    count++;
                    // Save context every 1000 items.
                    if (count >= 1000) {
                        if (![context save:&error]) {
                            // TODO: handle error.
                        }
                        else {
                            count = 0;
                        }
                    }
                }
            }];

            // Importing is finished, save for the last time and exit function.
            if (![context save:&error]) {
                return NO;
            }
            else {
                return YES;
            }
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BabyName"
                                              withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
     
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BabyName.sqlite"];
     
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
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
     
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end
