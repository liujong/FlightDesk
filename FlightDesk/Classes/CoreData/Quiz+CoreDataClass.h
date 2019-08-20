//
//  Quiz+CoreDataClass.h
//  
//
//  Created by stepanekdavid on 6/28/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LessonGroup, Question;

NS_ASSUME_NONNULL_BEGIN

@interface Quiz : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Quiz+CoreDataProperties.h"
