//
//  Faqs+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 10/31/17.
//
//

#import "Faqs+CoreDataProperties.h"

@implementation Faqs (CoreDataProperties)

+ (NSFetchRequest<Faqs *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Faqs"];
}

@dynamic answer;
@dynamic category;
@dynamic faqs_id;
@dynamic faqs_local_id;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic question;

@end
