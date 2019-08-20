//
//  ResourcesCalendar+CoreDataProperties.m
//  
//
//  Created by Liu Jie on 12/8/17.
//
//

#import "ResourcesCalendar+CoreDataProperties.h"

@implementation ResourcesCalendar (CoreDataProperties)

+ (NSFetchRequest<ResourcesCalendar *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ResourcesCalendar"];
}

@dynamic aircrafts;
@dynamic alertTimeInterVal;
@dynamic calendar_identify;
@dynamic calendar_name;
@dynamic classrooms;
@dynamic endDate;
@dynamic event_id;
@dynamic event_identify;
@dynamic event_local_id;
@dynamic group_id;
@dynamic invitedUser_id;
@dynamic isEditable;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic startDate;
@dynamic timeIntervalEndDate;
@dynamic timeIntervalStartDate;
@dynamic title;
@dynamic user_id;
@dynamic aircraft;
@dynamic classroom;

@end
