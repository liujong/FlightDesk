//
//  GeneralFlightDesk+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 10/31/17.
//
//

#import "GeneralFlightDesk+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface GeneralFlightDesk (CoreDataProperties)

+ (NSFetchRequest<GeneralFlightDesk *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *copyrightAndTradeMarks;
@property (nullable, nonatomic, copy) NSString *gettingStart;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *privacy;
@property (nullable, nonatomic, copy) NSString *termsOfUse;

@end

NS_ASSUME_NONNULL_END
