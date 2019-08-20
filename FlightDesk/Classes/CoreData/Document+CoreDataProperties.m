//
//  Document+CoreDataProperties.m
//  
//
//  Created by stepanekdavid on 7/21/17.
//
//

#import "Document+CoreDataProperties.h"

@implementation Document (CoreDataProperties)

+ (NSFetchRequest<Document *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Document"];
}

@dynamic documentID;
@dynamic downloaded;
@dynamic groupID;
@dynamic lastSync;
@dynamic lastUpdate;
@dynamic name;
@dynamic pdfURL;
@dynamic remoteURL;
@dynamic studentID;
@dynamic type;

@end
