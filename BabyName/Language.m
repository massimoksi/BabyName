//
//  Language.m
//  BabyName
//
//  Created by Massimo Peri on 23/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "Language.h"


@implementation Language

- (instancetype)initWithName:(NSString *)name index:(NSInteger)index andSelected:(BOOL)selected
{
    self = [super init];
    if (self) {
        _name = name;
        _index = index;
        _selected = selected;
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d - %@: %d", self.index, self.name, self.selected];
}

#pragma mark - Accessors

- (NSString *)localizedName
{
    return NSLocalizedString(self.name, nil);
}

@end
