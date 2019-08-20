//
//  SyncManagerMoreTools.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/22/17.
//  Copyright © 2017 spider. All rights reserved.
//

// Order of Operations:
//
// uploadQueriesToDelete
// uploadNavLog
// ==> handleUploadNavLogsResults
// uploadChecklists
// ==> handleUploadChecklistsResults
// performNavLogSyncCheck
// handleNavLogsUpdate
// performCheckListsSyncCheck
// handleChecklistsUpdate

#import "SyncManagerMoreTools.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#define FOREGROUND_UPDATE_INTERVAL 10 // 1 minute (TODO: make this configurable)

@interface SyncManagerMoreTools ()

@property (strong, nonatomic) dispatch_source_t syncTimerForMoreTools;

@end
@implementation SyncManagerMoreTools
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
        self.syncTimerForMoreTools = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForMoreTools) {
            dispatch_source_set_timer(self.syncTimerForMoreTools, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForMoreTools, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForMoreTools);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForMoreTools);
    dispatch_source_set_cancel_handler(self.syncTimerForMoreTools, ^{
        self.syncTimerForMoreTools = nil;
    });
    self.syncTimerForMoreTools = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"******** START with MORE TOOLS ********");
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
     
        [self uploadQueriesToDelete:apiURLString andUserID:userID];
    }else{
        NSLog(@"Already was stared to sync *** MORE TOOLS ***");
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
- (void)uploadQueriesToDelete:(NSString*)apiURLString andUserID:(NSNumber*)userID{
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
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadQueriesTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
            
            [self uploadNavLog:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadNavLog:apiURLString andUserID:userID];
    }
}
//Uploading changes
- (void)uploadNavLog:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadNavLog");
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedNavLogs = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    if (fetchedNavLogs.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save navlogs until logged in!");
            return;
        }
        NSMutableArray *navLogs = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedNavLogIDs = [[NSMutableArray alloc] init];
        for (NavLog *navLog in fetchedNavLogs) {
            NSMutableArray *navLogRecordsArray = [[NSMutableArray alloc] init];
            for (NavLogRecord *navLogRecord in navLog.navLogRecords) {
                NSArray *navLogRecordArray = [[NSArray alloc] initWithObjects:navLogRecord.navLogRecordID,navLogRecord.navLogID, navLogRecord.attitude, navLogRecord.casTas, navLogRecord.ch, navLogRecord.checkPoint, navLogRecord.course, navLogRecord.dev, navLogRecord.distLeg, navLogRecord.distRem, navLogRecord.fuelATA, navLogRecord.fuelETA, navLogRecord.gphFuel, navLogRecord.gphRem, navLogRecord.gsAct, navLogRecord.gsEst, navLogRecord.lrWca, navLogRecord.lwVar, navLogRecord.mh, navLogRecord.tc, navLogRecord.th, navLogRecord.timeOffATE, navLogRecord.timeOffETE, navLogRecord.vorFreq, navLogRecord.vorIdent, navLogRecord.vorFrom, navLogRecord.vorTo, navLogRecord.windDir, navLogRecord.windTemp, navLogRecord.windVel, navLogRecord.ordering, nil];
                [navLogRecordsArray addObject:navLogRecordArray];
            }
            NSArray *navLogArray = [[NSArray alloc] initWithObjects:navLog.navLogID, navLog.navLogLocalID, navLog.aircraftNum, navLog.casTasVal, navLog.distLeg, navLog.fuel, navLog.gph, navLog.lastSync, navLog.lastUpdate,navLog.navLogDate, navLog.navLogName, navLog.notes, navLog.timeOff, navLog.userID ,navLogRecordsArray, nil];
            [navLogs addObject:navLogArray];
            [fetchedNavLogIDs addObject:[navLog objectID]];
        }
        
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_navlogs", @"action", userID, @"user_id", navLogs, @"navlogs", nil];
        NSData *navLogsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *savenavlogssURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveNavLogRequest = [NSMutableURLRequest requestWithURL:savenavlogssURL];
        [saveNavLogRequest setHTTPMethod:@"POST"];
        [saveNavLogRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveNavLogRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveNavLogRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)navLogsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveNavLogRequest setHTTPBody:navLogsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadNavLogsTask = [session dataTaskWithRequest:saveNavLogRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the navlogs update
            if (data != nil) {
                [self handleUploadNavLogsResults:data AndRecordIDs:fetchedNavLogIDs contextForNavLog:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading NavLog";
                }
                FDLogError(@"%@", errorText);
            }
            [self uploadChecklists:apiURLString andUserID:userID];
        }];
        [uploadNavLogsTask resume];
    } else {
        [self uploadChecklists:apiURLString andUserID:userID];
    }
}
- (void)uploadChecklists:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadChecklists");
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedChecklist = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    if (fetchedChecklist.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save checklists until logged in!");
            return;
        }
        NSMutableArray *checklistsArray = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedChecklistsIDs = [[NSMutableArray alloc] init];
        for (Checklists *oneChecklist in fetchedChecklist) {
            NSMutableArray *checklistContentsArray = [[NSMutableArray alloc] init];
            for (ChecklistsContent *checklistContent in oneChecklist.checklists) {
                NSArray *oneChecklistContent = [[NSArray alloc] initWithObjects:checklistContent.checklistContentID, checklistContent.checklistID, checklistContent.isChecked, checklistContent.content, checklistContent.contentTail, checklistContent.type, checklistContent.ordering, nil];
                [checklistContentsArray addObject:oneChecklistContent];
            }
            NSArray *oneChecklistArray = [[NSArray alloc] initWithObjects:oneChecklist.checklistsID, oneChecklist.category, oneChecklist.groupChecklist, oneChecklist.checklist, oneChecklist.userID, oneChecklist.parentChecklistsID, oneChecklist.lastSync, oneChecklist.lastUpdate, oneChecklist.checklistsLocalId ,checklistContentsArray, nil];
            [checklistsArray addObject:oneChecklistArray];
            [fetchedChecklistsIDs addObject:[oneChecklist objectID]];
        }
        NSString *type = @"";
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
            type = @"1";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_checklists", @"action", userID, @"user_id", checklistsArray, @"checklists",type, @"user_type", nil];
        NSData *checklistsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *savechecklistsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveNavLogRequest = [NSMutableURLRequest requestWithURL:savechecklistsURL];
        [saveNavLogRequest setHTTPMethod:@"POST"];
        [saveNavLogRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveNavLogRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveNavLogRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)checklistsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveNavLogRequest setHTTPBody:checklistsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadChecklistsTask = [session dataTaskWithRequest:saveNavLogRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the checklists update
            if (data != nil) {
                [self handleUploadChecklistsResults:data AndRecordIDs:fetchedChecklistsIDs contextForChecklist:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading NavLog";
                }
                FDLogError(@"%@", errorText);
            }
            [self performNavLogSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadChecklistsTask resume];
    } else {
        [self performNavLogSyncCheck:apiURLString andUserID:userID];
    }
}

