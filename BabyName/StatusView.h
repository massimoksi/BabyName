//
//  StatusView.h
//  BabyName
//
//  Created by Massimo Peri on 11/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface StatusView : UIImageView

@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) NSTimeInterval delay;
@property (nonatomic) CGFloat scale;

- (void)showInView:(UIView *)view position:(CGPoint)position completion:(void (^)(BOOL finished))completion;

@end
