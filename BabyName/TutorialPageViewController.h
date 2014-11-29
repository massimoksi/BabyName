//
//  TutorialPageViewController.h
//  BabyName
//
//  Created by Massimo Peri on 27/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EmbeddedViewController.h"


@interface TutorialPageViewController : UIPageViewController <UIPageViewControllerDataSource, EmbeddedViewController>

- (void)completeTutorial;

@end
