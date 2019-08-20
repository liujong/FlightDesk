//
//  Endorsement+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/26/17.
//
//

#import "Endorsement+CoreDataProperties.h"

@implementation Endorsement (CoreDataProperties)

+ (NSFetchRequest<Endorsement *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Endorsement"];
}

@dynamic cfiNumber;
@dynamic cfiSignature;
@dynamic endorsementDate;
@dynamic endorsementExpDate;
@dynamic endorsementID;
@dynamic isSupersed;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic name;
@dynamic text;
@dynamic type;
@dynamic endorsement_local_id;
@dynamic endorsements;
- (void)insertObject:(LogEntry *)value inEndorsementsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet insertObject:value atIndex:idx];
    self.endorsements = tempSet;
}
- (void)removeObjectFromEndorsementsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObjectAtIndex:idx];
    self.endorsements = tempSet;
}
- (void)insertEndorsements:(NSArray<LogEntry *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet insertObjects:value atIndexes:indexes];
    self.endorsements = tempSet;
}
- (void)removeEndorsementsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObjectsAtIndexes:indexes];
    self.endorsements = tempSet;
}
- (void)replaceObjectInEndorsementsAtIndex:(NSUInteger)idx withObject:(LogEntry *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.endorsements = tempSet;
}
- (void)replaceEndorsementsAtIndexes:(NSIndexSet *)indexes withEndorsements:(NSArray<LogEntry *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.endorsements = tempSet;
}
- (void)addEndorsementsObject:(LogEntry *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet addObject:value];
    self.endorsements = tempSet;
}
- (void)removeEndorsementsObject:(LogEntry *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.endorsements];
    [tempSet removeObject:value];
    self.endorsements = tempSet;
}
- (void)addEndorsements:(NSOrderedSet<LogEntry *> *)values{
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
- (void)removeEndorsements:(NSOrderedSet<LogEntry *> *)values{
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
