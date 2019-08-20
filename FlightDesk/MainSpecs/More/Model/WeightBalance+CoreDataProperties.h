//
//  WeightBalance+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/12/17.
//
//

#import "WeightBalance+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface WeightBalance (CoreDataProperties)

+ (NSFetchRequest<WeightBalance *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *auxTankArm;
@property (nullable, nonatomic, copy) NSNumber *auxTankMoment;
@property (nullable, nonatomic, copy) NSNumber *auxTankweight;
@property (nullable, nonatomic, copy) NSNumber *auxTankWeightGl;
@property (nullable, nonatomic, copy) NSNumber *backPax2Arm;
@property (nullable, nonatomic, copy) NSNumber *backPax2Moment;
@property (nullable, nonatomic, copy) NSNumber *backPax2Weight;
@property (nullable, nonatomic, copy) NSNumber *backPaxArm;
@property (nullable, nonatomic, copy) NSNumber *backPaxMoment;
@property (nullable, nonatomic, copy) NSNumber *backPaxWeight;
@property (nullable, nonatomic, copy) NSNumber *basicEmptyArm;
@property (nullable, nonatomic, copy) NSNumber *basicEmptyMoment;
@property (nullable, nonatomic, copy) NSNumber *basicEmptyWeight;
@property (nullable, nonatomic, copy) NSNumber *cargo1Arm;
@property (nullable, nonatomic, copy) NSNumber *cargo1Moment;
@property (nullable, nonatomic, copy) NSNumber *cargo1Weight;
@property (nullable, nonatomic, copy) NSNumber *cargo2Arm;
@property (nullable, nonatomic, copy) NSNumber *cargo2Moment;
@property (nullable, nonatomic, copy) NSNumber *cargo2Weight;
@property (nullable, nonatomic, copy) NSNumber *cg2BasicEmptyWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cg2BasicEmptyWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cg2EmptyFuelWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cg2EmptyFuelWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cg2GrossWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cg2GrossWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cg2TakeOffweightMax;
@property (nullable, nonatomic, copy) NSNumber *cg2TakeOffweightMin;
@property (nullable, nonatomic, copy) NSNumber *cgBasicEmptyWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cgBasicEmptyWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cgEmptyFuelWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cgEmptyFuelWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cgGrossWeightMax;
@property (nullable, nonatomic, copy) NSNumber *cgGrossWeightMin;
@property (nullable, nonatomic, copy) NSNumber *cgTakeOffweightMax;
@property (nullable, nonatomic, copy) NSNumber *cgTakeOffWeightMin;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelArm;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelMoment;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeight;
@property (nullable, nonatomic, copy) NSNumber *frontPax2Arm;
@property (nullable, nonatomic, copy) NSNumber *frontPax2Moment;
@property (nullable, nonatomic, copy) NSNumber *frontPax2Weight;
@property (nullable, nonatomic, copy) NSNumber *frontPaxArm;
@property (nullable, nonatomic, copy) NSNumber *frontPaxMoment;
@property (nullable, nonatomic, copy) NSNumber *frontPaxWeight;
@property (nullable, nonatomic, copy) NSNumber *mainTanksArm;
@property (nullable, nonatomic, copy) NSNumber *mainTanksMoment;
@property (nullable, nonatomic, copy) NSNumber *mainTanksWeight;
@property (nullable, nonatomic, copy) NSNumber *mainTanksWeightGl;
@property (nullable, nonatomic, copy) NSNumber *maxCargo1Weight;
@property (nullable, nonatomic, copy) NSNumber *maxCargo2Weight;
@property (nullable, nonatomic, copy) NSNumber *maxEmptyFuelWeight;
@property (nullable, nonatomic, copy) NSNumber *maxGrossWeight;
@property (nullable, nonatomic, copy) NSNumber *maxLandingWeight;
@property (nullable, nonatomic, copy) NSNumber *maxTakeOffWeight;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *totalArm;
@property (nullable, nonatomic, copy) NSNumber *totalMoment;
@property (nullable, nonatomic, copy) NSNumber *totalWeight;

@end

NS_ASSUME_NONNULL_END
