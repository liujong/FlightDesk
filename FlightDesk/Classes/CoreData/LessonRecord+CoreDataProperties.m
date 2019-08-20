//
//  LessonRecord+CoreDataProperties.m
//  FlightDesk
//
//  Created by Gregory Bayard on 3/27/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LessonRecord+CoreDataProperties.h"

@implementation LessonRecord (CoreDataProperties)

@dynamic flightCompleted;
@dynamic flightNotes;
@dynamic groundCompleted;
@dynamic groundNotes;
@dynamic instructorID;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic lessonDate;
@dynamic recordID;
@dynamic userID;
@dynamic lesson;
@dynamic lessonLog;

@end
