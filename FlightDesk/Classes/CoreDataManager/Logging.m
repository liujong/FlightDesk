//
//  Logging.m
//  FlightDesk
//
//  Created by Gregory Bayard on 2/7/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#import "Logging.h"

static os_log_t fd_log;

static void AddStderrOnce()
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fd_log = os_log_create("com.nova.aero-FligthDesk", "FD");
    });
}

void FDLog(int level, NSString *format, ...)
{
    AddStderrOnce();
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    switch (level) {
        case FD_LOG_INFO:
        {
            os_log_info(fd_log, "%@", message);
            break;
        }
        case FD_LOG_DEBUG:
        {
            os_log_debug(fd_log, "%@", message);
            break;
        }
        case FD_LOG_ERROR:
        {
            os_log_error(fd_log, "%@", message);
            break;
        }
        case FD_LOG_FAULT:
        {
            os_log_fault(fd_log, "%@", message);
            break;
        }
        default:
        {
            
        }
    }
    va_end(args);
}
