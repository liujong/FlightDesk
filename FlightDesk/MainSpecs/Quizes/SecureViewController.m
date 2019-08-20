//
//  SecureViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 2/1/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "SecureViewController.h"
#import "LoginView.h"
#import "DashboardView.h"
#import "AppDelegate.h"
#import "SettingViewController.h"
#import "GeneralViewController.h"
#import "TOSplitViewController.h"
#import "RegisterViewController.h"
#import "LoginViewController.h"
#import "WelcomeViewController.h"
#import "VerfiyViewController.h"
#import "UIView+Badge.h"

@interface SecureViewController () <RegisterViewControllerDelegate, TOSplitViewControllerDelegate, LoginViewControllerDelegate, WelcomeViewControllerDelegate, VerfiyViewControllerDelegate>

@end

@implementation SecureViewController
{
    DashboardView *dashboardView;
}

- (void)viewDidLoad
{
    [self.navigationController.navigationBar  setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.view.backgroundColor = [UIColor whiteColor];
    // add the dashboard button
    UIImage *dashImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Dashboard" ofType:@"png"]];
    CGRect dashImageFrame = CGRectMake(0, 0, dashImage.size.width, dashImage.size.height);
    UIButton *dashButton = [[UIButton alloc] initWithFrame:dashImageFrame];
    [dashButton setBackgroundImage:dashImage forState:UIControlStateNormal];
    [dashButton addTarget:self action:@selector(showDashboard) forControlEvents:UIControlEventTouchUpInside];
    [dashButton setShowsTouchWhenHighlighted:YES];
    UIView *containsViewOfDashboard = [[UIView alloc] initWithFrame:CGRectMake(5, 0, dashImage.size.width+10, dashImage.size.height)];
    [containsViewOfDashboard addSubview:dashButton];
    
    UIBarButtonItem *dashButtonItem =[[UIBarButtonItem alloc] initWithCustomView:containsViewOfDashboard];
    
    UIImage *settingsImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Settings_nav" ofType:@"png"]];
    CGRect settingsImageFrame = CGRectMake(0, 0, settingsImage.size.width, settingsImage.size.height);
    settingsButton = [[UIButton alloc] initWithFrame:settingsImageFrame];
    [settingsButton setBackgroundImage:settingsImage forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setShowsTouchWhenHighlighted:YES];
    
    UIButton *settingCvBtn = [[UIButton alloc] initWithFrame:settingsImageFrame];
    [settingCvBtn addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [settingCvBtn setShowsTouchWhenHighlighted:YES];
    
    UIView *containsViewOfSetting = [[UIView alloc] initWithFrame:CGRectMake(5, 0, settingsImage.size.width+10, settingsImage.size.height)];
    [containsViewOfSetting addSubview:settingsButton];
    [containsViewOfSetting addSubview:settingCvBtn];
    UIBarButtonItem *settingsButtonItem =[[UIBarButtonItem alloc] initWithCustomView:containsViewOfSetting];
    //self.navigationItem.rightBarButtonItem=dashButtonItem;
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:dashButtonItem, settingsButtonItem, nil];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    if (username && userId && ![username isEqualToString:@""] && ![userId isEqualToString:@""]) {
        [[AppDelegate sharedDelegate] loadPilotProfileFromLocal];
        if ([AppDelegate sharedDelegate].isVerify == 1) {
            [AppDelegate sharedDelegate].isLogin = YES;
            [[AppDelegate sharedDelegate] sendPushForLogInOut:1];
        }
    }
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAircraftBadge) name:NOTIFICATION_AIRCRAFT_BADGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideDashBoardFromPush) name:NOTIFICATION_CLOSE_DASHBOARD object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_AIRCRAFT_BADGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_CLOSE_DASHBOARD object:nil];
}
- (void)reloadAircraftBadge{
    settingsButton.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:nil];
    settingsButton.badge.badgeColor = [UIColor redColor];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [super viewWillAppear:animated];
    
    settingsButton.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:nil];
    settingsButton.badge.badgeColor = [UIColor redColor];
    // check if the user must login!
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    if (username && userId && ![username isEqualToString:@""] && ![userId isEqualToString:@""]) {
        [[AppDelegate sharedDelegate] loadPilotProfileFromLocal];
        if ([AppDelegate sharedDelegate].isVerify == 1) {
            [AppDelegate sharedDelegate].isLogin = YES;
            if ([AppDelegate sharedDelegate].isOpenFirstWithDash == NO){
                [AppDelegate sharedDelegate].isOpenFirstWithDash = YES;
                [self showDashboard];
                [[AppDelegate sharedDelegate] logUser];
            }
        }else{
            
            if (self.navigationController != nil) {
                self.navigationController.navigationBar.userInteractionEnabled = NO;
            }
            
            [AppDelegate sharedDelegate].isLogin = NO;
            VerfiyViewController *verifyView = [[VerfiyViewController alloc] initWithNibName:@"VerfiyViewController" bundle:nil];
            [verifyView.view setFrame:[UIScreen mainScreen].bounds];
            verifyView.delegate = self;
            verifyView.verifiyType = 1;
            [self displayContentController:verifyView];
            [verifyView animateShow];
        }
    }else if (userId && ![userId isEqualToString:@""] && (!username || [username isEqualToString:@""]) ){
        // disable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }
        [AppDelegate sharedDelegate].isLogin = NO;
        [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
        LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
        [loginView.view setFrame:[UIScreen mainScreen].bounds];
        loginView.delegate = self;
        loginView.isLogin = YES;
        [self displayContentController:loginView];
        [loginView animateShowLoginView];
        
    }else if (([username isEqualToString:@""] && [userId isEqualToString:@""]) || (!userId && !username)){
        // disable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }
        [AppDelegate sharedDelegate].isLogin = NO;
        [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
        WelcomeViewController *welView = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
        [welView.view setFrame:[UIScreen mainScreen].bounds];
        welView.delegate = self;
        [self displayContentController:welView];
        [welView showAnimation];
    }
}
- (void)superClassDeviceOrientationDidChange{
    if (dashboardView != nil) {
        [dashboardView setFrame:[[UIScreen mainScreen] bounds]];
        CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
        if (currentScreenRect.size.height<currentScreenRect.size.width) {
            [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
        }else{
            [dashboardView setContentSize:CGSizeMake(0,0)];
        }
        [dashboardView reloadViewsWithCurrentScreen];
    }
}
-(void)hideSettingBtn{
    settingsButton.hidden = YES;
}
- (void)hideDashBoardFromPush{
    if (dashboardView != nil) {
        dashboardView.hidden = YES;
        [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:dashboardView];
        [dashboardView removeFromSuperview];
        dashboardView = nil;
        // enable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = YES;
        }
    }
}
-(void)handleDashboardTap:(UIGestureRecognizer *)gestureRecognizer {
    if (dashboardView != nil) {
        dashboardView.hidden = YES;
        [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:dashboardView];
        [dashboardView removeFromSuperview];
        dashboardView = nil;
        // enable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = YES;
        }
    }
}

