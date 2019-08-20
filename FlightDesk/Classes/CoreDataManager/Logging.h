//
//  Logging.h
//  FlightDesk
//
//  Created by Gregory Bayard on 2/6/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#ifndef Logging_h
#define Logging_h

#include <os/log.h>

#define FD_LOG_DEBUG 1
#define FD_LOG_INFO 2
#define FD_LOG_ERROR 3
#define FD_LOG_FAULT 4

void FDLog(int level, NSString *format, ...);

// ASL_LEVEL_NOTICE level for release, ASL_LEVEL_DEBUG level for debug
#ifndef FD_COMPILE_TIME_LOG_LEVEL

// default log levels based on X-Code project's release level
#ifdef NDEBUG
#define FD_COMPILE_TIME_LOG_LEVEL FD_LOG_DEBUG
#else
#define FD_COMPILE_TIME_LOG_LEVEL FD_LOG_DEBUG
#endif

#endif

// define each log level
#if FD_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_CRIT
#define FDLogCritical(args...) FDLog(FD_LOG_FAULT,args);
#else
#define FDLogCritical(...)
#endif

#if FD_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_ERR
#define FDLogError(args...) FDLog(FD_LOG_ERROR,args);
#else
#define FDLogError(...)
#endif

#if FD_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_INFO
#define FDLogInfo(args...) FDLog(FD_LOG_INFO,args);
#else
#define FDLogInfo(...)
#endif

#if FD_COMPILE_TIME_LOG_LEVEL >= ASL_LEVEL_DEBUG
#define FDLogDebug(args...) FDLog(FD_LOG_DEBUG,args);
#else
#define FDLogDebug(...)
#endif

#endif /* Logging_h */
