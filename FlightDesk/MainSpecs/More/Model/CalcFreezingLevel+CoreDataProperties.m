//
//  CalcFreezingLevel+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcFreezingLevel+CoreDataProperties.h"

@implementation CalcFreezingLevel (CoreDataProperties)

+ (NSFetchRequest<CalcFreezingLevel *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcFreezingLevel"];
}

@dynamic temp;
@dynamic ft;
@dynamic name;

@end