//Perform data
- (void)performNavLogSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
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
        // handle the navlogs update
        if (data != nil) {
            [self handleNavLogsUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download navlogs: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download navlogs due to unknown error!");
            }
        }
        
        [self performCheckListsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [navLogTask resume];
}
- (void)performCheckListsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"******** END with MORE TOOLS ********");
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }];
    [checklistsTask resume];
}

//handle uploaded
- (void)handleUploadNavLogsResults:(NSData *)results AndRecordIDs:(NSArray *)navLogIDs contextForNavLog:(NSManagedObjectContext *)_contextNavLog{
    NSError *error;
    NSDictionary *navLogResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for navlog data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [navLogResults objectForKey:@"navlogs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected navlogs results element which was not an array!");
        return;
    }
    NSArray *navlogsResultsArray = value;
    
    int navlogIndex = 0;
    for (id navlogResultElement in navlogsResultsArray) {
        if ([navlogResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *navlogResultFields = navlogResultElement;
            NSNumber *resultBool = [navlogResultFields objectForKey:@"success"];
            NSNumber *recordID = [navlogResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [navlogResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [navlogResultFields objectForKey:@"error_str"];
            if (navlogIndex < [navLogIDs count]) {
                NSManagedObjectID *navlogID = [navLogIDs objectAtIndex:navlogIndex];
                NavLog *navlog = [_contextNavLog existingObjectWithID:navlogID error:&error];
                if ([resultBool boolValue] == YES) {
                    navlog.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (navlog.navLogID == nil || [navlog.navLogID integerValue] == 0) {
                        navlog.navLogID = recordID;
                    } else if ([navlog.navLogID intValue] != [recordID intValue]) {
                        
                    }
                    id navlogRecordA = [navlogResultFields objectForKey:@"navLogRecords"];
                    if ([navlogRecordA isKindOfClass:[NSArray class]] == NO) {
                        return;
                    }
                    NSArray *navlogsRecordsResultsArray = navlogRecordA;
                    for (NSDictionary *navlogRecord in navlogsRecordsResultsArray) {
                        NSNumber *resultBoolRec = [navlogRecord objectForKey:@"success"];
                        NSNumber *navlogRecordID = [navlogRecord objectForKey:@"record_id"];
                        NSNumber *ordering = [navlogRecord objectForKey:@"ordering"];
                        
                        if ([resultBoolRec boolValue] == YES) {
                            for (NavLogRecord *navlogRecToUpdate in navlog.navLogRecords){
                                if ([navlogRecToUpdate.ordering integerValue] == [ordering integerValue]) {
                                    if (navlogRecToUpdate.navLogRecordID == nil || [navlogRecToUpdate.navLogRecordID integerValue] == 0) {
                                        navlogRecToUpdate.navLogRecordID = navlogRecordID;
                                    } else if ([navlogRecToUpdate.navLogRecordID intValue] != [navlogRecordID intValue]) {
                                        
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    
                } else {
                    
                }
            } else {
                
            }
        }
        navlogIndex += 1;
    }
    
    if ([_contextNavLog hasChanges]) {
        [_contextNavLog save:&error];
    }
}
- (void)handleUploadChecklistsResults:(NSData *)results AndRecordIDs:(NSArray *)checklistsIDs contextForChecklist:(NSManagedObjectContext *)_contextChecklist{
    NSError *error;
    NSDictionary *checklistsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for checklist data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [checklistsResults objectForKey:@"checklists"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected checklists results element which was not an array!");
        return;
    }
    NSArray *checklistsResultsArray = value;
    
    int checklistIndex = 0;
    for (id checklistResultElement in checklistsResultsArray) {
        if ([checklistResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *checklistResultFields = checklistResultElement;
            NSNumber *resultBool = [checklistResultFields objectForKey:@"success"];
            NSNumber *recordID = [checklistResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [checklistResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [checklistResultFields objectForKey:@"error_str"];
            if (checklistIndex < [checklistsIDs count]) {
                NSManagedObjectID *checklistID = [checklistsIDs objectAtIndex:checklistIndex];
                Checklists *oneChecklist = [_contextChecklist existingObjectWithID:checklistID error:&error];
                if ([resultBool boolValue] == YES) {
                    oneChecklist.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (oneChecklist.checklistsID == nil || [oneChecklist.checklistsID integerValue] == 0) {
                        oneChecklist.checklistsID = recordID;
                    } else if ([oneChecklist.checklistsID intValue] != [recordID intValue]) {
                        
                    }
                    id checklistContentA = [checklistResultFields objectForKey:@"checklistContents"];
                    if ([checklistContentA isKindOfClass:[NSArray class]] == NO) {
                        return;
                    }
                    NSArray *checklistContentsResultsArray = checklistContentA;
                    for (NSDictionary *checklistContentDict in checklistContentsResultsArray) {
                        NSNumber *resultBoolRec = [checklistContentDict objectForKey:@"success"];
                        NSInteger checklistContentID = [[checklistContentDict objectForKey:@"record_id"] integerValue];
                        NSNumber *ordering = [checklistContentDict objectForKey:@"ordering"];
                        
                        if ([resultBoolRec boolValue] == YES) {
                            for (ChecklistsContent *checklistcontentToUpdate in oneChecklist.checklists){
                                if ([checklistcontentToUpdate.ordering integerValue] == [ordering integerValue]) {
                                    if (checklistcontentToUpdate.checklistContentID == nil || [checklistcontentToUpdate.checklistContentID integerValue] == 0) {
                                        checklistcontentToUpdate.checklistContentID =[NSNumber numberWithInteger:checklistContentID];
                                    } else if ([checklistcontentToUpdate.checklistContentID intValue] != checklistContentID) {
                                        
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    
                } else {
                    
                }
            } else {
                
            }
        }
        checklistIndex += 1;
    }
    
    if ([_contextChecklist hasChanges]) {
        [_contextChecklist save:&error];
    }
}

//Handle downloaded
- (void)handleNavLogsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
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
        // notify navlogs view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].navLog_VC) {
                //do anything
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
}
- (BOOL)parseNavLogsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return NO;
    }
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
            FDLogError(@"Skipped navlogs update since there was an error checking for existing navlogs!");
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
                    navLogRecord.lastSync = epochMicros;
                    [navLog addNavLogRecordsObject:navLogRecord];
                }
            }
            requireRepopulate = YES;
        } else if (fetchedNavLogs.count == 1) {
            navLog = [fetchedNavLogs objectAtIndex:0];
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
                                break;
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
                            navLogRecordToCheck.lastSync = epochMicros;
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
                            navLogRecordToCheck.lastSync = epochMicros;
                            [navLog addNavLogRecordsObject:navLogRecordToCheck];
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
                    navLogRecord.lastSync = epochMicros;
                    [navLog addNavLogRecordsObject:navLogRecord];
                }
            }
            requireRepopulate = YES;
        }
        if (navLog != nil) {
            navLog.lastSync = epochMicros;
        }
    }
    // loop through navlogs, delete any that have not been synced
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
    
    expiredNavLogRequest = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"NavLogRecord" inManagedObjectContext:context];
    [expiredNavLogRequest setEntity:entityDescription];
    predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
    [expiredNavLogRequest setPredicate:predicate];
    NSArray *expiredNavLogRecords = [context executeFetchRequest:expiredNavLogRequest error:&error];
    if (expiredNavLogRecords != nil && expiredNavLogRecords.count > 0) {
        for (NavLogRecord *navLogToDelete in expiredNavLogRecords) {
            [context deleteObject:navLogToDelete];
        }
        
        requireRepopulate = YES;
    }
    return requireRepopulate;
}

- (void)handleChecklistsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return;
    }
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
    
    isStarted = NO;
    NSLog(@"******** END with MORE TOOLS ********");
    
    if ([checklistsManagedObjectContext hasChanges]) {
        [checklistsManagedObjectContext save:&error];
        // notify checklists view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([AppDelegate sharedDelegate].checklist_VC) {
                // do anything
            }
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
        });
    }
    
}
- (BOOL)parseChecklistsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MoreTools sync is stoped forcibly ***");
        return NO;
    }
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
@end
