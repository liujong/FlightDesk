//
//  SyncManagerResourcesCalendar.m
//  FlightDesk
//
//  Created by jellaliu on 11/10/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerResourcesCalendar.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"

#define FOREGROUND_UPDATE_INTERVAL 10 // 1 minute (TODO: make this configurable)
@interface SyncManagerResourcesCalendar ()
@property (strong, nonatomic) dispatch_source_t syncTimerForresourcesCalendar;
@end

@implementation SyncManagerResourcesCalendar
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
        self.syncTimerForresourcesCalendar = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForresourcesCalendar) {
            dispatch_source_set_timer(self.syncTimerForresourcesCalendar, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForresourcesCalendar, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForresourcesCalendar);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForresourcesCalendar);
    dispatch_source_set_cancel_handler(self.syncTimerForresourcesCalendar, ^{
        self.syncTimerForresourcesCalendar = nil;
    });
    self.syncTimerForresourcesCalendar = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"*********** START with RESOURCESCALENDAR ***********");
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
        NSLog(@"Already was stared to sync *** RESOURCESCALENDAR ***");
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** ResourcesCalendar Sycn is stoped forcibly ***");
        return;
    }
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DeleteQuery" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    // all resourcesCalendar records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idToDelete != 0"];
    [request setPredicate:predicate];
    NSArray *fetchedQueriesToDelete = [context executeFetchRequest:request error:&error];
    // create dictionary for uploading resourcesCalendars
    if (fetchedQueriesToDelete.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save resourcesCalendar records until logged in!");
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
        NSData *resourcesCalendarRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveResourcesCalendarsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveResourcesCalendarsRequest = [NSMutableURLRequest requestWithURL:saveResourcesCalendarsURL];
        [saveResourcesCalendarsRequest setHTTPMethod:@"POST"];
        [saveResourcesCalendarsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveResourcesCalendarsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveResourcesCalendarsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)resourcesCalendarRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveResourcesCalendarsRequest setHTTPBody:resourcesCalendarRecordsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadQueriesTask = [session dataTaskWithRequest:saveResourcesCalendarsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
            
            [self uploadResourcesCalendar:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadResourcesCalendar:apiURLString andUserID:userID];
    }
}
- (void)uploadResourcesCalendar:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** ResourcesCalendar Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadResourcesCalendar");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND user_id ==%@ AND isEditable == YES", userID];
    [request setPredicate:predicate];
    NSArray *fetchedResourcesCalendars = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading resourcesCalendars
    if (fetchedResourcesCalendars.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save resourcesCalendar records until logged in!");
            return;
        }
        NSMutableArray *resourcesCalendars = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedResourcesCalendarIDs = [[NSMutableArray alloc] init];
        
        for (ResourcesCalendar *resourcesCalendar in fetchedResourcesCalendars) {
            NSArray *resourcesCalendarArray = [[NSArray alloc] initWithObjects:resourcesCalendar.event_id, resourcesCalendar.title, resourcesCalendar.calendar_name, resourcesCalendar.endDate, resourcesCalendar.event_local_id, resourcesCalendar.lastSync, resourcesCalendar.lastUpdate, resourcesCalendar.startDate, resourcesCalendar.group_id,resourcesCalendar.invitedUser_id,resourcesCalendar.alertTimeInterVal,resourcesCalendar.aircraft, resourcesCalendar.classroom, nil];
            [resourcesCalendars addObject:resourcesCalendarArray];
            [fetchedResourcesCalendarIDs addObject:[resourcesCalendar objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_resourcesCalendar_items", @"action", userID, @"user_id",type, @"user_type", resourcesCalendars, @"resourcesCalendars", nil];
        NSData *resourcesCalendarRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveResourcesCalendarsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveResourcesCalendarsRequest = [NSMutableURLRequest requestWithURL:saveResourcesCalendarsURL];
        [saveResourcesCalendarsRequest setHTTPMethod:@"POST"];
        [saveResourcesCalendarsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveResourcesCalendarsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveResourcesCalendarsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)resourcesCalendarRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveResourcesCalendarsRequest setHTTPBody:resourcesCalendarRecordsJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:resourcesCalendarRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the resourcesCalendar records! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveResourcesCalendarsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadResourcesCalendarsResults:data AndRecordIDs:fetchedResourcesCalendarIDs contextForResourcesCalendar:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading resourcesCalendar records";
                }
                FDLogError(@"%@", errorText);
            }
            
            [self performUsersSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadQuizRecordsTask resume];
    } else {
        [self performUsersSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadResourcesCalendarsResults:(NSData *)results AndRecordIDs:(NSArray *)resourcesCalendarIDs contextForResourcesCalendar:(NSManagedObjectContext *)_contextResourcesCalendar{
    NSError *error;
    // parse the query results
    NSDictionary *resourcesCalendarResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for resourcesCalendar data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [resourcesCalendarResults objectForKey:@"resourcesCalendars"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected resourcesCalendar results element which was not an array!");
        return;
    }
    NSArray *resourcesCalendarsResultsArray = value;
    
    int resourcesCalendarIndex = 0;
    for (id resourcesCalendarResultElement in resourcesCalendarsResultsArray) {
        if ([resourcesCalendarResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resourcesCalendarResultFields = resourcesCalendarResultElement;
            NSNumber *resultBool = [resourcesCalendarResultFields objectForKey:@"success"];
            NSNumber *recordID = [resourcesCalendarResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [resourcesCalendarResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [resourcesCalendarResultFields objectForKey:@"error_str"];
            if (resourcesCalendarIndex < [resourcesCalendarIDs count]) {
                NSManagedObjectID *resourcesCalendarID = [resourcesCalendarIDs objectAtIndex:resourcesCalendarIndex];
                ResourcesCalendar *resourcesCalendar = [_contextResourcesCalendar existingObjectWithID:resourcesCalendarID error:&error];
                if ([resultBool boolValue] == YES) {
                    resourcesCalendar.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (resourcesCalendar.event_id == nil || [resourcesCalendar.event_id integerValue] == 0) {
                        resourcesCalendar.event_id = recordID;
                    } else if ([resourcesCalendar.event_id intValue] != [recordID intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        resourcesCalendarIndex += 1;
    }
    
    if ([_contextResourcesCalendar hasChanges]) {
        [_contextResourcesCalendar save:&error];
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
        
        [self performResourcesCalendarSyncCheck:apiURLString andUserID:userID];
        
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
- (void)performResourcesCalendarSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** ResourcesCalendar Sycn is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"*********** END with RESOURCESCALENDAR ***********");
        }
        
        
    }];
    [resourcesCalendarsTask resume];
}
- (void)handleResourcesCalendarsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** ResourcesCalendar Sycn is stoped forcibly ***");
        return;
    }
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
    isStarted = NO;
    NSLog(@"*********** END with RESOURCESCALENDAR ***********");
    if ([resourcesCalendarsManagedObjectContext hasChanges]) {
        [resourcesCalendarsManagedObjectContext save:&error];
        // notify documents view controller to reload the managed object context
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSError *mainMOCError;
            [self.mainManagedObjectContext save:&mainMOCError];
            
            [[AppDelegate sharedDelegate].scheduleMain_VC reloadEventsFromCalendarViewController];
        });
    }
    
}
- (BOOL)parseResourcesCalendarsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
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
        
        if ([current_user_id integerValue] == 0 && [invited_user_id integerValue] ==[[AppDelegate sharedDelegate].userId integerValue]) {
            continue;
        }
        
        
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
            resourcesCalendar.event_identify = [self saveCurrentEventOnCalendar:resourcesCalendar withContext:context];
            requireRepopulate = YES;
        } else if (fetchedResourcesCalendars.count == 1) {
            // check if the group has been updated
            resourcesCalendar = [fetchedResourcesCalendars objectAtIndex:0];
            resourcesCalendar.title = title;
            resourcesCalendar.endDate = endDate;
            resourcesCalendar.event_local_id = event_local_id;
            resourcesCalendar.aircraft = aircraft;
            resourcesCalendar.classroom = classroom;
            resourcesCalendar.lastUpdate = epochMicros;
            resourcesCalendar.startDate = startDate;
            resourcesCalendar.user_id = current_user_id;
            resourcesCalendar.group_id = group_id;
            resourcesCalendar.alertTimeInterVal = alertTimeInterVal;
            resourcesCalendar.timeIntervalStartDate = [NSNumber numberWithDouble:[[formaatter dateFromString:startDate] timeIntervalSince1970] * 1000000];
            resourcesCalendar.timeIntervalEndDate = [NSNumber numberWithDouble:[[formaatter dateFromString:endDate] timeIntervalSince1970] * 1000000];
            
            if ([resourcesCalendar.calendar_name isEqualToString:@""]) {
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
                resourcesCalendar.calendar_identify = [self getCalendarIdentify:resourcesCalendar.calendar_name];
            }
            
            
            
            if (resourcesCalendar.event_identify == nil || [resourcesCalendar.event_identify isEqualToString:@""]) {
                resourcesCalendar.event_identify = [self saveCurrentEventOnCalendar:resourcesCalendar withContext:context];
            }
            [self updateCurrentEventOnCalendar:resourcesCalendar];
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
            resourcesCalendar.event_identify = [self saveCurrentEventOnCalendar:resourcesCalendar withContext:context];
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

- (void)updateCurrentEventOnCalendar:(ResourcesCalendar *)resourcesCalendar{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    NSError *error;
    EKEvent *eventToUpdate = [eventStore eventWithIdentifier:resourcesCalendar.event_identify];
    if (eventToUpdate) {
        eventToUpdate.title = resourcesCalendar.title;
        eventToUpdate.startDate = [dateFormatter dateFromString:resourcesCalendar.startDate];
        eventToUpdate.endDate = [dateFormatter dateFromString:resourcesCalendar.endDate];
        [eventStore saveEvent:eventToUpdate span:EKSpanThisEvent error:&error];
        if (error != nil) {
            NSLog(@"Event Saving Error : %@", error.localizedDescription);
        }
        if ([resourcesCalendar.alertTimeInterVal integerValue] >= 0) {
            
            if ([[AppDelegate sharedDelegate] isShownHideCurrentEventFromLocal:eventToUpdate]) {
                [[AppDelegate sharedDelegate] updateLocalNotificationWithReservation:resourcesCalendar.title withTimeInterVal:[resourcesCalendar.alertTimeInterVal integerValue] withAlertTitle:resourcesCalendar.title withStartDate:[dateFormatter dateFromString:resourcesCalendar.startDate] withEventIdentify:eventToUpdate.eventIdentifier];
            }
        }
    }
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
- (NSString *)saveCurrentEventOnCalendar:(ResourcesCalendar *)resourcesCalendar withContext:(NSManagedObjectContext *)context{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    EKEvent *ev = [EKEvent eventWithEventStore:eventStore];
    ev.title = resourcesCalendar.title;
    ev.startDate = [dateFormatter dateFromString:resourcesCalendar.startDate];
    ev.endDate = [dateFormatter dateFromString:resourcesCalendar.endDate];
    
    NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    BOOL isExistCalendar = NO;
    for (EKCalendar *currentCalendar in calendars) {
        if ([currentCalendar.title isEqualToString:resourcesCalendar.calendar_name]) {
            ev.calendar = currentCalendar;
            isExistCalendar = YES;
        }
    }
    
//    if (!isExistCalendar) {
//        ev.calendar = [self addOrUpdateCalendarWithString:resourcesCalendar.calendar_name withEventStore:eventStore];
//    }
    
    
    NSError *error;
    [eventStore saveEvent:ev span:EKSpanThisEvent error:&error];
    if (error != nil) {
        NSLog(@"Event Saving Error : %@", error.localizedDescription);
        if (error.code == 4) {
            DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
            deleteQueryForAssignment.type = @"resourcesCalendars";
            deleteQueryForAssignment.idToDelete = resourcesCalendar.event_id;
            [context save:&error];
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
        }
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
- (EKCalendar *)addOrUpdateCalendarWithString:(NSString *)calendarId withEventStore:(EKEventStore *)eventStore{
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
                return calendar;
            }
        }
    }
    return nil;
}
@end
