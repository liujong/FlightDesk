//
//  ContentRecord+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "ContentRecord+CoreDataProperties.h"

@implementation ContentRecord (CoreDataProperties)

+ (NSFetchRequest<ContentRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ContentRecord"];
}

@dynamic completed;
@dynamic contentRecordID;
@dynamic remarks;
@dynamic userID;
@dynamic content;

@end
