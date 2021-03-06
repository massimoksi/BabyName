//
//  AppDelegate.m
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "AppDelegate.h"

#import "Constants.h"
#import "SuggestionsManager.h"


@interface AppDelegate ()

@end


@implementation AppDelegate
            
+ (void)initialize
{
#if DEBUG
    NSLog(@"Defaults: start registering");
#endif

    // Get current language from the system.
    NSInteger selectedLanguage;
    NSString *currentLanguageCode;
    if ([NSLocale preferredLanguages].count) {
        currentLanguageCode  = [[[NSLocale preferredLanguages] firstObject] substringToIndex:2];
    }
    else {
        currentLanguageCode = [[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] substringToIndex:2];
    }
#if DEBUG
    NSLog(@"Defaults: launguage code %@", currentLanguageCode);
#endif
    
    if ([currentLanguageCode isEqualToString:@"it"]) {
#if DEBUG
        NSLog(@"Defaults: italian");
#endif
        
        selectedLanguage = kLanguageBitmaskIT;
    }
    else if ([currentLanguageCode isEqualToString:@"en"]) {
#if DEBUG
        NSLog(@"Defaults: english");
#endif

        selectedLanguage = kLanguageBitmaskEN;
    }
    else if ([currentLanguageCode isEqualToString:@"de"]) {
#if DEBUG
        NSLog(@"Defaults: german");
#endif

        selectedLanguage = kLanguageBitmaskDE;
    }
    else if ([currentLanguageCode isEqualToString:@"fr"]) {
#if DEBUG
        NSLog(@"Defaults: french");
#endif

        selectedLanguage = kLanguageBitmaskFR;
    }
    else {
#if DEBUG
        NSLog(@"Defaults: other");
#endif
        
        selectedLanguage = kLanguageBitmaskEN;
    }
    
    NSDictionary *defaultSettingsDict = @{kSettingsSelectedGendersKey   : @(kGenderBitmaskMale | kGenderBitmaskFemale),
                                          kSettingsSelectedLanguagesKey : @(selectedLanguage)};

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettingsDict];

#if DEBUG
    NSLog(@"Defaults: registered");
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    // Populate the database at first start.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults boolForKey:kSettingsDBPopulatedKey]) {
        if ([[SuggestionsManager sharedManager] populate]) {            
            [userDefaults setBool:YES
                           forKey:kSettingsDBPopulatedKey];
        }
        else {
            [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];

            [userDefaults setBool:NO
                           forKey:kSettingsDBPopulatedKey];
        }
    }
    
    // Fetch suggestions before the main view controller is loaded.
    if (![[SuggestionsManager sharedManager] update]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }

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

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    if (![[SuggestionsManager sharedManager] save]) {
        [self showAlertWithMessage:NSLocalizedString(@"Oops, there was an error.", @"Generic error message.")];
    }
}

#pragma mark - Private methods

- (void)showAlertWithMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Alert: title.")
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert: accept button.")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alertController addAction:acceptAction];
    
    [self.window.rootViewController presentViewController:alertController
                                                 animated:YES
                                               completion:nil];
}

@end
