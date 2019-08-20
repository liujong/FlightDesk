//
//  Checklists+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 9/20/17.
//
//

#import "Checklists+CoreDataProperties.h"

@implementation Checklists (CoreDataProperties)

+ (NSFetchRequest<Checklists *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Checklists"];
}

@dynamic category;
@dynamic checklist;
@dynamic checklistsID;
@dynamic checklistsLocalId;
@dynamic groupChecklist;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic parentChecklistsID;
@dynamic userID;
@dynamic warning;
@dynamic checklists;
- (void)insertObject:(ChecklistsContent *)value inChecklistsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet insertObject:value atIndex:idx];
    self.checklists = tempSet;
}
- (void)removeObjectFromChecklistsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet removeObjectAtIndex:idx];
    self.checklists = tempSet;
}
- (void)insertChecklists:(NSArray<ChecklistsContent *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet insertObjects:value atIndexes:indexes];
    self.checklists = tempSet;
}
- (void)removeChecklistsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet removeObjectsAtIndexes:indexes];
    self.checklists = tempSet;
}
- (void)replaceObjectInChecklistsAtIndex:(NSUInteger)idx withObject:(ChecklistsContent *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.checklists = tempSet;
}
- (void)replaceChecklistsAtIndexes:(NSIndexSet *)indexes withChecklists:(NSArray<ChecklistsContent *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.checklists = tempSet;
}
- (void)addChecklistsObject:(ChecklistsContent *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet addObject:value];
    self.checklists = tempSet;
}
- (void)removeChecklistsObject:(ChecklistsContent *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    [tempSet removeObject:value];
    self.checklists = tempSet;
}
- (void)addChecklists:(NSOrderedSet<ChecklistsContent *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.checklists = tmpOrderedSet;
    }
}
- (void)removeChecklists:(NSOrderedSet<ChecklistsContent *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.checklists];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.checklists = tmpOrderedSet;
    }
}
@end
