//
//  AddRCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddRCell.h"

@implementation AddRCell
+ (AddRCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"AddRCell" owner:nil options:nil];
    AddRCell *cell = [array objectAtIndex:0];
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

- (IBAction)onAddItem:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionItem1 = [UIAlertAction actionWithTitle:@"Group" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"group"];
    }];
    UIAlertAction* actionItem2 = [UIAlertAction actionWithTitle:@"Checklist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"checklist"];
    }];
    UIAlertAction* actionItem3 = [UIAlertAction actionWithTitle:@"Warning" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"w"];
    }];
    UIAlertAction* actionItem4 = [UIAlertAction actionWithTitle:@"Notice" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"n"];
    }];
    UIAlertAction* actionItem5 = [UIAlertAction actionWithTitle:@"Title" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"t"];
    }];
    UIAlertAction* actionItem6 = [UIAlertAction actionWithTitle:@"P" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"p"];
    }];
    UIAlertAction* actionItem7 = [UIAlertAction actionWithTitle:@"C" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"c"];
    }];
    UIAlertAction* actionItem8 = [UIAlertAction actionWithTitle:@"R" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromRCell:self withType:@"r"];
    }];
    
    [alert addAction:actionItem1];
    [alert addAction:actionItem2];
    [alert addAction:actionItem3];
    [alert addAction:actionItem4];
    [alert addAction:actionItem5];
    [alert addAction:actionItem6];
    [alert addAction:actionItem7];
    [alert addAction:actionItem8];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = self.btnAdd;
    popPresenter.sourceRect = self.btnAdd.bounds;
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    
}
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField == self.preContentTxtField) {
        [self.delegate updatedContentFromRCell:self withContent:[NSString stringWithFormat:@"%@~%@", text, self.tailContentTxtField.text]];
    }else if (textField == self.tailContentTxtField){
        [self.delegate updatedContentFromRCell:self withContent:[NSString stringWithFormat:@"%@~%@", self.preContentTxtField.text, text]];
    }
    
    return YES;
}

@end
