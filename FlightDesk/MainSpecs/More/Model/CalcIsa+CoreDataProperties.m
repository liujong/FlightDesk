//
//  CalcIsa+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcIsa+CoreDataProperties.h"

@implementation CalcIsa (CoreDataProperties)

+ (NSFetchRequest<CalcIsa *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcIsa"];
}

@dynamic altElev;
@dynamic baro;
@dynamic temp;
@dynamic diffC;
@dynamic diffFT;
@dynamic name;

@end
