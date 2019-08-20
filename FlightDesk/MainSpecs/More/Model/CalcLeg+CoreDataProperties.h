//
//  CalcLeg+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcLeg+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcLeg (CoreDataProperties)

+ (NSFetchRequest<CalcLeg *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *leg1GS;
@property (nullable, nonatomic, copy) NSNumber *leg1Dist;
@property (nullable, nonatomic, copy) NSNumber *leg2Dist;
@property (nullable, nonatomic, copy) NSNumber *leg2GS;
@property (nullable, nonatomic, copy) NSNumber *leg3Dist;
@property (nullable, nonatomic, copy) NSNumber *leg3GS;
@property (nullable, nonatomic, copy) NSNumber *leg4Dist;
@property (nullable, nonatomic, copy) NSNumber *leg4GS;
@property (nullable, nonatomic, copy) NSNumber *fuelLoad;
@property (nullable, nonatomic, copy) NSNumber *galHr;
@property (nullable, nonatomic, copy) NSNumber *totalDist;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *leg1Time;
@property (nullable, nonatomic, copy) NSNumber *leg1DistRem;
@property (nullable, nonatomic, copy) NSNumber *leg1GalUsed;
@property (nullable, nonatomic, copy) NSNumber *leg1GalRem;
@property (nullable, nonatomic, copy) NSString *leg2Time;
@property (nullable, nonatomic, copy) NSNumber *leg2DistRem;
@property (nullable, nonatomic, copy) NSNumber *leg2GalUsed;
@property (nullable, nonatomic, copy) NSNumber *leg2GalRem;
@property (nullable, nonatomic, copy) NSString *leg3Time;
@property (nullable, nonatomic, copy) NSNumber *leg3DistRem;
@property (nullable, nonatomic, copy) NSNumber *leg3GalUsed;
@property (nullable, nonatomic, copy) NSNumber *leg3GalRem;
@property (nullable, nonatomic, copy) NSString *leg4Time;
@property (nullable, nonatomic, copy) NSNumber *leg4DistRem;
@property (nullable, nonatomic, copy) NSNumber *leg4GalUsed;
@property (nullable, nonatomic, copy) NSNumber *leg4GalRem;

@end

NS_ASSUME_NONNULL_END
