//
//  ChatBoard+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 10/9/17.
//
//

#import "ChatBoard+CoreDataProperties.h"

@implementation ChatBoard (CoreDataProperties)

+ (NSFetchRequest<ChatBoard *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChatBoard"];
}

@dynamic boardID;
@dynamic targetUserID;
@dynamic userID;

@end
