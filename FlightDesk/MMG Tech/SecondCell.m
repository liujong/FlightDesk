//
//  SecondCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SecondCell.h"

@implementation SecondCell
+ (SecondCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"SecondCell" owner:nil options:nil];
    SecondCell *cell = [array objectAtIndex:0];
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
