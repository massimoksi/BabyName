//
//  Settings.h
//  BabyName
//
//  Created by Massimo Peri on 14/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, SettingsSelectedGender) {
    kSettingsSelectedGenderMale = 0,
    kSettingsSelectedGenderFemale,
    kSettingsSelectedGenderBoth
};


extern NSString * const kSettingsSelectedGenderKey;
extern NSString * const kSettingsSelectedLanguagesKey;


@interface Settings : NSObject

@end
