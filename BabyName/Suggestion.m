//
//  Suggestion.m
//  BabyName
//
//  Created by Massimo Peri on 26/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "Suggestion.h"


@implementation Suggestion

@dynamic gender;
@dynamic language;
@dynamic name;
@dynamic state;

- (NSString *)initials
{
    return [self.name.decomposedStringWithCanonicalMapping substringToIndex:1];
}

@end
