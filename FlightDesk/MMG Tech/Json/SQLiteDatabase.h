//
//  SQLiteDatabase.h
//  giftgallary1
//
//  Created by Shivang Vyas on 11/21/13.
//  Copyright (c) 2013 dhiren. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLiteDatabase : NSObject {
    sqlite3 *database;
}

+ (NSString *) databasePath;
+ (void) copyDatabaseToDocumentDir;

+ (BOOL)performQuery:(NSString *)query;
+ (NSMutableArray *) performSelectQuery:(NSString *) query;
+ (BOOL) exportCsv: (NSString *)filename :(NSString *) query;
+ (void) createTempFile: (NSString*) filename;
@end