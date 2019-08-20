//
//  SyncManagerRecordsFiles.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SyncManagerRecordsFiles.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"

#define FOREGROUND_UPDATE_INTERVAL 5 // 1 minute (TODO: make this configurable)
@interface SyncManagerRecordsFiles ()
@property (strong, nonatomic) dispatch_source_t syncTimerForRecordsFiles;
@end
@implementation SyncManagerRecordsFiles
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
        self.syncTimerForRecordsFiles = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForRecordsFiles) {
            dispatch_source_set_timer(self.syncTimerForRecordsFiles, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForRecordsFiles, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForRecordsFiles);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForRecordsFiles);
    dispatch_source_set_cancel_handler(self.syncTimerForRecordsFiles, ^{
        self.syncTimerForRecordsFiles = nil;
    });
    self.syncTimerForRecordsFiles = nil;
    isStarted = NO;
    isStopedByOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"********* START With syncTimerForRecordsFiles *********");
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
        NSLog(@"Already was stared to sync *** syncTimerForRecordsFiles ***");
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
            
            [self uploadRecordsFiles:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadRecordsFiles:apiURLString andUserID:userID];
    }
}
- (void)uploadRecordsFiles:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadRecordsFiles");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0 AND isUploaded == 1"];
    [request setPredicate:predicate];
    NSArray *fetchedRecordsFiles = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading lessons
    if (fetchedRecordsFiles.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *recordsFiles = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedRecordsFileIDs = [[NSMutableArray alloc] init];
        for (RecordsFile *recordsFile in fetchedRecordsFiles) {
            NSArray *recordsFilesArray = [[NSArray alloc] initWithObjects:recordsFile.records_id, recordsFile.file_url, recordsFile.file_name, recordsFile.user_id, recordsFile.student_id, recordsFile.lastSync, recordsFile.lastUpdate, recordsFile.fileSize,recordsFile.fileType, recordsFile.thumb_url,recordsFile.recordsLocal_id, nil];
            [recordsFiles addObject:recordsFilesArray];
            [fetchedRecordsFileIDs addObject:[recordsFile objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_recordsfiles", @"action", userID, @"user_id",type, @"user_type", recordsFiles, @"records", nil];
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
        //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadRecordsFileTask = [session dataTaskWithRequest:saveRecordsFileRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadRecordsFileResults:data AndRecordIDs:fetchedRecordsFileIDs contextForRecordsFile:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading recordsfiles";
                }
                FDLogError(@"%@", errorText);
            }
            [self performUsersSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadRecordsFileTask resume];
    } else {
        [self performUsersSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadRecordsFileResults:(NSData *)results AndRecordIDs:(NSArray *)recordsFileIDs contextForRecordsFile:(NSManagedObjectContext *)_contextRecordsFile{
    NSError *error;
    // parse the query results
    NSDictionary *recordsFileResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for recordsFile data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [recordsFileResults objectForKey:@"records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected recordsfile results element which was not an array!");
        return;
    }
    NSArray *recordsFileResultsArray = value;
    
    int recordsFileIndex = 0;
    for (id recordsFileResultElement in recordsFileResultsArray) {
        if ([recordsFileResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *recordsFileResultFields = recordsFileResultElement;
            NSNumber *resultBool = [recordsFileResultFields objectForKey:@"success"];
            NSNumber *recordID = [recordsFileResultFields objectForKey:@"recordfile_id"];
            NSNumber *timestamp = [recordsFileResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [recordsFileResultFields objectForKey:@"error_str"];
            if (recordsFileIndex < [recordsFileIDs count]) {
                NSManagedObjectID *recordsFileID = [recordsFileIDs objectAtIndex:recordsFileIndex];
                RecordsFile *recordsFile = [_contextRecordsFile existingObjectWithID:recordsFileID error:&error];
                if ([resultBool boolValue] == YES) {
                    recordsFile.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (recordsFile.records_id == nil || [recordsFile.records_id integerValue] == 0) {
                        recordsFile.records_id = recordID;
                    } else if ([recordsFile.records_id intValue] != [recordID intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        recordsFileIndex += 1;
    }
    
    if ([_contextRecordsFile hasChanges]) {
        [_contextRecordsFile save:&error];
    }
}
- (void)performRecordsFileSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return;
    }
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
            isStarted = NO;
            NSLog(@"*********** END with recordsfiles ***********");
        }
        
        
    }];
    [recordsFileTask resume];
}
- (void)handleRecordsFileUpdate:(NSData *)results{
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
    isStarted = NO;
    NSLog(@"*********** END with RecordsFile ***********");
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
    if (isStopedByOther) {
        isStopedByOther = NO;
        NSLog(@"*** RecordsFile Sycn is stoped forcibly ***");
        return NO;
    }
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
        
        [self performRecordsFileSyncCheck:apiURLString andUserID:userID];
        
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
