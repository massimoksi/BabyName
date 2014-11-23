//
//  Constants.m
//  BabyName
//
//  Created by Massimo Peri on 14/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "Constants.h"


NSString * const kSettingsDBPopulatedKey       = @"SettingsDBPopulated";
NSString * const kSettingsSelectedGendersKey   = @"SettingsSelectedGenders";
NSString * const kSettingsSelectedLanguagesKey = @"SettingsSelectedLanguages";
NSString * const kSettingsPreferredInitialsKey = @"SettingsPreferredInitials";
NSString * const kSettingsShowSurnameKey       = @"SettingsShowSurname";
NSString * const kSettingsSurnameKey           = @"SettingsSurname";
NSString * const kSettingsDueDateKey           = @"SettingsDueDate";

NSString * const kFetchedObjectsOutdatedNotification      = @"FetchedObjectsOutdated";
NSString * const kFetchedObjectWasPreferredNotification   = @"FetchedObjectWasPreferred";
NSString * const kFetchedObjectWasUnpreferredNotification = @"FetchedObjectWasUnpreferred";

NSString * const kPreferredSuggestionChangedNotification = @"PreferredSuggestionChanged";
NSString * const kFetchingPreferencesChangedNotification = @"FetchingPreferencesChanged";

const CGFloat kPaneOverlapWidth = 44.0;


@implementation UIColor (BabyName)

+ (UIColor *)bbn_barTintColor
{
	return [UIColor colorWithRed:30.0/255.0
		                   green:36.0/255.0
		                    blue:60.0/255.0
		                   alpha:1.0];
}

+ (UIColor *)bbn_tintColor
{
	return [UIColor colorWithRed:240.0/255.0
                           green:74.0/255.0
                            blue:92.0/255.0
                           alpha:1.0];
}

+ (UIColor *)bbn_acceptColor
{
	return [UIColor colorWithRed:100.0/255.0
                           green:196.0/255.0
                            blue:98.0/255.0
                           alpha:1.0];
}

+ (UIColor *)bbn_rejectColor
{
	return [UIColor colorWithRed:245.0/255.0
                           green:99.0/255.0
                            blue:111.0/255.0
                           alpha:1.0];
}

+ (UIColor *)bbn_refreshColor
{
	return [UIColor colorWithRed:255.0/255.0
                          green:204.0/255.0
                           blue:0.0/255.0
                          alpha:1.0];
}

+ (UIColor *)bbn_preferColor
{
	return [UIColor colorWithRed:37.0/255.0
                           green:166.0/255.0
                            blue:255.0/255.0
                           alpha:1.0];
}

@end
