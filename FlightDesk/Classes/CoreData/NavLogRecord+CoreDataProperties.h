//
//  NavLogRecord+CoreDataProperties.h
//  FlightDesk
//
//  Created by Liu Jie on 4/25/18.
//  Copyright © 2018 spider. All rights reserved.
//
//

#import "NavLogRecord+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NavLogRecord (CoreDataProperties)

+ (NSFetchRequest<NavLogRecord *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *attitude;
@property (nullable, nonatomic, copy) NSNumber *casTas;
@property (nullable, nonatomic, copy) NSString *ch;
@property (nullable, nonatomic, copy) NSString *checkPoint;
@property (nullable, nonatomic, copy) NSString *course;
@property (nullable, nonatomic, copy) NSString *dev;
@property (nullable, nonatomic, copy) NSNumber *distLeg;
@property (nullable, nonatomic, copy) NSNumber *distRem;
@property (nullable, nonatomic, copy) NSString *fuelATA;
@property (nullable, nonatomic, copy) NSString *fuelETA;
@property (nullable, nonatomic, copy) NSString *gphFuel;
@property (nullable, nonatomic, copy) NSString *gphRem;
@property (nullable, nonatomic, copy) NSString *gsAct;
@property (nullable, nonatomic, copy) NSString *gsEst;
@property (nullable, nonatomic, copy) NSString *lrWca;
@property (nullable, nonatomic, copy) NSString *lwVar;
@property (nullable, nonatomic, copy) NSString *mh;
@property (nullable, nonatomic, copy) NSNumber *navLogID;
@property (nullable, nonatomic, copy) NSNumber *navLogRecordID;
@property (nullable, nonatomic, copy) NSNumber *ordering;
@property (nullable, nonatomic, copy) NSString *tc;
@property (nullable, nonatomic, copy) NSString *th;
@property (nullable, nonatomic, copy) NSString *timeOffATE;
@property (nullable, nonatomic, copy) NSString *timeOffETE;
@property (nullable, nonatomic, copy) NSString *vorFreq;
@property (nullable, nonatomic, copy) NSString *vorFrom;
@property (nullable, nonatomic, copy) NSString *vorIdent;
@property (nullable, nonatomic, copy) NSString *vorTo;
@property (nullable, nonatomic, copy) NSNumber *windDir;
@property (nullable, nonatomic, copy) NSNumber *windTemp;
@property (nullable, nonatomic, copy) NSNumber *windVel;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, retain) NavLog *navLogGroups;

@end

NS_ASSUME_NONNULL_END
