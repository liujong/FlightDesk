//
//  SquawksCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SquawksCell.h"

@implementation SquawksCell

+ (SquawksCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"SquawksCell" owner:nil options:nil];
    SquawksCell *cell = [array objectAtIndex:0];
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
