//
//  CalcConversions+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcConversions+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CalcConversions (CoreDataProperties)

+ (NSFetchRequest<CalcConversions *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *admosBaro;
@property (nullable, nonatomic, copy) NSNumber *admosMillibars;
@property (nullable, nonatomic, copy) NSNumber *admosPsi;
@property (nullable, nonatomic, copy) NSNumber *attribute;
@property (nullable, nonatomic, copy) NSNumber *diatanceNautical;
@property (nullable, nonatomic, copy) NSNumber *distanceFeet;
@property (nullable, nonatomic, copy) NSNumber *distanceKilometer;
@property (nullable, nonatomic, copy) NSNumber *distanceMiles;
@property (nullable, nonatomic, copy) NSNumber *fluidGallons;
@property (nullable, nonatomic, copy) NSNumber *fluidLiters;
@property (nullable, nonatomic, copy) NSNumber *fluidOunces;
@property (nullable, nonatomic, copy) NSNumber *fluidPints;
@property (nullable, nonatomic, copy) NSNumber *fluidQuarts;
@property (nullable, nonatomic, copy) NSNumber *fuelAvGas;
@property (nullable, nonatomic, copy) NSNumber *fuelJetA;
@property (nullable, nonatomic, copy) NSNumber *fuelOil;
@property (nullable, nonatomic, copy) NSNumber *fuelPounds;
@property (nullable, nonatomic, copy) NSNumber *fuelTks;
@property (nullable, nonatomic, copy) NSNumber *fuelWater;
@property (nullable, nonatomic, copy) NSNumber *speedKph;
@property (nullable, nonatomic, copy) NSNumber *speedKts;
@property (nullable, nonatomic, copy) NSNumber *speedMph;
@property (nullable, nonatomic, copy) NSNumber *tempCelcius;
@property (nullable, nonatomic, copy) NSNumber *tempfarnate;
@property (nullable, nonatomic, copy) NSNumber *tempKelbin;
@property (nullable, nonatomic, copy) NSNumber *timeDecimal;
@property (nullable, nonatomic, copy) NSString *timeEnd;
@property (nullable, nonatomic, copy) NSString *timeStart;
@property (nullable, nonatomic, copy) NSString *timeTotal;
@property (nullable, nonatomic, copy) NSString *timeZoneLocal;
@property (nullable, nonatomic, copy) NSString *timeZoneLosAngeles;
@property (nullable, nonatomic, copy) NSString *timeZoneZULU;
@property (nullable, nonatomic, copy) NSNumber *weightKilos;
@property (nullable, nonatomic, copy) NSNumber *weightPound;
@property (nullable, nonatomic, copy) NSNumber *weightTons;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
