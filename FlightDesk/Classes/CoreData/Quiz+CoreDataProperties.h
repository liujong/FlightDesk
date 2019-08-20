//
//  Quiz+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 6/28/17.
//
//

#import "Quiz+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Quiz (CoreDataProperties)

+ (NSFetchRequest<Quiz *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *courseGroupID;
@property (nullable, nonatomic, copy) NSNumber *gotScore;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *passingScore;
@property (nullable, nonatomic, copy) NSNumber *quizId;
@property (nullable, nonatomic, copy) NSNumber *quizNumber;
@property (nullable, nonatomic, copy) NSNumber *quizTaken;
@property (nullable, nonatomic, copy) NSNumber *recordId;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSString *timeLimit;
@property (nullable, nonatomic, copy) NSNumber *quizGroupId;
@property (nullable, nonatomic, retain) NSOrderedSet<Question *> *questions;
@property (nullable, nonatomic, retain) LessonGroup *quizgroup;

@end

@interface Quiz (CoreDataGeneratedAccessors)

- (void)insertObject:(Question *)value inQuestionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromQuestionsAtIndex:(NSUInteger)idx;
- (void)insertQuestions:(NSArray<Question *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeQuestionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInQuestionsAtIndex:(NSUInteger)idx withObject:(Question *)value;
- (void)replaceQuestionsAtIndexes:(NSIndexSet *)indexes withQuestions:(NSArray<Question *> *)values;
- (void)addQuestionsObject:(Question *)value;
- (void)removeQuestionsObject:(Question *)value;
- (void)addQuestions:(NSOrderedSet<Question *> *)values;
- (void)removeQuestions:(NSOrderedSet<Question *> *)values;

@end

NS_ASSUME_NONNULL_END
