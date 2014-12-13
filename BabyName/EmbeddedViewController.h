//
//  EmbeddedViewController.h
//  BabyName
//
//  Created by Massimo Peri on 23/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContainerViewController.h"


@protocol EmbeddedViewController <NSObject>

@property (nonatomic, weak) id<ContainerViewController> containerViewController;

@end
