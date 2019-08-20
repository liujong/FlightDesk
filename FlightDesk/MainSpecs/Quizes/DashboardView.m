//
//  DashboardView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 12/1/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "DashboardView.h"

@implementation DashboardView
{
    UIView *theDialogView;
    UIView *theContentView;
    UILabel *theTitleLabel;
    UILabel *theContentLabel;
    
    UIView *dashboardView;
}

#define DEFAULT_DURATION 0.3
#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define CURRENCY_RED_COLOR RGBA(219, 54, 36, 1)
#define CURRENCY_YELLOW_COLOR RGBA(253, 222, 35, 1)
#define CURRENCY_GREEN_COLOR RGBA(98, 184, 64, 1)
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:85.0f/255.0f green:85.0f/255.0f blue:85.0f/255.0f alpha:0.9f]];
        [self reloadViewsWithCurrentScreen];
        
    }
    
    return self;
}
- (void)reloadViewsWithCurrentScreen{
    [dashboardView removeFromSuperview];
    LogEntry *latestDayLandingLogEntry = nil;
    LogEntry *latestNightLandingLogEntry = nil;
    LogEntry *oldestApproachLogEntry = nil;
    NSDate *latestLandingDay;
    NSDate *latestLandingNight;
    NSDate *latestLandingFlightReview;
    NSDate *oldestApproachDate;
    
    
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM/dd/yyyy"];
    NSString *strDay = @"";
    
    
    //read logbook from coredata
    NSManagedObjectContext *contextLog = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:contextLog];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"landingsDay != 0 AND picTime != 0 AND landingsDay < 4"];
    [request setPredicate:predicate];
    [request setEntity:entityDesc];
    NSArray *objects = [contextLog executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"Unable to retrieve lessons!");
    } else if (objects.count == 0) {
        NSLog(@"No valid lesson groups found!");
    } else {
        NSLog(@"%lu lesson groups found", (unsigned long)[objects count]);
        NSMutableArray *tempLogbookEntries = [NSMutableArray arrayWithArray:objects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"logDate" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedLogbookEntries = [tempLogbookEntries sortedArrayUsingDescriptors:sortDescriptors];
        
        NSMutableArray *logbooksFiltered = [[NSMutableArray alloc] init];
        NSInteger landingDayCount = 0;
        for (LogEntry *logToCheck in sortedLogbookEntries) {
//            BOOL isExit = NO;
//            for (LogEntry *logLandingDayToCheck in logbooksFiltered) {
//                if ([logLandingDayToCheck.landingsDay integerValue] == [logToCheck.landingsDay integerValue]) {
//                    isExit = YES;
//                    break;
//                }
//            }
//            if (!isExit) {
                [logbooksFiltered addObject:logToCheck];
                landingDayCount +=[logToCheck.landingsDay integerValue];
                if (landingDayCount >= 3) {
                    break;
                }
//            }
        }
        if (logbooksFiltered.count > 0 && landingDayCount>=3) {
//            NSMutableArray *tempLogbookEntriesForLandingDay = [NSMutableArray arrayWithArray:logbooksFiltered];
//            NSSortDescriptor *sortDescriptorForLandingDay = [[NSSortDescriptor alloc] initWithKey:@"landingsDay" ascending:NO];
//            NSArray *sortDescriptorsForLandingDay = [NSArray arrayWithObject:sortDescriptorForLandingDay];
//            NSArray *sortedLogbookEntriesForLandingDay = [tempLogbookEntriesForLandingDay sortedArrayUsingDescriptors:sortDescriptorsForLandingDay];
            latestDayLandingLogEntry = logbooksFiltered[0];
            latestLandingDay = latestDayLandingLogEntry.logDate;
        }
    }
    
    request = [[NSFetchRequest alloc] init];
    predicate = [NSPredicate predicateWithFormat:@"landingsNight != 0 AND picTime != 0 "];
    [request setPredicate:predicate];
    [request setEntity:entityDesc];
    objects = [contextLog executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"Unable to retrieve lessons!");
    } else if (objects.count == 0) {
        NSLog(@"No valid lesson groups found!");
    } else {
        NSLog(@"%lu lesson groups found", (unsigned long)[objects count]);
        NSMutableArray *tempLogbookEntries = [NSMutableArray arrayWithArray:objects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"logDate" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedLogbookEntries = [tempLogbookEntries sortedArrayUsingDescriptors:sortDescriptors];
        NSMutableArray *logbooksFiltered = [[NSMutableArray alloc] init];
        NSInteger landingNightCount = 0;
        for (LogEntry *logToCheck in sortedLogbookEntries) {
//            BOOL isExit = NO;
//            for (LogEntry *logLandingDayToCheck in logbooksFiltered) {
//                if ([logLandingDayToCheck.landingsNight integerValue] == [logToCheck.landingsNight integerValue]) {
//                    isExit = YES;
//                    break;
//                }
//            }
//            if (!isExit) {
                [logbooksFiltered addObject:logToCheck];
                landingNightCount +=[logToCheck.landingsNight integerValue];
                if (landingNightCount >= 3) {
                    break;
                }
           // }
        }
        if (logbooksFiltered.count > 0 && landingNightCount>=3) {
//            NSMutableArray *tempLogbookEntriesForLandingNight = [NSMutableArray arrayWithArray:logbooksFiltered];
//            NSSortDescriptor *sortDescriptorForLandingNight = [[NSSortDescriptor alloc] initWithKey:@"landingsNight" ascending:NO];
//            NSArray *sortDescriptorsForLandingNight = [NSArray arrayWithObject:sortDescriptorForLandingNight];
//            NSArray *sortedLogbookEntriesForLandingNight = [tempLogbookEntriesForLandingNight sortedArrayUsingDescriptors:sortDescriptorsForLandingNight];
            latestNightLandingLogEntry = logbooksFiltered[0];
            latestLandingNight = latestNightLandingLogEntry.logDate;
        }
    }
    request = [[NSFetchRequest alloc] init];
    predicate = [NSPredicate predicateWithFormat:@"approachesCount != 0 AND picTime != 0 "];
    [request setPredicate:predicate];
    [request setEntity:entityDesc];
    objects = [contextLog executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"Unable to retrieve lessons!");
    } else if (objects.count == 0) {
        NSLog(@"No valid lesson groups found!");
    } else {
        NSLog(@"%lu lesson groups found", (unsigned long)[objects count]);
        NSMutableArray *tempLogbookEntries = [NSMutableArray arrayWithArray:objects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"logDate" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedLogbookEntries = [tempLogbookEntries sortedArrayUsingDescriptors:sortDescriptors];
        NSMutableArray *logbooksFiltered = [[NSMutableArray alloc] init];
        NSInteger approachCount = 0;
        for (LogEntry *logToCheck in sortedLogbookEntries) {
                [logbooksFiltered addObject:logToCheck];
                approachCount += [logToCheck.approachesCount integerValue];
                if (approachCount >= 6) {
                    break;
                }
        }
        if (logbooksFiltered.count > 0 && approachCount>=6) {
            oldestApproachLogEntry = logbooksFiltered[logbooksFiltered.count-1];
            oldestApproachDate = oldestApproachLogEntry.logDate;
        }
    }
    request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    objects = [contextLog executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"Unable to retrieve lessons!");
    } else if (objects.count == 0) {
        NSLog(@"No valid lesson groups found!");
    } else {
        NSLog(@"%lu lesson groups found", (unsigned long)[objects count]);
        NSMutableArray *tempLogbookEntries = [NSMutableArray arrayWithArray:objects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"logDate" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedLogbookEntries = [tempLogbookEntries sortedArrayUsingDescriptors:sortDescriptors];
        
        for (LogEntry *logEntryToCheck in sortedLogbookEntries) {
            if (logEntryToCheck.endorsements.count > 0) {
                for (Endorsement *endorsementToCheck in logEntryToCheck.endorsements) {
                    if ([endorsementToCheck.name isEqualToString:@"Completion of a flight review: § 61.56(a) and 61.56(c)."]) {
                        NSString *flightReviewDateStr = endorsementToCheck.endorsementDate;
                        if (![flightReviewDateStr isEqualToString:@""]) {
                            latestLandingFlightReview = [format dateFromString:flightReviewDateStr];
                            break;
                        }
                    }
                }
            }
        }
    }
    if (latestLandingFlightReview == nil) {
        entityDesc = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:contextLog];
        request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        predicate = [NSPredicate predicateWithFormat:@"type == 2"];
        [request setPredicate:predicate];
        NSArray *endorsementObjects = [contextLog executeFetchRequest:request error:&error];
        if (endorsementObjects == nil) {
            FDLogError(@"Unable to retrieve Endorsements!");
        } else if (endorsementObjects.count == 0) {
            FDLogDebug(@"No valid Endorsements found!");
        } else {
            for (Endorsement *endorsement in endorsementObjects) {
                if ([endorsement.name isEqualToString:@"Completion of a flight review: § 61.56(a) and 61.56(c)."]) {
                    NSString *flightReviewDateStr = endorsement.endorsementDate;
                    if (![flightReviewDateStr isEqualToString:@""]) {
                        latestLandingFlightReview = [format dateFromString:flightReviewDateStr];
                    }
                }
            }
        }
    }
    
    
    CGFloat leftPadding = 120;
    CGFloat graphSpacing = 130;
    CGFloat y = 0;
    // the objectives view size is based on the objective text
    dashboardView = [[UIView alloc] initWithFrame:CGRectMake(25, 50, [UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.height-100)];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, dashboardView.frame.size.width, 50.0f)];
    titleLbl.font = [UIFont fontWithName:@"Helvetica" size:30];
    titleLbl.text = @"CURRENCY";
    titleLbl.textColor = [UIColor whiteColor];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    [dashboardView addSubview:titleLbl];
    y += 50.0f;
    
    UIView *colorLineViewGreen = [[UIView alloc] initWithFrame:CGRectMake(leftPadding, y + graphSpacing, dashboardView.frame.size.width-150, 10)];
    colorLineViewGreen.backgroundColor = CURRENCY_GREEN_COLOR;
    
    UIView *colorLineViewYellow = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreen.frame.size.width/2, 0, colorLineViewGreen.frame.size.width/2, 10)];
    colorLineViewYellow.backgroundColor = CURRENCY_YELLOW_COLOR;
    [colorLineViewGreen addSubview:colorLineViewYellow];
    
    UIView *colorLineViewRed = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewYellow.frame.size.width/2, 0, colorLineViewYellow.frame.size.width/2, 10)];
    colorLineViewRed.backgroundColor = CURRENCY_RED_COLOR;
    [colorLineViewYellow addSubview:colorLineViewRed];
    
    UILabel *noPaxFirst = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewRed.frame.size.width, 10)];
    noPaxFirst.textAlignment = NSTextAlignmentCenter;
    noPaxFirst.text = @"* NO PAX *";
    noPaxFirst.font = [UIFont fontWithName:@"Helvetica" size:13];
    noPaxFirst.textColor = [UIColor whiteColor];
    [colorLineViewRed addSubview:noPaxFirst];
    
    UIView *firstLineDay = [[UIView alloc] initWithFrame:CGRectMake(leftPadding+2, y + graphSpacing - 50, 1, 60)];
    firstLineDay.backgroundColor = [UIColor whiteColor];
    UIView *secondLineDay = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    secondLineDay.backgroundColor = [UIColor whiteColor];
    
    UILabel *dayLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y + graphSpacing - 4, leftPadding-10, 14)];
    dayLbl.textAlignment = NSTextAlignmentRight;
    dayLbl.text = @"DAY";
    dayLbl.font = [UIFont fontWithName:@"Helvetica" size:15];
    dayLbl.textColor = [UIColor whiteColor];
    
    UILabel *latestDayLanding = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding-100, y + graphSpacing - 100, 200, 50)];
    latestDayLanding.textAlignment = NSTextAlignmentCenter;
    if (latestLandingDay != nil) {
        strDay = [format stringFromDate:latestLandingDay];
        latestDayLanding.text = [NSString stringWithFormat:@"Latest 3rd DAY Landing\n%@",strDay];
    }else{
        latestDayLanding.text = @"Latest 3rd DAY Landing\nMM/dd/yyyy";
    }
    latestDayLanding.font = [UIFont fontWithName:@"Helvetica" size:15];
    latestDayLanding.textColor = [UIColor whiteColor];
    latestDayLanding.numberOfLines = 0;
    
    UILabel *dayAfter90Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/4 -50 , y + graphSpacing - 100, 100, 50)];
    dayAfter90Days.textAlignment = NSTextAlignmentCenter;
    if (latestLandingDay != nil) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *daysAfter90 = [cal dateByAddingUnit:NSCalendarUnitDay
                                              value:90
                                             toDate:latestLandingDay
                                            options:0];
        strDay = [format stringFromDate:daysAfter90];
        dayAfter90Days.text = [NSString stringWithFormat:@"90 Days\n%@",strDay];
    }else{
        dayAfter90Days.text = @"90 Days\nMM/dd/yyyy";
    }
    dayAfter90Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    dayAfter90Days.textColor = [UIColor whiteColor];
    dayAfter90Days.numberOfLines = 0;
    
    CGRect todayRect = CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding - 50, y + graphSpacing-50, 100, 55);
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:latestLandingDay
                                                          toDate:[NSDate date]
                                                         options:0];
    
    NSInteger daysDif = [components day];
    if (latestLandingDay == nil ){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150);
    }else if ([components day] > 90){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150)*3/4 + (dashboardView.frame.size.width-150)/4 *(daysDif-90)/180;
    }else if ([components day] <=80) {
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * daysDif / 160;
    }else if ([components day] > 80 && [components day] <=90){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150)/2 + (dashboardView.frame.size.width-150) * (daysDif-80)/40;
    }
    
    UIView *todayViewForDay = [[UIView alloc] initWithFrame:todayRect];
    
    UILabel *todayLblForDay = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    todayLblForDay.textAlignment = NSTextAlignmentCenter;
    todayLblForDay.text = [NSString stringWithFormat:@"Today\n%@",[format stringFromDate:[NSDate date]]];
    todayLblForDay.font = [UIFont fontWithName:@"Helvetica" size:13];
    todayLblForDay.textColor = [UIColor whiteColor];
    todayLblForDay.numberOfLines = 0;
    
    UIImageView *pointTodayForDayImgView = [[UIImageView alloc] initWithFrame:CGRectMake(37, 30, 26, 25)];
    [pointTodayForDayImgView setImage:[UIImage imageNamed:@"currency_today_point.png"]];
    
    //    UIImageView *dottedLine = [[UIImageView alloc] initWithFrame:CGRectMake(49, 75, 1, 105)];
    //    UIBezierPath * path = [[UIBezierPath alloc] init];
    //    [path moveToPoint:CGPointMake(0, 0)];
    //    [path addLineToPoint:CGPointMake(0, dottedLine.frame.size.height)];
    //    [path setLineWidth:3.0];
    //    CGFloat dashes[] = { path.lineWidth, path.lineWidth * 2 };
    //    [path setLineDash:dashes count:2 phase:0];
    //    [path setLineCapStyle:kCGLineCapRound];
    //    UIGraphicsBeginImageContextWithOptions(CGSizeMake(dottedLine.frame.size.width, dottedLine.frame.size.height), false, 1);
    //    [[UIColor whiteColor] setStroke];
    //    [path stroke];
    //    UIImage * dottedImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    //    [dottedLine setImage:dottedImage];
    
    [todayViewForDay addSubview:todayLblForDay];
    [todayViewForDay addSubview:pointTodayForDayImgView];
    
    [dashboardView addSubview:colorLineViewGreen];
    [dashboardView addSubview:firstLineDay];
    [dashboardView addSubview:secondLineDay];
    [dashboardView addSubview:dayLbl];
    [dashboardView addSubview:latestDayLanding];
    [dashboardView addSubview:dayAfter90Days];
    [dashboardView addSubview:todayViewForDay];
    y+=graphSpacing+10;
    
    UIView *colorLineViewGreenSecond = [[UIView alloc] initWithFrame:CGRectMake(leftPadding, y + graphSpacing, dashboardView.frame.size.width-150, 10)];
    colorLineViewGreenSecond.backgroundColor = CURRENCY_GREEN_COLOR;
    
    UIView *colorLineViewYellowSecond = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenSecond.frame.size.width/2, 0, colorLineViewGreenSecond.frame.size.width/2, 10)];
    colorLineViewYellowSecond.backgroundColor = CURRENCY_YELLOW_COLOR;
    [colorLineViewGreenSecond addSubview:colorLineViewYellowSecond];
    
    UIView *colorLineViewRedSecond = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewYellowSecond.frame.size.width/2, 0, colorLineViewYellowSecond.frame.size.width/2, 10)];
    colorLineViewRedSecond.backgroundColor = CURRENCY_RED_COLOR;
    [colorLineViewYellowSecond addSubview:colorLineViewRedSecond];
    
    UILabel *noPaxSecond = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewRed.frame.size.width, 10)];
    noPaxSecond.textAlignment = NSTextAlignmentCenter;
    noPaxSecond.text = @"* NO PAX *";
    noPaxSecond.font = [UIFont fontWithName:@"Helvetica" size:13];
    noPaxSecond.textColor = [UIColor whiteColor];
    [colorLineViewRedSecond addSubview:noPaxSecond];
    
    UIView *firstLineNight = [[UIView alloc] initWithFrame:CGRectMake(leftPadding+2, y + graphSpacing - 50, 1, 60)];
    firstLineNight.backgroundColor = [UIColor whiteColor];
    UIView *secondLineNight = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    secondLineNight.backgroundColor = [UIColor whiteColor];
    
    UILabel *nightLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y + graphSpacing - 4, leftPadding-10, 14)];
    nightLbl.textAlignment = NSTextAlignmentRight;
    nightLbl.text = @"NIGHT";
    nightLbl.font = [UIFont fontWithName:@"Helvetica" size:15];
    nightLbl.textColor = [UIColor whiteColor];
    
    UILabel *latestNightLanding = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding-100, y + graphSpacing - 100, 200, 50)];
    latestNightLanding.textAlignment = NSTextAlignmentCenter;
    if (latestLandingNight != nil) {
        strDay = [format stringFromDate:latestLandingNight];
        latestNightLanding.text = [NSString stringWithFormat:@"Latest 3rd NIGHT Landing\n%@",strDay];
    }else{
        latestNightLanding.text = @"Latest 3rd NIGHT Landing\nMM/dd/yyyy";
    }
    latestNightLanding.font = [UIFont fontWithName:@"Helvetica" size:15];
    latestNightLanding.textColor = [UIColor whiteColor];
    latestNightLanding.numberOfLines = 0;
    
    UILabel *nightAfter90Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/4 -50 , y + graphSpacing - 100, 100, 50)];
    nightAfter90Days.textAlignment = NSTextAlignmentCenter;
    if (latestLandingNight != nil) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *daysAfter90 = [cal dateByAddingUnit:NSCalendarUnitDay
                                              value:90
                                             toDate:latestLandingNight
                                            options:0];
        strDay = [format stringFromDate:daysAfter90];
        nightAfter90Days.text = [NSString stringWithFormat:@"90 Days\n%@",strDay];
    }else{
        nightAfter90Days.text = @"90 Days\nMM/dd/yyyy";
    }
    nightAfter90Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    nightAfter90Days.textColor = [UIColor whiteColor];
    nightAfter90Days.numberOfLines = 0;
    
    
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    components = [gregorianCalendar components:NSCalendarUnitDay
                                      fromDate:latestLandingNight
                                        toDate:[NSDate date]
                                       options:0];
    
    daysDif = [components day];
    if (latestLandingNight == nil ){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150);
    }else if ([components day] > 90){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150)*3/4 + (dashboardView.frame.size.width-150)/4 *(daysDif-90)/180;
    }else if ([components day] <=80) {
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * daysDif / 160;
    }else if ([components day] > 80 && [components day] <=90){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150)/2 + (dashboardView.frame.size.width-150) * (daysDif-80)/40;
    }
    todayRect.origin.y = y + graphSpacing-50;
    UIView *todayViewForNight = [[UIView alloc] initWithFrame:todayRect];
    
    UILabel *todayLblForNight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    todayLblForNight.textAlignment = NSTextAlignmentCenter;
    todayLblForNight.text = [NSString stringWithFormat:@"Today\n%@",[format stringFromDate:[NSDate date]]];
    todayLblForNight.font = [UIFont fontWithName:@"Helvetica" size:13];
    todayLblForNight.textColor = [UIColor whiteColor];
    todayLblForNight.numberOfLines = 0;
    
    UIImageView *pointTodayForNightImgView = [[UIImageView alloc] initWithFrame:CGRectMake(37, 30, 26, 25)];
    [pointTodayForNightImgView setImage:[UIImage imageNamed:@"currency_today_point.png"]];
    
    [todayViewForNight addSubview:todayLblForNight];
    [todayViewForNight addSubview:pointTodayForNightImgView];
    
    [dashboardView addSubview:colorLineViewGreenSecond];
    [dashboardView addSubview:firstLineNight];
    [dashboardView addSubview:secondLineNight];
    [dashboardView addSubview:nightLbl];
    [dashboardView addSubview:latestNightLanding];
    [dashboardView addSubview:nightAfter90Days];
    [dashboardView addSubview:todayViewForNight];
    y+=graphSpacing+10;
    
    UIView *colorLineViewGreenThird = [[UIView alloc] initWithFrame:CGRectMake(120, y + graphSpacing, dashboardView.frame.size.width-150, 10)];
    colorLineViewGreenThird.backgroundColor = CURRENCY_GREEN_COLOR;
    
    UIView *colorLineViewYellowThird = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenThird.frame.size.width*5/8, 0, colorLineViewGreenThird.frame.size.width/8, 10)];
    colorLineViewYellowThird.backgroundColor = CURRENCY_YELLOW_COLOR;
    [colorLineViewGreenThird addSubview:colorLineViewYellowThird];
    
    
    UIView *colorLineViewRedThird = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenThird.frame.size.width*3/4, 0, colorLineViewGreenThird.frame.size.width/4, 10)];
    colorLineViewRedThird.backgroundColor = CURRENCY_RED_COLOR;
    [colorLineViewGreenThird addSubview:colorLineViewRedThird];
    
    UILabel *noPaxThird = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewRedThird.frame.size.width, 10)];
    noPaxThird.textAlignment = NSTextAlignmentCenter;
    noPaxThird.text = @"* NO FLIGHT *";
    noPaxThird.font = [UIFont fontWithName:@"Helvetica" size:13];
    noPaxThird.textColor = [UIColor whiteColor];
    [colorLineViewRedThird addSubview:noPaxThird];
    
    UIView *firstLineFlightReview = [[UIView alloc] initWithFrame:CGRectMake(leftPadding+2, y + graphSpacing - 50, 1, 60)];
    firstLineFlightReview.backgroundColor = [UIColor whiteColor];
    UIView *secondLineFlightReview = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    secondLineFlightReview.backgroundColor = [UIColor whiteColor];
    
    UILabel *flightReviewLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y + graphSpacing - 4, leftPadding-5, 14)];
    flightReviewLbl.textAlignment = NSTextAlignmentRight;
    flightReviewLbl.text = @"FLIGHT REVIEW";
    flightReviewLbl.font = [UIFont fontWithName:@"Helvetica" size:14];
    flightReviewLbl.textColor = [UIColor whiteColor];
    
    UILabel *latestFlightReviewLanding = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding-100, y + graphSpacing - 100, 200, 50)];
    latestFlightReviewLanding.textAlignment = NSTextAlignmentCenter;
    if (latestLandingFlightReview != nil) {
        strDay = [format stringFromDate:latestLandingFlightReview];
        latestFlightReviewLanding.text = [NSString stringWithFormat:@"Done Last\n%@",strDay];
    }else{
        latestFlightReviewLanding.text = @"Done Last\nMM/dd/yyyy";
    }
    latestFlightReviewLanding.font = [UIFont fontWithName:@"Helvetica" size:15];
    latestFlightReviewLanding.textColor = [UIColor whiteColor];
    latestFlightReviewLanding.numberOfLines = 0;
    
    UILabel *flightReviewAfter720Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/4 -50 , y + graphSpacing - 100, 100, 50)];
    flightReviewAfter720Days.textAlignment = NSTextAlignmentCenter;
    if (latestLandingFlightReview != nil) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *daysAfter720 = [cal dateByAddingUnit:NSCalendarUnitDay
                                              value:720
                                             toDate:latestLandingFlightReview
                                            options:0];
        strDay = [format stringFromDate:daysAfter720];
        flightReviewAfter720Days.text = [NSString stringWithFormat:@"Due Next\n%@",strDay];
    }else{
        flightReviewAfter720Days.text = @"Due Next\nMM/dd/yyyy";
    }
    flightReviewAfter720Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    flightReviewAfter720Days.textColor = [UIColor whiteColor];
    flightReviewAfter720Days.numberOfLines = 0;
    
    
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    components = [gregorianCalendar components:NSCalendarUnitDay
                                      fromDate:latestLandingFlightReview
                                        toDate:[NSDate date]
                                       options:0];
    
    daysDif = [components day];
    if (latestLandingFlightReview == nil || [components day] >720){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/4;
    }else if ([components day] <=710) {
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 5/8 * daysDif / 710;
    }else if ([components day] > 710 && [components day] <=720){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 5/8 + (dashboardView.frame.size.width-150)/8* (daysDif-710)/10;
    }
    todayRect.origin.y = y + graphSpacing-50;
    UIView *todayViewForFlightReivew = [[UIView alloc] initWithFrame:todayRect];
    
    UILabel *todayLblForFlgihtReview = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    todayLblForFlgihtReview.textAlignment = NSTextAlignmentCenter;
    todayLblForFlgihtReview.text = [NSString stringWithFormat:@"Today\n%@",[format stringFromDate:[NSDate date]]];
    todayLblForFlgihtReview.font = [UIFont fontWithName:@"Helvetica" size:13];
    todayLblForFlgihtReview.textColor = [UIColor whiteColor];
    todayLblForFlgihtReview.numberOfLines = 0;
    
    UIImageView *pointTodayForFlgihtReviewImgView = [[UIImageView alloc] initWithFrame:CGRectMake(37, 30, 26, 25)];
    [pointTodayForFlgihtReviewImgView setImage:[UIImage imageNamed:@"currency_today_point.png"]];
    
    [todayViewForFlightReivew addSubview:todayLblForFlgihtReview];
    [todayViewForFlightReivew addSubview:pointTodayForFlgihtReviewImgView];
    
    
    [dashboardView addSubview:colorLineViewGreenThird];
    [dashboardView addSubview:firstLineFlightReview];
    [dashboardView addSubview:secondLineFlightReview];
    [dashboardView addSubview:flightReviewLbl];
    [dashboardView addSubview:latestFlightReviewLanding];
    [dashboardView addSubview:flightReviewAfter720Days];
    [dashboardView addSubview:todayViewForFlightReivew];
    y+=graphSpacing+10;
    
    UIView *colorLineViewGreenMedical = [[UIView alloc] initWithFrame:CGRectMake(120, y + graphSpacing, dashboardView.frame.size.width-150, 10)];
    colorLineViewGreenMedical.backgroundColor = CURRENCY_GREEN_COLOR;
    
    UIView *colorLineViewYellowMedical = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenMedical.frame.size.width*5/8, 0, colorLineViewGreenMedical.frame.size.width/8, 10)];
    colorLineViewYellowMedical.backgroundColor = CURRENCY_YELLOW_COLOR;
    [colorLineViewGreenMedical addSubview:colorLineViewYellowMedical];
    
    
    UIView *colorLineViewRedMedical = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenMedical.frame.size.width*3/4, 0, colorLineViewGreenMedical.frame.size.width/4, 10)];
    colorLineViewRedMedical.backgroundColor = CURRENCY_RED_COLOR;
    [colorLineViewGreenMedical addSubview:colorLineViewRedMedical];
    
    UILabel *noFlightMedical = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewRedMedical.frame.size.width, 10)];
    noFlightMedical.textAlignment = NSTextAlignmentCenter;
    noFlightMedical.text = @"* NO FLIGHT *";
    noFlightMedical.font = [UIFont fontWithName:@"Helvetica" size:13];
    noFlightMedical.textColor = [UIColor whiteColor];
    [colorLineViewRedMedical addSubview:noFlightMedical];
    
    UIView *firstLineMedicalReview = [[UIView alloc] initWithFrame:CGRectMake(leftPadding+2, y + graphSpacing - 50, 1, 60)];
    firstLineMedicalReview.backgroundColor = [UIColor whiteColor];
    UIView *secondLineMedicalReview = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    secondLineMedicalReview.backgroundColor = [UIColor whiteColor];
    
    UILabel *medicalLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y + graphSpacing - 4, leftPadding-5, 14)];
    medicalLbl.textAlignment = NSTextAlignmentRight;
    medicalLbl.text = @"MEDICAL";
    medicalLbl.font = [UIFont fontWithName:@"Helvetica" size:14];
    medicalLbl.textColor = [UIColor whiteColor];
    
    UILabel *latestMedicalLanding = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding-100, y + graphSpacing - 100, 200, 50)];
    latestMedicalLanding.textAlignment = NSTextAlignmentCenter;
    if ([AppDelegate sharedDelegate].medicalCertIssueDate != nil && ![[AppDelegate sharedDelegate].medicalCertIssueDate isEqualToString:@""]) {
        latestMedicalLanding.text = [NSString stringWithFormat:@"Issued\n%@",[AppDelegate sharedDelegate].medicalCertIssueDate];
    }else{
        latestMedicalLanding.text = @"Issued\nMM/dd/yyyy";
    }
    latestMedicalLanding.font = [UIFont fontWithName:@"Helvetica" size:15];
    latestMedicalLanding.textColor = [UIColor whiteColor];
    latestMedicalLanding.numberOfLines = 0;
    
    UILabel *medicalAfter720Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/4 -50 , y + graphSpacing - 100, 100, 50)];
    medicalAfter720Days.textAlignment = NSTextAlignmentCenter;
    if ([AppDelegate sharedDelegate].medicalCertExpDate != nil && ![[AppDelegate sharedDelegate].medicalCertExpDate isEqualToString:@""]) {
        medicalAfter720Days.text = [NSString stringWithFormat:@"Expires\n%@",[AppDelegate sharedDelegate].medicalCertExpDate];
    }else{
        medicalAfter720Days.text = @"Expires\nMM/dd/yyyy";
    }
    medicalAfter720Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    medicalAfter720Days.textColor = [UIColor whiteColor];
    medicalAfter720Days.numberOfLines = 0;
    
    if ([AppDelegate sharedDelegate].medicalCertIssueDate != nil && ![[AppDelegate sharedDelegate].medicalCertIssueDate isEqualToString:@""] && [AppDelegate sharedDelegate].medicalCertExpDate != nil && ![[AppDelegate sharedDelegate].medicalCertExpDate  isEqualToString:@""]) {
        NSInteger daysBetweenMedicIssueAndExp = 0;
        NSDate *medicalCertIssueDate = [format dateFromString:[AppDelegate sharedDelegate].medicalCertIssueDate];
        NSDate *medicalCertExpDate = [format dateFromString:[AppDelegate sharedDelegate].medicalCertExpDate];
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:medicalCertIssueDate
                                            toDate:medicalCertExpDate
                                           options:0];
        daysBetweenMedicIssueAndExp = [components day];
        
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:medicalCertIssueDate
                                            toDate:[NSDate date]
                                           options:0];
        daysDif = [components day];
        if (daysDif >= daysBetweenMedicIssueAndExp) {
            todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/4;
        }else if ([components day] <=daysBetweenMedicIssueAndExp-10) {
            todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 5/8 * daysDif / (daysBetweenMedicIssueAndExp-10);
        }else if ([components day] > (daysBetweenMedicIssueAndExp-10) && [components day] <=daysBetweenMedicIssueAndExp){
            todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 5/8 + (dashboardView.frame.size.width-150)/8* (daysDif-daysBetweenMedicIssueAndExp+10)/10;
        }
    }else{
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/4;
    }
    
    todayRect.origin.y = y + graphSpacing-50;
    UIView *todayViewForMedical = [[UIView alloc] initWithFrame:todayRect];
    
    UILabel *todayLblForMedical = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    todayLblForMedical.textAlignment = NSTextAlignmentCenter;
    todayLblForMedical.text = [NSString stringWithFormat:@"Today\n%@",[format stringFromDate:[NSDate date]]];
    todayLblForMedical.font = [UIFont fontWithName:@"Helvetica" size:13];
    todayLblForMedical.textColor = [UIColor whiteColor];
    todayLblForMedical.numberOfLines = 0;
    
    UIImageView *pointTodayForMedicalImgView = [[UIImageView alloc] initWithFrame:CGRectMake(37, 30, 26, 25)];
    [pointTodayForMedicalImgView setImage:[UIImage imageNamed:@"currency_today_point.png"]];
    
    [todayViewForMedical addSubview:todayLblForMedical];
    [todayViewForMedical addSubview:pointTodayForMedicalImgView];
    
    
    [dashboardView addSubview:colorLineViewGreenMedical];
    [dashboardView addSubview:firstLineMedicalReview];
    [dashboardView addSubview:secondLineMedicalReview];
    [dashboardView addSubview:medicalLbl];
    [dashboardView addSubview:latestMedicalLanding];
    [dashboardView addSubview:medicalAfter720Days];
    [dashboardView addSubview:todayViewForMedical];
    y+=graphSpacing+10;
    
    UIView *colorLineViewGreenApproach = [[UIView alloc] initWithFrame:CGRectMake(120, y + graphSpacing, dashboardView.frame.size.width-150, 10)];
    colorLineViewGreenApproach.backgroundColor = CURRENCY_GREEN_COLOR;
    
    UIView *colorLineViewYellowApproach = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenApproach.frame.size.width*3/8, 0, colorLineViewGreenApproach.frame.size.width*3/8, 10)];
    colorLineViewYellowApproach.backgroundColor = CURRENCY_YELLOW_COLOR;
    [colorLineViewGreenApproach addSubview:colorLineViewYellowApproach];
    
    UILabel *noPaxApproach = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewYellowApproach.frame.size.width, 10)];
    noPaxApproach.textAlignment = NSTextAlignmentCenter;
    noPaxApproach.text = @"* NO IFR PAX *";
    noPaxApproach.font = [UIFont fontWithName:@"Helvetica" size:13];
    noPaxApproach.textColor = [UIColor whiteColor];
    [colorLineViewYellowApproach addSubview:noPaxApproach];
    
    UIView *colorLineViewRedApproach = [[UIView alloc] initWithFrame:CGRectMake(colorLineViewGreenApproach.frame.size.width*3/4, 0, colorLineViewGreenApproach.frame.size.width/4, 10)];
    colorLineViewRedApproach.backgroundColor = CURRENCY_RED_COLOR;
    [colorLineViewGreenApproach addSubview:colorLineViewRedApproach];
    
    UILabel *noFlightApproach = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, colorLineViewRedApproach.frame.size.width, 10)];
    noFlightApproach.textAlignment = NSTextAlignmentCenter;
    noFlightApproach.text = @"* NO IFR FLIGHT *";
    noFlightApproach.font = [UIFont fontWithName:@"Helvetica" size:13];
    noFlightApproach.textColor = [UIColor whiteColor];
    [colorLineViewRedApproach addSubview:noFlightApproach];
    
    UIView *firstLineApproach = [[UIView alloc] initWithFrame:CGRectMake(leftPadding+2, y + graphSpacing - 50, 1, 60)];
    firstLineApproach.backgroundColor = [UIColor whiteColor];
    UIView *secondLineApproach = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/8 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    secondLineApproach.backgroundColor = [UIColor whiteColor];
    UIView *thirdLineApproach = [[UIView alloc] initWithFrame:CGRectMake((dashboardView.frame.size.width-150)*3/4 + leftPadding+2, y + graphSpacing - 50, 1, 60)];
    thirdLineApproach.backgroundColor = [UIColor whiteColor];
    
    UILabel *approachLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y + graphSpacing - 4, leftPadding-5, 14)];
    approachLbl.textAlignment = NSTextAlignmentRight;
    approachLbl.text = @"APPROACHES";
    approachLbl.font = [UIFont fontWithName:@"Helvetica" size:14];
    approachLbl.textColor = [UIColor whiteColor];
    
    UILabel *latestApproachLanding = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding-100, y + graphSpacing - 100, 200, 50)];
    latestApproachLanding.textAlignment = NSTextAlignmentCenter;
    if (oldestApproachDate != nil) {
        strDay = [format stringFromDate:oldestApproachDate];
        latestApproachLanding.text = [NSString stringWithFormat:@"6th Oldest Approach\n%@",strDay];
    }else{
        latestApproachLanding.text = @"6th Oldest Approach\nMM/dd/yyyy";
    }
    latestApproachLanding.font = [UIFont fontWithName:@"Helvetica" size:15];
    latestApproachLanding.textColor = [UIColor whiteColor];
    latestApproachLanding.numberOfLines = 0;
    
    NSInteger preDaysForApproach = 0;
    NSInteger oldDaysForApproach = 0;
    NSInteger lastDaysForApproach = 0;
    
    UILabel *approachAfterFirst80Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/8 -50 , y + graphSpacing - 100, 100, 50)];
    approachAfterFirst80Days.textAlignment = NSTextAlignmentCenter;
    if (oldestApproachDate != nil) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *daysAfter80 = [cal dateByAddingUnit:NSCalendarUnitMonth
                                               value:6
                                              toDate:oldestApproachDate
                                             options:0];
        strDay = [format stringFromDate:daysAfter80];
        approachAfterFirst80Days.text = [NSString stringWithFormat:@"Due Next\n%@",strDay];
        
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:oldestApproachDate
                                            toDate:daysAfter80
                                           options:0];
        preDaysForApproach = [components day];
    }else{
        approachAfterFirst80Days.text = @"Due Next\nMM/dd/yyyy";
    }
    approachAfterFirst80Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    approachAfterFirst80Days.textColor = [UIColor whiteColor];
    approachAfterFirst80Days.numberOfLines = 0;
    
    UILabel *approachAfter10Days = [[UILabel alloc] initWithFrame:CGRectMake(leftPadding + (dashboardView.frame.size.width-150)*3/4 -50 , y + graphSpacing - 100, 100, 50)];
    approachAfter10Days.textAlignment = NSTextAlignmentCenter;
    if (oldestApproachDate != nil) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *daysAfter10 = [cal dateByAddingUnit:NSCalendarUnitMonth
                                               value:12
                                              toDate:oldestApproachDate
                                             options:0];
        strDay = [format stringFromDate:daysAfter10];
        approachAfter10Days.text = [NSString stringWithFormat:@"Due Next\n%@",strDay];
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:oldestApproachDate
                                            toDate:daysAfter10
                                           options:0];
        oldDaysForApproach = [components day];
        // calculate last days for 12 months
        NSDate * dateAfter12 = [cal dateByAddingUnit:NSCalendarUnitMonth
                                      value:24
                                     toDate:oldestApproachDate
                                    options:0];
        
        gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        components = [gregorianCalendar components:NSCalendarUnitDay
                                          fromDate:oldestApproachDate
                                            toDate:dateAfter12
                                           options:0];
        lastDaysForApproach = [components day];
    }else{
        approachAfter10Days.text = @"Due Next\nMM/dd/yyyy";
    }
    approachAfter10Days.font = [UIFont fontWithName:@"Helvetica" size:15];
    approachAfter10Days.textColor = [UIColor whiteColor];
    approachAfter10Days.numberOfLines = 0;
    
    
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    components = [gregorianCalendar components:NSCalendarUnitDay
                                      fromDate:oldestApproachDate
                                        toDate:[NSDate date]
                                       options:0];
    
    daysDif = [components day];
    if (oldestApproachDate == nil && [components day] >= lastDaysForApproach){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150);
    }else if ([components day] <=preDaysForApproach) {
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/8 * daysDif / preDaysForApproach;
    }else if ([components day] > preDaysForApproach && [components day] <=oldDaysForApproach){
        todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/8 + (dashboardView.frame.size.width-150) * 3/8* (daysDif-preDaysForApproach)/(oldDaysForApproach - preDaysForApproach);
    }else if ([components day] > oldDaysForApproach && [components day] <=lastDaysForApproach){
       todayRect.origin.x = leftPadding - 50 + (dashboardView.frame.size.width-150) * 3/4 + (dashboardView.frame.size.width-150)/4 * (daysDif-oldDaysForApproach)/(lastDaysForApproach - oldDaysForApproach);
    }
    todayRect.origin.y = y + graphSpacing-50;
    UIView *todayViewForApproach = [[UIView alloc] initWithFrame:todayRect];
    
    UILabel *todayLblForApproach = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    todayLblForApproach.textAlignment = NSTextAlignmentCenter;
    todayLblForApproach.text = [NSString stringWithFormat:@"Today\n%@",[format stringFromDate:[NSDate date]]];
    todayLblForApproach.font = [UIFont fontWithName:@"Helvetica" size:13];
    todayLblForApproach.textColor = [UIColor whiteColor];
    todayLblForApproach.numberOfLines = 0;
    
    UIImageView *pointTodayForApproachImgView = [[UIImageView alloc] initWithFrame:CGRectMake(37, 30, 26, 25)];
    [pointTodayForApproachImgView setImage:[UIImage imageNamed:@"currency_today_point.png"]];
    
    [todayViewForApproach addSubview:todayLblForApproach];
    [todayViewForApproach addSubview:pointTodayForApproachImgView];
    
    
    [dashboardView addSubview:colorLineViewGreenApproach];
    [dashboardView addSubview:firstLineApproach];
    [dashboardView addSubview:secondLineApproach];
    [dashboardView addSubview:thirdLineApproach];
    [dashboardView addSubview:approachLbl];
    [dashboardView addSubview:latestApproachLanding];
    [dashboardView addSubview:approachAfterFirst80Days];
    [dashboardView addSubview:approachAfter10Days];
    [dashboardView addSubview:todayViewForApproach];
    y+=graphSpacing+10;
    
    [self addSubview:dashboardView];
}
@end
