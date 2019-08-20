//
//  CheckListContentCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "CheckListContentCell.h"

@implementation CheckListContentCell
+ (CheckListContentCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"CheckListContentCell" owner:nil options:nil];
    CheckListContentCell *cell = [array objectAtIndex:0];
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

- (IBAction)onCheck:(id)sender {
    self.btnCheckListItem.selected = !self.btnCheckListItem.selected;
//    if (self.btnCheckListItem.selected) {
//        self.checkListContentLBL.textColor = [UIColor greenColor];
//        self.lblBridge.textColor = [UIColor greenColor];
//        self.lblCheckListContentValue.textColor = [UIColor greenColor];
//        self.btnCheckListItem.layer.borderColor = [UIColor greenColor].CGColor;
//    }else{
//        self.checkListContentLBL.textColor = [UIColor colorWithRed:45.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
//        self.lblBridge.textColor = [UIColor colorWithRed:45.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
//        self.lblCheckListContentValue.textColor = [UIColor colorWithRed:45.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
//        self.btnCheckListItem.layer.borderColor = [UIColor colorWithRed:45.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f].CGColor;
//    }
    
    
    [self.delegateToUpdate didCheckedCheckListItem:self withStatus:self.btnCheckListItem.selected];
}
@end
