//
//  LessonGroup+CoreDataClass.h
//  
//
//  Created by Liu Jie on 8/3/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Document, Lesson, Quiz, Student;

NS_ASSUME_NONNULL_BEGIN

@interface LessonGroup : NSManagedObject 

@end

NS_ASSUME_NONNULL_END

#import "LessonGroup+CoreDataProperties.h"
