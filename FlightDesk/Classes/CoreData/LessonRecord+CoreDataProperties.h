//
//  LessonRecord+CoreDataProperties.h
//  FlightDesk
//
//  Created by Gregory Bayard on 3/27/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LessonRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface LessonRecord (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *flightCompleted;
@property (nullable, nonatomic, retain) NSString *flightNotes;
@property (nullable, nonatomic, retain) NSString *groundCompleted;
@property (nullable, nonatomic, retain) NSString *groundNotes;
@property (nullable, nonatomic, retain) NSNumber *instructorID;
@property (nullable, nonatomic, retain) NSNumber *lastSync;
@property (nullable, nonatomic, retain) NSNumber *lastUpdate;
@property (nullable, nonatomic, retain) NSDate *lessonDate;
@property (nullable, nonatomic, retain) NSNumber *recordID;
@property (nullable, nonatomic, retain) NSNumber *userID;
@property (nullable, nonatomic, retain) Lesson *lesson;
@property (nullable, nonatomic, retain) LogEntry *lessonLog;

@end

NS_ASSUME_NONNULL_END