-(void)showDashboard
{
    if (dashboardView != nil) {
        NSLog(@"Dashboard already displayed!");
        return;
    }
    // disable naviation bar
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    // create a new dashboard view
    dashboardView = [[DashboardView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
    if (currentScreenRect.size.height<currentScreenRect.size.width) {
        [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
    }else{
        [dashboardView setContentSize:CGSizeMake(0,0)];
    }
    // use tap gesture to close view
    UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDashboardTap:)];
    [dashboardView addGestureRecognizer:tapToClose];
    // add the view to the root view controller
    [AppDelegate sharedDelegate].reloadDashBoard_V = dashboardView;
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:dashboardView];
}

-(void)showSettings
{
    SettingViewController *settingVc = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    NSArray *controllers = @[settingVc];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewController.delegate = self;
    splitViewController.title = @"Settings";
    splitViewController.isShowFromSetting = YES;
    [self.navigationController pushViewController:splitViewController animated:YES];
}
-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        //NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)loggedInSuccessfully
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_LOGIN_SUCCESSFUL_SNYC object:nil userInfo:nil];
    //start sync thread
}

#pragma mark VerifyViewControllerDelegate methods
- (void)returnVerifyView:(VerfiyViewController *)verifyView{
    
    [self removeContentcontroller:verifyView];
//    LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
//    [loginView.view setFrame:self.view.bounds];
//    loginView.delegate = self;
//    loginView.isLogin = YES;
//    [self displayContentController:loginView];
//    [loginView animateShowLoginView];
}
- (void)cancelVerifyView:(VerfiyViewController *)verifyView{
    
    [self removeContentcontroller:verifyView];
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    [AppDelegate sharedDelegate].isLogin = NO;
    [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
    LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [loginView.view setFrame:self.view.bounds];
    loginView.delegate = self;
    loginView.isLogin = YES;
    [self displayContentController:loginView];
    [loginView animateShowLoginView];
}


#pragma mark WelcomeViewControllerDelegate methods
- (void)didRegisterPilotProfile:(WelcomeViewController *)welView{
    
    [self removeContentcontroller:welView];
    RegisterViewController *registerView = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
    [registerView.view setFrame:[UIScreen mainScreen].bounds];
    registerView.delegate = self;
    [self displayContentController:registerView];
    [registerView animateShow];
    
}
- (void)didSignInPilotAccount:(WelcomeViewController *)welView{
    
    [self removeContentcontroller:welView];
    LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [loginView.view setFrame:[UIScreen mainScreen].bounds];
    loginView.delegate = self;
    loginView.isLogin = YES;
    [self displayContentController:loginView];
    [loginView animateShowLoginView];
}
- (void) displayContentController: (UIViewController*) content;
{
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:content.view];
    [[AppDelegate sharedDelegate].window.rootViewController addChildViewController:content];
    [content didMoveToParentViewController:[AppDelegate sharedDelegate].window.rootViewController];
    
//    [self.view addSubview:content.view];
//    [self addChildViewController:content];
//    [content didMoveToParentViewController:self];
}
- (void)removeContentcontroller:(UIViewController *)content{
    
    [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:content.view];
    [content willMoveToParentViewController:nil];  // 1
    [content.view removeFromSuperview];            // 2
    [content removeFromParentViewController];
}
#pragma mark RegisterViewDelegate methods
- (void)loginButtonTappedInRegisterView{
    // disable naviation bar
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    LoginViewController *loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
    [loginView.view setFrame:[UIScreen mainScreen].bounds];
    loginView.delegate = self;
    loginView.isLogin = YES;
    [self displayContentController:loginView];
    [loginView animateShowLoginView];
}
- (void)registerButtonTappedInRegisterView:(RegisterViewController *)registerView{
    
    [self removeContentcontroller:registerView];
    
    // disable naviation bar
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    VerfiyViewController *verifyView = [[VerfiyViewController alloc] initWithNibName:@"VerfiyViewController" bundle:nil];
    [verifyView.view setFrame:[UIScreen mainScreen].bounds];
    verifyView.delegate = self;
    verifyView.verifiyType = 3;
    [self displayContentController:verifyView];
    [verifyView animateShow];

}

#pragma mark LoginViewDelegate methods
- (void)loginSuccessfuly:(LoginViewController *)loginView{
    [self removeContentcontroller:loginView];
}
- (void)gotoRegisterView:(LoginViewController *)loginView{
    
    [self removeContentcontroller:loginView];
    
    RegisterViewController *registerView = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
    [registerView.view setFrame:[UIScreen mainScreen].bounds];
    registerView.delegate = self;
    [self displayContentController:registerView];
    [registerView animateShow];
}
@end
