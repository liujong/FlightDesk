//
//  ItemCell.h
//  FlightDesk
//
//  Created by Liu Jie on 8/8/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@class ItemCell;
@protocol ItemCellDelegate
@optional;
- (void)textFieldDidBeginEditingWithItem:(ItemCell *)_cell;
- (BOOL)shouldChangeCharactersWithItem:(ItemCell *)_cell InRange:(NSRange)range replacementString:(NSString *)string;
- (BOOL)shouldReturnWithItem:(ItemCell *)_cell;
- (void)didPopupDateDialog:(ItemCell *)_cell;
- (void)didPopupLookDialog:(ItemCell *)_cell;
- (void)didAnnualDialog:(ItemCell *) _cell;
- (void)didEndEditingTextFieldWithCell:(ItemCell *)_cell;
@end

@interface ItemCell : SWTableViewCell<UITextFieldDelegate>
+ (ItemCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblFieldName;
@property (weak, nonatomic) IBOutlet UITextField *txtContent;
@property (weak, nonatomic) IBOutlet UILabel *lblBannerAlertCount;
@property (weak, nonatomic) IBOutlet UIButton *btnPopup;
@property (weak, nonatomic) IBOutlet UIButton *btnPopupLook;
@property (weak, nonatomic) IBOutlet UILabel *currentReading;
@property (weak, nonatomic) IBOutlet UIButton *btnAnnual;


- (IBAction)onPopupDialog:(id)sender;
- (IBAction)onPopupLookDialog:(UIButton *)sender;
- (IBAction)onAnnualDialog:(UIButton *)sender;

@property (nonatomic, weak, readwrite) id <ItemCellDelegate> itemDelegate;

@end
