//
//  PersistentCoreDataStack.m
//  FlightDesk
//
//  Created by Gregory Bayard on 3/29/15.
//  Copyright (c) 2015 NOVA.GregoryBayard. All rights reserved.
//

#import "PersistentCoreDataStack.h"
#import "Logging.h"

@interface PersistentCoreDataStack ()

@property (nonatomic,readwrite) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSURL* modelURL;
@property (nonatomic) NSURL* storeURL;

@end

@implementation PersistentCoreDataStack

- (id)initWithStoreURL:(NSURL*)storeURL modelURL:(NSURL*)modelURL
{
    self = [super init];
    if (self) {
        self.storeURL = storeURL;
        self.modelURL = modelURL;
        [self setupManagedObjectContext];
    }
    return self;
}

- (void)setupManagedObjectContext
{
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.managedObjectContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSError* error;
    [self.managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                  configuration:nil
                                                                            URL:self.storeURL
                                                                        options:nil
                                                                          error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
        NSLog(@"rm \"%@\"", self.storeURL.path);
    }
    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
}

- (NSManagedObjectModel*)managedObjectModel
{
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
}

@end
