//
//  CheckListsMainCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CheckListsMainCell;
@protocol CheckListsMainCellDelegate
@optional;
- (void)deleteCurrentCategory:(CheckListsMainCell *)_cell;
- (void)updateCategory:(CheckListsMainCell *)_cell;
@end

@interface CheckListsMainCell : UICollectionViewCell


@property (nonatomic, weak, readwrite) id <CheckListsMainCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *categoryCV;
@property (weak, nonatomic) IBOutlet UILabel *lblChecklistCategory;
@property (weak, nonatomic) IBOutlet UITextView *checklistCategoryTxtView;
@property (weak, nonatomic) IBOutlet UIView *deleteView;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;
@property (weak, nonatomic) IBOutlet UIView *editBtnCV;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
- (IBAction)onDelete:(id)sender;
- (IBAction)onEdit:(id)sender;

@property(nonatomic,strong)NSDictionary *dic;

@end
