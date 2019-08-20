//
//  LoginViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSArray *arrQuestions;
}
@end

@implementation LoginViewController
@synthesize isLogin;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    bgLogin.hidden = YES;
    bgSecurtyQuestion.hidden = YES;
    
    bgLogin.autoresizesSubviews = NO;
    bgLogin.contentMode = UIViewContentModeRedraw;
    bgLogin.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    bgLogin.layer.shadowRadius = 3.0f;
    bgLogin.layer.shadowOpacity = 1.0f;
    bgLogin.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    bgLogin.layer.shadowPath = [UIBezierPath bezierPathWithRect:bgLogin.bounds].CGPath;
    bgLogin.layer.cornerRadius = 5.0f;
    
    bgSecurtyQuestion.autoresizesSubviews = NO;
    bgSecurtyQuestion.contentMode = UIViewContentModeRedraw;
    bgSecurtyQuestion.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    bgSecurtyQuestion.layer.shadowRadius = 3.0f;
    bgSecurtyQuestion.layer.shadowOpacity = 1.0f;
    bgSecurtyQuestion.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    bgSecurtyQuestion.layer.shadowPath = [UIBezierPath bezierPathWithRect:bgLogin.bounds].CGPath;
    bgSecurtyQuestion.layer.cornerRadius = 5.0f;
    
    QuestionTableView.delegate = self;
    QuestionTableView.dataSource = self;
    arrQuestions = [[NSArray alloc] initWithObjects:@"In what city were you born",
                    @"What was your favorite place to visit as a child",
                    @"Who is your favorite actor, musician, or artist",
                    @"What is the name of your favorite pet",
                    @"What high school did you attend",
                    @"What is your favorite movie",
                    @"What is your mother's maiden name",
                    @"What street did you grow up on",
                    @"What is your favorite color",
                    @"What is the name of your first grade teacher",
                    @"Which is your favorite web browser",
                    @"When is your anniversary",
                    @"What was the make of your first car", nil];
    if (isLogin) {
        securityQuestionTitle.text = @"Answer your security question";
    }else{
        securityQuestionTitle.text  =@"Security Question";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateHideLoginView
{
    self.view.userInteractionEnabled = NO;
    [self.view endEditing:YES];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         bgSecurityViewCons.constant += 600.0f;
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         bgLogin.hidden = YES;
     }
     ];
}

- (void)animateShowLoginView
{
    bgLogin.hidden = NO;
    [UIView animateWithDuration:0.3
                          delay: 0.0
                        options: UIViewAnimationOptionTransitionNone
                     animations:^{
                         bgLoginViewCons.constant += 400.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished)
     {
         self.view.userInteractionEnabled = YES;
     }];
    
    [txtUsername becomeFirstResponder]; // Show keyboard
}
- (void)animateHideSecuView
{
    self.view.userInteractionEnabled = NO;
    [self.view endEditing:YES];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         bgSecurityViewCons.constant += 600.0f;
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
         
         bgSecurtyQuestion.hidden = YES;
     }
     ];
}

