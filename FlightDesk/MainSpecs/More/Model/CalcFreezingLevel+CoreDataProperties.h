//
//  CalcFreezingLevel+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcFreezingLevel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcFreezingLevel (CoreDataProperties)

+ (NSFetchRequest<CalcFreezingLevel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *temp;
@property (nullable, nonatomic, copy) NSNumber *ft;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
