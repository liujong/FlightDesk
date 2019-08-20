//
//  LoginViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;
@protocol LoginViewControllerDelegate

@optional;
- (void)loginSuccessfuly:(LoginViewController *)loginView;
- (void)gotoRegisterView:(LoginViewController *)loginView;
- (void)securityViewCancel:(LoginViewController *)loginView;
- (void)securityViewDone:(LoginViewController *)loginView question:(NSString *)_question answer:(NSString *)_answer;
@end
@interface LoginViewController : UIViewController{
    //login view
    __weak IBOutlet UIView *bgLogin;
    __weak IBOutlet UITextField *txtUsername;
    __weak IBOutlet UITextField *txtPassword;
    __weak IBOutlet UIButton *btnForgotPassword;
    __weak IBOutlet UIButton *btnPwdShowHide;
    
    //security question
    __weak IBOutlet UIView *bgSecurtyQuestion;
    __weak IBOutlet UITextField *txtSecurityQuestion;
    __weak IBOutlet UITextField *txtAnswer;
    __weak IBOutlet UIButton *btnSecurityQShowHide;
    __weak IBOutlet UITableView *QuestionTableView;
    __weak IBOutlet UILabel *securityQuestionTitle;
    
    __weak IBOutlet NSLayoutConstraint *bgLoginViewCons;
    __weak IBOutlet NSLayoutConstraint *bgSecurityViewCons;
    
}

- (void)animateHideLoginView;
- (void)animateShowLoginView;
- (void)animateHideSecuView;
- (void)animateShowSecuView;

- (IBAction)onLogin:(id)sender;
- (IBAction)onForgotPassword:(id)sender;
- (IBAction)onPwdShowHide:(id)sender;
- (IBAction)onRelease:(UIButton *)sender;


- (IBAction)onSecurityQuestionDone:(id)sender;
- (IBAction)onSecurityQShowHide:(id)sender;
- (IBAction)onSecurityQuestionCancel:(id)sender;

@property (nonatomic, weak, readwrite) id <LoginViewControllerDelegate> delegate;
@property BOOL isLogin;

@end
