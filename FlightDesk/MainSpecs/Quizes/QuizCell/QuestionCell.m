//
//  QuestionCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "QuestionCell.h"

@implementation QuestionCell
+ (QuestionCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"QuestionCell" owner:nil options:nil];
    QuestionCell *cell = [array objectAtIndex:0];
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

- (void)setDist:(NSDictionary *)dist{
    self.currentDist = dist;
}

@end
