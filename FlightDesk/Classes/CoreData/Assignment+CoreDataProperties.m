//
//  Assignment+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Assignment+CoreDataProperties.h"

@implementation Assignment (CoreDataProperties)

+ (NSFetchRequest<Assignment *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Assignment"];
}

@dynamic assignmentID;
@dynamic chapters;
@dynamic groundOrFlight;
@dynamic referenceID;
@dynamic studentUserID;
@dynamic title;
@dynamic assignment_local_id;
@dynamic lesson;

@end
