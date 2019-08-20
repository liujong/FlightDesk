//
//  EndorsementRecord.h
//  FlightDesk
//
//  Created by Gregory Bayard on 11/20/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LogEntry, Endorsement;

NS_ASSUME_NONNULL_BEGIN

@interface EndorsementRecord : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "EndorsementRecord+CoreDataProperties.h"
