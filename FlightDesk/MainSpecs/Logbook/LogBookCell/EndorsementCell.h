//
//  EndorsementCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/20/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@class EndorsementCell;
@protocol EndorsementCellDelegate
@optional;
-(void)didSignatureWithCell:(EndorsementCell *)cell;
-(void)didEndorsementDateWithCell:(EndorsementCell *)cell;
-(void)didEndorsementExpDateWithCell:(EndorsementCell *)cell;
-(void)didAdditionalEndorsementWithCell:(EndorsementCell *)cell;
-(void)didAddEndorsementWithCell:(EndorsementCell *)cell;
-(void)didSupersedWithCell:(EndorsementCell *)cell withFlag:(BOOL)isFlag;
-(void)didEndEditingWithTextView:(EndorsementCell *)cell withText:(NSString *)_text;
-(void)didCancelEndorsementWithCell:(EndorsementCell *)cell;
@end

@interface EndorsementCell : SWTableViewCell<UITextViewDelegate>
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


@property (nonatomic, weak, readwrite) id <EndorsementCellDelegate> endorsementDelegate;

- (IBAction)onSignature:(id)sender;
- (IBAction)onEndorsementDate:(id)sender;
- (IBAction)onEndorsementExpDate:(id)sender;
- (IBAction)onAdditionalEndorsement:(id)sender;
- (IBAction)onAddEndorsement:(id)sender;
- (IBAction)onChangeEndorsement:(id)sender;
- (IBAction)onSupersed:(id)sender;
- (IBAction)onCancel:(id)sender;


@end
