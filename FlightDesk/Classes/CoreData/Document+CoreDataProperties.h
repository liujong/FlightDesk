//
//  Document+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 7/21/17.
//
//

#import "Document+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Document (CoreDataProperties)

+ (NSFetchRequest<Document *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *documentID;
@property (nullable, nonatomic, copy) NSNumber *downloaded;
@property (nullable, nonatomic, copy) NSNumber *groupID;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *pdfURL;
@property (nullable, nonatomic, copy) NSString *remoteURL;
@property (nullable, nonatomic, copy) NSNumber *studentID;
@property (nullable, nonatomic, copy) NSNumber *type;

@end

NS_ASSUME_NONNULL_END
