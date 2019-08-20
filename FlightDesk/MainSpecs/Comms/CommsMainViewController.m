//
//  CommsMainViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "CommsMainViewController.h"
#import "LiveChatViewController.h"
#import "ChatStartingViewController.h"
#import "LiveMemberCell.h"

@interface CommsMainViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>{
    NSMutableArray *userInfoArray;
    NSMutableArray *searchedUserArray;
    
    NSInteger selectedIndex;
}

@end

@implementation CommsMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Comms";
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    userInfoArray = [[NSMutableArray alloc] init];
    searchedUserArray = [[NSMutableArray alloc] init];
    selectedIndex = -4;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        userTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    }else{
        userTableView.contentInset = UIEdgeInsetsMake(-20.0f, 0.0f, 0.0f, 0.0f);
    }
    
    lblGeneralChatBadgeCount.layer.cornerRadius = lblGeneralChatBadgeCount.frame.size.height / 2.0f;
    lblGeneralChatBadgeCount.layer.masksToBounds = YES;
    
    lblGeneralChatBadgeCount.hidden = YES;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        [headerView setFrame:CGRectMake(0, 0, 200, 144)];
        btnGeneralBanersByAdmin.hidden = NO;
    }else{
        [headerView setFrame:CGRectMake(0, 0, 200, 94)];
        btnGeneralBanersByAdmin.hidden = YES;
    }
    
    //hide if current user is support team
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        btnSupport.hidden = YES;
    }
    
    ChatStartingViewController *controller = [[ChatStartingViewController alloc] init];
    [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    [self onGeneralRoon:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        [self getUsersWhatRequestSupports];
    }else{
        [self getUserInfos];
    }
    [AppDelegate sharedDelegate].commsMain_vc = self;
    [self setNavigationColorWithGradiant];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"CommsMainViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    //
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
}
- (void)setNavigationColorWithGradiant{
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:85.0f/255.0f blue:1.0f alpha:1.0f].CGColor, (__bridge id)[UIColor magentaColor].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [navImageVoiew setImage:gradientImage];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [AppDelegate sharedDelegate].commsMain_vc = nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)getUsersWhatRequestSupports{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"get_users_request_support", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
    NSData *usersJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *usersRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [usersRequest setHTTPMethod:@"POST"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [usersRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)usersJSON.length] forHTTPHeaderField:@"Content-Length"];
    [usersRequest setHTTPBody:usersJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *usersTask = [session dataTaskWithRequest:usersRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                    
                    [userInfoArray removeAllObjects];
                    [searchedUserArray removeAllObjects];
                    for (NSDictionary *userInfo in [queryResults objectForKey:@"users"]) {
                        [userInfoArray addObject:userInfo];
                    }
                    searchedUserArray = [userInfoArray mutableCopy];
                    [userTableView reloadData];
                    
                });
                
            }else{
                
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
    [usersTask resume];
}
- (void)getUserInfos{
    [userInfoArray removeAllObjects];
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]) {
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve LessonGroups!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid LessonGroup found!");
        } else {
            for (LessonGroup *lessonGroup in objects) {
                if ([lessonGroup.instructorID integerValue] != 0 && ![lessonGroup.instructorName.lowercaseString isEqualToString:@"admin"]) {
                    BOOL isExit = NO;
                    for (NSDictionary *dict in userInfoArray) {
                        if ([[dict objectForKey:@"userID"] integerValue] == [lessonGroup.instructorID integerValue]) {
                            isExit = YES;
                            break;
                        }
                    }
                    if (!isExit) {
                        NSMutableDictionary *oneInstructorInfo = [[NSMutableDictionary alloc] init];
                        [oneInstructorInfo setObject:lessonGroup.instructorID forKey:@"userID"];
                        [oneInstructorInfo setObject:lessonGroup.instructorName forKey:@"userFullName"];
                        [oneInstructorInfo setObject:lessonGroup.instructorDeviceToken forKey:@"deviceToken"];
                        [oneInstructorInfo setObject:lessonGroup.instructorBadgeCount forKey:@"badgeCount"];
                        [oneInstructorInfo setObject:lessonGroup.is_active forKey:@"isActive"];
                        [oneInstructorInfo setObject:@"Instructor" forKey:@"type"];
                        [userInfoArray addObject:oneInstructorInfo];
                    }
                }
                
            }
        }
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            for (Student *student in objects) {
                BOOL isExit = NO;
                for (NSDictionary *dict in userInfoArray) {
                    if ([[dict objectForKey:@"userID"] integerValue] == [student.userID integerValue]) {
                        isExit = YES;
                        break;
                    }
                }
                if (!isExit) {
                    NSMutableDictionary *oneStudentInfo = [[NSMutableDictionary alloc] init];
                    [oneStudentInfo setObject:student.userID forKey:@"userID"];
                    [oneStudentInfo setObject:[NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName] forKey:@"userFullName"];
                    [oneStudentInfo setObject:student.deviceToken forKey:@"deviceToken"];
                    [oneStudentInfo setObject:student.badgeCount forKey:@"badgeCount"];
                    [oneStudentInfo setObject:student.is_active forKey:@"isActive"];
                    [oneStudentInfo setObject:@"Pilot" forKey:@"type"];
                    [userInfoArray addObject:oneStudentInfo];
                }
            }
        }
    }
    
    NSMutableArray *tempStudents = [userInfoArray mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userFullName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedStudents = [tempStudents sortedArrayUsingDescriptors:sortDescriptors];
    [userInfoArray removeAllObjects];
    userInfoArray = [sortedStudents mutableCopy];
    
    [self getBadgeCountOfGeneralRoom];
    
    [[AppDelegate sharedDelegate].isActivedUsersData removeAllObjects];
    for (NSDictionary *userInfo in userInfoArray) {
        NSMutableDictionary *dictActivedStatus = [[NSMutableDictionary alloc] init];
        [dictActivedStatus setObject:[userInfo objectForKey:@"userID"] forKey:@"userID"];
        [dictActivedStatus setObject:[userInfo objectForKey:@"isActive"] forKey:@"isActive"];
        [[AppDelegate sharedDelegate].isActivedUsersData addObject:dictActivedStatus];
    }
    [self updateUsersActivityStatusWithServer];
    searchedUserArray = [userInfoArray mutableCopy];
    
    [userTableView reloadData];
}

