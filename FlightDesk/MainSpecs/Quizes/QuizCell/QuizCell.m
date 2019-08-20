//
//  QuizCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "QuizCell.h"

@implementation QuizCell
+ (QuizCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"QuizCell" owner:nil options:nil];
    QuizCell *cell = [array objectAtIndex:0];
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
