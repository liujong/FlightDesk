//
//  ProgramCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ProgramCell.h"

@implementation ProgramCell


+ (ProgramCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ProgramCell" owner:nil options:nil];
    ProgramCell *cell = [array objectAtIndex:0];
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
- (void)saveProgramInfo:(NSString *)program{
    self.currentProgram = program;
}

@end
