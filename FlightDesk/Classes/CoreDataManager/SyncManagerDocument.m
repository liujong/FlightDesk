//
//  SyncManagerDocument.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/21/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerDocument.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "Document+CoreDataClass.h"

#define FOREGROUND_UPDATE_INTERVAL 5 // 1 minute (TODO: make this configurable)

@interface SyncManagerDocument ()

@property (strong, nonatomic) dispatch_source_t syncTimerForDoc;

@end
@implementation SyncManagerDocument
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
        self.syncTimerForDoc = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForDoc) {
            dispatch_source_set_timer(self.syncTimerForDoc, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForDoc, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForDoc);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForDoc);
    dispatch_source_set_cancel_handler(self.syncTimerForDoc, ^{
        self.syncTimerForDoc = nil;
    });
    self.syncTimerForDoc = nil;    
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        NSLog(@"*********** START with DOCUMENT ***********");
        isStarted = YES;
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
        NSLog(@"Already was stared to sync *** DOCUMENT ***");
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
        NSLog(@"*** Document sync is stoped forcibly ***");
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
            
            [self uploadDocument:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadDocument:apiURLString andUserID:userID];
    }
}

- (void)uploadDocument:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Document sync is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadDocument");
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND type == 1"];
    [request setPredicate:predicate];
    NSArray *fetchedDocuments = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedDocuments.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson until logged in!");
            return;
        }
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        NSMutableArray *fetchedDocumentids = [[NSMutableArray alloc] init];
        for (Document *document in fetchedDocuments) {
            NSArray *documentArray = [[NSArray alloc] initWithObjects:document.documentID ,document.name, document.remoteURL, nil];
            [documents addObject:documentArray];
            
            [fetchedDocumentids addObject:[document objectID]];
        }
        
        
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_documents", @"action", userID, @"user_id", documents, @"documents", nil];
        NSData *documentsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveDocumentURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveDocumentRequest = [NSMutableURLRequest requestWithURL:saveDocumentURL];
        [saveDocumentRequest setHTTPMethod:@"POST"];
        [saveDocumentRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveDocumentRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveDocumentRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)documentsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveDocumentRequest setHTTPBody:documentsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadDocumentTask = [session dataTaskWithRequest:saveDocumentRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadDocumentResults:data AndRecordIDs:fetchedDocumentids];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading documents";
                }
                FDLogError(@"%@", errorText);
            }
            
            [self uploadDocumentWithGroup:apiURLString andUserID:userID];
        }];
        [uploadDocumentTask resume];
    } else {
        [self uploadDocumentWithGroup:apiURLString andUserID:userID];
    }
}
- (void)uploadDocumentWithGroup:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Document sync is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadDocumentWithGroup");
    NSError *error;
    // upload lesson records
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    // all lesson records with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND type == 2"];
    [request setPredicate:predicate];
    NSArray *fetchedDocuments = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedDocuments.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson until logged in!");
            return;
        }
        NSMutableArray *documents = [[NSMutableArray alloc] init];
        NSMutableArray *fetchedDocumentids = [[NSMutableArray alloc] init];
        for (Document *document in fetchedDocuments) {
            NSArray *documentArray = [[NSArray alloc] initWithObjects:document.documentID, document.studentID, document.groupID, nil];
            [documents addObject:documentArray];
            [fetchedDocumentids addObject:[document objectID]];
        }
        
        NSString *type = @"";
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_documents_group", @"action", userID, @"user_id", documents, @"documents", type, @"user_type", nil];
        NSData *documentsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveDocumentURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveDocumentRequest = [NSMutableURLRequest requestWithURL:saveDocumentURL];
        [saveDocumentRequest setHTTPMethod:@"POST"];
        [saveDocumentRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveDocumentRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveDocumentRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)documentsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveDocumentRequest setHTTPBody:documentsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadDocumentTask = [session dataTaskWithRequest:saveDocumentRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                NSError *error;
                NSDictionary *documentResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                NSNumber *timestamp = [documentResults objectForKey:@"timestamp"];
                int lessonIndex = 0;
                for (id docuemtnElement in [documentResults objectForKey:@"documents"]) {
                    if ([docuemtnElement isKindOfClass:[NSDictionary class]]) {
                        if (lessonIndex < [fetchedDocumentids count]) {
                            NSManagedObjectID *doccumentsID = [fetchedDocumentids objectAtIndex:lessonIndex];
                            Document *document = [self.mainManagedObjectContext existingObjectWithID:doccumentsID error:&error];
                            document.lastUpdate = timestamp;
                        }
                    }
                    lessonIndex += 1;
                }
                
                if ([self.mainManagedObjectContext hasChanges]) {
                    [self.mainManagedObjectContext save:&error];
                }
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading document";
                }
                FDLogError(@"%@", errorText);
            }
            
            [self performDocumentsSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadDocumentTask resume];
    } else {
        [self performDocumentsSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadDocumentResults:(NSData *)results AndRecordIDs:(NSArray *)documentsIDs{
    NSError *error;
    // parse the query results
    NSDictionary *documentResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for documents results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [documentResults objectForKey:@"documents"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected documents results element which was not an array!");
        return;
    }
    NSArray *documentsResultsArray = value;
    NSManagedObjectContext *_contextForDocument = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_contextForDocument setParentContext:self.mainManagedObjectContext];
    int lessonIndex = 0;
    for (id docuemtnElement in documentsResultsArray) {
        if ([docuemtnElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *documentResultFields = docuemtnElement;
            NSNumber *resultBool = [documentResultFields objectForKey:@"success"];
            NSNumber *recordID = [documentResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [documentResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [documentResultFields objectForKey:@"error_str"];
            if (lessonIndex < [documentsIDs count]) {
                NSManagedObjectID *doccumentsID = [documentsIDs objectAtIndex:lessonIndex];
                Document *document = [_contextForDocument existingObjectWithID:doccumentsID error:&error];
                if ([resultBool boolValue] == YES) {
                    document.lastUpdate = timestamp;
                    if (document.documentID == nil || [document.documentID integerValue] == 0) {
                        document.documentID = recordID;
                    } else if ([document.documentID intValue] != [recordID intValue]) {
                        FDLogError(@"New DocumentID %@ for record with existing ID %@", recordID, document.documentID);
                    }
                } else {
                    FDLogError(@"Failed to insert/update Document with ID %@: %@", document.documentID, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store DocumentID due to out-of-bounds index %d (total records %d): %@", lessonIndex, [documentsIDs count], jsonStrData);
            }
        }
        lessonIndex += 1;
    }
    
    if ([_contextForDocument hasChanges]) {
        [_contextForDocument save:&error];
    }
}
- (void)performDocumentsSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Document sync is stoped forcibly ***");
        return;
    }
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
            
            NSLog(@"*********** END with DOCUMENT ***********");
            isStarted = NO;
        }
    }];
    [documentsTask resume];
}
- (void)handleDocumentsUpdate:(NSData *)results
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** Document sync is stoped forcibly ***");
        return;
    }
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
        
        //remove from group current document
        [self deleteDocumentFromGroup:documentToDelete withContext:documentsManagedObjectContext];
        
        [documentsManagedObjectContext deleteObject:documentToDelete];
        
    }
    
    NSLog(@"*********** END with DOCUMENT ***********");
    isStarted = NO;
    
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

    
- (void)deleteDocumentFromGroup:(Document *)focusDocument withContext:(NSManagedObjectContext *)docContext{
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:docContext];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] && ![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isShown == 1"];
        [groupRequest setPredicate:predicate];
    }
        
    NSError *error;
    NSArray *groupArray = [docContext executeFetchRequest:groupRequest error:&error];
    if (groupArray == nil) {
        FDLogError(@"Unable to retrieve lesson group!");
    } else if (groupArray.count == 0) {
        FDLogDebug(@"No groups stored!");
    } else {
        for (LessonGroup *group in groupArray) {
            if (group.parentGroup == nil) {
                for (Document *document in group.documents) {
                    if ([document.documentID integerValue] == [focusDocument.documentID integerValue]) {
                        [group removeDocumentsObject:focusDocument];
                    }
                }
            }
        }
    }
}
@end
