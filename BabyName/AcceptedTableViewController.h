//
//  AcceptedTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AcceptedNamesViewDataSource;
@protocol AcceptedNamesViewDelegate;


@interface AcceptedTableViewController : UITableViewController

@property (nonatomic, weak) id<AcceptedNamesViewDataSource> dataSource;
@property (nonatomic, weak) id<AcceptedNamesViewDelegate> delegate;

@end


@protocol AcceptedNamesViewDataSource <NSObject>

- (NSInteger)numberOfAcceptedNames;
- (id)acceptedNameAtIndex:(NSUInteger)index;
- (BOOL)hasPreferredName;

@end


@protocol AcceptedNamesViewDelegate <NSObject>

- (BOOL)removeAcceptedNameAtIndex:(NSUInteger)index;
- (BOOL)preferAcceptedNameAtIndex:(NSUInteger)index;
- (BOOL)unpreferAcceptedNameAtIndex:(NSUInteger)index;

@end
