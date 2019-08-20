//
//  CalcGlide+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcGlide+CoreDataProperties.h"

@implementation CalcGlide (CoreDataProperties)

+ (NSFetchRequest<CalcGlide *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcGlide"];
}

@dynamic ratio;
@dynamic alt;
@dynamic ias;
@dynamic distNm;
@dynamic distSM;
@dynamic timeAloft;
@dynamic name;

@end
