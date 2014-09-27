//
//  Suggestion.m
//  BabyName
//
//  Created by Massimo Peri on 09/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "Suggestion.h"


@implementation Suggestion

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %d, %d, %d", self.name, self.gender, self.language, self.state];
}

@end