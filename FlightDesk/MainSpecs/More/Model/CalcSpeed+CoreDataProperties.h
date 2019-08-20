//
//  CalcSpeed+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcSpeed+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcSpeed (CoreDataProperties)

+ (NSFetchRequest<CalcSpeed *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *as;
@property (nullable, nonatomic, copy) NSNumber *alt;
@property (nullable, nonatomic, copy) NSNumber *tas;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
