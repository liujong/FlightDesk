//
//  CheckListContentLabelCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/17/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "CheckListContentLabelCell.h"

@implementation CheckListContentLabelCell
+ (CheckListContentLabelCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CheckListContentLabelCell" owner:nil options:nil];
    CheckListContentLabelCell *cell = [array objectAtIndex:0];
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
