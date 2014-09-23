//
//  Language.h
//  BabyName
//
//  Created by Massimo Peri on 23/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, LanguageIndex) {
    kLanguageIndexIT = 0,
    kLanguageIndexEN = 1,
    kLanguageIndexDE = 2,
    kLanguageIndexFR = 3
};

typedef NS_OPTIONS(NSInteger, LanguageBitmask) {
    kLanguageBitmaskIT = 1 << 0,
    kLanguageBitmaskEN = 1 << 1,
    kLanguageBitmaskDE = 1 << 2,
    kLanguageBitmaskFR = 1 << 3
};


@interface Language : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL selected;

@property (nonatomic, copy, readonly) NSString *localizedName;

- (instancetype)initWithName:(NSString *)name index:(NSInteger)index andSelected:(BOOL)selected;

@end
