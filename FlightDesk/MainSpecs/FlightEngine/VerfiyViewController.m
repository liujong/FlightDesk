//
//  VerfiyViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "VerfiyViewController.h"

@interface VerfiyViewController ()<UITextFieldDelegate>{
    NSTimer *countDownTimer;
    int currMinute;
    int currSeconds;
}

@end

@implementation VerfiyViewController
@synthesize verifiyType;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    verificationDialog.autoresizesSubviews = NO;
    verificationDialog.contentMode = UIViewContentModeRedraw;
    verificationDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    verificationDialog.layer.shadowRadius = 3.0f;
    verificationDialog.layer.shadowOpacity = 1.0f;
    verificationDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    verificationDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:verificationDialog.bounds].CGPath;
    verificationDialog.layer.cornerRadius = 5.0f;
    
    emailUpdateView.hidden = YES;
    emailUpdateDialog.autoresizesSubviews = NO;
    emailUpdateDialog.contentMode = UIViewContentModeRedraw;
    emailUpdateDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    emailUpdateDialog.layer.shadowRadius = 3.0f;
    emailUpdateDialog.layer.shadowOpacity = 1.0f;
    emailUpdateDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    emailUpdateDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:emailUpdateDialog.bounds].CGPath;
    emailUpdateDialog.layer.cornerRadius = 5.0f;
    
    lblEmailVerifyDes.text = [NSString stringWithFormat:@"An email with a verification code has been sent to %@. Enter the code here:", [AppDelegate sharedDelegate].userEmail];
    
    lblTimer.hidden = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateHide{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dialogBottomCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}
- (void)animateShow{
    
    if (verifiyType == 1) {
       [self resendVerification];
        
    }else if (verifiyType == 2){
        
    }else {
        
        lblTimer.hidden = NO;
        btnResendVerifyCode.enabled = NO;
        currMinute = 1;
        currSeconds = 0;
        countDownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
        [code1 becomeFirstResponder];
    }
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             dialogBottomCons.constant += 350.0f;
             [self.view layoutIfNeeded];
             
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
         }
         ];
    }
}
#pragma mark UITextFieldDelegate
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == code1) {
        
    }else if (textField == code2){
        
    }else if (textField == code3){
        
    }else if (textField == code4){
        
    }else if (textField == code5){
        
    }else if (textField == code6){
        
    }
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (text.length > 1)
        return NO;
    if (textField == code1) {
        code1.text = text;
        if (code2.text.length == 1) {
            [code2 selectAll:self];
        }
        
        [code2 becomeFirstResponder];
    }else if (textField == code2){
        code2.text = text;
        if (code3.text.length == 1) {
            [code3 selectAll:self];
        }
        [code3 becomeFirstResponder];
    }else if (textField == code3){
        code3.text = text;
        if (code4.text.length == 1) {
            [code4 selectAll:self];
        }
        [code4 becomeFirstResponder];
    }else if (textField == code4){
        code4.text = text;
        if (code5.text.length == 1) {
            [code5 selectAll:self];
        }
        [code5 becomeFirstResponder];
    }else if (textField == code5){
        code5.text = text;
        if (code6.text.length == 1) {
            [code6 selectAll:self];
        }
        [code6 becomeFirstResponder];
    }else if (textField == code6){
        code6.text = text;
    }
    return NO;
}
- (IBAction)resendVerificationCode:(id)sender {
    [self.view endEditing:YES];
    [self resendVerification];
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
- (IBAction)onVerify:(id)sender {
    if (!code1.text.length || !code2.text.length || !code3.text.length || !code4.text.length || !code5.text.length || !code6.text.length )
    {
        [self showAlert:@"Please input verification code" :@"Input Error"];
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Verifying…";
    
    NSString *verify = [NSString stringWithFormat:@"%@%@%@%@%@%@", code1.text, code2.text, code3.text, code4.text, code5.text
                        , code6.text];
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"verify_email", @"action", [AppDelegate sharedDelegate].userId, @"user_id", verify, @"verify_code", nil];
    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        // handle the documents update
        if (data != nil) {
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [AppDelegate sharedDelegate].isLogin = YES;
                    [AppDelegate sharedDelegate].isVerify = 1;
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    [AppDelegate sharedDelegate].isBackPreUser = NO;
                    [AppDelegate sharedDelegate].isRegister = YES;
                    
                    
                    [countDownTimer invalidate];
                    countDownTimer = nil;
                    
                    if (self.view.hidden == NO) // Visible
                    {
                        self.view.userInteractionEnabled = NO;
                        
                        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                                         animations:^(void)
                         {
                             self.view.alpha = 0.0f; // Fade out
                             dialogBottomCons.constant += -520.0f;
                             [self.view layoutIfNeeded];
                         }
                                         completion:^(BOOL finished)
                         {
                             self.view.hidden = YES;
                             [self.delegate returnVerifyView:self];
                             
                             [[AppDelegate sharedDelegate] gotoMainView];
                         }
                         ];
                    }
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Incorrect verification code, Please try again" :@"Failed!"] ;
                });
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
    
}

