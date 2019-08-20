//
//  SyncManagerGeneral.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/26/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerGeneral.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"

#define FOREGROUND_UPDATE_INTERVAL 10 // 1 minute (TODO: make this configurable)
@interface SyncManagerGeneral ()
@property (strong, nonatomic) dispatch_source_t syncTimerForGeneral;
@end
@implementation SyncManagerGeneral
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
        self.syncTimerForGeneral = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForGeneral) {
            dispatch_source_set_timer(self.syncTimerForGeneral, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForGeneral, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForGeneral);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForGeneral);
    dispatch_source_set_cancel_handler(self.syncTimerForGeneral, ^{
        self.syncTimerForGeneral = nil;
    });
    self.syncTimerForGeneral = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"********* START With syncTimerForGeneral *********");
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
        
        [self uploadQueriesToDelete:apiURLString andUserID:userID];
    }else{
        NSLog(@"Already was stared to sync *** syncTimerForGeneral ***");
    }
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
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                [self uploadGeneralContents:apiURLString andUserID:userID];
            }else{
                [self performUsersSyncCheck:apiURLString andUserID:userID];
            }
        }];
        [uploadQueriesTask resume];
    }else{
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            [self uploadGeneralContents:apiURLString andUserID:userID];
        }else{
            [self performUsersSyncCheck:apiURLString andUserID:userID];
        }
    }
}
- (void)uploadGeneralContents:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** syncTimerForGeneral Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadGeneralContents");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GeneralFlightDesk" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedRecordsFiles = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedRecordsFiles.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save GeneralFlightDesk until logged in!");
            return;
        }
        
        GeneralFlightDesk *generalFlightDesk = fetchedRecordsFiles[0];
        NSManagedObjectID *generalFlightDeskID = [generalFlightDesk objectID];
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_generalcontents", @"action", userID, @"user_id",generalFlightDesk.gettingStart, @"gettingStart",generalFlightDesk.termsOfUse, @"termsOfUse", generalFlightDesk.privacy, @"privacy", generalFlightDesk.copyrightAndTradeMarks, @"copyrightsAndTradeMarks", nil];
        NSData *recordsFilesJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveRecordsFileRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveRecordsFileRequest setHTTPMethod:@"POST"];
        [saveRecordsFileRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveRecordsFileRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveRecordsFileRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)recordsFilesJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveRecordsFileRequest setHTTPBody:recordsFilesJSON];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadRecordsFileTask = [session dataTaskWithRequest:saveRecordsFileRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadGeneralContentsResults:data AndRecordID:generalFlightDeskID contextForRecordsFile:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading recordsfiles";
                }
                FDLogError(@"%@", errorText);
            }
            [self uploadFaqsContents:apiURLString andUserID:userID];
        }];
        [uploadRecordsFileTask resume];
    } else {
        [self uploadFaqsContents:apiURLString andUserID:userID];
    }
}
- (void)handleUploadGeneralContentsResults:(NSData *)results AndRecordID:(NSManagedObjectID *)generalFlightDeskID contextForRecordsFile:(NSManagedObjectContext *)_contextRecordsFile{
    NSError *error;
    // parse the query results
    NSDictionary *recordsFileResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for general data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    NSNumber *resultBool = [recordsFileResults objectForKey:@"success"];
    NSNumber *timestamp = [recordsFileResults objectForKey:@"timestamp"];
    NSString *errorStr = [recordsFileResults objectForKey:@"error_str"];
    if ([resultBool boolValue] == YES) {
        GeneralFlightDesk *generalFlightDesk = [_contextRecordsFile existingObjectWithID:generalFlightDeskID error:&error];
        generalFlightDesk.lastUpdate = timestamp;
    }
    if ([_contextRecordsFile hasChanges]) {
        [_contextRecordsFile save:&error];
    }
}
- (void)uploadFaqsContents:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** syncTimerForGeneral Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadFaqsContents");
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Faqs" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedFaqsFiles = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedFaqsFiles.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save GeneralFlightDesk until logged in!");
            return;
        }
        NSMutableArray *faqsFiles = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedFaqsIDs = [[NSMutableArray alloc] init];
        for (Faqs *faqs in fetchedFaqsFiles) {
            NSArray *recordsFilesArray = [[NSArray alloc] initWithObjects:faqs.faqs_id,faqs.faqs_local_id, faqs.category, faqs.question, faqs.answer, faqs.lastSync, faqs.lastUpdate, nil];
            [faqsFiles addObject:recordsFilesArray];
            [fetchedFaqsIDs addObject:[faqs objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_faqs", @"action", userID, @"user_id",type, @"user_type", faqsFiles, @"faqs", nil];
        NSData *faqsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *savefaqsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveFaqsRequest = [NSMutableURLRequest requestWithURL:savefaqsURL];
        [saveFaqsRequest setHTTPMethod:@"POST"];
        [saveFaqsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveFaqsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveFaqsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)faqsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveFaqsRequest setHTTPBody:faqsJSON];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadFaqsTask = [session dataTaskWithRequest:saveFaqsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadFaqsResults:data AndFaqsIDs:fetchedFaqsIDs contextForFaqs:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading faqs";
                }
                FDLogError(@"%@", errorText);
            }
            [self performUsersSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadFaqsTask resume];
    } else {
        [self performUsersSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadFaqsResults:(NSData *)results AndFaqsIDs:(NSArray *)faqsIDs contextForFaqs:(NSManagedObjectContext *)_contextFaqs{
    NSError *error;
    // parse the query results
    NSDictionary *faqsResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for faqs data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [faqsResults objectForKey:@"faqs"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected faqs results element which was not an array!");
        return;
    }
    NSArray *faqsResultsArray = value;
    
    int faqsIndex = 0;
    for (id faqsResultElement in faqsResultsArray) {
        if ([faqsResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *faqsResultFields = faqsResultElement;
            NSNumber *resultBool = [faqsResultFields objectForKey:@"success"];
            NSNumber *recordID = [faqsResultFields objectForKey:@"faqs_id"];
            NSNumber *timestamp = [faqsResultFields objectForKey:@"timestamp"];
            if (faqsIndex < [faqsIDs count]) {
                NSManagedObjectID *faqsID = [faqsIDs objectAtIndex:faqsIndex];
                Faqs *faqs = [_contextFaqs existingObjectWithID:faqsID error:&error];
                if ([resultBool boolValue] == YES) {
                    faqs.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (faqs.faqs_id == nil || [faqs.faqs_id integerValue] == 0) {
                        faqs.faqs_id = recordID;
                    } else if ([faqs.faqs_id intValue] != [recordID intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        faqsIndex += 1;
    }
    
    if ([_contextFaqs hasChanges]) {
        [_contextFaqs save:&error];
    }
}
- (void)performGeneralContentSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** syncTimerForGeneral Sycn is stoped forcibly ***");
        return;
    }
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** syncTimerForGeneral Sycn is stoped forcibly ***");
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** faqs Sycn is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"*********** END with faqs ***********");
        }
        
        
    }];
    [faqsTask resume];
}
- (void)handleFaqsUpdate:(NSData *)results{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** faqs Sycn is stoped forcibly ***");
        return;
    }
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
    isStarted = NO;
    NSLog(@"*********** END with faqs ***********");
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** faqs Sycn is stoped forcibly ***");
        return NO;
    }
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
        
        [self performGeneralContentSyncCheck:apiURLString andUserID:userID];
        
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
@end
