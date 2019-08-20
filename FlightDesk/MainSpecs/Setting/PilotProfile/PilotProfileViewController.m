//
//  PilotProfileViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "PilotProfileViewController.h"
#import "LoginViewController.h"
#import "DateViewController.h"

@interface PilotProfileViewController ()<UITableViewDelegate, UITableViewDataSource, LoginViewControllerDelegate, DateViewControllerDelegate, UITextFieldDelegate>
{
    NSString *strUserRole;
    NSArray *arrRole;
    
    BOOL isPromptPicker;
}

@end

@implementation PilotProfileViewController
#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define REQUIREDCOLOR RGBA(255, 80, 80, 1)
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    strUserRole = @"instructor";
    RoleTableView.hidden = YES;
    arrRole = [[NSArray alloc] initWithObjects:@"Instructor",@"Student", nil];
    RoleTableView.dataSource = self;
    RoleTableView.delegate = self;
    
    
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 960.0f;
    [scrView setContentSize:scrSize];
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:@"Required" attributes:@{ NSForegroundColorAttributeName : REQUIREDCOLOR}];
    txtFirstName.attributedPlaceholder = attrText;
    txtLastName.attributedPlaceholder = attrText;
    txtEmail.attributedPlaceholder = attrText;
    txtPhonenumber.attributedPlaceholder = attrText;
    txtPilotCertification.attributedPlaceholder = attrText;
    txtPilotCerIssueDate.attributedPlaceholder = attrText;
    txtMedicalCertiIssueDate.attributedPlaceholder = attrText;
    txtMedicalCertiExpireDate.attributedPlaceholder = attrText;
    txtCFIDate.attributedPlaceholder = attrText;
    txtUserName.attributedPlaceholder = attrText;
    txtAnswer.attributedPlaceholder = attrText;
    isPromptPicker = NO;
    
    cfiExpirationBadge.layer.masksToBounds = YES;
    cfiExpirationBadge.layer.cornerRadius = 8.0f;
    medicalExpirationBadge.layer.masksToBounds = YES;
    medicalExpirationBadge.layer.cornerRadius = 8.0f;
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"PilotProfileViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [self loadPilotProfile];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self savePilotProfile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [scrView setContentSize:CGSizeMake(scrView.frame.size.width, 960.0f)];
}
- (void)loadPilotProfile{
    txtFirstName.text = [AppDelegate sharedDelegate].clientFirstName;
    txtMiddleName.text = [AppDelegate sharedDelegate].clientMiddleName;
    txtLastName.text = [AppDelegate sharedDelegate].clientLastName;
    txtUserName.text = [AppDelegate sharedDelegate].userName;
    txtEmail.text = [AppDelegate sharedDelegate].userEmail;
    txtPhonenumber.text = [AppDelegate sharedDelegate].userPhoneNum;
    strUserRole = [AppDelegate sharedDelegate].userLevel;
    if ([strUserRole isEqualToString:@"Student"]) {
        lblCFICertiExpirationDate.hidden = YES;
        tipLblCFICertiExpiraDate.hidden = YES;
        txtCFIDate.hidden = YES;
        btnCfiCertExpDate.hidden = YES;
        cfiExpirationBadge.hidden = YES;
    }
    [btnRole setTitle:strUserRole forState:UIControlStateNormal];
    txtPassword.text = [AppDelegate sharedDelegate].userPassword;
    txtPilotCertification.text = [AppDelegate sharedDelegate].pilotCert;
    txtPilotCerIssueDate.text = [AppDelegate sharedDelegate].pilotCertIssueDate;
    txtMedicalCertiIssueDate.text = [AppDelegate sharedDelegate].medicalCertIssueDate;
    txtMedicalCertiExpireDate.text = [AppDelegate sharedDelegate].medicalCertExpDate;
    txtCFIDate.text = [AppDelegate sharedDelegate].cfiCertExpDate;
    lblQuestion.text = [AppDelegate sharedDelegate].question;
    txtAnswer.text = [AppDelegate sharedDelegate].answer;
    
    
    [self calculateBadgeExpirationDate];
}
- (void)calculateBadgeExpirationDate{
    //calculate badge
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    NSDate *date1 = [dateFormat dateFromString:txtMedicalCertiExpireDate.text];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:[NSDate date]
                                                          toDate:date1
                                                         options:0];
    medicalExpirationBadge.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
    if((long)[components day] + 1 < 0){
        medicalExpirationBadge.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
        [medicalExpirationBadge setBackgroundColor:[UIColor redColor]];
        [txtMedicalCertiExpireDate setTextColor:[UIColor redColor]];
    }else if((long)[components day] + 1 >= 0 && (long)[components day] + 1 < 30){
        [medicalExpirationBadge setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
        [txtMedicalCertiExpireDate setTextColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
    }else if((long)[components day] + 1 >= 30){
        [medicalExpirationBadge setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
        [txtMedicalCertiExpireDate setTextColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f]];
    }
    
    date1 = [dateFormat dateFromString:txtCFIDate.text];
    
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    components = [gregorianCalendar components:NSCalendarUnitDay
                                      fromDate:[NSDate date]
                                        toDate:date1
                                       options:0];
    cfiExpirationBadge.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
    if((long)[components day] + 1 < 0){
        cfiExpirationBadge.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
        [cfiExpirationBadge setBackgroundColor:[UIColor redColor]];
        [txtCFIDate setTextColor:[UIColor redColor]];
    }else if((long)[components day] + 1 >= 0 && (long)[components day] + 1 < 90){
        [cfiExpirationBadge setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
        [txtCFIDate setTextColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
    }else if((long)[components day] + 1 >= 90){
        [cfiExpirationBadge setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
        [txtCFIDate setTextColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f]];
    }
}
- (void)savePilotProfile{
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            [AppDelegate sharedDelegate].clientFirstName = txtFirstName.text ;
            [AppDelegate sharedDelegate].clientMiddleName =  txtMiddleName.text;
            [AppDelegate sharedDelegate].clientLastName = txtLastName.text;
            [AppDelegate sharedDelegate].userName = txtUserName.text;
            [AppDelegate sharedDelegate].userEmail = txtEmail.text;
            [AppDelegate sharedDelegate].userPhoneNum = txtPhonenumber.text;
            [AppDelegate sharedDelegate].userLevel = strUserRole;
            [AppDelegate sharedDelegate].userPassword = txtPassword.text;
            [AppDelegate sharedDelegate].userId = [NSString stringWithFormat:@"%@", [_responseObject objectForKey:@"userid"]];
            [AppDelegate sharedDelegate].pilotCert = txtPilotCertification.text;
            [AppDelegate sharedDelegate].pilotCertIssueDate = txtPilotCerIssueDate.text;
            [AppDelegate sharedDelegate].medicalCertIssueDate = txtMedicalCertiIssueDate.text;
            [AppDelegate sharedDelegate].medicalCertExpDate = txtMedicalCertiExpireDate.text;
            [AppDelegate sharedDelegate].cfiCertExpDate = txtCFIDate.text;
            [AppDelegate sharedDelegate].question = lblQuestion.text;
            [AppDelegate sharedDelegate].answer = txtAnswer.text;
            [[AppDelegate sharedDelegate] savePilotProfileToLocal];
            
        }else{
            [ self  showAlert: [_responseObject objectForKey:@"error_str"] :@"Failed!"] ;
        }
        
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [ self  showAlert: @"Internet connection error!" :@"Failed!"] ;
        
    } ;

    [[Communication sharedManager] ActionFlightDeskUserRegisterUpdate:@"register_update_userinfo" firstName:txtFirstName.text middleName:txtMiddleName.text lastName:txtLastName.text email:txtEmail.text phone:txtPhonenumber.text role:strUserRole username:txtUserName.text password:txtPassword.text userid:[AppDelegate sharedDelegate].userId pilotCert:txtPilotCertification.text pilotCertIssueDate:txtPilotCerIssueDate.text medicalCertIssueDate:txtMedicalCertiIssueDate.text medicalCertExpDate:txtMedicalCertiExpireDate.text cfiCertExpDate:txtCFIDate.text question:lblQuestion.text answer:txtAnswer.text successed:successed failure:failure];

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

- (IBAction)onRole:(UIButton *)sender {
    RoleTableView.hidden = NO;
}

- (IBAction)onShowHidePwd:(UIButton *)sender {
    btnShowHide.selected = !btnShowHide.selected;
    if (btnShowHide.selected) {
        txtPassword.secureTextEntry = NO;
    }else{
        txtPassword.secureTextEntry = YES;
    }
}

- (IBAction)onShowHideAnswer:(id)sender {
    btnAnswerShowHide.selected  = !btnAnswerShowHide.selected;
    if (btnAnswerShowHide.selected) {
        txtAnswer.secureTextEntry = NO;
    }else {
        txtAnswer.secureTextEntry = YES;
    }
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

- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
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
        [btnRole setTitle:[arrRole objectAtIndex:indexPath.row] forState:UIControlStateNormal];
        strUserRole = [arrRole objectAtIndex:indexPath.row];
        if ([[arrRole objectAtIndex:indexPath.row] isEqualToString:@"Student"]) {
            lblCFICertiExpirationDate.hidden = YES;
            tipLblCFICertiExpiraDate.hidden = YES;
            txtCFIDate.hidden = YES;
            btnCfiCertExpDate.hidden = YES;
            cfiExpirationBadge.hidden = YES;
        }else{
            lblCFICertiExpirationDate.hidden = NO;
            tipLblCFICertiExpiraDate.hidden = NO;
            txtCFIDate.hidden = NO;
            btnCfiCertExpDate.hidden = NO;
            cfiExpirationBadge.hidden = NO;
        }
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

#pragma mark DateViewControllerDelegate
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    switch (_type) {
        case 1:
            txtPilotCerIssueDate.text = _strDate;
            break;
        case 5:
            txtMedicalCertiExpireDate.text = _strDate;
            break;
        case 3:
            txtCFIDate.text = _strDate;
            break;
        case 4:
            txtMedicalCertiIssueDate.text = _strDate;
            break;
        default:
            break;
    }
    [self calculateBadgeExpirationDate];
    [self removeCurrentViewFromSuper:dateView];
}

- (void)didCancelDateView:(DateViewController *)dateView{
    [self removeCurrentViewFromSuper:dateView];
}

- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    isPromptPicker = NO;
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}

#pragma  mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtFirstName) {
        [txtMiddleName becomeFirstResponder];
    }else if (textField == txtMiddleName) {
        [txtLastName becomeFirstResponder];
    }else if (textField == txtLastName) {
        [txtEmail becomeFirstResponder];
    }else if (textField == txtEmail) {
        [txtPhonenumber becomeFirstResponder];
    }else if (textField == txtPhonenumber) {
        [txtPilotCertification becomeFirstResponder];
    }else if (textField ==txtPilotCertification) {
        //[txtMiddleName becomeFirstResponder];
    }else if (textField ==txtUserName) {
        [txtPassword becomeFirstResponder];
    }
    return  YES;
}

@end
