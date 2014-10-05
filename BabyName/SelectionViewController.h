//
//  SelectionViewController.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectionViewDataSource;
@protocol SelectionViewDelegate;


@interface SelectionViewController : UIViewController

@property (nonatomic, weak) id<SelectionViewDataSource> dataSource;
@property (nonatomic, weak) id<SelectionViewDelegate> delegate;

@end


@protocol SelectionViewDataSource <NSObject>

- (BOOL)shouldReloadName;

- (NSString *)randomName;

@end


@protocol SelectionViewDelegate <NSObject>

- (void)selectionViewDidBeginPanning;
- (void)selectionViewDidEndPanning;

- (void)acceptName;
- (void)rejectName;

@end
