//
//  ContentEditCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@class ContentEditCell;
@protocol ContentEditCellDelegate
@optional;
- (void)didAddContent:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell withType:(NSInteger)_type;
- (void)didCheckedRemarks:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell selected:(BOOL)_selected withType:(NSInteger)_type;
- (void)didCheckedCheckBox:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell selected:(BOOL)_selected withType:(NSInteger)_type;
- (void)fieldTableCell:(ContentEditCell *)cell textDidChange:(NSString *)text withType:(NSInteger)_type;
- (void)fieldTableCellTextFieldDidReturn:(ContentEditCell *)cell withType:(NSInteger)_type;
@end

@interface ContentEditCell : SWTableViewCell<UITextFieldDelegate>
+ (ContentEditCell *)sharedCell;
@property (nonatomic, weak, readwrite) id <ContentEditCellDelegate> contentDelegate;
@property (weak, nonatomic) IBOutlet UITextField *txtContent;
@property (nonatomic, retain) NSMutableDictionary *currentDist;

- (IBAction)onAddContent:(id)sender;


@property (weak, nonatomic) IBOutlet UIImageView *imgRemark;
@property (weak, nonatomic) IBOutlet UIButton *btnRemark;
- (IBAction)onCheckForRemark:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *imgCheck;
@property (weak, nonatomic) IBOutlet UIButton *btnCheck;
- (IBAction)onCheckForCheck:(id)sender;


- (void)saveContentInfo:(NSMutableDictionary *)dict type:(NSInteger)_type;
@property NSInteger contenttype;

@end
