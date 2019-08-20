//
//  RegisterViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/31/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "RegisterViewController.h"
#import "LoginViewController.h"
#import "DateViewController.h"

@interface RegisterViewController ()<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, LoginViewControllerDelegate, DateViewControllerDelegate>
{
    NSInteger visibleCenterY;
    NSInteger hiddenCenterY;
    
    NSArray *arrRole;
    
    BOOL isPromptPicker;
}

@end

@implementation RegisterViewController
#pragma mark Constants

#define TOOLBAR_HEIGHT 44.0f

#define DIALOG_WIDTH_LARGE 569.0f
#define DIALOG_WIDTH_SMALL 569.0f
#define DIALOG_HEIGHT 712.0f

#define TEXT_LENGTH_LIMIT 128

#define DEFAULT_DURATION 0.3
#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define REQUIREDCOLOR RGBA(255, 80, 80, 1)

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    
    visibleCenterY = (large ? (DIALOG_HEIGHT * 1.1f) : (DIALOG_HEIGHT - (TOOLBAR_HEIGHT / 2.0f)));
    
    CGFloat dialogWidth = (large ? DIALOG_WIDTH_LARGE : DIALOG_WIDTH_SMALL); // Dialog width
    
    CGFloat dialogY = (0.0f - DIALOG_HEIGHT); // Start off screen
    CGFloat dialogX = ((self.view.bounds.size.width - dialogWidth) / 2.0f);
    CGRect dialogRect = CGRectMake(dialogX, dialogY, dialogWidth, DIALOG_HEIGHT);
    [registerDialogView setFrame:dialogRect];
    hiddenCenterY = registerDialogView.center.y;
    
    registerDialogView.autoresizesSubviews = NO;
    registerDialogView.contentMode = UIViewContentModeRedraw;
    registerDialogView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    registerDialogView.layer.shadowRadius = 3.0f;
    registerDialogView.layer.shadowOpacity = 1.0f;
    registerDialogView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    registerDialogView.layer.shadowPath = [UIBezierPath bezierPathWithRect:registerDialogView.bounds].CGPath;
    registerDialogView.layer.cornerRadius = 5.0f;
    
    
    RoleTableView.hidden = YES;
    arrRole = [[NSArray alloc] initWithObjects:@"Instructor",@"Student", nil];
    RoleTableView.dataSource = self;
    RoleTableView.delegate = self;
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:@"Required" attributes:@{ NSForegroundColorAttributeName : REQUIREDCOLOR}];
    txtFname.attributedPlaceholder = attrText;
    txtLname.attributedPlaceholder = attrText;
    txtEmail.attributedPlaceholder = attrText;
    txtPhone.attributedPlaceholder = attrText;
    txtPilotCertificate.attributedPlaceholder = attrText;
    txtPilotCertIssDate.attributedPlaceholder = attrText;
    txtMedicalCertIssueDate.attributedPlaceholder = attrText;
    txtMedicalCertExpDate.attributedPlaceholder = attrText;
    txtCFICertExpDate.attributedPlaceholder = attrText;
    txtUsername.attributedPlaceholder = attrText;
    txtAnswer.attributedPlaceholder = attrText;
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    gesture.delegate=self;
    [self.view addGestureRecognizer:gesture];
    
    isPromptPicker = NO;
    
    [scrView setContentSize:CGSizeMake(scrView.frame.size.width, 800)];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)deviceOrientationDidChange{
    if (self.view.frame.size.height > self.view.frame.size.width) {
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.height + 200.0f)];
    }else{
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.width + 300.0f)];
    }
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (self.view.frame.size.height > self.view.frame.size.width) {
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.height + 200.0f)];
    }else{
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.width + 300.0f)];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    [self.view endEditing:YES];
//    [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
//                     animations:^(void)
//     {
//         [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 120, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
//     }
//                     completion:^(BOOL finished){}];
    if (self.view.frame.size.height > self.view.frame.size.width) {
        [scrView setContentSize:CGSizeMake(0, 0)];
    }else{
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.width + 300.0f)];
    }
}
-(void)handleTap
{
    [self.view endEditing:YES];
}
- (void)animateHide
{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        [self.view endEditing:YES];
        
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, -DIALOG_HEIGHT, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}

- (void)animateShow
{
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 120, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
         }
         ];
        
        [txtFname becomeFirstResponder]; // Show keyboard
    }
}

- (IBAction)onLoginFromPilot:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        [self.view endEditing:YES];
        
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, -DIALOG_HEIGHT, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             
             [_delegate loginButtonTappedInRegisterView];
         }
         ];
    }
}

