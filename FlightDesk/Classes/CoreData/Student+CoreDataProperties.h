//
//  Student+CoreDataProperties.h
//  
//
//  Created by Liu Jie on 8/2/17.
//
//

#import "Student+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Student (CoreDataProperties)

+ (NSFetchRequest<Student *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *badgeCount;
@property (nullable, nonatomic, copy) NSString *deviceToken;
@property (nullable, nonatomic, copy) NSNumber *expanded;
@property (nullable, nonatomic, copy) NSString *firstName;
@property (nullable, nonatomic, copy) NSNumber *is_active;
@property (nullable, nonatomic, copy) NSString *lastName;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *studentEmail;
@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, copy) NSString *username;
@property (nullable, nonatomic, retain) NSOrderedSet<LessonGroup *> *subGroups;

@end

@interface Student (CoreDataGeneratedAccessors)

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
