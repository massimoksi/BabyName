//
//  SelectionViewController.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EmbeddedViewController.h"

#import "Suggestion.h"  // TODO: remove.

@protocol SelectionViewDataSource;
@protocol SelectionViewDelegate;


@interface SelectionViewController : UIViewController <EmbeddedViewController>

@property (nonatomic, weak) id<SelectionViewDataSource> dataSource;     // TODO: remove.
@property (nonatomic, weak) id<SelectionViewDelegate> delegate;         // TODO: remove.

- (void)configureNameLabel;                                             // TODO: remove.

@end


@protocol SelectionViewDataSource <NSObject>

- (BOOL)shouldReloadName;

@end


@protocol SelectionViewDelegate <NSObject>

- (void)selectionViewDidBeginPanning;
- (void)selectionViewDidEndPanning;

- (void)acceptName;
- (void)rejectName;

@end
