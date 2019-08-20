//
//  VerfiyViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VerfiyViewController;
@protocol VerfiyViewControllerDelegate

@optional;
- (void)returnVerifyView:(VerfiyViewController *)verifyView;
- (void)cancelVerifyView:(VerfiyViewController *)verifyView;
@end

@interface VerfiyViewController : UIViewController{

    __weak IBOutlet UIView *verificationDialog;
    __weak IBOutlet UITextField *code1;
    __weak IBOutlet UITextField *code2;
    __weak IBOutlet UITextField *code3;
    __weak IBOutlet UITextField *code4;
    __weak IBOutlet UITextField *code5;
    __weak IBOutlet UITextField *code6;
    __weak IBOutlet NSLayoutConstraint *dialogBottomCons;
    __weak IBOutlet UILabel *lblEmailVerifyDes;
    __weak IBOutlet UILabel *lblTimer;
    __weak IBOutlet UIButton *btnResendVerifyCode;
    
    __weak IBOutlet UIView *emailUpdateView;
    __weak IBOutlet UIView *emailUpdateDialog;
    __weak IBOutlet UITextField *txtChangeEmail;
    
    
}
- (IBAction)resendVerificationCode:(id)sender;
- (IBAction)onVerify:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onShowChangeEmailView:(id)sender;
- (IBAction)onUpdateEmail:(id)sender;
- (IBAction)onCancelUpdateEmail:(id)sender;

@property (nonatomic, weak, readwrite) id <VerfiyViewControllerDelegate> delegate;
@property NSInteger verifiyType;
- (void)animateHide;
- (void)animateShow;
@end