- (IBAction)onCancel:(id)sender {
    
    [countDownTimer invalidate];
    countDownTimer = nil;
    
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dialogBottomCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate cancelVerifyView:self];
         }
         ];
    }
}

- (IBAction)onShowChangeEmailView:(id)sender {
    emailUpdateView.hidden = NO;
    txtChangeEmail.text = [AppDelegate sharedDelegate].userEmail;
    // instantaneously make the image view small (scaled to 1% of its actual size)
    emailUpdateDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        emailUpdateDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
        [txtChangeEmail becomeFirstResponder];
    }];
}

- (IBAction)onUpdateEmail:(id)sender {
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"update_useremail", @"action", [AppDelegate sharedDelegate].userId, @"user_id", txtChangeEmail.text, @"user_email", nil];
    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [countDownTimer invalidate];
                    countDownTimer = nil;
                    emailUpdateView.hidden = YES;
                    lblTimer.hidden = NO;
                    btnResendVerifyCode.enabled = NO;
                    currMinute = 1;
                    currSeconds = 0;
                    countDownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
                    
                    [AppDelegate sharedDelegate].userEmail = txtChangeEmail.text;
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    lblEmailVerifyDes.text = [NSString stringWithFormat:@"An email with a verification code has been sent to %@. Enter the code here:", [AppDelegate sharedDelegate].userEmail];
                    [code1 becomeFirstResponder];
                    
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Please try again" :@"Failed!"] ;
                });
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
}

- (IBAction)onCancelUpdateEmail:(id)sender {
    emailUpdateView.hidden = YES;
}

- (void)resendVerification{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"resend_verification_code", @"action", [AppDelegate sharedDelegate].userId, @"user_id", [AppDelegate sharedDelegate].userEmail, @"user_email", nil];
    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    lblTimer.hidden = NO;
                    btnResendVerifyCode.enabled = NO;
                    currMinute = 1;
                    currSeconds = 0;
                    countDownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
                    
                    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"We sent verification code to your email." preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                        NSLog(@"you pressed Yes, please button");
                        [code1 becomeFirstResponder];
                    }];
                    [alert addAction:yesButton];
                    [self presentViewController:alert animated:YES completion:nil];
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Please try again" :@"Failed!"] ;
                });
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
}

-(void)timerFired
{
    if (currMinute == 0 && currSeconds == 0) {
        btnResendVerifyCode.enabled = YES;
        lblTimer.hidden = YES;
        [countDownTimer invalidate];
    }else{
        if (currSeconds == 0 && currMinute != 0) {
            currMinute -= 1;
            currSeconds = 60;
        }
        if (currSeconds > 0){
            currSeconds -= 1;
        }
        if(currSeconds>-1){
            NSString *m, *s = @"";
            if (currSeconds < 10) {
                s = [NSString stringWithFormat:@"0%d", currSeconds];
            }else{
                s = [NSString stringWithFormat:@"%d", currSeconds];
            }
            if (currMinute < 10) {
                m = [NSString stringWithFormat:@"0%d", currMinute];
            }else{
                m = [NSString stringWithFormat:@"%d", currMinute];
            }
            
            [lblTimer setText:[NSString stringWithFormat:@"%@ : %@", m, s]];
        }
    }
}
@end
