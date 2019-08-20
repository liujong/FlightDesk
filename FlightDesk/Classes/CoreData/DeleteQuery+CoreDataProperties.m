//
//  DeleteQuery+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 6/14/17.
//
//

#import "DeleteQuery+CoreDataProperties.h"

@implementation DeleteQuery (CoreDataProperties)

+ (NSFetchRequest<DeleteQuery *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"DeleteQuery"];
}

@dynamic type;
@dynamic idToDelete;

@end
