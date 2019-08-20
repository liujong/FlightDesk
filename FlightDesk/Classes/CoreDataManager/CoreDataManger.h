//
//  CoreDataManger.h
//  FlightDesk
//
//  Created by Liu Jie on 1/28/18.
//  Copyright © 2018 spider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataManger : NSObject

+(CoreDataManger*)sharedCoreManager;
- (ContentRecord *)getContentRecord:(NSNumber *)contentLocalID withContext:(NSManagedObjectContext *)context;
- (LessonGroup *)getLessonGroup:(NSNumber *)lessonGroupLocalID withContext:(NSManagedObjectContext *)context;
- (LessonGroup *)getParentLessonGroup:(NSNumber *)lessonGroupLocalID withContext:(NSManagedObjectContext *)context;
- (LessonRecord *)getLessonRecord:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context;
- (LogEntry *)getLogEntry:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context;
- (Endorsement *)getEndorsement:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context;
- (Lesson *)getLesson:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistLessonOfParentGroup:(LessonGroup *)parentGroup returnLessons:(NSMutableArray **)lessonsArray withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistLessonGroupOfParentGroup:(LessonGroup *)parentGroup returnLessonGroups:(NSMutableArray **)groupsArray withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistContentOfLesson:(NSNumber *)lessonLocalID returnContents:(NSMutableArray **)contents withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistAssignmentOfLesson:(NSNumber *)lessonLocalID returnContents:(NSMutableArray **)contents withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistEndorsementOfLogEntry:(NSNumber *)logEnryLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistQuestionstOfQuiz:(NSNumber *)quizLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistDocumentOfLessonGroup:(NSNumber *)groupLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context;
- (BOOL)isExistContentRecordOfLessonRecord:(NSNumber *)lessonRecordLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context;

- (NSNumber *)getGroupID:(NSNumber *)groupLocalID withContext:(NSManagedObjectContext *)context;

- (void)removeAllContentFromLesson:(NSNumber *)lesson_local_id withContext:(NSManagedObjectContext *)contextToDel;
- (void)removeAllAssignmentFromLesson:(NSNumber *)lesson_local_id withContext:(NSManagedObjectContext *)contextToDel;
- (void)removeAllEndorsementFromLog:(NSNumber *)log_local_id withContext:(NSManagedObjectContext *)contextToDel;
- (void)removeAllQuestionsFromQuiz:(NSNumber *)quiz_local_id withContext:(NSManagedObjectContext *)contextToDel;
@end
