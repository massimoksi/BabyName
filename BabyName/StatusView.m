//
//  StatusView.m
//  BabyName
//
//  Created by Massimo Peri on 11/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import "StatusView.h"


@implementation StatusView

- (void)showInView:(UIView *)view position:(CGPoint)position completion:(void (^)(BOOL finished))completion
{
    self.center = position;

    [view addSubview:self];

    // Perform the animation.
    //  1. Zoom the status view.
    //  2. Fade out the status view.
    //  3. Run the completion block.
    //  4. Remove the status view.
    [UIView animateKeyframesWithDuration:0.5
                                   delay:0.0
                                 options:UIViewKeyframeAnimationOptionBeginFromCurrentState
                              animations:^{
                                [UIView addKeyframeWithRelativeStartTime:0.0
                                                        relativeDuration:0.5
                                                              animations:^{
                                                                  self.transform = CGAffineTransformMakeScale(1.2, 1.2);
                                                              }];
                                [UIView addKeyframeWithRelativeStartTime:0.5
                                                        relativeDuration:1.0
                                                              animations:^{
                                                                  self.alpha = 0.0;
                                                              }];
                              }
                              completion:^(BOOL finished){
                                  if (finished) {
                                      [self removeFromSuperview];
                                  }

                                  completion(finished);
                              }];
}

@end
