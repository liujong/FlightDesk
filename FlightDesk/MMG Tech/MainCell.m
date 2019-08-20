//
//  MainCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "MainCell.h"

@implementation MainCell
+ (MainCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"MainCell" owner:nil options:nil];
    MainCell *cell = [array objectAtIndex:0];
    return cell;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
