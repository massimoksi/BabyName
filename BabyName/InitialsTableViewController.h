//
//  InitialsTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 25/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchingPreferencesDelegate.h"


@interface InitialsTableViewController : UITableViewController

@property (nonatomic, weak) id<FetchingPreferencesDelegate> fetchingPreferencesDelegate;

@end
