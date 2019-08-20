//
//  SettingViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/23/17.
//  Copyright © 2017 NOVA.GregoryBayard. All rights reserved.
//

#import "SettingViewController.h"
#import "TOSplitViewController.h"
#import "TrainingViewController.h"
#import "StudentTrainingViewController.h"
#import "AdminTrainingViewController.h"
#import "AircraftViewController.h"
#import "PilotProfileViewController.h"
#import "GeneralViewController.h"
#import "SettingCell.h"
#import "UsersManagementViewController.h"
#import "RecordsFileViewController.h"
#import "UIView+Badge.h"

@interface SettingViewController ()<UITableViewDelegate, UITableViewDataSource>{
    NSArray *settingItemImg;
    NSArray *settingItemLbl;
    NSInteger currentSelectedIndex;
}

@end

@implementation SettingViewController
@synthesize SettingTableView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //[(SecureViewController *)self hideSettingBtn];
    //self.title = @"Settings";
    currentSelectedIndex = 0;
    settingItemImg = [[NSArray alloc] initWithObjects:@"gneral_setting.png", @"pilotprofile_set.png", @"Logbook.png", @"Programs.png",@"records.png",@"logout.png", nil];
    settingItemLbl = [[NSArray alloc] initWithObjects:@"General", @"Pilot Profile", @"Aircraft", @"Training",@"Records",@"Logout", nil];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        settingItemImg = [[NSArray alloc] initWithObjects:@"gneral_setting.png", @"Logbook.png",@"Programs.png",@"records.png", @"logout.png", nil];
        settingItemLbl = [[NSArray alloc] initWithObjects:@"General", @"Aircraft",@"Training",@"Records",@"Logout", nil];
    }
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        settingItemImg = [[NSArray alloc] initWithObjects:@"gneral_setting.png", @"pilotprofile_set.png", @"Logbook.png", @"Programs.png", @"users_setting.png",@"records.png",@"logout.png", nil];
        settingItemLbl = [[NSArray alloc] initWithObjects:@"General", @"Pilot Profile", @"Aircraft", @"Training",@"Users", @"Records",@"Logout", nil];
    }
    SettingTableView.delegate = self;
    SettingTableView.dataSource = self;
    [SettingTableView reloadData];
    if ([AppDelegate sharedDelegate].general_VC) {
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:[AppDelegate sharedDelegate].general_VC] sender:self];
    }else{
        GeneralViewController *controller = [[GeneralViewController alloc] init];
        [AppDelegate sharedDelegate].general_VC = controller;
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    }
    [SettingTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"SettingviewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self setNavigationColorWithGradiant];
    [AppDelegate sharedDelegate].setting_VC = self;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [AppDelegate sharedDelegate].setting_VC = nil;
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:229.0f/255.0f green:45.0f/255.0f blue:39.0f/2551.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:179.0f/255.0f green:18.0f/255.0f blue:23.0f/255.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnToPreview) name:NOTIFICATION_TAP_TABITEM object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAircraftBadge) name:NOTIFICATION_AIRCRAFT_BADGE object:nil];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_TAP_TABITEM object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_AIRCRAFT_BADGE object:nil];
    
}
- (void)reloadAircraftBadge{
    [SettingTableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)returnToPreview{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [settingItemImg count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SettingItem";
    SettingCell *settingCell = (SettingCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (settingCell == nil) {
        settingCell = [SettingCell sharedCell];
    }
    if ([[settingItemImg objectAtIndex:indexPath.row] isEqualToString:@"delete"]) {
        settingCell.itemLbl.text = [settingItemLbl objectAtIndex:indexPath.row];
        settingCell.itemLbl.textColor = [UIColor redColor];
    }else{
        [settingCell.itemImg setImage:[UIImage imageNamed:[settingItemImg objectAtIndex:indexPath.row]]];
        settingCell.itemLbl.text = [settingItemLbl objectAtIndex:indexPath.row];
        settingCell.itemLbl.textColor = [UIColor blackColor];
    }
    
    if ([[settingItemLbl objectAtIndex:indexPath.row] isEqualToString:@"Aircraft"]) {
        settingCell.lblBadge.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:nil];
        settingCell.lblBadge.badge.badgeColor = [UIColor redColor];
    }
    [settingCell.contentView setBackgroundColor:[UIColor clearColor]];
    if (indexPath.row == currentSelectedIndex) {
        [settingCell.contentView setBackgroundColor:[UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0]];
    }
    return settingCell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    currentSelectedIndex = indexPath.row;
    NSString *title = [settingItemLbl objectAtIndex:indexPath.row];
    // Two columns
    if ([title isEqualToString:@"General"]) {
        if ([AppDelegate sharedDelegate].general_VC) {
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:[AppDelegate sharedDelegate].general_VC] sender:self];
        }else{
            GeneralViewController *controller = [[GeneralViewController alloc] init];
            [AppDelegate sharedDelegate].general_VC = controller;
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
        }
    }else if ([title isEqualToString:@"Pilot Profile"]) {
        PilotProfileViewController *controller = [[PilotProfileViewController alloc] init];
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    }else if ([title isEqualToString:@"Users"]) {
        UsersManagementViewController *controller = [[UsersManagementViewController alloc] init];
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    }else if ([title isEqualToString:@"Aircraft"]) {
        if ([AppDelegate sharedDelegate].aircraft_vc == nil) {
            AircraftViewController *controller = [[AircraftViewController alloc] init];
            [AppDelegate sharedDelegate].aircraft_vc = controller;
        }
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:[AppDelegate sharedDelegate].aircraft_vc] sender:self];
    }else if ([title isEqualToString:@"Records"]) {
        if ([AppDelegate sharedDelegate].recordsfile_VC == nil) {
            RecordsFileViewController *controller = [[RecordsFileViewController alloc] init];
            [AppDelegate sharedDelegate].recordsfile_VC = controller;
        }
        [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:[AppDelegate sharedDelegate].recordsfile_VC] sender:self];
    }else if ([title isEqualToString:@"Training"]) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            TrainingViewController *controller = [[TrainingViewController alloc] init];
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]){
            StudentTrainingViewController *controller = [[StudentTrainingViewController alloc] init];
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]  || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]){
            AdminTrainingViewController *controller = [[AdminTrainingViewController alloc] init];
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
        }
    }else if ([title isEqualToString:@"Logout"]) {
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Are you sure you want to logout from FlightDesk?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            
            [self logout];
        }];
        UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            
        }];
        [alert addAction:yesButton];
        [alert addAction:noButton];
        [self presentViewController:alert animated:YES completion:nil];
    }else if ([title isEqualToString:@"Delete user"]) {
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Do you want to delete current user?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            
            [self deleteCurrentUser];
        }];
        UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            
        }];
        [alert addAction:yesButton];
        [alert addAction:noButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [SettingTableView reloadData];
}
- (void)deleteCurrentUser{
    
    [ MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated : YES ] ;
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        [ MBProgressHUD hideHUDForView : [AppDelegate sharedDelegate].window animated : YES ] ;
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults removeObjectForKey:@"userName"];
            [userDefaults removeObjectForKey:@"userId"];
            [userDefaults synchronize];
            
            [[AppDelegate sharedDelegate] clearDocuments];
            [[AppDelegate sharedDelegate] clearLessons];
            [[AppDelegate sharedDelegate] deletePilotProfileFromLocal];
            [AppDelegate sharedDelegate].isBackPreUser = NO;
            [AppDelegate sharedDelegate].isLogin = NO;
            [[AppDelegate sharedDelegate] gotoMainView];
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SyncedAllDataFromServer"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:[_responseObject objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [ MBProgressHUD hideHUDForView : [AppDelegate sharedDelegate].window animated : YES ] ;
        
    } ;
    [[Communication sharedManager] ActionFlightDeskDeleteCurrentUser:@"delete_user" userId:[AppDelegate sharedDelegate].userId successed:successed failure:failure];
}
- (void)logout{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet to log out." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSLog(@"you pressed Yes, please button");
        }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
        
    }
    
    [ MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated : YES ] ;
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        [ MBProgressHUD hideHUDForView : [AppDelegate sharedDelegate].window animated : YES ] ;
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults removeObjectForKey:@"userName"];
            [userDefaults removeObjectForKey:@"instructorInfo"];
            [userDefaults synchronize];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            [AppDelegate sharedDelegate].isLogin = NO;
            [[AppDelegate sharedDelegate] gotoMainView];
            [[AppDelegate sharedDelegate] sendPushForLogInOut:0];
            
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SyncedAllDataFromServer"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:[_responseObject objectForKey:@"msg"] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [ MBProgressHUD hideHUDForView : [AppDelegate sharedDelegate].window animated : YES ] ;
        
    } ;
    [[Communication sharedManager] ActionFlightDeskLogout:@"logout" userId:[AppDelegate sharedDelegate].userId successed:successed failure:failure];
}

@end