- (void)animateShowSecuView
{
    bgSecurtyQuestion.hidden = NO;
    [UIView animateWithDuration:0.3
                          delay: 0.0
                        options: UIViewAnimationOptionTransitionNone
                     animations:^{
                         bgSecurityViewCons.constant += 400.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished)
     {
         self.view.userInteractionEnabled = YES;
     }];
    
    [txtSecurityQuestion becomeFirstResponder]; // Show keyboard
}
- (IBAction)onLogin:(id)sender {
    if (!txtUsername.text.length)
    {
        [self showAlert:@"Please input UserName" :@"Input Error"];
        return;
    }
    if (!txtPassword.text.length)
    {
        [self showAlert:@"Please input Password" :@"Input Error"];
        return;
    }
    [self.view endEditing:YES];
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet to log in." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSLog(@"you pressed Yes, please button");
        }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
        
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Login…";
    
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            NSNumber *userID = [_responseObject objectForKey:@"user_id"];
            NSString *userLevel = [_responseObject objectForKey:@"user_level"];
            if (userID != nil && userLevel != nil) {
                // enable naviation bar
                if (self.navigationController != nil) {
                    self.navigationController.navigationBar.userInteractionEnabled = YES;
                }
                
                // check if there was an existing userID key
                NSString *userIDKey = @"userId";
                NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
                NSNumber *previousUserID = [NSNumber numberWithInteger: [currentUserId integerValue]];
                
                if (previousUserID != nil && ([userID intValue] != [previousUserID intValue])) {
                    [[AppDelegate sharedDelegate] deletePilotProfileFromLocal];
                    [AppDelegate sharedDelegate].isBackPreUser = NO;
                }
                
                [AppDelegate sharedDelegate].userId =[NSString stringWithFormat:@"%@", [_responseObject objectForKey:@"user_id"]];
                [AppDelegate sharedDelegate].userName = [_responseObject objectForKey:@"username"];
                [AppDelegate sharedDelegate].userPassword = [_responseObject objectForKey:@"password"];
                [AppDelegate sharedDelegate].userLevel = [_responseObject objectForKey:@"user_level"];
                [AppDelegate sharedDelegate].clientFirstName = [_responseObject objectForKey:@"firstName"];
                [AppDelegate sharedDelegate].clientMiddleName = [_responseObject objectForKey:@"middleName"];
                [AppDelegate sharedDelegate].clientLastName = [_responseObject objectForKey:@"lastName"];
                [AppDelegate sharedDelegate].userEmail = [_responseObject objectForKey:@"email"];
                [AppDelegate sharedDelegate].userPhoneNum = [_responseObject objectForKey:@"phoneNum"];
                [AppDelegate sharedDelegate].pilotCert = [_responseObject objectForKey:@"pilotCert"];
                [AppDelegate sharedDelegate].pilotCertIssueDate = [_responseObject objectForKey:@"pilotCertIssueDate"];
                [AppDelegate sharedDelegate].medicalCertIssueDate = [_responseObject objectForKey:@"medicalCertIssueDate"];
                [AppDelegate sharedDelegate].medicalCertExpDate = [_responseObject objectForKey:@"medicalCertExpDate"];
                [AppDelegate sharedDelegate].cfiCertExpDate = [_responseObject objectForKey:@"cfiCertExpDate"];
                [AppDelegate sharedDelegate].question = [_responseObject objectForKey:@"question"];
                [AppDelegate sharedDelegate].answer = [_responseObject objectForKey:@"answer"];
                [AppDelegate sharedDelegate].isVerify = 1;//[[_responseObject objectForKey:@"isVerify"] integerValue];
                [AppDelegate sharedDelegate].isLogin = YES;
                [[AppDelegate sharedDelegate] sendPushForLogInOut:1];
                [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                
                if (previousUserID != nil && ([userID intValue] != [previousUserID intValue])) {
                    FDLogInfo(@"new username %@, clear cached documents and lessons!", txtUsername.text);
                    [[AppDelegate sharedDelegate] clearLessons];
                    [[AppDelegate sharedDelegate] clearDocuments];
                    [AppDelegate sharedDelegate].isOpenFirstWithDash = NO;
                }
                
                // hide the login view
                // notify ouselves that we logged in successfully incase we need to do anything
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_LOGIN_SUCCESSFUL_SNYC object:nil userInfo:nil];
                
                self.view.userInteractionEnabled = NO;
                [self.view endEditing:YES];
                
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                                 animations:^(void)
                 {
                     bgLoginViewCons.constant += 620.0f;
                     [self.view layoutIfNeeded];
                 }
                                 completion:^(BOOL finished)
                 {
                     bgLogin.hidden = YES;                     
                     [self.delegate loginSuccessfuly:self];
                     [[AppDelegate sharedDelegate] gotoMainView];
                 }
                 ];
            }else{
                [self askForRegister];
            }
        }else{
            if ([_responseObject objectForKey:@"is_active"] && [[_responseObject objectForKey:@"is_active"] boolValue]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FlightDesk" message:[_responseObject objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }else if ([_responseObject objectForKey:@"password"] && [[_responseObject objectForKey:@"password"] boolValue]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FlightDesk" message:[_responseObject objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self askForRegister];
            }
        }
        
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [ MBProgressHUD hideHUDForView : self.view animated : YES ] ;
        [self askForRegister];
        
    } ;
    [[Communication sharedManager] ActionFlightDeskLogin:@"login" userName:txtUsername.text  password:txtPassword.text successed:successed failure:failure];
}

