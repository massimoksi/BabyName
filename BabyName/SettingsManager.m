//
//  SettingsManager.m
//  BabyName
//
//  Created by Massimo Peri on 14/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "SettingsManager.h"

#import "Language.h"


NSString * const kSettingsSelectedGendersKey = @"SettingsSelectedGenders";
NSString * const kSettingsSelectedLanguagesKey = @"SettingsSelectedLanguages";


@implementation SettingsManager

+ (instancetype)sharedManager
{
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[SettingsManager alloc]  init];
    });
    
    return _sharedManager;
}

+ (NSArray *)availableLanguages
{
    // Get settings from user defaults.
    NSInteger selectedLanguages = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
    
    // Create the array containing available languages.
    Language *languageIT = [[Language alloc] initWithName:@"Italian" index:kLanguageIndexIT andSelected:(selectedLanguages & kLanguageBitmaskIT)];
    Language *languageEN = [[Language alloc] initWithName:@"English" index:kLanguageIndexEN andSelected:(selectedLanguages & kLanguageBitmaskEN)];
    Language *languageDE = [[Language alloc] initWithName:@"German"  index:kLanguageIndexDE andSelected:(selectedLanguages & kLanguageBitmaskDE)];
    Language *languageFR = [[Language alloc] initWithName:@"French"  index:kLanguageIndexFR andSelected:(selectedLanguages & kLanguageBitmaskFR)];
    
    return @[languageIT, languageEN, languageDE, languageFR];
}

#pragma mark - Accessors

- (void)setSelectedGenders:(NSInteger)selectedGenders
{
    [[NSUserDefaults standardUserDefaults] setInteger:selectedGenders
                                               forKey:kSettingsSelectedGendersKey];
}

- (NSInteger)selectedGenders
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedGendersKey];
}

- (void)setSelectedLanguages:(NSInteger)selectedLanguages
{
    [[NSUserDefaults standardUserDefaults] setInteger:selectedLanguages
                                               forKey:kSettingsSelectedLanguagesKey];
}

- (NSInteger)selectedLanguages
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsSelectedLanguagesKey];
}

//- (NSString *)briefSelectedLanguages
//{
//    NSInteger numberOfSelectedLanguages = [self numberOfSelectedLanguages];
//    if (numberOfSelectedLanguages == 1) {
//        NSInteger selectedLanguages = [self selectedLanguages];
//        switch (selectedLanguages) {
//            case kLanguageBitmaskIT:
//                return NSLocalizedString(@"Italian", nil);
//                break;
//                
//            case kLanguageBitmaskEN:
//                return NSLocalizedString(@"English", nil);
//                break;
//                
//            case kLanguageBitmaskDE:
//                return NSLocalizedString(@"German", nil);
//                break;
//                
//            case kLanguageBitmaskFR:
//                return NSLocalizedString(@"French", nil);
//                break;
//        }
//    }
//    else {
//        return [NSString stringWithFormat:@"%d", numberOfSelectedLanguages];
//    }
//}

#pragma mark - Private methods

- (NSInteger)numberOfSelectedLanguages
{
    NSInteger currentLanguages = [self selectedLanguages];
    NSInteger count = ((currentLanguages >> 3) & 1) + ((currentLanguages >> 2) & 1) + ((currentLanguages >> 1) & 1) + (currentLanguages & 1);
    
    return count;
}

@end
