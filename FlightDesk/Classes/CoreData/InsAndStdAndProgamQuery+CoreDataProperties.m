//
//  InsAndStdAndProgamQuery+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 7/18/17.
//
//

#import "InsAndStdAndProgamQuery+CoreDataProperties.h"

@implementation InsAndStdAndProgamQuery (CoreDataProperties)

+ (NSFetchRequest<InsAndStdAndProgamQuery *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"InsAndStdAndProgamQuery"];
}

@dynamic queryType;
@dynamic instructorID;
@dynamic studentID;
@dynamic programID;

@end
