//
//  NavLogCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeViewController.h"

@class NavLogCell;
@protocol NavLogCellDelegate
@optional;
- (void)didUpdateNavLogRecord:(NSMutableDictionary *)contentInfo cell:(NavLogCell *)_cell;
- (void)didClacReg:(NSString *)disRemTxt cell:(NavLogCell *)_cell;
- (void)startedToEditCurrentCell:(NavLogCell *)_cell;
- (void)returnedToEditCurrentCell:(NavLogCell *)_cell;
@end

@interface NavLogCell : UITableViewCell<UITextFieldDelegate, TimeViewControllerDelegate>
+ (NavLogCell *)sharedCell;
@property (nonatomic, weak, readwrite) id <NavLogCellDelegate> delegate;
@property (strong,nonatomic)NSMutableDictionary *datadict;
@property (strong,nonatomic)NSString *distRem;
@property (strong,nonatomic)NSString *headerTimeOff;
@property (strong,nonatomic)NSString *headerFuelLoad;
@property (strong,nonatomic)NSString *headerGPH;


@property (weak, nonatomic) IBOutlet UITextField *courseTextField;
@property (weak, nonatomic) IBOutlet UITextField *attitudeTextField;

@property (weak, nonatomic) IBOutlet UITextField *windDirTextField;
@property (weak, nonatomic) IBOutlet UITextField *windVelTextField;
@property (weak, nonatomic) IBOutlet UITextField *windTempTextField;
@property (weak, nonatomic) IBOutlet UITextField *casTasValueTextField;

@property (weak, nonatomic) IBOutlet UITextField *tcTextField;
@property (weak, nonatomic) IBOutlet UITextField *thFieldField;
@property (weak, nonatomic) IBOutlet UITextField *mhTextField;
@property (weak, nonatomic) IBOutlet UITextField *wcaTextField;
@property (weak, nonatomic) IBOutlet UITextField *varTextField;
@property (weak, nonatomic) IBOutlet UITextField *devTextField;
@property (weak, nonatomic) IBOutlet UITextField *chAnsTextField;

@property (weak, nonatomic) IBOutlet UITextField *leg12TextField;
@property (weak, nonatomic) IBOutlet UITextField *legSumTextField;
@property (weak, nonatomic) IBOutlet UITextField *estTextField;
@property (weak, nonatomic) IBOutlet UITextField *actTextField;

@property (weak, nonatomic) IBOutlet UITextField *timeOffTextField;
@property (weak, nonatomic) IBOutlet UITextField *fuelTextField;
@property (weak, nonatomic) IBOutlet UITextField *gphTextField;
@property (weak, nonatomic) IBOutlet UITextField *gphRemTextField;
@property (weak, nonatomic) IBOutlet UITextField *timeOffATETextField;
@property (weak, nonatomic) IBOutlet UITextField *fuelATATextField;
- (IBAction)onGetTimeOfATE:(id)sender;
- (IBAction)onGetFuelATA:(id)sender;
@property BOOL isOpenTimeView;
- (void)saveNavLogRecord:(NSMutableDictionary *)dict;
@end