- (IBAction)onRegisterFromPilot:(id)sender {
    if (!txtFname.text.length)
    {
        [self showAlert:@"Please input First Name" :@"Input Error"];
        return;
    }
    if (!txtLname.text.length)
    {
        [self showAlert:@"Please input Last Name" :@"Input Error"];
        return;
    }
    
    if (!txtEmail.text.length)
    {
        [self showAlert:@"Please input your Email address" :@"Input Error"];
        return;
    }
    if (!txtPhone.text.length)
    {
        [self showAlert:@"Please input your Phone number" :@"Input Error"];
        return;
    }
    if (!txtPilotCertificate.text.length)
    {
        [self showAlert:@"Please input Pilot Certificate" :@"Input Error"];
        return;
    }
    if (!txtPilotCertIssDate.text.length)
    {
        [self showAlert:@"Please setup your Pilot Certificate Issue Date" :@"Input Error"];
        return;
    }
    if (!txtMedicalCertIssueDate.text.length)
    {
        [self showAlert:@"Please setup your Medical Certificate Issue Date" :@"Input Error"];
        return;
    }
    if (!txtMedicalCertExpDate.text.length)
    {
        [self showAlert:@"Please setup your Medical Certificate Expiration Date" :@"Input Error"];
        return;
    }
    if (!txtUsername.text.length)
    {
        [self showAlert:@"Please input Username" :@"Input Error"];
        return;
    }
    if (!txtPassword.text.length)
    {
        [self showAlert:@"Please input Password" :@"Input Error"];
        return;
    }
    if (!txtAnswer.text.length)
    {
        [self showAlert:@"Please input your security answer" :@"Input Error"];
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
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Register…";
    
    NSError *error;
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"register_update_userinfo", @"action", txtFname.text, @"firstName", txtMname.text, @"middleName",txtLname.text, @"lastName",txtEmail.text, @"email",txtPhone.text, @"phone",btnSelectRole.titleLabel.text, @"role",txtUsername.text, @"username",txtPassword.text, @"password",[dateFormatter stringFromDate:[NSDate date]], @"created",txtPilotCertificate.text, @"pilotCert",txtPilotCertIssDate.text, @"pilotCertIssueDate",txtMedicalCertIssueDate.text, @"medicalCertIssueDate", txtMedicalCertExpDate.text, @"medicalCertExpDate",txtCFICertExpDate.text, @"cfiCertExpDate",lblQuestion.text, @"question",txtAnswer.text, @"answer",[AppDelegate sharedDelegate].device_token, @"device_token", nil];
    
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
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
                    FDLogInfo(@"new username %@, clear cached documents and lessons!", txtUsername.text);
                    [[AppDelegate sharedDelegate] clearDocuments];
                    [[AppDelegate sharedDelegate] clearLessons];
                    [[AppDelegate sharedDelegate] deletePilotProfileFromLocal];
                    [AppDelegate sharedDelegate].isBackPreUser = NO;
                    [AppDelegate sharedDelegate].isOpenFirstWithDash = NO;
                    
                    [AppDelegate sharedDelegate].isLogin = NO;
                    [AppDelegate sharedDelegate].clientFirstName = txtFname.text ;
                    [AppDelegate sharedDelegate].clientMiddleName =  txtMname.text;
                    [AppDelegate sharedDelegate].clientLastName = txtLname.text;
                    [AppDelegate sharedDelegate].userName = txtUsername.text;
                    [AppDelegate sharedDelegate].userEmail = txtEmail.text;
                    [AppDelegate sharedDelegate].userPhoneNum = txtPhone.text;
                    [AppDelegate sharedDelegate].userLevel = btnSelectRole.titleLabel.text;
                    [AppDelegate sharedDelegate].userPassword = txtPassword.text;
                    [AppDelegate sharedDelegate].userId = [NSString stringWithFormat:@"%@", [queryResults objectForKey:@"userid"]];
                    
                    [AppDelegate sharedDelegate].pilotCert = txtPilotCertificate.text;
                    [AppDelegate sharedDelegate].pilotCertIssueDate = txtPilotCertIssDate.text;
                    [AppDelegate sharedDelegate].medicalCertIssueDate = txtMedicalCertIssueDate.text;
                    [AppDelegate sharedDelegate].medicalCertExpDate = txtMedicalCertExpDate.text;
                    [AppDelegate sharedDelegate].cfiCertExpDate = txtCFICertExpDate.text;
                    [AppDelegate sharedDelegate].question = lblQuestion.text;
                    [AppDelegate sharedDelegate].answer = txtAnswer.text;
                    [AppDelegate sharedDelegate].isVerify = 0;
                    
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    
                    if (self.view.hidden == NO) // Visible
                    {
                        self.view.userInteractionEnabled = NO;
                        [self.view endEditing:YES];
                        
                        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                                         animations:^(void)
                         {
                             self.view.alpha = 0.0f; // Fade out
                             
                             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, -DIALOG_HEIGHT, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
                         }
                                         completion:^(BOOL finished)
                         {
                             self.view.hidden = YES;
                             
                             [_delegate registerButtonTappedInRegisterView:self];
                         }
                         ];
                    }
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: [queryResults objectForKey:@"message"] :@"Failed!"] ;
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
-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)onShowHidePassword:(id)sender {
    btnShowHide.selected = !btnShowHide.selected;
    if (btnShowHide.selected) {
        txtPassword.secureTextEntry = NO;
    }else{
        txtPassword.secureTextEntry = YES;
    }
}

