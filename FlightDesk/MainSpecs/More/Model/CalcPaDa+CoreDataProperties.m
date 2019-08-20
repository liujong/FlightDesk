//
//  CalcPaDa+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcPaDa+CoreDataProperties.h"

@implementation CalcPaDa (CoreDataProperties)

+ (NSFetchRequest<CalcPaDa *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcPaDa"];
}

@dynamic paAltElev;
@dynamic paRaro;
@dynamic paMilibars;
@dynamic pa;
@dynamic daAltElev;
@dynamic daTemp;
@dynamic daBaro;
@dynamic daDew;
@dynamic da;
@dynamic name;

@end
