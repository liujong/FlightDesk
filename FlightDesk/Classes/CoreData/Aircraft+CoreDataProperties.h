//
//  Aircraft+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/28/17.
//
//

#import "Aircraft+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Aircraft (CoreDataProperties)

+ (NSFetchRequest<Aircraft *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *aircraftID;
@property (nullable, nonatomic, copy) NSString *aircraftItems;
@property (nullable, nonatomic, copy) NSString *avionicsItems;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *liftLimitedParts;
@property (nullable, nonatomic, copy) NSString *maintenanceItems;
@property (nullable, nonatomic, copy) NSString *otherItems;
@property (nullable, nonatomic, copy) NSString *squawksItems;
@property (nullable, nonatomic, copy) NSNumber *valueForSort;
@property (nullable, nonatomic, copy) NSNumber *aircraft_local_id;

@end

NS_ASSUME_NONNULL_END
