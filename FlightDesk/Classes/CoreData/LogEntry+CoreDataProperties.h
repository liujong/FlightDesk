//
//  LogEntry+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/26/17.
//
//

#import "LogEntry+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface LogEntry (CoreDataProperties)

+ (NSFetchRequest<LogEntry *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *aircraftCategory;
@property (nullable, nonatomic, copy) NSString *aircraftClass;
@property (nullable, nonatomic, copy) NSString *aircraftModel;
@property (nullable, nonatomic, copy) NSString *aircraftRegistration;
@property (nullable, nonatomic, copy) NSNumber *approachesCount;
@property (nullable, nonatomic, copy) NSString *approachesType;
@property (nullable, nonatomic, copy) NSDecimalNumber *complex;
@property (nullable, nonatomic, copy) NSDate *creationDateTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGiven;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenCFI;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenCommercial;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenGlider;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenInstrument;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenOther;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenRecreational;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualGivenSport;
@property (nullable, nonatomic, copy) NSDecimalNumber *dualReceived;
@property (nullable, nonatomic, copy) NSNumber *entryID;
@property (nullable, nonatomic, copy) NSString *flightRoute;
@property (nullable, nonatomic, copy) NSDecimalNumber *glider;
@property (nullable, nonatomic, copy) NSDecimalNumber *groundTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *helicopter;
@property (nullable, nonatomic, copy) NSDecimalNumber *highPerf;
@property (nullable, nonatomic, copy) NSDecimalNumber *hobbsIn;
@property (nullable, nonatomic, copy) NSDecimalNumber *hobbsOut;
@property (nullable, nonatomic, copy) NSNumber *holds;
@property (nullable, nonatomic, copy) NSString *instructorCertNo;
@property (nullable, nonatomic, copy) NSNumber *instructorID;
@property (nullable, nonatomic, copy) NSString *instructorSignature;
@property (nullable, nonatomic, copy) NSDecimalNumber *instrumentActual;
@property (nullable, nonatomic, copy) NSDecimalNumber *instrumentHood;
@property (nullable, nonatomic, copy) NSDecimalNumber *instrumentSim;
@property (nullable, nonatomic, copy) NSDecimalNumber *jet;
@property (nullable, nonatomic, copy) NSNumber *landingsDay;
@property (nullable, nonatomic, copy) NSNumber *landingsNight;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSNumber *lessonId;
@property (nullable, nonatomic, copy) NSDate *logDate;
@property (nullable, nonatomic, copy) NSDecimalNumber *nightDualReceived;
@property (nullable, nonatomic, copy) NSDecimalNumber *nightTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *picTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *recreational;
@property (nullable, nonatomic, copy) NSString *remarks;
@property (nullable, nonatomic, copy) NSDecimalNumber *sicTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *soloTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *sport;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSDecimalNumber *taildragger;
@property (nullable, nonatomic, copy) NSDecimalNumber *totalFlightTime;
@property (nullable, nonatomic, copy) NSString *tracking;
@property (nullable, nonatomic, copy) NSDecimalNumber *turboprop;
@property (nullable, nonatomic, copy) NSDecimalNumber *ultraLight;
@property (nullable, nonatomic, copy) NSNumber *userID;
@property (nullable, nonatomic, copy) NSNumber *valueForSort;
@property (nullable, nonatomic, copy) NSDecimalNumber *xc;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcDualGiven;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcDualReceived;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcNightDualReceived;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcNightTime;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcPIC;
@property (nullable, nonatomic, copy) NSDecimalNumber *xcSolo;
@property (nullable, nonatomic, copy) NSNumber *log_local_id;
@property (nullable, nonatomic, retain) NSOrderedSet<Endorsement *> *endorsements;
@property (nullable, nonatomic, retain) LessonRecord *logLessonRecord;

@end

@interface LogEntry (CoreDataGeneratedAccessors)

- (void)insertObject:(Endorsement *)value inEndorsementsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEndorsementsAtIndex:(NSUInteger)idx;
- (void)insertEndorsements:(NSArray<Endorsement *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEndorsementsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEndorsementsAtIndex:(NSUInteger)idx withObject:(Endorsement *)value;
- (void)replaceEndorsementsAtIndexes:(NSIndexSet *)indexes withEndorsements:(NSArray<Endorsement *> *)values;
- (void)addEndorsementsObject:(Endorsement *)value;
- (void)removeEndorsementsObject:(Endorsement *)value;
- (void)addEndorsements:(NSOrderedSet<Endorsement *> *)values;
- (void)removeEndorsements:(NSOrderedSet<Endorsement *> *)values;

@end

NS_ASSUME_NONNULL_END
