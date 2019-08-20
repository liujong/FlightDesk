//
//  syncManagerNoUpload.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/22/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerNoUpload.h"
#import "Reachability.h"
#import "RecordsViewController.h"
#import "DocumentsViewController.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "Document+CoreDataClass.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "LogEntry+CoreDataClass.h"

#import "Student+CoreDataClass.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"

#define FOREGROUND_UPDATE_INTERVAL 60 // 1 minute (TODO: make this configurable)

@interface SyncManagerNoUpload ()
@property (strong, nonatomic) dispatch_source_t syncTimerForNoUpload;
@end
@implementation SyncManagerNoUpload
{
    // all DocumentInfo instances indexed by ID
    Reachability *serverReachability;
    BOOL isStarted;
}
- (id)initWithContext:(NSManagedObjectContext *)mainMOC
{
    
    self = [super init];
    if (self) {
        self.mainManagedObjectContext = mainMOC;
        
        // use reachability to check internet connection status
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *hostName = [serverName substringFromIndex:7];
        // remove "http://" prefix from string
        //FDLogDebug(@"testing server reachability for '%@'", hostName);
        serverReachability = [Reachability reachabilityWithHostName:hostName];
        [serverReachability startNotifier];
        
        // create timer for synchronizing with web service
        isStarted = NO;
        self.syncTimerForNoUpload = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForNoUpload) {
            dispatch_source_set_timer(self.syncTimerForNoUpload, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForNoUpload, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForNoUpload);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForNoUpload);
    dispatch_source_set_cancel_handler(self.syncTimerForNoUpload, ^{
        self.syncTimerForNoUpload = nil;
    });
    self.syncTimerForNoUpload = nil;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        [AppDelegate sharedDelegate].isStartPerformSyncCheck = YES;
        [AppDelegate sharedDelegate].currentSyncingIndex = -1;
        NSLog(@"*********************** START **************************");
        NetworkStatus netStatus = [serverReachability currentReachabilityStatus];
        if (netStatus == NotReachable) {
            FDLogError(@"Skipped sync check since server was unreachable!");
            isStarted = NO;
            [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
            return;
        }
        // make sure we are logged in
        NSString *userIDKey = @"userId";
        NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
        NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to perform sync until logged in!");
            isStarted = NO;
            [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
            return;
        }
        // grab URL for API
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        
        [[AppDelegate sharedDelegate] updateDeviceToken];
        [self getBadgeCountForCurrentUser:apiURLString andUserID:userID];
        [self performLessonsSyncCheck:apiURLString andUserID:userID];
    }
    
    
}
- (void)getBadgeCountForCurrentUser:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    
    NSURL *apiURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"getBadgeCount", @"action", userID, @"user_id", nil];
    NSError *error;
    NSData *jsonRequestData =[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRequestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getBadgeCountTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the navlogs update
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil) {
                    FDLogError(@"Unable to parse JSON for list!");
                    return;
                }
                
                if ([results objectForKey:@"success"]) {
                    id value = [results objectForKey:@"badges_users"];
                    if ([value isKindOfClass:[NSArray class]]) {
                        NSArray *badgesArray = value;
                        [[AppDelegate sharedDelegate].unreadData  removeAllObjects];
                        for (id badgesElement in badgesArray) {
                            if ([badgesElement isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *badgesDetails = badgesElement;
                                
                                NSMutableDictionary *dictToReplaceWithCount;
                                NSInteger indexToReplace = 0;
                                for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                                    NSDictionary *dict = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                                    if ([[dict objectForKey:@"userID"] integerValue] == [[badgesDetails objectForKey:@"userID"] integerValue]) {
                                        dictToReplaceWithCount = [dict mutableCopy];
                                        indexToReplace = i;
                                    }
                                }
                                
                                if (dictToReplaceWithCount) {
                                    NSInteger count = [[dictToReplaceWithCount objectForKey:@"unreadCount"] integerValue];
                                    [dictToReplaceWithCount setObject:@(count + 1) forKey:@"unreadCount"];
                                    [[AppDelegate sharedDelegate].unreadData replaceObjectAtIndex:indexToReplace withObject:dictToReplaceWithCount];
                                }else{
                                    
                                    NSMutableDictionary *dictToAddWithBadgesCountAndUserID = [[NSMutableDictionary alloc] init];
                                    [dictToAddWithBadgesCountAndUserID setObject:[badgesDetails objectForKey:@"userID"] forKey:@"userID"];
                                    NSInteger count = 0;
                                    [dictToAddWithBadgesCountAndUserID setObject:@(count + 1) forKey:@"unreadCount"];
                                    [[AppDelegate sharedDelegate].unreadData addObject:dictToAddWithBadgesCountAndUserID];
                                }
                                
                            }
                        }
                    }
                    
                    [AppDelegate sharedDelegate].unreadGeneralCount = [[results objectForKey:@"unread_general"] integerValue];
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
                }
            });
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to get BadgeCount: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to get BadgeCount due to unknown error!");
            }
        }
        
        [self getUsersActivityStatus:apiURLString andUserID:userID];
    }];
    [getBadgeCountTask resume];
}
- (void)getUsersActivityStatus:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if ([[AppDelegate sharedDelegate].isActivedUsersData count] == 0) {
        return;
    }
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLStr = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *apiURL = [NSURL URLWithString:apiURLStr];
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
    NSURLSessionDataTask *getUserStatusTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the navlogs update
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
                    if ([AppDelegate sharedDelegate].commsMain_vc != nil) {
                        [[AppDelegate sharedDelegate].commsMain_vc reloadTableViewWithPush];
                    }
                }
            });
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to get users Activity Status: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to get users Activity Status due to unknown error!");
            }
        }
        
        
    }];
    [getUserStatusTask resume];
}
- (void)performLessonsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([AppDelegate sharedDelegate].trainingHud != nil) {
            
            [AppDelegate sharedDelegate].trainingHud.label.text = [NSString stringWithFormat:@"Adding User to %@", [AppDelegate sharedDelegate].programName];
        }
    });
    
    
    
    
    FDLogDebug(@"performLessonsSyncCheck");
    // LESSONS
    // check if there are any lesson updates to download from the web service
    NSNumber *lastLessonsUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_lessons_update"];
    if (lastLessonsUpdate == nil) {
        lastLessonsUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *lessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:lessonsURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *lessonsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"lessons", @"action", userID, @"user_id", lastLessonsUpdate, @"last_update", type, @"user_type", nil];
    NSError *error;
    NSData *jsonLessonsRequestData =[NSJSONSerialization dataWithJSONObject:lessonsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonLessonsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonLessonsRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *lessonsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleLessonsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download lessons: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download lessons due to unknown error!");
            }
        }
        // request lesson records
        [self performLessonRecordsSyncCheck:apiURLString andUserID:userID];
    }];
    [lessonsTask resume];
}
- (void)handleLessonsUpdate:(NSData *)results
{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse lessons update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *lessonsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [lessonsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *lessonResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for lesson data: %@", error);
        return;
    }
    // last update time
    NSNumber *epoch_microseconds;
    id value = [lessonResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_lessons_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate* newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest lessons update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped lessons update with invalid last_update time!");
        return;
    }
    BOOL requireRepopulate = NO;
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        value = [lessonResults objectForKey:@"groups"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected groups element which was not an array!");
            return;
        }
        NSArray *lessonGroupArray = value;
        if ([self parseLessonGroupArray:lessonGroupArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        // lessons
        value = [lessonResults objectForKey:@"lessons"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected lessons element which was not an array!");
            return;
        }
        NSArray *lessonArray = value;
        if ([self parseLessonArray:lessonArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        // assignments
        value = [lessonResults objectForKey:@"assignments"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected assignment element which was not an array!");
            return;
        }
        NSArray *assignmentArray = value;
        if ([self parseAssignmentArray:assignmentArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        // content
        value = [lessonResults objectForKey:@"content"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected content element which was not an array!");
            return;
        }
        NSArray *contentArray = value;
        if ([self parseContentArray:contentArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
    }else {
        
        // students
        value = [lessonResults objectForKey:@"students"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected students element which was not an array!");
            return;
        }
        NSArray *studentsArray = value;
        if ([self parseStudentArray:studentsArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds] == YES) {
            requireRepopulate = YES;
        }
        // lesson groups (server always sends parent groups first!)
        //[self parseLessonGroups:lessonGroupArray];
        value = [lessonResults objectForKey:@"groups"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected groups element which was not an array!");
            return;
        }
        NSArray *lessonGroupArray = value;
        if ([self parseLessonGroupArray:lessonGroupArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        FDLogDebug(@"Group are updated");
        // lessons
        value = [lessonResults objectForKey:@"lessons"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected lessons element which was not an array!");
            return;
        }
        NSArray *lessonArray = value;
        if ([self parseLessonArray:lessonArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        FDLogDebug(@"Lessons are Updated");
        // assignments
        value = [lessonResults objectForKey:@"assignments"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected assignment element which was not an array!");
            return;
        }
        NSArray *assignmentArray = value;
        if ([self parseAssignmentArray:assignmentArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        FDLogDebug(@"Assignments are updated");
        // content
        value = [lessonResults objectForKey:@"content"];
        if ([value isKindOfClass:[NSArray class]] == NO) {
            FDLogError(@"Encountered unexpected content element which was not an array!");
            return;
        }
        NSArray *contentArray = value;
        if ([self parseContentArray:contentArray IntoContext:lessonsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
        FDLogDebug(@"Contents are updated");
    }
    
    //close refreshing with tableview
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AppDelegate sharedDelegate].records_vc endRefresh];
    });
    if ([lessonsManagedObjectContext hasChanges]) {
        [lessonsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL requireRepopulate = [[AppDelegate sharedDelegate].records_vc populateLessons];
            if (requireRepopulate == YES) {
                [[AppDelegate sharedDelegate].records_vc reloadData];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
}
- (BOOL)parseLessonGroupArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    // load lesson groups without parent groups
    
    [AppDelegate sharedDelegate].groupIdsStr = @"";
    for (id lessonGroupElement in array) {
        if ([lessonGroupElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected lesson group element which was not a dictionary!");
            continue;
        }
        NSDictionary *lessonGroupFields = lessonGroupElement;
        // TODO: add lastSync datetime
        NSNumber *studentUserID = [lessonGroupFields objectForKey:@"student_user_id"];
        NSNumber *groupID = [lessonGroupFields objectForKey:@"group_id"];
        FDLogDebug(@"group ID %@", groupID);
        NSNumber *parentGroupID = [lessonGroupFields objectForKey:@"parent_group_id"];
        NSString *groupName = [lessonGroupFields objectForKey:@"name"];
        
        //Admin
        NSNumber *ableByAdmin = nil;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            ableByAdmin = [lessonGroupFields objectForKey:@"ableByAdmin"];
        }
        
        NSNumber *instructor_id = [lessonGroupFields objectForKey:@"instructor_id"];
        NSString *instructor_email = [lessonGroupFields objectForKey:@"instructor_email"];
        NSString *instructor_name = [lessonGroupFields objectForKey:@"instructor_name"];
        NSString *instructor_pilot_cert = [lessonGroupFields objectForKey:@"instructor_pilot_cert"];
        NSString *instructor_cfi_cert_expdate = [lessonGroupFields objectForKey:@"instructor_cfi_cert_expdate"];
        NSString *instructor_device_token = [lessonGroupFields objectForKey:@"instructor_device_token"];
        NSNumber *instructor_badgeCount = [lessonGroupFields objectForKey:@"instructor_badgeCount"];
        NSNumber *updated_epoch_microseconds = [lessonGroupFields objectForKey:@"lesson_group_updated"];
        BOOL isLive = NO;
        if (![[lessonGroupFields objectForKey:@"group_live"] isKindOfClass:[NSNull class]]) {
            isLive = [[lessonGroupFields objectForKey:@"group_live"] boolValue];
        }
        BOOL isAccountLive = [[lessonGroupFields objectForKey:@"instructor_active"] boolValue];
        
        // studentUserID 0 is actually nil
        if ([studentUserID isEqual:[NSNull null]]) {
            studentUserID = userID;
        }
        // parentGroupID 0 is actually nil
        if ([parentGroupID isEqual:[NSNull null]]) {
            parentGroupID = nil;
            if ([[AppDelegate sharedDelegate].groupIdsStr isEqualToString:@""]) {
                [AppDelegate sharedDelegate].groupIdsStr = [NSString stringWithFormat:@"%ld", (long)[groupID integerValue]];
            }else{
                [AppDelegate sharedDelegate].groupIdsStr = [NSString stringWithFormat:@"%@,%ld", [AppDelegate sharedDelegate].groupIdsStr, (long)[groupID integerValue]];
            }
        }
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@ AND studentUserID == %@", groupID, studentUserID];
        [request setPredicate:predicate];
        NSArray *fetchedLessonGroups = [context executeFetchRequest:request error:&error];
        LessonGroup *lessonGroup = nil;
        if (fetchedLessonGroups == nil) {
            FDLogError(@"Skipped lesson group update since there was an error checking for existing lessons!");
        } else if (fetchedLessonGroups.count == 0) {
            // insert the new group
            //FDLogDebug(@"Adding new lesson group ID %@ (%@)", groupID, groupName);
            lessonGroup = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:context];
            lessonGroup.groupID = groupID;
            lessonGroup.name = groupName;
            lessonGroup.ableByAdmin = ableByAdmin;
            lessonGroup.lastUpdate = updated_epoch_microseconds;
            lessonGroup.instructorID = instructor_id;
            lessonGroup.instructorEmail = instructor_email;
            lessonGroup.instructorName = instructor_name;
            lessonGroup.instructorPilotCert = instructor_pilot_cert;
            lessonGroup.instructorCfiCertExpDate = instructor_cfi_cert_expdate;
            lessonGroup.instructorDeviceToken = instructor_device_token;
            lessonGroup.instructorBadgeCount = instructor_badgeCount;
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]) {
                if (isLive) {
                    lessonGroup.isShown = @YES;
                }else{
                    lessonGroup.isShown = @NO;
                }
            }else{
                lessonGroup.isShown = @YES;
            }
            
            if (isAccountLive) {
                lessonGroup.is_active = @YES;
            }else {
                lessonGroup.is_active = @NO;
            }
            
            // check if this is assigned to a student
            lessonGroup.studentUserID = studentUserID;
            // check if there's a parent group
            if (parentGroupID != nil) {
                [self assignParentGroupWithID:parentGroupID AndStudentID:studentUserID toGroup:lessonGroup WithContext:context];
            } else if (parentGroupID == nil && [studentUserID intValue] != [userID intValue]) {
                [self assignGroupToStudentWithID:studentUserID toGroup:lessonGroup WithContext:context];
            }
            requireRepopulate = YES;
        } else if (fetchedLessonGroups.count == 1) {
            // check if the group has been updated
            lessonGroup = [fetchedLessonGroups objectAtIndex:0];
            //if ([lessonGroup.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue] || ![lessonGroup.instructorEmail isEqualToString:instructor_email]) {
            // update the existing lesson group with the new values
            lessonGroup.name = groupName;
            lessonGroup.ableByAdmin = ableByAdmin;
            lessonGroup.lastUpdate = updated_epoch_microseconds;
            // NOTE: a lesson group's student should NEVER change!!!
            requireRepopulate = YES;
            lessonGroup.instructorID = instructor_id;
            lessonGroup.instructorEmail = instructor_email;
            lessonGroup.instructorName = instructor_name;
            lessonGroup.instructorPilotCert = instructor_pilot_cert;
            lessonGroup.instructorCfiCertExpDate = instructor_cfi_cert_expdate;
            lessonGroup.instructorDeviceToken = instructor_device_token;
            lessonGroup.instructorBadgeCount = instructor_badgeCount;
            
            if (isAccountLive) {
                lessonGroup.is_active = @YES;
            }else {
                lessonGroup.is_active = @NO;
            }
            
            //}
        } else if (fetchedLessonGroups.count > 1) {
            FDLogError(@"An unexpected error occurred: there were multiple groups found with the same ID (%@: %@), attempting to recover!", groupID, groupName);
            // delete all of the existing lesson groups with this ID (should be 1)
            // (data model will delete all associated sub-groups, lessons, etc..)
            for (LessonGroup *groupToDelete in fetchedLessonGroups) {
                [context deleteObject:groupToDelete];
            }
            // re-insert group
            //FDLogDebug(@"Recovering new lesson group ID %@ (%@)", groupID, groupName);
            lessonGroup = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:context];
            lessonGroup.groupID = groupID;
            lessonGroup.name = groupName;
            lessonGroup.ableByAdmin = ableByAdmin;
            lessonGroup.lastUpdate = updated_epoch_microseconds;
            // check if this is assigned to a student
            lessonGroup.studentUserID = studentUserID;
            lessonGroup.instructorID = instructor_id;
            lessonGroup.instructorEmail = instructor_email;
            lessonGroup.instructorName = instructor_name;
            lessonGroup.instructorPilotCert = instructor_pilot_cert;
            lessonGroup.instructorCfiCertExpDate = instructor_cfi_cert_expdate;
            lessonGroup.instructorDeviceToken = instructor_device_token;
            lessonGroup.instructorBadgeCount = instructor_badgeCount;
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]) {
                if (isLive) {
                    lessonGroup.isShown = @YES;
                }else{
                    lessonGroup.isShown = @NO;
                }
            }else{
                lessonGroup.isShown = @YES;
            }
            
            if (isAccountLive) {
                lessonGroup.is_active = @YES;
            }else {
                lessonGroup.is_active = @NO;
            }
            
            // check if there's a parent group
            if (parentGroupID != nil) {
                [self assignParentGroupWithID:parentGroupID AndStudentID:studentUserID toGroup:lessonGroup WithContext:context];
            } else if (parentGroupID == nil && studentUserID != nil) {
                [self assignGroupToStudentWithID:studentUserID toGroup:lessonGroup WithContext:context];
            }
            requireRepopulate = YES;
        }
        if (lessonGroup != nil) {
            lessonGroup.lastSync = epochMicros;
        }
    }
    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
    NSLog(@"%@", [AppDelegate sharedDelegate].groupIdsStr);
    // loop through lesson groups, delete any that have not been synced
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredLessonGroups = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredLessonGroups != nil && expiredLessonGroups.count > 0) {
        for (LessonGroup *groupToDelete in expiredLessonGroups) {
            [context deleteObject:groupToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)assignParentGroupWithID:(NSNumber *)parentGroupID AndStudentID:(NSNumber *)studentUserID toGroup:(LessonGroup *)lessonGroup WithContext:(NSManagedObjectContext *)context
{
    NSError *error;
    // assign the correct parent group
    NSFetchRequest *parentRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *parentEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    [parentRequest setEntity:parentEntityDescription];
    NSPredicate *parentPredicate = [NSPredicate predicateWithFormat:@"groupID = %@ AND studentUserID = %@", parentGroupID, studentUserID];
    [parentRequest setPredicate:parentPredicate];
    NSArray *fetchedParentGroup = [context executeFetchRequest:parentRequest error:&error];
    if (fetchedParentGroup.count == 1) {
        lessonGroup.parentGroup = [fetchedParentGroup objectAtIndex:0];
        lessonGroup.indentation = [NSNumber numberWithInt:[lessonGroup.parentGroup.indentation intValue] + 2];
    } else {
        // there was an error (either the parent ground didn't exist or there were multiple groups with the parent group's ID)
        FDLogError(@"Unable to set parent group (%@) for lesson group '%@' (%@)", parentGroupID, lessonGroup.name, lessonGroup.groupID);
    }
}
- (void)assignGroupToStudentWithID:(NSNumber *)studentUserID toGroup:(LessonGroup *)lessonGroup WithContext:(NSManagedObjectContext *)context
{
    NSError *error;
    // assign the correct parent group
    NSFetchRequest *studentRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *studentEntityDescription = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
    [studentRequest setEntity:studentEntityDescription];
    NSPredicate *studentPredicate = [NSPredicate predicateWithFormat:@"userID = %@", studentUserID];
    [studentRequest setPredicate:studentPredicate];
    NSArray *fetchedStudent = [context executeFetchRequest:studentRequest error:&error];
    if (fetchedStudent.count == 1) {
        lessonGroup.student = [fetchedStudent objectAtIndex:0];
        lessonGroup.indentation = [NSNumber numberWithInt:2];
    } else {
        // there was an error (either the parent ground didn't exist or there were multiple groups with the parent group's ID)
        FDLogError(@"Unable to set student (%@) for lesson group '%@' (%@)", studentUserID, lessonGroup.name, lessonGroup.groupID);
    }
}
- (BOOL)parseLessonArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id lessonElement in array) {
        if ([lessonElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *lessonFields = lessonElement;
            NSNumber *studentUserID = [lessonFields objectForKey:@"student_user_id"];
            NSNumber *lessonID = [lessonFields objectForKey:@"lesson_id"];
            NSNumber *lesson_local_id = [lessonFields objectForKey:@"lesson_local_id"];
            NSNumber *groupID = [lessonFields objectForKey:@"group_id"];
            NSString *lessonName = [lessonFields objectForKey:@"lesson_name"];
            NSString *lessonTitle = [lessonFields objectForKey:@"lesson_title"];
            NSNumber *lessonNumber = [lessonFields objectForKey:@"lesson_number"];
            NSString *minGround = [lessonFields objectForKey:@"min_ground"];
            NSString *minInstrument = [lessonFields objectForKey:@"min_instrument"];
            NSString *minDual = [lessonFields objectForKey:@"min_dual"];
            NSString *minSolo = [lessonFields objectForKey:@"min_solo"];
            NSString *groundDescription = [lessonFields objectForKey:@"ground_description"];
            NSString *groundObjective = [lessonFields objectForKey:@"ground_objective"];
            NSString *groundCompletionStds = [lessonFields objectForKey:@"ground_completion_stds"];
            NSString *flightDescription = [lessonFields objectForKey:@"flight_description"];
            NSString *flightObjective = [lessonFields objectForKey:@"flight_objective"];
            NSString *flightCompletionStds = [lessonFields objectForKey:@"flight_completion_stds"];
            NSNumber *updated_epoch_microseconds = [lessonFields objectForKey:@"lesson_updated"];
            // studentUserID 0 is actually nil/NULL/current user ID
            if ([studentUserID isEqual:[NSNull null]]) {
                studentUserID = userID;
            }
            //FDLogDebug(@"loaded lesson: id=%@, group_id=%@, name=%@, updated=%@", lessonID, groupID, lessonName, updated_epoch_microseconds);
            // check to see if this lesson needs to be saved
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonID = %@ AND studentUserID = %@", lessonID, studentUserID];
            [request setPredicate:predicate];
            NSArray *fetchedLessons = [context executeFetchRequest:request error:&error];
            Lesson *lesson = nil;
            if (fetchedLessons == nil) {
                FDLogError(@"Skipped lesson update since there was an error checking for existing lessons!");
            } else if (fetchedLessons.count == 0) {
                // insert a new lesson
                lesson = [self updateOrInsertLesson:nil InContext:context WithStudentUserID:studentUserID WithLessonID:lessonID GroupID:groupID LessonName:lessonName LessonTitle:lessonTitle LessonNumber:lessonNumber MinGround:minGround MinInstrument:minInstrument MinDual:minDual MinSolo:minSolo GroundDescription:groundDescription GroundObjective:groundObjective GroundCompletionStds:groundCompletionStds FlightDescription:flightDescription FlightObjective:flightObjective FlightCompletionStds:flightCompletionStds Updated:updated_epoch_microseconds lessonLocalID:lesson_local_id];
                requireRepopulate = YES;
            } else if (fetchedLessons.count == 1) {
                // update an existing lesson
                if ([lesson.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue]) {
                    lesson = [fetchedLessons objectAtIndex:0];
                    lesson = [self updateOrInsertLesson:lesson InContext:context WithStudentUserID:studentUserID WithLessonID:lessonID GroupID:groupID LessonName:lessonName  LessonTitle:lessonTitle LessonNumber:lessonNumber  MinGround:minGround MinInstrument:minInstrument MinDual:minDual MinSolo:minSolo GroundDescription:groundDescription GroundObjective:groundObjective GroundCompletionStds:groundCompletionStds FlightDescription:flightDescription FlightObjective:flightObjective FlightCompletionStds:flightCompletionStds Updated:updated_epoch_microseconds lessonLocalID:lesson_local_id];
                    requireRepopulate = YES;
                }
            } else {
                FDLogError(@"An unexpected error occurred: there were multiple lessons found with the same ID (%@: %@), attempting to recover!", lessonID, lessonName);
                // delete all of the existing lesson groups with this ID (should be 1)
                // (data model will delete all associated sub-groups, lessons, etc..)
                for (Lesson *lessonToDelete in fetchedLessons) {
                    [context deleteObject:lessonToDelete];
                }
                // re-insert lesson
                lesson = [self updateOrInsertLesson:nil InContext:context WithStudentUserID:studentUserID WithLessonID:lessonID GroupID:groupID LessonName:lessonName LessonTitle:lessonTitle LessonNumber:lessonNumber  MinGround:minGround MinInstrument:minInstrument MinDual:minDual MinSolo:minSolo GroundDescription:groundDescription GroundObjective:groundObjective GroundCompletionStds:groundCompletionStds FlightDescription:flightDescription FlightObjective:flightObjective FlightCompletionStds:flightCompletionStds Updated:updated_epoch_microseconds lessonLocalID:lesson_local_id];
                requireRepopulate = YES;
            }
            if (lesson != nil) {
                lesson.lastSync = epochMicros;
            }
        }
    }
    NSFetchRequest *expiredLessonRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *expiredEntityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
    [expiredLessonRequest setEntity:expiredEntityDescription];
    NSPredicate *expiredPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredLessonRequest setPredicate:expiredPredicate];
    NSArray *expiredLessons = [context executeFetchRequest:expiredLessonRequest error:&error];
    //FDLogDebug(@"Checking for expired lessons...");
    if (expiredLessons != nil && expiredLessons.count > 0) {
        //FDLogDebug(@"At least one lesson appears to be expired!");
        for (Lesson *lessonToDelete in expiredLessons) {
            //FDLogDebug(@"Deleting expired lesson '%@' with ID %@", lessonToDelete.name, lessonToDelete.lessonID);
            [context deleteObject:lessonToDelete];
        }
        // force a context save
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (Lesson *)updateOrInsertLesson:(Lesson *)lesson InContext:(NSManagedObjectContext *)context WithStudentUserID:(NSNumber *)studentUserID WithLessonID:(NSNumber *)lessonID GroupID:(NSNumber *)groupID LessonName:(NSString *)lessonName LessonTitle:(NSString *)lessonTitle LessonNumber:(NSNumber *)lessonNumber MinGround:(NSString *)minGround MinInstrument:(NSString *)minInstrument MinDual:(NSString *)minDual MinSolo:(NSString *)minSolo GroundDescription:(NSString *)groundDescription GroundObjective:(NSString *)groundObjective GroundCompletionStds:(NSString *)groundCompletionStds FlightDescription:(NSString *)flightDescription FlightObjective:(NSString *)flightObjective FlightCompletionStds:(NSString *)flightCompletionStds Updated:(NSNumber *)epochMicros lessonLocalID:(NSNumber *)lessonLocalId
{
    NSError *error;
    if (lesson == nil) {
        // add new lesson
        //FDLogDebug(@"Adding new lesson ID %@", lessonID);
        lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:context];
    }
    lesson.lessonID = lessonID;
    lesson.lesson_local_id = lessonLocalId;
    lesson.name = lessonName;
    lesson.title = lessonTitle;
    lesson.minGround = minGround;
    lesson.minInstrument = minInstrument;
    lesson.minDual = minDual;
    lesson.minSolo = minSolo;
    lesson.groundDescription = groundDescription;
    lesson.groundObjective = groundObjective;
    lesson.groundCompletionStds = groundCompletionStds;
    lesson.flightDescription = flightDescription;
    lesson.flightObjective = flightObjective;
    lesson.flightCompletionStds = flightCompletionStds;
    lesson.lastUpdate = epochMicros;
    lesson.studentUserID = studentUserID;
    lesson.lessonNumber = lessonNumber;
    if (lesson.lessonGroup == nil || (lesson.lessonGroup != nil && [lesson.lessonGroup.groupID longValue] != [groupID longValue])) {
        // lookup group and add this lesson
        NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        [groupRequest setEntity:groupEntityDescription];
        NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"groupID = %@ AND studentUserID = %@", groupID, studentUserID];
        [groupRequest setPredicate:groupPredicate];
        NSArray *fetchedGroups = [context executeFetchRequest:groupRequest error:&error];
        LessonGroup *group = nil;
        if (fetchedGroups == nil) {
            FDLogError(@"Unable to retrieve group with ID %@ and studentUserID %@!", groupID, studentUserID);
        } else if (fetchedGroups.count == 0) {
            FDLogError(@"LessonID %@ owner group with ID %@ and studentUserID %@ not found", lessonID, groupID, studentUserID);
        } else if (fetchedGroups.count == 1) {
            group = [fetchedGroups objectAtIndex:0];
            lesson.lessonGroup = group;
            lesson.indentation = [NSNumber numberWithInt:[lesson.lessonGroup.indentation intValue] + 2];
        } else {
            FDLogError(@"More than one group with ID %@ for ownership of lesson with ID %@ and studentUserID %@", groupID, lessonID, studentUserID);
        }
    }
    return lesson;
}
- (BOOL)parseAssignmentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id assignmentElement in array) {
        if ([assignmentElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *assignmentFields = assignmentElement;
            NSNumber *studentUserID = [assignmentFields objectForKey:@"student_user_id"];
            NSNumber *assignmentID = [assignmentFields objectForKey:@"assignment_id"];
            NSNumber *assignment_local_id = [assignmentFields objectForKey:@"assignment_local_id"];
            NSNumber *lessonID = [assignmentFields objectForKey:@"lesson_id"];
            NSNumber *groundOrFlight = [assignmentFields objectForKey:@"ground_or_flight"];
            NSString *referenceID = [assignmentFields objectForKey:@"reference_id"];
            NSString *title = [assignmentFields objectForKey:@"title"];
            NSString *chapters = [assignmentFields objectForKey:@"chapters"];
            if ([studentUserID isEqual:[NSNull null]]) {
                studentUserID = userID;
            }
            //FDLogDebug(@"loaded assignment: id=%@, lesson_id=%@, title=%@", assignmentID, lessonID, title);
            // check to see if this lesson needs to be saved
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Assignment" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"assignmentID = %@ AND studentUserID = %@", assignmentID, studentUserID];
            [request setPredicate:predicate];
            NSArray *fetchedAssignments = [context executeFetchRequest:request error:&error];
            Assignment *assignment = nil;
            if (fetchedAssignments == nil) {
                FDLogError(@"Unable to retrieve assignment with ID %@!", assignmentID);
            } else if (fetchedAssignments.count == 0) {
                assignment = [NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:context];
                assignment.assignmentID = assignmentID;
                assignment.assignment_local_id = assignment_local_id;
                assignment.groundOrFlight = groundOrFlight;
                assignment.referenceID = referenceID;
                assignment.title = title;
                assignment.chapters = chapters;
                assignment.studentUserID = studentUserID;
                requireRepopulate = YES;
            } else if (fetchedAssignments.count == 1) {
                assignment = [fetchedAssignments objectAtIndex:0];
                if ([assignment.groundOrFlight isEqual:groundOrFlight] == NO || [assignment.referenceID isEqual:referenceID] == NO || [assignment.title isEqual:title] == NO || [assignment.chapters isEqual:chapters] == NO) {
                    assignment.groundOrFlight = groundOrFlight;
                    assignment.referenceID = referenceID;
                    assignment.title = title;
                    assignment.chapters = chapters;
                    assignment.studentUserID = studentUserID;
                    requireRepopulate = YES;
                }
            } else {
                FDLogError(@"An unexpected error occurred: there were multiple assignments found with the same ID (%@: %@), attempting to recover!", assignmentID, title);
                // delete all of the existing lesson groups with this ID (should be 1)
                // (data model will delete all associated sub-groups, lessons, etc..)
                for (Assignment *assignmentToDelete in fetchedAssignments) {
                    [context deleteObject:assignmentToDelete];
                }
                // re-insert lesson
                assignment = [NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:context];
                assignment.assignmentID = assignmentID;
                assignment.groundOrFlight = groundOrFlight;
                assignment.referenceID = referenceID;
                assignment.title = title;
                assignment.assignment_local_id = assignment_local_id;
                assignment.chapters = chapters;
                assignment.studentUserID = studentUserID;
                requireRepopulate = YES;
            }
            if (assignment.lesson == nil || (assignment.lesson != nil && [assignment.lesson.lessonID longValue] != [lessonID longValue])) {
                // lookup lesson and add this assignment
                NSFetchRequest *lessonRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *lessonEntityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
                [lessonRequest setEntity:lessonEntityDescription];
                NSPredicate *lessonPredicate = [NSPredicate predicateWithFormat:@"lessonID = %@ AND studentUserID = %@", lessonID, studentUserID];
                [lessonRequest setPredicate:lessonPredicate];
                NSArray *fetchedLessons = [context executeFetchRequest:lessonRequest error:&error];
                Lesson *lesson = nil;
                if (fetchedLessons == nil) {
                    FDLogError(@"Unable to retrieve lesson with ID %@ and student ID %@!", lessonID, studentUserID);
                } else if (fetchedLessons.count == 0) {
                    FDLogError(@"LessonID %@ for assignment with ID %@ and student ID %@ not found", lessonID, assignmentID, studentUserID);
                } else if (fetchedLessons.count == 1) {
                    lesson = [fetchedLessons objectAtIndex:0];
                    assignment.lesson = lesson;
                } else {
                    FDLogError(@"More than one lesson with ID %@ for assignment with ID %@ and student ID %@", lessonID, assignmentID, studentUserID);
                }
            }
        }
    }
    return requireRepopulate;
}
- (BOOL)parseContentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id contentElement in array) {
        if ([contentElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *contentFields = contentElement;
            NSNumber *studentUserID = [contentFields objectForKey:@"student_user_id"];
            NSNumber *contentID = [contentFields objectForKey:@"content_id"];
            NSNumber *content_local_id = [contentFields objectForKey:@"content_local_id"];
            NSNumber *depth = [contentFields objectForKey:@"depth"];
            NSNumber *lessonID = [contentFields objectForKey:@"lesson_id"];
            NSNumber *orderNumber = [contentFields objectForKey:@"order_number"];
            NSNumber *groundOrFlight = [contentFields objectForKey:@"ground_or_flight"];
            NSNumber *hasRemarks = [contentFields objectForKey:@"has_remarks"];
            NSNumber *hasCheck = [contentFields objectForKey:@"has_check"];
            NSString *name = [contentFields objectForKey:@"content_name"];
            if ([studentUserID isEqual:[NSNull null]]) {
                studentUserID = userID;
            }
            // check if this content already exists
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Content" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contentID = %@ AND studentUserID = %@", contentID, studentUserID];
            [request setPredicate:predicate];
            NSArray *fetchedContent = [context executeFetchRequest:request error:&error];
            Content *content = nil;
            if (fetchedContent == nil) {
                FDLogError(@"Unable to retrieve content with ID %@!", contentID);
            } else if (fetchedContent.count == 0) {
                content = [NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:context];
                content.contentID = contentID;
                content.content_local_id = content_local_id;
                content.orderNumber = orderNumber;
                content.groundOrFlight = groundOrFlight;
                content.hasRemarks = hasRemarks;
                content.hasCheck = hasCheck;
                content.name = name;
                content.studentUserID = studentUserID;
                content.depth = depth;
                //FDLogDebug(@"added content: content_id=%@,lesson_id=%@,order_number=%@,ground_or_flight=%@,parent_content_id=%@,has_remarks=%@,has_check=%@,content_name=%@", contentID, lessonID, orderNumber, groundOrFlight, parentContentID, hasRemarks, hasCheck, name);
                requireRepopulate = YES;
            } else if (fetchedContent.count == 1) {
                content = [fetchedContent objectAtIndex:0];
                if ([content.orderNumber isEqual:orderNumber] == NO || [content.groundOrFlight isEqual:groundOrFlight] == NO || [content.hasRemarks isEqual:hasRemarks] == NO || [content.hasCheck isEqual:hasCheck] == NO ||
                    [content.name isEqual:name] == NO) {
                    content.orderNumber = orderNumber;
                    content.groundOrFlight = groundOrFlight;
                    content.hasRemarks = hasRemarks;
                    content.hasCheck = hasCheck;
                    content.name = name;
                    content.studentUserID = studentUserID;
                    content.depth = depth;
                    //FDLogDebug(@"updated content: content_id=%@,lesson_id=%@,order_number=%@,ground_or_flight=%@,parent_content_id=%@,has_remarks=%@,has_check=%@,content_name=%@", contentID, lessonID, orderNumber, groundOrFlight, parentContentID, hasRemarks, hasCheck, name);
                    requireRepopulate = YES;
                }
            } else {
                FDLogError(@"An unexpected error occurred: there were multiple content found with the same ID (%@: %@), attempting to recover!", contentID, name);
                // delete all of the existing lesson groups with this ID (should be 1)
                // (data model will delete all associated sub-groups, lessons, etc..)
                for (Content *contentToDelete in fetchedContent) {
                    [context deleteObject:contentToDelete];
                }
                // re-insert lesson
                content = [NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:context];
                content.contentID = contentID;
                content.orderNumber = orderNumber;
                content.groundOrFlight = groundOrFlight;
                content.hasRemarks = hasRemarks;
                content.hasCheck = hasCheck;
                content.name = name;
                content.content_local_id = content_local_id;
                content.studentUserID = studentUserID;
                content.depth = depth;
                requireRepopulate = YES;
            }
            // determine if this is going to be added to a parent lesson or a parent content
            
            // find the parent lesson
            NSFetchRequest *lessonRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *lessonEntityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
            [lessonRequest setEntity:lessonEntityDescription];
            NSPredicate *lessonPredicate = [NSPredicate predicateWithFormat:@"lessonID = %@ AND studentUserID = %@", lessonID, studentUserID];
            [lessonRequest setPredicate:lessonPredicate];
            NSArray *fetchedLessons = [context executeFetchRequest:lessonRequest error:&error];
            Lesson *lesson = nil;
            if (fetchedLessons == nil) {
                FDLogError(@"Unable to retrieve lesson with ID %@ and student ID %@!", lessonID, studentUserID);
            } else if (fetchedLessons.count == 0) {
                FDLogError(@"LessonID %@ for content with ID %@ and student ID %@ not found", lessonID, contentID, studentUserID);
            } else if (fetchedLessons.count == 1) {
                lesson = [fetchedLessons objectAtIndex:0];
                content.lesson = lesson;
            } else {
                FDLogError(@"More than one lesson with ID %@ for content with ID %@", lessonID, contentID);
            }
        }
    }
    return requireRepopulate;
}
- (BOOL)parseStudentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    BOOL requireRepopulate = NO;
    NSError *error;
    // load lesson groups without parent groups
    for (id studentElement in array) {
        if ([studentElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected lesson group element which was not a dictionary!");
            continue;
        }
        NSDictionary *studentElementFields = studentElement;
        // TODO: add lastSync datetime
        NSNumber *studentUserID = [studentElementFields objectForKey:@"student_user_id"];
        NSString *username = [studentElementFields objectForKey:@"username"];
        NSString *firstName = [studentElementFields objectForKey:@"first_name"];
        NSString *lastName = [studentElementFields objectForKey:@"last_name"];
        NSNumber *updated_epoch_microseconds = [studentElementFields objectForKey:@"student_updated"];
        NSString *studentEmail = [studentElementFields objectForKey:@"student_email"];
        NSString *studentDeviceToken = [studentElementFields objectForKey:@"student_device_token"];
        NSNumber *badgeCountOfStudent = [studentElementFields objectForKey:@"badgeCount"];
        
        BOOL isAccountLive = [[studentElementFields objectForKey:@"is_active"] boolValue];
        
        // check to see if existing version of this student needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", studentUserID];
        [request setPredicate:predicate];
        NSArray *fetchedStudents = [context executeFetchRequest:request error:&error];
        Student *student = nil;
        if (fetchedStudents == nil) {
            FDLogError(@"Skipped student update since there was an error checking for existing students!");
        } else if (fetchedStudents.count == 0) {
            // insert the new student
            //FDLogDebug(@"Adding new student with user ID %@ (%@)", studentUserID, username);
            student = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:context];
            student.userID = studentUserID;
            student.username = username;
            student.firstName = firstName;
            student.lastName = lastName;
            student.expanded = 0;
            student.lastUpdate = updated_epoch_microseconds;
            student.studentEmail = studentEmail;
            student.deviceToken = studentDeviceToken;
            student.badgeCount = badgeCountOfStudent;
            if (isAccountLive) {
                student.is_active = @YES;
            }else {
                student.is_active = @NO;
            }
            
            requireRepopulate = YES;
        } else if (fetchedStudents.count == 1) {
            // check if the group has been updated
            student = [fetchedStudents objectAtIndex:0];
            //if ([student.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue]) {
            // update the existing lesson group with the new values
            student.username = username;
            student.firstName = firstName;
            student.lastName = lastName;
            student.lastUpdate = updated_epoch_microseconds;
            student.studentEmail = studentEmail;
            student.deviceToken = studentDeviceToken;
            student.badgeCount = badgeCountOfStudent;
            if (isAccountLive) {
                student.is_active = @YES;
            }else {
                student.is_active = @NO;
            }
            requireRepopulate = YES;
            //}
        } else if (fetchedStudents.count > 1) {
            FDLogError(@"An unexpected error occurred: there were multiple groups found with the same ID (%@: %@), attempting to recover!", studentUserID, username);
            // delete all of the existing lesson groups with this ID (should be 1)
            // (data model will delete all associated sub-groups, lessons, etc..)
            for (Student *studentToDelete in fetchedStudents) {
                [context deleteObject:studentToDelete];
            }
            // re-insert group
            //FDLogDebug(@"Recovering new lesson group ID %@ (%@)", groupID, groupName);
            student = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:context];
            student.userID = studentUserID;
            student.username = username;
            student.firstName = firstName;
            student.lastName = lastName;
            student.expanded = 0;
            student.lastUpdate = updated_epoch_microseconds;
            student.studentEmail = studentEmail;
            student.deviceToken = studentDeviceToken;
            student.badgeCount = badgeCountOfStudent;
            if (isAccountLive) {
                student.is_active = @YES;
            }else {
                student.is_active = @NO;
            }
            requireRepopulate = YES;
        }
        if (student != nil) {
            student.lastSync = epochMicros;
        }
    }
    // loop through lesson groups, delete any that have not been synced
    NSFetchRequest *expiredStudentRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
    [expiredStudentRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredStudentRequest setPredicate:predicate];
    NSArray *expiredStudents = [context executeFetchRequest:expiredStudentRequest error:&error];
    if (expiredStudents != nil && expiredStudents.count > 0) {
        for (Student *studentToDelete in expiredStudents) {
            [context deleteObject:studentToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}

- (void)performLessonRecordsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performLessonRecordsSyncCheck");
    // LESSON RECORDS
    // check for lessons records and content records
    NSNumber *lastLessonRecordsUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_lesson_records_update"];
    if (lastLessonRecordsUpdate == nil) {
        lastLessonRecordsUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *lessonRecordsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:lessonRecordsURL];
    NSDictionary *lessonRecordsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"lesson_records", @"action", userID, @"user_id", lastLessonRecordsUpdate, @"last_update", nil];
    NSError *error;
    NSData *jsonLessonRecordsRequestData =[NSJSONSerialization dataWithJSONObject:lessonRecordsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonLessonRecordsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonLessonRecordsRequestData];
    //NSString *jsonRecordsStrData = [[NSString alloc] initWithData:jsonLessonRecordsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lesson records update! JSON '%@'", jsonRecordsStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *lessonRecordsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleLessonRecordsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download lesson records: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download lesson records due to unknown error!");
            }
        }
        // request log entries
        [self performLogEntriesSyncCheck:apiURLString andUserID:userID];
    }];
    [lessonRecordsTask resume];
}
- (void)handleLessonRecordsUpdate:(NSData *)results
{
    // get a child managed object context
    NSManagedObjectContext *lessonRecordsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [lessonRecordsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // output the query results for debug
    //NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"LessonRecords update JSON '%@'", jsonStrData);
    // parse the query results
    NSDictionary *lessonResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for lesson data: %@", error);
        return;
    }
    // last update time
    NSNumber *epoch_microseconds;
    id value = [lessonResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_lesson_records_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate* newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest lessons records update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped lessons update with invalid last_update time!");
        return;
    }
    // lesson records
    value = [lessonResults objectForKey:@"lesson_records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected lesson records element which was not an array!");
        return;
    }
    NSArray *lessonRecordArray = value;
    if ([self parseLessonRecordArray:lessonRecordArray IntoContext:lessonRecordsManagedObjectContext WithSync:epoch_microseconds])
    {
        if ([lessonRecordsManagedObjectContext hasChanges]) {
            [lessonRecordsManagedObjectContext save:&error];
            // TODO: in the future we may have to notify the UI of new/updated LessonRecords!
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
        }
    }
    
    NSFetchRequest *expiredLessonRecordRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *expiredLessonRecordsEntityDescription = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:lessonRecordsManagedObjectContext];
    [expiredLessonRecordRequest setEntity:expiredLessonRecordsEntityDescription];
    NSPredicate *expiredDocumentPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epoch_microseconds];
    [expiredLessonRecordRequest setPredicate:expiredDocumentPredicate];
    NSArray *expiredLessonRecordsArray = [lessonRecordsManagedObjectContext executeFetchRequest:expiredLessonRecordRequest error:&error];
    for (LessonRecord *lessonRecordsToDelete in expiredLessonRecordsArray) {
        [lessonRecordsManagedObjectContext deleteObject:lessonRecordsToDelete];
    }
    
    if ([lessonRecordsManagedObjectContext hasChanges]) {
        [lessonRecordsManagedObjectContext save:&error];
        // TODO: in the future we may have to notify the UI of new/updated LessonRecords!
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
    }
}
- (BOOL)parseLessonRecordArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id lessonRecordElement in array) {
        if ([lessonRecordElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *lessonRecordFields = lessonRecordElement;
            NSNumber *lessonRecordID = [lessonRecordFields objectForKey:@"record_id"];
            NSNumber *userID = [lessonRecordFields objectForKey:@"user_id"];
            NSNumber *lessonID = [lessonRecordFields objectForKey:@"lesson_id"];
            // parse lesson date from string
            NSString *lessonDateString = [lessonRecordFields objectForKey:@"lesson_date"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSDate *lessonDate = [formatter dateFromString:lessonDateString];
            NSNumber *instructorID = [lessonRecordFields objectForKey:@"instructor_id"];
            NSString *groundNotes = [lessonRecordFields objectForKey:@"ground_notes"];
            NSString *groundCompleted = [lessonRecordFields objectForKey:@"ground_completed"];
            NSString *flightNotes = [lessonRecordFields objectForKey:@"flight_notes"];
            NSString *flightCompleted = [lessonRecordFields objectForKey:@"flight_completed"];
            NSNumber *updated_epoch_microseconds = [lessonRecordFields objectForKey:@"lesson_record_updated"];
            NSArray *content_records = [lessonRecordFields objectForKey:@"content_records"];
            //FDLogDebug(@"loaded lesson record: id=%@, lesson_id=%@, ground_notes=%@, flight_notes=%@, updated=%@", lessonRecordID, lessonID, groundNotes, flightNotes, updated_epoch_microseconds);
            // check to see if this lesson needs to be saved
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            // WHY DOESNT THIS WORK?*******************
            //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordID = %@ AND userID = %@", lessonRecordID, userID];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordID == %@", lessonRecordID];
            [request setPredicate:predicate];
            NSArray *fetchedLessonRecords = [context executeFetchRequest:request error:&error];
            LessonRecord *lessonRecord = nil;
            if (fetchedLessonRecords == nil) {
                FDLogError(@"Skipped lesson record update since there was an error checking for existing lessons!");
            } else if (fetchedLessonRecords.count == 0) {
                // insert a new lesson
                lessonRecord = [self updateOrInsertLessonRecord:nil InContext:context WithLessonRecordID:lessonRecordID UserID:userID LessonID:lessonID LessonDate:lessonDate InstructorID:instructorID GroundNotes:groundNotes GroundCompleted:groundCompleted FlightNotes:flightNotes FlightCompleted:flightCompleted Updated:updated_epoch_microseconds];
                requireRepopulate = YES;
            } else if (fetchedLessonRecords.count == 1) {
                // update an existing lesson
                if ([lessonRecord.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue]) {
                    lessonRecord = [fetchedLessonRecords objectAtIndex:0];
                    [self updateOrInsertLessonRecord:lessonRecord InContext:context WithLessonRecordID:lessonRecordID UserID:userID LessonID:lessonID LessonDate:lessonDate InstructorID:instructorID GroundNotes:groundNotes GroundCompleted:groundCompleted FlightNotes:flightNotes FlightCompleted:flightCompleted Updated:updated_epoch_microseconds];
                    requireRepopulate = YES;
                }
            } else {
                FDLogError(@"An unexpected error occurred: there were multiple lesson records found with the same ID (%@: %@), attempting to recover!", lessonRecordID, lessonID);
                // delete all of the existing lesson groups with this ID (should be 1)
                // (data model will delete all associated sub-groups, lessons, etc..)
                for (LessonRecord *lessonRecordToDelete in fetchedLessonRecords) {
                    [context deleteObject:lessonRecordToDelete];
                }
                // re-insert lesson
                lessonRecord = [self updateOrInsertLessonRecord:nil InContext:context WithLessonRecordID:lessonRecordID UserID:userID LessonID:lessonID LessonDate:lessonDate InstructorID:instructorID GroundNotes:groundNotes GroundCompleted:groundCompleted FlightNotes:flightNotes FlightCompleted:flightCompleted Updated:updated_epoch_microseconds];
                requireRepopulate = YES;
            }
            if (lessonRecord != nil) {
                lessonRecord.lastSync = epochMicros;
            }
            
            // loop through the lesson's content, add/update content records with the latest
            if ([content_records isKindOfClass:[NSArray class]]) {
                for (id contentRecordElement in content_records) {
                    if ([contentRecordElement isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *contentRecordDictionary = contentRecordElement;
                        NSNumber *contentRecordID = [contentRecordDictionary objectForKey:@"content_record_id"];
                        NSNumber *contentID = [contentRecordDictionary objectForKey:@"content_id"];
                        NSNumber *completed = [contentRecordDictionary objectForKey:@"completed"];
                        id remarksElement = [contentRecordDictionary objectForKey:@"remarks"];
                        // find the content with the specified ID
                        NSFetchRequest *contentRequest = [[NSFetchRequest alloc] init];
                        NSEntityDescription *contentDescription = [NSEntityDescription entityForName:@"Content" inManagedObjectContext:context];
                        [contentRequest setEntity:contentDescription];
                        NSPredicate *contentPredicate = [NSPredicate predicateWithFormat:@"contentID = %@ AND studentUserID = %@", contentID, userID];
                        [contentRequest setPredicate:contentPredicate];
                        NSArray *fetchedContent = [context executeFetchRequest:contentRequest error:&error];
                        Content *content = nil;
                        if (fetchedContent == nil) {
                            FDLogError(@"Skipped content record update since there was an error checking for existing content!");
                        } else if (fetchedContent.count == 0) {
                            FDLogError(@"Skipped content record update since there was an error checking for existing content!");
                        } else if (fetchedContent.count == 1) {
                            // update an existing content
                            content = [fetchedContent objectAtIndex:0];
                            if (content.record == nil) {
                                // add a new content record
                                ContentRecord *contentRecord = [NSEntityDescription insertNewObjectForEntityForName:@"ContentRecord" inManagedObjectContext:context];
                                contentRecord.contentRecordID = contentRecordID;
                                contentRecord.content = content;
                                contentRecord.completed = completed;
                                contentRecord.userID = userID;
                                if (remarksElement != nil && [remarksElement isKindOfClass:[NSString class]]) {
                                    contentRecord.remarks = remarksElement;
                                }
                                contentRecord.content = content;
                            } else {
                                // update the existing content record
                                ContentRecord *contentRecord = content.record;
                                if (contentRecordID != contentRecord.contentRecordID) {
                                    //FDLogError(@"ContentRecordID for content record changed from %@ to %@", contentRecord.contentRecordID, contentRecordID);
                                    contentRecord.contentRecordID = contentRecordID;
                                }
                                contentRecord.completed = completed;
                                if (remarksElement != nil && [remarksElement isKindOfClass:[NSString class]]) {
                                    contentRecord.remarks = remarksElement;
                                }
                                contentRecord.content = content;
                            }
                        } else {
                            FDLogError(@"An unexpected error occurred: there were multiple contents found with the same ID (%@: %@), attempting to recover!", contentID, lessonID);
                            // delete all of the existing lesson groups with this ID (should be 1)
                            // (data model will delete all associated sub-groups, lessons, etc..)
                            for (Content *contentToDelete in fetchedContent) {
                                [context deleteObject:contentToDelete];
                            }
                        }
                    } else {
                        FDLogError(@"unexpected non-array type in content records for lesson record %d", lessonRecordID);
                    }
                }
            }
            [context save:&error];
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
        }
    }
    return requireRepopulate;
}
- (LessonRecord *)updateOrInsertLessonRecord:(LessonRecord *)lessonRecord InContext:(NSManagedObjectContext *)context WithLessonRecordID:(NSNumber *)recordID UserID:(NSNumber *)userID LessonID:(NSNumber *)lessonID LessonDate:(NSDate *)lessonDate InstructorID:(NSNumber *)instructorID GroundNotes:(NSString *)groundNotes GroundCompleted:(NSString *)groundCompleted FlightNotes:(NSString *)flightNotes FlightCompleted:(NSString *)flightCompleted Updated:(NSNumber *)epochMicros
{
    NSError *error;
    if (lessonRecord == nil) {
        // add new lesson
        FDLogDebug(@"Adding new lesson record ID %@ for lesson ID %@", recordID, lessonID);
        lessonRecord = [NSEntityDescription insertNewObjectForEntityForName:@"LessonRecord" inManagedObjectContext:context];
    }
    lessonRecord.recordID = recordID;
    lessonRecord.userID = userID;
    lessonRecord.lessonDate = lessonDate;
    lessonRecord.instructorID = instructorID;
    lessonRecord.groundNotes = groundNotes;
    lessonRecord.groundCompleted = groundCompleted;
    lessonRecord.flightNotes = flightNotes;
    lessonRecord.flightCompleted = flightCompleted;
    lessonRecord.lastUpdate = epochMicros;
    if (lessonRecord.lesson == nil) {
        // lookup lesson and add this lesson record
        NSFetchRequest *lessonRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *lessonEntityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
        [lessonRequest setEntity:lessonEntityDescription];
        NSPredicate *lessonPredicate = [NSPredicate predicateWithFormat:@"lessonID = %@ AND studentUserID = %@", lessonID, userID];
        [lessonRequest setPredicate:lessonPredicate];
        NSArray *fetchedLessons = [context executeFetchRequest:lessonRequest error:&error];
        Lesson *lesson = nil;
        if (fetchedLessons == nil) {
            FDLogError(@"Unable to retrieve lesson with ID %@ and user ID %@!", lessonID, userID);
        } else if (fetchedLessons.count == 0) {
            FDLogError(@"LessonRecordID %@ owner lesson with ID %@ and user ID %@ not found", recordID, lessonID, userID);
        } else if (fetchedLessons.count == 1) {
            FDLogDebug(@"ASSIGNED LessonRecordID %@ owner lesson with ID %@", recordID, lessonID);
            lesson = [fetchedLessons objectAtIndex:0];
            lessonRecord.lesson = lesson;
        } else {
            FDLogError(@"More than one lesson with ID %@ for ownership of lesson record with ID %@ and user ID %@", lessonID, recordID, userID);
        }
    }
    return lessonRecord;
}

- (void)performLogEntriesSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performLogEntriesSyncCheck");
    // LOG ENTRIES
    // check for lessons records and content records
    NSNumber *lastLogEntriesUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_log_entries_update"];
    if (lastLogEntriesUpdate == nil) {
        lastLogEntriesUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *logEntriesURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:logEntriesURL];
    NSDictionary *logEntriesRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"log_entries", @"action", userID, @"user_id", lastLogEntriesUpdate, @"last_update", nil];
    NSError *error;
    NSData *jsonLogEntriesRequestData =[NSJSONSerialization dataWithJSONObject:logEntriesRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonLogEntriesRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonLogEntriesRequestData];
    //NSString *jsonEntriesStrData = [[NSString alloc] initWithData:jsonLogEntriesRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lesson records update! JSON '%@'", jsonEntriesStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *logEntriesTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
                [self handleLogEntriesUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download log entries: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download log entries due to unknown error!");
            }
        }
        
        // request log entries
        [self performEndorsmentOwnSyncCheck:apiURLString andUserID:userID];
    }];
    [logEntriesTask resume];
}
- (void)performEndorsmentOwnSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performEndorsmentOwnSyncCheck");
    // LOG ENTRIES
    // check for lessons records and content records
    NSNumber *lastLogEntriesUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_log_entries_update"];
    if (lastLogEntriesUpdate == nil) {
        lastLogEntriesUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *logEntriesURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:logEntriesURL];
    NSDictionary *endorsementsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_endorsements_own", @"action", userID, @"user_id", lastLogEntriesUpdate, @"last_update", nil];
    NSError *error;
    NSData *jsonEndorsementsRequestData =[NSJSONSerialization dataWithJSONObject:endorsementsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonEndorsementsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonEndorsementsRequestData];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *endorsmentsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleEndorsementsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download log entries: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download log entries due to unknown error!");
            }
        }
        
        [self performQuizesSyncCheck:apiURLString andUserID:userID];
    }];
    [endorsmentsTask resume];
}
- (void)handleEndorsementsUpdate:(NSData *)results
{
    // get a child managed object context
    NSManagedObjectContext *endorsmentsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [endorsmentsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // output the query results for debug
    //NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"LogEntries update JSON '%@'", jsonStrData);
    // parse the query results
    NSDictionary *endorsmentsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for endorsments data: %@", error);
        return;
    }
    // last update time
    NSNumber *epoch_microseconds;
    id value = [endorsmentsResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_log_entries_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate* newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest log entries update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped endorsments update with invalid last_update time!");
        return;
    }
    // log entries
    value = [endorsmentsResults objectForKey:@"endorsements"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected endorsments element which was not an array!");
        return;
    }
    NSArray *endorsmentsArray = value;
    if ([self parseEndorsementsArray:endorsmentsArray IntoContext:endorsmentsManagedObjectContext WithSync:epoch_microseconds])
    {
        
        NSFetchRequest *expiredLogRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *expiredLognsEntityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:endorsmentsManagedObjectContext];
        [expiredLogRequest setEntity:expiredLognsEntityDescription];
        NSPredicate *expiredLogsPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND type == 2", epoch_microseconds];
        [expiredLogRequest setPredicate:expiredLogsPredicate];
        NSArray *expiredLogsArray = [endorsmentsManagedObjectContext executeFetchRequest:expiredLogRequest error:&error];
        for (Endorsement *endorsementToDelete in expiredLogsArray) {
            [endorsmentsManagedObjectContext deleteObject:endorsementToDelete];
        }
        if ([endorsmentsManagedObjectContext hasChanges]) {
            [endorsmentsManagedObjectContext save:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[[AppDelegate sharedDelegate].endorsementRecevied_VC endorsmentsReload];
            });
        }
    }
}
- (BOOL)parseEndorsementsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id endorsementsElement in array) {
        if ([endorsementsElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected endorsements element which was not a dictionary!");
            continue;
        }
        NSDictionary *endorsementEleFields = endorsementsElement;
        NSNumber *endorsementID = [endorsementEleFields objectForKey:@"endo_id"];
        NSString *cfiNum = [endorsementEleFields objectForKey:@"cfi_number"];
        NSString *cfiSignature = [endorsementEleFields objectForKey:@"cfi_signature"];
        NSString *endoDate = [endorsementEleFields objectForKey:@"endo_date"];
        NSString *endorExpDate = [endorsementEleFields objectForKey:@"endo_exp_date"];
        NSNumber *isSuporsed = [endorsementEleFields objectForKey:@"isSuporsed"];
        NSString *endorName = [endorsementEleFields objectForKey:@"endo_name"];
        NSString *endorText = [endorsementEleFields objectForKey:@"endo_text"];
        NSString *endorType = [endorsementEleFields objectForKey:@"type"];
        NSNumber *endorsement_local_id = [endorsementEleFields objectForKey:@"endorsement_local_id"];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"endorsementID = %@ AND type=2", endorsementID];
        [request setPredicate:predicate];
        NSArray *fetchedEndorsements = [context executeFetchRequest:request error:&error];
        
        Endorsement *endorsement = nil;
        if (fetchedEndorsements == nil) {
            FDLogError(@"Skipped checklists update since there was an error checking for existing endorsements!");
        } else if (fetchedEndorsements.count == 0) {
            
            endorsement = [NSEntityDescription insertNewObjectForEntityForName:@"Endorsement" inManagedObjectContext:context];
            endorsement.endorsementID = endorsementID;
            endorsement.cfiNumber = cfiNum;
            endorsement.cfiSignature = cfiSignature;
            endorsement.endorsementDate = endoDate;
            endorsement.endorsementExpDate = endorExpDate;
            endorsement.isSupersed = isSuporsed;
            endorsement.name = endorName;
            endorsement.text = endorText;
            endorsement.type = @2;
            endorsement.lastSync = epochMicros;
            endorsement.lastUpdate = epochMicros;
            endorsement.endorsement_local_id = endorsement_local_id;
            requireRepopulate = YES;
        } else if (fetchedEndorsements.count == 1) {
            endorsement = [fetchedEndorsements objectAtIndex:0];
            endorsement.endorsementID = endorsementID;
            endorsement.cfiNumber = cfiNum;
            endorsement.cfiSignature = cfiSignature;
            endorsement.endorsementDate = endoDate;
            endorsement.endorsementExpDate = endorExpDate;
            endorsement.isSupersed = isSuporsed;
            endorsement.name = endorName;
            endorsement.text = endorText;
            endorsement.type = @2;
            endorsement.lastSync = epochMicros;
            endorsement.lastUpdate = epochMicros;
            endorsement.endorsement_local_id = endorsement_local_id;
            requireRepopulate = YES;
        } else if (fetchedEndorsements.count > 1) {
            for (Endorsement *endorsementToDelete in fetchedEndorsements) {
                [context deleteObject:endorsementToDelete];
            }
            endorsement = [NSEntityDescription insertNewObjectForEntityForName:@"Endorsement" inManagedObjectContext:context];
            endorsement.endorsementID = endorsementID;
            endorsement.cfiNumber = cfiNum;
            endorsement.cfiSignature = cfiSignature;
            endorsement.endorsementDate = endoDate;
            endorsement.endorsementExpDate = endorExpDate;
            endorsement.isSupersed = isSuporsed;
            endorsement.name = endorName;
            endorsement.text = endorText;
            endorsement.type = @2;
            endorsement.lastSync = epochMicros;
            endorsement.lastUpdate = epochMicros;
            endorsement.endorsement_local_id = endorsement_local_id;
            requireRepopulate = YES;
        }
        if (endorsement != nil) {
            endorsement.lastSync = epochMicros;
        }
    }
    // loop through Endorsements, delete any that have not been synced
    NSFetchRequest *expiredChecklistsRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:context];
    [expiredChecklistsRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0 AND type == 2", epochMicros];
    [expiredChecklistsRequest setPredicate:predicate];
    NSArray *expiredEndorsments = [context executeFetchRequest:expiredChecklistsRequest error:&error];
    if (expiredEndorsments != nil && expiredEndorsments.count > 0) {
        for (Endorsement *endorsmentToDelete in expiredEndorsments) {
            [context deleteObject:endorsmentToDelete];
        }
        
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)handleLogEntriesUpdate:(NSData *)results
{
    // get a child managed object context
    NSManagedObjectContext *logEntriesManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [logEntriesManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // output the query results for debug
    //NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"LogEntries update JSON '%@'", jsonStrData);
    // parse the query results
    NSDictionary *logEntriesResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for lesson data: %@", error);
        return;
    }
    // last update time
    NSNumber *epoch_microseconds;
    id value = [logEntriesResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_log_entries_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate* newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest log entries update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped log entries update with invalid last_update time!");
        return;
    }
    // log entries
    value = [logEntriesResults objectForKey:@"log_entries"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected log entries element which was not an array!");
        return;
    }
    NSArray *logEntriesArray = value;
    if ([self parseLogEntriesArray:logEntriesArray IntoContext:logEntriesManagedObjectContext WithSync:epoch_microseconds])
    {
        
        NSFetchRequest *expiredLogRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *expiredLognsEntityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:logEntriesManagedObjectContext];
        [expiredLogRequest setEntity:expiredLognsEntityDescription];
        NSPredicate *expiredLogsPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epoch_microseconds];
        [expiredLogRequest setPredicate:expiredLogsPredicate];
        NSArray *expiredLogsArray = [logEntriesManagedObjectContext executeFetchRequest:expiredLogRequest error:&error];
        for (LogEntry *logEntryToDelete in expiredLogsArray) {
            if (logEntryToDelete.endorsements.count > 0) {
                for (Endorsement *endorsementToDelete in logEntryToDelete.endorsements) {
                    [logEntriesManagedObjectContext deleteObject:endorsementToDelete];
                }
            }
            [logEntriesManagedObjectContext deleteObject:logEntryToDelete];
        }
        if ([logEntriesManagedObjectContext hasChanges]) {
            [logEntriesManagedObjectContext save:&error];
            // notify documents view controller to reload the managed object context
            dispatch_async(dispatch_get_main_queue(), ^{
                    [[AppDelegate sharedDelegate].logbook_vc populateLogBooks];
            });
        }
    }
}
- (BOOL)parseLogEntriesArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    BOOL requireRepopulate = NO;
    for (id logEntryElement in array) {
        if ([logEntryElement isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            NSDictionary *logEntryFields = logEntryElement;
            id field;
            NSNumber *entryID = [logEntryFields objectForKey:@"entry_id"];
            NSNumber *lessonRecordID = [logEntryFields objectForKey:@"entry_lesson_record_id"];
            NSNumber *lessonID = nil;
            if (![[logEntryFields objectForKey:@"entry_lesson_id"] isKindOfClass:[NSNull class]]) {
                lessonID = [logEntryFields objectForKey:@"entry_lesson_id"];
            }
            NSNumber *userID = [logEntryFields objectForKey:@"user_id"];
            NSNumber *studentID = [logEntryFields objectForKey:@"student_id"];
            NSNumber *instructorID;
            field = [logEntryFields objectForKey:@"instructor_id"];
            if ([field isEqual:[NSNull null]]) {
                instructorID = nil;
            } else {
                instructorID = field;
            }
            NSString *creationDateTimeStr = [logEntryFields objectForKey:@"creation_datetime"];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *creationDateTime = [dateFormat dateFromString:creationDateTimeStr];
            NSString *aircraftCategory = [logEntryFields objectForKey:@"aircraft_category"];
            NSString *aircraftClass = [logEntryFields objectForKey:@"aircraft_class"];
            NSString *aircraftModel = [logEntryFields objectForKey:@"aircraft_model"];
            NSString *aircraftRegistration = [logEntryFields objectForKey:@"aircraft_registration"];
            NSNumber *approachesCount;
            field = [logEntryFields objectForKey:@"approaches_count"];
            if ([field isEqual:[NSNull null]]) {
                approachesCount = nil;
            } else {
                approachesCount = field;
            }
            NSString *approachesType;
            field = [logEntryFields objectForKey:@"approaches_type"];
            if ([field isEqual:[NSNull null]]) {
                approachesType = nil;
            } else {
                approachesType = field;
            }
            NSDecimalNumber *complex;
            field = [logEntryFields objectForKey:@"complex"];
            if ([field isEqual:[NSNull null]]) {
                complex = nil;
            } else {
                complex = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGiven;
            field = [logEntryFields objectForKey:@"dual_given"];
            if ([field isEqual:[NSNull null]]) {
                dualGiven = nil;
            } else {
                dualGiven = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenCFI;
            field = [logEntryFields objectForKey:@"dual_given_cfi"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenCFI = nil;
            } else {
                dualGivenCFI = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenCommercial;
            field = [logEntryFields objectForKey:@"dual_given_commercial"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenCommercial = nil;
            } else {
                dualGivenCommercial = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenGlider;
            field = [logEntryFields objectForKey:@"dual_given_glider"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenGlider = nil;
            } else {
                dualGivenGlider = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenInstrument;
            field = [logEntryFields objectForKey:@"dual_given_instrument"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenInstrument = nil;
            } else {
                dualGivenInstrument = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenOther;
            field = [logEntryFields objectForKey:@"dual_given_other"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenOther = nil;
            } else {
                dualGivenOther = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenRecreational;
            field = [logEntryFields objectForKey:@"dual_given_recreational"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenRecreational = nil;
            } else {
                dualGivenRecreational = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualGivenSport;
            field = [logEntryFields objectForKey:@"dual_given_sport"];
            if ([field isEqual:[NSNull null]]) {
                dualGivenSport = nil;
            } else {
                dualGivenSport = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *dualReceived;
            field = [logEntryFields objectForKey:@"dual_received"];
            if ([field isEqual:[NSNull null]]) {
                dualReceived = nil;
            } else {
                dualReceived = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSString *flightRoute;
            field = [logEntryFields objectForKey:@"flight_route"];
            if ([field isEqual:[NSNull null]]) {
                flightRoute = nil;
            } else {
                flightRoute = field;
            }
            
            NSDecimalNumber *glider;
            field = [logEntryFields objectForKey:@"glider"];
            if ([field isEqual:[NSNull null]]) {
                glider = nil;
            } else {
                glider = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *helicopter;
            field = [logEntryFields objectForKey:@"helicopter"];
            if ([field isEqual:[NSNull null]]) {
                helicopter = nil;
            } else {
                helicopter = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *hightPerf;
            field = [logEntryFields objectForKey:@"hight_perf"];
            if ([field isEqual:[NSNull null]]) {
                hightPerf = nil;
            } else {
                hightPerf = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *groundTime;
            field = [logEntryFields objectForKey:@"ground_time"];
            if ([field isEqual:[NSNull null]]) {
                groundTime = nil;
            } else {
                groundTime = [NSDecimalNumber decimalNumberWithString:field];
            }
            
            NSDecimalNumber *hobbsIn;
            field = [logEntryFields objectForKey:@"hobbs_in"];
            if ([field isEqual:[NSNull null]]) {
                hobbsIn = nil;
            } else {
                hobbsIn = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *hobbsOut;
            field = [logEntryFields objectForKey:@"hobbs_out"];
            if ([field isEqual:[NSNull null]]) {
                hobbsOut = nil;
            } else {
                hobbsOut = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSNumber *holds;
            field = [logEntryFields objectForKey:@"holds"];
            if ([field isEqual:[NSNull null]]) {
                holds = nil;
            } else {
                holds = field;
            }
            
            NSDecimalNumber *instrumentActual;
            field = [logEntryFields objectForKey:@"instrument_actual"];
            if ([field isEqual:[NSNull null]]) {
                instrumentActual = nil;
            } else {
                instrumentActual = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *instrumentHood;
            field = [logEntryFields objectForKey:@"instrument_hood"];
            if ([field isEqual:[NSNull null]]) {
                instrumentHood = nil;
            } else {
                instrumentHood = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *instrumentSim;
            field = [logEntryFields objectForKey:@"instrument_sim"];
            if ([field isEqual:[NSNull null]]) {
                instrumentSim = nil;
            } else {
                instrumentSim = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *jet;
            field = [logEntryFields objectForKey:@"jet"];
            if ([field isEqual:[NSNull null]]) {
                jet = nil;
            } else {
                jet = [NSDecimalNumber decimalNumberWithString:field];
            }
            
            
            NSNumber *landingsDay;
            field = [logEntryFields objectForKey:@"landings_day"];
            if ([field isEqual:[NSNull null]]) {
                landingsDay = nil;
            } else {
                landingsDay = field;
            }
            NSNumber *landingsNight;
            field = [logEntryFields objectForKey:@"landings_night"];
            if ([field isEqual:[NSNull null]]) {
                landingsNight = nil;
            } else {
                landingsNight = field;
            }
            
            NSArray *endorsementsArray = [logEntryFields objectForKey:@"endorsements"];
            
            NSNumber *updated_epoch_microseconds = [logEntryFields objectForKey:@"last_update"];
            // parse lesson date from string
            NSString *logDateString = [logEntryFields objectForKey:@"log_date"];
            NSDate *logDate = [dateFormat dateFromString:logDateString];
            NSString *remarks = [logEntryFields objectForKey:@"remarks"];
            NSDecimalNumber *totalFlightTime =[NSDecimalNumber decimalNumberWithString:[logEntryFields objectForKey:@"total_flight_time"]];
            
            NSDecimalNumber *nightDualReceived;
            field = [logEntryFields objectForKey:@"night_dual_received"];
            if ([field isEqual:[NSNull null]]) {
                nightDualReceived = nil;
            } else {
                nightDualReceived = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *nightTime;
            field = [logEntryFields objectForKey:@"night_time"];
            if ([field isEqual:[NSNull null]]) {
                nightTime = nil;
            } else {
                nightTime = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *picTime;
            field = [logEntryFields objectForKey:@"pic_time"];
            if ([field isEqual:[NSNull null]]) {
                picTime = nil;
            } else {
                picTime = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *recreational;
            field = [logEntryFields objectForKey:@"recreational"];
            if ([field isEqual:[NSNull null]]) {
                recreational = nil;
            } else {
                recreational = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *sicTime;
            field = [logEntryFields objectForKey:@"sic_time"];
            if ([field isEqual:[NSNull null]]) {
                sicTime = nil;
            } else {
                sicTime = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *soloTime;
            field = [logEntryFields objectForKey:@"solo_time"];
            if ([field isEqual:[NSNull null]]) {
                soloTime = nil;
            } else {
                soloTime = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *sport;
            field = [logEntryFields objectForKey:@"sport"];
            if ([field isEqual:[NSNull null]]) {
                sport = nil;
            } else {
                sport = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *taildragger;
            field = [logEntryFields objectForKey:@"taildragger"];
            if ([field isEqual:[NSNull null]]) {
                taildragger = nil;
            } else {
                taildragger = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSString *tracking;
            field = [logEntryFields objectForKey:@"tracking"];
            if ([field isEqual:[NSNull null]]) {
                tracking = nil;
            } else {
                tracking = field;
            }
            NSDecimalNumber *turboprop;
            field = [logEntryFields objectForKey:@"turboprop"];
            if ([field isEqual:[NSNull null]]) {
                turboprop = nil;
            } else {
                turboprop = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *ultralight;
            field = [logEntryFields objectForKey:@"ultralight"];
            if ([field isEqual:[NSNull null]]) {
                ultralight = nil;
            } else {
                ultralight = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountry;
            field = [logEntryFields objectForKey:@"cross_country"];
            if ([field isEqual:[NSNull null]]) {
                crossCountry = nil;
            } else {
                crossCountry = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountryDualGiven;
            field = [logEntryFields objectForKey:@"cross_country_dual_given"];
            if ([field isEqual:[NSNull null]]) {
                crossCountryDualGiven = nil;
            } else {
                crossCountryDualGiven = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountryDualReceived;
            field = [logEntryFields objectForKey:@"cross_country_dual_received"];
            if ([field isEqual:[NSNull null]]) {
                crossCountryDualReceived = nil;
            } else {
                crossCountryDualReceived = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountryNightDualReceived;
            field = [logEntryFields objectForKey:@"cross_country_night_dual_received"];
            if ([field isEqual:[NSNull null]]) {
                crossCountryNightDualReceived = nil;
            } else {
                crossCountryNightDualReceived = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountryNight;
            field = [logEntryFields objectForKey:@"cross_country_night"];
            if ([field isEqual:[NSNull null]]) {
                crossCountryNight = nil;
            } else {
                crossCountryNight = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountryPic;
            field = [logEntryFields objectForKey:@"cross_country_pic"];
            if ([field isEqual:[NSNull null]]) {
                crossCountryPic = nil;
            } else {
                crossCountryPic = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSDecimalNumber *crossCountrySolo;
            field = [logEntryFields objectForKey:@"cross_country_solo"];
            if ([field isEqual:[NSNull null]]) {
                crossCountrySolo = nil;
            } else {
                crossCountrySolo = [NSDecimalNumber decimalNumberWithString:field];
            }
            NSString *instructorSignature;
            field = [logEntryFields objectForKey:@"instructor_signature"];
            if ([field isEqual:[NSNull null]]) {
                instructorSignature = nil;
            } else {
                instructorSignature = field;
            }
            NSString *instructorCertNo;
            field = [logEntryFields objectForKey:@"instructor_cert_no"];
            if ([field isEqual:[NSNull null]]) {
                instructorCertNo = nil;
            } else {
                instructorCertNo = field;
            }
            NSNumber *log_local_id = [logEntryFields objectForKey:@"log_local_id"];
            //FDLogDebug(@"loaded lesson record: id=%@, lesson_id=%@, ground_notes=%@, flight_notes=%@, updated=%@", lessonRecordID, lessonID, groundNotes, flightNotes, updated_epoch_microseconds);
            // check to see if this lesson needs to be saved
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"entryID = %@", entryID];
            [request setPredicate:predicate];
            NSArray *fetchedLogEntries = [context executeFetchRequest:request error:&error];
            LogEntry *entry = nil;
            if (fetchedLogEntries == nil) {
                FDLogError(@"Skipped log entry update since there was an error checking for existing log entries!");
            } else if (fetchedLogEntries.count == 0) {
                // make sure there's not an existing entry with the same creationDateTime & user ID!
                NSFetchRequest *requestByCreation = [[NSFetchRequest alloc] init];
                [requestByCreation setEntity:entityDescription];
                NSPredicate *creationPredicate = [NSPredicate predicateWithFormat:@"userID = %@ AND creationDateTime = %@", userID, creationDateTime];
                [requestByCreation setPredicate:creationPredicate];
                NSArray *fetchedLogEntriesByCreation = [context executeFetchRequest:requestByCreation error:&error];
                if (fetchedLogEntriesByCreation == nil) {
                    FDLogError(@"Skipped log entry update since there was an error checking for existing log entries!");
                } else if (fetchedLogEntriesByCreation.count >= 1) {
                    // delete any existing lessons which appear to be duplicates!
                    for (LogEntry *logEntryToDelete in fetchedLogEntriesByCreation) {
                        [context deleteObject:logEntryToDelete];
                    }
                }
                // insert a new lesson
                entry = [self updateOrInsertLogEntry:nil InContext:context WithEntryID:entryID LessonRecordID:lessonRecordID LessonID:lessonID LogDate:logDate Updated:updated_epoch_microseconds];
                entry.valueForSort = updated_epoch_microseconds;
                requireRepopulate = YES;
            } else if (fetchedLogEntries.count == 1) {
                // update an existing lesson
                entry = [fetchedLogEntries objectAtIndex:0];
                if ([entry.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue] || entry.isFault) {
                    entry = [self updateOrInsertLogEntry:nil InContext:context WithEntryID:entryID LessonRecordID:lessonRecordID LessonID:lessonID LogDate:logDate Updated:updated_epoch_microseconds];
                    requireRepopulate = YES;
                } else {
                    entry.lastSync = epochMicros;
                    //entry = nil;
                }
            } else {
                FDLogError(@"An unexpected error occurred: there were multiple log entries found with the same ID (%@), attempting to recover!", entryID);
                // delete all of the existing lesson groups with this ID (should be 1)
                // (data model will delete all associated sub-groups, lessons, etc..)
                for (LogEntry *logEntryToDelete in fetchedLogEntries) {
                    for (Endorsement *endorsementToDelete in logEntryToDelete.endorsements) {
                        [context deleteObject:endorsementToDelete];
                    }
                    [context deleteObject:logEntryToDelete];
                }
                // re-insert lesson
                entry = [self updateOrInsertLogEntry:nil InContext:context WithEntryID:entryID LessonRecordID:lessonRecordID LessonID:lessonID LogDate:logDate Updated:updated_epoch_microseconds];
                requireRepopulate = YES;
            }
            if (entry != nil) {
                // update the fields of the log entry
                entry.logDate = logDate;
                entry.totalFlightTime = totalFlightTime;
                entry.lastSync = epochMicros;
                entry.userID = userID;
                entry.instructorID = instructorID;
                entry.creationDateTime = creationDateTime;
                entry.aircraftCategory = aircraftCategory;
                entry.aircraftClass = aircraftClass;
                entry.aircraftModel = aircraftModel;
                entry.aircraftRegistration = aircraftRegistration;
                entry.approachesCount = approachesCount;
                entry.approachesType = approachesType;
                entry.complex = complex;
                entry.dualGiven = dualGiven;
                entry.dualGivenCFI = dualGivenCFI;
                entry.dualGivenCommercial = dualGivenCommercial;
                entry.dualGivenGlider = dualGivenGlider;
                entry.dualGivenInstrument = dualGivenInstrument;
                entry.dualGivenOther = dualGivenOther;
                entry.dualGivenRecreational = dualGivenRecreational;
                entry.dualGivenSport = dualGivenSport;
                entry.dualReceived = dualReceived;
                entry.flightRoute = flightRoute;
                entry.glider = glider;
                entry.groundTime = groundTime;
                entry.helicopter = helicopter;
                entry.highPerf = hightPerf;
                entry.hobbsIn = hobbsIn;
                entry.hobbsOut = hobbsOut;
                entry.holds = holds;
                entry.instrumentActual = instrumentActual;
                entry.instrumentHood = instrumentHood;
                entry.instrumentSim = instrumentSim;
                entry.jet = jet;
                entry.landingsDay = landingsDay;
                entry.landingsNight = landingsNight;
                entry.lessonId = lessonID;
                entry.nightDualReceived = nightDualReceived;
                entry.nightTime = nightTime;
                entry.picTime = picTime;
                entry.recreational = recreational;
                entry.sicTime = sicTime;
                entry.soloTime = soloTime;
                entry.sport = sport;
                entry.taildragger = taildragger;
                entry.tracking = tracking;
                entry.turboprop = turboprop;
                entry.ultraLight = ultralight;
                
                entry.xc = crossCountry;
                entry.xcDualGiven = crossCountryDualGiven;
                entry.xcDualReceived = crossCountryDualReceived;
                entry.xcNightDualReceived = crossCountryNightDualReceived;
                entry.xcNightTime = crossCountryNight;
                entry.xcPIC = crossCountryPic;
                entry.xcSolo = crossCountrySolo;
                
                entry.studentUserID = studentID;
                if ([remarks isEqual:[NSNull null]] == NO) {
                    entry.remarks = remarks;
                }
                
                entry.instructorSignature = instructorSignature;
                entry.instructorCertNo = instructorCertNo;
                
                entry.log_local_id = log_local_id;
                
                
                NSMutableArray *endorsementIDs = [[NSMutableArray alloc] init];
                for (NSDictionary *dictToEndorsement in endorsementsArray) {
                    NSNumber *endorsementID = [dictToEndorsement objectForKey:@"endo_id"];
                    NSNumber *endorsement_local_id = [dictToEndorsement objectForKey:@"endorsement_local_id"];
                    [endorsementIDs addObject:endorsementID];
                    Endorsement *endorsementToAdd = nil;
                    for (Endorsement *endorsement in entry.endorsements) {
                        if ([endorsement.endorsementID integerValue] == [endorsementID integerValue]) {
                            endorsementToAdd = endorsement;
                            break;
                        }
                    }
                    
                    if (endorsementToAdd == nil) {
                        endorsementToAdd =  [NSEntityDescription insertNewObjectForEntityForName:@"Endorsement" inManagedObjectContext:context];
                        endorsementToAdd.endorsementID = [dictToEndorsement objectForKey:@"endo_id"];
                        endorsementToAdd.cfiNumber = [dictToEndorsement objectForKey:@"cfi_number"];
                        endorsementToAdd.cfiSignature = [dictToEndorsement objectForKey:@"cfi_signature"];
                        endorsementToAdd.endorsementDate = [dictToEndorsement objectForKey:@"endo_date"];
                        endorsementToAdd.endorsementExpDate = [dictToEndorsement objectForKey:@"endo_exp_date"];
                        endorsementToAdd.isSupersed = [dictToEndorsement objectForKey:@"isSuporsed"];
                        endorsementToAdd.name = [dictToEndorsement objectForKey:@"endo_name"];
                        endorsementToAdd.text = [dictToEndorsement objectForKey:@"endo_text"];
                        endorsementToAdd.type = [dictToEndorsement objectForKey:@"type"];
                        endorsementToAdd.lastSync = epochMicros;
                        endorsementToAdd.lastUpdate = epochMicros;
                        endorsementToAdd.endorsement_local_id = endorsement_local_id;
                        [entry addEndorsementsObject:endorsementToAdd];
                    }else{
                        endorsementToAdd.endorsementID = [dictToEndorsement objectForKey:@"endo_id"];
                        endorsementToAdd.cfiNumber = [dictToEndorsement objectForKey:@"cfi_number"];
                        endorsementToAdd.cfiSignature = [dictToEndorsement objectForKey:@"cfi_signature"];
                        endorsementToAdd.endorsementDate = [dictToEndorsement objectForKey:@"endo_date"];
                        endorsementToAdd.endorsementExpDate = [dictToEndorsement objectForKey:@"endo_exp_date"];
                        endorsementToAdd.isSupersed = [dictToEndorsement objectForKey:@"isSuporsed"];
                        endorsementToAdd.name = [dictToEndorsement objectForKey:@"endo_name"];
                        endorsementToAdd.text = [dictToEndorsement objectForKey:@"endo_text"];
                        endorsementToAdd.type = [dictToEndorsement objectForKey:@"type"];
                        endorsementToAdd.lastSync = epochMicros;
                        endorsementToAdd.lastUpdate = epochMicros;
                        endorsementToAdd.endorsement_local_id = endorsement_local_id;
                    }
                }
                
                for (Endorsement *endorsementToDelete in entry.endorsements) {
                    if (![endorsementIDs containsObject:endorsementToDelete.endorsementID]) {
                        [context deleteObject:endorsementToDelete];
                    }
                }
            }
            
            [context save:&error];
            if (error) {
                NSLog(@"%@", error);
            }
        }
    }
    return requireRepopulate;
}
- (LogEntry *)updateOrInsertLogEntry:(LogEntry *)entry InContext:(NSManagedObjectContext *)context WithEntryID:(NSNumber *)entryID LessonRecordID:(NSNumber *)lessonRecordID LessonID:(NSNumber *)lessonID LogDate:(NSDate *)logDate Updated:(NSNumber *)epochMicros
{
    NSError *error;
    if (entry == nil) {
        // add new lesson
        FDLogDebug(@"Adding new log entry ID %@ for lesson ID %@", entryID, lessonID);
        entry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
    }
    entry.entryID = entryID;
    entry.logDate = logDate;
    entry.lastUpdate = epochMicros;
    if (entry.logLessonRecord == nil && lessonRecordID != nil && [lessonRecordID isEqual:[NSNull null]] == NO) {
        // lookup lesson record and add this log entry
        NSFetchRequest *lessonRecordRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *lessonRecordEntityDescription = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:context];
        [lessonRecordRequest setEntity:lessonRecordEntityDescription];
        NSPredicate *lessonRecordPredicate = [NSPredicate predicateWithFormat:@"recordID = %@", lessonRecordID];
        [lessonRecordRequest setPredicate:lessonRecordPredicate];
        NSArray *fetchedLessonRecords = [context executeFetchRequest:lessonRecordRequest error:&error];
        LessonRecord *lessonRecord = nil;
        if (fetchedLessonRecords == nil) {
            FDLogError(@"Unable to retrieve lesson record with ID %@!", lessonRecordID);
        } else if (fetchedLessonRecords.count == 0) {
            FDLogError(@"LogEntryID %@ owner lesson record with ID %@ not found", entryID, lessonRecordID);
        } else if (fetchedLessonRecords.count == 1) {
            //FDLogDebug(@"ASSIGNED LogEntryID %@ owner lesson record with ID %@", entryID, lessonRecordID);
            lessonRecord = [fetchedLessonRecords objectAtIndex:0];
            lessonRecord.lessonLog = entry;
        } else {
            FDLogError(@"More than one lesson record with ID %@ for ownership of log entry with ID %@", lessonRecordID, entryID);
        }
    }
    return entry;
}
- (void)performQuizesSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    // quizes
    // check if there are any lesson updates to download from the web service
    NSNumber *lastQuizesUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_quizes_update"];
    if (lastQuizesUpdate == nil) {
        lastQuizesUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *lessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:lessonsURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    NSDictionary *lessonsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_quizes", @"action", type, @"user_type",  userID, @"user_id", lastQuizesUpdate, @"last_update", nil];
    NSError *error;
    NSData *jsonLessonsRequestData =[NSJSONSerialization dataWithJSONObject:lessonsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonLessonsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonLessonsRequestData];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *lessonsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        if (data != nil) {
                [self handleQuizesUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download Quizes: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download Quizes due to unknown error!");
            }
        }
            [self performDocumentsSyncCheck:apiURLString andUserID:userID];
    }];
    [lessonsTask resume];
}
- (void)handleQuizesUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse quizes update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *quizesManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [quizesManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *quizResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for lesson data: %@", error);
        return;
    }
    // last update time
    NSNumber *epoch_microseconds;
    id value = [quizResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_quizes_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate* newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest lessons update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped lessons update with invalid last_update time!");
        return;
    }
    BOOL requireRepopulate = NO;
    value = [quizResults objectForKey:@"quizes"];
    if ([self parseQuizArray:value IntoContext:quizesManagedObjectContext WithSync:epoch_microseconds] == YES) {
        requireRepopulate = YES;
    }
    
    if ([quizesManagedObjectContext hasChanges]) {
        [quizesManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL requireRepopulate = [[AppDelegate sharedDelegate].quizses_VC populateQuizes];
            if (requireRepopulate == YES) {
                [[AppDelegate sharedDelegate].quizses_VC reloadData];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
        });
    }
}
- (BOOL)parseQuizArray:(NSArray *)quizsArray IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id quizElement in quizsArray) {
        if ([quizElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected lesson group element which was not a dictionary!");
            continue;
        }
        NSDictionary *quizElementFields = quizElement;
        NSNumber *courseGroupID = [quizElementFields objectForKey:@"coursegroupid"];
        NSNumber *gotScore = [quizElementFields objectForKey:@"gotscore"];
        NSNumber *lastSync = [quizElementFields objectForKey:@"lastsync"];
        NSNumber *lastUpdate = [quizElementFields objectForKey:@"lastupdate"];
        NSString *name = [quizElementFields objectForKey:@"name"];
        NSNumber *passingScore = [quizElementFields objectForKey:@"passingscore"];
        NSNumber *quizId = [quizElementFields objectForKey:@"quizidlocal"];
        NSNumber *quizNumber = [quizElementFields objectForKey:@"quiznumber"];
        NSNumber *quizTaken = [quizElementFields objectForKey:@"quiztaken"];
        NSNumber *studentUserID = [quizElementFields objectForKey:@"studentuserid"];
        NSString *timeLimit = [quizElementFields objectForKey:@"timelimit"];
        NSNumber *recordId = [quizElementFields objectForKey:@"record_id"];
        NSNumber *quizGroupId = [quizElementFields objectForKey:@"quiz_group_id"];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordId = %@", recordId];
        [request setPredicate:predicate];
        NSArray *fetchedQuizes = [context executeFetchRequest:request error:&error];
        
        Quiz *quiz = nil;
        if (fetchedQuizes == nil) {
            FDLogError(@"Skipped quiz update since there was an error checking for existing quizes!");
        } else if (fetchedQuizes.count == 0) {
            
            quiz = [NSEntityDescription insertNewObjectForEntityForName:@"Quiz" inManagedObjectContext:context];
            quiz.courseGroupID = courseGroupID;
            quiz.gotScore = gotScore;
            quiz.lastSync = epochMicros;
            quiz.lastUpdate = lastUpdate;
            quiz.name = name;
            quiz.passingScore = passingScore;
            quiz.quizId = quizId;
            quiz.quizNumber = quizNumber;
            quiz.quizTaken = quizTaken;
            quiz.studentUserID = studentUserID;
            quiz.timeLimit = timeLimit;
            quiz.recordId = recordId;
            quiz.quizGroupId = quizGroupId;
            if ([quizElementFields objectForKey:@"questions"] && [[quizElementFields objectForKey:@"questions"] count] > 0) {
                for (NSDictionary *dict in [quizElementFields objectForKey:@"questions"]) {
                    Question *question = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:context];
                    question.question = [dict objectForKey:@"question"];
                    question.answerA = [dict objectForKey:@"answerA"];
                    question.answerB = [dict objectForKey:@"answerB"];
                    question.answerC = [dict objectForKey:@"answerC"];
                    question.explanationReference = [dict objectForKey:@"explanationref"];
                    question.explanationcode = [dict objectForKey:@"explanationcode"];
                    question.explanationofcorrectAnswer = [dict objectForKey:@"explanationcorrectanswer"];
                    question.lastSync =epochMicros;
                    question.lastUpdate = lastUpdate;
                    question.marked = [dict objectForKey:@"marked"];
                    question.gaveAnswer = [dict objectForKey:@"gaveanswer"];
                    question.questionId = [dict objectForKey:@"questionidlocal"];
                    question.quizId = quiz.recordId;
                    question.correctAnswer = [dict objectForKey:@"correctanswer"];
                    question.recodeId = [dict objectForKey:@"question_recordid"];
                    question.figureurl = [dict objectForKey:@"figure_url"];
                    question.ordering = [dict objectForKey:@"ordering"];
                    [quiz addQuestionsObject:question];
                }
            }
            requireRepopulate = YES;
        } else if (fetchedQuizes.count == 1) {
            quiz = [fetchedQuizes objectAtIndex:0];
            if ([quiz.lastSync longLongValue] < [lastSync longLongValue]) {
                quiz.courseGroupID = courseGroupID;
                quiz.gotScore = gotScore;
                quiz.lastSync = epochMicros;
                quiz.lastUpdate = lastUpdate;
                quiz.name = name;
                quiz.passingScore = passingScore;
                quiz.quizId = quizId;
                quiz.quizNumber = quizNumber;
                quiz.quizTaken = quizTaken;
                quiz.studentUserID = studentUserID;
                quiz.timeLimit = timeLimit;
                quiz.recordId = recordId;
                quiz.quizGroupId = quizGroupId;
                
                if ([quizElementFields objectForKey:@"questions"] && [[quizElementFields objectForKey:@"questions"] count] > 0) {
                    for (NSDictionary *dict in [quizElementFields objectForKey:@"questions"]) {
                        Question *questionToCheck = nil;
                        for (int i = 0; i < quiz.questions.count; i ++) {
                            Question *ques = [quiz.questions objectAtIndex:i];
                            if ([ques.ordering integerValue] == [[dict objectForKey:@"ordering"] integerValue] && [ques.questionId integerValue] == [[dict objectForKey:@"questionidlocal"] integerValue]) {
                                questionToCheck = ques;
                            }
                        }
                        if (questionToCheck != nil) {
                            questionToCheck.question = [dict objectForKey:@"question"];
                            questionToCheck.answerA = [dict objectForKey:@"answerA"];
                            questionToCheck.answerB = [dict objectForKey:@"answerB"];
                            questionToCheck.answerC = [dict objectForKey:@"answerC"];
                            questionToCheck.explanationReference = [dict objectForKey:@"explanationref"];
                            questionToCheck.explanationcode = [dict objectForKey:@"explanationcode"];
                            questionToCheck.explanationofcorrectAnswer = [dict objectForKey:@"explanationcorrectanswer"];
                            questionToCheck.lastSync =epochMicros;
                            questionToCheck.lastUpdate = lastUpdate;
                            BOOL isInstructorLevel = YES;
                            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                                isInstructorLevel = YES;
                            }else{
                                isInstructorLevel = NO;
                            }
                            if ([AppDelegate sharedDelegate].isTestingScreen && !isInstructorLevel) {
                                
                            }else{
                                questionToCheck.marked = [dict objectForKey:@"marked"];
                                questionToCheck.gaveAnswer = [dict objectForKey:@"gaveanswer"];
                            }
                            questionToCheck.questionId = [dict objectForKey:@"questionidlocal"];
                            questionToCheck.quizId = quiz.recordId;
                            questionToCheck.correctAnswer = [dict objectForKey:@"correctanswer"];
                            questionToCheck.recodeId = [dict objectForKey:@"question_recordid"];
                            questionToCheck.figureurl = [dict objectForKey:@"figure_url"];
                            questionToCheck.ordering = [dict objectForKey:@"ordering"];
                        }else{
                            questionToCheck = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:context];
                            questionToCheck.question = [dict objectForKey:@"question"];
                            questionToCheck.answerA = [dict objectForKey:@"answerA"];
                            questionToCheck.answerB = [dict objectForKey:@"answerB"];
                            questionToCheck.answerC = [dict objectForKey:@"answerC"];
                            questionToCheck.explanationReference = [dict objectForKey:@"explanationref"];
                            questionToCheck.explanationcode = [dict objectForKey:@"explanationcode"];
                            questionToCheck.explanationofcorrectAnswer = [dict objectForKey:@"explanationcorrectanswer"];
                            questionToCheck.lastSync =epochMicros;
                            questionToCheck.lastUpdate = lastUpdate;
                            questionToCheck.marked = [dict objectForKey:@"marked"];
                            questionToCheck.gaveAnswer = [dict objectForKey:@"gaveanswer"];
                            questionToCheck.questionId = [dict objectForKey:@"questionidlocal"];
                            questionToCheck.quizId = quiz.recordId;
                            questionToCheck.correctAnswer = [dict objectForKey:@"correctanswer"];
                            questionToCheck.recodeId = [dict objectForKey:@"question_recordid"];
                            questionToCheck.figureurl = [dict objectForKey:@"figure_url"];
                            questionToCheck.ordering = [dict objectForKey:@"ordering"];
                            [quiz addQuestionsObject:questionToCheck];
                        }
                    }
                }
                
                requireRepopulate = YES;
            }
        } else if (fetchedQuizes.count > 1) {
            for (Quiz *quizToDelete in fetchedQuizes) {
                for (Question *questionToDelete in quizToDelete.questions) {
                    [context deleteObject:questionToDelete];
                }
                [context deleteObject:quizToDelete];
            }
            FDLogError(@"An unexpected error occurred: there were multiple groups found with the same ID (%@: %@), attempting to recover!", recordId, name);
            quiz = [NSEntityDescription insertNewObjectForEntityForName:@"Quiz" inManagedObjectContext:context];
            quiz.courseGroupID = courseGroupID;
            quiz.gotScore = gotScore;
            quiz.lastSync = epochMicros;
            quiz.lastUpdate = lastUpdate;
            quiz.name = name;
            quiz.passingScore = passingScore;
            quiz.quizId = quizId;
            quiz.quizNumber = quizNumber;
            quiz.quizTaken = quizTaken;
            quiz.studentUserID = studentUserID;
            quiz.timeLimit = timeLimit;
            quiz.recordId = recordId;
            quiz.quizGroupId = quizGroupId;
            if ([quizElementFields objectForKey:@"questions"] && [[quizElementFields objectForKey:@"questions"] count] > 0) {
                for (NSDictionary *dict in [quizElementFields objectForKey:@"questions"]) {
                    Question *questionToCheck = nil;
                    for (int i = 0; i < quiz.questions.count; i ++) {
                        Question *ques = [quiz.questions objectAtIndex:i];
                        if ([ques.ordering integerValue] == [[dict objectForKey:@"ordering"] integerValue] && [ques.questionId integerValue] == [[dict objectForKey:@"questionidlocal"] integerValue]) {
                            questionToCheck = ques;
                        }
                    }
                    if (questionToCheck != nil) {
                        questionToCheck.question = [dict objectForKey:@"question"];
                        questionToCheck.answerA = [dict objectForKey:@"answerA"];
                        questionToCheck.answerB = [dict objectForKey:@"answerB"];
                        questionToCheck.answerC = [dict objectForKey:@"answerC"];
                        questionToCheck.explanationReference = [dict objectForKey:@"explanationref"];
                        questionToCheck.explanationcode = [dict objectForKey:@"explanationcode"];
                        questionToCheck.explanationofcorrectAnswer = [dict objectForKey:@"explanationcorrectanswer"];
                        questionToCheck.lastSync =epochMicros;
                        questionToCheck.lastUpdate = lastUpdate;
                        questionToCheck.marked = [dict objectForKey:@"marked"];
                        questionToCheck.gaveAnswer = [dict objectForKey:@"gaveanswer"];
                        questionToCheck.questionId = [dict objectForKey:@"questionidlocal"];
                        questionToCheck.quizId = quiz.recordId;
                        questionToCheck.correctAnswer = [dict objectForKey:@"correctanswer"];
                        questionToCheck.recodeId = [dict objectForKey:@"question_recordid"];
                        questionToCheck.figureurl = [dict objectForKey:@"figure_url"];
                        questionToCheck.ordering = [dict objectForKey:@"ordering"];
                    }else{
                        questionToCheck = [NSEntityDescription insertNewObjectForEntityForName:@"Question" inManagedObjectContext:context];
                        questionToCheck.question = [dict objectForKey:@"question"];
                        questionToCheck.answerA = [dict objectForKey:@"answerA"];
                        questionToCheck.answerB = [dict objectForKey:@"answerB"];
                        questionToCheck.answerC = [dict objectForKey:@"answerC"];
                        questionToCheck.explanationReference = [dict objectForKey:@"explanationref"];
                        questionToCheck.explanationcode = [dict objectForKey:@"explanationcode"];
                        questionToCheck.explanationofcorrectAnswer = [dict objectForKey:@"explanationcorrectanswer"];
                        questionToCheck.lastSync =epochMicros;
                        questionToCheck.lastUpdate = lastUpdate;
                        questionToCheck.marked = [dict objectForKey:@"marked"];
                        questionToCheck.gaveAnswer = [dict objectForKey:@"gaveanswer"];
                        questionToCheck.questionId = [dict objectForKey:@"questionidlocal"];
                        questionToCheck.quizId = quiz.recordId;
                        questionToCheck.correctAnswer = [dict objectForKey:@"correctanswer"];
                        questionToCheck.recodeId = [dict objectForKey:@"question_recordid"];
                        questionToCheck.figureurl = [dict objectForKey:@"figure_url"];
                        questionToCheck.ordering = [dict objectForKey:@"ordering"];
                        [quiz addQuestionsObject:questionToCheck];
                    }
                }
            }
            requireRepopulate = YES;
        }
        if (quiz != nil) {
            quiz.lastSync = epochMicros;
            for (Question *questionToSync in quiz.questions) {
                questionToSync.lastSync = epochMicros;
            }
        }
    }
    // loop through lesson groups, delete any that have not been synced
    NSFetchRequest *expiredQuestoinRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Question" inManagedObjectContext:context];
    [expiredQuestoinRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredQuestoinRequest setPredicate:predicate];
    NSArray *expiredQuestionz = [context executeFetchRequest:expiredQuestoinRequest error:&error];
    if (expiredQuestionz != nil && expiredQuestionz.count > 0) {
        for (Question *questionToDelete in expiredQuestionz) {
            [context deleteObject:questionToDelete];
        }
        requireRepopulate = YES;
    }
    
    
    // loop through lesson groups, delete any that have not been synced
    NSFetchRequest *expiredStudentRequest = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
    [expiredStudentRequest setEntity:entityDescription];
    predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredStudentRequest setPredicate:predicate];
    NSArray *expiredQuizes = [context executeFetchRequest:expiredStudentRequest error:&error];
    if (expiredQuizes != nil && expiredQuizes.count > 0) {
        for (Quiz *quizToDelete in expiredQuizes) {
            [context deleteObject:quizToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performDocumentsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"peformDocumentsSyncCheck");
    // check if there are any document updates to download from the web service
    NSNumber *lastDocumentsUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_documents_update"];
    if (lastDocumentsUpdate == nil) {
        lastDocumentsUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *documentsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:documentsURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"documents", @"action", userID, @"user_id", lastDocumentsUpdate, @"last_update", type, @"user_type", nil];
    NSError *error;
    NSData *jsonRequestData =[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRequestData];
    //FDLogDebug(@"Checking for any document updates!");
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *documentsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
                [self handleDocumentsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download documents: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download documents due to unknown error!");
            }
        }
            [self performNavLogSyncCheck:apiURLString andUserID:userID];
    }];
    [documentsTask resume];
}
- (void)handleDocumentsUpdate:(NSData *)results
{
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse Documents update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *documentsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [documentsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *documentResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for document list!");
        return;
    }
    // store last document update time
    NSNumber *epoch_microseconds;
    id value = [documentResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
        [[NSUserDefaults standardUserDefaults] setObject:epoch_microseconds forKey:@"last_document_update"];
        //NSTimeInterval time_zone_seconds = [[NSTimeZone localTimeZone] secondsFromGMT];
        //double local_epoch_seconds = ([epoch_microseconds doubleValue] / 1000000.0) + time_zone_seconds;
        //NSDate *newSyncTime = [NSDate dateWithTimeIntervalSince1970:local_epoch_seconds];
        //FDLogDebug(@"Received latest documents update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped documents update with invalid last_update timestamp!");
        return;
    }
    value = [documentResults objectForKey:@"my_docs"];
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *documentsArray = value;
        // load lesson groups without parent groups
        for (id documentElement in documentsArray) {
            if ([documentElement isKindOfClass:[NSDictionary class]]) {
                NSDictionary *documentDetails = documentElement;
                NSNumber *documentID = [documentDetails objectForKey:@"document_id"];
                NSString *documentName = [documentDetails objectForKey:@"document_name"];
                NSString *documentURL = [documentDetails objectForKey:@"document_url"];
                NSNumber *updated_epoch_microseconds = [documentDetails objectForKey:@"updated"];
                // check if this document exists and is updated on disk
                NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:documentsManagedObjectContext];
                [documentRequest setEntity:documentEntityDescription];
                NSPredicate *documentPredicate = [NSPredicate predicateWithFormat:@"documentID = %@ AND type==1", documentID];
                [documentRequest setPredicate:documentPredicate];
                NSArray *documentArray = [documentsManagedObjectContext executeFetchRequest:documentRequest error:&error];
                Document *document = nil;
                if (documentArray == nil) {
                    FDLogError(@"Unable to retrieve information about document with ID %@, skipping!", documentID);
                } else if (documentArray.count == 0) {
                    // add new course
                    //FDLogDebug(@"Adding new document ID %@", documentID);
                    document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:documentsManagedObjectContext];
                    document.documentID = documentID;
                    document.lastUpdate = updated_epoch_microseconds;
                    document.name = documentName;
                    document.remoteURL = documentURL;
                    document.pdfURL = nil;
                    document.downloaded = [[NSNumber alloc] initWithBool:NO];
                    document.type = @(1);
                } else if (documentArray.count == 1) {
                    document = [documentArray objectAtIndex:0];
                    if ([document.downloaded boolValue] == NO || ([document.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue])) {
                        document.name = documentName;
                        document.remoteURL = documentURL;
                        document.downloaded = [[NSNumber alloc] initWithBool:NO];
                        document.lastUpdate = updated_epoch_microseconds;
                        document.type = @(1);
                    }
                } else {
                    FDLogError(@"More than one document for document ID %@!", documentID);
                    // delete all of the existing documents with this ID (should be 1)
                    // (data model will delete all associated sub-groups, lessons, etc..)
                    for (Document *documentToDelete in documentArray) {
                        [documentsManagedObjectContext deleteObject:documentToDelete];
                    }
                }
                if (document != nil) {
                    document.lastSync = epoch_microseconds;
                }
            } else {
                FDLogError(@"Bad document result from documents query for document!");
            }
        }
    } else {
        FDLogError(@"No document array!");
    }
    value = [documentResults objectForKey:@"documents"];
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *documentsArray = value;
        for (id documentElement in documentsArray) {
            if ([documentElement isKindOfClass:[NSDictionary class]]) {
                NSDictionary *documentDetails = documentElement;
                NSNumber *documentID = [documentDetails objectForKey:@"document_id"];
                NSString *documentName = [documentDetails objectForKey:@"document_name"];
                NSString *documentURL = [documentDetails objectForKey:@"document_url"];
                NSNumber *updated_epoch_microseconds = [documentDetails objectForKey:@"updated"];
                NSNumber *groupID = [documentDetails objectForKey:@"group_id"];
                NSNumber *studentID = [documentDetails objectForKey:@"student_id"];
                if ([studentID isEqual:[NSNull null]]) {
                    studentID = userID;
                }
                //NSString *groupName = [documentDetails objectForKey:@"group_name"];
                // check if this course already exists
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:documentsManagedObjectContext];
                [request setEntity:entityDescription];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID = %@", groupID];
                [request setPredicate:predicate];
                NSArray *groupArray = [documentsManagedObjectContext executeFetchRequest:request error:&error];
                LessonGroup *group = nil;
                if (groupArray == nil || groupArray.count == 0) {
                    // no group(s) for this document
                    FDLogDebug(@"no groups for document! (documentID=%@,documentName=%@)", documentID, documentName);
                    continue;
                }
                
                // check if this document exists and is updated on disk
                NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:documentsManagedObjectContext];
                [documentRequest setEntity:documentEntityDescription];
                NSPredicate *documentPredicate = [NSPredicate predicateWithFormat:@"documentID == %@ AND type != 1 AND studentID == %@ AND groupID == %@", documentID, studentID, groupID];
                [documentRequest setPredicate:documentPredicate];
                NSArray *documentArray = [documentsManagedObjectContext executeFetchRequest:documentRequest error:&error];
                Document *document = nil;
                if (documentArray == nil) {
                    FDLogError(@"Unable to retrieve information about document with ID %@, skipping!", documentID);
                } else if (documentArray.count == 0) {
                    // add new course
                    //FDLogDebug(@"Adding new document ID %@", documentID);
                    document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:documentsManagedObjectContext];
                    document.documentID = documentID;
                    document.lastUpdate = updated_epoch_microseconds;
                    document.name = documentName;
                    document.remoteURL = documentURL;
                    document.pdfURL = nil;
                    document.downloaded = [[NSNumber alloc] initWithBool:NO];
                    document.type = @(2);
                    document.studentID = studentID;
                    document.groupID = groupID;
                } else if (documentArray.count == 1) {
                    document = [documentArray objectAtIndex:0];
                    if ([document.downloaded boolValue] == NO || ([document.lastUpdate longLongValue] < [updated_epoch_microseconds longLongValue]) || ![document.remoteURL isEqualToString:documentURL]) {
                        //FDLogDebug(@"detected document %@ out of date, updating! Last Update: %@ New Update: %lld", courseDocument.documentID, courseDocument.lastUpdate, updated_epoch_microseconds);
                        document.name = documentName;
                        document.remoteURL = documentURL;
                        document.downloaded = [[NSNumber alloc] initWithBool:NO];
                        document.lastUpdate = updated_epoch_microseconds;
                        document.type = @(2);
                    }
                } else {
                    FDLogError(@"More than one document for document ID %@!", documentID);
                    // delete all of the existing documents with this ID (should be 1)
                    // (data model will delete all associated sub-groups, lessons, etc..)
                    for (Document *documentToDelete in documentArray) {
                        [documentsManagedObjectContext deleteObject:documentToDelete];
                    }
                }
                if (document != nil) {
                    document.lastSync = epoch_microseconds;
                    // update confirmation times to the current time
                    //FDLogDebug(@"document %@ %@ %@ %@", documentID, documentName, courseDocument.downloaded, courseDocument.pdfURL);
                }
                for (group in groupArray) {
                    //FDLogDebug(@"Assigning Document to GroupID=%@,Name=%@", group.groupID, group.name);
                    // check if this document is already assigned to this course
                    //if ([document.groups containsObject:group] == NO) {
                    //    [document addGroupsObject:group];
                    //}
                    if ([group.documents containsObject:document] == NO && document != nil) {
                        [group addDocumentsObject:document];
                    }
                }
            } else {
                
                FDLogError(@"Bad document result from documents query for document!");
            }
        }
    } else {
        FDLogError(@"No document array!");
    }
    // loop through all of the documents, delete documents which were not sync'd
    
    
    NSFetchRequest *expiredDocumentRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *expiredDocumentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:documentsManagedObjectContext];
    [expiredDocumentRequest setEntity:expiredDocumentEntityDescription];
    NSPredicate *expiredDocumentPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0 AND type!= 1", epoch_microseconds];
    [expiredDocumentRequest setPredicate:expiredDocumentPredicate];
    NSArray *expiredDocumentArray = [documentsManagedObjectContext executeFetchRequest:expiredDocumentRequest error:&error];
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectoryToDelte=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (Document *documentToDelete in expiredDocumentArray) {
        [fm removeItemAtPath:[documentDirectoryToDelte stringByAppendingPathComponent:[documentToDelete.remoteURL lastPathComponent]] error:&error];
        [documentsManagedObjectContext deleteObject:documentToDelete];
    }
    if ([documentsManagedObjectContext hasChanges]) {
        [documentsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppDelegate sharedDelegate].documents_vc populateDocuments];
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
        });
    }
}
- (void)performNavLogSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performNavLogSyncCheck");
    
    NSURL *navlogURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:navlogURL];
    NSDictionary *navlogsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_navlogs", @"action", userID, @"user_id", nil];
    NSError *error;
    NSData *jsonNavLogsRequestData =[NSJSONSerialization dataWithJSONObject:navlogsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonNavLogsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonNavLogsRequestData];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *navLogTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
                [self handleNavLogsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download navlogs: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download navlogs due to unknown error!");
            }
        }
            [self performAircraftSyncCheck:apiURLString andUserID:userID];
        
    }];
    [navLogTask resume];
}
- (void)handleNavLogsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse navLogs update without being logged in!");
        return;
    }
    NSManagedObjectContext *navlogsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [navlogsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *navLogsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for navLogs data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [navLogsResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped navLog update with invalid last_update time!");
        return;
    }
    
    value = [navLogsResults objectForKey:@"navlogs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *navLogsArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseNavLogsArray:navLogsArray IntoContext:navlogsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    
    if ([navlogsManagedObjectContext hasChanges]) {
        [navlogsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].navLog_VC) {
                //[[AppDelegate sharedDelegate].navLog_VC reloadNavLogs];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseNavLogsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id navLogElement in array) {
        if ([navLogElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected navLog element which was not a dictionary!");
            continue;
        }
        NSDictionary *navLogEleFields = navLogElement;
        NSNumber *navLogID = [navLogEleFields objectForKey:@"navLogID"];
        NSNumber *navLogLocalID = [navLogEleFields objectForKey:@"navLogLocalID"];
        NSString *navLogName = [navLogEleFields objectForKey:@"navLogName"];
        NSString *aircraftNum = [navLogEleFields objectForKey:@"aircraftNum"];
        NSString *navLogDate = [navLogEleFields objectForKey:@"navLogDate"];
        NSString *casTasVal = [navLogEleFields objectForKey:@"casTasVal"];
        NSNumber *distLeg = [navLogEleFields objectForKey:@"distLeg"];
        NSNumber *fuel = [navLogEleFields objectForKey:@"fuel"];
        NSNumber *gph = [navLogEleFields objectForKey:@"gph"];
        NSString *timeOff = [navLogEleFields objectForKey:@"timeOff"];
        NSNumber *lastSync = [navLogEleFields objectForKey:@"lastSync"];
        NSNumber *lastUpdate = [navLogEleFields objectForKey:@"lastUpdate"];
        NSString *notes = [navLogEleFields objectForKey:@"notes"];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogID = %@", navLogID];
        [request setPredicate:predicate];
        NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
        
        NavLog *navLog = nil;
        if (fetchedNavLogs == nil) {
            FDLogError(@"Skipped quiz update since there was an error checking for existing quizes!");
        } else if (fetchedNavLogs.count == 0) {
            
            navLog = [NSEntityDescription insertNewObjectForEntityForName:@"NavLog" inManagedObjectContext:context];
            navLog.navLogID = navLogID;
            navLog.navLogLocalID = navLogLocalID;
            navLog.aircraftNum = aircraftNum;
            navLog.casTasVal = casTasVal;
            navLog.distLeg = distLeg;
            navLog.fuel =fuel;
            navLog.gph = gph;
            navLog.navLogDate  =navLogDate;
            navLog.navLogName = navLogName;
            navLog.notes = notes;
            navLog.timeOff = timeOff;
            navLog.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            navLog.lastUpdate = epochMicros;
            
            if ([navLogEleFields objectForKey:@"navLogRecords"] && [[navLogEleFields objectForKey:@"navLogRecords"] count] > 0) {
                for (NSDictionary *dict in [navLogEleFields objectForKey:@"navLogRecords"]) {
                    NavLogRecord *navLogRecord = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
                    navLogRecord.navLogRecordID = [dict objectForKey:@"navLogRecordID"];
                    navLogRecord.navLogID = [dict objectForKey:@"navLogID"];
                    navLogRecord.attitude = [dict objectForKey:@"attitude"];
                    navLogRecord.casTas = [dict objectForKey:@"casTas"];
                    navLogRecord.ch = [dict objectForKey:@"ch"];
                    navLogRecord.checkPoint = [dict objectForKey:@"checkPoint"];
                    navLogRecord.course = [dict objectForKey:@"course"];
                    navLogRecord.dev = [dict objectForKey:@"dev"];
                    navLogRecord.distLeg = [dict objectForKey:@"distLeg"];
                    navLogRecord.distRem = [dict objectForKey:@"distRem"];
                    navLogRecord.fuelATA = [dict objectForKey:@"fuelATA"];
                    navLogRecord.fuelETA = [dict objectForKey:@"fuelETA"];
                    navLogRecord.gphFuel = [dict objectForKey:@"gphFuel"];
                    navLogRecord.gphRem = [dict objectForKey:@"gphRem"];
                    navLogRecord.gsAct = [dict objectForKey:@"gsAct"];
                    navLogRecord.gsEst = [dict objectForKey:@"gsEst"];
                    navLogRecord.lrWca = [dict objectForKey:@"lrWca"];
                    navLogRecord.lwVar = [dict objectForKey:@"lwVar"];
                    navLogRecord.mh = [dict objectForKey:@"mh"];
                    navLogRecord.tc = [dict objectForKey:@"tc"];
                    navLogRecord.th = [dict objectForKey:@"th"];
                    navLogRecord.timeOffATE = [dict objectForKey:@"timeOffATE"];
                    navLogRecord.timeOffETE = [dict objectForKey:@"timeOffETE"];
                    navLogRecord.vorFreq = [dict objectForKey:@"vorFreq"];
                    navLogRecord.vorIdent = [dict objectForKey:@"vorIdent"];
                    navLogRecord.vorFrom = [dict objectForKey:@"vorFrom"];
                    navLogRecord.vorTo = [dict objectForKey:@"vorTo"];
                    navLogRecord.windDir = [dict objectForKey:@"windDir"];
                    navLogRecord.windTemp = [dict objectForKey:@"windTemp"];
                    navLogRecord.windVel = [dict objectForKey:@"windvel"];
                    navLogRecord.ordering = [dict objectForKey:@"ordering"];
                    [navLog addNavLogRecordsObject:navLogRecord];
                }
            }
            requireRepopulate = YES;
        } else if (fetchedNavLogs.count == 1) {
            navLog = [fetchedNavLogs objectAtIndex:0];
            if ([navLog.lastSync longLongValue] < [lastSync longLongValue]) {
                navLog.navLogID = navLogID;
                navLog.navLogLocalID = navLogLocalID;
                navLog.aircraftNum = aircraftNum;
                navLog.casTasVal = casTasVal;
                navLog.distLeg = distLeg;
                navLog.fuel =fuel;
                navLog.gph = gph;
                navLog.navLogDate  =navLogDate;
                navLog.navLogName = navLogName;
                navLog.notes = notes;
                navLog.timeOff = timeOff;
                navLog.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                navLog.lastUpdate = epochMicros;
                if ([navLogEleFields objectForKey:@"navLogRecords"] && [[navLogEleFields objectForKey:@"navLogRecords"] count] > 0) {
                    for (NSDictionary *dict in [navLogEleFields objectForKey:@"navLogRecords"]) {
                        NavLogRecord *navLogRecordToCheck = nil;
                        for (int i = 0; i < navLog.navLogRecords.count; i ++) {
                            NavLogRecord *nlRec = [navLog.navLogRecords objectAtIndex:i];
                            if ([nlRec.ordering integerValue] == [[dict objectForKey:@"ordering"] integerValue] && [nlRec.navLogRecordID integerValue] == [[dict objectForKey:@"navLogRecordID"] integerValue]) {
                                navLogRecordToCheck = nlRec;
                            }
                        }
                        if (navLogRecordToCheck != nil) {
                            navLogRecordToCheck.navLogRecordID = [dict objectForKey:@"navLogRecordID"];
                            navLogRecordToCheck.navLogID = [dict objectForKey:@"navLogID"];
                            navLogRecordToCheck.attitude = [dict objectForKey:@"attitude"];
                            navLogRecordToCheck.casTas = [dict objectForKey:@"casTas"];
                            navLogRecordToCheck.ch = [dict objectForKey:@"ch"];
                            navLogRecordToCheck.checkPoint = [dict objectForKey:@"checkPoint"];
                            navLogRecordToCheck.course = [dict objectForKey:@"course"];
                            navLogRecordToCheck.dev = [dict objectForKey:@"dev"];
                            navLogRecordToCheck.distLeg = [dict objectForKey:@"distLeg"];
                            navLogRecordToCheck.distRem = [dict objectForKey:@"distRem"];
                            navLogRecordToCheck.fuelATA = [dict objectForKey:@"fuelATA"];
                            navLogRecordToCheck.fuelETA = [dict objectForKey:@"fuelETA"];
                            navLogRecordToCheck.gphFuel = [dict objectForKey:@"gphFuel"];
                            navLogRecordToCheck.gphRem = [dict objectForKey:@"gphRem"];
                            navLogRecordToCheck.gsAct = [dict objectForKey:@"gsAct"];
                            navLogRecordToCheck.gsEst = [dict objectForKey:@"gsEst"];
                            navLogRecordToCheck.lrWca = [dict objectForKey:@"lrWca"];
                            navLogRecordToCheck.lwVar = [dict objectForKey:@"lwVar"];
                            navLogRecordToCheck.mh = [dict objectForKey:@"mh"];
                            navLogRecordToCheck.tc = [dict objectForKey:@"tc"];
                            navLogRecordToCheck.th = [dict objectForKey:@"th"];
                            navLogRecordToCheck.timeOffATE = [dict objectForKey:@"timeOffATE"];
                            navLogRecordToCheck.timeOffETE = [dict objectForKey:@"timeOffETE"];
                            navLogRecordToCheck.vorFreq = [dict objectForKey:@"vorFreq"];
                            navLogRecordToCheck.vorIdent = [dict objectForKey:@"vorIdent"];
                            navLogRecordToCheck.vorFrom = [dict objectForKey:@"vorFrom"];
                            navLogRecordToCheck.vorTo = [dict objectForKey:@"vorTo"];
                            navLogRecordToCheck.windDir = [dict objectForKey:@"windDir"];
                            navLogRecordToCheck.windTemp = [dict objectForKey:@"windTemp"];
                            navLogRecordToCheck.windVel = [dict objectForKey:@"windVel"];
                            navLogRecordToCheck.ordering = [dict objectForKey:@"ordering"];
                        }else{
                            navLogRecordToCheck = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
                            navLogRecordToCheck.navLogRecordID = [dict objectForKey:@"navLogRecordID"];
                            navLogRecordToCheck.navLogID = [dict objectForKey:@"navLogID"];
                            navLogRecordToCheck.attitude = [dict objectForKey:@"attitude"];
                            navLogRecordToCheck.casTas = [dict objectForKey:@"casTas"];
                            navLogRecordToCheck.ch = [dict objectForKey:@"ch"];
                            navLogRecordToCheck.checkPoint = [dict objectForKey:@"checkPoint"];
                            navLogRecordToCheck.course = [dict objectForKey:@"course"];
                            navLogRecordToCheck.dev = [dict objectForKey:@"dev"];
                            navLogRecordToCheck.distLeg = [dict objectForKey:@"distLeg"];
                            navLogRecordToCheck.distRem = [dict objectForKey:@"distRem"];
                            navLogRecordToCheck.fuelATA = [dict objectForKey:@"fuelATA"];
                            navLogRecordToCheck.fuelETA = [dict objectForKey:@"fuelETA"];
                            navLogRecordToCheck.gphFuel = [dict objectForKey:@"gphFuel"];
                            navLogRecordToCheck.gphRem = [dict objectForKey:@"gphRem"];
                            navLogRecordToCheck.gsAct = [dict objectForKey:@"gsAct"];
                            navLogRecordToCheck.gsEst = [dict objectForKey:@"gsEst"];
                            navLogRecordToCheck.lrWca = [dict objectForKey:@"lrWca"];
                            navLogRecordToCheck.lwVar = [dict objectForKey:@"lwVar"];
                            navLogRecordToCheck.mh = [dict objectForKey:@"mh"];
                            navLogRecordToCheck.tc = [dict objectForKey:@"tc"];
                            navLogRecordToCheck.th = [dict objectForKey:@"th"];
                            navLogRecordToCheck.timeOffATE = [dict objectForKey:@"timeOffATE"];
                            navLogRecordToCheck.timeOffETE = [dict objectForKey:@"timeOffETE"];
                            navLogRecordToCheck.vorFreq = [dict objectForKey:@"vorFreq"];
                            navLogRecordToCheck.vorIdent = [dict objectForKey:@"vorIdent"];
                            navLogRecordToCheck.vorFrom = [dict objectForKey:@"vorFrom"];
                            navLogRecordToCheck.vorTo = [dict objectForKey:@"vorTo"];
                            navLogRecordToCheck.windDir = [dict objectForKey:@"windDir"];
                            navLogRecordToCheck.windTemp = [dict objectForKey:@"windTemp"];
                            navLogRecordToCheck.windVel = [dict objectForKey:@"windVel"];
                            navLogRecordToCheck.ordering = [dict objectForKey:@"ordering"];
                            [navLog addNavLogRecordsObject:navLogRecordToCheck];
                        }
                    }
                }
                
                requireRepopulate = YES;
            }
        } else if (fetchedNavLogs.count > 1) {
            for (NavLog *navLogToDelete in fetchedNavLogs) {
                for (NavLogRecord *navlogRecordToDelete in navLogToDelete.navLogRecords) {
                    [context deleteObject:navlogRecordToDelete];
                }
                [context deleteObject:navLogToDelete];
            }
            navLog = [NSEntityDescription insertNewObjectForEntityForName:@"NavLog" inManagedObjectContext:context];
            navLog.navLogID = navLogID;
            navLog.navLogLocalID = navLogLocalID;
            navLog.aircraftNum = aircraftNum;
            navLog.casTasVal = casTasVal;
            navLog.distLeg = distLeg;
            navLog.fuel =fuel;
            navLog.gph = gph;
            navLog.navLogDate  =navLogDate;
            navLog.navLogName = navLogName;
            navLog.notes = notes;
            navLog.timeOff = timeOff;
            navLog.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            navLog.lastUpdate = epochMicros;
            if ([navLogEleFields objectForKey:@"navLogRecords"] && [[navLogEleFields objectForKey:@"navLogRecords"] count] > 0) {
                for (NSDictionary *dict in [navLogEleFields objectForKey:@"navLogRecords"]) {
                    NavLogRecord *navLogRecord = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
                    navLogRecord.navLogRecordID = [dict objectForKey:@"navLogRecordID"];
                    navLogRecord.navLogID = [dict objectForKey:@"navLogID"];
                    navLogRecord.attitude = [dict objectForKey:@"attitude"];
                    navLogRecord.casTas = [dict objectForKey:@"casTas"];
                    navLogRecord.ch = [dict objectForKey:@"ch"];
                    navLogRecord.checkPoint = [dict objectForKey:@"checkPoint"];
                    navLogRecord.course = [dict objectForKey:@"course"];
                    navLogRecord.dev = [dict objectForKey:@"dev"];
                    navLogRecord.distLeg = [dict objectForKey:@"distLeg"];
                    navLogRecord.distRem = [dict objectForKey:@"distRem"];
                    navLogRecord.fuelATA = [dict objectForKey:@"fuelATA"];
                    navLogRecord.fuelETA = [dict objectForKey:@"fuelETA"];
                    navLogRecord.gphFuel = [dict objectForKey:@"gphFuel"];
                    navLogRecord.gphRem = [dict objectForKey:@"gphRem"];
                    navLogRecord.gsAct = [dict objectForKey:@"gsAct"];
                    navLogRecord.gsEst = [dict objectForKey:@"gsEst"];
                    navLogRecord.lrWca = [dict objectForKey:@"lrWca"];
                    navLogRecord.lwVar = [dict objectForKey:@"lwVar"];
                    navLogRecord.mh = [dict objectForKey:@"mh"];
                    navLogRecord.tc = [dict objectForKey:@"tc"];
                    navLogRecord.th = [dict objectForKey:@"th"];
                    navLogRecord.timeOffATE = [dict objectForKey:@"timeOffATE"];
                    navLogRecord.timeOffETE = [dict objectForKey:@"timeOffETE"];
                    navLogRecord.vorFreq = [dict objectForKey:@"vorFreq"];
                    navLogRecord.vorIdent = [dict objectForKey:@"vorIdent"];
                    navLogRecord.vorFrom = [dict objectForKey:@"vorFrom"];
                    navLogRecord.vorTo = [dict objectForKey:@"vorTo"];
                    navLogRecord.windDir = [dict objectForKey:@"windDir"];
                    navLogRecord.windTemp = [dict objectForKey:@"windTemp"];
                    navLogRecord.windVel = [dict objectForKey:@"windVel"];
                    navLogRecord.ordering = [dict objectForKey:@"ordering"];
                    [navLog addNavLogRecordsObject:navLogRecord];
                }
            }
            requireRepopulate = YES;
        }
        if (navLog != nil) {
            navLog.lastSync = epochMicros;
        }
    }
    // loop through lesson groups, delete any that have not been synced
    NSFetchRequest *expiredNavLogRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
    [expiredNavLogRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredNavLogRequest setPredicate:predicate];
    NSArray *expiredNavLogs = [context executeFetchRequest:expiredNavLogRequest error:&error];
    if (expiredNavLogs != nil && expiredNavLogs.count > 0) {
        for (NavLog *navLogToDelete in expiredNavLogs) {
            for (NavLogRecord *navlogRecordToDelete in navLogToDelete.navLogRecords) {
                [context deleteObject:navlogRecordToDelete];
            }
            [context deleteObject:navLogToDelete];
        }
        
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performAircraftSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performAircraftSyncCheck");
    
    NSURL *aircraftURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aircraftURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *aircraftRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"aircrafts", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonAircraftsRequestData =[NSJSONSerialization dataWithJSONObject:aircraftRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonAircraftsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonAircraftsRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *lessonsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
                [self handleAircraftsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download lessons: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download lessons due to unknown error!");
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].trainingHud != nil) {
                [AppDelegate sharedDelegate].trainingHud.label.text = [NSString stringWithFormat:@"User Added to %@", [AppDelegate sharedDelegate].programName];
                [[AppDelegate sharedDelegate].trainingHud hideAnimated:YES];
                [AppDelegate sharedDelegate].trainingHud = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_FIND_INSTRUCTOR object:nil userInfo:nil];
            }
        });
        [self performMaintenanceLogsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [lessonsTask resume];
}
- (void)handleAircraftsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse aircraft update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *aircraftsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [aircraftsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *aircraftResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for lesson data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [aircraftResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped aircraft update with invalid last_update time!");
        return;
    }
    
    value = [aircraftResults objectForKey:@"aircrafts"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *aircraftsArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseAircraftsArray:aircraftsArray IntoContext:aircraftsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    
    if ([aircraftsManagedObjectContext hasChanges]) {
        [aircraftsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppDelegate sharedDelegate].aircraft_vc reloadData];
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_AIRCRAFT_BADGE object:nil userInfo:nil];
        });
    }
    
}
- (BOOL)parseAircraftsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id aircraftsElement in array) {
        if ([aircraftsElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected aircraft element which was not a dictionary!");
            continue;
        }
        NSDictionary *aircraftsFields = aircraftsElement;
        // TODO: add lastSync datetime
        NSNumber *aircraftID = [aircraftsFields objectForKey:@"aircraftID"];
        NSNumber *aircraft_local_id = [aircraftsFields objectForKey:@"aircraft_local_id"];
        NSString *aircraftItems = [aircraftsFields objectForKey:@"aircraftItems"];
        NSString *avoinicsItems = [aircraftsFields objectForKey:@"avoinicsItems"];
        NSString *lifeLimitedParts = [aircraftsFields objectForKey:@"lifeLimitedParts"];
        NSString *maintenanceItems = [aircraftsFields objectForKey:@"maintenanceItems"];
        NSString *otherItems = [aircraftsFields objectForKey:@"otherItems"];
        NSString *squawkItems = [aircraftsFields objectForKey:@"squawkItems"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aircraftID == %@", aircraftID];
        [request setPredicate:predicate];
        NSArray *fetchedAircrafts = [context executeFetchRequest:request error:&error];
        Aircraft *aircraft = nil;
        if (fetchedAircrafts == nil) {
            FDLogError(@"Skipped aircraft update since there was an error checking for existing aircraft!");
        } else if (fetchedAircrafts.count == 0) {
            
            aircraft = [NSEntityDescription insertNewObjectForEntityForName:@"Aircraft" inManagedObjectContext:context];
            aircraft.aircraftID = aircraftID;
            aircraft.aircraftItems = aircraftItems;
            aircraft.maintenanceItems = maintenanceItems;
            aircraft.avionicsItems = avoinicsItems;
            aircraft.liftLimitedParts = lifeLimitedParts;
            aircraft.otherItems = otherItems;
            aircraft.squawksItems = squawkItems;
            aircraft.lastUpdate = epochMicros;
            aircraft.valueForSort = epochMicros;
            aircraft.aircraft_local_id = aircraft_local_id;
            
            requireRepopulate = YES;
        } else if (fetchedAircrafts.count == 1) {
            // check if the group has been updated
            aircraft = [fetchedAircrafts objectAtIndex:0];
            aircraft.aircraftItems = aircraftItems;
            aircraft.maintenanceItems = maintenanceItems;
            aircraft.avionicsItems = avoinicsItems;
            aircraft.liftLimitedParts = lifeLimitedParts;
            aircraft.otherItems = otherItems;
            aircraft.squawksItems = squawkItems;
            aircraft.lastUpdate = epochMicros;
        } else if (fetchedAircrafts.count > 1) {
            
            for (Aircraft *aircraftToDelete in fetchedAircrafts) {
                [context deleteObject:aircraftToDelete];
            }
            aircraft = [NSEntityDescription insertNewObjectForEntityForName:@"Aircraft" inManagedObjectContext:context];
            aircraft.aircraftID = aircraftID;
            aircraft.aircraftItems = aircraftItems;
            aircraft.maintenanceItems = maintenanceItems;
            aircraft.avionicsItems = avoinicsItems;
            aircraft.liftLimitedParts = lifeLimitedParts;
            aircraft.otherItems = otherItems;
            aircraft.squawksItems = squawkItems;
            aircraft.lastUpdate = epochMicros;
            aircraft.aircraft_local_id = aircraft_local_id;
            
            requireRepopulate = YES;
        }
        if (aircraft != nil) {
            aircraft.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredAircrafts = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredAircrafts != nil && expiredAircrafts.count > 0) {
        for (Aircraft *aircraftToDelete in expiredAircrafts) {
            [context deleteObject:aircraftToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performMaintenanceLogsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performMaintenanceLogsSyncCheck");
    
    NSURL *maintenanceLogsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:maintenanceLogsURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *maintenanceLogsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_maintenanceLogs", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonMaintenanceLogsRequestData =[NSJSONSerialization dataWithJSONObject:maintenanceLogsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonMaintenanceLogsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonMaintenanceLogsRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *maintenanceLogsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleMaintenanceLogsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download recordsfiles: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download recordsfiles due to unknown error!");
            }
        }
        
        [self performCheckListsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [maintenanceLogsTask resume];
}
- (void)handleMaintenanceLogsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse MaintenanceLogs update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *maintenanceLogsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [maintenanceLogsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *maintenanceLogsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for MaintenanceLogs data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [maintenanceLogsResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped MaintenanceLogs update with invalid last_update time!");
        return;
    }
    
    value = [maintenanceLogsResults objectForKey:@"maintenanceLogs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *maintenanceLogssArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseMaintenanceLogssArray:maintenanceLogssArray IntoContext:maintenanceLogsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    if ([maintenanceLogsManagedObjectContext hasChanges]) {
        [maintenanceLogsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppDelegate sharedDelegate].aircraft_vc reloadData];
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_AIRCRAFT_BADGE object:nil userInfo:nil];
        });
    }
    
}
- (BOOL)parseMaintenanceLogssArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id maintenanceLogssElement in array) {
        if ([maintenanceLogssElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected maintenanceLogs element which was not a dictionary!");
            continue;
        }
        NSDictionary *maintenanceLogssFields = maintenanceLogssElement;
        // TODO: add lastSync datetime
        NSNumber *maintenance_id = [maintenanceLogssFields objectForKey:@"maintenance_id"];
        NSString *fileUrl = [maintenanceLogssFields objectForKey:@"file_url"];
        NSString *fileName = [maintenanceLogssFields objectForKey:@"file_name"];
        NSNumber *aircraft_local_id = [maintenanceLogssFields objectForKey:@"aircraft_local_id"];
        NSString *fileSize = [maintenanceLogssFields objectForKey:@"fileSize"];
        NSString *fileType = [maintenanceLogssFields objectForKey:@"fileType"];
        NSString *thumbUrl = [maintenanceLogssFields objectForKey:@"thumb_url"];
        NSNumber *recordsLocalID = [maintenanceLogssFields objectForKey:@"recordsLocal_id"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"maintenancelog_id == %@", maintenance_id];
        [request setPredicate:predicate];
        NSArray *fetchedmaintenanceLogss = [context executeFetchRequest:request error:&error];
        MaintenanceLogs *maintenanceLogs = nil;
        if (fetchedmaintenanceLogss == nil) {
            FDLogError(@"Skipped maintenanceLogs update since there was an error checking for existing maintenanceLogs!");
        } else if (fetchedmaintenanceLogss.count == 0) {
            maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:context];
            maintenanceLogs.maintenancelog_id = maintenance_id;
            maintenanceLogs.file_url = fileUrl;
            maintenanceLogs.file_name = fileName;
            maintenanceLogs.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            maintenanceLogs.aircraft_local_id = aircraft_local_id;
            maintenanceLogs.lastUpdate = epochMicros;
            maintenanceLogs.fileSize = fileSize;
            maintenanceLogs.fileType = fileType;
            maintenanceLogs.thumb_url = thumbUrl;
            maintenanceLogs.recordsLocal_id = recordsLocalID;
            maintenanceLogs.isUploaded = @1;
            requireRepopulate = YES;
        } else if (fetchedmaintenanceLogss.count == 1) {
            // check if the group has been updated
            maintenanceLogs = [fetchedmaintenanceLogss objectAtIndex:0];
            maintenanceLogs.file_url = fileUrl;
            maintenanceLogs.file_name = fileName;
            maintenanceLogs.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            maintenanceLogs.aircraft_local_id = aircraft_local_id;
            maintenanceLogs.lastUpdate = epochMicros;
            maintenanceLogs.fileSize = fileSize;
            maintenanceLogs.fileType = fileType;
            maintenanceLogs.thumb_url = thumbUrl;
            maintenanceLogs.recordsLocal_id = recordsLocalID;
            maintenanceLogs.isUploaded = @1;
        } else if (fetchedmaintenanceLogss.count > 1) {
            
            for (MaintenanceLogs *maintenanceLogsToDelete in fetchedmaintenanceLogss) {
                [context deleteObject:maintenanceLogsToDelete];
            }
            maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:context];
            maintenanceLogs.maintenancelog_id = maintenance_id;
            maintenanceLogs.file_url = fileUrl;
            maintenanceLogs.file_name = fileName;
            maintenanceLogs.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            maintenanceLogs.aircraft_local_id = aircraft_local_id;
            maintenanceLogs.lastUpdate = epochMicros;
            maintenanceLogs.fileSize = fileSize;
            maintenanceLogs.fileType = fileType;
            maintenanceLogs.thumb_url = thumbUrl;
            maintenanceLogs.recordsLocal_id = recordsLocalID;
            maintenanceLogs.isUploaded = @1;
            
            requireRepopulate = YES;
        }
        if (maintenanceLogs != nil) {
            maintenanceLogs.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredmaintenanceLogss = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredmaintenanceLogss != nil && expiredmaintenanceLogss.count > 0) {
        for (MaintenanceLogs *maintenanceLogsToDelete in expiredmaintenanceLogss) {
            [context deleteObject:maintenanceLogsToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performCheckListsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    NSURL *checklistURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:checklistURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    NSDictionary *checklistsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_checklist", @"action", type, @"user_type",  userID, @"user_id", nil];
    NSError *error;
    NSData *jsonChecklistRequestData =[NSJSONSerialization dataWithJSONObject:checklistsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonChecklistRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonChecklistRequestData];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *checklistsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        if (data != nil) {
                [self handleChecklistsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download Quizes: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download Quizes due to unknown error!");
            }
        }
        [self performUsersSyncCheck:apiURLString andUserID:userID];
    }];
    [checklistsTask resume];
}
- (void)handleChecklistsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse checklists update without being logged in!");
        return;
    }
    NSManagedObjectContext *checklistsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [checklistsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *checklistsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for checklists data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [checklistsResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped checklists update with invalid last_update time!");
        return;
    }
    
    value = [checklistsResults objectForKey:@"checklists"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected checklists element which was not an array!");
        return;
    }
    NSArray *checklistsArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseChecklistsArray:checklistsArray IntoContext:checklistsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    
    if ([checklistsManagedObjectContext hasChanges]) {
        [checklistsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].navLog_VC) {
                //[[AppDelegate sharedDelegate].navLog_VC reloadNavLogs];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseChecklistsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id checklistsElement in array) {
        if ([checklistsElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected checklists element which was not a dictionary!");
            continue;
        }
        NSDictionary *checklistEleFields = checklistsElement;
        NSNumber *checklistID = [checklistEleFields objectForKey:@"checklist_id"];
        NSString *category = [checklistEleFields objectForKey:@"category"];
        NSString *groupchecklist = [checklistEleFields objectForKey:@"groupchecklist"];
        NSString *checklistStr = [checklistEleFields objectForKey:@"checklist"];
        NSNumber *currentChecklistUserID = [checklistEleFields objectForKey:@"user_id"];
        NSNumber *parentChecklistID = [checklistEleFields objectForKey:@"parent_checklist_id"];
        NSNumber *lastSync = [checklistEleFields objectForKey:@"lastSync"];
        NSNumber *lastUpdate = [checklistEleFields objectForKey:@"lastUpdate"];
        NSNumber *checklistLocalID = [checklistEleFields objectForKey:@"checklist_localID"];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"checklistsID = %@", checklistID];
        [request setPredicate:predicate];
        NSArray *fetchedChecklists = [context executeFetchRequest:request error:&error];
        
        Checklists *checklistEntity = nil;
        if (fetchedChecklists == nil) {
            FDLogError(@"Skipped checklists update since there was an error checking for existing checklists!");
        } else if (fetchedChecklists.count == 0) {
            
            checklistEntity = [NSEntityDescription insertNewObjectForEntityForName:@"Checklists" inManagedObjectContext:context];
            checklistEntity.checklistsID = checklistID;
            checklistEntity.category = category;
            checklistEntity.groupChecklist = groupchecklist;
            checklistEntity.checklist = checklistStr;
            checklistEntity.warning = @"";
            checklistEntity.userID = currentChecklistUserID;
            checklistEntity.parentChecklistsID = parentChecklistID;
            checklistEntity.lastUpdate = epochMicros;
            checklistEntity.checklistsLocalId = checklistLocalID;
            
            if ([checklistEleFields objectForKey:@"checklistcontents"] && [[checklistEleFields objectForKey:@"checklistcontents"] count] > 0 && [parentChecklistID integerValue] != 0) {
                for (NSDictionary *dict in [checklistEleFields objectForKey:@"checklistcontents"]) {
                    
                    ChecklistsContent *checklistContent = [NSEntityDescription insertNewObjectForEntityForName:@"ChecklistsContent" inManagedObjectContext:context];
                    checklistContent.checklistContentID = [dict objectForKey:@"checklist_content_id"];
                    checklistContent.isChecked = [dict objectForKey:@"isChecked"];
                    checklistContent.content = [dict objectForKey:@"content"];
                    checklistContent.contentTail = [dict objectForKey:@"content_tail"];
                    checklistContent.checklistID = [dict objectForKey:@"checklistID"];
                    checklistContent.ordering = [dict objectForKey:@"ordering"];
                    checklistContent.type = [dict objectForKey:@"type"];
                    
                    [checklistEntity addChecklistsObject:checklistContent];
                }
            }
            requireRepopulate = YES;
        } else if (fetchedChecklists.count == 1) {
            checklistEntity = [fetchedChecklists objectAtIndex:0];
            if ([checklistEntity.lastSync longLongValue] < [lastSync longLongValue]) {
                checklistEntity.checklistsID = checklistID;
                checklistEntity.category = category;
                checklistEntity.groupChecklist = groupchecklist;
                checklistEntity.checklist = checklistStr;
                checklistEntity.warning = @"";
                checklistEntity.userID = currentChecklistUserID;
                checklistEntity.parentChecklistsID = parentChecklistID;
                checklistEntity.lastUpdate = epochMicros;
                checklistEntity.checklistsLocalId = checklistLocalID;
                
                if ([checklistEleFields objectForKey:@"checklistcontents"] && [[checklistEleFields objectForKey:@"checklistcontents"] count] > 0 && [parentChecklistID integerValue] != 0) {
                    for (NSDictionary *dict in [checklistEleFields objectForKey:@"checklistcontents"]) {
                        ChecklistsContent *checklistsContentToCheck = nil;
                        for (int i = 0; i < checklistEntity.checklists .count; i ++) {
                            ChecklistsContent *nlRec = [checklistEntity.checklists objectAtIndex:i];
                            if ([nlRec.ordering integerValue] == [[dict objectForKey:@"ordering"] integerValue] && [nlRec.checklistContentID integerValue] == [[dict objectForKey:@"checklist_content_id"] integerValue]) {
                                checklistsContentToCheck = nlRec;
                            }
                        }
                        if (checklistsContentToCheck != nil) {
                            checklistsContentToCheck.checklistContentID = [dict objectForKey:@"checklist_content_id"];
                            checklistsContentToCheck.isChecked = [dict objectForKey:@"isChecked"];
                            checklistsContentToCheck.content = [dict objectForKey:@"content"];
                            checklistsContentToCheck.contentTail = [dict objectForKey:@"content_tail"];
                            checklistsContentToCheck.checklistID = [dict objectForKey:@"checklistID"];
                            checklistsContentToCheck.ordering = [dict objectForKey:@"ordering"];
                            checklistsContentToCheck.type = [dict objectForKey:@"type"];
                        }else{
                            checklistsContentToCheck = [NSEntityDescription insertNewObjectForEntityForName:@"ChecklistsContent" inManagedObjectContext:context];
                            checklistsContentToCheck.checklistContentID = [dict objectForKey:@"checklist_content_id"];
                            checklistsContentToCheck.isChecked = [dict objectForKey:@"isChecked"];
                            checklistsContentToCheck.content = [dict objectForKey:@"content"];
                            checklistsContentToCheck.contentTail = [dict objectForKey:@"content_tail"];
                            checklistsContentToCheck.checklistID = [dict objectForKey:@"checklistID"];
                            checklistsContentToCheck.ordering = [dict objectForKey:@"ordering"];
                            checklistsContentToCheck.type = [dict objectForKey:@"type"];
                            [checklistEntity addChecklistsObject:checklistsContentToCheck];
                        }
                    }
                }
                
                requireRepopulate = YES;
            }
        } else if (fetchedChecklists.count > 1) {
            for (Checklists *checklistsToDelete in fetchedChecklists) {
                for (ChecklistsContent *checklistsContentToDelete in checklistsToDelete.checklists) {
                    [context deleteObject:checklistsContentToDelete];
                }
                [context deleteObject:checklistsToDelete];
            }
            checklistEntity = [NSEntityDescription insertNewObjectForEntityForName:@"Checklists" inManagedObjectContext:context];
            checklistEntity.checklistsID = checklistID;
            checklistEntity.category = category;
            checklistEntity.groupChecklist = groupchecklist;
            checklistEntity.checklist = checklistStr;
            checklistEntity.warning = @"";
            checklistEntity.userID = currentChecklistUserID;
            checklistEntity.parentChecklistsID = parentChecklistID;
            checklistEntity.lastUpdate = epochMicros;
            checklistEntity.checklistsLocalId = checklistLocalID;
            
            if ([checklistEleFields objectForKey:@"checklistcontents"] && [[checklistEleFields objectForKey:@"checklistcontents"] count] > 0 && [parentChecklistID integerValue] != 0) {
                for (NSDictionary *dict in [checklistEleFields objectForKey:@"checklistcontents"]) {
                    
                    ChecklistsContent *checklistContent = [NSEntityDescription insertNewObjectForEntityForName:@"ChecklistsContent" inManagedObjectContext:context];
                    checklistContent.checklistContentID = [dict objectForKey:@"checklist_content_id"];
                    checklistContent.isChecked = [dict objectForKey:@"isChecked"];
                    checklistContent.content = [dict objectForKey:@"content"];
                    checklistContent.contentTail = [dict objectForKey:@"content_tail"];
                    checklistContent.checklistID = [dict objectForKey:@"checklistID"];
                    checklistContent.ordering = [dict objectForKey:@"ordering"];
                    checklistContent.type = [dict objectForKey:@"type"];
                    
                    [checklistEntity addChecklistsObject:checklistContent];
                }
            }
            requireRepopulate = YES;
        }
        if (checklistEntity != nil) {
            checklistEntity.lastSync = epochMicros;
        }
    }
    // loop through checklists, delete any that have not been synced
    NSFetchRequest *expiredChecklistsRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:context];
    [expiredChecklistsRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredChecklistsRequest setPredicate:predicate];
    NSArray *expiredChecklists = [context executeFetchRequest:expiredChecklistsRequest error:&error];
    if (expiredChecklists != nil && expiredChecklists.count > 0) {
        for (Checklists *checklistEntityToDelete in expiredChecklists) {
            for (ChecklistsContent *checklistsContentToDelete in checklistEntityToDelete.checklists) {
                [context deleteObject:checklistsContentToDelete];
            }
            [context deleteObject:checklistEntityToDelete];
        }
        
        requireRepopulate = YES;
    }
    return requireRepopulate;
    
}
- (void)performRecordsFileSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performRecordsFileSyncCheck");
    
    NSURL *recordsFileURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:recordsFileURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *recordsFileRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_recordsfiles", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonRecordsFileRequestData =[NSJSONSerialization dataWithJSONObject:recordsFileRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRecordsFileRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRecordsFileRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *recordsFileTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleRecordsFileUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download recordsfiles: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download recordsfiles due to unknown error!");
            }
        }
        
        
        [self performGeneralContentSyncCheck:apiURLString andUserID:userID];
    }];
    [recordsFileTask resume];
}
- (void)handleRecordsFileUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse RecordsFile update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *recordsFileManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [recordsFileManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *recordsFileResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for RecordsFile data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [recordsFileResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped RecordsFile update with invalid last_update time!");
        return;
    }
    
    value = [recordsFileResults objectForKey:@"records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *recordsFilesArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseRecordsFilesArray:recordsFilesArray IntoContext:recordsFileManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    if ([recordsFileManagedObjectContext hasChanges]) {
        [recordsFileManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].recordsfile_VC) {
                [[AppDelegate sharedDelegate].recordsfile_VC reloadUsersAndFiles];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseRecordsFilesArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id recordsFilesElement in array) {
        if ([recordsFilesElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected recordsFile element which was not a dictionary!");
            continue;
        }
        NSDictionary *recordsFilesFields = recordsFilesElement;
        // TODO: add lastSync datetime
        NSNumber *recordsFileID = [recordsFilesFields objectForKey:@"records_id"];
        NSString *fileUrl = [recordsFilesFields objectForKey:@"file_url"];
        NSString *fileName = [recordsFilesFields objectForKey:@"file_name"];
        NSNumber *studentID = [recordsFilesFields objectForKey:@"student_id"];
        NSString *fileSize = [recordsFilesFields objectForKey:@"fileSize"];
        NSString *fileType = [recordsFilesFields objectForKey:@"fileType"];
        NSString *thumbUrl = [recordsFilesFields objectForKey:@"thumb_url"];
        NSNumber *recordsLocalID = [recordsFilesFields objectForKey:@"recordsLocal_id"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"records_id == %@", recordsFileID];
        [request setPredicate:predicate];
        NSArray *fetchedrecordsFiles = [context executeFetchRequest:request error:&error];
        RecordsFile *recordsFile = nil;
        if (fetchedrecordsFiles == nil) {
            FDLogError(@"Skipped recordsFile update since there was an error checking for existing recordsFile!");
        } else if (fetchedrecordsFiles.count == 0) {
            recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
            recordsFile.records_id = recordsFileID;
            recordsFile.file_url = fileUrl;
            recordsFile.file_name = fileName;
            recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            recordsFile.student_id = studentID;
            recordsFile.lastUpdate = epochMicros;
            recordsFile.fileSize = fileSize;
            recordsFile.fileType = fileType;
            recordsFile.thumb_url = thumbUrl;
            recordsFile.recordsLocal_id = recordsLocalID;
            recordsFile.isUploaded = @1;
            requireRepopulate = YES;
        } else if (fetchedrecordsFiles.count == 1) {
            // check if the group has been updated
            recordsFile = [fetchedrecordsFiles objectAtIndex:0];
            recordsFile.file_url = fileUrl;
            recordsFile.file_name = fileName;
            recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            recordsFile.student_id = studentID;
            recordsFile.lastUpdate = epochMicros;
            recordsFile.fileSize = fileSize;
            recordsFile.fileType = fileType;
            recordsFile.thumb_url = thumbUrl;
            recordsFile.recordsLocal_id = recordsLocalID;
            recordsFile.isUploaded = @1;
        } else if (fetchedrecordsFiles.count > 1) {
            
            for (RecordsFile *recordsFileToDelete in fetchedrecordsFiles) {
                [context deleteObject:recordsFileToDelete];
            }
            recordsFile.records_id = recordsFileID;
            recordsFile.file_url = fileUrl;
            recordsFile.file_name = fileName;
            recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            recordsFile.student_id = studentID;
            recordsFile.lastUpdate = epochMicros;
            recordsFile.fileSize = fileSize;
            recordsFile.fileType = fileType;
            recordsFile.thumb_url = thumbUrl;
            recordsFile.recordsLocal_id = recordsLocalID;
            recordsFile.isUploaded = @1;
            
            requireRepopulate = YES;
        }
        if (recordsFile != nil) {
            recordsFile.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredrecordsFiles = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredrecordsFiles != nil && expiredrecordsFiles.count > 0) {
        for (RecordsFile *recordsFileToDelete in expiredrecordsFiles) {
            [context deleteObject:recordsFileToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performUsersSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performUsersSyncCheck");
    
    NSURL *recordsFileURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:recordsFileURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *recordsFileRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_users_for_records", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonRecordsFileRequestData =[NSJSONSerialization dataWithJSONObject:recordsFileRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRecordsFileRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRecordsFileRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *recordsFileTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleUsersUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download recordsfiles: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download recordsfiles due to unknown error!");
            }
        }
        
        [self performRecordsFileSyncCheck:apiURLString andUserID:userID];
        
    }];
    [recordsFileTask resume];
}
- (void)handleUsersUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse RecordsFile update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *usersManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [usersManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *usersResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for Users data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [usersResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped RecordsFile update with invalid last_update time!");
        return;
    }
    
    value = [usersResults objectForKey:@"users"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *recordsFilesArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseUsersArray:recordsFilesArray IntoContext:usersManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    if ([usersManagedObjectContext hasChanges]) {
        [usersManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseUsersArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id usersElement in array) {
        if ([usersElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected recordsFile element which was not a dictionary!");
            continue;
        }
        NSDictionary *usersFields = usersElement;
        // TODO: add lastSync datetime
        NSNumber *user_id = [usersFields objectForKey:@"user_id"];
        NSString *firstName = [usersFields objectForKey:@"first_name"];
        NSString *middleName = [usersFields objectForKey:@"middle_name"];
        NSString *lastName = [usersFields objectForKey:@"last_name"];
        NSString *userLevel = [usersFields objectForKey:@"user_level"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", user_id];
        [request setPredicate:predicate];
        NSArray *fetchedUsers = [context executeFetchRequest:request error:&error];
        Users *users = nil;
        if (fetchedUsers == nil) {
            FDLogError(@"Skipped users update since there was an error checking for existing users!");
        } else if (fetchedUsers.count == 0) {
            users = [NSEntityDescription insertNewObjectForEntityForName:@"Users" inManagedObjectContext:context];
            users.userID = user_id;
            users.firstName = firstName;
            users.middleName = middleName;
            users.lastName = lastName;
            users.level = userLevel;
            requireRepopulate = YES;
        } else if (fetchedUsers.count == 1) {
            // check if the group has been updated
            users = [fetchedUsers objectAtIndex:0];
            users.firstName = firstName;
            users.middleName = middleName;
            users.lastName = lastName;
            users.level = userLevel;
        } else if (fetchedUsers.count > 1) {
            
            for (Users *usersToDelete in fetchedUsers) {
                [context deleteObject:usersToDelete];
            }
            users.userID = user_id;
            users.firstName = firstName;
            users.middleName = middleName;
            users.lastName = lastName;
            users.level = userLevel;
            
            requireRepopulate = YES;
        }
        if (users != nil) {
            users.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredUsers = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredUsers != nil && expiredUsers.count > 0) {
        for (Users *usersToDelete in expiredUsers) {
            [context deleteObject:usersToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}

- (void)performGeneralContentSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performGeneralContentSyncCheck");
    
    NSURL *recordsFileURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:recordsFileURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *recordsFileRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_generalContent", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonRecordsFileRequestData =[NSJSONSerialization dataWithJSONObject:recordsFileRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRecordsFileRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRecordsFileRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonLessonsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for lessons update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *recordsFileTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleGeneralContentUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download GeneralContent: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download GeneralContent due to unknown error!");
            }
        }
        
        [self performFaqsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [recordsFileTask resume];
}
- (void)handleGeneralContentUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse RecordsFile update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *generalContentManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [generalContentManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *recordsFileResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for GeneralContent data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [recordsFileResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped RecordsFile update with invalid last_update time!");
        return;
    }
    
    NSString *gettingStart = [recordsFileResults objectForKey:@"gettingStart"];
    NSString *faqs = [recordsFileResults objectForKey:@"faqs"];
    NSString *termsOfUse = [recordsFileResults objectForKey:@"termsOfUse"];
    NSString *privacy = [recordsFileResults objectForKey:@"privacy"];
    NSString *copyrightAndTradeMarks = [recordsFileResults objectForKey:@"copyrightAndTradeMarks"];
    
    // check to see if existing version of this group needs to be updated
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GeneralFlightDesk" inManagedObjectContext:generalContentManagedObjectContext];
    [request setEntity:entityDescription];
    NSArray *fetchedrecordsFiles = [generalContentManagedObjectContext executeFetchRequest:request error:&error];
    GeneralFlightDesk *generalFlightDesk = nil;
    if (fetchedrecordsFiles == nil) {
        
    } else if (fetchedrecordsFiles.count == 0) {
        generalFlightDesk = [NSEntityDescription insertNewObjectForEntityForName:@"GeneralFlightDesk" inManagedObjectContext:generalContentManagedObjectContext];
        generalFlightDesk.gettingStart =  gettingStart;
        generalFlightDesk.termsOfUse = termsOfUse;
        generalFlightDesk.privacy = privacy;
        generalFlightDesk.copyrightAndTradeMarks = copyrightAndTradeMarks;
    } else if (fetchedrecordsFiles.count == 1) {
        // check if the group has been updated
        generalFlightDesk = [fetchedrecordsFiles objectAtIndex:0];
        generalFlightDesk.gettingStart =  gettingStart;
        generalFlightDesk.termsOfUse = termsOfUse;
        generalFlightDesk.privacy = privacy;
        generalFlightDesk.copyrightAndTradeMarks = copyrightAndTradeMarks;
    } else if (fetchedrecordsFiles.count > 1) {
        
        for (GeneralFlightDesk *recordsFileToDelete in fetchedrecordsFiles) {
            [generalContentManagedObjectContext deleteObject:recordsFileToDelete];
        }
        generalFlightDesk = [NSEntityDescription insertNewObjectForEntityForName:@"GeneralFlightDesk" inManagedObjectContext:generalContentManagedObjectContext];
        generalFlightDesk.gettingStart =  gettingStart;
        generalFlightDesk.termsOfUse = termsOfUse;
        generalFlightDesk.privacy = privacy;
        generalFlightDesk.copyrightAndTradeMarks = copyrightAndTradeMarks;
    }
    if (generalFlightDesk != nil) {
        generalFlightDesk.lastUpdate = epoch_microseconds;
    }
    
    if ([generalContentManagedObjectContext hasChanges]) {
        [generalContentManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (void)performFaqsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performFaqsSyncCheck");
    
    NSURL *recordsFileURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:recordsFileURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *faqsRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_faqs", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonFaqsRequestData =[NSJSONSerialization dataWithJSONObject:faqsRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonFaqsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonFaqsRequestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *faqsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleFaqsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download faqs: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download faqs due to unknown error!");
            }
        }
        
        [self performResourcesCalendarSyncCheck:apiURLString andUserID:userID];
        
    }];
    [faqsTask resume];
}
- (void)handleFaqsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse faqs update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *faqsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [faqsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *faqsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for faqs data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [faqsResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped faqs update with invalid last_update time!");
        return;
    }
    
    value = [faqsResults objectForKey:@"faqs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *faqsArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseFaqsArray:faqsArray IntoContext:faqsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    if ([faqsManagedObjectContext hasChanges]) {
        [faqsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].general_VC) {
                [[AppDelegate sharedDelegate].general_VC reloadFaqs];
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseFaqsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id faqsElement in array) {
        if ([faqsElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected faqs element which was not a dictionary!");
            continue;
        }
        NSDictionary *faqsFields = faqsElement;
        // TODO: add lastSync datetime
        NSNumber *faqsID = [faqsFields objectForKey:@"faqs_id"];
        NSString *category = [faqsFields objectForKey:@"category"];
        NSString *question = [faqsFields objectForKey:@"question"];
        NSString *answer = [faqsFields objectForKey:@"answer"];
        NSNumber *faqsLocalID = [faqsFields objectForKey:@"faqs_local_id"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Faqs" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"faqs_id == %@", faqsID];
        [request setPredicate:predicate];
        NSArray *fetchedFaqs = [context executeFetchRequest:request error:&error];
        Faqs *faqs = nil;
        if (fetchedFaqs == nil) {
            FDLogError(@"Skipped faqs update since there was an error checking for existing faqs!");
        } else if (fetchedFaqs.count == 0) {
            faqs = [NSEntityDescription insertNewObjectForEntityForName:@"Faqs" inManagedObjectContext:context];
            faqs.faqs_id = faqsID;
            faqs.faqs_local_id = faqsLocalID;
            faqs.category = category;
            faqs.question = question;
            faqs.answer = answer;
            faqs.lastUpdate = epochMicros;
            requireRepopulate = YES;
        } else if (fetchedFaqs.count == 1) {
            // check if the group has been updated
            faqs = [fetchedFaqs objectAtIndex:0];
            faqs.faqs_id = faqsID;
            faqs.faqs_local_id = faqsLocalID;
            faqs.category = category;
            faqs.question = question;
            faqs.answer = answer;
            faqs.lastUpdate = epochMicros;
            requireRepopulate = YES;
        } else if (fetchedFaqs.count > 1) {
            
            for (Faqs *faqsToDelete in fetchedFaqs) {
                [context deleteObject:faqsToDelete];
            }
            faqs = [NSEntityDescription insertNewObjectForEntityForName:@"Faqs" inManagedObjectContext:context];
            faqs.faqs_id = faqsID;
            faqs.faqs_local_id = faqsLocalID;
            faqs.category = category;
            faqs.question = question;
            faqs.answer = answer;
            faqs.lastUpdate = epochMicros;
            requireRepopulate = YES;
        }
        if (faqs != nil) {
            faqs.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Faqs" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredfaqs = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredfaqs != nil && expiredfaqs.count > 0) {
        for (Faqs *faqsToDel in expiredfaqs) {
            [context deleteObject:faqsToDel];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}
- (void)performResourcesCalendarSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    FDLogDebug(@"performResourcesCalendarSyncCheck");
    
    NSURL *resourcesCalendarURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesCalendarURL];
    NSString *type = @"1";
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        type = @"3";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        type = @"1";
    }else{
        type = @"2";
    }
    
    NSDictionary *resourcesCalendarRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_resourcesCalendars", @"action", userID, @"user_id", type, @"user_type", nil];
    NSError *error;
    NSData *jsonResourcesCalendarsRequestData =[NSJSONSerialization dataWithJSONObject:resourcesCalendarRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonResourcesCalendarsRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonResourcesCalendarsRequestData];
    //NSString *jsonStrData = [[NSString alloc] initWithData:jsonResourcesCalendarsRequestData encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Sending request for resourcesCalendars update! JSON '%@'", jsonStrData);
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *resourcesCalendarsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            [self handleResourcesCalendarsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download resourcesCalendars: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download resourcesCalendars due to unknown error!");
            }
        }
        
        isStarted = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            NSLog(@"********************* END *******************");
            [AppDelegate sharedDelegate].isStartPerformSyncCheck = NO;
            
            [[AppDelegate sharedDelegate] stopThreadToSyncData:1];
            
            [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
            [AppDelegate sharedDelegate].currentSyncingIndex = 0;
            [[AppDelegate sharedDelegate] getDocumentDownloadCount];
            [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
            [[AppDelegate sharedDelegate].records_vc endRefresh];
            if ([AppDelegate sharedDelegate].reloadDashBoard_V) {
                [[AppDelegate sharedDelegate].reloadDashBoard_V setFrame:[[UIScreen mainScreen] bounds]];
                [[AppDelegate sharedDelegate].reloadDashBoard_V reloadViewsWithCurrentScreen];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_FIND_INSTRUCTOR object:nil userInfo:nil];
        });
        
    }];
    [resourcesCalendarsTask resume];
}
- (void)handleResourcesCalendarsUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse resourcesCalendar update without being logged in!");
        return;
    }
    // get a child managed object context
    NSManagedObjectContext *resourcesCalendarsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [resourcesCalendarsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // parse the query results
    NSDictionary *resourcesCalendarResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for resourcesCalendar data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [resourcesCalendarResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped resourcesCalendar update with invalid last_update time!");
        return;
    }
    
    value = [resourcesCalendarResults objectForKey:@"resourcesCalendars"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected groups element which was not an array!");
        return;
    }
    NSArray *resourcesCalendarsArray = value;
    BOOL requireRepopulate = NO;
    if ([self parseResourcesCalendarsArray:resourcesCalendarsArray IntoContext:resourcesCalendarsManagedObjectContext WithSync:epoch_microseconds AsUserID:userID] == YES) {
        requireRepopulate = YES;
    }
    dispatch_async(dispatch_get_main_queue(), ^{        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SyncedAllDataFromServer"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    });
    
    if ([resourcesCalendarsManagedObjectContext hasChanges]) {
        [resourcesCalendarsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
        });
    }
    
}
- (BOOL)parseResourcesCalendarsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self updatingCalendarsWithData];
    });
    
    NSDateFormatter *formaatter = [NSDateFormatter new];
    formaatter.dateFormat = @"yyyy-MM-dd HH:mm";
    [formaatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    for (id resourcesCalendarsElement in array) {
        if ([resourcesCalendarsElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected resourcesCalendar element which was not a dictionary!");
            continue;
        }
        NSDictionary *resourcesCalendarsFields = resourcesCalendarsElement;
        // TODO: add lastSync datetime
        NSNumber *event_id = [resourcesCalendarsFields objectForKey:@"event_id"];
        NSString *title = [resourcesCalendarsFields objectForKey:@"title"];
        NSString *calendar_name = [resourcesCalendarsFields objectForKey:@"calendar_name"];
        NSString *endDate = [resourcesCalendarsFields objectForKey:@"endDate"];
        NSNumber *event_local_id = [resourcesCalendarsFields objectForKey:@"event_local_id"];
        NSString *startDate = [resourcesCalendarsFields objectForKey:@"startDate"];
        NSNumber *current_user_id = [resourcesCalendarsFields objectForKey:@"user_id"];
        NSNumber *invited_user_id = [resourcesCalendarsFields objectForKey:@"invited_user_id"];
        NSNumber *group_id = [resourcesCalendarsFields objectForKey:@"group_id"];
        NSNumber *alertTimeInterVal = [resourcesCalendarsFields objectForKey:@"alertTimeInterVal"];
        NSString *aircraft = [resourcesCalendarsFields objectForKey:@"aircraft"];
        NSString *classroom = [resourcesCalendarsFields objectForKey:@"classroom"];
        BOOL isEditable = [[resourcesCalendarsFields objectForKey:@"isEditable"] boolValue];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event_id == %@", event_id];
        [request setPredicate:predicate];
        NSArray *fetchedResourcesCalendars = [context executeFetchRequest:request error:&error];
        ResourcesCalendar *resourcesCalendar = nil;
        if (fetchedResourcesCalendars == nil) {
            FDLogError(@"Skipped resourcesCalendar update since there was an error checking for existing resourcesCalendar!");
        } else if (fetchedResourcesCalendars.count == 0) {
            resourcesCalendar = [NSEntityDescription insertNewObjectForEntityForName:@"ResourcesCalendar" inManagedObjectContext:context];
            resourcesCalendar.event_id = event_id;
            resourcesCalendar.title = title;
            resourcesCalendar.endDate = endDate;
            resourcesCalendar.event_local_id = event_local_id;
            resourcesCalendar.startDate = startDate;
            resourcesCalendar.user_id = current_user_id;
            resourcesCalendar.invitedUser_id = invited_user_id;
            resourcesCalendar.group_id = group_id;
            resourcesCalendar.lastUpdate = epochMicros;
            resourcesCalendar.alertTimeInterVal = alertTimeInterVal;
            resourcesCalendar.aircraft = aircraft;
            resourcesCalendar.classroom = classroom;
            resourcesCalendar.timeIntervalStartDate = [NSNumber numberWithDouble:[[formaatter dateFromString:startDate] timeIntervalSince1970] * 1000000];
            resourcesCalendar.timeIntervalEndDate = [NSNumber numberWithDouble:[[formaatter dateFromString:endDate] timeIntervalSince1970] * 1000000];
            if (calendar_name.length > 4) {
                NSString *prefixOfCalendar = [calendar_name substringToIndex:4];
                if ([prefixOfCalendar isEqualToString:@"FD-U"]) {
                    if ([userID integerValue] == [current_user_id integerValue]) {
                        resourcesCalendar.calendar_name = calendar_name;
                    }else{
                        resourcesCalendar.calendar_name = [self saveCalendarNameFromOtherUser:current_user_id];
                        if ([resourcesCalendar.calendar_name isEqualToString:@""]) {
                            resourcesCalendar.calendar_name = [self saveCalendarNameFromOtherUser:invited_user_id];
                        }
                    }
                }else{
                    resourcesCalendar.calendar_name = calendar_name;
                }
            }else{
                resourcesCalendar.calendar_name = calendar_name;
            }
            
            resourcesCalendar.isEditable = isEditable?@YES:@NO;
            resourcesCalendar.calendar_identify = [self getCalendarIdentify:resourcesCalendar.calendar_name];
            resourcesCalendar.event_identify = @"";//[self saveCurrentEventOnCalendar:resourcesCalendar];
            requireRepopulate = YES;
        } else if (fetchedResourcesCalendars.count == 1) {
            // check if the group has been updated
            resourcesCalendar = [fetchedResourcesCalendars objectAtIndex:0];
            resourcesCalendar.title = title;
            resourcesCalendar.endDate = endDate;
            resourcesCalendar.event_local_id = event_local_id;
            resourcesCalendar.lastUpdate = epochMicros;
            resourcesCalendar.startDate = startDate;
            resourcesCalendar.user_id = current_user_id;
            resourcesCalendar.group_id = group_id;
            resourcesCalendar.aircraft = aircraft;
            resourcesCalendar.classroom = classroom;
            resourcesCalendar.alertTimeInterVal = alertTimeInterVal;
            resourcesCalendar.timeIntervalStartDate = [NSNumber numberWithDouble:[[formaatter dateFromString:startDate] timeIntervalSince1970] * 1000000];
            resourcesCalendar.timeIntervalEndDate = [NSNumber numberWithDouble:[[formaatter dateFromString:endDate] timeIntervalSince1970] * 1000000];
            requireRepopulate = YES;
        } else if (fetchedResourcesCalendars.count > 1) {
            
            for (ResourcesCalendar *resourcesCalendarToDelete in fetchedResourcesCalendars) {
                [context deleteObject:resourcesCalendarToDelete];
            }
            resourcesCalendar = [NSEntityDescription insertNewObjectForEntityForName:@"ResourcesCalendar" inManagedObjectContext:context];
            resourcesCalendar.event_id = event_id;
            resourcesCalendar.title = title;
            resourcesCalendar.endDate = endDate;
            resourcesCalendar.event_local_id = event_local_id;
            resourcesCalendar.startDate = startDate;
            resourcesCalendar.user_id = current_user_id;
            resourcesCalendar.invitedUser_id = invited_user_id;
            resourcesCalendar.group_id = group_id;
            resourcesCalendar.lastUpdate = epochMicros;
            resourcesCalendar.aircraft = aircraft;
            resourcesCalendar.classroom = classroom;
            resourcesCalendar.alertTimeInterVal = alertTimeInterVal;
            resourcesCalendar.timeIntervalStartDate = [NSNumber numberWithDouble:[[formaatter dateFromString:startDate] timeIntervalSince1970] * 1000000];
            resourcesCalendar.timeIntervalEndDate = [NSNumber numberWithDouble:[[formaatter dateFromString:endDate] timeIntervalSince1970] * 1000000];
            
            if (calendar_name.length > 4) {
                NSString *prefixOfCalendar = [calendar_name substringToIndex:4];
                if ([prefixOfCalendar isEqualToString:@"FD-U"]) {
                    if ([userID integerValue] == [current_user_id integerValue]) {
                        resourcesCalendar.calendar_name = calendar_name;
                    }else{
                        resourcesCalendar.calendar_name = [self saveCalendarNameFromOtherUser:current_user_id];
                        if ([resourcesCalendar.calendar_name isEqualToString:@""]) {
                            resourcesCalendar.calendar_name = [self saveCalendarNameFromOtherUser:invited_user_id];
                        }
                    }
                }else{
                    resourcesCalendar.calendar_name = calendar_name;
                }
            }else{
                resourcesCalendar.calendar_name = calendar_name;
            }
            
            resourcesCalendar.isEditable = isEditable?@YES:@NO;
            resourcesCalendar.calendar_identify = [self getCalendarIdentify:resourcesCalendar.calendar_name];
            resourcesCalendar.event_identify = @"";//[self saveCurrentEventOnCalendar:resourcesCalendar];
            requireRepopulate = YES;
        }
        if (resourcesCalendar != nil) {
            resourcesCalendar.lastSync = epochMicros;
        }
    }
    
    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:context];
    [expiredGroupRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epochMicros];
    [expiredGroupRequest setPredicate:predicate];
    NSArray *expiredResourcesCalendars = [context executeFetchRequest:expiredGroupRequest error:&error];
    if (expiredResourcesCalendars != nil && expiredResourcesCalendars.count > 0) {
        for (ResourcesCalendar *resourcesCalendarToDelete in expiredResourcesCalendars) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self deleteCurrentEventFromCalendar:resourcesCalendarToDelete];
            });
            [context deleteObject:resourcesCalendarToDelete];
        }
        requireRepopulate = YES;
    }
    return requireRepopulate;
}

