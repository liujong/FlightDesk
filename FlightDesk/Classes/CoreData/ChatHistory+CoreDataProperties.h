//
//  ChatHistory+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 10/9/17.
//
//

#import "ChatHistory+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ChatHistory (CoreDataProperties)

+ (NSFetchRequest<ChatHistory *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *boardID;
@property (nullable, nonatomic, copy) NSString *fileUrl;
@property (nullable, nonatomic, copy) NSNumber *history_id;
@property (nullable, nonatomic, copy) NSNumber *isRead;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *message;
@property (nullable, nonatomic, copy) NSNumber *messageID;
@property (nullable, nonatomic, copy) NSNumber *ordering;
@property (nullable, nonatomic, copy) NSString *searchKey;
@property (nullable, nonatomic, copy) NSString *sentTime;
@property (nullable, nonatomic, copy) NSNumber *target_userID;
@property (nullable, nonatomic, copy) NSString *targetName;
@property (nullable, nonatomic, copy) NSString *thumbImageSize;
@property (nullable, nonatomic, copy) NSString *thumbUrl;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *userID;

@end

NS_ASSUME_NONNULL_END
