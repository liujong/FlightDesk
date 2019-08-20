//
//  RecordsFile+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/28/17.
//
//

#import "RecordsFile+CoreDataProperties.h"

@implementation RecordsFile (CoreDataProperties)

+ (NSFetchRequest<RecordsFile *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RecordsFile"];
}

@dynamic file_name;
@dynamic file_url;
@dynamic fileSize;
@dynamic fileType;
@dynamic isUploaded;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic local_url;
@dynamic records_id;
@dynamic recordsLocal_id;
@dynamic student_id;
@dynamic thumb_url;
@dynamic user_id;

@end