- (void)updateUsersActivityStatusWithServer{
    if ([[AppDelegate sharedDelegate].isActivedUsersData count] == 0) {
        return;
    }
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *apiURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"getUsersActivityStatus", @"action", [AppDelegate sharedDelegate].userId, @"user_id",[[AppDelegate sharedDelegate].isActivedUsersData copy], @"users", nil];
    NSError *error;
    NSData *jsonRequestData =[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRequestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *documentsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil) {
                    FDLogError(@"Unable to parse JSON for list!");
                    return;
                }
                
                if ([results objectForKey:@"success"]) {
                    id value = [results objectForKey:@"users"];
                    if ([value isKindOfClass:[NSArray class]]) {
                        NSArray *usersArray = value;
                        [[AppDelegate sharedDelegate].isActivedUsersData  removeAllObjects];
                        for (id userElement in usersArray) {
                            if ([userElement isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *userDetails = userElement;
                                NSMutableDictionary *dictActivedStatus = [[NSMutableDictionary alloc] init];
                                [dictActivedStatus setObject:[userDetails objectForKey:@"user_id"] forKey:@"userID"];
                                [dictActivedStatus setObject:[userDetails objectForKey:@"isActive"] forKey:@"isActive"];
                                [[AppDelegate sharedDelegate].isActivedUsersData addObject:dictActivedStatus];
                            }
                        }
                    }
                    [userTableView reloadData];
                }
            });
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download documents: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download documents due to unknown error!");
            }
        }
    }];
    [documentsTask resume];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchedUserArray count];
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    if (tableView == userTableView) {
        [view addSubview:headerView];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView == userTableView) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            return 144.0f;
        }else{
            return 94.0f;
        }
    }
    
    return 0.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60.0f;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:NO];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"LiveMemberItem";
    LiveMemberCell *cell = (LiveMemberCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [LiveMemberCell sharedCell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *userinfo = [searchedUserArray objectAtIndex:indexPath.row];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        
        cell.lblUserName.text = [NSString stringWithFormat:@"%@ %@ %@", [userinfo objectForKey:@"first_name"],[userinfo objectForKey:@"middle_name"], [userinfo objectForKey:@"last_name"]];
        [cell setBorder];
        [cell parseUserName:[NSString stringWithFormat:@"%@ %@", [userinfo objectForKey:@"first_name"], [userinfo objectForKey:@"last_name"]]];
        cell.lblUsersType.text = [userinfo objectForKey:@"user_level"];
        [cell setColorOnline:[userinfo objectForKey:@"isRequest"]];
        
        if (selectedIndex == indexPath.row) {
            [cell setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
            for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                NSDictionary *badgeDetails = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                if ([[badgeDetails objectForKey:@"userID"] integerValue] == [[userinfo objectForKey:@"user_id"] integerValue]) {
                    [[AppDelegate sharedDelegate].unreadData removeObjectAtIndex:i];
                }
            }
            NSInteger count = 0;
            for (NSDictionary *dict in [AppDelegate sharedDelegate].unreadData) {
                count = count + [[dict objectForKey:@"unreadCount"] integerValue];
            }
            if (count == 0) {
                [AppDelegate sharedDelegate].comms_nc.tabBarItem.badgeValue = nil;
            }else{
                [AppDelegate sharedDelegate].comms_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
            }
            
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[AppDelegate sharedDelegate].countRedBadge + count];
            [self markReadStatusAllChatHistories:[userinfo objectForKey:@"user_id"]];
        }else{
            [cell setBackgroundColor:[UIColor clearColor]];
        }
        
        //show red badge for each user
        cell.redBOfOneUser.hidden = YES;
        NSNumber *currentUserID = [userinfo objectForKey:@"user_id"];
        NSInteger countBadgeOfCurrentUser = [self getRedBadgeOfCurrentUser:currentUserID];
        if (countBadgeOfCurrentUser > 0) {
            cell.redBOfOneUser.hidden = NO;
            cell.redBOfOneUser.text = [NSString stringWithFormat:@"%ld", (long)countBadgeOfCurrentUser];
        }
    }else{
        
        cell.lblUserName.text = [userinfo objectForKey:@"userFullName"];
        [cell setBorder];
        [cell parseUserName:[userinfo objectForKey:@"userFullName"]];
        cell.lblUsersType.text = [userinfo objectForKey:@"type"];
        
        if ([[AppDelegate sharedDelegate].isActivedUsersData count] > indexPath.row) {
            NSDictionary *userActivityStatusDetails = [[AppDelegate sharedDelegate].isActivedUsersData objectAtIndex:indexPath.row];
            [cell setColorOnline:[userActivityStatusDetails objectForKey:@"isActive"]];
        }else{
            [cell setColorOnline:[userinfo objectForKey:@"isActive"]];
        }
        
        if (selectedIndex == indexPath.row) {
            [cell setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
            for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                NSDictionary *badgeDetails = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                if ([[badgeDetails objectForKey:@"userID"] integerValue] == [[userinfo objectForKey:@"userID"] integerValue]) {
                    [[AppDelegate sharedDelegate].unreadData removeObjectAtIndex:i];
                }
            }
            NSInteger count = 0;
            for (NSDictionary *dict in [AppDelegate sharedDelegate].unreadData) {
                count = count + [[dict objectForKey:@"unreadCount"] integerValue];
            }
            if (count == 0) {
                [AppDelegate sharedDelegate].comms_nc.tabBarItem.badgeValue = nil;
            }else{
                [AppDelegate sharedDelegate].comms_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
            }
            
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[AppDelegate sharedDelegate].countRedBadge + count];
            [self markReadStatusAllChatHistories:[userinfo objectForKey:@"userID"]];
        }else{
            [cell setBackgroundColor:[UIColor clearColor]];
        }
        
        //show red badge for each user
        cell.redBOfOneUser.hidden = YES;
        NSNumber *currentUserID = [userinfo objectForKey:@"userID"];
        NSInteger countBadgeOfCurrentUser = [self getRedBadgeOfCurrentUser:currentUserID];
        if (countBadgeOfCurrentUser > 0) {
            cell.redBOfOneUser.hidden = NO;
            cell.redBOfOneUser.text = [NSString stringWithFormat:@"%ld", (long)countBadgeOfCurrentUser];
        }
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [btnGeneralBanersByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnGeneralByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnSupport setBackgroundColor:[UIColor clearColor]];
    if (selectedIndex == indexPath.row) {
        
    }else{
        selectedIndex = indexPath.row;
        LiveChatViewController *controller = [[LiveChatViewController alloc] init];
        NSDictionary *userinfo = [searchedUserArray objectAtIndex:indexPath.row];
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            NSArray *parseNameArray = [[NSString stringWithFormat:@"%@ %@", [userinfo objectForKey:@"first_name"], [userinfo objectForKey:@"last_name"]] componentsSeparatedByString:@" "];
            NSString *abbName = @"";
            if (parseNameArray.count == 1) {
                abbName = [[parseNameArray[0] substringToIndex:1] uppercaseString];
            }else {
                abbName = [NSString stringWithFormat:@"%@%@", [[parseNameArray[0] substringToIndex:1] uppercaseString], [[parseNameArray[1] substringToIndex:1] uppercaseString]];
            }
            controller.abbreviationName =  abbName;
            controller.friendID = [userinfo objectForKey:@"user_id"];
            controller.friendName = [NSString stringWithFormat:@"%@ %@ %@", [userinfo objectForKey:@"first_name"],[userinfo objectForKey:@"middle_name"], [userinfo objectForKey:@"last_name"]];
            controller.deviceToken = [userinfo objectForKey:@"device_token"];
            controller.badgeCountOfUser = @0;
            [AppDelegate sharedDelegate].liveChat_vc = controller;
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
            
            for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                NSDictionary *badgeDetails = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                if ([[badgeDetails objectForKey:@"userID"] integerValue] == [[userinfo objectForKey:@"user_id"] integerValue]) {
                    [[AppDelegate sharedDelegate].unreadData removeObjectAtIndex:i];
                }
            }
            [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
            [self markReadStatusAllChatHistories:[userinfo objectForKey:@"user_id"]];
        }else{
            
            NSArray *parseNameArray = [[userinfo objectForKey:@"userFullName"] componentsSeparatedByString:@" "];
            NSString *abbName = @"";
            if (parseNameArray.count == 1) {
                abbName = [[parseNameArray[0] substringToIndex:1] uppercaseString];
            }else if (parseNameArray.count != 0) {
                abbName = [[parseNameArray[0] substringToIndex:1] uppercaseString];
                NSString *midName = parseNameArray[1];
                if (midName.length > 1) {
                    abbName = [NSString stringWithFormat:@"%@%@", abbName, [[parseNameArray[1] substringToIndex:1] uppercaseString]];
                }else if (parseNameArray.count == 3){
                    midName = parseNameArray[2];
                    if (midName.length > 1) {
                        abbName = [NSString stringWithFormat:@"%@%@", abbName, [[parseNameArray[2] substringToIndex:1] uppercaseString]];
                    }
                }
            }
            controller.abbreviationName =  abbName;
            controller.friendID = [userinfo objectForKey:@"userID"];
            controller.friendName = [userinfo objectForKey:@"userFullName"];
            controller.deviceToken = [userinfo objectForKey:@"deviceToken"];
            controller.badgeCountOfUser = [userinfo objectForKey:@"badgeCount"];
            [AppDelegate sharedDelegate].liveChat_vc = controller;
            [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
            
            for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                NSDictionary *badgeDetails = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                if ([[badgeDetails objectForKey:@"userID"] integerValue] == [[userinfo objectForKey:@"userID"] integerValue]) {
                    [[AppDelegate sharedDelegate].unreadData removeObjectAtIndex:i];
                }
            }
            [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
            [self markReadStatusAllChatHistories:[userinfo objectForKey:@"userID"]];
        }
        [userTableView reloadData];
    }
}
- (void)markReadStatusAllChatHistories:(NSNumber *)targetUserID{
    NSError *error;
    NSString *userID = [AppDelegate sharedDelegate].userId;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        userID = @"999999";
    }
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"mark_allChatHistories_currentUser", @"action", userID, @"user_id", targetUserID, @"target_user_id", nil];
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
- (void)markReadStatusGeneral{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"mark_readstatus_general", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
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
- (NSInteger)getRedBadgeOfCurrentUser:(NSNumber *)userID{
    NSInteger count = 0;
    for (NSDictionary *dict in [AppDelegate sharedDelegate].unreadData) {
        if ([[dict objectForKey:@"userID"] integerValue] == [userID integerValue]) {
            count = count + [[dict objectForKey:@"unreadCount"] integerValue];
        }
    }
    return count;
}


- (void)getBadgeCountOfGeneralRoom{
    if (selectedIndex == -1) {
        [AppDelegate sharedDelegate].unreadGeneralCount = 0;
        [self markReadStatusGeneral];
    }
    
    
    if ([AppDelegate sharedDelegate].unreadGeneralCount > 0) {
        lblGeneralChatBadgeCount.hidden = NO;
        lblGeneralChatBadgeCount.text  = [NSString stringWithFormat:@"%ld", (long)[AppDelegate sharedDelegate].unreadGeneralCount];
    }else {
        lblGeneralChatBadgeCount.hidden = YES;
    }
}

- (void)reloadTableViewWithPush{
    [self getBadgeCountOfGeneralRoom];
    [self updateUsersActivityStatusWithServer];
}

- (void)reloadTableViewWithOnlineStatus:(NSString *)fromDevice onLinevalue:(NSNumber*)online
 {
    if (userInfoArray == nil)
        return;
    for (NSMutableDictionary *oneUser in userInfoArray) {
        NSString *deviceToken = @"";
        deviceToken = [oneUser objectForKey:@"deviceToken"];
        if ([[deviceToken lowercaseString] rangeOfString:fromDevice.lowercaseString].location != NSNotFound){
            [oneUser setObject:(NSNumber*)online forKey:@"isActive"];
        }
    }
     
     [userTableView reloadData];
}

#pragma mark - UISearchBarDelegata
#pragma - SearchBar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [searchedUserArray removeAllObjects];
    searchedUserArray =[userInfoArray mutableCopy];
    [userTableView reloadData];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [userSearchBar resignFirstResponder];
    if (searchBar.text.length != 0) {
        searchedUserArray = [NSMutableArray new];
        for (NSDictionary *oneUser in userInfoArray) {
            NSString *name = @"";
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
                name = [NSString stringWithFormat:@"%@ %@", [oneUser objectForKey:@"first_name"], [oneUser objectForKey:@"last_name"]];
            }else{
                name = [oneUser objectForKey:@"userFullName"];
            }
            if ([[name lowercaseString] rangeOfString:searchBar.text.lowercaseString].location != NSNotFound) {
                [searchedUserArray addObject:oneUser];
            }
        }
    } else {
        [searchedUserArray removeAllObjects];
        
        searchedUserArray =[userInfoArray mutableCopy];
    }
    
    [userTableView reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length != 0) {
        searchedUserArray = [NSMutableArray new];
        for (NSDictionary *oneUser in userInfoArray) {
            NSString *name = @"";
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
                name = [NSString stringWithFormat:@"%@ %@", [oneUser objectForKey:@"first_name"], [oneUser objectForKey:@"last_name"]];
            }else{
                name = [oneUser objectForKey:@"userFullName"];
            }
            if ([[name lowercaseString] rangeOfString:searchText.lowercaseString].location != NSNotFound) {
                [searchedUserArray addObject:oneUser];
            }
        }
    } else {
        [searchedUserArray removeAllObjects];
        searchedUserArray =[userInfoArray mutableCopy];
    }
    
    [userTableView reloadData];
}
- (IBAction)onGeneralRoon:(id)sender {
    if (selectedIndex == -1) {
        return;
    }
    [btnGeneralByAdmin setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
    [btnGeneralBanersByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnSupport setBackgroundColor:[UIColor clearColor]];
    [AppDelegate sharedDelegate].unreadGeneralCount = 0;
    lblGeneralChatBadgeCount.text = @"0";
    lblGeneralChatBadgeCount.hidden = YES;
    LiveChatViewController *controller = [[LiveChatViewController alloc] init];
    controller.abbreviationName =  @"A";
    controller.friendName = @"Admin";
    controller.isGeneralRoom = YES;
    controller.boardID = @999999;
    
    [AppDelegate sharedDelegate].liveChat_vc = controller;
    [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    selectedIndex = -1;
    
    [userTableView reloadData];
    [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
    [self markReadStatusGeneral];
}

- (IBAction)onGengeralBaners:(id)sender {
    if (selectedIndex == -2) {
        return;
    }
    [btnGeneralByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnGeneralBanersByAdmin setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
    [btnSupport setBackgroundColor:[UIColor clearColor]];
    LiveChatViewController *controller = [[LiveChatViewController alloc] init];
    controller.abbreviationName =  @"A";
    controller.friendName = @"Admin";
    controller.boardID = @99999;
    controller.isGeneralBanner = YES;
    
    [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    selectedIndex = -2;
    [userTableView reloadData];
}

- (IBAction)onSupport:(id)sender {
    if (selectedIndex == -3) {
        return;
    }
    [btnGeneralByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnGeneralBanersByAdmin setBackgroundColor:[UIColor clearColor]];
    [btnSupport setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
    LiveChatViewController *controller = [[LiveChatViewController alloc] init];
    controller.abbreviationName =  @"Support";
    controller.friendID = @"999999";
    controller.friendName = @"Support";
    controller.deviceToken = [AppDelegate sharedDelegate].deviceTokenOfSupport;
    [AppDelegate sharedDelegate].liveChat_vc = controller;
    
    [self to_showDetailViewController:[[UINavigationController alloc] initWithRootViewController:controller] sender:self];
    selectedIndex = -3;
    [userTableView reloadData];
    
    [self markReadStatusAllChatHistories:@999999];
}
@end
