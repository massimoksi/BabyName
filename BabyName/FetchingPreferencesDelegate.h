//
//  FetchingPreferencesDelegate.h
//  BabyName
//
//  Created by Massimo Peri on 25/09/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol FetchingPreferencesDelegate <NSObject>

- (void)viewControllerDidChangeFetchingPreferences;

@end