- (IBAction)onShowHideRecovery:(id)sender {
    btnShowHideRecovery.selected = !btnShowHideRecovery.selected;
    if (btnShowHideRecovery.selected) {
        txtAnswer.secureTextEntry = NO;
    }else{
        txtAnswer.secureTextEntry = YES;
    }
}

- (IBAction)onSelectRole:(id)sender {
    RoleTableView.hidden = NO;
}

- (IBAction)onSelectQuestion:(id)sender {
    if (isPromptPicker) {
        return;
    }
    isPromptPicker = YES;
    LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [loginView.view setFrame:self.view.bounds];
    loginView.delegate = self;
    loginView.isLogin = NO;
    [self displayContentController:loginView];
    [loginView animateShowSecuView];
}

- (IBAction)onGetPilotCertIssueDate:(id)sender {
    if (isPromptPicker) {
        return;
    }
    isPromptPicker = YES;
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 1;
    dateView.pickerTitle = @"Pilot Certificate Issue Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}

- (IBAction)onMedicalCertIssueDate:(id)sender {
    if (isPromptPicker) {
        return;
    }
    isPromptPicker = YES;
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 4;
    dateView.pickerTitle = @"Medical Certificate issue Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}

- (IBAction)onMedicalCertExpDate:(id)sender {
    if (isPromptPicker) {
        return;
    }
    isPromptPicker = YES;
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 5;
    dateView.pickerTitle = @"Medical Certificate expiration Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}

- (IBAction)onCFICertExpDate:(id)sender {
    if (isPromptPicker) {
        return;
    }
    isPromptPicker = YES;
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 3;
    dateView.pickerTitle = @"CFI Certificate Expiration Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}
- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}

#pragma mark DateViewControllerDelegate
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    switch (_type) {
        case 1:
            txtPilotCertIssDate.text = _strDate;
            break;
        case 5:
            txtMedicalCertExpDate.text = _strDate;
            break;
        case 3:
            txtCFICertExpDate.text = _strDate;
            break;
        case 4:
            txtMedicalCertIssueDate.text = _strDate;
            break;
            
        default:
            break;
    }
    [self removeCurrentViewFromSuper:dateView];
}
- (void)didCancelDateView:(DateViewController *)dateView{
     [self removeCurrentViewFromSuper:dateView];
}
#pragma mark LoginViewControllerDelegate
- (void)securityViewCancel:(LoginViewController *)loginView{
     [self removeCurrentViewFromSuper:loginView];
}
- (void)securityViewDone:(LoginViewController *)loginView question:(NSString *)_question answer:(NSString *)_answer{
    [self removeCurrentViewFromSuper:loginView];
    lblQuestion.text = _question;
    txtAnswer.text = _answer;
}

- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    isPromptPicker = NO;
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}


#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [arrRole count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30.0f;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *sortTableViewIdentifier = @"RoleItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sortTableViewIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:sortTableViewIdentifier];
    }
    cell.textLabel.text =[arrRole objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
        RoleTableView.hidden = YES;
        [btnSelectRole setTitle:[arrRole objectAtIndex:indexPath.row] forState:UIControlStateNormal];
        if ([[arrRole objectAtIndex:indexPath.row] isEqualToString:@"Student"]) {
           lblCFI.hidden = YES;
           lblCFITip.hidden = YES;
           txtCFICertExpDate.hidden = YES;
            btnCFICertExpDate.hidden = YES;
        }else{
            lblCFI.hidden = NO;
            lblCFITip.hidden = NO;
            txtCFICertExpDate.hidden = NO;
            btnCFICertExpDate.hidden = NO;
        }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == txtUsername) {
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 80, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
        completion:^(BOOL finished){}];
    }else if (textField == txtPassword) {
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 40, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished){}];
    }else{
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 120, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished){}];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtFname) {
        [txtMname becomeFirstResponder];
    }else if (textField == txtMname){
        [txtLname becomeFirstResponder];
    }else if (textField == txtLname){
        [txtEmail becomeFirstResponder];
    }else if (textField == txtEmail){
        [txtPhone becomeFirstResponder];
    }else if (textField == txtPhone){
        [txtPilotCertificate becomeFirstResponder];
    }else if (textField == txtPilotCertificate) {
        [txtUsername becomeFirstResponder];
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 80, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished){}];
    }else if (textField == txtUsername) {
        [txtPassword becomeFirstResponder];
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 40, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished){}];
    }else if (textField == txtPassword) {
        [self.view endEditing:YES];
        [UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             [registerDialogView setFrame:CGRectMake(registerDialogView.frame.origin.x, 120, DIALOG_WIDTH_LARGE, DIALOG_HEIGHT)];
         }
                         completion:^(BOOL finished){}];
    }
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view isKindOfClass:[UIScrollView class]]) {
        return YES;
    }
    if([touch.view isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    // UITableViewCellContentView => UITableViewCell
    if([touch.view.superview isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    // UITableViewCellContentView => UITableViewCellScrollView => UITableViewCell
    if([touch.view.superview.superview isKindOfClass:[UITableViewCell class]]) {
        return NO;
    }
    return YES;
}
@end
