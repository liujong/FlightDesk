//
//  Lesson+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Lesson+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Lesson (CoreDataProperties)

+ (NSFetchRequest<Lesson *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *flightCompletionStds;
@property (nullable, nonatomic, copy) NSString *flightDescription;
@property (nullable, nonatomic, copy) NSString *flightObjective;
@property (nullable, nonatomic, copy) NSString *groundCompletionStds;
@property (nullable, nonatomic, copy) NSString *groundDescription;
@property (nullable, nonatomic, copy) NSString *groundObjective;
@property (nullable, nonatomic, copy) NSNumber *groupIdToSave;
@property (nullable, nonatomic, copy) NSNumber *indentation;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSNumber *lessonID;
@property (nullable, nonatomic, copy) NSNumber *lessonNumber;
@property (nullable, nonatomic, copy) NSString *minDual;
@property (nullable, nonatomic, copy) NSString *minGround;
@property (nullable, nonatomic, copy) NSString *minInstrument;
@property (nullable, nonatomic, copy) NSString *minSolo;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSNumber *lesson_local_id;
@property (nullable, nonatomic, retain) NSOrderedSet<Assignment *> *assignments;
@property (nullable, nonatomic, retain) NSOrderedSet<Content *> *content;
@property (nullable, nonatomic, retain) LessonGroup *lessonGroup;
@property (nullable, nonatomic, retain) LessonRecord *record;

@end

@interface Lesson (CoreDataGeneratedAccessors)

- (void)insertObject:(Assignment *)value inAssignmentsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAssignmentsAtIndex:(NSUInteger)idx;
- (void)insertAssignments:(NSArray<Assignment *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAssignmentsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAssignmentsAtIndex:(NSUInteger)idx withObject:(Assignment *)value;
- (void)replaceAssignmentsAtIndexes:(NSIndexSet *)indexes withAssignments:(NSArray<Assignment *> *)values;
- (void)addAssignmentsObject:(Assignment *)value;
- (void)removeAssignmentsObject:(Assignment *)value;
- (void)addAssignments:(NSOrderedSet<Assignment *> *)values;
- (void)removeAssignments:(NSOrderedSet<Assignment *> *)values;

- (void)insertObject:(Content *)value inContentAtIndex:(NSUInteger)idx;
- (void)removeObjectFromContentAtIndex:(NSUInteger)idx;
- (void)insertContent:(NSArray<Content *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeContentAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInContentAtIndex:(NSUInteger)idx withObject:(Content *)value;
- (void)replaceContentAtIndexes:(NSIndexSet *)indexes withContent:(NSArray<Content *> *)values;
- (void)addContentObject:(Content *)value;
- (void)removeContentObject:(Content *)value;
- (void)addContent:(NSOrderedSet<Content *> *)values;
- (void)removeContent:(NSOrderedSet<Content *> *)values;

@end

NS_ASSUME_NONNULL_END