- (void)askForRegister{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Your user info doesn't exit in FlightDesk, do you want to setup your new pilot profile?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                                              animations:^(void)
                              {
                                  bgLoginViewCons.constant += 600.0f;
                                  [self.view layoutIfNeeded];
                              }
                                              completion:^(BOOL finished)
                              {
                                  bgLogin.hidden = YES;
                                  [self.delegate gotoRegisterView:self];
                              }
                              ];
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
                             {
                                 [txtUsername becomeFirstResponder];
                             }];
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)onForgotPassword:(id)sender {
    if (!txtUsername.text.length)
    {
        [self showAlert:@"Please input username" :@"Input Error"];
        return;
    }
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet to register." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSLog(@"you pressed Yes, please button");
        }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
        
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            bgSecurityViewCons.constant += 400.0f;
            bgSecurtyQuestion.hidden = NO;
            bgSecurtyQuestion.alpha = 0.0f;
            
            txtSecurityQuestion.text = [_responseObject objectForKey:@"question"];
            txtSecurityQuestion.enabled = NO;
            QuestionTableView.hidden = YES;
            [UIView animateWithDuration:0.3
                                  delay: 0.0
                                options: UIViewAnimationOptionTransitionNone
                             animations:^{
                                     securityQuestionTitle.text = @"Answer your security question";
                                 bgSecurtyQuestion.alpha = 1.0f;
                                 bgLogin.alpha = 0.0f;
                             }
                             completion:^(BOOL finished)
             {
                 bgLogin.hidden = YES;
                 [txtAnswer becomeFirstResponder];
                 self.view.userInteractionEnabled = YES;
             }];
        }else{
            [self showAlert:@"Username doesn't exist, Try again" :@"Failed!"];
        }
        
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [ MBProgressHUD hideHUDForView : self.view animated : YES ] ;
        [self showAlert:@"Username doesn't exist, Try again" :@"Failed!"];
        
    } ;
    [[Communication sharedManager] ActionFlightDeskCheckUsername:@"checkusername" username:txtUsername.text successed:successed failure:failure];
    
}

- (IBAction)onPwdShowHide:(id)sender {
    btnPwdShowHide.selected = !btnPwdShowHide.selected;
    if (btnPwdShowHide.selected) {
        txtPassword.secureTextEntry = NO;
    }else{
        txtPassword.secureTextEntry = YES;
    }
}

- (IBAction)onRelease:(UIButton *)sender {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
//        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet to log in." preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//            NSLog(@"you pressed Yes, please button");
//        }];
//        [alert addAction:yesButton];
//        [self presentViewController:alert animated:YES completion:nil];
        
        return;
        
    }
    
    
    
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            return;
        }else{
            return;
        }
        
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        return;
        
    } ;
    [[Communication sharedManager] ActionFlightDeskRelease:@"release" userName:txtUsername.text  password:txtPassword.text successed:successed failure:failure];
}

