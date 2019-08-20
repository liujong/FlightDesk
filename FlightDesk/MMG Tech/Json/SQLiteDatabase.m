//
//  SQLiteDatabase.m
//  giftgallary1
//
//  Created by Shivang Vyas on 11/21/13.
//  Copyright (c) 2013 dhiren. All rights reserved.
//

#import "SQLiteDatabase.h"

#define DocumentDir ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])
#define DatabaseName @"quizdb"


@implementation SQLiteDatabase

+ (NSString *) databasePath {
    NSLog(@"%@",[NSString stringWithFormat:@"%@/%@.sqlite",DocumentDir,DatabaseName]);
    return [NSString stringWithFormat:@"%@/%@.sqlite",DocumentDir,DatabaseName];
}

+ (void) copyDatabaseToDocumentDir {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[SQLiteDatabase databasePath]]) {
        NSError * error;
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:DatabaseName ofType:@"sqlite"] toPath:[SQLiteDatabase databasePath] error:&error];
    }  
}

// For Insert/Update/Delete
+ (BOOL)performQuery:(NSString *)query {
    BOOL success = false;
    sqlite3_stmt *statement = NULL;
    sqlite3 *mySqliteDB;
    const char *dbpath = [[SQLiteDatabase databasePath] UTF8String];
    if (sqlite3_open(dbpath, &mySqliteDB) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithString:query];
        
        const char *insert_stmt = [insertSQL UTF8String];
        if (sqlite3_prepare_v2(mySqliteDB, insert_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                success = true;
            }
            else {
                NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
            }
        } else {
            NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
        }
    
    } else {
        NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(mySqliteDB);
    
    return success;
}


// For Select Data.
+ (NSMutableArray *) performSelectQuery:(NSString *) query
{
    NSMutableArray *responseData = [[NSMutableArray alloc] init];
    const char *dbpath = [[SQLiteDatabase databasePath] UTF8String];
    sqlite3_stmt    *statement;
    sqlite3 *mySqliteDB;
    if (sqlite3_open(dbpath, &mySqliteDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithString:query];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(mySqliteDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
//             Get Table Information.
//            BOOL isDynamicDataType = YES;
//            if (tableName == nil) {
//                isDynamicDataType = NO;
//            }
//            NSDictionary * tableInfo = [NSDictionary dictionaryWithDictionary:[self getColumnDataTypeValueForTable:tableName]];
//            NSLog(@"%@",tableInfo);
            
            int countColumn = sqlite3_column_count(statement);
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSMutableDictionary * row = [[NSMutableDictionary alloc] init];
                
                for (int i=0; i<countColumn; i++) {
                    NSString * columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];
                    
//                    if (isDynamicDataType) {
                        if ([[columnName lowercaseString] isEqualToString:@"max(ID)"] || [columnName isEqualToString:@"ID"])
                        {
                            int field = (int)sqlite3_column_int(statement, i);
                            [row setObject:[NSString stringWithFormat:@"%d",field] forKey:columnName];
                        }
                        else
                        {
                            [row setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:columnName];
                        }
//                    } else {
//                        [row setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:columnName];
//                    }
                    
                }
                [responseData addObject:row];
            }
            sqlite3_finalize(statement);
        } else {
            NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
        }
        sqlite3_close(mySqliteDB);
    } else {
        NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
    }
    
    return responseData;
}

+ (NSMutableDictionary *) getColumnDataTypeValueForTable:(NSString *) tableName
{
    NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] init];
    NSString * tableInfoQuery = [NSString stringWithFormat:@"pragma table_info(%@)",tableName];
    NSMutableArray * tableInfoArray = [SQLiteDatabase performSelectQuery:tableInfoQuery];
    
    for (int i=0; i<[tableInfoArray count]; i++) {
        NSDictionary * tableInfoDict = [NSDictionary dictionaryWithDictionary:[tableInfoArray objectAtIndex:i]];
        [dataDict setObject:[tableInfoDict valueForKey:@"type"] forKey:[tableInfoDict valueForKey:@"name"]];
    }
    return dataDict;
}

