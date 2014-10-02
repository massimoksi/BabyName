//
//  DrawerContainerViewController.h
//  BabyName
//
//  Created by Massimo Peri on 30/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface DrawerContainerViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)selectChildViewController;

@end
