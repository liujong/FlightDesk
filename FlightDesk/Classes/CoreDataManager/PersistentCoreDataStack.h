//
//  PersistentCoreDataStack.h
//  FlightDesk
//
//  Created by Gregory Bayard on 3/29/15.
//  Copyright (c) 2015 NOVA.GregoryBayard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PersistentCoreDataStack : NSObject

- (id)initWithStoreURL:(NSURL*)storeURL modelURL:(NSURL*)modelURL;

@property (nonatomic,readonly) NSManagedObjectContext* managedObjectContext;

@end
