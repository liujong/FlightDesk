//
//  Lesson+CoreDataProperties.m
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Lesson+CoreDataProperties.h"

@implementation Lesson (CoreDataProperties)

+ (NSFetchRequest<Lesson *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Lesson"];
}

@dynamic flightCompletionStds;
@dynamic flightDescription;
@dynamic flightObjective;
@dynamic groundCompletionStds;
@dynamic groundDescription;
@dynamic groundObjective;
@dynamic groupIdToSave;
@dynamic indentation;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic lessonID;
@dynamic lessonNumber;
@dynamic minDual;
@dynamic minGround;
@dynamic minInstrument;
@dynamic minSolo;
@dynamic name;
@dynamic studentUserID;
@dynamic title;
@dynamic lesson_local_id;
@dynamic assignments;
@dynamic content;
@dynamic lessonGroup;
@dynamic record;
- (void)insertObject:(Assignment *)value inAssignmentsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet insertObject:value atIndex:idx];
    self.assignments = tempSet;
}
- (void)removeObjectFromAssignmentsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet removeObjectAtIndex:idx];
    self.assignments = tempSet;
}
- (void)insertAssignments:(NSArray<Assignment *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet insertObjects:value atIndexes:indexes];
    self.assignments = tempSet;
}
- (void)removeAssignmentsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet removeObjectsAtIndexes:indexes];
    self.assignments = tempSet;
}
- (void)replaceObjectInAssignmentsAtIndex:(NSUInteger)idx withObject:(Assignment *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.assignments = tempSet;
}
- (void)replaceAssignmentsAtIndexes:(NSIndexSet *)indexes withAssignments:(NSArray<Assignment *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.assignments = tempSet;
}
- (void)addAssignmentsObject:(Assignment *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet addObject:value];
    self.assignments = tempSet;
}
- (void)removeAssignmentsObject:(Assignment *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    [tempSet removeObject:value];
    self.assignments = tempSet;
}
- (void)addAssignments:(NSOrderedSet<Assignment *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.assignments = tmpOrderedSet;
    }
}
- (void)removeAssignments:(NSOrderedSet<Assignment *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.assignments];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.assignments = tmpOrderedSet;
    }
}

- (void)insertObject:(Content *)value inContentAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet insertObject:value atIndex:idx];
    self.content = tempSet;
}
- (void)removeObjectFromContentAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet removeObjectAtIndex:idx];
    self.content = tempSet;
}
- (void)insertContent:(NSArray<Content *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet insertObjects:value atIndexes:indexes];
    self.content = tempSet;
}
- (void)removeContentAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet removeObjectsAtIndexes:indexes];
    self.content = tempSet;
}
- (void)replaceObjectInContentAtIndex:(NSUInteger)idx withObject:(Content *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.content = tempSet;
}
- (void)replaceContentAtIndexes:(NSIndexSet *)indexes withContent:(NSArray<Content *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.content = tempSet;
}
- (void)addContentObject:(Content *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet addObject:value];
    self.content = tempSet;
}
- (void)removeContentObject:(Content *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    [tempSet removeObject:value];
    self.content = tempSet;
}
- (void)addContent:(NSOrderedSet<Content *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.content = tmpOrderedSet;
    }
}
- (void)removeContent:(NSOrderedSet<Content *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.content];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.content = tmpOrderedSet;
    }
}
@end
