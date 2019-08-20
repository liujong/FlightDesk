//
//  preNovLogCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "preNovLogCell.h"

@implementation preNovLogCell
+ (preNovLogCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"preNovLogCell" owner:nil options:nil];
    preNovLogCell *cell = [array objectAtIndex:0];
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
- (void)savePreNavLog:(NSMutableDictionary *)dict{
    self.datadict = dict;
    _DescriptionLblTxt.text = @"";
    if (![[dict objectForKey:@"checkPoint"] isEqualToString:@""]) {
        _DescriptionLblTxt.text = [dict objectForKey:@"checkPoint"];
    }
    _identTextField.text = @"";
    if (![[dict objectForKey:@"vorIdent"] isEqualToString:@""]) {
        _identTextField.text = [dict objectForKey:@"vorIdent"];
    }
    _freqTextField.text = @"";
    if (![[dict objectForKey:@"vorFreq"] isEqualToString:@""]) {
        _freqTextField.text = [dict objectForKey:@"vorFreq"];
    }
    _toTextField.text = @"";
    if (![[dict objectForKey:@"vorTo"] isEqualToString:@""]) {
        _toTextField.text = [dict objectForKey:@"vorTo"];
    }
    _fromTextField.text = @"";
    if (![[dict objectForKey:@"vorFrom"] isEqualToString:@""]) {
        _fromTextField.text = [dict objectForKey:@"vorFrom"];
    }
}
#pragma mark- TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.delegate beginedToEditCurrentCell:self];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == _identTextField) {
        [_freqTextField becomeFirstResponder];
    }else if (textField == _freqTextField) {
        [_toTextField becomeFirstResponder];
    }else if (textField == _toTextField) {
        [_fromTextField becomeFirstResponder];
    }else if (textField == _fromTextField) {
        [self.delegate returnLastTextfield:self];
    }
    return  YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField == _identTextField) {
        [self.datadict setObject:text forKey:@"vorIdent"];
    }else if (textField == _freqTextField) {
        [self.datadict setObject:text forKey:@"vorFreq"];
    }else if (textField == _toTextField) {
        [self.datadict setObject:text forKey:@"vorTo"];
    }else if (textField == _fromTextField) {
        [self.datadict setObject:text forKey:@"vorFrom"];
    }
    [self.delegate didUpdatePreNavLog:self.datadict cell:self];
    return YES;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView{
    _txtViewCheckPoint.text = _DescriptionLblTxt.text;
    _DescriptionLblTxt.text = @"";
    [self.delegate beginedToEditCurrentCell:self];
}
- (void)textViewDidEndEditing:(UITextView *)textView{
    
    [self.datadict setObject:_txtViewCheckPoint.text forKey:@"checkPoint"];
    _DescriptionLblTxt.text = _txtViewCheckPoint.text;
    _txtViewCheckPoint.text = @"";
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSString *textStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self.datadict setObject:textStr forKey:@"checkPoint"];
    [self.delegate didUpdatePreNavLog:self.datadict cell:self];
    return YES;
}
@end
