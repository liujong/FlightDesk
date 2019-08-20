//
//  LessonGroup+CoreDataProperties.h
//  
//
//  Created by Liu Jie on 8/3/17.
//
//

#import "LessonGroup+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface LessonGroup (CoreDataProperties)

+ (NSFetchRequest<LessonGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *expanded;
@property (nullable, nonatomic, copy) NSNumber *groupID;
@property (nullable, nonatomic, copy) NSNumber *indentation;
@property (nullable, nonatomic, copy) NSNumber *instructorBadgeCount;
@property (nullable, nonatomic, copy) NSString *instructorCfiCertExpDate;
@property (nullable, nonatomic, copy) NSString *instructorDeviceToken;
@property (nullable, nonatomic, copy) NSString *instructorEmail;
@property (nullable, nonatomic, copy) NSNumber *instructorID;
@property (nullable, nonatomic, copy) NSString *instructorName;
@property (nullable, nonatomic, copy) NSString *instructorPilotCert;
@property (nullable, nonatomic, copy) NSNumber *is_active;
@property (nullable, nonatomic, copy) NSNumber *isShown;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSNumber *ableByAdmin;
@property (nullable, nonatomic, retain) NSOrderedSet<Document *> *documents;
@property (nullable, nonatomic, retain) NSOrderedSet<Lesson *> *lessons;
@property (nullable, nonatomic, retain) LessonGroup *parentGroup;
@property (nullable, nonatomic, retain) NSOrderedSet<Quiz *> *quizes;
@property (nullable, nonatomic, retain) Student *student;
@property (nullable, nonatomic, retain) NSOrderedSet<LessonGroup *> *subGroups;

@end


@interface LessonGroup (CoreDataGeneratedAccessors)

- (void)insertObject:(Document *)value inDocumentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDocumentsAtIndex:(NSUInteger)idx;
- (void)insertDocuments:(NSArray<Document *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDocumentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDocumentsAtIndex:(NSUInteger)idx withObject:(Document *)value;
- (void)replaceDocumentsAtIndexes:(NSIndexSet *)indexes withDocuments:(NSArray<Document *> *)values;
- (void)addDocumentsObject:(Document *)value;
- (void)removeDocumentsObject:(Document *)value;
- (void)addDocuments:(NSOrderedSet<Document *> *)values;
- (void)removeDocuments:(NSOrderedSet<Document *> *)values;

- (void)insertObject:(Lesson *)value inLessonsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLessonsAtIndex:(NSUInteger)idx;
- (void)insertLessons:(NSArray<Lesson *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLessonsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLessonsAtIndex:(NSUInteger)idx withObject:(Lesson *)value;
- (void)replaceLessonsAtIndexes:(NSIndexSet *)indexes withLessons:(NSArray<Lesson *> *)values;
- (void)addLessonsObject:(Lesson *)value;
- (void)removeLessonsObject:(Lesson *)value;
- (void)addLessons:(NSOrderedSet<Lesson *> *)values;
- (void)removeLessons:(NSOrderedSet<Lesson *> *)values;

- (void)insertObject:(Quiz *)value inQuizesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromQuizesAtIndex:(NSUInteger)idx;
- (void)insertQuizes:(NSArray<Quiz *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeQuizesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInQuizesAtIndex:(NSUInteger)idx withObject:(Quiz *)value;
- (void)replaceQuizesAtIndexes:(NSIndexSet *)indexes withQuizes:(NSArray<Quiz *> *)values;
- (void)addQuizesObject:(Quiz *)value;
- (void)removeQuizesObject:(Quiz *)value;
- (void)addQuizes:(NSOrderedSet<Quiz *> *)values;
- (void)removeQuizes:(NSOrderedSet<Quiz *> *)values;

- (void)insertObject:(LessonGroup *)value inSubGroupsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSubGroupsAtIndex:(NSUInteger)idx;
- (void)insertSubGroups:(NSArray<LessonGroup *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSubGroupsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSubGroupsAtIndex:(NSUInteger)idx withObject:(LessonGroup *)value;
- (void)replaceSubGroupsAtIndexes:(NSIndexSet *)indexes withSubGroups:(NSArray<LessonGroup *> *)values;
- (void)addSubGroupsObject:(LessonGroup *)value;
- (void)removeSubGroupsObject:(LessonGroup *)value;
- (void)addSubGroups:(NSOrderedSet<LessonGroup *> *)values;
- (void)removeSubGroups:(NSOrderedSet<LessonGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
