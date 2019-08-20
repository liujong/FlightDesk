//
//  ManagedObjectCloner.h
//  FlightDesk
//
//  Created by Liu Jie on 1/24/18.
//  Copyright © 2018 spider. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ManagedObjectCloner : NSObject

+(NSManagedObject *)clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context;
@end
