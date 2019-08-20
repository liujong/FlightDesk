//
//  RegisterViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/31/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RegisterViewController;
@protocol RegisterViewControllerDelegate

@optional;
- (void)loginButtonTappedInRegisterView;
- (void)registerButtonTappedInRegisterView:(RegisterViewController *)registerView;
@end

@interface RegisterViewController : UIViewController
{
    __weak IBOutlet UIView *registerDialogView;
    __weak IBOutlet UITextField *txtFname;
    __weak IBOutlet UITextField *txtMname;
    __weak IBOutlet UITextField *txtLname;
    __weak IBOutlet UITextField *txtEmail;
    __weak IBOutlet UITextField *txtPhone;
    __weak IBOutlet UITextField *txtPilotCertificate;
    __weak IBOutlet UITextField *txtPilotCertIssDate;
    __weak IBOutlet UITextField *txtMedicalCertIssueDate;
    __weak IBOutlet UITextField *txtMedicalCertExpDate;
    
    __weak IBOutlet UIButton *btnSelectRole;
    __weak IBOutlet UILabel *lblCFI;
    __weak IBOutlet UILabel *lblCFITip;
    __weak IBOutlet UITextField *txtCFICertExpDate;
    __weak IBOutlet UIButton *btnCFICertExpDate;

    __weak IBOutlet UITextField *txtUsername;
    __weak IBOutlet UITextField *txtPassword;
    __weak IBOutlet UILabel *lblQuestion;
    __weak IBOutlet UITextField *txtAnswer;
    __weak IBOutlet UIButton *btnShowHide;
    __weak IBOutlet UIButton *btnShowHideRecovery;
    
    __weak IBOutlet UITableView *RoleTableView;
    __weak IBOutlet UIScrollView *scrView;
}
@property (nonatomic, weak, readwrite) id <RegisterViewControllerDelegate> delegate;

- (void)animateHide;
- (void)animateShow;
- (IBAction)onLoginFromPilot:(id)sender;
- (IBAction)onRegisterFromPilot:(id)sender;
- (IBAction)onShowHidePassword:(id)sender;
- (IBAction)onShowHideRecovery:(id)sender;
- (IBAction)onSelectRole:(id)sender;
- (IBAction)onSelectQuestion:(id)sender;

- (IBAction)onGetPilotCertIssueDate:(id)sender;
- (IBAction)onMedicalCertIssueDate:(id)sender;
- (IBAction)onMedicalCertExpDate:(id)sender;
- (IBAction)onCFICertExpDate:(id)sender;



@end
