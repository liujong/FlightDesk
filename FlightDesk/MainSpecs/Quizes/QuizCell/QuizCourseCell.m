//
//  QuizCourseCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "QuizCourseCell.h"

@implementation QuizCourseCell
+ (QuizCourseCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"QuizCourseCell" owner:nil options:nil];
    QuizCourseCell *cell = [array objectAtIndex:0];
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
