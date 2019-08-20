//
//  SyncManagerQuiz.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/21/17.
//  Copyright © 2017 spider. All rights reserved.
//

// Order of Operations:
//
// uploadQueriesToDelete
// uploadQuizes
// ==> handleUploadQuizRecordResults
// performQuizesSyncCheck
// handleQuizesUpdate

#import "SyncManagerQuiz.h"
#import "Reachability.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "Student+CoreDataClass.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"
#define FOREGROUND_UPDATE_INTERVAL 15 // 1 minute (TODO: make this configurable)

@interface SyncManagerQuiz ()
@property (strong, nonatomic) dispatch_source_t syncTimerForQuiz;
@end
@implementation SyncManagerQuiz
{
    Reachability *serverReachability;
    BOOL isStarted;
    BOOL isStopedbyOther;
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
        isStopedbyOther = NO;
        self.syncTimerForQuiz = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (self.syncTimerForQuiz) {
            dispatch_source_set_timer(self.syncTimerForQuiz, dispatch_time(DISPATCH_TIME_NOW, FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC), FOREGROUND_UPDATE_INTERVAL * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            dispatch_source_set_event_handler(self.syncTimerForQuiz, ^
                                              {
                                                  if ([AppDelegate sharedDelegate].isLogin == YES) {
                                                      [self performSyncCheck];
                                                  }
                                              });
            dispatch_resume(self.syncTimerForQuiz);
        }
        // perform initial synchronization
        if ([AppDelegate sharedDelegate].isLogin == YES) {
            [self performSyncCheck];
        }
    }
    return self;
}
- (void)cancelSycnTimer{
    dispatch_source_cancel(self.syncTimerForQuiz);
    dispatch_source_set_cancel_handler(self.syncTimerForQuiz, ^{
        self.syncTimerForQuiz = nil;
    });
    self.syncTimerForQuiz = nil;
    isStarted = NO;
    isStopedbyOther = YES;
}
- (void)performSyncCheck
{
    if (!isStarted) {
        isStarted = YES;
        NSLog(@"********* START With Quiz *********");
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
        NSLog(@"Already was stared to sync *** QUIZ ***");
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
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DeleteQuery" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    // all quizes with lastUpdate == 0 need to be uploaded
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idToDelete != 0"];
    [request setPredicate:predicate];
    NSArray *fetchedQueriesToDelete = [context executeFetchRequest:request error:&error];
    // create dictionary for uploading Quizs
    if (fetchedQueriesToDelete.count > 0) {
        // make sure we are logged in
        
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save quizes until logged in!");
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
        NSData *quizRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveQuizsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveQuizsRequest = [NSMutableURLRequest requestWithURL:saveQuizsURL];
        [saveQuizsRequest setHTTPMethod:@"POST"];
        [saveQuizsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveQuizsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveQuizsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)quizRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveQuizsRequest setHTTPBody:quizRecordsJSON];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadQueriesTask = [session dataTaskWithRequest:saveQuizsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
            
            [self uploadQuizes:apiURLString andUserID:userID];
        }];
        [uploadQueriesTask resume];
    }else{
        [self uploadQuizes:apiURLString andUserID:userID];
    }
}
- (void)uploadQuizes:(NSString*)apiURLString andUserID:(NSNumber*)userID{
    if (isStopedbyOther) {
        isStopedbyOther = NO;
        NSLog(@"*** Quiz sync is stoped forcibly ***");
        return;
    }
    FDLogDebug(@"uploadQuizes");
    NSError *error;
    // upload Quizes
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:self.mainManagedObjectContext];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedQuizes = [self.mainManagedObjectContext executeFetchRequest:request error:&error];
    // create dictionary for uploading Quizs
    if (fetchedQuizes.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save quizes until logged in!");
            return;
        }
        //FDLogDebug(@"Found %lu quizes to upload!", (unsigned long)fetchedQuizRecords.count);
        // create array of Quiz record arrays [[recordId, QuizID, flightCompleted...], ...]
        NSMutableArray *quizRecords = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedQuizRecordIDs = [[NSMutableArray alloc] init];
        for (Quiz *quiz in fetchedQuizes) {
            NSMutableArray *questionRecordArray = [[NSMutableArray alloc] init];
            for (Question *question in quiz.questions) {
                //[self addQuestion:question RecordsToArray:questionRecordArray];
                NSArray *questionArray = [[NSArray alloc] initWithObjects:question.marked, question.answerA, question.answerB, question.answerC, question.correctAnswer, question.explanationReference, question.explanationofcorrectAnswer, question.explanationcode, question.gaveAnswer, question.question, question.questionId, question.recodeId,question.figureurl,  question.ordering,nil];
                [questionRecordArray addObject:questionArray];
            }
            // the user ID has to be the user of the Quiz! (not necessarily the currently logged in user)
            NSNumber *quizRecordUserID = quiz.studentUserID;
            NSArray *quizRecordArray = [[NSArray alloc] initWithObjects:quiz.name, quiz.timeLimit, quiz.courseGroupID, quiz.passingScore, quiz.gotScore,  quiz.quizNumber, quiz.quizTaken, quiz.quizId, quizRecordUserID, quiz.lastSync, quiz.lastUpdate, questionRecordArray, quiz.recordId,quiz.quizGroupId, nil];
            [quizRecords addObject:quizRecordArray];
            [fetchedQuizRecordIDs addObject:[quiz objectID]];
        }
        NSString *type;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            type = @"1";
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            type = @"3";
        }else{
            type = @"2";
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_quiz_records", @"action", userID, @"user_id",type, @"user_type", quizRecords, @"quiz_records", nil];
        NSData *quizRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveQuizsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveQuizsRequest = [NSMutableURLRequest requestWithURL:saveQuizsURL];
        [saveQuizsRequest setHTTPMethod:@"POST"];
        [saveQuizsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveQuizsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveQuizsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)quizRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveQuizsRequest setHTTPBody:quizRecordsJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:QuizRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the quizes! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveQuizsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadQuizRecordResults:data AndRecordIDs:fetchedQuizRecordIDs contextForQuiz:self.mainManagedObjectContext];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading quizes";
                }
                FDLogError(@"%@", errorText);
            }
            [self performQuizesSyncCheck:apiURLString andUserID:userID];
        }];
        [uploadQuizRecordsTask resume];
    } else {
        [self performQuizesSyncCheck:apiURLString andUserID:userID];
    }
}
- (void)handleUploadQuizRecordResults:(NSData *)results AndRecordIDs:(NSArray *)quizRecordIDs contextForQuiz:(NSManagedObjectContext *)_contextQuiz{
    NSError *error;
    // parse the query results
    NSDictionary *quizResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for quiz results data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [quizResults objectForKey:@"quiz_records"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected quiz results element which was not an array!");
        return;
    }
    NSArray *quizRecordResultsArray = value;
    
    int quizIndex = 0;
    for (id quizRecordResultElement in quizRecordResultsArray) {
        if ([quizRecordResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *quizRecordResultFields = quizRecordResultElement;
            NSNumber *resultBool = [quizRecordResultFields objectForKey:@"success"];
            NSNumber *recordID = [quizRecordResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [quizRecordResultFields objectForKey:@"timestamp"];
            NSString *errorStr = [quizRecordResultFields objectForKey:@"error_str"];
            NSArray *questionArray = [quizRecordResultFields objectForKey:@"questions"];
            if (quizIndex < [quizRecordIDs count]) {
                NSManagedObjectID *QuizRecordID = [quizRecordIDs objectAtIndex:quizIndex];
                Quiz *quizRecord = [_contextQuiz existingObjectWithID:QuizRecordID error:&error];
                if ([resultBool boolValue] == YES) {
                    quizRecord.lastSync = timestamp;
                    quizRecord.lastUpdate = timestamp;
                    for (Question *questionToUpdate in quizRecord.questions) {
                        questionToUpdate.lastSync = timestamp;
                        questionToUpdate.lastUpdate = timestamp;
                    }
                    // insert/update succeeded, save record id
                    if (quizRecord.recordId == nil || [quizRecord.recordId integerValue] == 0) {
                        quizRecord.recordId = recordID;
                    } else if ([quizRecord.recordId intValue] != [recordID intValue]) {
                        FDLogError(@"New Quizrecordid %@ for record with existing ID %@", recordID, quizRecord.recordId);
                    }
                    
                    for (Question *questionToUpdate in quizRecord.questions) {
                        for (NSDictionary *questionDetails in questionArray) {
                            NSNumber *resultBoolForQuestion = [questionDetails objectForKey:@"success"];
                            NSNumber *recordIDForQuestion = [questionDetails objectForKey:@"record_id"];
                            NSNumber *orderingForQuestion = [questionDetails objectForKey:@"ordering"];
                            if ([resultBoolForQuestion boolValue] == YES) {
                                if ([questionToUpdate.ordering integerValue] == [orderingForQuestion integerValue]) {
                                    if (questionToUpdate.recodeId == nil || [questionToUpdate.recodeId integerValue] == 0) {
                                        questionToUpdate.recodeId = recordIDForQuestion;
                                    } else if ([questionToUpdate.recodeId intValue] != [recordIDForQuestion intValue]) {
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    
                } else {
                    FDLogError(@"Failed to insert/update Quiz for Quiz with ID %@: %@", quizRecord.quizId, errorStr);
                }
            } else {
                NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
                FDLogError(@"Failed to store QuizRecrodId due to out-of-bounds index %d (total records %d): %@", quizIndex, [quizRecordIDs count], jsonStrData);
            }
        }
        quizIndex += 1;
    }
    
    if ([_contextQuiz hasChanges]) {
        [_contextQuiz save:&error];
    }
}
- (void)performQuizesSyncCheck:(NSString*)apiURLString andUserID:(NSNumber*)userID
{
    if (isStopedbyOther) {
        isStopedbyOther = NO;
        NSLog(@"*** Quiz sync is stoped forcibly ***");
        return;
    }
    // quizes
    // check if there are any Quiz updates to download from the web service
    NSNumber *lastQuizesUpdate = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"last_quizes_update"];
    if (lastQuizesUpdate == nil) {
        lastQuizesUpdate = [[NSNumber alloc] initWithInt:0];
    }
    NSURL *quizsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:quizsURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    NSDictionary *quizesRequestDict = [NSDictionary dictionaryWithObjectsAndKeys:@"get_quizes", @"action", type, @"user_type",  userID, @"user_id", lastQuizesUpdate, @"last_update", nil];
    NSError *error;
    NSData *jsonQuizRequestData =[NSJSONSerialization dataWithJSONObject:quizesRequestDict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonQuizRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonQuizRequestData];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *quizsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        if (data != nil) {
            [self handleQuizesUpdate:data];
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download Quizes: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download Quizes due to unknown error!");
            }
            
            
            NSLog(@"********* END With Quiz *********");
            isStarted = NO;
        }
    }];
    [quizsTask resume];
}
- (void)handleQuizesUpdate:(NSData *)results{
    if (isStopedbyOther) {
        isStopedbyOther = NO;
        NSLog(@"*** Quiz sync is stoped forcibly ***");
        return;
    }
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
        FDLogError(@"Unable to parse JSON for quiz data: %@", error);
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
        //FDLogDebug(@"Received latest Quizs update %@ (%@)", epoch_microseconds, newSyncTime);
    } else {
        FDLogError(@"Skipped quizes update with invalid last_update time!");
        return;
    }
    BOOL requireRepopulate = NO;
    value = [quizResults objectForKey:@"quizes"];
    if ([self parseQuizArray:value IntoContext:quizesManagedObjectContext WithSync:epoch_microseconds] == YES) {
        requireRepopulate = YES;
    }
    
    NSLog(@"********* END With Quiz *********");
    isStarted = NO;
    
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
    if (isStopedbyOther) {
        isStopedbyOther = NO;
        NSLog(@"*** Quiz sync is stoped forcibly ***");
        return NO;
    }
    BOOL requireRepopulate = NO;
    NSError *error;
    for (id quizElement in quizsArray) {
        if ([quizElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected quizes element which was not a dictionary!");
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
//            if ([quiz.lastSync longLongValue] < [lastSync longLongValue]) {
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
//            }
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
        }
    }
    // loop through quizes, delete any that have not been synced
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
    
    
    // loop through quizes, delete any that have not been synced
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
@end
