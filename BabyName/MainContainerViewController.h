//
//  MainContainerViewController.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>                                               // TODO: remove.

#import "ContainerViewController.h"


@interface MainContainerViewController : UIViewController <ContainerViewController>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext; // TODO: remove.
@property (nonatomic) BOOL panningEnabled;                                  // TODO: remove.

@end
