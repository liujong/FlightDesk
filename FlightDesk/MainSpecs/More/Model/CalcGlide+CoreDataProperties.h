//
//  CalcGlide+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcGlide+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcGlide (CoreDataProperties)

+ (NSFetchRequest<CalcGlide *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *ratio;
@property (nullable, nonatomic, copy) NSNumber *alt;
@property (nullable, nonatomic, copy) NSNumber *ias;
@property (nullable, nonatomic, copy) NSNumber *distNm;
@property (nullable, nonatomic, copy) NSNumber *distSM;
@property (nullable, nonatomic, copy) NSString *timeAloft;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
