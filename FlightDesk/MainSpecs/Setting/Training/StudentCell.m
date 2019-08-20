//
//  StudentCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "StudentCell.h"

@implementation StudentCell
+ (StudentCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"StudentCell" owner:nil options:nil];
    StudentCell *cell = [array objectAtIndex:0];
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
- (void)setCurrentStudent:(Student *)_student{
    self.currentStudent = _student;
}

- (IBAction)onAddStudentView:(id)sender {
    [self.delegateWithStudent didRequestStudent:self];
}


@end
