//
//  NavLogRecord+CoreDataProperties.m
//  FlightDesk
//
//  Created by Liu Jie on 4/25/18.
//  Copyright © 2018 spider. All rights reserved.
//
//

#import "NavLogRecord+CoreDataProperties.h"

@implementation NavLogRecord (CoreDataProperties)

+ (NSFetchRequest<NavLogRecord *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"NavLogRecord"];
}

@dynamic attitude;
@dynamic casTas;
@dynamic ch;
@dynamic checkPoint;
@dynamic course;
@dynamic dev;
@dynamic distLeg;
@dynamic distRem;
@dynamic fuelATA;
@dynamic fuelETA;
@dynamic gphFuel;
@dynamic gphRem;
@dynamic gsAct;
@dynamic gsEst;
@dynamic lrWca;
@dynamic lwVar;
@dynamic mh;
@dynamic navLogID;
@dynamic navLogRecordID;
@dynamic ordering;
@dynamic tc;
@dynamic th;
@dynamic timeOffATE;
@dynamic timeOffETE;
@dynamic vorFreq;
@dynamic vorFrom;
@dynamic vorIdent;
@dynamic vorTo;
@dynamic windDir;
@dynamic windTemp;
@dynamic windVel;
@dynamic lastSync;
@dynamic navLogGroups;

@end
