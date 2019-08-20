//
//  CalcConversions+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcConversions+CoreDataProperties.h"

@implementation CalcConversions (CoreDataProperties)

+ (NSFetchRequest<CalcConversions *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcConversions"];
}

@dynamic admosBaro;
@dynamic admosMillibars;
@dynamic admosPsi;
@dynamic attribute;
@dynamic diatanceNautical;
@dynamic distanceFeet;
@dynamic distanceKilometer;
@dynamic distanceMiles;
@dynamic fluidGallons;
@dynamic fluidLiters;
@dynamic fluidOunces;
@dynamic fluidPints;
@dynamic fluidQuarts;
@dynamic fuelAvGas;
@dynamic fuelJetA;
@dynamic fuelOil;
@dynamic fuelPounds;
@dynamic fuelTks;
@dynamic fuelWater;
@dynamic speedKph;
@dynamic speedKts;
@dynamic speedMph;
@dynamic tempCelcius;
@dynamic tempfarnate;
@dynamic tempKelbin;
@dynamic timeDecimal;
@dynamic timeEnd;
@dynamic timeStart;
@dynamic timeTotal;
@dynamic timeZoneLocal;
@dynamic timeZoneLosAngeles;
@dynamic timeZoneZULU;
@dynamic weightKilos;
@dynamic weightPound;
@dynamic weightTons;
@dynamic name;

@end
