//
//  CalcFuel+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "CalcFuel+CoreDataProperties.h"

@implementation CalcFuel (CoreDataProperties)

+ (NSFetchRequest<CalcFuel *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CalcFuel"];
}

@dynamic burnTimeDec;
@dynamic burnTime;
@dynamic burnFBhr;
@dynamic burnFURequired;
@dynamic nmGal;
@dynamic nmGalTimeDec;
@dynamic nmGalFBhr;
@dynamic nmGalNg;
@dynamic bnGalGN;
@dynamic name;

@end
