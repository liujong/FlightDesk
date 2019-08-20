//
//  Endorsement+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/26/17.
//
//

#import "Endorsement+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Endorsement (CoreDataProperties)

+ (NSFetchRequest<Endorsement *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *cfiNumber;
@property (nullable, nonatomic, copy) NSString *cfiSignature;
@property (nullable, nonatomic, copy) NSString *endorsementDate;
@property (nullable, nonatomic, copy) NSString *endorsementExpDate;
@property (nullable, nonatomic, copy) NSNumber *endorsementID;
@property (nullable, nonatomic, copy) NSNumber *isSupersed;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSNumber *type;
@property (nullable, nonatomic, copy) NSNumber *endorsement_local_id;
@property (nullable, nonatomic, retain) NSOrderedSet<LogEntry *> *endorsements;

@end

@interface Endorsement (CoreDataGeneratedAccessors)

- (void)insertObject:(LogEntry *)value inEndorsementsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEndorsementsAtIndex:(NSUInteger)idx;
- (void)insertEndorsements:(NSArray<LogEntry *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEndorsementsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEndorsementsAtIndex:(NSUInteger)idx withObject:(LogEntry *)value;
- (void)replaceEndorsementsAtIndexes:(NSIndexSet *)indexes withEndorsements:(NSArray<LogEntry *> *)values;
- (void)addEndorsementsObject:(LogEntry *)value;
- (void)removeEndorsementsObject:(LogEntry *)value;
- (void)addEndorsements:(NSOrderedSet<LogEntry *> *)values;
- (void)removeEndorsements:(NSOrderedSet<LogEntry *> *)values;

@end

NS_ASSUME_NONNULL_END
