//
//  CalcLeg+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcLeg+CoreDataProperties.h"

@implementation CalcLeg (CoreDataProperties)

+ (NSFetchRequest<CalcLeg *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcLeg"];
}

@dynamic leg1GS;
@dynamic leg1Dist;
@dynamic leg2Dist;
@dynamic leg2GS;
@dynamic leg3Dist;
@dynamic leg3GS;
@dynamic leg4Dist;
@dynamic leg4GS;
@dynamic fuelLoad;
@dynamic galHr;
@dynamic totalDist;
@dynamic name;
@dynamic leg1Time;
@dynamic leg1DistRem;
@dynamic leg1GalUsed;
@dynamic leg1GalRem;
@dynamic leg2Time;
@dynamic leg2DistRem;
@dynamic leg2GalUsed;
@dynamic leg2GalRem;
@dynamic leg3Time;
@dynamic leg3DistRem;
@dynamic leg3GalUsed;
@dynamic leg3GalRem;
@dynamic leg4Time;
@dynamic leg4DistRem;
@dynamic leg4GalUsed;
@dynamic leg4GalRem;

@end
