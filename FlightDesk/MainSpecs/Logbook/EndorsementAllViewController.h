//
//  EndorsementAllViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/26/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EndorsementAllViewController : UIViewController
{
    UIButton *addButton;
    __weak IBOutlet UITableView *EndorsementTableview;
    __weak IBOutlet UISegmentedControl *segmentsTypeOfEndorsement;
    
    __weak IBOutlet UIView *addEndorsementCV;
    __weak IBOutlet UIView *addEndorsementDialog;
    __weak IBOutlet UITextView *endorsementTxtView;
    __weak IBOutlet UILabel *lblCfi;
    __weak IBOutlet UIButton *btnEndorsementSign;
    __weak IBOutlet UIButton *btnEndorsementDate;
    __weak IBOutlet UIButton *btnExpirationDate;
    __weak IBOutlet UIButton *btnSupersed;
    __weak IBOutlet UIButton *btnChangeEndorsement;
    __weak IBOutlet UIButton *btnAddEndorsment;
    __weak IBOutlet UITextField *cfiNumTxtField;
    
    __weak IBOutlet NSLayoutConstraint *dialogHeightConstraints;
    __weak IBOutlet NSLayoutConstraint *dialogBottomPaddingConstraints;
    __weak IBOutlet UIView *supersedView;
    __weak IBOutlet NSLayoutConstraint *endorsmentsTypeConstraints;
    
}
- (IBAction)onChangeTypeOfEndorsement:(id)sender;

- (IBAction)onSave:(id)sender;
- (IBAction)onCancel:(id)sender;

- (IBAction)onSelectEndorsement:(id)sender;
- (IBAction)onSignEndorsement:(id)sender;
- (IBAction)onDateEndorsement:(id)sender;
- (IBAction)onExpirationEndorsementDate:(id)sender;
- (IBAction)onSupersed:(id)sender;

@end
