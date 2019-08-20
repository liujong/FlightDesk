//
//  MaintenanceLogs+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/28/17.
//
//

#import "MaintenanceLogs+CoreDataProperties.h"

@implementation MaintenanceLogs (CoreDataProperties)

+ (NSFetchRequest<MaintenanceLogs *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MaintenanceLogs"];
}

@dynamic file_name;
@dynamic file_url;
@dynamic fileSize;
@dynamic fileType;
@dynamic isUploaded;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic local_url;
@dynamic maintenancelog_id;
@dynamic recordsLocal_id;
@dynamic aircraft_local_id;
@dynamic thumb_url;
@dynamic user_id;

@end
