//
//  CoreDataManger.m
//  FlightDesk
//
//  Created by Liu Jie on 1/28/18.
//  Copyright © 2018 spider. All rights reserved.
//

#import "CoreDataManger.h"

@implementation CoreDataManger
+(CoreDataManger*)sharedCoreManager
{
    CoreDataManger *coredataManer = [[CoreDataManger alloc] init];
    return coredataManer;
}
- (ContentRecord *)getContentRecord:(NSNumber *)contentLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ContentRecord" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"content_local_id == %@", contentLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (LessonGroup *)getLessonGroup:(NSNumber *)lessonGroupLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_local_id == %@", lessonGroupLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (LessonGroup *)getParentLessonGroup:(NSNumber *)lessonGroupLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_local_id == %@ AND parent_group_id = 0", lessonGroupLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (LessonRecord *)getLessonRecord:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (LogEntry *)getLogEntry:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (Endorsement *)getEndorsement:(NSNumber *)endorsementLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"endorsement_local_id == %@", endorsementLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (Lesson *)getLesson:(NSNumber *)lessonLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects.count > 0) {
        return objects[0];
    }
    return nil;
}
- (BOOL)isExistLessonOfParentGroup:(LessonGroup *)parentGroup returnLessons:(NSMutableArray **)lessonsArray withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", parentGroup.groupID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        NSMutableArray *tempLessonGroups = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lessonNumber" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedRootGroups = [tempLessonGroups sortedArrayUsingDescriptors:sortDescriptors];
        *lessonsArray = [sortedRootGroups mutableCopy];
        return YES;
    }
}
- (BOOL)isExistLessonGroupOfParentGroup:(LessonGroup *)parentGroup returnLessonGroups:(NSMutableArray **)groupsArray withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", parentGroup.parentGroup.groupID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        *groupsArray = [objects mutableCopy];
        return YES;
    }
}

- (BOOL)isExistContentOfLesson:(NSNumber *)lessonLocalID returnContents:(NSMutableArray **)contents withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Content" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        NSMutableArray *tempLessonGroups = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderNumber" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedRootGroups = [tempLessonGroups sortedArrayUsingDescriptors:sortDescriptors];
        *contents = [sortedRootGroups mutableCopy];
        return YES;
    }
}
- (BOOL)isExistAssignmentOfLesson:(NSNumber *)lessonLocalID returnContents:(NSMutableArray **)contents withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Assignment" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        *contents = [objects mutableCopy];
        return YES;
    }
}
- (BOOL)isExistEndorsementOfLogEntry:(NSNumber *)logEnryLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"logEntry_local_id == %@", logEnryLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        *dataObjects = [objects mutableCopy];
        return YES;
    }
}
- (BOOL)isExistQuestionstOfQuiz:(NSNumber *)quizLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Question" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quiz_local_id == %@", quizLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        NSMutableArray *tempLessonGroups = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ordering" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedRootGroups = [tempLessonGroups sortedArrayUsingDescriptors:sortDescriptors];
        *dataObjects = [sortedRootGroups mutableCopy];
        return YES;
    }
}
- (BOOL)isExistDocumentOfLessonGroup:(NSNumber *)groupLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_local_id == %@", groupLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        *dataObjects = [objects mutableCopy];
        return YES;
    }
}

- (BOOL)isExistContentRecordOfLessonRecord:(NSNumber *)lessonRecordLocalID returnContents:(NSMutableArray **)dataObjects withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ContentRecord" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id == %@", lessonRecordLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        *dataObjects = [objects mutableCopy];
        return YES;
    }
}


- (NSNumber *)getGroupID:(NSNumber *)groupLocalID withContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_local_id == %@", groupLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        return nil;
    } else if (objects.count == 0) {
        return nil;
    } else {
        LessonGroup *currentGroup = objects[0];
        return currentGroup.groupID;
    }
}
- (void)removeAllContentFromLesson:(NSNumber *)lesson_local_id withContext:(NSManagedObjectContext *)contextToDel{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Content" inManagedObjectContext:contextToDel];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id = %@", lesson_local_id];
    [request setPredicate:predicate];
    NSArray *fetchedContent = [contextToDel executeFetchRequest:request error:&error];
    if (fetchedContent.count > 0) {
        for (Content *contentToDel in fetchedContent) {
            [contextToDel deleteObject:contentToDel];
        }
    }
}
- (void)removeAllAssignmentFromLesson:(NSNumber *)lesson_local_id withContext:(NSManagedObjectContext *)contextToDel{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Assignment" inManagedObjectContext:contextToDel];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lesson_local_id = %@", lesson_local_id];
    [request setPredicate:predicate];
    NSArray *fetchedAssignment = [contextToDel executeFetchRequest:request error:&error];
    if (fetchedAssignment.count > 0) {
        for (Assignment *assignmentToDel in fetchedAssignment) {
            [contextToDel deleteObject:assignmentToDel];
        }
    }
}
- (void)removeAllEndorsementFromLog:(NSNumber *)log_local_id withContext:(NSManagedObjectContext *)contextToDel{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:contextToDel];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"logEntry_local_id = %@", log_local_id];
    [request setPredicate:predicate];
    NSArray *fetchedLogEntries = [contextToDel executeFetchRequest:request error:&error];
    if (fetchedLogEntries.count > 0) {
        for (Endorsement *endToDel in fetchedLogEntries) {
            [contextToDel deleteObject:endToDel];
        }
    }
}
- (void)removeAllQuestionsFromQuiz:(NSNumber *)quiz_local_id withContext:(NSManagedObjectContext *)contextToDel{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Question" inManagedObjectContext:contextToDel];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quiz_local_id = %@", quiz_local_id];
    [request setPredicate:predicate];
    NSArray *fetchedQuestions = [contextToDel executeFetchRequest:request error:&error];
    if (fetchedQuestions.count > 0) {
        for (Question *questionToDel in fetchedQuestions) {
            [contextToDel deleteObject:questionToDel];
        }
    }
}
@end
