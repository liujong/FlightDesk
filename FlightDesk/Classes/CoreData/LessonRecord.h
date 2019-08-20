//
//  LessonRecord.h
//  FlightDesk
//
//  Created by Gregory Bayard on 11/8/15.
//  Copyright © 2015 NOVA.GregoryBayard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Lesson, LogEntry;

NS_ASSUME_NONNULL_BEGIN

@interface LessonRecord : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "LessonRecord+CoreDataProperties.h"
