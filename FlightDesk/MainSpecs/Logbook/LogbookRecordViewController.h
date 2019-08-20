//
//  LogbookRecordViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 4/6/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogEntry;

@interface LogbookRecordViewController : UIViewController

- (id)initWithLogEntry:(LogEntry*)logEntry;

@property BOOL isTotal;

@property BOOL isOpenFromLogBook;
@end
