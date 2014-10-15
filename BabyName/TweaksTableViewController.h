//
//  TweaksTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 15/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PresentingDelegate.h"


@interface TweaksTableViewController : UITableViewController

@property (nonatomic, weak) id<PresentingDelegate> presentingDelegate;

@end
