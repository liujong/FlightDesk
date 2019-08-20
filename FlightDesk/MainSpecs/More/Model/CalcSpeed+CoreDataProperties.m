//
//  CalcSpeed+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcSpeed+CoreDataProperties.h"

@implementation CalcSpeed (CoreDataProperties)

+ (NSFetchRequest<CalcSpeed *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcSpeed"];
}

@dynamic as;
@dynamic alt;
@dynamic tas;
@dynamic name;

@end
