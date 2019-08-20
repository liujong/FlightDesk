//
//  AircraftCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AircraftCell.h"

@implementation AircraftCell
+ (AircraftCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"AircraftCell" owner:nil options:nil];
    AircraftCell *cell = [array objectAtIndex:0];
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
