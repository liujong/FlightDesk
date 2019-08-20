//
//  Aircraft+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/28/17.
//
//

#import "Aircraft+CoreDataProperties.h"

@implementation Aircraft (CoreDataProperties)

+ (NSFetchRequest<Aircraft *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Aircraft"];
}

@dynamic aircraftID;
@dynamic aircraftItems;
@dynamic avionicsItems;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic liftLimitedParts;
@dynamic maintenanceItems;
@dynamic otherItems;
@dynamic squawksItems;
@dynamic valueForSort;
@dynamic aircraft_local_id;

@end
