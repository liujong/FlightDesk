//
//  NavLog+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/5/17.
//
//

#import "NavLog+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NavLog (CoreDataProperties)

+ (NSFetchRequest<NavLog *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *navLogID;
@property (nullable, nonatomic, copy) NSNumber *navLogLocalID;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, copy) NSString *navLogName;
@property (nullable, nonatomic, copy) NSString *aircraftNum;
@property (nullable, nonatomic, copy) NSString *navLogDate;
@property (nullable, nonatomic, copy) NSString *notes;
@property (nullable, nonatomic, copy) NSString *casTasVal;
@property (nullable, nonatomic, copy) NSNumber *distLeg;
@property (nullable, nonatomic, copy) NSString *timeOff;
@property (nullable, nonatomic, copy) NSNumber *fuel;
@property (nullable, nonatomic, copy) NSNumber *gph;
@property (nullable, nonatomic, retain) NSOrderedSet<NavLogRecord *> *navLogRecords;

@end

@interface NavLog (CoreDataGeneratedAccessors)

- (void)insertObject:(NavLogRecord *)value inNavLogRecordsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromNavLogRecordsAtIndex:(NSUInteger)idx;
- (void)insertNavLogRecords:(NSArray<NavLogRecord *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeNavLogRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInNavLogRecordsAtIndex:(NSUInteger)idx withObject:(NavLogRecord *)value;
- (void)replaceNavLogRecordsAtIndexes:(NSIndexSet *)indexes withNavLogRecords:(NSArray<NavLogRecord *> *)values;
- (void)addNavLogRecordsObject:(NavLogRecord *)value;
- (void)removeNavLogRecordsObject:(NavLogRecord *)value;
- (void)addNavLogRecords:(NSOrderedSet<NavLogRecord *> *)values;
- (void)removeNavLogRecords:(NSOrderedSet<NavLogRecord *> *)values;

@end

NS_ASSUME_NONNULL_END
