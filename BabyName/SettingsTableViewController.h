//
//  SettingsTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "StaticDataTableViewController.h"


@interface SettingsTableViewController : StaticDataTableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
