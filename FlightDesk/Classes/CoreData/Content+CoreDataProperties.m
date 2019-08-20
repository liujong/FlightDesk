//
//  Content+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Content+CoreDataProperties.h"

@implementation Content (CoreDataProperties)

+ (NSFetchRequest<Content *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Content"];
}

@dynamic contentID;
@dynamic groundOrFlight;
@dynamic hasCheck;
@dynamic hasRemarks;
@dynamic name;
@dynamic orderNumber;
@dynamic studentUserID;
@dynamic depth;
@dynamic content_local_id;
@dynamic lesson;
@dynamic record;

@end
