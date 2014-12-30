//
//  SearchTableViewCell.h
//  BabyName
//
//  Created by Massimo Peri on 03/10/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MGSwipeTableCell.h"


@interface SearchTableViewCell : MGSwipeTableCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *stateImageView;

@end
