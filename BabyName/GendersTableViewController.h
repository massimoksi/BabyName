//
//  GendersTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchingPreferencesDelegate.h"


@interface GendersTableViewController : UITableViewController

@property (nonatomic, weak) id<FetchingPreferencesDelegate> fetchingPreferencesDelegate;

@end