- (NSString *)getCalendarIdentify:(NSString *)calendarName{
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    for (EKCalendar *currentCalendar in calendars) {
        if ([currentCalendar.title isEqualToString:calendarName]) {
            return currentCalendar.calendarIdentifier;
        }
    }
    return @"";
}
- (NSString *)saveCalendarNameFromOtherUser:(NSNumber *)userId{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", userId];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Users!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Users found!");
    } else {
        Users *checkedUser = objects[0];
        return [NSString stringWithFormat:@"FD-U-(%@ %@ %@)", checkedUser.firstName, checkedUser.middleName, checkedUser.lastName];
    }
    return @"";
}
- (NSString *)saveCurrentEventOnCalendar:(ResourcesCalendar *)resourcesCalendar{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    EKEvent *ev = [EKEvent eventWithEventStore:eventStore];
    ev.title = resourcesCalendar.title;
    ev.startDate = [dateFormatter dateFromString:resourcesCalendar.startDate];
    ev.endDate = [dateFormatter dateFromString:resourcesCalendar.endDate];
    
    NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    for (EKCalendar *currentCalendar in calendars) {
        if ([currentCalendar.title isEqualToString:resourcesCalendar.calendar_name]) {
            ev.calendar = currentCalendar;
        }
    }
    NSError *error;
    [eventStore saveEvent:ev span:EKSpanThisEvent error:&error];
    if (error != nil) {
        NSLog(@"Event Saving Error : %@", error.localizedDescription);
    }
    if ([resourcesCalendar.alertTimeInterVal integerValue] >= 0) {
        if ([[AppDelegate sharedDelegate] isShownHideCurrentEventFromLocal:ev]) {
            [[AppDelegate sharedDelegate] updateLocalNotificationWithReservation:resourcesCalendar.title withTimeInterVal:[resourcesCalendar.alertTimeInterVal integerValue] withAlertTitle:resourcesCalendar.title withStartDate:[dateFormatter dateFromString:resourcesCalendar.startDate] withEventIdentify:ev.eventIdentifier];
        }
    }
    return ev.eventIdentifier;
}

