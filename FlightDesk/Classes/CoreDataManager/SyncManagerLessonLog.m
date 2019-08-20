//
//  SyncManagerLessonLog.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/22/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerLessonLog.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "LogEntry+CoreDataClass.h"

#define FOREGROUND_UPDATE_INTERVAL 25 // 1 minute (TODO: make this configurable)
@interface SyncManagerLessonLog ()

@property (strong, nonatomic) dispatch_source_t syncTimerForLessonLog;

@end
@implementation SyncManagerLessonLog
{
    Reachability *serverReachability;
    BOOL isStarted;
    BOOL isStopedByOther;
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
        isStopedByOther = NO;
        self.syncTimerForLessonLog = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForLessonLog) {
            dispatch_source_set_timer(self.syncTimerForLessonLog, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForLessonLog, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForLessonLog);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForLessonLog);
    dispatch_source_set_cancel_handler(self.syncTimerForLessonLog, ^{
        self.syncTimerForLessonLog = nil;
    });
    self.syncTimerForLessonLog = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"******** START with LESSON AND LOGS ********");
        NetworkStatus netStatus = [serverReachability currentReachabilityStatus];
        if (netStatus == NotReachable) {
            FDLogError(@"Skipped sync check since server was unreachable!");
            isStarted = NO;
            return;
        }
        // make sure we are logged in
        NSString *userIDKey = @"userId";
        NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
        NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to perform sync until logged in!");
            isStarted = NO;
            return;
        }
        // grab URL for API
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        
        [self getBadgeCountForCurrentUser:apiURLString andUserID:userID];
        
        
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            [self uploadInsAndStdAndProgramsQuery:apiURLString andUserID:userID];
        }else{
            [self uploadQueriesToDelete:apiURLString andUserID:userID];
        }
    }else{
        NSLog(@"Already was stared to sync *** LESSON AND LOG ***");
    }
    
}
- (void)getBadgeCountForCurrentUser:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([AppDelegate sharedDelegate].commsMain_vc != nil) {
                            [[AppDelegate sharedDelegate].commsMain_vc reloadTableViewWithPush];
                        }
                    });
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
- (void)uploadInsAndStdAndProgramsQuery:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"InsAndStdAndProgamQuery" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"instructorID != 0"];
    [request setPredicate:predicate];
    NSArray *fetchedQueriesToDelete = [context executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedQueriesToDelete.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *queriesArry = [[NSMutableArray alloc] init];
        for (InsAndStdAndProgamQuery *query in fetchedQueriesToDelete) {
            
            NSArray *queryArray = [[NSArray alloc] initWithObjects:query.queryType, query.instructorID, query.studentID, query.programID, nil];
            [queriesArry addObject:queryArray];
        }
        NSString *type = @"";
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else{
            type = @"2";
        }
        
        
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"instructor_student_programs_query", @"action", userID, @"user_id", queriesArry, @"queries",type, @"user_type", nil];
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
                for (InsAndStdAndProgamQuery *query in fetchedQueriesToDelete) {
                    [context deleteObject:query];
                }
                
                if ([context hasChanges]) {
                    [context save:&error];
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
            
            [self uploadQueriesToDelete:apiURLString andUserID:userID];
        }];
        [uploadLessonRecordsTask resume];
    }else{
        [self uploadQueriesToDelete:apiURLString andUserID:userID];
    }
}
- (void)uploadQueriesToDelete:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DeleteQuery" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idToDelete != 0"];
    [request setPredicate:predicate];
    NSArray *fetchedQueriesToDelete = [context executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedQueriesToDelete.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *queriesArry = [[NSMutableArray alloc] init];
        for (DeleteQuery *query in fetchedQueriesToDelete) {
            
            NSString *typeToDelete = query.type;
            NSArray *queryArray;
            NSArray *parseType = [typeToDelete componentsSeparatedByString:@"#.#"];
            if (parseType.count == 1) {
                queryArray = [[NSArray alloc] initWithObjects:typeToDelete, query.idToDelete, nil];
            }else if (parseType.count == 2){
                NSNumber *studentIdForDoc = [NSNumber numberWithInteger:[parseType[1] integerValue]];
                queryArray = [[NSArray alloc] initWithObjects:parseType[0], query.idToDelete, studentIdForDoc, nil];
            }else if (parseType.count == 3){
                NSNumber *studentIdForDoc = [NSNumber numberWithInteger:[parseType[1] integerValue]];
                NSNumber *groupIdForDoc = [NSNumber numberWithInteger:[parseType[2] integerValue]];
                queryArray = [[NSArray alloc] initWithObjects:parseType[0], query.idToDelete, studentIdForDoc,groupIdForDoc, nil];
            }
            [queriesArry addObject:queryArray];
        }
        NSString *type = @"";
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else{
            type = @"2";
        }
        
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"delete_queries", @"action", userID, @"user_id", queriesArry, @"queries",type, @"user_type", nil];
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
                for (NSDictionary *oneQuery in [queryResults objectForKey:@"query_result"]) {
                    if ([oneQuery objectForKey:@"success"] && [[oneQuery objectForKey:@"success"] boolValue] == YES) {
                        NSNumber *queryID = [oneQuery objectForKey:@"query_id"];
                        for (DeleteQuery *query in fetchedQueriesToDelete) {
                            if ([query.idToDelete integerValue] == [queryID integerValue]) {
                                [context deleteObject:query];
                                break;
                            }
                        }
                    }
                }
                
                if ([context hasChanges]) {
                    [context save:&error];
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
            
            [self uploadLessonGroupForParent:apiURLString andUserID:userID];
        }];
        [uploadLessonRecordsTask resume];
    }else{
        [self uploadLessonGroupForParent:apiURLString andUserID:userID];
    }
}
- (void)uploadLessonGroupForParent:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"upload lesson group");
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND parentGroup == NULL"];
    [request setPredicate:predicate];
    NSArray *fetchedLesonGroups = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedLesonGroups.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lessonGroup until logged in!");
            return;
        }
        NSMutableArray *lessonRecords = [[NSMutableArray alloc] init];
        NSMutableArray *fetchedLessongroupIDs = [[NSMutableArray alloc] init];
        for (LessonGroup *lessonGroup in fetchedLesonGroups) {
            NSArray *lessonGroupArray = [[NSArray alloc] initWithObjects:lessonGroup.groupID, lessonGroup.name, lessonGroup.lastSync, lessonGroup.lastUpdate, lessonGroup.studentUserID,lessonGroup.isShown,  lessonGroup.parentGroup.groupID , nil];
            [lessonRecords addObject:lessonGroupArray];
            
            [fetchedLessongroupIDs addObject:[lessonGroup objectID]];
        }
        
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else {
            type = @"2";
        }
        
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_lessongroup", @"action", userID, @"user_id", lessonRecords, @"lessonGroups", type , @"user_type", nil];
        NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveLessonGroupsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveLessonGroupsRequest setHTTPMethod:@"POST"];
        [saveLessonGroupsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveLessonGroupsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveLessonGroupsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveLessonGroupsRequest setHTTPBody:lessonRecordsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadLessonGroupTask = [session dataTaskWithRequest:saveLessonGroupsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadLessonGroupsResults:data AndRecordIDs:fetchedLessongroupIDs];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                FDLogError(@"%@", errorText);
            }
            
            // UPLOAD SUBLESSONGROUPS
            [self uploadLessonGroup:apiURLString andUserID:userID];
        }];
        [uploadLessonGroupTask resume];
    } else {
        
        // UPLOAD SUBLESSONGROUPS
        [self uploadLessonGroup:apiURLString andUserID:userID];
    }
}
- (void)uploadLessonGroup:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"upload lesson group");
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedLesonGroups = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedLesonGroups.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lessonGroup until logged in!");
            return;
        }
        NSMutableArray *lessonRecords = [[NSMutableArray alloc] init];
        NSMutableArray *fetchedLessongroupIDs = [[NSMutableArray alloc] init];
        for (LessonGroup *lessonGroup in fetchedLesonGroups) {
            NSArray *lessonGroupArray = [[NSArray alloc] initWithObjects:lessonGroup.groupID, lessonGroup.name, lessonGroup.lastSync, lessonGroup.lastUpdate, @(0), @(1),lessonGroup.parentGroup.groupID , nil];
            [lessonRecords addObject:lessonGroupArray];
            
            [fetchedLessongroupIDs addObject:[lessonGroup objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else {
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_lessongroup", @"action", userID, @"user_id", lessonRecords, @"lessonGroups", type, @"user_type", nil];
        NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveLessonGroupsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveLessonGroupsRequest setHTTPMethod:@"POST"];
        [saveLessonGroupsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveLessonGroupsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveLessonGroupsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveLessonGroupsRequest setHTTPBody:lessonRecordsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadLessonGroupTask = [session dataTaskWithRequest:saveLessonGroupsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadLessonGroupsResults:data AndRecordIDs:fetchedLessongroupIDs];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                FDLogError(@"%@", errorText);
            }
            
            // UPLOAD LESSONS
            [self uploadLesson:apiURLString andUserID:userID];
        }];
        [uploadLessonGroupTask resume];
    } else {
        
        // UPLOAD LESSONS
        [self uploadLesson:apiURLString andUserID:userID];
    }
}
- (void)uploadLesson:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"uploadLessones");
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedLesons = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedLesons.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson until logged in!");
            return;
        }
        NSMutableArray *lessonRecords = [[NSMutableArray alloc] init];
        NSMutableArray *fetchedLessonIDs = [[NSMutableArray alloc] init];
        for (Lesson *lesson in fetchedLesons) {
            NSMutableArray *lessonContentArray = [[NSMutableArray alloc] init];
            for (Content *content in lesson.content) {
                NSArray *contentArray = [[NSArray alloc] initWithObjects:content.contentID, content.orderNumber, content.groundOrFlight, content.hasRemarks, content.hasCheck, content.name, content.content_local_id, content.depth, nil];
                [lessonContentArray addObject:contentArray];
            }
            NSMutableArray *assignmentRecordArray = [[NSMutableArray alloc] init];
            for (Assignment *assignment in lesson.assignments) {
                NSArray *assignmentArray = [[NSArray alloc] initWithObjects:assignment.chapters, assignment.referenceID, assignment.title, assignment.assignmentID, assignment.groundOrFlight,assignment.assignment_local_id, nil];
                [assignmentRecordArray addObject:assignmentArray];
            }
            NSArray *lessonRecordArray = [[NSArray alloc] initWithObjects:lesson.lessonNumber, lesson.flightCompletionStds, lesson.flightDescription, lesson.flightObjective, lesson.groundCompletionStds, lesson.groundDescription, lesson.groundObjective, lesson.minDual, lesson.minGround, lesson.minInstrument, lesson.minSolo, lesson.title, lesson.lastSync, lesson.lastUpdate, lesson.indentation, lesson.lessonID,lesson.lesson_local_id, lesson.studentUserID, lessonContentArray, assignmentRecordArray ,lesson.lessonGroup.groupID, nil];
            [lessonRecords addObject:lessonRecordArray];
            
            [fetchedLessonIDs addObject:[lesson objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else {
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_lessons", @"action", userID, @"user_id", lessonRecords, @"lessons", type, @"user_type", nil];
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
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadLessonResults:data AndRecordIDs:fetchedLessonIDs];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                FDLogError(@"%@", errorText);
            }
            // start with lesson records
            // upload lesson records
            [self uploadLessonRecords:apiURLString andUserID:userID];
        }];
        [uploadQuizRecordsTask resume];
        
    } else {
        
        // start with lesson records
        // upload lesson records
        [self uploadLessonRecords:apiURLString andUserID:userID];
    }
}
- (void)uploadLessonRecords:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"uploadLessonRecords");
    // TODO: consider gathering new/updated LessonRecord objects in another thread with a new child object context
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedLessonRecords = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedLessonRecords.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        //FDLogDebug(@"Found %lu lesson records to upload!", (unsigned long)fetchedLessonRecords.count);
        // create array of lesson record arrays [[recordId, lessonID, flightCompleted...], ...]
        NSMutableArray *lessonRecords = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedLessonRecordIDs = [[NSMutableArray alloc] init];
        for (LessonRecord *lessonRecord in fetchedLessonRecords) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            NSString *lessonDateStr = @"";
            if (lessonRecord.lessonDate) {
                lessonDateStr = [formatter stringFromDate:lessonRecord.lessonDate];
            }else{
                lessonDateStr = [formatter stringFromDate:[NSDate date]];
            }
            
            NSMutableArray *lessonContentRecordArray = [[NSMutableArray alloc] init];
            // loop through each content record for the lesson
            // LessonRecord ==> Lesson ==> Content ==> ContentRecord
            for (Content *content in lessonRecord.lesson.content) {
                NSArray *contentRecordArray = [[NSArray alloc] initWithObjects:content.record.contentRecordID, content.contentID, content.record.completed, content.record.remarks, nil];
                [lessonContentRecordArray addObject:contentRecordArray];
            }
            //FDLogDebug(@"recordID=%@,lessonID=%@,flightCompleted='%@',flightNotes='%@',groundCompleted='%@',groundNotes='%@',instructorID=%@,userID=%@,lessonDate='%@',lastUpdate=%@,contentRecords=%lu", lessonRecord.recordID, lessonRecord.lesson.lessonID, lessonRecord.flightCompleted, lessonRecord.flightNotes, lessonRecord.groundCompleted, lessonRecord.groundNotes, lessonRecord.instructorID, userID, lessonDateStr, lessonRecord.lastUpdate, (unsigned long)[lessonContentRecordArray count]);
            // the user ID has to be the user of the lesson! (not necessarily the currently logged in user)
            NSNumber *lessonRecordUserID = lessonRecord.lesson.studentUserID;
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                NSArray *lessonRecordArray = [[NSArray alloc] initWithObjects:lessonRecord.recordID, lessonRecord.lesson.lessonID, lessonRecord.flightCompleted, lessonRecord.flightNotes, lessonRecord.groundCompleted, lessonRecord.groundNotes, lessonRecord.instructorID, lessonRecordUserID, lessonDateStr, lessonRecord.lastUpdate, lessonContentRecordArray, nil];
                [lessonRecords addObject:lessonRecordArray];
            }else{
                NSArray *lessonRecordArray = [[NSArray alloc] initWithObjects:lessonRecord.recordID, lessonRecord.lesson.lessonID, lessonRecord.flightCompleted, lessonRecord.flightNotes, lessonRecord.groundCompleted, lessonRecord.groundNotes, lessonRecord.lesson.lessonGroup.instructorID, lessonRecordUserID, lessonDateStr, lessonRecord.lastUpdate, lessonContentRecordArray, nil];
                [lessonRecords addObject:lessonRecordArray];
            }
            [fetchedLessonRecordIDs addObject:[lessonRecord objectID]];
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_lesson_records", @"action", userID, @"user_id", lessonRecords, @"lesson_records", nil];
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
                // parse LessonRecord results
                [self handleUploadLessonRecordResults:data AndRecordIDs:fetchedLessonRecordIDs];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                // show error
                //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //[alert show];
                FDLogError(@"%@", errorText);
            }
            // request lessons
            [self uploadLogEntries:apiURLString andUserID:userID];
        }];
        [uploadLessonRecordsTask resume];
    } else {
        // request lessons
        [self uploadLogEntries:apiURLString andUserID:userID];
    }
}
- (void)uploadLogEntries:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"uploadLogEntries");
    // get a child managed object context
    NSManagedObjectContext *logEntryManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [logEntryManagedObjectContext setParentContext:self.mainManagedObjectContext];
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:logEntryManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND hobbsIn != 0 AND hobbsOut != 0"];
    [request setPredicate:predicate];
    NSArray *fetchedLogEntries = [logEntryManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedLogEntries.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save log book entries until logged in!");
            return;
        }
        //FDLogDebug(@"Found %lu log book entries to upload!", (unsigned long)fetchedLogEntries.count);
        // create array of lesson record arrays [[recordId, lessonID, flightCompleted...], ...]
        NSMutableArray *logEntries = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedLogEntriesIDs = [[NSMutableArray alloc] init];
        for (LogEntry *logEntry in fetchedLogEntries) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd"];
            //NSString *logDateStr = [formatter stringFromDate:logEntry.logDate];
            NSNumber *logEntryLessonRecordID = nil;
            NSNumber *logEntryLessonID = nil;
            if (logEntry.logLessonRecord != nil) {
                logEntryLessonID = logEntry.logLessonRecord.lesson.lessonID;
                logEntryLessonRecordID = logEntry.logLessonRecord.recordID;
            }
            if (logEntryLessonID == nil) {
                logEntryLessonID = logEntry.lessonId;
            }
            //FDLogDebug(@"logEntryID=%@,logEntryLessonID=%@,logLessonRecordID=%@,category='%@',class='%@',model='%@',registration='%@'", logEntry.entryID, logEntryLessonRecordID, logEntryLessonID, logEntry.aircraftCategory, logEntry.aircraftClass, logEntry.aircraftModel, logEntry.aircraftRegistration);
            NSMutableDictionary *logEntryDictionary = [[NSMutableDictionary alloc] init];
            if (logEntry.entryID != nil && [logEntry.entryID intValue] != 0) {
                [logEntryDictionary setValue:logEntry.entryID forKey:@"entry_id"];
            }
            
            if (logEntryLessonRecordID != nil) {
                [logEntryDictionary setValue:logEntryLessonRecordID forKey:@"entry_lesson_record_id"];
            }
            if (logEntryLessonID != nil) {
                [logEntryDictionary setValue:logEntryLessonID forKey:@"entry_lesson_id"];
            }
            if (logEntry.userID != nil) {
                [logEntryDictionary setValue:logEntry.userID forKey:@"user_id"];
            }
            // "YYYYMMDD HH:MM:SS.000" (backup for log entry ID which is assigned by database and not yet known!)
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *creationDateTimeStr = [dateFormat stringFromDate:logEntry.creationDateTime];
            [logEntryDictionary setValue:creationDateTimeStr forKey:@"creation_datetime"];
            if (logEntry.instructorID != nil) {
                [logEntryDictionary setValue:logEntry.instructorID forKey:@"instructor_id"];
            }
            if (logEntry.aircraftCategory != nil) {
                [logEntryDictionary setValue:logEntry.aircraftCategory forKey:@"aircraft_category"];
            }
            if (logEntry.aircraftClass != nil) {
                [logEntryDictionary setValue:logEntry.aircraftClass forKey:@"aircraft_class"];
            }
            if (logEntry.aircraftModel != nil) {
                [logEntryDictionary setValue:logEntry.aircraftModel forKey:@"aircraft_model"];
            }
            if (logEntry.aircraftRegistration != nil) {
                [logEntryDictionary setValue:logEntry.aircraftRegistration forKey:@"aircraft_registration"];
            }
            if (logEntry.approachesCount != nil) {
                [logEntryDictionary setValue:logEntry.approachesCount forKey:@"approaches_count"];
            }
            if (logEntry.approachesType != nil) {
                [logEntryDictionary setValue:logEntry.approachesType forKey:@"approaches_type"];
            }
            if (logEntry.complex != nil && ![logEntry.complex isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.complex forKey:@"complex"];
            }
            if (logEntry.dualGiven != nil && ![logEntry.dualGiven isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGiven forKey:@"dual_given"];
            }
            if (logEntry.dualGivenCFI != nil && ![logEntry.dualGivenCFI isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenCFI forKey:@"dual_given_cfi"];
            }
            if (logEntry.dualGivenCommercial != nil && ![logEntry.dualGivenCommercial isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenCommercial forKey:@"dual_given_commercial"];
            }
            if (logEntry.dualGivenGlider != nil && ![logEntry.dualGivenGlider isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenGlider forKey:@"dual_given_glider"];
            }
            if (logEntry.dualGivenInstrument != nil && ![logEntry.dualGivenInstrument isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenInstrument forKey:@"dual_given_instrument"];
            }
            if (logEntry.dualGivenOther != nil && ![logEntry.dualGivenOther isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenOther forKey:@"dual_given_other"];
            }
            if (logEntry.dualGivenRecreational != nil && ![logEntry.dualGivenRecreational isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenRecreational forKey:@"dual_given_recreational"];
            }
            if (logEntry.dualGivenSport != nil && ![logEntry.dualGivenSport isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualGivenSport forKey:@"dual_given_sport"];
            }
            if (logEntry.dualReceived != nil && ![logEntry.dualReceived isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.dualReceived forKey:@"dual_received"];
            }
            if (logEntry.flightRoute != nil) {
                [logEntryDictionary setValue:logEntry.flightRoute forKey:@"flight_route"];
            }
            if (logEntry.glider != nil && ![logEntry.glider isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.glider forKey:@"glider"];
            }
            if (logEntry.groundTime != nil && ![logEntry.groundTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.groundTime forKey:@"ground_time"];
            }
            if (logEntry.helicopter != nil && ![logEntry.helicopter isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.helicopter forKey:@"helicopter"];
            }
            if (logEntry.highPerf != nil && ![logEntry.highPerf isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.highPerf forKey:@"high_perf"];
            }
            if (logEntry.hobbsIn != nil) {
                [logEntryDictionary setValue:logEntry.hobbsIn forKey:@"hobbs_in"];
            }
            if (logEntry.hobbsOut != nil) {
                [logEntryDictionary setValue:logEntry.hobbsOut forKey:@"hobbs_out"];
            }
            if (logEntry.holds != nil) {
                [logEntryDictionary setValue:logEntry.holds forKey:@"holds"];
            }
            if (logEntry.instrumentActual != nil && ![logEntry.instrumentActual isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.instrumentActual forKey:@"instrument_actual"];
            }
            if (logEntry.instrumentHood != nil && ![logEntry.instrumentHood isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.instrumentHood forKey:@"instrument_hood"];
            }
            if (logEntry.instrumentSim != nil && ![logEntry.instrumentSim isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.instrumentSim forKey:@"instrument_sim"];
            }
            if (logEntry.jet != nil && ![logEntry.jet isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.jet forKey:@"jet"];
            }
            if (logEntry.landingsDay != nil) {
                [logEntryDictionary setValue:logEntry.landingsDay forKey:@"landings_day"];
            }
            if (logEntry.landingsNight != nil) {
                [logEntryDictionary setValue:logEntry.landingsNight forKey:@"landings_night"];
            }
            if (logEntry.lastSync != nil) {
                [logEntryDictionary setValue:logEntry.lastSync forKey:@"last_sync"];
            }
            if (logEntry.lastUpdate != nil) {
                [logEntryDictionary setValue:logEntry.lastUpdate forKey:@"last_update"];
            }
            if (logEntry.logDate != nil) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd"];
                NSString *logDateStr = [formatter stringFromDate:logEntry.logDate];
                [logEntryDictionary setValue:logDateStr forKey:@"log_date"];
            }
            if (logEntry.nightDualReceived != nil && ![logEntry.nightDualReceived isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.nightDualReceived forKey:@"night_dual_received"];
            }
            if (logEntry.nightTime != nil && ![logEntry.nightTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.nightTime forKey:@"night_time"];
            }
            if (logEntry.picTime != nil && ![logEntry.picTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.picTime forKey:@"pic_time"];
            }
            if (logEntry.recreational != nil && ![logEntry.recreational isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.recreational forKey:@"recreational"];
            }
            if (logEntry.remarks != nil) {
                [logEntryDictionary setValue:logEntry.remarks forKey:@"remarks"];
            }
            if (logEntry.sicTime != nil && ![logEntry.sicTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.sicTime forKey:@"sic_time"];
            }
            if (logEntry.soloTime != nil && ![logEntry.soloTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.soloTime forKey:@"solo_time"];
            }
            if (logEntry.sport != nil && ![logEntry.sport isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.sport forKey:@"sport"];
            }
            if (logEntry.taildragger != nil && ![logEntry.taildragger isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.taildragger forKey:@"taildragger"];
            }
            if (logEntry.totalFlightTime != nil && ![logEntry.totalFlightTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.totalFlightTime forKey:@"total_flight_time"];
            }
            if (logEntry.tracking != nil) {
                [logEntryDictionary setValue:logEntry.tracking forKey:@"tracking"];
            }
            if (logEntry.turboprop != nil && ![logEntry.turboprop isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.turboprop forKey:@"turboprop"];
            }
            if (logEntry.ultraLight != nil && ![logEntry.ultraLight isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.ultraLight forKey:@"ultra_light"];
            }
            if (logEntry.xc != nil && ![logEntry.xc isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xc forKey:@"cross_country"];
            }
            if (logEntry.xcDualGiven != nil && ![logEntry.xcDualGiven isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcDualGiven forKey:@"cross_country_dual_given"];
            }
            if (logEntry.xcDualReceived != nil && ![logEntry.xcDualReceived isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcDualReceived forKey:@"cross_country_dual_received"];
            }
            if (logEntry.xcNightDualReceived != nil && ![logEntry.xcNightDualReceived isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcNightDualReceived forKey:@"cross_country_night_dual_received"];
            }
            if (logEntry.xcNightTime != nil && ![logEntry.xcNightTime isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcNightTime forKey:@"cross_country_night"];
            }
            if (logEntry.xcPIC != nil && ![logEntry.xcPIC isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcPIC forKey:@"cross_country_pic"];
            }
            if (logEntry.xcSolo != nil && ![logEntry.xcSolo isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.xcSolo forKey:@"cross_country_solo"];
            }
            if (logEntry.studentUserID != nil && ![logEntry.studentUserID isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [logEntryDictionary setValue:logEntry.studentUserID forKey:@"entry_student_id"];
            }
            if (logEntry.instructorSignature != nil) {
                [logEntryDictionary setValue:logEntry.instructorSignature forKey:@"instructor_signature"];
            }
            if (logEntry.instructorCertNo != nil) {
                [logEntryDictionary setValue:logEntry.instructorCertNo forKey:@"instructor_cert_no"];
            }
            if (logEntry.log_local_id != nil && [logEntry.log_local_id intValue] != 0) {
                [logEntryDictionary setValue:logEntry.log_local_id forKey:@"log_local_id"];
            }
            if (logEntry.endorsements != nil && logEntry.endorsements.count > 0) {
                NSMutableArray *endorsementsArray = [[NSMutableArray alloc] init];
                for (Endorsement *endorSement in logEntry.endorsements) {
                    NSMutableDictionary *dictForEndorsement = [[NSMutableDictionary alloc] init];
                    [dictForEndorsement setObject:endorSement.endorsementID forKey:@"endo_id"];
                    [dictForEndorsement setObject:endorSement.name forKey:@"endo_name"];
                    [dictForEndorsement setObject:endorSement.text forKey:@"endo_text"];
                    [dictForEndorsement setObject:endorSement.endorsementDate forKey:@"endo_date"];
                    [dictForEndorsement setObject:endorSement.endorsementExpDate forKey:@"endo_exp_date"];
                    if (endorSement.cfiNumber != nil) {
                        [dictForEndorsement setObject:endorSement.cfiNumber forKey:@"cfi_num"];
                    }else{
                        [dictForEndorsement setObject:@"" forKey:@"cfi_num"];
                    }
                    [dictForEndorsement setObject:endorSement.cfiSignature forKey:@"cfi_signature"];
                    [dictForEndorsement setObject:endorSement.isSupersed forKey:@"isSuporsed"];
                    if (endorSement.type != nil) {
                        [dictForEndorsement setObject:endorSement.type forKey:@"type"];
                    }else{
                        [dictForEndorsement setObject:@1 forKey:@"type"];
                    }
                    [dictForEndorsement setObject:endorSement.endorsement_local_id forKey:@"endorsement_local_id"];
                    [endorsementsArray addObject:[dictForEndorsement copy]];
                }
                [logEntryDictionary setValue:[endorsementsArray copy] forKey:@"endorsements"];
            }
            
            [logEntries addObject:logEntryDictionary];
            [fetchedLogEntriesIDs addObject:[logEntry objectID]];
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_log_entries", @"action", userID, @"user_id", logEntries, @"log_entries", nil];
        NSData *logEntriesJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLogEntriesURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveLogEntriesRequest = [NSMutableURLRequest requestWithURL:saveLogEntriesURL];
        [saveLogEntriesRequest setHTTPMethod:@"POST"];
        [saveLogEntriesRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveLogEntriesRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveLogEntriesRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)logEntriesJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveLogEntriesRequest setHTTPBody:logEntriesJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:logEntriesJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the log book entries! JSON '%@'", jsonStrData);
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadLogEntriesTask = [session dataTaskWithRequest:saveLogEntriesRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the log book entries upload response
            if (data != nil) {
                // parse LogEntry results
                [self handleUploadLogEntryResults:data AndRecordIDs:fetchedLogEntriesIDs];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                // show error
                //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //[alert show];
                FDLogError(@"%@", errorText);
            }
            [self uploadEndorsementOwn:apiURLString andUserID:userID];
        }];
        [uploadLogEntriesTask resume];
    } else {
        
        [self uploadEndorsementOwn:apiURLString andUserID:userID];
    }
}
- (void)uploadEndorsementOwn:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
    FDLogDebug(@"uploadEndorsementOwn");
    // TODO: consider gathering new/updated LessonRecord objects in another thread with a new child object context
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND type == 2"];
    [request setPredicate:predicate];
    NSArray *fetchedEndrosements = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedEndrosements.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        //FDLogDebug(@"Found %lu lesson records to upload!", (unsigned long)fetchedLessonRecords.count);
        // create array of lesson record arrays [[recordId, lessonID, flightCompleted...], ...]
        NSMutableArray *endorsements = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedEndorsements = [[NSMutableArray alloc] init];
        for (Endorsement *endorSement in fetchedEndrosements) {
            NSArray *endorsementArray = [[NSArray alloc] initWithObjects:endorSement.endorsementID,endorSement.name,  endorSement.text, endorSement.endorsementDate, endorSement.endorsementExpDate, endorSement.cfiNumber,endorSement.cfiSignature,endorSement.isSupersed, @2,endorSement.endorsement_local_id,  nil];
            [endorsements addObject:endorsementArray];
            [fetchedEndorsements addObject:[endorSement objectID]];
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_endorsement_own", @"action", userID, @"user_id", endorsements, @"endoserments", nil];
        NSData *endorsementsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveEndorsementRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveEndorsementRequest setHTTPMethod:@"POST"];
        [saveEndorsementRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveEndorsementRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveEndorsementRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)endorsementsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveEndorsementRequest setHTTPBody:endorsementsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadEndorsmentsTask = [session dataTaskWithRequest:saveEndorsementRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                // parse LessonRecord results
                [self handleUploadEndorsementsResults:data AndRecordIDs:fetchedEndorsements];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                // show error
                //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                //[alert show];
                FDLogError(@"%@", errorText);
            }
            // upload lesson records
            [self performUsersSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadEndorsmentsTask resume];
    } else {
        // upload lesson records
        [self performUsersSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)performUsersSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return;
    }
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
        
        [self performLessonsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [recordsFileTask resume];
}
- (void)handleUsersUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return NO;
    }
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
            users = [NSEntityDescription insertNewObjectForEntityForName:@"Users" inManagedObjectContext:context];
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
// perform
- (void)performLessonsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
- (void)performLessonRecordsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
- (void)performLogEntriesSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
            NSLog(@"******** END with LESSON AND LOGS ********");
            isStarted = NO;
        }
    }];
    [endorsmentsTask resume];
}
//handle
- (void)handleUploadLessonGroupsResults:(NSData *)results AndRecordIDs:(NSArray *)lessonGroupIDs{
    NSError *error;
    // parse the query results
    NSDictionary *lessonGroupResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for lessonGroup results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [lessonGroupResults objectForKey:@"lesson_records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected lesson results element which was not an array!");
        return;
    }
    NSArray *lessonGroupResultsArray = value;
    NSManagedObjectContext *_contextForLessonGroup = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_contextForLessonGroup setParentContext:self.mainManagedObjectContext];
    
    int lessonIndex = 0;
    for (id lessonGroupResultElement in lessonGroupResultsArray) {
        if ([lessonGroupResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *lessonGroupResultFields = lessonGroupResultElement;
            NSNumber *resultBool = [lessonGroupResultFields objectForKey:@"success"];
            NSNumber *recordID = [lessonGroupResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [lessonGroupResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [lessonGroupResultFields objectForKey:@"error_str"];
            if (lessonIndex < [lessonGroupIDs count]) {
                NSManagedObjectID *lessonGroupID = [lessonGroupIDs objectAtIndex:lessonIndex];
                LessonGroup *lessonGroup = [_contextForLessonGroup existingObjectWithID:lessonGroupID error:&error];
                if ([resultBool boolValue] == YES) {
                    lessonGroup.lastUpdate = timestamp;
                    if (lessonGroup.groupID == nil || [lessonGroup.groupID integerValue] == 0) {
                        lessonGroup.groupID = recordID;
                    } else if ([lessonGroup.groupID intValue] != [recordID intValue]) {
                        FDLogError(@"New LessonRecordID %@ for record with existing ID %@", recordID, lessonGroup.groupID);
                    }
                } else {
                    FDLogError(@"Failed to insert/update LessonRecord for lesson with ID %@: %@", lessonGroup.groupID, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store LessonRecordID due to out-of-bounds index %d (total records %d): %@", lessonIndex, [lessonGroupIDs count], jsonStrData);
            }
        }
        lessonIndex += 1;
    }
    
    if ([_contextForLessonGroup hasChanges]) {
        [_contextForLessonGroup save:&error];
    }
}
- (void)handleUploadLessonResults:(NSData *)results AndRecordIDs:(NSArray *)lessonRecordIDs{
    NSError *error;
    // parse the query results
    NSDictionary *lessonResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for lesson results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [lessonResults objectForKey:@"lesson_records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected lesson results element which was not an array!");
        return;
    }
    NSArray *lessonRecordResultsArray = value;
    NSManagedObjectContext *_contextForLesson = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_contextForLesson setParentContext:self.mainManagedObjectContext];
    int lessonIndex = 0;
    for (id lessonRecordResultElement in lessonRecordResultsArray) {
        if ([lessonRecordResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *lessonRecordResultFields = lessonRecordResultElement;
            NSNumber *resultBool = [[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"success"];
            NSNumber *recordID = [[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"record_id"];
            NSNumber *timestamp = [[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"timestamp"];
            NSString *errorStr = [[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"error_str"];
            if (lessonIndex < [lessonRecordIDs count]) {
                NSManagedObjectID *lessonRecordID = [lessonRecordIDs objectAtIndex:lessonIndex];
                Lesson *lessonRecord = [_contextForLesson existingObjectWithID:lessonRecordID error:&error];
                if ([resultBool boolValue] == YES) {
                    lessonRecord.lastUpdate = timestamp;
                    if ([[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"lesson_name"]) {
                        lessonRecord.name = [[lessonRecordResultFields objectForKey:@"lesson"] objectForKey:@"lesson_name"];
                    }
                    if (lessonRecord.assignments.count) {
                        NSInteger assignCount = 0;
                        for (Assignment *assignToUpdate in lessonRecord.assignments) {
                            if ([[lessonRecordResultFields objectForKey:@"assignment"] count] > assignCount) {
                                NSDictionary *assignDict = [[lessonRecordResultFields objectForKey:@"assignment"] objectAtIndex:assignCount];
                                NSNumber *assignID = [assignDict objectForKey:@"assign_id"];
                                if ([[assignDict objectForKey:@"success"] boolValue]) {
                                    if (assignToUpdate.assignmentID == nil || [assignToUpdate.assignmentID integerValue] == 0) {
                                        assignToUpdate.assignmentID = assignID;
                                    }
                                }
                                assignCount = assignCount + 1;
                            }
                        }
                    }
                    if (lessonRecord.content.count) {
                        NSInteger contentCount = 0;
                        for (Content *contentToUpdate in lessonRecord.content) {
                            if ([[lessonRecordResultFields objectForKey:@"content"] count] > contentCount) {
                                NSDictionary *contentDict =[[lessonRecordResultFields objectForKey:@"content"] objectAtIndex:contentCount];
                                contentCount = contentCount + 1;
                                NSNumber *contentID = [contentDict objectForKey:@"content_id"];
                                if ([[contentDict objectForKey:@"success"] boolValue]) {
                                    if (contentToUpdate.contentID == nil || [contentToUpdate.contentID integerValue] == 0) {
                                        contentToUpdate.contentID = contentID;
                                    }
                                }
                            }
                        }
                    }
                    // insert/update succeeded, save record id
                    if (lessonRecord.lessonID == nil || [lessonRecord.lessonID integerValue] == 0) {
                        lessonRecord.lessonID = recordID;
                    } else if ([lessonRecord.lessonID intValue] != [recordID intValue]) {
                        FDLogError(@"New LessonRecordID %@ for record with existing ID %@", recordID, lessonRecord.lessonID);
                    }
                } else {
                    FDLogError(@"Failed to insert/update LessonRecord for lesson with ID %@: %@", lessonRecord.lessonID, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store LessonRecordID due to out-of-bounds index %d (total records %d): %@", lessonIndex, [lessonRecordIDs count], jsonStrData);
            }
        }
        lessonIndex += 1;
    }
    
    if ([_contextForLesson hasChanges]) {
        [_contextForLesson save:&error];
    }
}
- (void)handleUploadLessonRecordResults:(NSData *)results AndRecordIDs:(NSArray *)lessonRecordIDs
{
    NSError *error;
    // parse the query results
    NSDictionary *lessonResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for lesson record results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [lessonResults objectForKey:@"lesson_records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected lesson record results element which was not an array!");
        return;
    }
    NSArray *lessonRecordResultsArray = value;
    
    // get a child managed object context
    NSManagedObjectContext *recordsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [recordsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    
    int recordIndex = 0;
    for (id lessonRecordResultElement in lessonRecordResultsArray) {
        if ([lessonRecordResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *lessonRecordResultFields = lessonRecordResultElement;
            NSNumber *resultBool = [lessonRecordResultFields objectForKey:@"result"];
            NSNumber *recordID = [lessonRecordResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [lessonRecordResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [lessonRecordResultFields objectForKey:@"error_str"];
            if (recordIndex < [lessonRecordIDs count]) {
                NSManagedObjectID *lessonRecordID = [lessonRecordIDs objectAtIndex:recordIndex];
                LessonRecord *lessonRecord = [recordsManagedObjectContext existingObjectWithID:lessonRecordID error:&error];
                if ([resultBool boolValue] == YES) {
                    lessonRecord.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (lessonRecord.recordID == nil) {
                        lessonRecord.recordID = recordID;
                    } else if ([lessonRecord.recordID intValue] != [recordID intValue]) {
                        FDLogError(@"New LessonRecordID %@ for record with existing ID %@", recordID, lessonRecord.recordID);
                    }
                } else {
                    FDLogError(@"Failed to insert/update LessonRecord for lesson with ID %@: %@", lessonRecord.lesson.lessonID, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store LessonRecordID due to out-of-bounds index %d (total records %d): %@", recordIndex, [lessonRecordIDs count], jsonStrData);
            }
        }
        recordIndex += 1;
    }
    
    if ([recordsManagedObjectContext hasChanges]) {
        [recordsManagedObjectContext save:&error];
    }
}
- (void)handleUploadLogEntryResults:(NSData *)results AndRecordIDs:(NSArray *)logEntryRecordIDs
{
    NSError *error;
    //NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"log entry results JSON '%@'", jsonStrData);
    // parse the query results
    id value = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if ([value isKindOfClass:[NSDictionary class]] == NO) {
        FDLogError(@"Encountered unexpected log entry result which was not a dictionary!");
        return;
    }
    NSDictionary *logEntryResults = value;
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for log entry results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    value = [logEntryResults objectForKey:@"log_entries"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected log entry results element which was not an array!");
        return;
    }
    NSArray *logEntryResultsArray = value;
    // get a child managed object context
    NSManagedObjectContext *logEntriesManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [logEntriesManagedObjectContext setParentContext:self.mainManagedObjectContext];
    
    int recordIndex = 0;
    for (id logEntryResultElement in logEntryResultsArray) {
        if ([logEntryResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *logEntryResultFields = logEntryResultElement;
            NSNumber *resultBool = [logEntryResultFields objectForKey:@"result"];
            NSNumber *entryID = [logEntryResultFields objectForKey:@"entry_id"];
            NSNumber *timestamp = [logEntryResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [logEntryResultFields objectForKey:@"error_str"];
            NSArray *endorsements = [logEntryResultFields objectForKey:@"endorsements"];
            if (recordIndex < [logEntryRecordIDs count]) {
                NSManagedObjectID *logEntryID = [logEntryRecordIDs objectAtIndex:recordIndex];
                LogEntry *logEntry = [logEntriesManagedObjectContext existingObjectWithID:logEntryID error:&error];
                if ([resultBool boolValue] == YES) {
                    logEntry.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (logEntry.entryID == nil) {
                        logEntry.entryID = entryID;
                    } else if ([logEntry.entryID intValue] != [entryID intValue]) {
                        FDLogError(@"New LogEntryID %@ for log entry with existing ID %@", entryID, logEntry.entryID);
                        logEntry.entryID = entryID;
                    }
                    for (int i = 0; i < endorsements.count; i ++) {
                        NSDictionary *dictToEndorsement = endorsements[i];
                        if ([logEntry.endorsements objectAtIndex:i]) {
                            if ([[dictToEndorsement objectForKey:@"result"] boolValue]) {
                                NSNumber *endorseemtnId = [dictToEndorsement objectForKey:@"endorsement_id"];
                                if ([[logEntry.endorsements objectAtIndex:i].endorsementID intValue] != [endorseemtnId intValue]) {
                                    [logEntry.endorsements objectAtIndex:i].endorsementID = endorseemtnId;
                                }
                            }
                        }
                    }
                } else {
                    FDLogError(@"Failed to insert/update LogEntry with ID %@ and date %@: %@", logEntry.entryID, logEntry.logDate, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store LessonRecordID due to out-of-bounds index %d (total records %d): %@", recordIndex, [logEntryRecordIDs count], jsonStrData);
            }
        }
        recordIndex += 1;
    }
    
    if ([logEntriesManagedObjectContext hasChanges]) {
        [logEntriesManagedObjectContext save:&error];
        //FDLogDebug(@"upload log entries synced!");
    }
}
- (void)handleUploadEndorsementsResults:(NSData *)results AndRecordIDs:(NSArray *)endorsementIDs
{
    NSError *error;
    // parse the query results
    NSDictionary *endorsementResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for endorsement results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [endorsementResults objectForKey:@"endorsements"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected endorsments results element which was not an array!");
        return;
    }
    NSArray *endorsementsResultsArray = value;
    
    // get a child managed object context
    NSManagedObjectContext *recordsManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [recordsManagedObjectContext setParentContext:self.mainManagedObjectContext];
    
    int recordIndex = 0;
    for (id endorsementsResultElement in endorsementsResultsArray) {
        if ([endorsementsResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *endorsementResultFields = endorsementsResultElement;
            NSNumber *resultBool = [endorsementResultFields objectForKey:@"result"];
            NSNumber *recordID = [endorsementResultFields objectForKey:@"endorsement_id"];
            NSNumber *timestamp = [endorsementResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [endorsementResultFields objectForKey:@"error_str"];
            if (recordIndex < [endorsementIDs count]) {
                NSManagedObjectID *endorsmentID = [endorsementIDs objectAtIndex:recordIndex];
                Endorsement *endorsement = [recordsManagedObjectContext existingObjectWithID:endorsmentID error:&error];
                if ([resultBool boolValue] == YES) {
                    endorsement.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (endorsement.endorsementID == nil || [endorsement.endorsementID integerValue] == 0) {
                        endorsement.endorsementID = recordID;
                    } else if ([endorsement.endorsementID intValue] != [recordID intValue]) {
                        FDLogError(@"New endorsementID %@ for record with existing ID %@", recordID,endorsement.endorsementID);
                    }
                } else {
                    FDLogError(@"Failed to insert/update LessonRecord for lesson with ID %@: %@", endorsement.endorsementID, errorStr);
                }
            } else {
                
            }
        }
        recordIndex += 1;
    }
    
    if ([recordsManagedObjectContext hasChanges]) {
        [recordsManagedObjectContext save:&error];
    }
}
- (void)handleLessonsUpdate:(NSData *)results
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
- (BOOL)parseLessonArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
- (BOOL)parseStudentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
- (BOOL)parseAssignmentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
                assignment.assignment_local_id = assignment_local_id;
                assignment.groundOrFlight = groundOrFlight;
                assignment.referenceID = referenceID;
                assignment.title = title;
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

// NOTE: this assumes parent content definitions are always returned BEFORE child content from the server
- (BOOL)parseContentArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
                content.depth = depth;
                content.orderNumber = orderNumber;
                content.groundOrFlight = groundOrFlight;
                content.hasRemarks = hasRemarks;
                content.hasCheck = hasCheck;
                content.name = name;
                content.studentUserID = studentUserID;
                //FDLogDebug(@"added content: content_id=%@,lesson_id=%@,order_number=%@,ground_or_flight=%@,parent_content_id=%@,has_remarks=%@,has_check=%@,content_name=%@", contentID, lessonID, orderNumber, groundOrFlight, parentContentID, hasRemarks, hasCheck, name);
                requireRepopulate = YES;
            } else if (fetchedContent.count == 1) {
                content = [fetchedContent objectAtIndex:0];
                    content.orderNumber = orderNumber;
                    content.groundOrFlight = groundOrFlight;
                    content.hasRemarks = hasRemarks;
                    content.hasCheck = hasCheck;
                    content.name = name;
                    content.content_local_id = content_local_id;
                    content.depth = depth;
                    content.studentUserID = studentUserID;
                    //FDLogDebug(@"updated content: content_id=%@,lesson_id=%@,order_number=%@,ground_or_flight=%@,parent_content_id=%@,has_remarks=%@,has_check=%@,content_name=%@", contentID, lessonID, orderNumber, groundOrFlight, parentContentID, hasRemarks, hasCheck, name);
                    requireRepopulate = YES;
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
                content.depth = depth;
                content.studentUserID = studentUserID;
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
- (void)handleLessonRecordsUpdate:(NSData *)results
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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

- (void)handleLogEntriesUpdate:(NSData *)results
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
        
        
    }
    NSFetchRequest *expiredLogRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *expiredLognsEntityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:logEntriesManagedObjectContext];
    [expiredLogRequest setEntity:expiredLognsEntityDescription];
    NSPredicate *expiredLogsPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND lastUpdate != 0", epoch_microseconds];
    [expiredLogRequest setPredicate:expiredLogsPredicate];
    NSArray *expiredLogsArray = [logEntriesManagedObjectContext executeFetchRequest:expiredLogRequest error:&error];
    for (LogEntry *logEntryToDelete in expiredLogsArray) {
        if (logEntryToDelete.endorsements.count > 0) {
            for (Endorsement *endorsementToDelete in logEntryToDelete.endorsements) {
                if ([endorsementToDelete.type integerValue] != 2) {
                    [logEntriesManagedObjectContext deleteObject:endorsementToDelete];
                }
            }
        }
        [logEntriesManagedObjectContext deleteObject:logEntryToDelete];
    }
    
    NSFetchRequest *expiredEndorsementRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *expiredEndorsementEntityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:logEntriesManagedObjectContext];
    [expiredEndorsementRequest setEntity:expiredEndorsementEntityDescription];
    NSPredicate *expiredEndorsementsPredicate = [NSPredicate predicateWithFormat:@"lastSync < %@ AND type != 2", epoch_microseconds];
    [expiredEndorsementRequest setPredicate:expiredEndorsementsPredicate];
    NSArray *expiredEndorsementArray = [logEntriesManagedObjectContext executeFetchRequest:expiredEndorsementRequest error:&error];
    for (Endorsement *endorsementToDelete in expiredEndorsementArray) {
        if ([endorsementToDelete.type integerValue] != 2) {
            [logEntriesManagedObjectContext deleteObject:endorsementToDelete];
        }
    }
    
    
    if ([logEntriesManagedObjectContext hasChanges]) {
        [logEntriesManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
    }
    //close refreshing with tableview
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AppDelegate sharedDelegate].records_vc endRefresh];
        [[AppDelegate sharedDelegate].logbook_vc populateLogBooks];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FLIGHTDESK_FIND_INSTRUCTOR object:nil userInfo:nil];
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            if ([AppDelegate sharedDelegate].train_VC) {
                [[AppDelegate sharedDelegate].train_VC reloadDataWithTraining];
            }
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]){
            if ([AppDelegate sharedDelegate].studentTrain_VC) {
                [[AppDelegate sharedDelegate].studentTrain_VC reloadDataWithTraining];
            }
        }
    });
    NSLog(@"******** END with LESSON AND LOGS ********");
    isStarted = NO;
}
- (BOOL)parseLogEntriesArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return NO;
    }
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
                entry.valueForSort=updated_epoch_microseconds;
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

- (void)handleEndorsementsUpdate:(NSData *)results
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"**** LessonLog sync is stoped forcibly ****");
        return;
    }
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
        }
    }
    
}
- (BOOL)parseEndorsementsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return NO;
    }
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
@end
