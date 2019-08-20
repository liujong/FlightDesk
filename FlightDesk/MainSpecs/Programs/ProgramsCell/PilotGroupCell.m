//
//  PilotGroupCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "PilotGroupCell.h"

@implementation PilotGroupCell
+ (PilotGroupCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"PilotGroupCell" owner:nil options:nil];
    PilotGroupCell *cell = [array objectAtIndex:0];
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