+(BOOL) exportCsv: (NSString *)filename :(NSString *) query
{
    NSMutableArray *responseData = [[NSMutableArray alloc] init];
    const char *dbpath = [[SQLiteDatabase databasePath] UTF8String];
    sqlite3_stmt    *statement;
    sqlite3 *mySqliteDB;
    if (sqlite3_open(dbpath, &mySqliteDB) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithString:query];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(mySqliteDB, query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            //             Get Table Information.
            //            BOOL isDynamicDataType = YES;
            //            if (tableName == nil) {
            //                isDynamicDataType = NO;
            //            }
            //            NSDictionary * tableInfo = [NSDictionary dictionaryWithDictionary:[self getColumnDataTypeValueForTable:tableName]];
            //            NSLog(@"%@",tableInfo);
            
            
            [self createTempFile: filename];
            NSOutputStream* output = [[NSOutputStream alloc] initToFileAtPath: filename append: YES];
            [output open];
            if (![output hasSpaceAvailable]) {
                NSLog(@"No space available in %@", filename);
                return FALSE;
                // TODO: UIAlertView?
            } else {
                NSString* header = @"NO,First Name,Last Name,Email Address,Age,Phone No,Datetime\n";
                NSInteger result = [output write: (unsigned char *)[header UTF8String] maxLength: [header length]];
                if (result <= 0) {
                    NSLog(@"exportCsv encountered error=%ld from header write", (long)result);
                    return FALSE;
                }

            }
            int countColumn = sqlite3_column_count(statement);
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSMutableDictionary * row = [[NSMutableDictionary alloc] init];
                
                for (int i=0; i<countColumn; i++) {
                    NSString * columnName = [NSString stringWithUTF8String:sqlite3_column_name(statement, i)];
                    
                    //                    if (isDynamicDataType) {
                    if ([[columnName lowercaseString] isEqualToString:@"max(ID)"] || [columnName isEqualToString:@"ID"])
                    {
                        int field = (int)sqlite3_column_int(statement, i);
                        [row setObject:[NSString stringWithFormat:@"%d",field] forKey:columnName];
                    }
                    else
                    {
                        [row setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:columnName];
                    }
                    //                    } else {
                    //                        [row setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:columnName];
                    //                    }
                    
                }
               
                NSString* line = [[NSString alloc] initWithFormat: @"%@,%@,%@,%@,%@,%@,%@\n",[row objectForKey:@"id"],[row objectForKey:@"fname"],[row objectForKey:@"lname"],[row objectForKey:@"email"],[row objectForKey:@"age"],[row objectForKey:@"phone"],[row objectForKey:@"datetime"]];
                 NSInteger result = [output write: (unsigned char*)[line UTF8String] maxLength: [line length]];
                if (result <= 0) {
                    NSLog(@"exportCsv write returned %ld", (long)result);
                   
                }
                NSLog(@"row=%@",row);
                [responseData addObject:row];
                 NSLog(@"responseData=%@",responseData);
            }
            sqlite3_finalize(statement);
        } else {
            NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
            return FALSE;
        }
        sqlite3_close(mySqliteDB);
    } else {
        
        NSLog(@"SQL:Error %s",sqlite3_errmsg(mySqliteDB));
        return FALSE;
    }
    
    return TRUE;
}

+(void) createTempFile: (NSString*) filename {
    NSFileManager* fileSystem = [NSFileManager defaultManager];
    [fileSystem removeItemAtPath: filename error: nil];
    
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    NSNumber* permission = [NSNumber numberWithLong: 0640];
    [attributes setObject: permission forKey: NSFilePosixPermissions];
    if (![fileSystem createFileAtPath: filename contents: nil attributes: attributes]) {
        NSLog(@"Unable to create temp file for exporting CSV.");
        // TODO: UIAlertView?
    }
   
}


@end
