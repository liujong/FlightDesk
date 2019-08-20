//
//  GeneralFlightDesk+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 10/31/17.
//
//

#import "GeneralFlightDesk+CoreDataProperties.h"

@implementation GeneralFlightDesk (CoreDataProperties)

+ (NSFetchRequest<GeneralFlightDesk *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"GeneralFlightDesk"];
}

@dynamic copyrightAndTradeMarks;
@dynamic gettingStart;
@dynamic lastUpdate;
@dynamic privacy;
@dynamic termsOfUse;

@end