- (void)deleteCurrentEventFromCalendar:(ResourcesCalendar *)resourcesCalendar{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    EKEvent *eventToDelete = [eventStore eventWithIdentifier:resourcesCalendar.event_identify];
    NSError *error;
    [eventStore removeEvent:eventToDelete span:EKSpanThisEvent error:&error];
    if (error != nil) {
        NSLog(@"Event Removing Error : %@", error.localizedDescription);
    }
}
- (void)addOrUpdateCalendarWithString:(NSString *)calendarId withType:(NSInteger)type withEventStore:(EKEventStore *)eventStore{
    //adding a EKCalendar
    BOOL isExitCal  =NO;
    for (EKCalendar *calToCheck in [eventStore calendarsForEntityType:EKEntityTypeEvent]) {
        if ([calToCheck.title isEqualToString:calendarId]) {
            isExitCal = YES;
            break;
        }
    }
    if (isExitCal == NO) {
        NSString* calendarName = calendarId;
        EKCalendar* calendar;
        
        // Get the calendar source
        EKSource* localSource;
        for (EKSource* source in eventStore.sources) {
            NSLog(@"%ld", (long)source.sourceType);
            if (source.sourceType == EKSourceTypeLocal || source.sourceType == EKSourceTypeCalDAV)
            {
                localSource = source;
                break;
            }
        }
        
        if (localSource)
        {
            calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
            calendar.source = localSource;
            calendar.title = calendarName;
            CGFloat red = arc4random_uniform(255) / 255.0;
            CGFloat green = arc4random_uniform(255) / 255.0;
            CGFloat blue = arc4random_uniform(255) / 255.0;
            calendar.CGColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f].CGColor;
            
            NSError* error;
            BOOL success= [eventStore saveCalendar:calendar commit:YES error:&error];
            if (error != nil)
            {
                NSLog(@"%@", error.description);
                // TODO: error handling here
            }
            if (success) {
                
            }
        }
    }
}
- (void)updatingCalendarsWithData{
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    NSError *error;
    NSMutableArray *usersArray = [[NSMutableArray alloc] init];
    NSMutableArray *aircraftArray = [[NSMutableArray alloc] init];
    NSMutableArray *classroomsArray = [[NSMutableArray alloc] init];
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Users!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Users found!");
    } else {
        NSMutableArray *tempUsers= [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedUsers = [tempUsers sortedArrayUsingDescriptors:sortDescriptors];
        for (Users *users in sortedUsers) {
            BOOL isExit = NO;
            for (Users *userToCheck in usersArray) {
                if ([userToCheck.userID integerValue] == [users.userID integerValue]) {
                    isExit = YES;
                    break;
                }
            }
            if (!isExit) {
                [usersArray addObject:users];
            }
        }
    }
    
    entityDesc = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Aircraft!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Aircrafts found!");
    } else {
        FDLogDebug(@"%lu Aircrafts found", (unsigned long)[objects count]);
        NSMutableArray *tempAircrafts = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"valueForSort" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedAircrafts = [tempAircrafts sortedArrayUsingDescriptors:sortDescriptors];
        for (Aircraft *aircraft in sortedAircrafts) {
            [aircraftArray addObject:aircraft];
        }
    }
    
    [classroomsArray addObject:@"Cirrus Room"];
    [classroomsArray addObject:@"Cessna Room"];
    
    
    for (Users *oneUser in usersArray) {
        [self addOrUpdateCalendarWithString:[NSString stringWithFormat:@"FD-U-(%@ %@ %@)", oneUser.firstName, oneUser.middleName, oneUser.lastName] withType:1 withEventStore:eventStore];
    }
    for (Aircraft *oneAircraft in aircraftArray) {
        NSString *aircraftItems = oneAircraft.aircraftItems;
        NSData *data = [aircraftItems dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *aircraftReg = @"";
        NSString *aircraftMod = @"";
        for (NSDictionary *fieldInfo in json) {
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
                aircraftReg= [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Model"]) {
                aircraftMod = [fieldInfo objectForKey:@"content"];
            }
        }
        
        [self addOrUpdateCalendarWithString:[NSString stringWithFormat:@"FD-A-(%@ %@)", aircraftReg, aircraftMod]  withType:2 withEventStore:eventStore];
    }
    for (NSString *classrooms in classroomsArray) {
        [self addOrUpdateCalendarWithString:[NSString stringWithFormat:@"FD-C-(%@)", classrooms]  withType:3 withEventStore:eventStore];
    }
}
@end
