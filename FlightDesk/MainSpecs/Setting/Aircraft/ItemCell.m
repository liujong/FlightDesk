//
//  ItemCell.m
//  FlightDesk
//
//  Created by Liu Jie on 8/8/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ItemCell.h"

@implementation ItemCell
+ (ItemCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ItemCell" owner:nil options:nil];
    ItemCell *cell = [array objectAtIndex:0];
    return cell;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.lblBannerAlertCount.layer.cornerRadius = self.lblBannerAlertCount.frame.size.height / 2.0f;
    self.lblBannerAlertCount.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.itemDelegate textFieldDidBeginEditingWithItem:self];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    BOOL isResult = [self.itemDelegate shouldReturnWithItem:self];
    return isResult;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self.itemDelegate didEndEditingTextFieldWithCell:self];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    BOOL isResult = [self.itemDelegate shouldChangeCharactersWithItem:self InRange:range replacementString:string];
    return isResult;
}
- (IBAction)onPopupDialog:(id)sender {
    [self.itemDelegate didPopupDateDialog:self];
}

- (IBAction)onPopupLookDialog:(UIButton *)sender {
    [self.itemDelegate didPopupLookDialog:self];
}

- (IBAction)onAnnualDialog:(UIButton *)sender {
    //[self.itemDelegate didAnnualDialog:self];
}
@end
