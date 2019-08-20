//
//  ContentRecord+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "ContentRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ContentRecord (CoreDataProperties)

+ (NSFetchRequest<ContentRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *completed;
@property (nullable, nonatomic, copy) NSNumber *contentRecordID;
@property (nullable, nonatomic, copy) NSString *remarks;
@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, retain) Content *content;

@end

NS_ASSUME_NONNULL_END
