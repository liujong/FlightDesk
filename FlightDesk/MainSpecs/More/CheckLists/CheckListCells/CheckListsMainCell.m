//
//  CheckListsMainCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "CheckListsMainCell.h"

@implementation CheckListsMainCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (IBAction)onDelete:(id)sender {
    if (self.btnDelete.selected == YES) {
        [self endEditing:YES];
        self.lblChecklistCategory.hidden = NO;
        self.checklistCategoryTxtView.hidden = YES;
        self.lblChecklistCategory.text= self.checklistCategoryTxtView.text;
        self.editBtnCV.layer.borderColor = [UIColor colorWithRed:68.0f/255.0f green:68.0f/255.0f blue:68.0f/255.0f alpha:1.0f].CGColor;
        [self.btnEdit setImage:[UIImage imageNamed:@"edit_checklist"] forState:UIControlStateNormal];
        [self.btnDelete setImage:[UIImage imageNamed:@"del_checklist"] forState:UIControlStateNormal];
        self.btnDelete.selected = NO;
    }else{
        [self.delegate deleteCurrentCategory:self];
    }
}

- (IBAction)onEdit:(id)sender {
    self.btnEdit.selected = !self.btnEdit.selected;
    if (self.btnEdit.selected == YES) {
        self.lblChecklistCategory.hidden = YES;
        self.checklistCategoryTxtView.hidden = NO;
        self.checklistCategoryTxtView.text= self.lblChecklistCategory.text;
        [self.checklistCategoryTxtView becomeFirstResponder];
        [self.btnEdit setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
        self.editBtnCV.layer.borderColor = [UIColor colorWithRed:156.0f/255.0f green:210.0f/255.0f blue:17.0f/255.0f alpha:1.0f].CGColor;
        [self.btnDelete setImage:[UIImage imageNamed:@"wrong.png"] forState:UIControlStateNormal];
        self.btnDelete.selected = YES;
    }else{
        [self endEditing:YES];
        self.lblChecklistCategory.hidden = NO;
        self.checklistCategoryTxtView.hidden = YES;
        self.lblChecklistCategory.text= self.checklistCategoryTxtView.text;
        self.editBtnCV.layer.borderColor = [UIColor colorWithRed:68.0f/255.0f green:68.0f/255.0f blue:68.0f/255.0f alpha:1.0f].CGColor;
        [self.btnEdit setImage:[UIImage imageNamed:@"edit_checklist"] forState:UIControlStateNormal];
        [self.btnDelete setImage:[UIImage imageNamed:@"del_checklist"] forState:UIControlStateNormal];
        self.btnDelete.selected = NO;
        [self.delegate updateCategory:self];
    }
}

- (void)setDic:(NSDictionary *)dic {
    
    _dic = dic;
    NSLog(@"sfsfsf");
}
@end
