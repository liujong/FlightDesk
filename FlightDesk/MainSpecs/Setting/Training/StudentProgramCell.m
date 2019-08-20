//
//  StudentProgramCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "StudentProgramCell.h"

@implementation StudentProgramCell
@synthesize btnSelect, selectImageView;


+ (StudentProgramCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"StudentProgramCell" owner:nil options:nil];
    StudentProgramCell *cell = [array objectAtIndex:0];
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
- (IBAction)onChangeOrAddInstructor:(id)sender {
    [self.delegate didRequestInstructor:self];
}


- (IBAction)onSelect:(id)sender {
    btnSelect.selected = !btnSelect.selected;
    
    if (btnSelect.selected) {
        [selectImageView setImage:[UIImage imageNamed:@"right.png"]];
    }else{
        [selectImageView setImage:nil];
    }
    
    [self.delegate didChecked:self selected:btnSelect.selected];
}
@end
