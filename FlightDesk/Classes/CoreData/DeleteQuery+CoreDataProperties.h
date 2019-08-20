//
//  DeleteQuery+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 6/14/17.
//
//

#import "DeleteQuery+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DeleteQuery (CoreDataProperties)

+ (NSFetchRequest<DeleteQuery *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, copy) NSNumber *idToDelete;

@end

NS_ASSUME_NONNULL_END
