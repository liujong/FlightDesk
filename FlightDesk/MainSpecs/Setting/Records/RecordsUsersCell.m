//
//  RecordsUsersCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "RecordsUsersCell.h"

@implementation RecordsUsersCell
+ (RecordsUsersCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"RecordsUsersCell" owner:nil options:nil];
    RecordsUsersCell *cell = [array objectAtIndex:0];
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
