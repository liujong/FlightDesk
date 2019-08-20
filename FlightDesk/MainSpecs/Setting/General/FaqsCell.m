//
//  FaqsCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/31/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "FaqsCell.h"

@implementation FaqsCell

+ (FaqsCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"FaqsCell" owner:nil options:nil];
    FaqsCell *cell = [array objectAtIndex:0];
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
