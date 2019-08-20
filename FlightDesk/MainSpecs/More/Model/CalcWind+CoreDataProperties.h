//
//  CalcWind+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcWind+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcWind (CoreDataProperties)

+ (NSFetchRequest<CalcWind *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *windDirection;
@property (nullable, nonatomic, copy) NSNumber *windSpeed;
@property (nullable, nonatomic, copy) NSNumber *trueAirSpeed;
@property (nullable, nonatomic, copy) NSNumber *course;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
