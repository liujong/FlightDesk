//
//  SyncManagerAircraft.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/21/17.
//  Copyright © 2017 spider. All rights reserved.
//
// Order of Operations:
//
// uploadQueriesToDelete
// uploadAirCraft
// ==> handleUploadAircraftsResults
// performAircraftSyncCheck
// handleAircraftsUpdate
#import "SyncManagerAircraft.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"

#define FOREGROUND_UPDATE_INTERVAL 5 // 1 minute (TODO: make this configurable)

@interface SyncManagerAircraft ()
@property (strong, nonatomic) dispatch_source_t syncTimerForAircraft;
@end

@implementation SyncManagerAircraft
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
        self.syncTimerForAircraft = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForAircraft) {
            dispatch_source_set_timer(self.syncTimerForAircraft, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForAircraft, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForAircraft);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForAircraft);
    dispatch_source_set_cancel_handler(self.syncTimerForAircraft, ^{
        self.syncTimerForAircraft = nil;
    });
    self.syncTimerForAircraft = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"*********** START with AIRCRAFT ***********");
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
        NSLog(@"Already was stared to sync *** AIRCRAFT ***");
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
        NSLog(@"*** Aricraft Sycn is stoped forcibly ***");
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
            
            [self uploadAirCraft:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadAirCraft:apiURLString andUserID:userID];
    }
}
- (void)uploadAirCraft:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aricraft Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadAircraft");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedAircrafts = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedAircrafts.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *aircrafts = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedAircraftIDs = [[NSMutableArray alloc] init];
        for (Aircraft *aircraft in fetchedAircrafts) {
            NSArray *aircraftArray = [[NSArray alloc] initWithObjects:aircraft.aircraftID, aircraft.aircraftItems, aircraft.maintenanceItems, aircraft.avionicsItems, aircraft.liftLimitedParts, aircraft.otherItems, aircraft.squawksItems, aircraft.lastSync, aircraft.lastUpdate,aircraft.aircraft_local_id, nil];
            [aircrafts addObject:aircraftArray];
            [fetchedAircraftIDs addObject:[aircraft objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_aircraft_items", @"action", userID, @"user_id",type, @"user_type", aircrafts, @"aircrafts", nil];
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
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadAircraftsResults:data AndRecordIDs:fetchedAircraftIDs contextForAircraft:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                FDLogError(@"%@", errorText);
            }
            [self uploadMaintenanceLogs:apiURLString andUserID:userID];
        }];
        [uploadQuizRecordsTask resume];
    } else {
        [self uploadMaintenanceLogs:apiURLString andUserID:userID];
    }
}
- (void)handleUploadAircraftsResults:(NSData *)results AndRecordIDs:(NSArray *)aircraftIDs contextForAircraft:(NSManagedObjectContext *)_contextAircraft{
    NSError *error;
    // parse the query results
    NSDictionary *aircraftResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for aircraft data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [aircraftResults objectForKey:@"aircrafts"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected aircraft results element which was not an array!");
        return;
    }
    NSArray *aircraftsResultsArray = value;
    
    int aircraftIndex = 0;
    for (id aircraftResultElement in aircraftsResultsArray) {
        if ([aircraftResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *aircraftResultFields = aircraftResultElement;
            NSNumber *resultBool = [aircraftResultFields objectForKey:@"success"];
            NSNumber *recordID = [aircraftResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [aircraftResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [aircraftResultFields objectForKey:@"error_str"];
            if (aircraftIndex < [aircraftIDs count]) {
                NSManagedObjectID *aircraftID = [aircraftIDs objectAtIndex:aircraftIndex];
                Aircraft *aircraft = [_contextAircraft existingObjectWithID:aircraftID error:&error];
                if ([resultBool boolValue] == YES) {
                    aircraft.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (aircraft.aircraftID == nil || [aircraft.aircraftID integerValue] == 0) {
                        aircraft.aircraftID = recordID;
                    } else if ([aircraft.aircraftID intValue] != [recordID intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        aircraftIndex += 1;
    }
    
    if ([_contextAircraft hasChanges]) {
        [_contextAircraft save:&error];
    }
}
- (void)uploadMaintenanceLogs:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aircraft Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadMaintenanceLogs");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND isUploaded == 1"];
    [request setPredicate:predicate];
    NSArray *fetchedMaintenanceLogss = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedMaintenanceLogss.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *maintenanceLogss = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedMaintenanceLogsIDs = [[NSMutableArray alloc] init];
        for (MaintenanceLogs *maintenanceLogs in fetchedMaintenanceLogss) {
            NSArray *maintenanceLogssArray = [[NSArray alloc] initWithObjects:maintenanceLogs.maintenancelog_id, maintenanceLogs.file_url, maintenanceLogs.file_name, maintenanceLogs.user_id, maintenanceLogs.aircraft_local_id, maintenanceLogs.lastSync, maintenanceLogs.lastUpdate, maintenanceLogs.fileSize,maintenanceLogs.fileType, maintenanceLogs.thumb_url,maintenanceLogs.recordsLocal_id, nil];
            [maintenanceLogss addObject:maintenanceLogssArray];
            [fetchedMaintenanceLogsIDs addObject:[maintenanceLogs objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_maintenanceLogs", @"action", userID, @"user_id",type, @"user_type", maintenanceLogss, @"maintenanceLogs", nil];
        NSData *maintenanceLogssJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveMaintenanceLogsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveMaintenanceLogsRequest setHTTPMethod:@"POST"];
        [saveMaintenanceLogsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveMaintenanceLogsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveMaintenanceLogsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)maintenanceLogssJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveMaintenanceLogsRequest setHTTPBody:maintenanceLogssJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadMaintenanceLogsTask = [session dataTaskWithRequest:saveMaintenanceLogsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadMaintenanceLogsResults:data AndRecordIDs:fetchedMaintenanceLogsIDs contextForMaintenanceLogs:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading recordsfiles";
                }
                FDLogError(@"%@", errorText);
            }
            [self performAircraftSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadMaintenanceLogsTask resume];
    } else {
        [self performAircraftSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadMaintenanceLogsResults:(NSData *)results AndRecordIDs:(NSArray *)maintenanceLogsIDs contextForMaintenanceLogs:(NSManagedObjectContext *)_contextMaintenanceLogs{
    NSError *error;
    // parse the query results
    NSDictionary *maintenanceLogsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for maintenanceLogs data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [maintenanceLogsResults objectForKey:@"maintenanceLogs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected recordsfile results element which was not an array!");
        return;
    }
    NSArray *maintenanceLogsResultsArray = value;
    
    int maintenanceLogsIndex = 0;
    for (id maintenanceLogsResultElement in maintenanceLogsResultsArray) {
        if ([maintenanceLogsResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *maintenanceLogsResultFields = maintenanceLogsResultElement;
            NSNumber *resultBool = [maintenanceLogsResultFields objectForKey:@"success"];
            NSNumber *maintenance_id = [maintenanceLogsResultFields objectForKey:@"maintenance_id"];
            NSNumber *timestamp = [maintenanceLogsResultFields objectForKey:@"timestamp"];
            
            if (maintenanceLogsIndex < [maintenanceLogsIDs count]) {
                NSManagedObjectID *maintenanceLogsID = [maintenanceLogsIDs objectAtIndex:maintenanceLogsIndex];
                MaintenanceLogs *maintenanceLogs = [_contextMaintenanceLogs existingObjectWithID:maintenanceLogsID error:&error];
                if ([resultBool boolValue] == YES) {
                    maintenanceLogs.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (maintenanceLogs.maintenancelog_id == nil || [maintenanceLogs.maintenancelog_id integerValue] == 0) {
                        maintenanceLogs.maintenancelog_id = maintenance_id;
                    } else if ([maintenanceLogs.maintenancelog_id intValue] != [maintenance_id intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        maintenanceLogsIndex += 1;
    }
    
    if ([_contextMaintenanceLogs hasChanges]) {
        [_contextMaintenanceLogs save:&error];
    }
}
- (void)performAircraftSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aricraft Sycn is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"*********** END with AIRCRAFT ***********");
        }
        
        [self performMaintenanceLogsSyncCheck:apiURLString andUserID:userID];
        
    }];
    [lessonsTask resume];
}
- (void)handleAircraftsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aricraft Sycn is stoped forcibly ***");
        return;
    }
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
    
}
- (BOOL)parseAircraftsArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)context WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aricraft Sycn is stoped forcibly ***");
        return NO;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aircraft Sycn is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"*********** END with Aircraft ***********");
        }
        
        
    }];
    [maintenanceLogsTask resume];
}
- (void)handleMaintenanceLogsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Aircraft Sycn is stoped forcibly ***");
        return;
    }
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
    
    isStarted = NO;
    NSLog(@"*********** END with AIRCRAFT ***********");
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** MaintenanceLogs Sycn is stoped forcibly ***");
        return NO;
    }
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
@end
