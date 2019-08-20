//
//  CalcFuel+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcFuel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcFuel (CoreDataProperties)

+ (NSFetchRequest<CalcFuel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *burnTimeDec;
@property (nullable, nonatomic, copy) NSString *burnTime;
@property (nullable, nonatomic, copy) NSNumber *burnFBhr;
@property (nullable, nonatomic, copy) NSNumber *burnFURequired;
@property (nullable, nonatomic, copy) NSNumber *nmGal;
@property (nullable, nonatomic, copy) NSNumber *nmGalTimeDec;
@property (nullable, nonatomic, copy) NSNumber *nmGalFBhr;
@property (nullable, nonatomic, copy) NSNumber *nmGalNg;
@property (nullable, nonatomic, copy) NSNumber *bnGalGN;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
