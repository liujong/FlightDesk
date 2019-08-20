//
//  InsAndStdAndProgamQuery+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 7/18/17.
//
//

#import "InsAndStdAndProgamQuery+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface InsAndStdAndProgamQuery (CoreDataProperties)

+ (NSFetchRequest<InsAndStdAndProgamQuery *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *queryType;
@property (nullable, nonatomic, copy) NSNumber *instructorID;
@property (nullable, nonatomic, copy) NSNumber *studentID;
@property (nullable, nonatomic, copy) NSNumber *programID;

@end

NS_ASSUME_NONNULL_END
