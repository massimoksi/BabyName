//
//  Suggestion.h
//  BabyName
//
//  Created by Massimo Peri on 09/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef NS_OPTIONS(int16_t, SuggestionGender) {
    kSuggestionGenderMale = 1 << 0,
    kSuggestionGenderFemale = 1 << 1
};

typedef NS_OPTIONS(int32_t, SuggestionLanguage) {
    kSuggestionLanguageIT = 1 << 0,
    kSuggestionLanguageEN = 1 << 1
};

typedef NS_ENUM(int16_t, SuggestionState) {
    kSuggestionStateMaybe = 0,
    kSuggestionStateYes,
    kSuggestionStateNo
};


@interface Suggestion : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t gender;
@property (nonatomic) int32_t language;
@property (nonatomic) int16_t state;
@property (nonatomic, retain) NSString * variants;

@end
