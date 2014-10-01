//
//  AcceptedNamesViewController.h
//  BabyName
//
//  Created by Massimo Peri on 28/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface AcceptedNamesViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray *acceptedNames;

@end
