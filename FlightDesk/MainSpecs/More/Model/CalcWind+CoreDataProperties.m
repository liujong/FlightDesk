//
//  CalcWind+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcWind+CoreDataProperties.h"

@implementation CalcWind (CoreDataProperties)

+ (NSFetchRequest<CalcWind *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcWind"];
}

@dynamic windDirection;
@dynamic windSpeed;
@dynamic trueAirSpeed;
@dynamic course;
@dynamic name;

@end
