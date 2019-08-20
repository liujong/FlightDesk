//
//  PilotProfileViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PilotProfileViewController : UIViewController{
    __weak IBOutlet UITextField *txtFirstName;
    __weak IBOutlet UITextField *txtMiddleName;
    __weak IBOutlet UITextField *txtLastName;
    __weak IBOutlet UITextField *txtEmail;
    __weak IBOutlet UITextField *txtPhonenumber;
    __weak IBOutlet UITextField *txtPilotCertification;
    __weak IBOutlet UITextField *txtPilotCerIssueDate;
    __weak IBOutlet UITextField *txtMedicalCertiIssueDate;
    __weak IBOutlet UITextField *txtMedicalCertiExpireDate;
    
    __weak IBOutlet UIButton *btnRole;
    __weak IBOutlet UILabel *lblCFICertiExpirationDate;
    __weak IBOutlet UILabel *tipLblCFICertiExpiraDate;
    __weak IBOutlet UITextField *txtCFIDate;
    __weak IBOutlet UIButton *btnCfiCertExpDate;
    
    __weak IBOutlet UITextField *txtUserName;
    __weak IBOutlet UITextField *txtPassword;
    __weak IBOutlet UIButton *btnShowHide;
    
    __weak IBOutlet UITableView *RoleTableView;
    __weak IBOutlet UILabel *lblQuestion;
    __weak IBOutlet UITextField *txtAnswer;
    __weak IBOutlet UIButton *btnAnswerShowHide;
    
    __weak IBOutlet UIScrollView *scrView;
    __weak IBOutlet UILabel *medicalExpirationBadge;
    __weak IBOutlet UILabel *cfiExpirationBadge;
}
- (IBAction)onRole:(UIButton *)sender;
- (IBAction)onShowHidePwd:(UIButton *)sender;
- (IBAction)onShowHideAnswer:(id)sender;
- (IBAction)onSelectQuestion:(id)sender;

- (IBAction)onGetPilotCertIssueDate:(id)sender;
- (IBAction)onMedicalCertIssueDate:(id)sender;
- (IBAction)onMedicalCertExpDate:(id)sender;
- (IBAction)onCFICertExpDate:(id)sender;
@end
