//
//  NavLog+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/5/17.
//
//

#import "NavLog+CoreDataProperties.h"

@implementation NavLog (CoreDataProperties)

+ (NSFetchRequest<NavLog *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"NavLog"];
}

@dynamic navLogID;
@dynamic navLogLocalID;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic userID;
@dynamic navLogName;
@dynamic aircraftNum;
@dynamic navLogDate;
@dynamic notes;
@dynamic casTasVal;
@dynamic distLeg;
@dynamic timeOff;
@dynamic fuel;
@dynamic gph;
@dynamic navLogRecords;

- (void)insertObject:(NavLogRecord *)value inNavLogRecordsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet insertObject:value atIndex:idx];
    self.navLogRecords = tempSet;
}
- (void)removeObjectFromNavLogRecordsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet removeObjectAtIndex:idx];
    self.navLogRecords = tempSet;
}
- (void)insertNavLogRecords:(NSArray<NavLogRecord *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet insertObjects:value atIndexes:indexes];
    self.navLogRecords = tempSet;
}
- (void)removeNavLogRecordsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet removeObjectsAtIndexes:indexes];
    self.navLogRecords = tempSet;
}
- (void)replaceObjectInNavLogRecordsAtIndex:(NSUInteger)idx withObject:(NavLogRecord *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.navLogRecords = tempSet;
}
- (void)replaceNavLogRecordsAtIndexes:(NSIndexSet *)indexes withNavLogRecords:(NSArray<NavLogRecord *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.navLogRecords = tempSet;
}
- (void)addNavLogRecordsObject:(NavLogRecord *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet addObject:value];
    self.navLogRecords = tempSet;
}
- (void)removeNavLogRecordsObject:(NavLogRecord *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    [tempSet removeObject:value];
    self.navLogRecords = tempSet;
}
- (void)addNavLogRecords:(NSOrderedSet<NavLogRecord *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.navLogRecords = tmpOrderedSet;
    }
}
- (void)removeNavLogRecords:(NSOrderedSet<NavLogRecord *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.navLogRecords];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.navLogRecords = tmpOrderedSet;
    }
}

@end
