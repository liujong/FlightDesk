//
//  UserManageCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/9/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "UserManageCell.h"

@implementation UserManageCell

+ (UserManageCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"UserManageCell" owner:nil options:nil];
    UserManageCell *cell = [array objectAtIndex:0];
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
