//
//  ChecklistsContent+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/18/17.
//
//

#import "ChecklistsContent+CoreDataProperties.h"

@implementation ChecklistsContent (CoreDataProperties)

+ (NSFetchRequest<ChecklistsContent *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChecklistsContent"];
}

@dynamic checklistContentID;
@dynamic checklistID;
@dynamic content;
@dynamic contentTail;
@dynamic isChecked;
@dynamic ordering;
@dynamic type;
@dynamic checkContents;

@end
