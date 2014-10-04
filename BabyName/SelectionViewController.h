//
//  SelectionViewController.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SelectionViewDataSource;


@interface SelectionViewController : UIViewController

@property (nonatomic, weak) id<SelectionViewDataSource> dataSource;

@end


@protocol SelectionViewDataSource <NSObject>

- (NSString *)randomName;

- (void)acceptName;
- (void)rejectName;

@end
