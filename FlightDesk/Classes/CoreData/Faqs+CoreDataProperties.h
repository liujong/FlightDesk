//
//  Faqs+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 10/31/17.
//
//

#import "Faqs+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Faqs (CoreDataProperties)

+ (NSFetchRequest<Faqs *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *answer;
@property (nullable, nonatomic, copy) NSString *category;
@property (nullable, nonatomic, copy) NSNumber *faqs_id;
@property (nullable, nonatomic, copy) NSNumber *faqs_local_id;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *question;

@end

NS_ASSUME_NONNULL_END
