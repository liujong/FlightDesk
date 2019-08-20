//
//  ContentEditCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ContentEditCell.h"

@implementation ContentEditCell
@synthesize imgRemark, btnRemark;
@synthesize imgCheck, btnCheck;
+ (ContentEditCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"ContentEditCell" owner:nil options:nil];
    ContentEditCell *cell = [array objectAtIndex:0];
    return cell;
}

- (IBAction)onAddContent:(id)sender {
    [self.contentDelegate didAddContent:self.currentDist cell:self withType:self.contenttype];
}

- (IBAction)onCheckForRemark:(id)sender {
    btnRemark.selected = !btnRemark.selected;
    if (btnRemark.selected) {
        [imgRemark setImage:[UIImage imageNamed:@"right.png"]];
    }else{
        [imgRemark setImage:nil];
    }
    
    [self.contentDelegate didCheckedRemarks:self.currentDist cell:self  selected:btnRemark.selected withType:self.contenttype];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)onCheckForCheck:(id)sender {
    btnCheck.selected = !btnCheck.selected;
    if (btnCheck.selected) {
        [imgCheck setImage:[UIImage imageNamed:@"right.png"]];
    }else{
        [imgCheck setImage:nil];
    }
    
    [self.contentDelegate didCheckedCheckBox:self.currentDist cell:self  selected:btnCheck.selected withType:self.contenttype];
}

- (void)saveContentInfo:(NSMutableDictionary *)dict type:(NSInteger)_type{
    self.currentDist = dict;
    self.txtContent.delegate = self;
    self.contenttype = _type;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self.contentDelegate fieldTableCell:self textDidChange:text withType:self.contenttype];
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.contentDelegate fieldTableCellTextFieldDidReturn:self withType:self.contenttype];
    return NO;
}
@end
