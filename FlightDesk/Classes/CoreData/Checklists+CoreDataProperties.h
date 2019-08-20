//
//  Checklists+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/20/17.
//
//

#import "Checklists+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Checklists (CoreDataProperties)

+ (NSFetchRequest<Checklists *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *category;
@property (nullable, nonatomic, copy) NSString *checklist;
@property (nullable, nonatomic, copy) NSNumber *checklistsID;
@property (nullable, nonatomic, copy) NSNumber *checklistsLocalId;
@property (nullable, nonatomic, copy) NSString *groupChecklist;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSNumber *parentChecklistsID;
@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, copy) NSString *warning;
@property (nullable, nonatomic, retain) NSOrderedSet<ChecklistsContent *> *checklists;

@end

@interface Checklists (CoreDataGeneratedAccessors)

- (void)insertObject:(ChecklistsContent *)value inChecklistsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromChecklistsAtIndex:(NSUInteger)idx;
- (void)insertChecklists:(NSArray<ChecklistsContent *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeChecklistsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInChecklistsAtIndex:(NSUInteger)idx withObject:(ChecklistsContent *)value;
- (void)replaceChecklistsAtIndexes:(NSIndexSet *)indexes withChecklists:(NSArray<ChecklistsContent *> *)values;
- (void)addChecklistsObject:(ChecklistsContent *)value;
- (void)removeChecklistsObject:(ChecklistsContent *)value;
- (void)addChecklists:(NSOrderedSet<ChecklistsContent *> *)values;
- (void)removeChecklists:(NSOrderedSet<ChecklistsContent *> *)values;

@end

NS_ASSUME_NONNULL_END
