//
//  Language.h
//  BabyName
//
//  Created by Massimo Peri on 23/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Language : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL selected;

- (instancetype)initWithName:(NSString *)name index:(NSInteger)index andSelected:(BOOL)selected;

@end
