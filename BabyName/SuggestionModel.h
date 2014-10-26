//
//  SuggestionModel.h
//  BabyName
//
//  Created by Massimo Peri on 25/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SuggestionModel : NSManagedObject

@property (nonatomic) int16_t gender;
@property (nonatomic) int32_t language;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int16_t state;
@property (nonatomic, retain) NSString * variants;

@property (nonatomic, readonly) NSString *initial;

@end
