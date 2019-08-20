//
//  TOLD+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/15/17.
//
//

#import "TOLD+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface TOLD (CoreDataProperties)

+ (NSFetchRequest<TOLD *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *atLanding;
@property (nullable, nonatomic, copy) NSNumber *atLandingVa;
@property (nullable, nonatomic, copy) NSNumber *atLandingVfe;
@property (nullable, nonatomic, copy) NSNumber *atLandingVg;
@property (nullable, nonatomic, copy) NSNumber *atLandingVle;
@property (nullable, nonatomic, copy) NSNumber *atLandingVlo;
@property (nullable, nonatomic, copy) NSNumber *atLandingVne;
@property (nullable, nonatomic, copy) NSNumber *atLandingVno;
@property (nullable, nonatomic, copy) NSNumber *atLandingVr;
@property (nullable, nonatomic, copy) NSNumber *atLandingVs1;
@property (nullable, nonatomic, copy) NSNumber *atLandingVso;
@property (nullable, nonatomic, copy) NSNumber *atLandingVx;
@property (nullable, nonatomic, copy) NSNumber *atLandingVy;
@property (nullable, nonatomic, copy) NSNumber *aTLB1;
@property (nullable, nonatomic, copy) NSNumber *atLB1Va;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vfe;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vg;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vle;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vlo;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vne;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vno;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vr;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vs1;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vso;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vx;
@property (nullable, nonatomic, copy) NSNumber *atLB1Vy;
@property (nullable, nonatomic, copy) NSNumber *atLB2;
@property (nullable, nonatomic, copy) NSNumber *atLB2Va;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vfe;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vg;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vle;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vlo;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vne;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vno;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vr;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vs1;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vso;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vx;
@property (nullable, nonatomic, copy) NSNumber *atLB2Vy;
@property (nullable, nonatomic, copy) NSNumber *atThisFlight;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVa;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVfe;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVg;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVle;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVlo;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVne;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVno;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVr;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVs1;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVso;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVx;
@property (nullable, nonatomic, copy) NSNumber *atThisFlightVy;
@property (nullable, nonatomic, copy) NSNumber *coloumHigherTakeOFF;
@property (nullable, nonatomic, copy) NSNumber *coloumLandingHigher;
@property (nullable, nonatomic, copy) NSNumber *coloumLandingLower;
@property (nullable, nonatomic, copy) NSNumber *coloumLowerTakeOFF;
@property (nullable, nonatomic, copy) NSNumber *departureUsableLength;
@property (nullable, nonatomic, copy) NSNumber *destinationUsableLength;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeight;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVa;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVfe;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVg;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVle;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVlo;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVne;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVno;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVr;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVs1;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVso;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVx;
@property (nullable, nonatomic, copy) NSNumber *emptyFuelWeightVy;
@property (nullable, nonatomic, copy) NSNumber *grossWeight;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVa;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVfe;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVg;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVle;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVlo;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVne;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVno;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVr;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVs1;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVso;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVx;
@property (nullable, nonatomic, copy) NSNumber *grossWeightVy;
@property (nullable, nonatomic, copy) NSNumber *landingRunwayReq;
@property (nullable, nonatomic, copy) NSNumber *landingTemp;
@property (nullable, nonatomic, copy) NSNumber *landingVrefReq;
@property (nullable, nonatomic, copy) NSNumber *lendingWeight;
@property (nullable, nonatomic, copy) NSNumber *lengthHigherTakeOFF;
@property (nullable, nonatomic, copy) NSNumber *lengthLandingHigher;
@property (nullable, nonatomic, copy) NSNumber *lengthLandingLower;
@property (nullable, nonatomic, copy) NSNumber *lengthLowerTakeOFF;
@property (nullable, nonatomic, copy) NSNumber *takeOffRunwayReq;
@property (nullable, nonatomic, copy) NSNumber *takeOffTemp;
@property (nullable, nonatomic, copy) NSNumber *takeOffVRReq;
@property (nullable, nonatomic, copy) NSNumber *takeOffWeight;
@property (nullable, nonatomic, copy) NSString *name;

@end

NS_ASSUME_NONNULL_END
