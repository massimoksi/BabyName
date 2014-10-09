//
//  PresentingDelegate.h
//  BabyName
//
//  Created by Massimo Peri on 06/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol PresentingDelegate <NSObject>

- (void)closePresentedViewController:(UIViewController *)viewController;

@end
