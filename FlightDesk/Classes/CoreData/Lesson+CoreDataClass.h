//
//  Lesson+CoreDataClass.h
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Assignment, Content, LessonGroup, LessonRecord;

NS_ASSUME_NONNULL_BEGIN

@interface Lesson : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Lesson+CoreDataProperties.h"
