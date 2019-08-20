//
//  Quiz+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 6/28/17.
//
//

#import "Quiz+CoreDataProperties.h"

@implementation Quiz (CoreDataProperties)

+ (NSFetchRequest<Quiz *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Quiz"];
}

@dynamic courseGroupID;
@dynamic gotScore;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic name;
@dynamic passingScore;
@dynamic quizId;
@dynamic quizNumber;
@dynamic quizTaken;
@dynamic recordId;
@dynamic studentUserID;
@dynamic timeLimit;
@dynamic quizGroupId;
@dynamic questions;
@dynamic quizgroup;

- (void)insertObject:(Question *)value inQuestionsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet insertObject:value atIndex:idx];
    self.questions = tempSet;
}
- (void)removeObjectFromQuestionsAtIndex:(NSUInteger)idx{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet removeObjectAtIndex:idx];
    self.questions = tempSet;
}
- (void)insertQuestions:(NSArray<Question *> *)value atIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet insertObjects:value atIndexes:indexes];
    self.questions = tempSet;
}
- (void)removeQuestionsAtIndexes:(NSIndexSet *)indexes{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet removeObjectsAtIndexes:indexes];
    self.questions = tempSet;
}
- (void)replaceObjectInQuestionsAtIndex:(NSUInteger)idx withObject:(Question *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet replaceObjectAtIndex:idx withObject:value];
    self.questions = tempSet;
}
- (void)replaceQuestionsAtIndexes:(NSIndexSet *)indexes withQuestions:(NSArray<Question *> *)values{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet replaceObjectsAtIndexes:indexes withObjects:values];
    self.questions = tempSet;
}
- (void)addQuestionsObject:(Question *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet addObject:value];
    self.questions = tempSet;
}
- (void)removeQuestionsObject:(Question *)value{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    [tempSet removeObject:value];
    self.questions = tempSet;
}
- (void)addQuestions:(NSOrderedSet<Question *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSUInteger valuesCount = [values count];
    NSUInteger objectsCount = [tmpOrderedSet count];
    for (NSUInteger i = 0; i < valuesCount; ++i) {
        [indexes addIndex:(objectsCount + i)];
    }
    if (valuesCount > 0) {
        [tmpOrderedSet addObjectsFromArray:[values array]];
        self.questions = tmpOrderedSet;
    }
}
- (void)removeQuestions:(NSOrderedSet<Question *> *)values{
    NSMutableOrderedSet *tmpOrderedSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.questions];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for (id value in values) {
        NSUInteger idx = [tmpOrderedSet indexOfObject:value];
        if (idx != NSNotFound) {
            [indexes addIndex:idx];
        }
    }
    if ([indexes count] > 0) {
        [tmpOrderedSet removeObjectsAtIndexes:indexes];
        self.questions = tmpOrderedSet;
    }
}
@end
