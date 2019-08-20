//
//  ChecklistsContent+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 9/18/17.
//
//

#import "ChecklistsContent+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ChecklistsContent (CoreDataProperties)

+ (NSFetchRequest<ChecklistsContent *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *checklistContentID;
@property (nullable, nonatomic, copy) NSNumber *checklistID;
@property (nullable, nonatomic, copy) NSString *content;
@property (nullable, nonatomic, copy) NSString *contentTail;
@property (nullable, nonatomic, copy) NSNumber *isChecked;
@property (nullable, nonatomic, copy) NSNumber *ordering;
@property (nullable, nonatomic, copy) NSString *type;
@property (nullable, nonatomic, retain) Checklists *checkContents;

@end

NS_ASSUME_NONNULL_END
