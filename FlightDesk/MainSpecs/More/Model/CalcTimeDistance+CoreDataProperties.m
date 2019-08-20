//
//  CalcTimeDistance+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcTimeDistance+CoreDataProperties.h"

@implementation CalcTimeDistance (CoreDataProperties)

+ (NSFetchRequest<CalcTimeDistance *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcTimeDistance"];
}

@dynamic timeDistanceTime;
@dynamic timeDistanceKts;
@dynamic timeDistanceNM;
@dynamic timeDistanceSM;
@dynamic etaKTS;
@dynamic etaNM;
@dynamic etaSM;
@dynamic etaTime;
@dynamic name;

@end
