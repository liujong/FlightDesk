//
//  LogEndorsementCell.h
//  FlightDesk
//
//  Created by Liu Jie on 1/23/18.
//  Copyright © 2018 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogEndorsementCell;
@protocol LogEndorsementCellDelegate
@optional;
-(void)didSignatureWithCell:(LogEndorsementCell *)cell;
-(void)didEndorsementDateWithCell:(LogEndorsementCell *)cell;
-(void)didEndorsementExpDateWithCell:(LogEndorsementCell *)cell;
-(void)didAdditionalEndorsementWithCell:(LogEndorsementCell *)cell;
-(void)didAddEndorsementWithCell:(LogEndorsementCell *)cell;
-(void)didSupersedWithCell:(LogEndorsementCell *)cell withFlag:(BOOL)isFlag;
-(void)didEndEditingWithTextView:(LogEndorsementCell *)cell withText:(NSString *)_text;
-(void)didCancelEndorsementWithCell:(LogEndorsementCell *)cell;
@end

@interface LogEndorsementCell : UITableViewCell<UITextViewDelegate>
+ (EndorsementCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UITextView *endorsementTxtView;
@property (weak, nonatomic) IBOutlet UILabel *lblCFINumber;
@property (weak, nonatomic) IBOutlet UIButton *btnSingature;
@property (weak, nonatomic) IBOutlet UIButton *btnEndorsementDate;
@property (weak, nonatomic) IBOutlet UIButton *btnEndorsementExpDate;
@property (weak, nonatomic) IBOutlet UIView *supersedMaskView;
@property (weak, nonatomic) IBOutlet UIButton *btnAdditionalEndorsement;
@property (weak, nonatomic) IBOutlet UIButton *btnAddEndorsement;
@property (weak, nonatomic) IBOutlet UIButton *btnChangeEndorsement;
@property (weak, nonatomic) IBOutlet UIButton *btnSuporsed;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;


@property (nonatomic, weak, readwrite) id <LogEndorsementCellDelegate> endorsementDelegate;

- (IBAction)onSignature:(id)sender;
- (IBAction)onEndorsementDate:(id)sender;
- (IBAction)onEndorsementExpDate:(id)sender;
- (IBAction)onAdditionalEndorsement:(id)sender;
- (IBAction)onAddEndorsement:(id)sender;
- (IBAction)onChangeEndorsement:(id)sender;
- (IBAction)onSupersed:(id)sender;
- (IBAction)onCancel:(id)sender;


@end
