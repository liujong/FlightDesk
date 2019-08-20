//
//  CalcPaDa+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcPaDa+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcPaDa (CoreDataProperties)

+ (NSFetchRequest<CalcPaDa *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *paAltElev;
@property (nullable, nonatomic, copy) NSNumber *paRaro;
@property (nullable, nonatomic, copy) NSNumber *paMilibars;
@property (nullable, nonatomic, copy) NSNumber *pa;
@property (nullable, nonatomic, copy) NSNumber *daAltElev;
@property (nullable, nonatomic, copy) NSNumber *daTemp;
@property (nullable, nonatomic, copy) NSNumber *daBaro;
@property (nullable, nonatomic, copy) NSNumber *daDew;
@property (nullable, nonatomic, copy) NSNumber *da;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
