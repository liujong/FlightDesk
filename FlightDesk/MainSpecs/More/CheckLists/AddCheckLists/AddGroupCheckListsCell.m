//
//  AddGroupCheckListsCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddGroupCheckListsCell.h"

@implementation AddGroupCheckListsCell
+ (AddGroupCheckListsCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"AddGroupCheckListsCell" owner:nil options:nil];
    AddGroupCheckListsCell *cell = [array objectAtIndex:0];
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
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"group"];
    }];
    UIAlertAction* actionItem2 = [UIAlertAction actionWithTitle:@"Checklist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"checklist"];
    }];
    UIAlertAction* actionItem3 = [UIAlertAction actionWithTitle:@"Warning" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"w"];
    }];
    UIAlertAction* actionItem4 = [UIAlertAction actionWithTitle:@"Notice" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"n"];
    }];
    UIAlertAction* actionItem5 = [UIAlertAction actionWithTitle:@"Title" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"t"];
    }];
    UIAlertAction* actionItem6 = [UIAlertAction actionWithTitle:@"P" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"p"];
    }];
    UIAlertAction* actionItem7 = [UIAlertAction actionWithTitle:@"C" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"c"];
    }];
    UIAlertAction* actionItem8 = [UIAlertAction actionWithTitle:@"R" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate didAddedItemFromGroupCheckCell:self withType:@"r"];
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
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];;
    [self.delegate updateContentFromGroupCheckCell:self withContent:text];
    return  YES;
}
@end
