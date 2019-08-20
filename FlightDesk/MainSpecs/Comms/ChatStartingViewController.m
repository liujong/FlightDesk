//
//  ChatStartingViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/26/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ChatStartingViewController.h"
#import "DashboardView.h"
#import "SettingViewController.h"
@interface ChatStartingViewController ()<TOSplitViewControllerDelegate>{
    DashboardView *dashboardView;
}

@end

@implementation ChatStartingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [AppDelegate sharedDelegate].isShownChatBoard = YES;
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
}
- (IBAction)onSetting:(id)sender {
    SettingViewController *settingVc = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    NSArray *controllers = @[settingVc];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewController.delegate = self;
    splitViewController.title = @"Settings";
    splitViewController.isShowFromSetting = YES;
    [[AppDelegate sharedDelegate].commsMain_vc.navigationController pushViewController:splitViewController animated:YES];
}

- (IBAction)onDashBoard:(id)sender {
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
    
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:dashboardView];
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
@end
