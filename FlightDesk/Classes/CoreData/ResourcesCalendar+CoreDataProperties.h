//
//  ResourcesCalendar+CoreDataProperties.h
//  
//
//  Created by Liu Jie on 12/8/17.
//
//

#import "ResourcesCalendar+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ResourcesCalendar (CoreDataProperties)

+ (NSFetchRequest<ResourcesCalendar *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *aircrafts;
@property (nullable, nonatomic, copy) NSNumber *alertTimeInterVal;
@property (nullable, nonatomic, copy) NSString *calendar_identify;
@property (nullable, nonatomic, copy) NSString *calendar_name;
@property (nullable, nonatomic, copy) NSString *classrooms;
@property (nullable, nonatomic, copy) NSString *endDate;
@property (nullable, nonatomic, copy) NSNumber *event_id;
@property (nullable, nonatomic, copy) NSString *event_identify;
@property (nullable, nonatomic, copy) NSNumber *event_local_id;
@property (nullable, nonatomic, copy) NSNumber *group_id;
@property (nullable, nonatomic, copy) NSNumber *invitedUser_id;
@property (nullable, nonatomic, copy) NSNumber *isEditable;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSString *startDate;
@property (nullable, nonatomic, copy) NSNumber *timeIntervalEndDate;
@property (nullable, nonatomic, copy) NSNumber *timeIntervalStartDate;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSNumber *user_id;
@property (nullable, nonatomic, copy) NSString *aircraft;
@property (nullable, nonatomic, copy) NSString *classroom;

@end

NS_ASSUME_NONNULL_END
