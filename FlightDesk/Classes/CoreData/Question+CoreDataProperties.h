//
//  Question+CoreDataProperties.h
//  
//
//  Created by stepanekdavid on 6/28/17.
//
//

#import "Question+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Question (CoreDataProperties)

+ (NSFetchRequest<Question *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *answerA;
@property (nullable, nonatomic, copy) NSString *answerB;
@property (nullable, nonatomic, copy) NSString *answerC;
@property (nullable, nonatomic, copy) NSString *correctAnswer;
@property (nullable, nonatomic, copy) NSString *explanationcode;
@property (nullable, nonatomic, copy) NSString *explanationofcorrectAnswer;
@property (nullable, nonatomic, copy) NSString *explanationReference;
@property (nullable, nonatomic, copy) NSString *figureurl;
@property (nullable, nonatomic, copy) NSString *gaveAnswer;
@property (nullable, nonatomic, copy) NSNumber *lastSync;
@property (nullable, nonatomic, copy) NSNumber *lastUpdate;
@property (nullable, nonatomic, copy) NSNumber *marked;
@property (nullable, nonatomic, copy) NSNumber *ordering;
@property (nullable, nonatomic, copy) NSString *question;
@property (nullable, nonatomic, copy) NSNumber *questionId;
@property (nullable, nonatomic, copy) NSNumber *quizId;
@property (nullable, nonatomic, copy) NSNumber *recodeId;
@property (nullable, nonatomic, copy) NSNumber *questionGroupId;
@property (nullable, nonatomic, retain) Quiz *questiongroups;

@end

NS_ASSUME_NONNULL_END
