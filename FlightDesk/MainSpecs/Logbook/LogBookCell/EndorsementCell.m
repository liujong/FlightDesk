//
//  EndorsementCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/20/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "EndorsementCell.h"

@implementation EndorsementCell
+ (EndorsementCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"EndorsementCell" owner:nil options:nil];
    EndorsementCell *cell = [array objectAtIndex:0];
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

- (IBAction)onSignature:(id)sender {
    [self.endorsementDelegate didSignatureWithCell:self];
}

- (IBAction)onEndorsementDate:(id)sender {
    [self.endorsementDelegate didEndorsementDateWithCell:self];
}

- (IBAction)onEndorsementExpDate:(id)sender {
    [self.endorsementDelegate didEndorsementExpDateWithCell:self];
}

- (IBAction)onAdditionalEndorsement:(id)sender {
    [self.endorsementDelegate didAdditionalEndorsementWithCell:self];
}

- (IBAction)onAddEndorsement:(id)sender {
    [self.endorsementDelegate didAddEndorsementWithCell:self];
}

- (IBAction)onChangeEndorsement:(id)sender {
    [self.endorsementDelegate didAddEndorsementWithCell:self];
}

- (IBAction)onSupersed:(id)sender {
    [self.endorsementDelegate didSupersedWithCell:self withFlag:!_supersedMaskView.hidden];
}

- (IBAction)onCancel:(id)sender {
    [self.endorsementDelegate didCancelEndorsementWithCell:self];
}

#pragma mark UITextViewendorsementDelegate
- (void)textViewDidEndEditing:(UITextView *)textView{
    [self.endorsementDelegate didEndEditingWithTextView:self withText:textView.text];
}

@end
