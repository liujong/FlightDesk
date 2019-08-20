//
//  SyncManagerResourcesCalendar.h
//  FlightDesk
//
//  Created by jellaliu on 11/10/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Logging.h"


@interface SyncManagerResourcesCalendar : NSObject
// access to the main (GUI) thread's managed object context
@property (strong, nonatomic) NSManagedObjectContext *mainManagedObjectContext;

- (id)initWithContext:(NSManagedObjectContext *)mainMOC;
- (void)performSyncCheck;
- (void)cancelSycnTimer;

@end
