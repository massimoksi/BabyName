//
//  SettingsViewController.h
//  BabyName
//
//  Created by Massimo Peri on 13/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate;


@interface SettingsViewController : UITableViewController

@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;

@end


@protocol SettingsViewControllerDelegate <NSObject>

@required
- (void)settingsViewControllerWillClose:(SettingsViewController *)viewController;

@end
