//
//  SettingsTableViewController.h
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsTableViewControllerDelegate;


@interface SettingsTableViewController : UITableViewController

@property (nonatomic, weak) id<SettingsTableViewControllerDelegate> delegate;

@end


@protocol SettingsTableViewControllerDelegate <NSObject>

- (void)settingsViewControllerWillClose:(SettingsTableViewController *)viewController;

@end
