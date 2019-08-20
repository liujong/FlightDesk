//
//  LessonGroup+CoreDataProperties.m
//  
//
//  Created by Liu Jie on 8/3/17.
//
//

#import "LessonGroup+CoreDataProperties.h"

@implementation LessonGroup (CoreDataProperties)

+ (NSFetchRequest<LessonGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"LessonGroup"];
}

@dynamic expanded;
@dynamic groupID;
@dynamic indentation;
@dynamic instructorBadgeCount;
@dynamic instructorCfiCertExpDate;
@dynamic instructorDeviceToken;
@dynamic instructorEmail;
@dynamic instructorID;
@dynamic instructorName;
@dynamic instructorPilotCert;
@dynamic is_active;
@dynamic isShown;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic name;
@dynamic studentUserID;
@dynamic ableByAdmin;
@dynamic documents;
@dynamic lessons;
@dynamic parentGroup;
@dynamic quizes;
@dynamic student;
@dynamic subGroups;

- (void)insertObject:(Document *)value inDocumentsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet insertObject:value atIndex:idx];
    self.documents = tempSet;
}
- (void)removeObjectFromDocumentsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet removeObjectAtIndex:idx];
    self.documents = tempSet;
}
- (void)insertDocuments:(NSArray<Document *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet insertObjects:value atIndexes:indexes];
    self.documents = tempSet;
}
- (void)removeDocumentsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet removeObjectsAtIndexes:indexes];
    self.documents = tempSet;
}
- (void)replaceObjectInDocumentsAtIndex:(NSUInteger)idx withObject:(Document *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.documents = tempSet;
}
- (void)replaceDocumentsAtIndexes:(NSIndexSet *)indexes withDocuments:(NSArray<Document *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.documents = tempSet;
}
- (void)addDocumentsObject:(Document *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet addObject:value];
    self.documents = tempSet;
}
- (void)removeDocumentsObject:(Document *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    [tempSet removeObject:value];
    self.documents = tempSet;
}
- (void)addDocuments:(NSOrderedSet<Document *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.documents = tmpOrderedSet;
    }
}
- (void)removeDocuments:(NSOrderedSet<Document *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.documents];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.documents = tmpOrderedSet;
    }
}

- (void)insertObject:(Lesson *)value inLessonsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet insertObject:value atIndex:idx];
    self.lessons = tempSet;
}
- (void)removeObjectFromLessonsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet removeObjectAtIndex:idx];
    self.lessons = tempSet;
}
- (void)insertLessons:(NSArray<Lesson *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet insertObjects:value atIndexes:indexes];
    self.lessons = tempSet;
}
- (void)removeLessonsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet removeObjectsAtIndexes:indexes];
    self.lessons = tempSet;
}
- (void)replaceObjectInLessonsAtIndex:(NSUInteger)idx withObject:(Lesson *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.lessons = tempSet;
}
- (void)replaceLessonsAtIndexes:(NSIndexSet *)indexes withLessons:(NSArray<Lesson *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.lessons = tempSet;
}
- (void)addLessonsObject:(Lesson *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet addObject:value];
    self.lessons = tempSet;
}
- (void)removeLessonsObject:(Lesson *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    [tempSet removeObject:value];
    self.lessons = tempSet;
}
- (void)addLessons:(NSOrderedSet<Lesson *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.lessons = tmpOrderedSet;
    }
}
- (void)removeLessons:(NSOrderedSet<Lesson *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.lessons];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.lessons = tmpOrderedSet;
    }
}

- (void)insertObject:(Quiz *)value inQuizesAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet insertObject:value atIndex:idx];
    self.quizes = tempSet;
}
- (void)removeObjectFromQuizesAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet removeObjectAtIndex:idx];
    self.quizes = tempSet;
}
- (void)insertQuizes:(NSArray<Quiz *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet insertObjects:value atIndexes:indexes];
    self.quizes = tempSet;
}
- (void)removeQuizesAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet removeObjectsAtIndexes:indexes];
    self.quizes = tempSet;
}
- (void)replaceObjectInQuizesAtIndex:(NSUInteger)idx withObject:(Quiz *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.quizes = tempSet;
}
- (void)replaceQuizesAtIndexes:(NSIndexSet *)indexes withQuizes:(NSArray<Quiz *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.quizes = tempSet;
}
- (void)addQuizesObject:(Quiz *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet addObject:value];
    self.quizes = tempSet;
}
- (void)removeQuizesObject:(Quiz *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    [tempSet removeObject:value];
    self.quizes = tempSet;
}
- (void)addQuizes:(NSOrderedSet<Quiz *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.quizes = tmpOrderedSet;
    }
}
- (void)removeQuizes:(NSOrderedSet<Quiz *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.quizes];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.quizes = tmpOrderedSet;
    }
}

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
