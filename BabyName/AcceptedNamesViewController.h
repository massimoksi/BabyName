//
//  AcceptedNamesViewController.h
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AcceptedNamesViewDataSource;


@interface AcceptedNamesViewController : UIViewController

@property (nonatomic, weak) id<AcceptedNamesViewDataSource> dataSource;

@end


@protocol AcceptedNamesViewDataSource <NSObject>

- (NSInteger)numberOfAcceptedNames;
- (id)acceptedNameAtIndex:(NSUInteger)index;

- (BOOL)removeAcceptedNameAtIndex:(NSUInteger)index;
- (BOOL)preferAcceptedNameAtIndex:(NSUInteger)index;

@end
