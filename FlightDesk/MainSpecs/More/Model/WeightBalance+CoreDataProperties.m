//
//  WeightBalance+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/12/17.
//
//

#import "WeightBalance+CoreDataProperties.h"

@implementation WeightBalance (CoreDataProperties)

+ (NSFetchRequest<WeightBalance *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WeightBalance"];
}

@dynamic auxTankArm;
@dynamic auxTankMoment;
@dynamic auxTankweight;
@dynamic auxTankWeightGl;
@dynamic backPax2Arm;
@dynamic backPax2Moment;
@dynamic backPax2Weight;
@dynamic backPaxArm;
@dynamic backPaxMoment;
@dynamic backPaxWeight;
@dynamic basicEmptyArm;
@dynamic basicEmptyMoment;
@dynamic basicEmptyWeight;
@dynamic cargo1Arm;
@dynamic cargo1Moment;
@dynamic cargo1Weight;
@dynamic cargo2Arm;
@dynamic cargo2Moment;
@dynamic cargo2Weight;
@dynamic cg2BasicEmptyWeightMax;
@dynamic cg2BasicEmptyWeightMin;
@dynamic cg2EmptyFuelWeightMax;
@dynamic cg2EmptyFuelWeightMin;
@dynamic cg2GrossWeightMax;
@dynamic cg2GrossWeightMin;
@dynamic cg2TakeOffweightMax;
@dynamic cg2TakeOffweightMin;
@dynamic cgBasicEmptyWeightMax;
@dynamic cgBasicEmptyWeightMin;
@dynamic cgEmptyFuelWeightMax;
@dynamic cgEmptyFuelWeightMin;
@dynamic cgGrossWeightMax;
@dynamic cgGrossWeightMin;
@dynamic cgTakeOffweightMax;
@dynamic cgTakeOffWeightMin;
@dynamic emptyFuelArm;
@dynamic emptyFuelMoment;
@dynamic emptyFuelWeight;
@dynamic frontPax2Arm;
@dynamic frontPax2Moment;
@dynamic frontPax2Weight;
@dynamic frontPaxArm;
@dynamic frontPaxMoment;
@dynamic frontPaxWeight;
@dynamic mainTanksArm;
@dynamic mainTanksMoment;
@dynamic mainTanksWeight;
@dynamic mainTanksWeightGl;
@dynamic maxCargo1Weight;
@dynamic maxCargo2Weight;
@dynamic maxEmptyFuelWeight;
@dynamic maxGrossWeight;
@dynamic maxLandingWeight;
@dynamic maxTakeOffWeight;
@dynamic name;
@dynamic totalArm;
@dynamic totalMoment;
@dynamic totalWeight;

@end
