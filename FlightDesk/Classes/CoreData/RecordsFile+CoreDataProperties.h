//
//  RecordsFile+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/28/17.
//
//

#import "RecordsFile+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface RecordsFile (CoreDataProperties)

+ (NSFetchRequest<RecordsFile *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *file_name;
@property (nullable, nonatomic, copy) NSString *file_url;
@property (nullable, nonatomic, copy) NSString *fileSize;
@property (nullable, nonatomic, copy) NSString *fileType;
@property (nullable, nonatomic, copy) NSNumber *isUploaded;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *local_url;
@property (nullable, nonatomic, copy) NSNumber *records_id;
@property (nullable, nonatomic, copy) NSNumber *recordsLocal_id;
@property (nullable, nonatomic, copy) NSNumber *student_id;
@property (nullable, nonatomic, copy) NSString *thumb_url;
@property (nullable, nonatomic, copy) NSNumber *user_id;

@end

NS_ASSUME_NONNULL_END