- (IBAction)onSecurityQuestionDone:(id)sender {
    if (isLogin) {
        if (!txtAnswer.text.length)
        {
            [self showAlert:@"Please answer your security question" :@"Input Error"];
            return;
        }
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        [reachability startNotifier];
        NetworkStatus status = [reachability currentReachabilityStatus];
        if (status == NotReachable) {
            // you must be connected to the internet to download documents
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSLog(@"you pressed Yes, please button");
            }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
            
            return;
            
        }
        [self.view endEditing:YES];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        void ( ^successed )( id _responseObject ) = ^( id _responseObject )
        {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            if ([[_responseObject objectForKey:@"success"] boolValue]) {
                NSNumber *userID = [_responseObject objectForKey:@"user_id"];
                NSString *userLevel = [_responseObject objectForKey:@"user_level"];
                if (userID != nil && userLevel != nil) {
                    // enable naviation bar
                    if (self.navigationController != nil) {
                        self.navigationController.navigationBar.userInteractionEnabled = YES;
                    }
                    // check if there was an existing userID key
                    NSString *userIDKey = @"userId";
                    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
                    NSNumber *previousUserID = [NSNumber numberWithInteger: [currentUserId integerValue]];
                    if (previousUserID != nil && ([userID intValue] != [previousUserID intValue])) {
                        FDLogInfo(@"new username %@, clear cached documents and lessons!", txtUsername.text);
                        [[AppDelegate sharedDelegate] clearDocuments];
                        [[AppDelegate sharedDelegate] clearLessons];
                        [[AppDelegate sharedDelegate] deletePilotProfileFromLocal];
                        [AppDelegate sharedDelegate].isBackPreUser = NO;
                        [AppDelegate sharedDelegate].isOpenFirstWithDash = NO;
                    }
                    
                    [AppDelegate sharedDelegate].userId =[NSString stringWithFormat:@"%@", [_responseObject objectForKey:@"user_id"]];
                    [AppDelegate sharedDelegate].userName = [_responseObject objectForKey:@"username"];
                    [AppDelegate sharedDelegate].userPassword = [_responseObject objectForKey:@"password"];
                    [AppDelegate sharedDelegate].userLevel = [_responseObject objectForKey:@"user_level"];
                    [AppDelegate sharedDelegate].clientFirstName = [_responseObject objectForKey:@"firstName"];
                    [AppDelegate sharedDelegate].clientMiddleName = [_responseObject objectForKey:@"middleName"];
                    [AppDelegate sharedDelegate].clientLastName = [_responseObject objectForKey:@"lastName"];
                    [AppDelegate sharedDelegate].userEmail = [_responseObject objectForKey:@"email"];
                    [AppDelegate sharedDelegate].userPhoneNum = [_responseObject objectForKey:@"phoneNum"];
                    [AppDelegate sharedDelegate].pilotCert = [_responseObject objectForKey:@"pilotCert"];
                    [AppDelegate sharedDelegate].pilotCertIssueDate = [_responseObject objectForKey:@"pilotCertIssueDate"];
                    [AppDelegate sharedDelegate].medicalCertIssueDate = [_responseObject objectForKey:@"medicalCertIssueDate"];
                    [AppDelegate sharedDelegate].medicalCertExpDate = [_responseObject objectForKey:@"medicalCertExpDate"];
                    [AppDelegate sharedDelegate].cfiCertExpDate = [_responseObject objectForKey:@"cfiCertExpDate"];
                    [AppDelegate sharedDelegate].question = [_responseObject objectForKey:@"question"];
                    [AppDelegate sharedDelegate].answer = [_responseObject objectForKey:@"answer"];
                    [AppDelegate sharedDelegate].isVerify = 1;//[[_responseObject objectForKey:@"isVerify"] integerValue];
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    // hide the login view
                    // notify ouselves that we logged in successfully incase we need to do anything
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_LOGIN_SUCCESSFUL_SNYC object:nil userInfo:nil];
                    [AppDelegate sharedDelegate].isLogin = YES;
                    self.view.userInteractionEnabled = NO;
                    [self.view endEditing:YES];
                    
                    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                                     animations:^(void)
                     {
                         bgLoginViewCons.constant += 600.0f;
                         [self.view layoutIfNeeded];
                     }
                                     completion:^(BOOL finished)
                     {
                         bgLogin.hidden = YES;
                         [self.delegate loginSuccessfuly:self];
                         [[AppDelegate sharedDelegate] gotoMainView];
                     }
                     ];
                }else{
                    [self showAlert:@"Incorrect answer" :@"Failed!"];
                }
            }else{
                [self showAlert:@"Incorrect answer" :@"Failed!"];
            }
            
        };
        
        void ( ^failure )( NSError* _error ) = ^( NSError* _error )
        {
            [ MBProgressHUD hideHUDForView : self.view animated : YES ] ;
            [self showAlert:@"Incorrect answer" :@"Failed!"];
            
        } ;
        [[Communication sharedManager] ActionFlightDeskSecurityQuestion:@"securityAnswer" username:txtUsername.text question:txtSecurityQuestion.text  answer:txtAnswer.text successed:successed failure:failure];
    }else{
        self.view.userInteractionEnabled = NO;
        [self.view endEditing:YES];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             bgSecurityViewCons.constant += 600.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             
             bgSecurtyQuestion.hidden = YES;
             [self.delegate securityViewDone:self question:txtSecurityQuestion.text answer:txtAnswer.text];
         }
         ];
    }
}
- (IBAction)onSecurityQShowHide:(id)sender {
    btnSecurityQShowHide.selected = !btnSecurityQShowHide.selected;
    if (btnSecurityQShowHide.selected) {
        txtAnswer.secureTextEntry = NO;
    }else{
        txtAnswer.secureTextEntry = YES;
    }
}

- (IBAction)onSecurityQuestionCancel:(id)sender {
    if (isLogin) {
        bgLogin.hidden = NO;
        [UIView animateWithDuration:0.5
                              delay: 0.0
                            options: UIViewAnimationOptionTransitionNone
                         animations:^{
                             bgLogin.alpha = 1.0f;
                             bgSecurtyQuestion.alpha = 0.0f;
                         }
                         completion:^(BOOL finished)
         {
             txtSecurityQuestion.text = @"";
             txtSecurityQuestion.enabled = YES;
             bgSecurityViewCons.constant += 400.0f;
             bgSecurtyQuestion.hidden = NO;
             QuestionTableView.hidden = NO;
         }];
    }else{
        self.view.userInteractionEnabled = NO;
        [self.view endEditing:YES];
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             bgSecurityViewCons.constant += 600.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             
             bgSecurtyQuestion.hidden = YES;
             [self.delegate securityViewCancel:self];
         }
         ];
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtUsername) {
        [txtPassword becomeFirstResponder];
    }else if (textField == txtPassword){
        [self onLogin:nil];
    }else if (textField == txtSecurityQuestion){
        [QuestionTableView setHidden:YES];
        [txtAnswer becomeFirstResponder];
    }else if (textField == txtAnswer){
        [self onSecurityQuestionDone:nil];
    }
    return  YES;
}
#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [arrQuestions count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30.0f;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == QuestionTableView){
        static NSString *sortTableViewIdentifier = @"QuestionItem";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sortTableViewIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:sortTableViewIdentifier];
        }
        cell.textLabel.text =[arrQuestions objectAtIndex:indexPath.row];
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == QuestionTableView){
        QuestionTableView.hidden = YES;
        txtSecurityQuestion.text = [arrQuestions objectAtIndex:indexPath.row];
        [txtAnswer becomeFirstResponder];
    }
}
@end
