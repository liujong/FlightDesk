//
//  EndorsementRecord+CoreDataProperties.h
//  FlightDesk
//
//  Created by Gregory Bayard on 11/20/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EndorsementRecord.h"

NS_ASSUME_NONNULL_BEGIN

@interface EndorsementRecord (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *userID;
@property (nullable, nonatomic, retain) NSNumber *instructorID;
@property (nullable, nonatomic, retain) NSNumber *lastSync;
@property (nullable, nonatomic, retain) NSNumber *lastUpdate;
@property (nullable, nonatomic, retain) NSNumber *recordID;
@property (nullable, nonatomic, retain) NSNumber *endorsementID;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) LogEntry *endorsementLog;
@property (nullable, nonatomic, retain) Endorsement *endorsement;

@end

NS_ASSUME_NONNULL_END
