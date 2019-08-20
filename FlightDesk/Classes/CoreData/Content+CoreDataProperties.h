//
//  Content+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Content+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Content (CoreDataProperties)

+ (NSFetchRequest<Content *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *contentID;
@property (nullable, nonatomic, copy) NSNumber *groundOrFlight;
@property (nullable, nonatomic, copy) NSNumber *hasCheck;
@property (nullable, nonatomic, copy) NSNumber *hasRemarks;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *orderNumber;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSNumber *depth;
@property (nullable, nonatomic, copy) NSNumber *content_local_id;
@property (nullable, nonatomic, retain) Lesson *lesson;
@property (nullable, nonatomic, retain) ContentRecord *record;

@end

NS_ASSUME_NONNULL_END
