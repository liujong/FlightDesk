//
//  Assignment+CoreDataProperties.h
//  
//
//  Created by jellaliu on 11/30/17.
//
//

#import "Assignment+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Assignment (CoreDataProperties)

+ (NSFetchRequest<Assignment *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *assignmentID;
@property (nullable, nonatomic, copy) NSString *chapters;
@property (nullable, nonatomic, copy) NSNumber *groundOrFlight;
@property (nullable, nonatomic, copy) NSString *referenceID;
@property (nullable, nonatomic, copy) NSNumber *studentUserID;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSNumber *assignment_local_id;
@property (nullable, nonatomic, retain) Lesson *lesson;

@end

NS_ASSUME_NONNULL_END
