//
//  LanguagesTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 17/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchingPreferencesDelegate.h"


@interface LanguagesTableViewController : UITableViewController

@property (nonatomic, weak) id<FetchingPreferencesDelegate> fetchingPreferencesDelegate;

@end
