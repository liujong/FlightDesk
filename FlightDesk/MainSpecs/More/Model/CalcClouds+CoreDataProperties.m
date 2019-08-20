//
//  CalcClouds+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcClouds+CoreDataProperties.h"

@implementation CalcClouds (CoreDataProperties)

+ (NSFetchRequest<CalcClouds *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcClouds"];
}

@dynamic cloudTemp;
@dynamic dew;
@dynamic bases;
@dynamic name;

@end
