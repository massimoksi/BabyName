//
//  MainViewController.h
//  BabyName
//
//  Created by Massimo Peri on 26/08/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "MSDynamicsDrawerViewController.h"


@interface MainViewController : UIViewController <MSDynamicsDrawerViewControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) MSDynamicsDrawerViewController *drawerViewController;

@end
