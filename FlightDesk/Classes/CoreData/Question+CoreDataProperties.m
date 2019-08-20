//
//  Question+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 6/28/17.
//
//

#import "Question+CoreDataProperties.h"

@implementation Question (CoreDataProperties)

+ (NSFetchRequest<Question *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Question"];
}

@dynamic answerA;
@dynamic answerB;
@dynamic answerC;
@dynamic correctAnswer;
@dynamic explanationcode;
@dynamic explanationofcorrectAnswer;
@dynamic explanationReference;
@dynamic figureurl;
@dynamic gaveAnswer;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic marked;
@dynamic ordering;
@dynamic question;
@dynamic questionId;
@dynamic quizId;
@dynamic recodeId;
@dynamic questionGroupId;
@dynamic questiongroups;

@end
