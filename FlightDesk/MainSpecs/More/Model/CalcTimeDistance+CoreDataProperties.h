//
//  CalcTimeDistance+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcTimeDistance+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcTimeDistance (CoreDataProperties)

+ (NSFetchRequest<CalcTimeDistance *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *timeDistanceTime;
@property (nullable, nonatomic, copy) NSNumber *timeDistanceKts;
@property (nullable, nonatomic, copy) NSNumber *timeDistanceNM;
@property (nullable, nonatomic, copy) NSNumber *timeDistanceSM;
@property (nullable, nonatomic, copy) NSNumber *etaKTS;
@property (nullable, nonatomic, copy) NSNumber *etaNM;
@property (nullable, nonatomic, copy) NSNumber *etaSM;
@property (nullable, nonatomic, copy) NSString *etaTime;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
