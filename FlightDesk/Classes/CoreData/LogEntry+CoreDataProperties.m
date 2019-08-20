//
//  LogEntry+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/26/17.
//
//

#import "LogEntry+CoreDataProperties.h"

@implementation LogEntry (CoreDataProperties)

+ (NSFetchRequest<LogEntry *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LogEntry"];
}

@dynamic aircraftCategory;
@dynamic aircraftClass;
@dynamic aircraftModel;
@dynamic aircraftRegistration;
@dynamic approachesCount;
@dynamic approachesType;
@dynamic complex;
@dynamic creationDateTime;
@dynamic dualGiven;
@dynamic dualGivenCFI;
@dynamic dualGivenCommercial;
@dynamic dualGivenGlider;
@dynamic dualGivenInstrument;
@dynamic dualGivenOther;
@dynamic dualGivenRecreational;
@dynamic dualGivenSport;
@dynamic dualReceived;
@dynamic entryID;
@dynamic flightRoute;
@dynamic glider;
@dynamic groundTime;
@dynamic helicopter;
@dynamic highPerf;
@dynamic hobbsIn;
@dynamic hobbsOut;
@dynamic holds;
@dynamic instructorCertNo;
@dynamic instructorID;
@dynamic instructorSignature;
@dynamic instrumentActual;
@dynamic instrumentHood;
@dynamic instrumentSim;
@dynamic jet;
@dynamic landingsDay;
@dynamic landingsNight;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic lessonId;
@dynamic logDate;
@dynamic nightDualReceived;
@dynamic nightTime;
@dynamic picTime;
@dynamic recreational;
@dynamic remarks;
@dynamic sicTime;
@dynamic soloTime;
@dynamic sport;
@dynamic studentUserID;
@dynamic taildragger;
@dynamic totalFlightTime;
@dynamic tracking;
@dynamic turboprop;
@dynamic ultraLight;
@dynamic userID;
@dynamic valueForSort;
@dynamic xc;
@dynamic xcDualGiven;
@dynamic xcDualReceived;
@dynamic xcNightDualReceived;
@dynamic xcNightTime;
@dynamic xcPIC;
@dynamic xcSolo;
@dynamic log_local_id;
@dynamic endorsements;
@dynamic logLessonRecord;
- (void)insertObject:(Endorsement *)value inEndorsementsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet insertObject:value atIndex:idx];
    self.endorsements = tempSet;
}
- (void)removeObjectFromEndorsementsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObjectAtIndex:idx];
    self.endorsements = tempSet;
}
- (void)insertEndorsements:(NSArray<Endorsement *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet insertObjects:value atIndexes:indexes];
    self.endorsements = tempSet;
}
- (void)removeEndorsementsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObjectsAtIndexes:indexes];
    self.endorsements = tempSet;
}
- (void)replaceObjectInEndorsementsAtIndex:(NSUInteger)idx withObject:(Endorsement *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.endorsements = tempSet;
}
- (void)replaceEndorsementsAtIndexes:(NSIndexSet *)indexes withEndorsements:(NSArray<Endorsement *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.endorsements = tempSet;
}
- (void)addEndorsementsObject:(Endorsement *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet addObject:value];
    self.endorsements = tempSet;
}
- (void)removeEndorsementsObject:(Endorsement *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObject:value];
    self.endorsements = tempSet;
}
- (void)addEndorsements:(NSOrderedSet<Endorsement *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.endorsements = tmpOrderedSet;
    }
}
- (void)removeEndorsements:(NSOrderedSet<Endorsement *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.endorsements = tmpOrderedSet;
    }
}
@end
