//
//  FinishedViewController.h
//  BabyName
//
//  Created by Massimo Peri on 04/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MSDynamicsDrawerViewController.h"

#import "EmbeddedViewController.h"


@interface FinishedViewController : UIViewController <EmbeddedViewController>

@property (nonatomic, weak) MSDynamicsDrawerViewController *drawerViewController;

@end
