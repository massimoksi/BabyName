//
//  SettingsTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StaticDataTableViewController.h"

#import "FetchingPreferencesDelegate.h"
#import "PresentingDelegate.h"

@protocol SettingsTableViewControllerDelegate;


@interface SettingsTableViewController : StaticDataTableViewController <FetchingPreferencesDelegate>

@property (nonatomic, weak) id<SettingsTableViewControllerDelegate> delegate;
@property (nonatomic, weak) id<PresentingDelegate> presentingDelegate;

@end


@protocol SettingsTableViewControllerDelegate <NSObject>

- (void)resetAllSelections;

@end
