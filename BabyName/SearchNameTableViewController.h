//
//  SearchNameTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "PresentingDelegate.h"


@interface SearchNameTableViewController : UITableViewController

@property (nonatomic, weak) id<PresentingDelegate> presentingDelegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
