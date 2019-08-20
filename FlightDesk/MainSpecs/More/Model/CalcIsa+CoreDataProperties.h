//
//  CalcIsa+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcIsa+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcIsa (CoreDataProperties)

+ (NSFetchRequest<CalcIsa *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *altElev;
@property (nullable, nonatomic, copy) NSNumber *baro;
@property (nullable, nonatomic, copy) NSNumber *temp;
@property (nullable, nonatomic, copy) NSNumber *diffC;
@property (nullable, nonatomic, copy) NSNumber *diffFT;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
