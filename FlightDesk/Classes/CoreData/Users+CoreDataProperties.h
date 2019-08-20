//
//  Users+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 10/16/17.
//
//

#import "Users+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Users (CoreDataProperties)

+ (NSFetchRequest<Users *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, copy) NSString *firstName;
@property (nullable, nonatomic, copy) NSString *middleName;
@property (nullable, nonatomic, copy) NSString *lastName;
@property (nullable, nonatomic, copy) NSString *level;
@property (nullable, nonatomic, copy) NSNumber *lastSync;

@end

NS_ASSUME_NONNULL_END
