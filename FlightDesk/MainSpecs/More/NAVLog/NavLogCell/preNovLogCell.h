//
//  preNovLogCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class preNovLogCell;
@protocol preNovLogCellDelegate
@optional;
- (void)didUpdatePreNavLog:(NSMutableDictionary *)contentInfo cell:(preNovLogCell *)_cell;
- (void)returnLastTextfield:(preNovLogCell *)_cell;
- (void)beginedToEditCurrentCell:(preNovLogCell *)_cell;
@end

@interface preNovLogCell : UITableViewCell<UITextFieldDelegate, UITextViewDelegate>
+ (preNovLogCell *)sharedCell;
@property (nonatomic, weak, readwrite) id <preNovLogCellDelegate> delegate;
@property (strong,nonatomic)NSMutableDictionary *datadict;



/** Check Point **/
@property (weak, nonatomic) IBOutlet UILabel *DescriptionLblTxt;
@property (weak, nonatomic) IBOutlet UITextView *txtViewCheckPoint;
/** Vor Ident **/
@property (weak, nonatomic) IBOutlet UITextField *identTextField;
/** Vor Freq. **/
@property (weak, nonatomic) IBOutlet UITextField *freqTextField;
/** Vor To. **/
@property (weak, nonatomic) IBOutlet UITextField *toTextField;
/** Vor From. **/
@property (weak, nonatomic) IBOutlet UITextField *fromTextField;

- (void)savePreNavLog:(NSMutableDictionary *)dict;
@end
