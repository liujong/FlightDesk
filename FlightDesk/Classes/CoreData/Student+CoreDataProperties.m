//
//  Student+CoreDataProperties.m
//  
//
//  Created by Liu Jie on 8/2/17.
//
//

#import "Student+CoreDataProperties.h"

@implementation Student (CoreDataProperties)

+ (NSFetchRequest<Student *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Student"];
}

@dynamic badgeCount;
@dynamic deviceToken;
@dynamic expanded;
@dynamic firstName;
@dynamic is_active;
@dynamic lastName;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic studentEmail;
@dynamic userID;
@dynamic username;
@dynamic subGroups;

- (void)insertObject:(LessonGroup *)value inSubGroupsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet insertObject:value atIndex:idx];
    self.subGroups = tempSet;
}
- (void)removeObjectFromSubGroupsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet removeObjectAtIndex:idx];
    self.subGroups = tempSet;
}
- (void)insertSubGroups:(NSArray<LessonGroup *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet insertObjects:value atIndexes:indexes];
    self.subGroups = tempSet;
}
- (void)removeSubGroupsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet removeObjectsAtIndexes:indexes];
    self.subGroups = tempSet;
}
- (void)replaceObjectInSubGroupsAtIndex:(NSUInteger)idx withObject:(LessonGroup *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.subGroups = tempSet;
}
- (void)replaceSubGroupsAtIndexes:(NSIndexSet *)indexes withSubGroups:(NSArray<LessonGroup *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.subGroups = tempSet;
}
- (void)addSubGroupsObject:(LessonGroup *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet addObject:value];
    self.subGroups = tempSet;
}
- (void)removeSubGroupsObject:(LessonGroup *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    [tempSet removeObject:value];
    self.subGroups = tempSet;
}
- (void)addSubGroups:(NSOrderedSet<LessonGroup *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.subGroups = tmpOrderedSet;
    }
}
- (void)removeSubGroups:(NSOrderedSet<LessonGroup *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.subGroups];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.subGroups = tmpOrderedSet;
    }
}
@end
