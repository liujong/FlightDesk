//
//  Users+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 10/16/17.
//
//

#import "Users+CoreDataProperties.h"

@implementation Users (CoreDataProperties)

+ (NSFetchRequest<Users *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Users"];
}

@dynamic userID;
@dynamic firstName;
@dynamic middleName;
@dynamic lastName;
@dynamic level;
@dynamic lastSync;

@end
