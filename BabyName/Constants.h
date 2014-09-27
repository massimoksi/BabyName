//
//  Constants.h
//  BabyName
//
//  Created by Massimo Peri on 14/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const kSettingsSelectedGendersKey;
extern NSString * const kSettingsSelectedLanguagesKey;
extern NSString * const kSettingsPreferredInitialsKey;


typedef NS_ENUM(NSInteger, LanguageIndex) {
    kLanguageIndexIT = 0,
    kLanguageIndexEN = 1,
    kLanguageIndexDE = 2,
    kLanguageIndexFR = 3
};

typedef NS_OPTIONS(NSInteger, LanguageBitmask) {
    kLanguageBitmaskIT = 1 << kLanguageIndexIT,
    kLanguageBitmaskEN = 1 << kLanguageIndexEN,
    kLanguageBitmaskDE = 1 << kLanguageIndexDE,
    kLanguageBitmaskFR = 1 << kLanguageIndexFR
};


typedef NS_OPTIONS(NSInteger, GenderBitmask) {
    kGenderBitmaskMale   = 1 << 0,
    kGenderBitmaskFemale = 1 << 1
};


typedef NS_ENUM(NSInteger, SelectionState) {
    kSelectionStateMaybe = 0,
    kSelectionStateAccepted,
    kSelectionStateRejected
};