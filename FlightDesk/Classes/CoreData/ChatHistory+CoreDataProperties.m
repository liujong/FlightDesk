//
//  ChatHistory+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 10/9/17.
//
//

#import "ChatHistory+CoreDataProperties.h"

@implementation ChatHistory (CoreDataProperties)

+ (NSFetchRequest<ChatHistory *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ChatHistory"];
}

@dynamic boardID;
@dynamic fileUrl;
@dynamic history_id;
@dynamic isRead;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic message;
@dynamic messageID;
@dynamic ordering;
@dynamic searchKey;
@dynamic sentTime;
@dynamic target_userID;
@dynamic targetName;
@dynamic thumbImageSize;
@dynamic thumbUrl;
@dynamic type;
@dynamic userID;

@end
