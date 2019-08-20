//
//  ChatBoard+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 10/9/17.
//
//

#import "ChatBoard+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ChatBoard (CoreDataProperties)

+ (NSFetchRequest<ChatBoard *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *boardID;
@property (nullable, nonatomic, copy) NSNumber *targetUserID;
@property (nullable, nonatomic, copy) NSNumber *userID;

@end

NS_ASSUME_NONNULL_END
