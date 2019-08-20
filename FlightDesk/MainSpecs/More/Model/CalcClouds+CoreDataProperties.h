//
//  CalcClouds+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcClouds+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcClouds (CoreDataProperties)

+ (NSFetchRequest<CalcClouds *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *cloudTemp;
@property (nullable, nonatomic, copy) NSNumber *dew;
@property (nullable, nonatomic, copy) NSNumber *bases;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
