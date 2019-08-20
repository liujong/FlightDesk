//
//  LogbookRecordView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 4/11/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

//#import "M13Checkbox.h"
#import "FlightDesk-Swift.h"
#import "LogbookRecordView.h"
#import "LogEntry+CoreDataClass.h"
#import "LessonRecord.h"
#import "EndorsementViewController.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "LogEndorsementCell.h"
#import "Endorsement+CoreDataClass.h"

@implementation LogbookRecordView
{
    LogEntry *currentLogEntry;
    NSNumber *currentInstructorID;
    NSNumber *currentUserID;
    NSNumberFormatter *numberFormatter;
    // Primary fields
    UIButton    *logDate;
    UITextField *aircraftModel;
    UITextField *aircraftRegistration;
    UITextField *hobbsOut;
    UITextField *hobbsIn;
    UITextField *totalFlightTime;
    UIButton    *aircraftCategoryBtn;
    UIButton    *aircraftClassBtn;
    
    UITextField *flightRoute;
    UITextField *landingsDay;
    UITextField *landingsNight;
    
    // experience (conditions)
    UITextField *nightTime;
    UITextField *picTime;
    UITextField *sicTime;
    UITextField *soloTime;
    UITextField *xcDayTime;
    UITextField *xcSolo;
    UITextField *xcPIC;
    UITextField *xcNightTime;
    
    // experience (aircraft) [REPLACED WITH CHECKBOXES]
    UITextField *recreationalTime;
    UITextField *sportTime;
    UITextField *highPerfTime;
    UITextField *complexTime;
    UITextField *taildraggerTime;
    UITextField *gliderTime;
    UITextField *ultraLightTime;
    UITextField *helicopterTime;
    UITextField *turbopropTime;
    UITextField *jetTime;
    
    // Training
    UITextField *groundTime;
    UITextField *dualReceived;
    UITextField *nightDualReceived;
    UITextField *xcDualReceived;
    UITextField *xcNightDualReceived;
    
    // Instrument fields
    UITextField *instrumentActual;
    UITextField *instrumentHood;
    UITextField *instrumentSim;
    UITextField *approachesCount;
    UITextField *approachesType;
    UITextField *holds;
    UITextField *tracking;
    
    // As instructor
    UITextField *dualGiven;
    UITextField *xcDualGiven;
    UITextField *dualGivenInstrument;
    UITextField *dualGivenCommercial;
    UITextField *dualGivenCFI;
    UITextField *dualGivenSport;
    UITextField *dualGivenRecreational;
    UITextField *dualGivenGlider;
    UITextField *dualGivenOther;
    
    // Remarks
    UITextView *remarks;
    
    // Instructor information
    UITableView *EndorsementTableView;
    BOOL isShownPickerView;
    NSManagedObjectContext *context;
    NSInteger endorsementOrignalCount;
    NSMutableArray *arrFlagToEditLog;
    
    //lesson with log
    Lesson *lessonToContainLog;
    
    BOOL isTotalEntry;
    UIButton *certByInstructorBtn;
    UIButton *signatureByInstructorBtn;
    UITextField *certByInsTextField;
    
    UIButton *addEndorsementFirst;
    
    //auto resize with remarks
    UIView *remarksLogView;
    UIView *instructorSignatureView;
    
    NSString *currentLogCfiNum;
    
    NSNumber *currentLogEntryID;
}

- (id)initWithFrame:(CGRect)frame andLogEntry:(LogEntry*)logEntry andRecordLesson:(LessonRecord *)lessonRecord andLesson:(Lesson *)lessonOfLog andInstructorID:(NSNumber *)instructorID andUserID:(NSNumber *)userID  CFInumber:(NSString *)cfiNum fromLesson:(BOOL)isFromLesson withTotalEngry:(BOOL)isTotal
{
    self = [super initWithFrame:frame];
    if (self) {
        if (isFromLesson) {
            [self setScrollEnabled:NO];
        }
        isTotalEntry = isTotal;
        context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        isShownPickerView = NO;
        currentLogEntry = logEntry;
        currentInstructorID = instructorID;
        currentUserID = userID;
        if (lessonOfLog != nil) {
            lessonToContainLog = lessonOfLog;
        }
        currentLogCfiNum = cfiNum;
        // grab the current user's ID
        NSString *userIDKey = @"userId";
        NSString *currentUserIdstr = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
        NSNumber *userID = [NSNumber numberWithInteger: [currentUserIdstr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable parse log entries update without being logged in!");
        }
        
        BOOL editable = YES;
        
        if (currentLogEntry != nil && currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.instructorID != nil && [currentLogEntry.logLessonRecord.instructorID intValue] != [userID intValue]) {
            editable = NO;
        } else if (currentInstructorID != nil && [currentInstructorID intValue] != [userID intValue]) {
            editable = NO;
        }
        
        UIColor *logBookBGColor = [[UIColor alloc] initWithRed:190.0/255.0 green:230.0/255.0 blue:210.0/255.0 alpha:0.5];
        self.backgroundColor = logBookBGColor;
        UIColor *userFieldColor = [UIColor colorWithRed:0.02 green:0.47 blue:1 alpha:1];
        
        int y = 15;
        //UILabel *logBookLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 300, 35)];
        //logBookLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:22];
        //logBookLabel.text = @"Log Book Entry";
        //[self addSubview:logBookLabel];
        //y = y + 10;
        
        int logRowWidth = self.bounds.size.width - 50;
        UIView *firstLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        firstLogView.layer.borderColor = [UIColor blackColor].CGColor;
        firstLogView.layer.borderWidth = 1.0;
        firstLogView.backgroundColor = logBookBGColor;
        
        int fixedColumWidths = 80 + 60 + 60 + 60 + 70 + 70 + 70 + 70 + 70;
        
        int logX = 0;
        // LOG DATE
        UILabel *logDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 91, 51)];
        logDateLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        logDateLabel.textAlignment = NSTextAlignmentCenter;
        logDateLabel.numberOfLines = 0;
        logDateLabel.text = @"DATE";
        logDateLabel.layer.borderColor = [UIColor blackColor].CGColor;
        logDateLabel.layer.borderWidth = 1.0;
        
        logDate = [[UIButton alloc] initWithFrame:CGRectMake(logX, 50, 91, 25)];
        [logDate setTitleColor:userFieldColor forState:UIControlStateNormal];
        logDate.titleLabel.font =[UIFont fontWithName:@"Noteworthy-Bold" size:13];
        logDate.layer.borderColor = [UIColor blackColor].CGColor;
        logDate.layer.borderWidth = 1.0;
        if (editable == NO) {
            [logDate setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        [logDate addTarget:self action:@selector(onDatePickerValueChanged) forControlEvents:UIControlEventTouchUpInside];
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setUsesSignificantDigits: YES];
        numberFormatter.maximumSignificantDigits = 100;
        [numberFormatter setGroupingSeparator:@""];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
        NSDate *logNSDate;
        if (currentLogEntry != nil && currentLogEntry.logDate != nil) {
            logNSDate = currentLogEntry.logDate;
        } else{
            logNSDate = [NSDate date];
        }
        [logDate setTitle:[formatter stringFromDate:logNSDate] forState:UIControlStateNormal];
        
        [firstLogView addSubview:logDateLabel];
        [firstLogView addSubview:logDate];
        logX += 90;
        
        // AIRCRAFT MODEL
        int modelWidth = logRowWidth - fixedColumWidths;
        UILabel *aircraftModelLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, modelWidth + 1-25, 51)];
        aircraftModelLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        aircraftModelLabel.textAlignment = NSTextAlignmentCenter;
        aircraftModelLabel.numberOfLines = 0;
        aircraftModelLabel.text = @"MODEL";
        aircraftModelLabel.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftModelLabel.layer.borderWidth = 1.0;
        
        aircraftModel = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, modelWidth + 1-25, 25)];
        aircraftModel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:14];
        aircraftModel.textAlignment = NSTextAlignmentCenter;
        aircraftModel.textColor = userFieldColor;
        aircraftModel.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftModel.layer.borderWidth = 1.0;
        aircraftModel.delegate = self;
        aircraftModel.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        [aircraftModel addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        if (currentLogEntry != nil && currentLogEntry.aircraftModel != nil && ![currentLogEntry.aircraftModel isEqualToString:@""]) {
            aircraftModel.text = currentLogEntry.aircraftModel;
        } else {
            aircraftModel.text = @"";
        }
        if (editable == NO) {
            aircraftModel.enabled = NO;
            aircraftModel.textColor = [UIColor blackColor];
        }
        [firstLogView addSubview:aircraftModelLabel];
        [firstLogView addSubview:aircraftModel];
        logX += modelWidth-25;
        
        // AIRCRAFT REGISTRATION
        UILabel *aircraftRegistrationLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 71, 51)];
        aircraftRegistrationLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        aircraftRegistrationLabel.textAlignment = NSTextAlignmentCenter;
        aircraftRegistrationLabel.numberOfLines = 0;
        aircraftRegistrationLabel.text = @"REG";
        aircraftRegistrationLabel.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftRegistrationLabel.layer.borderWidth = 1.0;
        
        aircraftRegistration = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 71, 25)];
        aircraftRegistration.font = [UIFont fontWithName:@"Noteworthy-Bold" size:14];
        aircraftRegistration.textAlignment = NSTextAlignmentCenter;
        aircraftRegistration.textColor = userFieldColor;
        aircraftRegistration.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftRegistration.layer.borderWidth = 1.0;
        aircraftRegistration.delegate = self;
        aircraftRegistration.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        [aircraftRegistration addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        if (currentLogEntry != nil && currentLogEntry.aircraftRegistration != nil) {
            aircraftRegistration.text = currentLogEntry.aircraftRegistration;
        } else {
            aircraftRegistration.text = @"";
        }
        if (editable == NO) {
            aircraftRegistration.enabled = NO;
            aircraftRegistration.textColor = [UIColor blackColor];
        }
        [firstLogView addSubview:aircraftRegistrationLabel];
        [firstLogView addSubview:aircraftRegistration];
        logX += 70;
        
        // HOBBs
        UILabel *hobbsLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 166, 26)];
        hobbsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        hobbsLabel.textAlignment = NSTextAlignmentCenter;
        hobbsLabel.text = @"HOBBS";
        hobbsLabel.layer.borderColor = [UIColor blackColor].CGColor;
        hobbsLabel.layer.borderWidth = 1.0;
        [firstLogView addSubview:hobbsLabel];
        
        // HOBBS OUT
        UILabel *hobbsOutLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, 83, 26)];
        hobbsOutLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        hobbsOutLabel.textAlignment = NSTextAlignmentCenter;
        hobbsOutLabel.numberOfLines = 0;
        hobbsOutLabel.text = @"OUT";
        hobbsOutLabel.layer.borderColor = [UIColor blackColor].CGColor;
        hobbsOutLabel.layer.borderWidth = 1.0;
        
        hobbsOut = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 83, 25)];
        hobbsOut.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        hobbsOut.textAlignment = NSTextAlignmentCenter;
        hobbsOut.textColor = userFieldColor;
        hobbsOut.layer.borderColor = [UIColor blackColor].CGColor;
        hobbsOut.layer.borderWidth = 1.0;
        hobbsOut.keyboardType = UIKeyboardTypeNumberPad;
        hobbsOut.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.hobbsOut != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.hobbsOut] == NO && [currentLogEntry.hobbsOut floatValue] != 0) {
            hobbsOut.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.hobbsOut stringValue]];
        } else {
            hobbsOut.text = @"";
        }
        if (editable == NO) {
            hobbsOut.enabled = NO;
            hobbsOut.textColor = [UIColor blackColor];
        }
        [firstLogView addSubview:hobbsOutLabel];
        [firstLogView addSubview:hobbsOut];
        logX += 82;
        
        // HOBBS IN
        UILabel *hobbsInLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, 84, 26)];
        hobbsInLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        hobbsInLabel.textAlignment = NSTextAlignmentCenter;
        hobbsInLabel.numberOfLines = 0;
        hobbsInLabel.text = @"IN";
        hobbsInLabel.layer.borderColor = [UIColor blackColor].CGColor;
        hobbsInLabel.layer.borderWidth = 1.0;
        
        hobbsIn = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 84, 25)];
        hobbsIn.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        hobbsIn.textAlignment = NSTextAlignmentCenter;
        hobbsIn.textColor = userFieldColor;
        hobbsIn.layer.borderColor = [UIColor blackColor].CGColor;
        hobbsIn.layer.borderWidth = 1.0;
        hobbsIn.keyboardType = UIKeyboardTypeNumberPad;
        hobbsIn.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.hobbsIn != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.hobbsIn] == NO && [currentLogEntry.hobbsIn floatValue] != 0) {
            hobbsIn.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.hobbsIn stringValue]];
        } else {
            hobbsIn.text = @"";
        }
        if (editable == NO) {
            hobbsIn.enabled = NO;
            hobbsIn.textColor = [UIColor blackColor];
        }
        [firstLogView addSubview:hobbsInLabel];
        [firstLogView addSubview:hobbsIn];
        logX += 83;
        
        // TOTAL FLIGHT TIME
        UILabel *totalFlightTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 81, 51)];
        totalFlightTimeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        totalFlightTimeLabel.textAlignment = NSTextAlignmentCenter;
        totalFlightTimeLabel.numberOfLines = 0;
        totalFlightTimeLabel.text = @"FLIGHT\nTOTAL";
        totalFlightTimeLabel.layer.borderColor = [UIColor blackColor].CGColor;
        totalFlightTimeLabel.layer.borderWidth = 1.0;
        
        totalFlightTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 81, 25)];
        totalFlightTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:14];
        totalFlightTime.textAlignment = NSTextAlignmentCenter;
        totalFlightTime.textColor = userFieldColor;
        totalFlightTime.layer.borderColor = [UIColor blackColor].CGColor;
        totalFlightTime.layer.borderWidth = 1.0;
        if (currentLogEntry != nil && currentLogEntry.totalFlightTime && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.totalFlightTime] == NO && [currentLogEntry.totalFlightTime floatValue] != 0) {
            totalFlightTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.totalFlightTime stringValue]];
        } else {
            totalFlightTime.text = @"";
        }
        
        NSString *hobbsOutString = hobbsOut.text;
        hobbsOutString = [hobbsOutString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSString *hobbsInString = hobbsIn.text;
        hobbsInString = [hobbsInString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSDecimalNumber *hobbsOutNumber = [NSDecimalNumber decimalNumberWithString:hobbsOutString];
        NSDecimalNumber *hobbsInNumber = [NSDecimalNumber decimalNumberWithString:hobbsInString];
        if (![hobbsOutNumber isEqualToNumber:[NSDecimalNumber notANumber]] && ![hobbsInNumber isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [hobbsInNumber decimalNumberBySubtracting:hobbsOutNumber];
            totalFlightTime.text = [self placeSpacesWithCurrentStringForDecimal:[NSString stringWithFormat:@"%@", totalTimeNumber]];
        }
        
        totalFlightTime.enabled = NO;
        if (editable == NO) {
            totalFlightTime.enabled = NO;
            totalFlightTime.textColor = [UIColor blackColor];
        }
        [firstLogView addSubview:totalFlightTimeLabel];
        [firstLogView addSubview:totalFlightTime];
        logX += 80;
        
        // AIRCRAFT CATEGORY
        UILabel *aircraftCategoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 136, 51)];
        aircraftCategoryLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        aircraftCategoryLabel.textAlignment = NSTextAlignmentCenter;
        aircraftCategoryLabel.numberOfLines = 0;
        aircraftCategoryLabel.text = @"AIRCRAFT\nCATEGORY";
        aircraftCategoryLabel.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftCategoryLabel.layer.borderWidth = 1.0;
        
        
        aircraftCategoryBtn = [[UIButton alloc] initWithFrame:CGRectMake(logX, 50, 136, 25)];
        [aircraftCategoryBtn setTitleColor:userFieldColor forState:UIControlStateNormal];
        aircraftCategoryBtn.titleLabel.font =[UIFont fontWithName:@"Noteworthy-Bold" size:16];
        aircraftCategoryBtn.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftCategoryBtn.layer.borderWidth = 1.0;
        [aircraftCategoryBtn addTarget:self action:@selector(didSelectAircraftCategories) forControlEvents:UIControlEventTouchUpInside];
        if (currentLogEntry != nil && currentLogEntry.aircraftCategory != nil && ![currentLogEntry.aircraftCategory isEqualToString:@""]) {
            [aircraftCategoryBtn setTitle:currentLogEntry.aircraftCategory forState:UIControlStateNormal];
        } else {
            [aircraftCategoryBtn setTitle:@"Airplane" forState:UIControlStateNormal];
        }
        if (editable == NO) {
            [aircraftCategoryBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        [firstLogView addSubview:aircraftCategoryLabel];
        [firstLogView addSubview:aircraftCategoryBtn];
        logX += 135;
        
        // AIRCRAFT CLASS
        int aircraftClassWidth = logRowWidth - logX;
        UILabel *aircraftClassLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, aircraftClassWidth, 51)];
        aircraftClassLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        aircraftClassLabel.textAlignment = NSTextAlignmentCenter;
        aircraftClassLabel.numberOfLines = 0;
        aircraftClassLabel.text = @"AIRCRAFT\nCLASS";
        aircraftClassLabel.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftClassLabel.layer.borderWidth = 1.0;
        
        aircraftClassBtn = [[UIButton alloc] initWithFrame:CGRectMake(logX, 50, aircraftClassWidth, 25)];
        [aircraftClassBtn setTitleColor:userFieldColor forState:UIControlStateNormal];
        aircraftClassBtn.titleLabel.font =[UIFont fontWithName:@"Noteworthy-Bold" size:16];
        aircraftClassBtn.layer.borderColor = [UIColor blackColor].CGColor;
        aircraftClassBtn.layer.borderWidth = 1.0;
        [aircraftClassBtn addTarget:self action:@selector(didSelectAirecraftClass) forControlEvents:UIControlEventTouchUpInside];
        if (editable == NO) {
            [aircraftClassBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        if (currentLogEntry != nil && currentLogEntry.aircraftClass != nil && ![currentLogEntry.aircraftClass isEqualToString:@""]) {
            [aircraftClassBtn setTitle:currentLogEntry.aircraftClass forState:UIControlStateNormal];
        } else {
            [aircraftClassBtn setTitle:@"SEL" forState:UIControlStateNormal];
        }
        [firstLogView addSubview:aircraftClassLabel];
        [firstLogView addSubview:aircraftClassBtn];
        
        [self addSubview:firstLogView];
        y = y + 90;
        
        UIView *secondLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        secondLogView.layer.borderColor = [UIColor blackColor].CGColor;
        secondLogView.layer.borderWidth = 1.0;
        secondLogView.backgroundColor = logBookBGColor;
        
        // ROUTE
        logX = 0;
        int routeWidth = logRowWidth - logX - 120;
        UILabel *routeLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, routeWidth + 1, 51)];
        routeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        routeLabel.textAlignment = NSTextAlignmentCenter;
        routeLabel.numberOfLines = 0;
        routeLabel.text = @"ROUTE";
        routeLabel.layer.borderColor = [UIColor blackColor].CGColor;
        routeLabel.layer.borderWidth = 1.0;
        
        flightRoute = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, routeWidth + 1, 25)];
        flightRoute.font = [UIFont fontWithName:@"Noteworthy-Bold" size:14];
        flightRoute.textAlignment = NSTextAlignmentCenter;
        flightRoute.textColor = userFieldColor;
        flightRoute.layer.borderColor = [UIColor blackColor].CGColor;
        flightRoute.layer.borderWidth = 1.0;
        flightRoute.delegate = self;
        flightRoute.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        [flightRoute addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        if (currentLogEntry != nil && currentLogEntry.flightRoute != nil && ![currentLogEntry.flightRoute isEqualToString:@""]) {
            flightRoute.text = currentLogEntry.flightRoute;
        } else {
            flightRoute.text = @"";
        }
        if (editable == NO) {
            flightRoute.enabled = NO;
            flightRoute.textColor = [UIColor blackColor];
        }
        [secondLogView addSubview:routeLabel];
        [secondLogView addSubview:flightRoute];
        logX += routeWidth;
        
        // LANDINGS
        UILabel *landingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, 120, 26)];
        landingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        landingsLabel.textAlignment = NSTextAlignmentCenter;
        landingsLabel.text = @"LANDINGS";
        landingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
        landingsLabel.layer.borderWidth = 1.0;
        [secondLogView addSubview:landingsLabel];
        
        // DAY LANDINGS
        UILabel *dayLandingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, 61, 26)];
        dayLandingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        dayLandingsLabel.textAlignment = NSTextAlignmentCenter;
        dayLandingsLabel.numberOfLines = 0;
        dayLandingsLabel.text = @"DAY";
        dayLandingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dayLandingsLabel.layer.borderWidth = 1.0;
        
        landingsDay = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 61, 25)];
        landingsDay.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        landingsDay.textAlignment = NSTextAlignmentCenter;
        landingsDay.textColor = userFieldColor;
        landingsDay.layer.borderColor = [UIColor blackColor].CGColor;
        landingsDay.layer.borderWidth = 1.0;
        landingsDay.keyboardType = UIKeyboardTypeNumberPad;
        landingsDay.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.landingsDay != nil && [currentLogEntry.landingsDay floatValue] != 0) {
            landingsDay.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.landingsDay stringValue]];
        } else {
            landingsDay.text = @"";
        }
        if (editable == NO) {
            landingsDay.enabled = NO;
            landingsDay.textColor = [UIColor blackColor];
        }
        [secondLogView addSubview:dayLandingsLabel];
        [secondLogView addSubview:landingsDay];
        logX += 60;
        
        // NIGHT LANDINGS
        UILabel *nightLandingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, 60, 26)];
        nightLandingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        nightLandingsLabel.textAlignment = NSTextAlignmentCenter;
        nightLandingsLabel.numberOfLines = 0;
        nightLandingsLabel.text = @"NITE";
        nightLandingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
        nightLandingsLabel.layer.borderWidth = 1.0;
        
        landingsNight = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, 60, 25)];
        landingsNight.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        landingsNight.textAlignment = NSTextAlignmentCenter;
        landingsNight.textColor = userFieldColor;
        landingsNight.layer.borderColor = [UIColor blackColor].CGColor;
        landingsNight.layer.borderWidth = 1.0;
        landingsNight.keyboardType = UIKeyboardTypeNumberPad;
        landingsNight.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.landingsNight != nil && [currentLogEntry.landingsNight floatValue] != 0) {
            landingsNight.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.landingsNight stringValue]];
        } else {
            landingsNight.text = @"";
        }
        if (editable == NO) {
            landingsNight.enabled = NO;
            landingsNight.textColor = [UIColor blackColor];
        }
        [secondLogView addSubview:nightLandingsLabel];
        [secondLogView addSubview:landingsNight];
        logX += 60;
        
        [self addSubview:secondLogView];
        y = y + 90;
        
        UIView *experienceLogView1 = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        experienceLogView1.layer.borderColor = [UIColor blackColor].CGColor;
        experienceLogView1.layer.borderWidth = 1.0;
        experienceLogView1.backgroundColor = logBookBGColor;
        
        // EXPERIENCE (CONDITIONS)
        logX = 0;
        UILabel *experienceLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        experienceLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        experienceLabel.textAlignment = NSTextAlignmentCenter;
        experienceLabel.text = @"EXPERIENCE";
        experienceLabel.layer.borderColor = [UIColor blackColor].CGColor;
        experienceLabel.layer.borderWidth = 1.0;
        [experienceLogView1 addSubview:experienceLabel];
        
        // NIGHT
        int experienceTimeWidth = logRowWidth / 8;
        UILabel *nightLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        nightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        nightLabel.textAlignment = NSTextAlignmentCenter;
        nightLabel.numberOfLines = 0;
        nightLabel.text = @"NITE";
        nightLabel.layer.borderColor = [UIColor blackColor].CGColor;
        nightLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoNite = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoNite setBackgroundColor:[UIColor clearColor]];
        btnAutoNite.tag = 1501;
        [btnAutoNite addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoNite aboveSubview:nightLabel];
        
        nightTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        nightTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        nightTime.textAlignment = NSTextAlignmentCenter;
        nightTime.textColor = userFieldColor;
        nightTime.layer.borderColor = [UIColor blackColor].CGColor;
        nightTime.layer.borderWidth = 1.0;
        nightTime.keyboardType = UIKeyboardTypeNumberPad;
        nightTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.nightTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.nightTime] == NO && [currentLogEntry.nightTime floatValue] != 0) {
            nightTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.nightTime stringValue]];
        } else {
            nightTime.text = @"";
        }
        if (editable == NO) {
            nightTime.enabled = NO;
            nightTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:nightLabel];
        [experienceLogView1 addSubview:nightTime];
        logX += experienceTimeWidth;
        
        // PIC
        UILabel *picLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        picLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        picLabel.textAlignment = NSTextAlignmentCenter;
        picLabel.numberOfLines = 0;
        picLabel.text = @"PIC";
        picLabel.layer.borderColor = [UIColor blackColor].CGColor;
        picLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoPIC = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoPIC setBackgroundColor:[UIColor clearColor]];
        btnAutoPIC.tag = 1502;
        [btnAutoPIC addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoPIC aboveSubview:picLabel];
        
        picTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        picTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        picTime.textAlignment = NSTextAlignmentCenter;
        picTime.textColor = userFieldColor;
        picTime.layer.borderColor = [UIColor blackColor].CGColor;
        picTime.layer.borderWidth = 1.0;
        picTime.keyboardType = UIKeyboardTypeNumberPad;
        picTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.picTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.picTime] == NO && [currentLogEntry.picTime floatValue] != 0) {
            picTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.picTime stringValue]];
        } else {
            picTime.text = @"";
        }
        if (editable == NO) {
            picTime.enabled = NO;
            picTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:picLabel];
        [experienceLogView1 addSubview:picTime];
        logX += experienceTimeWidth;
        
        // SIC
        UILabel *sicLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        sicLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        sicLabel.textAlignment = NSTextAlignmentCenter;
        sicLabel.numberOfLines = 0;
        sicLabel.text = @"SIC";
        sicLabel.layer.borderColor = [UIColor blackColor].CGColor;
        sicLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoSIC = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoSIC setBackgroundColor:[UIColor clearColor]];
        btnAutoSIC.tag = 1503;
        [btnAutoSIC addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoSIC aboveSubview:sicLabel];
        
        
        sicTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        sicTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        sicTime.textAlignment = NSTextAlignmentCenter;
        sicTime.textColor = userFieldColor;
        sicTime.layer.borderColor = [UIColor blackColor].CGColor;
        sicTime.layer.borderWidth = 1.0;
        sicTime.keyboardType = UIKeyboardTypeNumberPad;
        sicTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.sicTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.sicTime] == NO && [currentLogEntry.sicTime floatValue] != 0) {
            sicTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.sicTime stringValue]];
        } else {
            sicTime.text = @"";
        }
        if (editable == NO) {
            sicTime.enabled = NO;
            sicTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:sicLabel];
        [experienceLogView1 addSubview:sicTime];
        logX += experienceTimeWidth;
        
        // SOLO
        UILabel *soloLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        soloLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        soloLabel.textAlignment = NSTextAlignmentCenter;
        soloLabel.numberOfLines = 0;
        soloLabel.text = @"SOLO";
        soloLabel.layer.borderColor = [UIColor blackColor].CGColor;
        soloLabel.layer.borderWidth = 1.0;
        
        
        UIButton *btnAutoSOLO = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoSOLO setBackgroundColor:[UIColor clearColor]];
        btnAutoSOLO.tag = 1504;
        [btnAutoSOLO addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoSOLO aboveSubview:soloLabel];
        
        
        soloTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        soloTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        soloTime.textAlignment = NSTextAlignmentCenter;
        soloTime.textColor = userFieldColor;
        soloTime.layer.borderColor = [UIColor blackColor].CGColor;
        soloTime.layer.borderWidth = 1.0;
        soloTime.keyboardType = UIKeyboardTypeNumberPad;
        soloTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.soloTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.soloTime] == NO && [currentLogEntry.soloTime floatValue] != 0) {
            soloTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.soloTime stringValue]];
        } else {
            soloTime.text = @"";
        }
        if (editable == NO) {
            soloTime.enabled = NO;
            soloTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:soloLabel];
        [experienceLogView1 addSubview:soloTime];
        logX += experienceTimeWidth;
        
        // X-C (Day)
        UILabel *xcLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        xcLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        xcLabel.textAlignment = NSTextAlignmentCenter;
        xcLabel.numberOfLines = 0;
        xcLabel.text = @"X-C";
        xcLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcLabel.layer.borderWidth = 1.0;
        
        
        UIButton *btnAutoXC = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoXC setBackgroundColor:[UIColor clearColor]];
        btnAutoXC.tag = 1505;
        [btnAutoXC addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoXC aboveSubview:xcLabel];
        
        
        xcDayTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        xcDayTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcDayTime.textAlignment = NSTextAlignmentCenter;
        xcDayTime.textColor = userFieldColor;
        xcDayTime.layer.borderColor = [UIColor blackColor].CGColor;
        xcDayTime.layer.borderWidth = 1.0;
        xcDayTime.keyboardType = UIKeyboardTypeNumberPad;
        xcDayTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xc != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xc] == NO && [currentLogEntry.xc floatValue] != 0) {
            xcDayTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xc stringValue]];
        } else {
            xcDayTime.text = @"";
        }
        if (editable == NO) {
            xcDayTime.enabled = NO;
            xcDayTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:xcLabel];
        [experienceLogView1 addSubview:xcDayTime];
        logX += experienceTimeWidth;
        
        // X-C Solo
        UILabel *xcSoloLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        xcSoloLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        xcSoloLabel.textAlignment = NSTextAlignmentCenter;
        xcSoloLabel.numberOfLines = 0;
        xcSoloLabel.text = @"X-C SOLO";
        xcSoloLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcSoloLabel.layer.borderWidth = 1.0;
        
        
        UIButton *btnAutoXcSolo = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoXcSolo setBackgroundColor:[UIColor clearColor]];
        btnAutoXcSolo.tag = 1506;
        [btnAutoXcSolo addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoXcSolo aboveSubview:xcSoloLabel];
        
        xcSolo = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        xcSolo.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcSolo.textAlignment = NSTextAlignmentCenter;
        xcSolo.textColor = userFieldColor;
        xcSolo.layer.borderColor = [UIColor blackColor].CGColor;
        xcSolo.layer.borderWidth = 1.0;
        xcSolo.keyboardType = UIKeyboardTypeNumberPad;
        xcSolo.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcSolo != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcSolo] == NO && [currentLogEntry.xcSolo floatValue] != 0) {
            xcSolo.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcSolo stringValue]];
        } else {
            xcSolo.text = @"";
        }
        if (editable == NO) {
            xcSolo.enabled = NO;
            xcSolo.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:xcSoloLabel];
        [experienceLogView1 addSubview:xcSolo];
        logX += experienceTimeWidth;
        
        // X-C PIC
        UILabel *xcPicLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTimeWidth + 1, 26)];
        xcPicLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        xcPicLabel.textAlignment = NSTextAlignmentCenter;
        xcPicLabel.numberOfLines = 0;
        xcPicLabel.text = @"X-C PIC";
        xcPicLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcPicLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoXcPic = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTimeWidth+1, 26)];
        [btnAutoXcPic setBackgroundColor:[UIColor clearColor]];
        btnAutoXcPic.tag = 1507;
        [btnAutoXcPic addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoXcPic aboveSubview:xcPicLabel];
        
        xcPIC = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTimeWidth + 1, 25)];
        xcPIC.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcPIC.textAlignment = NSTextAlignmentCenter;
        xcPIC.textColor = userFieldColor;
        xcPIC.layer.borderColor = [UIColor blackColor].CGColor;
        xcPIC.layer.borderWidth = 1.0;
        xcPIC.keyboardType = UIKeyboardTypeNumberPad;
        xcPIC.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcPIC != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcPIC] == NO && [currentLogEntry.xcPIC floatValue] != 0) {
            xcPIC.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcPIC stringValue]];
        } else {
            xcPIC.text = @"";
        }
        if (editable == NO) {
            xcPIC.enabled = NO;
            xcPIC.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:xcPicLabel];
        [experienceLogView1 addSubview:xcPIC];
        logX += experienceTimeWidth;
        
        // X-C Night
        int xcNightWidth = logRowWidth - logX;
        UILabel *xcNightLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, xcNightWidth, 26)];
        xcNightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        xcNightLabel.textAlignment = NSTextAlignmentCenter;
        xcNightLabel.numberOfLines = 0;
        xcNightLabel.text = @"X-C NITE";
        xcNightLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcNightLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoXcNite = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, xcNightWidth, 26)];
        [btnAutoXcNite setBackgroundColor:[UIColor clearColor]];
        btnAutoXcNite.tag = 1508;
        [btnAutoXcNite addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView1 insertSubview:btnAutoXcNite aboveSubview:xcNightLabel];
        
        xcNightTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, xcNightWidth, 25)];
        xcNightTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcNightTime.textAlignment = NSTextAlignmentCenter;
        xcNightTime.textColor = userFieldColor;
        xcNightTime.layer.borderColor = [UIColor blackColor].CGColor;
        xcNightTime.layer.borderWidth = 1.0;
        xcNightTime.keyboardType = UIKeyboardTypeNumberPad;
        xcNightTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcNightTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcNightTime] == NO && [currentLogEntry.xcNightTime floatValue] != 0) {
            xcNightTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcNightTime stringValue]];
        } else {
            xcNightTime.text = @"";
        }
        if (editable == NO) {
            xcNightTime.enabled = NO;
            xcNightTime.textColor = [UIColor blackColor];
        }
        [experienceLogView1 addSubview:xcNightLabel];
        [experienceLogView1 addSubview:xcNightTime];
        logX += experienceTimeWidth;
        
        [self addSubview:experienceLogView1];
        y = y + 90;
        
        UIView *experienceLogView2 = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        experienceLogView2.layer.borderColor = [UIColor blackColor].CGColor;
        experienceLogView2.layer.borderWidth = 1.0;
        experienceLogView2.backgroundColor = logBookBGColor;
        
        // EXPERIENCE (AIRCRAFT TYPE)
        logX = 0;
        UILabel *experienceLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        experienceLabel2.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        experienceLabel2.textAlignment = NSTextAlignmentCenter;
        experienceLabel2.text = @"EXPERIENCE";
        experienceLabel2.layer.borderColor = [UIColor blackColor].CGColor;
        experienceLabel2.layer.borderWidth = 1.0;
        [experienceLogView2 addSubview:experienceLabel2];
        
        // RECREATIONAL
        int experienceTypeWidth = logRowWidth / 10;
        int experienceCheckOffset = (experienceTypeWidth / 2) - 12;
        UILabel *recreationalLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        recreationalLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        recreationalLabel.textAlignment = NSTextAlignmentCenter;
        recreationalLabel.numberOfLines = 0;
        recreationalLabel.text = @"REC";
        recreationalLabel.layer.borderColor = [UIColor blackColor].CGColor;
        recreationalLabel.layer.borderWidth = 1.0;
        
        
        UIButton *btnAutoRect = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoRect setBackgroundColor:[UIColor clearColor]];
        btnAutoRect.tag = 1509;
        [btnAutoRect addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoRect aboveSubview:recreationalLabel];
        
        
        recreationalTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        recreationalTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        recreationalTime.textAlignment = NSTextAlignmentCenter;
        recreationalTime.textColor = userFieldColor;
        recreationalTime.layer.borderColor = [UIColor blackColor].CGColor;
        recreationalTime.layer.borderWidth = 1.0;
        recreationalTime.keyboardType = UIKeyboardTypeNumberPad;
        recreationalTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.recreational != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.recreational] == NO && [currentLogEntry.recreational floatValue] != 0) {
            recreationalTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.recreational stringValue]];
        } else {
            recreationalTime.text = @"";
        }
        if (editable == NO) {
            recreationalTime.enabled = NO;
            recreationalTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:recreationalLabel];
        [experienceLogView2 addSubview:recreationalTime];
        logX += experienceTypeWidth;
        
        // SPORT
        UILabel *sportLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        sportLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        sportLabel.textAlignment = NSTextAlignmentCenter;
        sportLabel.numberOfLines = 0;
        sportLabel.text = @"SPORT";
        sportLabel.layer.borderColor = [UIColor blackColor].CGColor;
        sportLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoSport = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoSport setBackgroundColor:[UIColor clearColor]];
        btnAutoSport.tag = 1510;
        [btnAutoSport addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoSport aboveSubview:sportLabel];
        
        sportTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        sportTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        sportTime.textAlignment = NSTextAlignmentCenter;
        sportTime.textColor = userFieldColor;
        sportTime.layer.borderColor = [UIColor blackColor].CGColor;
        sportTime.layer.borderWidth = 1.0;
        sportTime.keyboardType = UIKeyboardTypeNumberPad;
        sportTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.sport != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.sport] == NO && [currentLogEntry.sport floatValue] != 0) {
            sportTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.sport stringValue]];
        } else {
            sportTime.text = @"";
        }
        if (editable == NO) {
            sportTime.enabled = NO;
            sportTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:sportLabel];
        [experienceLogView2 addSubview:sportTime];
        logX += experienceTypeWidth;
        
        // High Performance
        UILabel *highPerfLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        highPerfLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        highPerfLabel.textAlignment = NSTextAlignmentCenter;
        highPerfLabel.numberOfLines = 0;
        highPerfLabel.text = @"HI-PERF";
        highPerfLabel.layer.borderColor = [UIColor blackColor].CGColor;
        highPerfLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoHiPerf = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoHiPerf setBackgroundColor:[UIColor clearColor]];
        btnAutoHiPerf.tag = 1511;
        [btnAutoHiPerf addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoHiPerf aboveSubview:highPerfLabel];
        
        highPerfTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        highPerfTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        highPerfTime.textAlignment = NSTextAlignmentCenter;
        highPerfTime.textColor = userFieldColor;
        highPerfTime.layer.borderColor = [UIColor blackColor].CGColor;
        highPerfTime.layer.borderWidth = 1.0;
        highPerfTime.keyboardType = UIKeyboardTypeNumberPad;
        highPerfTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.highPerf != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.highPerf] == NO && [currentLogEntry.highPerf floatValue] != 0) {
            highPerfTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.highPerf stringValue]];
        } else {
            highPerfTime.text = @"";
        }
        if (editable == NO) {
            highPerfTime.enabled = NO;
            highPerfTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:highPerfLabel];
        [experienceLogView2 addSubview:highPerfTime];
        logX += experienceTypeWidth;
        
        // Complex
        UILabel *complexLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        complexLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
        complexLabel.textAlignment = NSTextAlignmentCenter;
        complexLabel.numberOfLines = 0;
        complexLabel.text = @"CMPLX";
        complexLabel.layer.borderColor = [UIColor blackColor].CGColor;
        complexLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoCmplx = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoCmplx setBackgroundColor:[UIColor clearColor]];
        btnAutoCmplx.tag = 1512;
        [btnAutoCmplx addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoCmplx aboveSubview:complexLabel];
        
        complexTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        complexTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        complexTime.textAlignment = NSTextAlignmentCenter;
        complexTime.textColor = userFieldColor;
        complexTime.layer.borderColor = [UIColor blackColor].CGColor;
        complexTime.layer.borderWidth = 1.0;
        complexTime.keyboardType = UIKeyboardTypeNumberPad;
        complexTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.complex != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.complex] == NO && [currentLogEntry.complex floatValue] != 0) {
            complexTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.complex stringValue]];
        } else {
            complexTime.text = @"";
        }
        if (editable == NO) {
            complexTime.enabled = NO;
            complexTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:complexLabel];
        [experienceLogView2 addSubview:complexTime];
        logX += experienceTypeWidth;
        
        // Tail Dragger
        UILabel *tailDraggerLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        tailDraggerLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        tailDraggerLabel.textAlignment = NSTextAlignmentCenter;
        tailDraggerLabel.numberOfLines = 0;
        tailDraggerLabel.text = @"TAIL";
        tailDraggerLabel.layer.borderColor = [UIColor blackColor].CGColor;
        tailDraggerLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoTail = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoTail setBackgroundColor:[UIColor clearColor]];
        btnAutoTail.tag = 1513;
        [btnAutoTail addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoTail aboveSubview:tailDraggerLabel];
        
        taildraggerTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        taildraggerTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        taildraggerTime.textAlignment = NSTextAlignmentCenter;
        taildraggerTime.textColor = userFieldColor;
        taildraggerTime.layer.borderColor = [UIColor blackColor].CGColor;
        taildraggerTime.layer.borderWidth = 1.0;
        taildraggerTime.keyboardType = UIKeyboardTypeNumberPad;
        taildraggerTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.taildragger != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.taildragger] == NO && [currentLogEntry.taildragger floatValue] != 0) {
            taildraggerTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.taildragger stringValue]];
        } else {
            taildraggerTime.text = @"";
        }
        if (editable == NO) {
            taildraggerTime.enabled = NO;
            taildraggerTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:tailDraggerLabel];
        [experienceLogView2 addSubview:taildraggerTime];
        logX += experienceTypeWidth;
        
        // Glider
        UILabel *gliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        gliderLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        gliderLabel.textAlignment = NSTextAlignmentCenter;
        gliderLabel.numberOfLines = 0;
        gliderLabel.text = @"GLIDE";
        gliderLabel.layer.borderColor = [UIColor blackColor].CGColor;
        gliderLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoGlide = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoGlide setBackgroundColor:[UIColor clearColor]];
        btnAutoGlide.tag = 1514;
        [btnAutoGlide addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoGlide aboveSubview:gliderLabel];
        
        gliderTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        gliderTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        gliderTime.textAlignment = NSTextAlignmentCenter;
        gliderTime.textColor = userFieldColor;
        gliderTime.layer.borderColor = [UIColor blackColor].CGColor;
        gliderTime.layer.borderWidth = 1.0;
        gliderTime.keyboardType = UIKeyboardTypeNumberPad;
        gliderTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.glider != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.glider] == NO && [currentLogEntry.glider floatValue] != 0) {
            gliderTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.glider stringValue]];
        } else {
            gliderTime.text = @"";
        }
        if (editable == NO) {
            gliderTime.enabled = NO;
            gliderTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:gliderLabel];
        [experienceLogView2 addSubview:gliderTime];
        logX += experienceTypeWidth;
        
        // Ultra Light
        UILabel *ultraLightLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        ultraLightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        ultraLightLabel.textAlignment = NSTextAlignmentCenter;
        ultraLightLabel.numberOfLines = 0;
        ultraLightLabel.text = @"ULGHT";
        ultraLightLabel.layer.borderColor = [UIColor blackColor].CGColor;
        ultraLightLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoUlght = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoUlght setBackgroundColor:[UIColor clearColor]];
        btnAutoUlght.tag = 1515;
        [btnAutoUlght addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoUlght aboveSubview:ultraLightLabel];
        
        ultraLightTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        ultraLightTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        ultraLightTime.textAlignment = NSTextAlignmentCenter;
        ultraLightTime.textColor = userFieldColor;
        ultraLightTime.layer.borderColor = [UIColor blackColor].CGColor;
        ultraLightTime.layer.borderWidth = 1.0;
        ultraLightTime.keyboardType = UIKeyboardTypeNumberPad;
        ultraLightTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.ultraLight != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.ultraLight] == NO && [currentLogEntry.ultraLight floatValue] != 0) {
            ultraLightTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.ultraLight stringValue]];
        } else {
            ultraLightTime.text = @"";
        }
        if (editable == NO) {
            ultraLightTime.enabled = NO;
            ultraLightTime.textColor = [UIColor blackColor];
        }
        [experienceLogView2 addSubview:ultraLightLabel];
        [experienceLogView2 addSubview:ultraLightTime];
        logX += experienceTypeWidth;
        
        // Helicopter
        UILabel *helicopterLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        helicopterLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        helicopterLabel.textAlignment = NSTextAlignmentCenter;
        helicopterLabel.numberOfLines = 0;
        helicopterLabel.text = @"HELO";
        helicopterLabel.layer.borderColor = [UIColor blackColor].CGColor;
        helicopterLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoHelo = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoHelo setBackgroundColor:[UIColor clearColor]];
        btnAutoHelo.tag = 1516;
        [btnAutoHelo addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoHelo aboveSubview:helicopterLabel];
        
        helicopterTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        helicopterTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        helicopterTime.textAlignment = NSTextAlignmentCenter;
        helicopterTime.textColor = userFieldColor;
        helicopterTime.layer.borderColor = [UIColor blackColor].CGColor;
        helicopterTime.layer.borderWidth = 1.0;
        helicopterTime.keyboardType = UIKeyboardTypeNumberPad;
        helicopterTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.helicopter != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.helicopter] == NO && [currentLogEntry.helicopter floatValue] != 0) {
            helicopterTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.helicopter stringValue]];
        } else {
            helicopterTime.text = @"";
        }
        if (editable == NO) {
            helicopterTime.enabled = NO;
            helicopterTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:helicopterLabel];
        [experienceLogView2 addSubview:helicopterTime];
        logX += experienceTypeWidth;
        
        // Turboprop
        UILabel *turboPropLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, experienceTypeWidth + 1, 26)];
        turboPropLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        turboPropLabel.textAlignment = NSTextAlignmentCenter;
        turboPropLabel.numberOfLines = 0;
        turboPropLabel.text = @"TPROP";
        turboPropLabel.layer.borderColor = [UIColor blackColor].CGColor;
        turboPropLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoTprop = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, experienceTypeWidth+1, 26)];
        [btnAutoTprop setBackgroundColor:[UIColor clearColor]];
        btnAutoTprop.tag = 1517;
        [btnAutoTprop addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoTprop aboveSubview:turboPropLabel];
        
        
        turbopropTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, experienceTypeWidth + 1, 25)];
        turbopropTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        turbopropTime.textAlignment = NSTextAlignmentCenter;
        turbopropTime.textColor = userFieldColor;
        turbopropTime.layer.borderColor = [UIColor blackColor].CGColor;
        turbopropTime.layer.borderWidth = 1.0;
        turbopropTime.keyboardType = UIKeyboardTypeNumberPad;
        turbopropTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.turboprop != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.turboprop] == NO && [currentLogEntry.turboprop floatValue] != 0) {
            turbopropTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.turboprop stringValue]];
        } else {
            turbopropTime.text = @"";
        }
        if (editable == NO) {
            turbopropTime.enabled = NO;
            turbopropTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:turboPropLabel];
        [experienceLogView2 addSubview:turbopropTime];
        logX += experienceTypeWidth;
        
        // Jet
        int jetWidth = logRowWidth - logX;
        int jetCheckOffset = (jetWidth / 2) - 12;
        UILabel *jetLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, jetWidth, 26)];
        jetLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        jetLabel.textAlignment = NSTextAlignmentCenter;
        jetLabel.numberOfLines = 0;
        jetLabel.text = @"JET";
        jetLabel.layer.borderColor = [UIColor blackColor].CGColor;
        jetLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoJet = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, jetWidth, 26)];
        [btnAutoJet setBackgroundColor:[UIColor clearColor]];
        btnAutoJet.tag = 1518;
        [btnAutoJet addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [experienceLogView2 insertSubview:btnAutoJet aboveSubview:jetLabel];
        
        jetTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, jetWidth + 1, 25)];
        jetTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        jetTime.textAlignment = NSTextAlignmentCenter;
        jetTime.textColor = userFieldColor;
        jetTime.layer.borderColor = [UIColor blackColor].CGColor;
        jetTime.layer.borderWidth = 1.0;
        jetTime.keyboardType = UIKeyboardTypeNumberPad;
        jetTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.jet != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.jet] == NO && [currentLogEntry.jet floatValue] != 0) {
            jetTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.jet stringValue]];
        } else {
            jetTime.text = @"";
        }
        if (editable == NO) {
            jetTime.enabled = NO;
            jetTime.textColor = [UIColor blackColor];
        }
        
        [experienceLogView2 addSubview:jetLabel];
        [experienceLogView2 addSubview:jetTime];
        logX += jetWidth;
        
        [self addSubview:experienceLogView2];
        y = y + 90;
        
        UIView *trainingLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        trainingLogView.layer.borderColor = [UIColor blackColor].CGColor;
        trainingLogView.layer.borderWidth = 1.0;
        trainingLogView.backgroundColor = logBookBGColor;
        
        // TRAINING
        logX = 0;
        UILabel *trainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        trainingLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        trainingLabel.textAlignment = NSTextAlignmentCenter;
        trainingLabel.text = @"TRAINING";
        trainingLabel.layer.borderColor = [UIColor blackColor].CGColor;
        trainingLabel.layer.borderWidth = 1.0;
        [trainingLogView addSubview:trainingLabel];
        
        // GROUND RECEIVED
        int trainingWidth = logRowWidth / 5;
        UILabel *groundReceivedLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, trainingWidth + 1, 26)];
        groundReceivedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        groundReceivedLabel.textAlignment = NSTextAlignmentCenter;
        groundReceivedLabel.numberOfLines = 0;
        groundReceivedLabel.text = @"GRND RCVD";
        groundReceivedLabel.layer.borderColor = [UIColor blackColor].CGColor;
        groundReceivedLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoGrndRcvd = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, trainingWidth+1, 26)];
        [btnAutoGrndRcvd setBackgroundColor:[UIColor clearColor]];
        btnAutoGrndRcvd.tag = 1519;
        [btnAutoGrndRcvd addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [trainingLogView insertSubview:btnAutoGrndRcvd aboveSubview:groundReceivedLabel];
        
        groundTime = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, trainingWidth + 1, 25)];
        groundTime.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        groundTime.textAlignment = NSTextAlignmentCenter;
        groundTime.textColor = userFieldColor;
        groundTime.layer.borderColor = [UIColor blackColor].CGColor;
        groundTime.layer.borderWidth = 1.0;
        groundTime.keyboardType = UIKeyboardTypeNumberPad;
        groundTime.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.groundTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.groundTime] == NO && [currentLogEntry.groundTime floatValue] != 0) {
            groundTime.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.groundTime stringValue]];
        } else {
            groundTime.text = @"";
        }
        if (editable == NO) {
            groundTime.enabled = NO;
            groundTime.textColor = [UIColor blackColor];
        }
        [trainingLogView addSubview:groundReceivedLabel];
        [trainingLogView addSubview:groundTime];
        logX += trainingWidth;
        
        // DUAL RECEIVED
        UILabel *dualReceivedLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, trainingWidth + 1, 26)];
        dualReceivedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        dualReceivedLabel.textAlignment = NSTextAlignmentCenter;
        dualReceivedLabel.numberOfLines = 0;
        dualReceivedLabel.text = @"DUAL RCVD";
        dualReceivedLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualReceivedLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualRcvd = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, trainingWidth+1, 26)];
        [btnAutoDualRcvd setBackgroundColor:[UIColor clearColor]];
        btnAutoDualRcvd.tag = 1520;
        [btnAutoDualRcvd addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [trainingLogView insertSubview:btnAutoDualRcvd aboveSubview:dualReceivedLabel];
        
        dualReceived = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, trainingWidth + 1, 25)];
        dualReceived.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualReceived.textAlignment = NSTextAlignmentCenter;
        dualReceived.textColor = userFieldColor;
        dualReceived.layer.borderColor = [UIColor blackColor].CGColor;
        dualReceived.layer.borderWidth = 1.0;
        dualReceived.keyboardType = UIKeyboardTypeNumberPad;
        dualReceived.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualReceived] == NO && [currentLogEntry.dualReceived floatValue] != 0) {
            dualReceived.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualReceived stringValue]];
        } else {
            dualReceived.text = @"";
        }
        
        if (lessonToContainLog != nil) {
            if (totalFlightTime.text.length > 0 && dualReceived.text.length == 0) {
                dualReceived.text = totalFlightTime.text;
            }
        }
        
        if (editable == NO) {
            dualReceived.enabled = NO;
            dualReceived.textColor = [UIColor blackColor];
        }
        [trainingLogView addSubview:dualReceivedLabel];
        [trainingLogView addSubview:dualReceived];
        logX += trainingWidth;
        
        // NIGHT DUAL RECEIVED
        UILabel *nightDualReceivedLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, trainingWidth + 1, 26)];
        nightDualReceivedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        nightDualReceivedLabel.textAlignment = NSTextAlignmentCenter;
        nightDualReceivedLabel.numberOfLines = 0;
        nightDualReceivedLabel.text = @"NITE DUAL RCVD";
        nightDualReceivedLabel.layer.borderColor = [UIColor blackColor].CGColor;
        nightDualReceivedLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoNiteDualRcvd = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, trainingWidth+1, 26)];
        [btnAutoNiteDualRcvd setBackgroundColor:[UIColor clearColor]];
        btnAutoNiteDualRcvd.tag = 1521;
        [btnAutoNiteDualRcvd addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [trainingLogView insertSubview:btnAutoNiteDualRcvd aboveSubview:nightDualReceivedLabel];
        
        nightDualReceived = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, trainingWidth + 1, 25)];
        nightDualReceived.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        nightDualReceived.textAlignment = NSTextAlignmentCenter;
        nightDualReceived.textColor = userFieldColor;
        nightDualReceived.layer.borderColor = [UIColor blackColor].CGColor;
        nightDualReceived.layer.borderWidth = 1.0;
        nightDualReceived.keyboardType = UIKeyboardTypeNumberPad;
        nightDualReceived.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.nightDualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.nightDualReceived] == NO && [currentLogEntry.nightDualReceived floatValue] != 0) {
            nightDualReceived.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.nightDualReceived stringValue]];
        } else {
            nightDualReceived.text = @"";
        }
        if (editable == NO) {
            nightDualReceived.enabled = NO;
            nightDualReceived.textColor = [UIColor blackColor];
        }
        [trainingLogView addSubview:nightDualReceivedLabel];
        [trainingLogView addSubview:nightDualReceived];
        logX += trainingWidth;
        
        // X-C DUAL RECEIVED
        UILabel *xcDualReceivedLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, trainingWidth + 1, 26)];
        xcDualReceivedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        xcDualReceivedLabel.textAlignment = NSTextAlignmentCenter;
        xcDualReceivedLabel.numberOfLines = 0;
        xcDualReceivedLabel.text = @"XC DUAL RCVD";
        xcDualReceivedLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcDualReceivedLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoXcDualRcvd = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, trainingWidth+1, 26)];
        [btnAutoXcDualRcvd setBackgroundColor:[UIColor clearColor]];
        btnAutoXcDualRcvd.tag = 1522;
        [btnAutoXcDualRcvd addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [trainingLogView insertSubview:btnAutoXcDualRcvd aboveSubview:xcDualReceivedLabel];
        
        xcDualReceived = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, trainingWidth + 1, 25)];
        xcDualReceived.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcDualReceived.textAlignment = NSTextAlignmentCenter;
        xcDualReceived.textColor = userFieldColor;
        xcDualReceived.layer.borderColor = [UIColor blackColor].CGColor;
        xcDualReceived.layer.borderWidth = 1.0;
        xcDualReceived.keyboardType = UIKeyboardTypeNumberPad;
        xcDualReceived.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcDualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcDualReceived] == NO && [currentLogEntry.xcDualReceived floatValue] != 0) {
            xcDualReceived.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcDualReceived stringValue]];
        } else {
            xcDualReceived.text = @"";
        }
        if (editable == NO) {
            xcDualReceived.enabled = NO;
            xcDualReceived.textColor = [UIColor blackColor];
        }
        [trainingLogView addSubview:xcDualReceivedLabel];
        [trainingLogView addSubview:xcDualReceived];
        logX += trainingWidth;
        
        // X-C NIGHT DUAL RECEIVED
        int xcNightDualReceivedWidth = logRowWidth - logX;
        UILabel *xcNightDualReceivedLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, xcNightDualReceivedWidth, 26)];
        xcNightDualReceivedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        xcNightDualReceivedLabel.textAlignment = NSTextAlignmentCenter;
        xcNightDualReceivedLabel.numberOfLines = 0;
        xcNightDualReceivedLabel.text = @"XC NITE DUAL RCVD";
        xcNightDualReceivedLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcNightDualReceivedLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoXcNiteDualRcvd = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, xcNightDualReceivedWidth, 26)];
        [btnAutoXcNiteDualRcvd setBackgroundColor:[UIColor clearColor]];
        btnAutoXcNiteDualRcvd.tag = 1523;
        [btnAutoXcNiteDualRcvd addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [trainingLogView insertSubview:btnAutoXcNiteDualRcvd aboveSubview:xcNightDualReceivedLabel];

        xcNightDualReceived = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, xcNightDualReceivedWidth, 25)];
        xcNightDualReceived.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcNightDualReceived.textAlignment = NSTextAlignmentCenter;
        xcNightDualReceived.textColor = userFieldColor;
        xcNightDualReceived.layer.borderColor = [UIColor blackColor].CGColor;
        xcNightDualReceived.layer.borderWidth = 1.0;
        xcNightDualReceived.keyboardType = UIKeyboardTypeNumberPad;
        xcNightDualReceived.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcNightDualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcNightDualReceived] == NO && [currentLogEntry.xcNightDualReceived floatValue] != 0) {
            xcNightDualReceived.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcNightDualReceived stringValue]];
        } else {
            xcNightDualReceived.text = @"";
        }
        if (editable == NO) {
            xcNightDualReceived.enabled = NO;
            xcNightDualReceived.textColor = [UIColor blackColor];
        }
        [trainingLogView addSubview:xcNightDualReceivedLabel];
        [trainingLogView addSubview:xcNightDualReceived];
        logX += trainingWidth;
        
        [self addSubview:trainingLogView];
        y = y + 90;
        
        UIView *instrumentLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        instrumentLogView.layer.borderColor = [UIColor blackColor].CGColor;
        instrumentLogView.layer.borderWidth = 1.0;
        instrumentLogView.backgroundColor = logBookBGColor;
        
        // INSTRUMENT
        logX = 0;
        UILabel *instrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        instrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        instrumentLabel.textAlignment = NSTextAlignmentCenter;
        instrumentLabel.text = @"INSTRUMENT";
        instrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
        instrumentLabel.layer.borderWidth = 1.0;
        [instrumentLogView addSubview:instrumentLabel];
        
        
        // ACTUAL INSTRUMENT
        int instrumentWidth = logRowWidth / 7;
        UILabel *actualLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instrumentWidth + 1, 26)];
        actualLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        actualLabel.textAlignment = NSTextAlignmentCenter;
        actualLabel.numberOfLines = 0;
        actualLabel.text = @"ACTUAL";
        actualLabel.layer.borderColor = [UIColor blackColor].CGColor;
        actualLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoActual = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instrumentWidth+1, 26)];
        [btnAutoActual setBackgroundColor:[UIColor clearColor]];
        btnAutoActual.tag = 1524;
        [btnAutoActual addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instrumentLogView insertSubview:btnAutoActual aboveSubview:actualLabel];

        
        instrumentActual = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        instrumentActual.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        instrumentActual.textAlignment = NSTextAlignmentCenter;
        instrumentActual.textColor = userFieldColor;
        instrumentActual.layer.borderColor = [UIColor blackColor].CGColor;
        instrumentActual.layer.borderWidth = 1.0;
        instrumentActual.keyboardType = UIKeyboardTypeNumberPad;
        instrumentActual.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.instrumentActual != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.instrumentActual] == NO && [currentLogEntry.instrumentActual floatValue] != 0) {
            instrumentActual.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.instrumentActual stringValue]];
        } else {
            instrumentActual.text = @"";
        }
        if (editable == NO) {
            instrumentActual.enabled = NO;
            instrumentActual.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:actualLabel];
        [instrumentLogView addSubview:instrumentActual];
        logX += instrumentWidth;
        
        // HOOD INSTRUMENT
        UILabel *hoodLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instrumentWidth + 1, 26)];
        hoodLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        hoodLabel.textAlignment = NSTextAlignmentCenter;
        hoodLabel.numberOfLines = 0;
        hoodLabel.text = @"HOOD";
        hoodLabel.layer.borderColor = [UIColor blackColor].CGColor;
        hoodLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoHood = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instrumentWidth+1, 26)];
        [btnAutoHood setBackgroundColor:[UIColor clearColor]];
        btnAutoHood.tag = 1525;
        [btnAutoHood addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instrumentLogView insertSubview:btnAutoHood aboveSubview:hoodLabel];

        instrumentHood = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        instrumentHood.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        instrumentHood.textAlignment = NSTextAlignmentCenter;
        instrumentHood.textColor = userFieldColor;
        instrumentHood.layer.borderColor = [UIColor blackColor].CGColor;
        instrumentHood.layer.borderWidth = 1.0;
        instrumentHood.keyboardType = UIKeyboardTypeNumberPad;
        instrumentHood.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.instrumentHood != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.instrumentHood] == NO && [currentLogEntry.instrumentHood floatValue] != 0) {
            instrumentHood.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.instrumentHood stringValue]];
        } else {
            instrumentHood.text = @"";
        }
        if (editable == NO) {
            instrumentHood.enabled = NO;
            instrumentHood.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:hoodLabel];
        [instrumentLogView addSubview:instrumentHood];
        logX += instrumentWidth;
        
        // SIM INSTRUMENT
        UILabel *simLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instrumentWidth + 1, 26)];
        simLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        simLabel.textAlignment = NSTextAlignmentCenter;
        simLabel.numberOfLines = 0;
        simLabel.text = @"SIM";
        simLabel.layer.borderColor = [UIColor blackColor].CGColor;
        simLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoSim = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instrumentWidth, 26)];
        [btnAutoSim setBackgroundColor:[UIColor clearColor]];
        btnAutoSim.tag = 1526;
        [btnAutoSim addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instrumentLogView insertSubview:btnAutoSim aboveSubview:simLabel];
        
        instrumentSim = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        instrumentSim.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        instrumentSim.textAlignment = NSTextAlignmentCenter;
        instrumentSim.textColor = userFieldColor;
        instrumentSim.layer.borderColor = [UIColor blackColor].CGColor;
        instrumentSim.layer.borderWidth = 1.0;
        instrumentSim.keyboardType = UIKeyboardTypeNumberPad;
        instrumentSim.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.instrumentSim != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.instrumentSim] == NO && [currentLogEntry.instrumentSim floatValue] != 0) {
            instrumentSim.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.instrumentSim stringValue]];
        } else {
            instrumentSim.text = @"";
        }
        if (editable == NO) {
            instrumentSim.enabled = NO;
            instrumentSim.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:simLabel];
        [instrumentLogView addSubview:instrumentSim];
        logX += instrumentWidth;
        
        // APPROACHES
        UILabel *approachesLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, (instrumentWidth * 2) + 1, 14)];
        approachesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        approachesLabel.textAlignment = NSTextAlignmentCenter;
        approachesLabel.numberOfLines = 0;
        approachesLabel.text = @"APPROACHES";
        approachesLabel.layer.borderColor = [UIColor blackColor].CGColor;
        approachesLabel.layer.borderWidth = 1.0;
        [instrumentLogView addSubview:approachesLabel];
        
        // APPROACHES COUNT
        UILabel *approachesCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 38, instrumentWidth + 1, 13)];
        approachesCountLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        approachesCountLabel.textAlignment = NSTextAlignmentCenter;
        approachesCountLabel.numberOfLines = 0;
        approachesCountLabel.text = @"NO.";
        approachesCountLabel.layer.borderColor = [UIColor blackColor].CGColor;
        approachesCountLabel.layer.borderWidth = 1.0;
        
        approachesCount = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        approachesCount.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        approachesCount.textAlignment = NSTextAlignmentCenter;
        approachesCount.textColor = userFieldColor;
        approachesCount.layer.borderColor = [UIColor blackColor].CGColor;
        approachesCount.layer.borderWidth = 1.0;
        approachesCount.keyboardType = UIKeyboardTypeNumberPad;
        approachesCount.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.approachesCount != nil & [currentLogEntry.approachesCount floatValue] != 0) {
            approachesCount.text = [currentLogEntry.approachesCount stringValue];
        } else {
            approachesCount.text = @"";
        }
        if (editable == NO) {
            approachesCount.enabled = NO;
            approachesCount.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:approachesCountLabel];
        [instrumentLogView addSubview:approachesCount];
        logX += instrumentWidth;
        
        // APPROACHES TYPE
        UILabel *approachesTypeLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 38, instrumentWidth + 1, 13)];
        approachesTypeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        approachesTypeLabel.textAlignment = NSTextAlignmentCenter;
        approachesTypeLabel.numberOfLines = 0;
        approachesTypeLabel.text = @"TYPE";
        approachesTypeLabel.layer.borderColor = [UIColor blackColor].CGColor;
        approachesTypeLabel.layer.borderWidth = 1.0;
        
        approachesType = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        approachesType.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        approachesType.textAlignment = NSTextAlignmentCenter;
        approachesType.textColor = userFieldColor;
        approachesType.layer.borderColor = [UIColor blackColor].CGColor;
        approachesType.layer.borderWidth = 1.0;
        approachesType.keyboardType = UIKeyboardTypeNumberPad;
        approachesType.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.approachesType != nil && ![currentLogEntry.approachesType isEqualToString:@""]) {
            approachesType.text = currentLogEntry.approachesType;
        } else {
            approachesType.text = @"";
        }
        if (editable == NO) {
            approachesType.enabled = NO;
            approachesType.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:approachesTypeLabel];
        [instrumentLogView addSubview:approachesType];
        logX += instrumentWidth;
        
        // HOLDS
        UILabel *holdsLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instrumentWidth + 1, 26)];
        holdsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        holdsLabel.textAlignment = NSTextAlignmentCenter;
        holdsLabel.numberOfLines = 0;
        holdsLabel.text = @"HOLDS";
        holdsLabel.layer.borderColor = [UIColor blackColor].CGColor;
        holdsLabel.layer.borderWidth = 1.0;
        
        holds = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instrumentWidth + 1, 25)];
        holds.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        holds.textAlignment = NSTextAlignmentCenter;
        holds.textColor = userFieldColor;
        holds.layer.borderColor = [UIColor blackColor].CGColor;
        holds.layer.borderWidth = 1.0;
        holds.keyboardType = UIKeyboardTypeNumberPad;
        holds.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.holds != nil && [currentLogEntry.holds floatValue] != 0) {
            holds.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.holds stringValue]];
        } else {
            holds.text = @"";
        }
        if (editable == NO) {
            holds.enabled = NO;
            holds.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:holdsLabel];
        [instrumentLogView addSubview:holds];
        logX += instrumentWidth;
        
        // NAV-TRACK
        int navTrackWidth = logRowWidth - logX;
        UILabel *navTrackLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, navTrackWidth, 26)];
        navTrackLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        navTrackLabel.textAlignment = NSTextAlignmentCenter;
        navTrackLabel.numberOfLines = 0;
        navTrackLabel.text = @"NAV-TRACK";
        navTrackLabel.layer.borderColor = [UIColor blackColor].CGColor;
        navTrackLabel.layer.borderWidth = 1.0;
        
        tracking = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, navTrackWidth, 25)];
        tracking.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        tracking.textAlignment = NSTextAlignmentCenter;
        tracking.textColor = userFieldColor;
        tracking.layer.borderColor = [UIColor blackColor].CGColor;
        tracking.layer.borderWidth = 1.0;
        tracking.keyboardType = UIKeyboardTypeNumberPad;
        tracking.delegate= self;
        if (currentLogEntry != nil && currentLogEntry.tracking != nil && ![currentLogEntry.tracking isEqualToString:@""]) {
            tracking.text = currentLogEntry.tracking;
        } else {
            tracking.text = @"";
        }
        if (editable == NO) {
            tracking.enabled = NO;
            tracking.textColor = [UIColor blackColor];
        }
        [instrumentLogView addSubview:navTrackLabel];
        [instrumentLogView addSubview:tracking];
        logX += navTrackWidth;
        
        [self addSubview:instrumentLogView];
        y = y + 90;
        
        UIView *instructorLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 75)];
        instructorLogView.layer.borderColor = [UIColor blackColor].CGColor;
        instructorLogView.layer.borderWidth = 1.0;
        instructorLogView.backgroundColor = logBookBGColor;
        
        // AS INSTRUCTOR
        logX = 0;
        UILabel *asInstructorLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        asInstructorLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        asInstructorLabel.textAlignment = NSTextAlignmentCenter;
        asInstructorLabel.text = @"AS INSTRUCTOR";
        asInstructorLabel.layer.borderColor = [UIColor blackColor].CGColor;
        asInstructorLabel.layer.borderWidth = 1.0;
        [instructorLogView addSubview:asInstructorLabel];

        // DUAL GIVEN
        int instructorWidth = logRowWidth / 9;
        UILabel *dualGivenLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenLabel.numberOfLines = 0;
        dualGivenLabel.text = @"DUAL GIVEN";
        dualGivenLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGiven = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGiven setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGiven.tag = 1527;
        [btnAutoDualGiven addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGiven aboveSubview:dualGivenLabel];
        
        dualGiven = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGiven.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGiven.textAlignment = NSTextAlignmentCenter;
        dualGiven.textColor = userFieldColor;
        dualGiven.layer.borderColor = [UIColor blackColor].CGColor;
        dualGiven.layer.borderWidth = 1.0;
        dualGiven.keyboardType = UIKeyboardTypeNumberPad;
        dualGiven.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGiven != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGiven] == NO && [currentLogEntry.dualGiven floatValue] != 0) {
            dualGiven.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGiven stringValue]];
        } else {
            dualGiven.text = @"";
        }
        
        if (lessonToContainLog != nil) {
            if (totalFlightTime.text.length > 0 && dualGiven.text.length == 0) {
                dualGiven.text = totalFlightTime.text;
            }
        }
        if (editable == NO) {
            dualGiven.enabled = NO;
            dualGiven.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenLabel];
        [instructorLogView addSubview:dualGiven];
        logX += instructorWidth;
        
        // X-C DUAL GIVEN
        UILabel *xcDualGivenLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        xcDualGivenLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        xcDualGivenLabel.textAlignment = NSTextAlignmentCenter;
        xcDualGivenLabel.numberOfLines = 0;
        xcDualGivenLabel.text = @"X-C\nDUAL GIVEN";
        xcDualGivenLabel.layer.borderColor = [UIColor blackColor].CGColor;
        xcDualGivenLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoxcDualGiven = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoxcDualGiven setBackgroundColor:[UIColor clearColor]];
        btnAutoxcDualGiven.tag = 1528;
        [btnAutoxcDualGiven addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoxcDualGiven aboveSubview:xcDualGivenLabel];
        
        xcDualGiven = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        xcDualGiven.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        xcDualGiven.textAlignment = NSTextAlignmentCenter;
        xcDualGiven.textColor = userFieldColor;
        xcDualGiven.layer.borderColor = [UIColor blackColor].CGColor;
        xcDualGiven.layer.borderWidth = 1.0;
        xcDualGiven.keyboardType = UIKeyboardTypeNumberPad;
        xcDualGiven.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.xcDualGiven != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.xcDualGiven] == NO && [currentLogEntry.xcDualGiven floatValue] != 0) {
            xcDualGiven.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.xcDualGiven stringValue]];
        } else {
            xcDualGiven.text = @"";
        }
        if (editable == NO) {
            xcDualGiven.enabled = NO;
            xcDualGiven.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:xcDualGivenLabel];
        [instructorLogView addSubview:xcDualGiven];
        logX += instructorWidth;
        
        // DUAL GIVEN INSTRUMENT
        UILabel *dualGivenInstrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenInstrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenInstrumentLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenInstrumentLabel.numberOfLines = 0;
        dualGivenInstrumentLabel.text = @"DUAL GIVEN\nINSTRUMENT";
        dualGivenInstrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenInstrumentLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenInstrument = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGivenInstrument setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenInstrument.tag = 1529;
        [btnAutoDualGivenInstrument addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenInstrument aboveSubview:dualGivenInstrumentLabel];
        
        dualGivenInstrument = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenInstrument.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenInstrument.textAlignment = NSTextAlignmentCenter;
        dualGivenInstrument.textColor = userFieldColor;
        dualGivenInstrument.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenInstrument.layer.borderWidth = 1.0;
        dualGivenInstrument.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenInstrument.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenInstrument != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenInstrument] == NO && [currentLogEntry.dualGivenInstrument floatValue] != 0) {
            dualGivenInstrument.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenInstrument stringValue]];
        } else {
            dualGivenInstrument.text = @"";
        }
        if (editable == NO) {
            dualGivenInstrument.enabled = NO;
            dualGivenInstrument.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenInstrumentLabel];
        [instructorLogView addSubview:dualGivenInstrument];
        logX += instructorWidth;
        
        // DUAL GIVEN COMMERCIAL
        UILabel *dualGivenCommercialLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenCommercialLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenCommercialLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenCommercialLabel.numberOfLines = 0;
        dualGivenCommercialLabel.text = @"DUAL GIVEN\nCOMMERCIAL";
        dualGivenCommercialLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenCommercialLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutodualGivenCommercial = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutodualGivenCommercial setBackgroundColor:[UIColor clearColor]];
        btnAutodualGivenCommercial.tag = 1530;
        [btnAutodualGivenCommercial addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutodualGivenCommercial aboveSubview:dualGivenCommercialLabel];
        
        dualGivenCommercial = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenCommercial.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenCommercial.textAlignment = NSTextAlignmentCenter;
        dualGivenCommercial.textColor = userFieldColor;
        dualGivenCommercial.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenCommercial.layer.borderWidth = 1.0;
        dualGivenCommercial.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenCommercial.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenCommercial != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenCommercial] == NO && [currentLogEntry.dualGivenCommercial floatValue] != 0) {
            dualGivenCommercial.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenCommercial stringValue]];
        } else {
            dualGivenCommercial.text = @"";
        }
        if (editable == NO) {
            dualGivenCommercial.enabled = NO;
            dualGivenCommercial.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenCommercialLabel];
        [instructorLogView addSubview:dualGivenCommercial];
        logX += instructorWidth;
        
        // DUAL GIVEN CFI
        UILabel *dualGivenCFILabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenCFILabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenCFILabel.textAlignment = NSTextAlignmentCenter;
        dualGivenCFILabel.numberOfLines = 0;
        dualGivenCFILabel.text = @"DUAL GIVEN\nCFI";
        dualGivenCFILabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenCFILabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenCfi = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGivenCfi setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenCfi.tag = 1531;
        [btnAutoDualGivenCfi addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenCfi aboveSubview:dualGivenCFILabel];
        
        dualGivenCFI = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenCFI.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenCFI.textAlignment = NSTextAlignmentCenter;
        dualGivenCFI.textColor = userFieldColor;
        dualGivenCFI.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenCFI.layer.borderWidth = 1.0;
        dualGivenCFI.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenCFI.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenCFI != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenCFI] == NO && [currentLogEntry.dualGivenCFI floatValue] != 0) {
            dualGivenCFI.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenCFI stringValue]];
        } else {
            dualGivenCFI.text = @"";
        }
        if (editable == NO) {
            dualGivenCFI.enabled = NO;
            dualGivenCFI.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenCFILabel];
        [instructorLogView addSubview:dualGivenCFI];
        logX += instructorWidth;
        
        // DUAL GIVEN SPORT
        UILabel *dualGivenSportLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenSportLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenSportLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenSportLabel.numberOfLines = 0;
        dualGivenSportLabel.text = @"DUAL GIVEN\nSPORT";
        dualGivenSportLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenSportLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenSport = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGivenSport setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenSport.tag = 1532;
        [btnAutoDualGivenSport addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenSport aboveSubview:dualGivenSportLabel];
        
        dualGivenSport = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenSport.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenSport.textAlignment = NSTextAlignmentCenter;
        dualGivenSport.textColor = userFieldColor;
        dualGivenSport.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenSport.layer.borderWidth = 1.0;
        dualGivenSport.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenSport.delegate  =self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenSport != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenSport] == NO && [currentLogEntry.dualGivenSport floatValue] != 0) {
            dualGivenSport.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenSport stringValue]];
        } else {
            dualGivenSport.text = @"";
        }
        if (editable == NO) {
            dualGivenSport.enabled = NO;
            dualGivenSport.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenSportLabel];
        [instructorLogView addSubview:dualGivenSport];
        logX += instructorWidth;
        
        // DUAL GIVEN RECREATIONAL
        UILabel *dualGivenRecreationalLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenRecreationalLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenRecreationalLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenRecreationalLabel.numberOfLines = 0;
        dualGivenRecreationalLabel.text = @"DUAL GIVEN\nRECREAT";
        dualGivenRecreationalLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenRecreationalLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenRecreat = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGivenRecreat setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenRecreat.tag = 1533;
        [btnAutoDualGivenRecreat addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenRecreat aboveSubview:dualGivenRecreationalLabel];
        
        dualGivenRecreational = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenRecreational.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenRecreational.textAlignment = NSTextAlignmentCenter;
        dualGivenRecreational.textColor = userFieldColor;
        dualGivenRecreational.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenRecreational.layer.borderWidth = 1.0;
        dualGivenRecreational.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenRecreational.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenRecreational && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenRecreational] == NO && [currentLogEntry.dualGivenRecreational floatValue] != 0) {
            dualGivenRecreational.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenRecreational stringValue]];
        } else {
            dualGivenRecreational.text = @"";
        }
        if (editable == NO) {
            dualGivenRecreational.enabled = NO;
            dualGivenRecreational.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenRecreationalLabel];
        [instructorLogView addSubview:dualGivenRecreational];
        logX += instructorWidth;
        
        // DUAL GIVEN GLIDER
        UILabel *dualGivenGliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, instructorWidth + 1, 26)];
        dualGivenGliderLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenGliderLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenGliderLabel.numberOfLines = 0;
        dualGivenGliderLabel.text = @"DUAL GIVEN\nGLIDER";
        dualGivenGliderLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenGliderLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenGlider = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, instructorWidth+1, 36)];
        [btnAutoDualGivenGlider setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenGlider.tag = 1534;
        [btnAutoDualGivenGlider addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenGlider aboveSubview:dualGivenGliderLabel];
        
        dualGivenGlider = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, instructorWidth + 1, 25)];
        dualGivenGlider.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenGlider.textAlignment = NSTextAlignmentCenter;
        dualGivenGlider.textColor = userFieldColor;
        dualGivenGlider.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenGlider.layer.borderWidth = 1.0;
        dualGivenGlider.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenGlider.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenGlider != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenGlider] == NO && [currentLogEntry.dualGivenGlider floatValue] != 0) {
            dualGivenGlider.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenGlider stringValue]];
        } else {
            dualGivenGlider.text = @"";
        }
        if (editable == NO) {
            dualGivenGlider.enabled = NO;
            dualGivenGlider.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenGliderLabel];
        [instructorLogView addSubview:dualGivenGlider];
        logX += instructorWidth;
        
        // DUAL GIVEN OTHER
        int dualGivenOtherWidth = logRowWidth - logX;
        UILabel *dualGivenOtherLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 25, dualGivenOtherWidth, 26)];
        dualGivenOtherLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualGivenOtherLabel.textAlignment = NSTextAlignmentCenter;
        dualGivenOtherLabel.numberOfLines = 0;
        dualGivenOtherLabel.text = @"DUAL GIVEN\nOTHER";
        dualGivenOtherLabel.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenOtherLabel.layer.borderWidth = 1.0;
        
        UIButton *btnAutoDualGivenOther = [[UIButton alloc]  initWithFrame:CGRectMake(logX, 25, dualGivenOtherWidth, 36)];
        [btnAutoDualGivenOther setBackgroundColor:[UIColor clearColor]];
        btnAutoDualGivenOther.tag = 1535;
        [btnAutoDualGivenOther addTarget:self action:@selector(didSelectToAutoFillWithFlightTotal:) forControlEvents:UIControlEventTouchUpInside];
        [instructorLogView insertSubview:btnAutoDualGivenOther aboveSubview:dualGivenOtherLabel];
        
        dualGivenOther = [[UITextField alloc] initWithFrame:CGRectMake(logX, 50, dualGivenOtherWidth, 25)];
        dualGivenOther.font = [UIFont fontWithName:@"Noteworthy-Bold" size:12];
        dualGivenOther.textAlignment = NSTextAlignmentCenter;
        dualGivenOther.textColor = userFieldColor;
        dualGivenOther.layer.borderColor = [UIColor blackColor].CGColor;
        dualGivenOther.layer.borderWidth = 1.0;
        dualGivenOther.keyboardType = UIKeyboardTypeNumberPad;
        dualGivenOther.delegate = self;
        if (currentLogEntry != nil && currentLogEntry.dualGivenOther != nil && [[NSDecimalNumber notANumber] isEqualToValue:currentLogEntry.dualGivenOther] == NO && [currentLogEntry.dualGivenOther floatValue] != 0) {
            dualGivenOther.text = [self placeSpacesWithCurrentStringForDecimal:[currentLogEntry.dualGivenOther stringValue]];
        } else {
            dualGivenOther.text = @"";
        }
        if (editable == NO) {
            dualGivenOther.enabled = NO;
            dualGivenOther.textColor = [UIColor blackColor];
        }
        [instructorLogView addSubview:dualGivenOtherLabel];
        [instructorLogView addSubview:dualGivenOther];
        logX += dualGivenOtherWidth;
        
        [self addSubview:instructorLogView];
        y = y + 90;
        
        remarksLogView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 80)];
        remarksLogView.layer.borderColor = [UIColor blackColor].CGColor;
        remarksLogView.layer.borderWidth = 1.0;
        remarksLogView.backgroundColor = logBookBGColor;
        
        // REMARKS
        logX = 0;
        UILabel *remarksLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 26)];
        remarksLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        remarksLabel.textAlignment = NSTextAlignmentCenter;
        remarksLabel.numberOfLines = 0;
        remarksLabel.text = @"REMARKS";
        remarksLabel.layer.borderColor = [UIColor blackColor].CGColor;
        remarksLabel.layer.borderWidth = 1.0;
        
        remarks = [[UITextView alloc] initWithFrame:CGRectMake(logX, 25, logRowWidth, 55)];
        remarks.font = [UIFont fontWithName:@"Noteworthy-Bold" size:14];
        remarks.textAlignment = NSTextAlignmentCenter;
        remarks.textColor = userFieldColor;
        remarks.layer.borderColor = [UIColor blackColor].CGColor;
        remarks.layer.borderWidth = 1.0;
        remarks.backgroundColor = [UIColor clearColor];
        [remarks layoutIfNeeded];
        remarks.delegate = self;
        CGFloat heightOfRemarks = 55.0f;
        if (currentLogEntry != nil && currentLogEntry.remarks != nil && ![currentLogEntry.remarks isEqualToString:@""]) {
            NSString *currentLogRemarks = currentLogEntry.remarks;
            NSArray *parseRemarks = [currentLogRemarks componentsSeparatedByString:@" - "];
            if (parseRemarks.count > 1) {
                remarks.text = parseRemarks[1];
            }else{
                remarks.text = currentLogEntry.remarks;
            }
            heightOfRemarks = [self getHeightFromString:remarks.text withFont:[UIFont fontWithName:@"Noteworthy-Bold" size:14] withWidth:logRowWidth] + 20.0f;
        } else {
            remarks.text = @"";
        }
        [remarks setFrame:CGRectMake(logX, 25, logRowWidth, heightOfRemarks)];
        [remarksLogView setFrame:CGRectMake(25, y, logRowWidth, 25 + heightOfRemarks)];
        if (editable == NO) {
            remarks.editable = NO;
            remarks.textColor = [UIColor blackColor];
        }
        [remarksLogView addSubview:remarksLabel];
        [remarksLogView addSubview:remarks];
        
        [self addSubview:remarksLogView];
        y = y + 40 + heightOfRemarks;
        
        instructorSignatureView = [[UIView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 196)];
        instructorSignatureView.layer.borderColor = [UIColor blackColor].CGColor;
        instructorSignatureView.layer.borderWidth = 1.0;
        instructorSignatureView.backgroundColor = logBookBGColor;
        
        // signature
        logX = 0;
        UILabel *signatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(logX, 0, logRowWidth, 36)];
        signatureLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        signatureLabel.textAlignment = NSTextAlignmentCenter;
        signatureLabel.numberOfLines = 0;
        signatureLabel.text = @"FLIGHT SIGNOFF";
        signatureLabel.layer.borderColor = [UIColor blackColor].CGColor;
        signatureLabel.layer.borderWidth = 1.0;
        
        signatureByInstructorBtn = [[UIButton alloc] initWithFrame:CGRectMake(logX + 20, 46, logRowWidth - 370, 115)];
        [signatureByInstructorBtn addTarget:self action:@selector(onTapSignatureByIntructor) forControlEvents:UIControlEventTouchUpInside];
        
        if (currentLogEntry.instructorSignature != nil  && ![currentLogEntry.instructorSignature isEqualToString:@""]) {
            UIImage * signatureImage = [self decodeBase64ToImage:currentLogEntry.instructorSignature];
            [signatureByInstructorBtn setImage:signatureImage forState:UIControlStateNormal];
            [signatureByInstructorBtn setTitle:@"" forState:UIControlStateNormal];
            signatureByInstructorBtn.backgroundColor = [UIColor clearColor];
        } else {
            [signatureByInstructorBtn setImage:nil forState:UIControlStateNormal];
            if (editable == NO) {
                signatureByInstructorBtn.enabled = NO;
            }else{
                [signatureByInstructorBtn setTitle:@"Tap To Sign" forState:UIControlStateNormal];
                [signatureByInstructorBtn setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
                signatureByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
                signatureByInstructorBtn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                signatureByInstructorBtn.layer.cornerRadius = 10.0f;
            }
        }
        
        UIView *underlingOfSignature = [[UIView alloc] initWithFrame:CGRectMake(logX + 10, 166, logRowWidth - 350, 2)];
        [underlingOfSignature setBackgroundColor:[UIColor blackColor]];
        UILabel *lblInsSignature = [[UILabel alloc] initWithFrame:CGRectMake(logX + 10, 168, logRowWidth - 350, 30)];
        lblInsSignature.textAlignment = NSTextAlignmentCenter;
        lblInsSignature.font = [UIFont fontWithName:@"Helvetica" size:15];
        lblInsSignature.textColor = [UIColor blackColor];
        lblInsSignature.text = @"Instructor Signature";
        
        logX = logRowWidth - 320;
        certByInstructorBtn = [[UIButton alloc] initWithFrame:CGRectMake(logX + 20, 129, 280, 35)];
        [certByInstructorBtn addTarget:self action:@selector(onTapCertificateByIntructor) forControlEvents:UIControlEventTouchUpInside];
        if (currentLogEntry.instructorCertNo != nil  && ![currentLogEntry.instructorCertNo isEqualToString:@""]) {
            [certByInstructorBtn setTitle:currentLogEntry.instructorCertNo forState:UIControlStateNormal];
            certByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
            [certByInstructorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            certByInstructorBtn.backgroundColor = [UIColor clearColor];
        } else {
            if (editable == NO) {
                [certByInstructorBtn setTitle:@"" forState:UIControlStateNormal];
                certByInstructorBtn.enabled = NO;
            }else{
                [certByInstructorBtn setTitle:@"Tap To Enter No" forState:UIControlStateNormal];
                [certByInstructorBtn setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
                certByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
                certByInstructorBtn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                certByInstructorBtn.layer.cornerRadius = 10.0f;
            }
        }
        
        certByInsTextField = [[UITextField alloc] initWithFrame:CGRectMake(logX + 20, 111, 280, 50)];
        certByInsTextField.hidden = YES;
        certByInsTextField.delegate = self;
        certByInsTextField.textAlignment = NSTextAlignmentCenter;
        
        UIView *underlingOfCert = [[UIView alloc] initWithFrame:CGRectMake(logX + 10, 166, 300, 2)];
        [underlingOfCert setBackgroundColor:[UIColor blackColor]];
        UILabel *lblInsCert = [[UILabel alloc] initWithFrame:CGRectMake(logX + 10, 168, 300, 30)];
        lblInsCert.textAlignment = NSTextAlignmentCenter;
        lblInsCert.font = [UIFont fontWithName:@"Helvetica" size:15];
        lblInsCert.textColor = [UIColor blackColor];
        lblInsCert.text = @"Instructor Certificate No.";

        [instructorSignatureView addSubview:signatureLabel];
        [instructorSignatureView addSubview:signatureByInstructorBtn];
        [instructorSignatureView addSubview:underlingOfSignature];
        [instructorSignatureView addSubview:lblInsSignature];
        
        [instructorSignatureView addSubview:certByInstructorBtn];
        [instructorSignatureView addSubview:underlingOfCert];
        [instructorSignatureView addSubview:lblInsCert];
        [instructorSignatureView addSubview:certByInsTextField];
        
        [self addSubview:instructorSignatureView];
        y = y + 211;
        
        if (isTotalEntry) {
            self.contentSize = CGSizeMake(self.frame.size.width, y);
        }else{
            if (currentLogEntry.endorsements.count > 0) {
                endorsementOrignalCount = currentLogEntry.endorsements.count;
            }else{
                endorsementOrignalCount = 0;
            }
            
            EndorsementTableView = [[UITableView alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 280 * endorsementOrignalCount) style:UITableViewStylePlain];
            EndorsementTableView.scrollEnabled = NO;
            EndorsementTableView.separatorColor = [UIColor clearColor];
            EndorsementTableView.allowsSelection = NO;
            arrFlagToEditLog = [[NSMutableArray alloc] init];

            CGFloat calculatedHeightOfTable = 0;
            if (currentLogEntry.endorsements.count > 0) {
                for (Endorsement *oneEndorsement in currentLogEntry.endorsements) {
                    NSMutableDictionary *dictForFlagEditableOfLog = [[NSMutableDictionary alloc] init];
                    if (oneEndorsement.endorsementID == nil) {
                        [dictForFlagEditableOfLog setObject:@0 forKey:@"endorsementID"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.endorsementID forKey:@"endorsementID"];
                    }
                    if (oneEndorsement.text == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"text"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.text forKey:@"text"];
                    }
                    if (oneEndorsement.name == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"name"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.name forKey:@"name"];
                    }
                    if (oneEndorsement.cfiNumber == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"cfiNumber"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.cfiNumber forKey:@"cfiNumber"];
                    }
                    if (currentLogCfiNum && ![currentLogCfiNum isEqualToString:@""]) {
                        [dictForFlagEditableOfLog setObject:currentLogCfiNum forKey:@"cfiNumber"];
                    }
                    if (oneEndorsement.endorsementDate == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"endorsementDate"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.endorsementDate forKey:@"endorsementDate"];
                    }
                    if (oneEndorsement.endorsementExpDate == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"endorsementExpDate"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.endorsementExpDate forKey:@"endorsementExpDate"];
                    }
                    if (oneEndorsement.cfiSignature == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"cfiSignature"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.cfiSignature forKey:@"cfiSignature"];
                    }
                    if (oneEndorsement.isSupersed == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"isSupersed"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.isSupersed forKey:@"isSupersed"];
                    }
                    if (oneEndorsement.type == nil) {
                        [dictForFlagEditableOfLog setObject:@"" forKey:@"type"];
                    }else{
                        [dictForFlagEditableOfLog setObject:oneEndorsement.type forKey:@"type"];
                    }
                    [arrFlagToEditLog addObject:dictForFlagEditableOfLog];
                    
                    if (oneEndorsement && oneEndorsement.name && oneEndorsement.text && ![oneEndorsement.name isEqualToString:@""] && ![oneEndorsement.text isEqualToString:@""]) {
                         calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:oneEndorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableView.frame.size.width] + [self getHeightFromString:oneEndorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableView.frame.size.width] + 230.0f ;
                    }else{
                        calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
                    }
                    if ([oneEndorsement.cfiNumber isEqualToString:@""] || oneEndorsement.cfiNumber == nil) {
                        oneEndorsement.cfiNumber = currentLogCfiNum;
                        NSError *error;
                        [context save:&error];
                    }
                }
                
                CGRect tableRect = EndorsementTableView.frame;
                tableRect.size.height = calculatedHeightOfTable;
                EndorsementTableView.frame = tableRect;
            }
            
            EndorsementTableView.delegate = self;
            EndorsementTableView.dataSource = self;
            EndorsementTableView.backgroundColor = [UIColor clearColor];
            EndorsementTableView.clearsContextBeforeDrawing = YES;
            EndorsementTableView.userInteractionEnabled = YES;
            //[EndorsementTableView reloadData];
            [self addSubview:EndorsementTableView];
            
            y += calculatedHeightOfTable;
            
            
            addEndorsementFirst = [[UIButton alloc] initWithFrame:CGRectMake(25, y, logRowWidth, 50)];
            [addEndorsementFirst setTitle:@"+ Add Endorsement" forState:UIControlStateNormal];
            [addEndorsementFirst setFont:[UIFont fontWithName:@"Helvetica" size:15]];
            [addEndorsementFirst setBackgroundColor:[UIColor clearColor]];
            [addEndorsementFirst setTitleColor:[UIColor colorWithRed:5.0f/255.0f green:120.0f/255.0f blue:1.0f alpha:1.0f] forState:UIControlStateNormal];
            [addEndorsementFirst addTarget:self action:@selector(onAddedOneEndorsementFirst:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:addEndorsementFirst];
            y += 50.0f;
            addEndorsementFirst.hidden = YES;
            
            if (currentLogEntry.endorsements ==nil || currentLogEntry.endorsements.count == 0) {
                addEndorsementFirst.hidden = NO;
                if (editable == NO) {
                    addEndorsementFirst.hidden = YES;
                }
            }
            
            [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = y;
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
            self.contentSize = CGSizeMake(self.frame.size.width, y);
        }
    }
    return self;
}
- (CGFloat)getHeightFromString:(NSString*)strToHeight withFont:(UIFont *)font withWidth:(CGFloat)width{
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size;
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [strToHeight boundingRectWithSize:constraint
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:font}
                                                   context:context].size;
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    return size.height;
}
- (void)textFieldDidChange:(UITextField *)textField {
    NSRange range = [textField.text rangeOfString : @"-"];
    if (range.location != NSNotFound) {
        aircraftRegistration.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        flightRoute.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        aircraftModel.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    }
}

- (void)didSelectAircraftCategories{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    [self onShowViewToSelectFromPicker:1];
}

- (void)didSelectAirecraftClass{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    [self onShowViewToSelectFromPicker:2];
}
- (void)setDateFromDatePicker:(NSString *)_dateStr type:(NSInteger)_type withIndex:(NSInteger)index{
    isShownPickerView = NO;
    if (_type == 1) {
        NSMutableDictionary *endorsementToDate = [arrFlagToEditLog objectAtIndex:index];
        [endorsementToDate setObject:_dateStr forKey:@"endorsementDate"];
        [arrFlagToEditLog replaceObjectAtIndex:index withObject:endorsementToDate];
        [EndorsementTableView reloadData];
    }else if (_type == 2) {
        NSMutableDictionary *endorsementToDate = [arrFlagToEditLog objectAtIndex:index];
        [endorsementToDate setObject:_dateStr forKey:@"endorsementExpDate"];
        [arrFlagToEditLog replaceObjectAtIndex:index withObject:endorsementToDate];
        [EndorsementTableView reloadData];
    }else if (_type == 3){
        [logDate setTitle:_dateStr forState:UIControlStateNormal];
    }
}
- (void)setSignature:(UIImage *)signImage withIndex:(NSInteger)index{
    isShownPickerView = NO;
    if (index == -1) {
        [signatureByInstructorBtn setImage:signImage forState:UIControlStateNormal];
        [signatureByInstructorBtn setTitle:@"" forState:UIControlStateNormal];
        signatureByInstructorBtn.backgroundColor  =[UIColor clearColor];
    }else{
        NSMutableDictionary *endorsementToUpdateSignature = [arrFlagToEditLog objectAtIndex:index];
        [endorsementToUpdateSignature setObject:[self encodeToBase64String:signImage] forKey:@"cfiSignature"];
        [EndorsementTableView reloadData];
    }
}

-(void)onDatePickerValueChanged
{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showEndorsementDateView:3 withIndex:0];
    }
}

- (void)onTapSignatureByIntructor{
    [self.endorsementViewDelegate showEndorsementSignatureView:-1];

}
- (void)onTapCertificateByIntructor{
    certByInsTextField.hidden = NO;
    [certByInsTextField becomeFirstResponder];
}

- (void)save
{
    BOOL isInstructorOrStudent = YES;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        isInstructorOrStudent = YES;
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            if ([hobbsOut.text length] <= 0 && [hobbsIn.text length] <= 0) {
                FDLogDebug(@"Don't Save current logbook entry!");
                if (currentLogEntry.endorsements.count > 0) {
                    for (Endorsement *endorsement in currentLogEntry.endorsements ) {
                        [context deleteObject:endorsement];
                    }
                }
                if (currentLogEntry != nil) {
                    [context deleteObject:currentLogEntry];
                }
            }
            return;
        }
    }
    
    if (isTotalEntry) {
        if (currentLogEntry.endorsements.count > 0) {
            for (Endorsement *endorsement in currentLogEntry.endorsements ) {
                [context deleteObject:endorsement];
            }
        }
        if (currentLogEntry != nil) {
            [context deleteObject:currentLogEntry];
        }
        return;
    }
    
    NSString *hobbsOutString = hobbsOut.text;
    hobbsOutString = [hobbsOutString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *hobbsInString = hobbsIn.text;
    hobbsInString = [hobbsInString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSDecimalNumber *hobbsOutNumber = [NSDecimalNumber decimalNumberWithString:hobbsOutString];
    NSDecimalNumber *hobbsInNumber = [NSDecimalNumber decimalNumberWithString:hobbsInString];
    if (![hobbsOutNumber isEqualToNumber:[NSDecimalNumber notANumber]] && ![hobbsInNumber isEqualToNumber:[NSDecimalNumber notANumber]]) {
        NSDecimalNumber *totalTimeNumber = [hobbsInNumber decimalNumberBySubtracting:hobbsOutNumber];
        totalFlightTime.text = [self placeSpacesWithCurrentStringForDecimal:[NSString stringWithFormat:@"%@", totalTimeNumber]];
        if (lessonToContainLog != nil) {
            dualReceived.text = totalFlightTime.text;
            dualGiven.text = totalFlightTime.text;
        }
    }
    
    if ([hobbsOut.text length] <= 0 && [hobbsIn.text length] <= 0) {
        FDLogDebug(@"Don't Save current logbook entry!");
        if (currentLogEntry == nil) {
            return;
        }
    }
    
    if (currentLogEntry == nil) {
        currentLogEntry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
        // store the creation time
        currentLogEntry.creationDateTime = [NSDate date];
        currentLogEntry.log_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        // optional instructor
        if (currentInstructorID != nil) {
            currentLogEntry.instructorID = currentInstructorID;
        }
        // user
        if (currentUserID != nil) {
            currentLogEntry.userID = currentUserID;
        } else {
            // grab the current user's ID
            NSString *userIDKey = @"userId";
            NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
            NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
            if (userID == nil) {
                FDLogError(@"Unable parse log entries update without being logged in!");
            }
            currentLogEntry.userID = userID;
        }
        //}
    }
    
    FDLogDebug(@"Save current logbook entry!");
    NSError *error;
    // get the context
    
    // save any changes to the log entry
    if (currentLogEntry != nil) {
        // attempt to save each field if it is valid
        // Primary fields
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yyyy"];
        NSDate *nsLogDate = [dateFormat dateFromString:logDate.titleLabel.text];
        
        currentLogEntry.logDate = nsLogDate;
        if ([aircraftModel.text length] > 0) {
            currentLogEntry.aircraftModel = aircraftModel.text;
        } else {
            currentLogEntry.aircraftModel = @"";
        }
        if ([aircraftRegistration.text length] > 0) {
            currentLogEntry.aircraftRegistration = aircraftRegistration.text;
        } else {
            currentLogEntry.aircraftRegistration = @"";
        }
        if ([hobbsOut.text length] > 0) {
            currentLogEntry.hobbsOut = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:hobbsOut.text]];
        } else {
            currentLogEntry.hobbsOut = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([hobbsIn.text length] > 0) {
            currentLogEntry.hobbsIn = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:hobbsIn.text]];
        } else {
            currentLogEntry.hobbsIn = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([totalFlightTime.text length] > 0) {
        currentLogEntry.totalFlightTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:totalFlightTime.text]];
        } else {
            currentLogEntry.totalFlightTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([aircraftCategoryBtn.titleLabel.text length] > 0) {
            currentLogEntry.aircraftCategory = aircraftCategoryBtn.titleLabel.text;
        } else {
            currentLogEntry.aircraftCategory = @"";
        }
        if ([aircraftClassBtn.titleLabel.text length] > 0) {
            currentLogEntry.aircraftClass = aircraftClassBtn.titleLabel.text;
        } else {
            currentLogEntry.aircraftClass = @"";
        }
        if ([flightRoute.text length] > 0) {
            currentLogEntry.flightRoute = flightRoute.text;
        } else {
            currentLogEntry.flightRoute = @"";
        }
        if ([landingsDay.text length] > 0) {
            currentLogEntry.landingsDay = [NSNumber numberWithInt:[landingsDay.text intValue]];
        } else {
            currentLogEntry.landingsDay = @(0);
        }
        if ([landingsNight.text length] > 0) {
            currentLogEntry.landingsNight = [NSNumber numberWithInt:[landingsNight.text intValue]];
        } else {
            currentLogEntry.landingsNight = @(0);
        }
        
        // experience (conditions)
        if ([nightTime.text length] > 0) {
            currentLogEntry.nightTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:nightTime.text]];
        } else {
            currentLogEntry.nightTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([picTime.text length] > 0) {
            currentLogEntry.picTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:picTime.text]];
        } else {
            currentLogEntry.picTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([sicTime.text length] > 0) {
            currentLogEntry.sicTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:sicTime.text]];
        } else {
            currentLogEntry.sicTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([soloTime.text length] > 0) {
            currentLogEntry.soloTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:soloTime.text]];
        } else {
            currentLogEntry.soloTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([xcDayTime.text length] > 0) {
            currentLogEntry.xc = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcDayTime.text]];
        } else {
            currentLogEntry.xc = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([xcSolo.text length] > 0) {
            currentLogEntry.xcSolo = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcSolo.text]];
        } else {
            currentLogEntry.xcSolo = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([xcPIC.text length] > 0) {
            currentLogEntry.xcPIC = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcPIC.text]];
        } else {
            currentLogEntry.xcPIC = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([xcNightTime.text length] > 0) {
            currentLogEntry.xcNightTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcNightTime.text]];
        } else {
            currentLogEntry.xcNightTime = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        
        // experience (aircraft)
        if ([recreationalTime.text length] > 0) {
            currentLogEntry.recreational = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:recreationalTime.text]];
        } else {
            currentLogEntry.recreational = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([sportTime.text length] > 0) {
            currentLogEntry.sport = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:sportTime.text]];
        } else {
            currentLogEntry.sport = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([highPerfTime.text length] > 0) {
            currentLogEntry.highPerf = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:highPerfTime.text]];
        } else {
            currentLogEntry.highPerf = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([complexTime.text length] > 0) {
            currentLogEntry.complex = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:complexTime.text]];
        } else {
            currentLogEntry.complex = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([taildraggerTime.text length] > 0) {
            currentLogEntry.taildragger  = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:taildraggerTime.text]];
        } else {
            currentLogEntry.taildragger = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([gliderTime.text length] > 0) {
            currentLogEntry.glider = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:gliderTime.text]];
        } else {
            currentLogEntry.glider = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([ultraLightTime.text length] > 0) {
            currentLogEntry.ultraLight = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:ultraLightTime.text]];
        } else {
            currentLogEntry.ultraLight = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        if ([helicopterTime.text length] > 0) {
            currentLogEntry.helicopter = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:helicopterTime.text]];
        } else {
            currentLogEntry.helicopter = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([turbopropTime.text length] > 0) {
            currentLogEntry.turboprop = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:turbopropTime.text]];
        } else {
            currentLogEntry.turboprop = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
         if ([jetTime.text length] > 0) {
            currentLogEntry.jet = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:jetTime.text]];
        } else {
            currentLogEntry.jet = [NSDecimalNumber decimalNumberWithString:@"0"];
        }
        
        // Training
        if ([groundTime.text length] > 0) {
            currentLogEntry.groundTime = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:groundTime.text]];
        } else {
            currentLogEntry.groundTime = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualReceived.text length] > 0) {
            currentLogEntry.dualReceived = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualReceived.text]];
        } else {
            currentLogEntry.dualReceived = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([nightDualReceived.text length] > 0) {
            currentLogEntry.nightDualReceived = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:nightDualReceived.text]];
        } else {
            currentLogEntry.nightDualReceived = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([xcDualReceived.text length] > 0) {
            currentLogEntry.xcDualReceived = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcDualReceived.text]];
        } else {
            currentLogEntry.xcDualReceived = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([xcNightDualReceived.text length] > 0) {
            currentLogEntry.xcNightDualReceived = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcNightDualReceived.text]];
        } else {
            currentLogEntry.xcNightDualReceived = [NSDecimalNumber decimalNumberWithString:@""];
        }
        
        // Instrument fields
        if ([instrumentActual.text length] > 0) {
            currentLogEntry.instrumentActual = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:instrumentActual.text]];
        } else {
            currentLogEntry.instrumentActual = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([instrumentHood.text length] > 0) {
            currentLogEntry.instrumentHood = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:instrumentHood.text]];
        } else {
            currentLogEntry.instrumentHood = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([instrumentSim.text length] > 0) {
            currentLogEntry.instrumentSim = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:instrumentSim.text]];
        } else {
            currentLogEntry.instrumentSim = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([approachesCount.text length] > 0) {
            currentLogEntry.approachesCount = [NSNumber numberWithInt:[approachesCount.text intValue]];
        } else {
            currentLogEntry.approachesCount = @(0);
        }
        if ([approachesType.text length] > 0) {
            currentLogEntry.approachesType = approachesType.text;
        } else {
            currentLogEntry.approachesType = @"";
        }
        if ([holds.text length] > 0) {
            currentLogEntry.holds = [NSNumber numberWithInt:[holds.text intValue]];
        } else {
            currentLogEntry.holds = @(0);
        }
        if ([tracking.text length] > 0) {
            currentLogEntry.tracking = tracking.text;
        } else {
            currentLogEntry.tracking = @"";
        }
        
        // As instructor
        if ([dualGiven.text length] > 0) {
            currentLogEntry.dualGiven = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGiven.text]];
        } else {
            currentLogEntry.dualGiven = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([xcDualGiven.text length] > 0) {
            currentLogEntry.xcDualGiven = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:xcDualGiven.text]];
        } else {
            currentLogEntry.xcDualGiven = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenInstrument.text length] > 0) {
            currentLogEntry.dualGivenInstrument = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenInstrument.text]];
        } else {
            currentLogEntry.dualGivenInstrument = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenCommercial.text length] > 0) {
            currentLogEntry.dualGivenCommercial = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenCommercial.text]];
        } else {
            currentLogEntry.dualGivenCommercial = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenCFI.text length] > 0) {
            currentLogEntry.dualGivenCFI = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenCFI.text]];
        } else {
            currentLogEntry.dualGivenCFI = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenSport.text length] > 0) {
            currentLogEntry.dualGivenSport = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenSport.text]];
        } else {
            currentLogEntry.dualGivenSport = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenRecreational.text length] > 0) {
            currentLogEntry.dualGivenRecreational = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenRecreational.text]];
        } else {
            currentLogEntry.dualGivenRecreational = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenGlider.text length] > 0) {
            currentLogEntry.dualGivenGlider = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenGlider.text]];
        } else {
            currentLogEntry.dualGivenGlider = [NSDecimalNumber decimalNumberWithString:@""];
        }
        if ([dualGivenOther.text length] > 0) {
            currentLogEntry.dualGivenOther = [NSDecimalNumber decimalNumberWithString:[self getStringToRemovedSpaces:dualGivenOther.text]];
        } else {
            currentLogEntry.dualGivenOther = [NSDecimalNumber decimalNumberWithString:@""];
        }
        
        // Remarks
        if ([remarks.text length] > 0) {
            NSString *nameOfLessongroup = @"";
            NSString *lessonNumber = @"";
            if (lessonToContainLog != nil) {
                if (lessonToContainLog.lessonGroup.parentGroup != nil) {
                    nameOfLessongroup = lessonToContainLog.lessonGroup.parentGroup.name;
                }else{
                    nameOfLessongroup = lessonToContainLog.lessonGroup.name;
                }
                lessonNumber = [lessonToContainLog.lessonNumber stringValue];
            }else if (currentLogEntry.logLessonRecord.lesson != nil){
                if (currentLogEntry.logLessonRecord.lesson.lessonGroup.parentGroup != nil) {
                    nameOfLessongroup = currentLogEntry.logLessonRecord.lesson.lessonGroup.parentGroup.name;
                }else{
                    nameOfLessongroup = currentLogEntry.logLessonRecord.lesson.lessonGroup.name;
                }
                lessonNumber = [currentLogEntry.logLessonRecord.lesson.lessonNumber stringValue];
            }
            NSArray *parseLessonGroupName = [nameOfLessongroup componentsSeparatedByString:@" "];
            NSString *abbreviationName = @"";
            for (int i = 0; i < parseLessonGroupName.count; i ++) {
                if (![parseLessonGroupName[i] isEqualToString:@""]) {
                    abbreviationName = [NSString stringWithFormat:@"%@%@", abbreviationName, [[parseLessonGroupName[i] substringToIndex:1] uppercaseString]];
                }
            }
            if (![abbreviationName isEqualToString:@""]) {
                currentLogEntry.remarks = [NSString stringWithFormat:@"%@:L%@ - %@", abbreviationName, lessonNumber, remarks.text];
            }else{
                currentLogEntry.remarks = remarks.text;
            }
        } else {
            currentLogEntry.remarks = @"";
        }
        
        if (signatureByInstructorBtn.currentImage != nil) {
            UIImage *signatureImg = signatureByInstructorBtn.currentImage;
            currentLogEntry.instructorSignature =  [self encodeToBase64String:signatureImg];
        } else {
            currentLogEntry.instructorSignature = @"";
        }
        if ([certByInstructorBtn.titleLabel.text length] > 0 && ![certByInstructorBtn.titleLabel.text isEqualToString:@"Tap To Enter No"]) {
            currentLogEntry.instructorCertNo = certByInstructorBtn.titleLabel.text;
        } else {
            currentLogEntry.instructorCertNo = @"";
        }
        if (currentLogEntry.endorsements.count > 0) {
            for (Endorsement *endorsementToDelete in currentLogEntry.endorsements) {
                [currentLogEntry removeEndorsementsObject:endorsementToDelete];
                [context deleteObject:endorsementToDelete];
            }
        }
        for (NSDictionary *oneEndorsementToInsert in arrFlagToEditLog) {
            Endorsement *endorsementToInit = [NSEntityDescription insertNewObjectForEntityForName:@"Endorsement" inManagedObjectContext:context];
            endorsementToInit.endorsementID = [oneEndorsementToInsert objectForKey:@"endorsementID"];
            endorsementToInit.text = [oneEndorsementToInsert objectForKey:@"text"];
            endorsementToInit.name = [oneEndorsementToInsert objectForKey:@"name"];
            endorsementToInit.cfiNumber = [oneEndorsementToInsert objectForKey:@"cfiNumber"];
            endorsementToInit.endorsementDate = [oneEndorsementToInsert objectForKey:@"endorsementDate"];
            endorsementToInit.endorsementExpDate = [oneEndorsementToInsert objectForKey:@"endorsementExpDate"];
            endorsementToInit.cfiSignature = [oneEndorsementToInsert objectForKey:@"cfiSignature"];
            endorsementToInit.isSupersed = [oneEndorsementToInsert objectForKey:@"isSupersed"];
            endorsementToInit.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            endorsementToInit.lastUpdate = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            endorsementToInit.endorsement_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            endorsementToInit.type = [oneEndorsementToInsert objectForKey:@"type"];
            [currentLogEntry addEndorsementsObject:endorsementToInit];
        }
        [arrFlagToEditLog removeAllObjects];//avoid to be duplicated issue
        currentLogEntry.lastUpdate = @(0);
        currentLogEntry.valueForSort = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        
        if (lessonToContainLog != nil) {
            currentLogEntry.lessonId = lessonToContainLog.lessonID;
            currentLogEntry.studentUserID = lessonToContainLog.studentUserID;
        }
        
    }
    // save changes to disk
    [context save:&error];
    // save changes to web server
}
- (NSString *)getStringToRemovedSpaces:(NSString *)_spaceStr{
    return [_spaceStr stringByReplacingOccurrencesOfString:@" " withString:@""];
}
- (NSString *)placeSpacesWithCurrentStringForDecimal:(NSString *)_noSpaceStr{
    return [_noSpaceStr stringByReplacingOccurrencesOfString:@"." withString:@" .  "];
}
- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}

-(LogEntry*)getCurrentEntry
{
    return currentLogEntry;
}

#pragma mark UITextFieldDelegate
-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == hobbsIn || textField == hobbsOut) {
        NSString *hobbsOutString = hobbsOut.text;
        hobbsOutString = [hobbsOutString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSString *hobbsInString = hobbsIn.text;
        hobbsInString = [hobbsInString stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSDecimalNumber *hobbsOutNumber = [NSDecimalNumber decimalNumberWithString:hobbsOutString];
        NSDecimalNumber *hobbsInNumber = [NSDecimalNumber decimalNumberWithString:hobbsInString];
        if (![hobbsOutNumber isEqualToNumber:[NSDecimalNumber notANumber]] && ![hobbsInNumber isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [hobbsInNumber decimalNumberBySubtracting:hobbsOutNumber];
            totalFlightTime.text = [self placeSpacesWithCurrentStringForDecimal:[NSString stringWithFormat:@"%@", totalTimeNumber]];
            if (lessonToContainLog != nil) {
                dualReceived.text = totalFlightTime.text;
                dualGiven.text = totalFlightTime.text;
            }
        }
    }else if(textField == certByInsTextField){
        certByInsTextField.hidden = YES;
        if (certByInsTextField.text.length > 0){
            [certByInstructorBtn setTitle:certByInsTextField.text forState:UIControlStateNormal];
            certByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
            [certByInstructorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            certByInstructorBtn.backgroundColor = [UIColor clearColor];
        }else{
            [certByInstructorBtn setTitle:@"Tap To Enter No" forState:UIControlStateNormal];
            [certByInstructorBtn setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
            certByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
            certByInstructorBtn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
            certByInstructorBtn.layer.cornerRadius = 10.0f;
        }
        certByInsTextField.text = @"";
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == aircraftModel) {
        [aircraftRegistration becomeFirstResponder];
    }else if (textField == aircraftRegistration) {
        [hobbsOut becomeFirstResponder];
    }else if (textField == hobbsOut) {
        [hobbsIn becomeFirstResponder];
    }else if (textField == hobbsIn) {
        [flightRoute becomeFirstResponder];
    }else if (textField == flightRoute) {
        [landingsDay becomeFirstResponder];
    }else if (textField == landingsDay) {
        [landingsNight becomeFirstResponder];
    }else if (textField == landingsNight) {
        [nightTime becomeFirstResponder];
    }else if (textField == nightTime) {
        [picTime becomeFirstResponder];
    }else if (textField == picTime) {
        [sicTime becomeFirstResponder];
    }else if (textField == sicTime) {
        [soloTime becomeFirstResponder];
    }else if (textField == soloTime) {
        [xcDayTime becomeFirstResponder];
    }else if (textField == xcDayTime) {
        [xcSolo becomeFirstResponder];
    }else if (textField == xcSolo) {
        [xcPIC becomeFirstResponder];
    }else if (textField == xcPIC) {
        [xcNightTime becomeFirstResponder];
    }else if (textField == xcNightTime) {
        [recreationalTime becomeFirstResponder];
    }else if (textField == recreationalTime) {
        [sportTime becomeFirstResponder];
    }else if (textField == sportTime) {
        [highPerfTime becomeFirstResponder];
    }else if (textField == highPerfTime) {
        [complexTime becomeFirstResponder];
    }else if (textField == complexTime) {
        [taildraggerTime becomeFirstResponder];
    }else if (textField == taildraggerTime) {
        [gliderTime becomeFirstResponder];
    }else if (textField == gliderTime) {
        [ultraLightTime becomeFirstResponder];
    }else if (textField == ultraLightTime) {
        [helicopterTime becomeFirstResponder];
    }else if (textField == helicopterTime) {
        [turbopropTime becomeFirstResponder];
    }else if (textField == turbopropTime) {
        [jetTime becomeFirstResponder];
    }else if (textField == jetTime) {
        [groundTime becomeFirstResponder];
    }else if (textField == groundTime) {
        [dualReceived becomeFirstResponder];
    }else if (textField == dualReceived) {
        [nightDualReceived becomeFirstResponder];
    }else if (textField == nightDualReceived) {
        [xcDualReceived becomeFirstResponder];
    }else if (textField == xcDualReceived) {
        [xcNightDualReceived becomeFirstResponder];
    }else if (textField == xcNightDualReceived) {
        [instrumentActual becomeFirstResponder];
    }else if (textField == instrumentActual) {
        [instrumentHood becomeFirstResponder];
    }else if (textField == instrumentHood) {
        [instrumentSim becomeFirstResponder];
    }else if (textField == instrumentSim) {
        [approachesCount becomeFirstResponder];
    }else if (textField == approachesCount) {
        [approachesType becomeFirstResponder];
    }else if (textField == approachesType) {
        [holds becomeFirstResponder];
    }else if (textField == holds) {
        [tracking becomeFirstResponder];
    }else if (textField == tracking) {
        [dualGiven becomeFirstResponder];
    }else if (textField == dualGiven) {
        [xcDualGiven becomeFirstResponder];
    }else if (textField == xcDualGiven) {
        [dualGivenInstrument becomeFirstResponder];
    }else if (textField == dualGivenInstrument) {
        [dualGivenCommercial becomeFirstResponder];
    }else if (textField == dualGivenCommercial) {
        [dualGivenCFI becomeFirstResponder];
    }else if (textField == dualGivenCFI) {
        [dualGivenSport becomeFirstResponder];
    }else if (textField == dualGivenSport) {
        [dualGivenRecreational becomeFirstResponder];
    }else if (textField == dualGivenRecreational) {
        [dualGivenGlider becomeFirstResponder];
    }else if (textField == dualGivenGlider) {
        [dualGivenOther becomeFirstResponder];
    }else if (textField == dualGivenOther) {
        [remarks becomeFirstResponder];
    }else if (textField == certByInsTextField) {
        [self endEditing:YES];
    }
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == certByInsTextField) {
        certByInsTextField.returnKeyType = UIReturnKeyDone;
        [certByInstructorBtn setTitle:@"" forState:UIControlStateNormal];
        certByInstructorBtn.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:17];
        [certByInstructorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        certByInstructorBtn.backgroundColor = [UIColor clearColor];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == hobbsOut || textField == hobbsIn || textField == landingsDay || textField == landingsNight || textField == nightTime || textField == picTime || textField == sicTime || textField == soloTime || textField == xcDayTime || textField == xcSolo || textField == xcPIC || textField == xcNightTime || textField == recreationalTime || textField == sportTime || textField == highPerfTime || textField == complexTime || textField == taildraggerTime || textField == gliderTime || textField == ultraLightTime || textField == helicopterTime || textField == turbopropTime || textField == jetTime || textField == groundTime || textField == dualReceived || textField == nightDualReceived || textField == xcDualReceived || textField == xcNightDualReceived || textField == instrumentActual || textField == instrumentHood || textField == instrumentSim || textField == approachesCount || textField == holds || textField == tracking || textField == dualGiven || textField == xcDualGiven || textField == dualGivenInstrument || textField == dualGivenCommercial || textField == dualGivenCFI || textField == dualGivenSport || textField == dualGivenRecreational || textField == dualGivenGlider || textField == dualGivenOther) {
        BOOL valid = NO;
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        for (int i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if ([myCharSet characterIsMember:c]) {
                valid = YES;
            }
        }
        
        if (!valid && range.length != 1){
            return NO;
        }
    }
    
    NSString *text = @"";
    if ([string isEqualToString:@"."]) {
        if ([textField.text rangeOfString:@"."].location != NSNotFound){
            return NO;
        }
        
        BOOL isEmpty = NO;
        if ([textField.text stringByReplacingOccurrencesOfString:@" " withString:@""].length == 0) {
            isEmpty = YES;
        }
        text = [textField.text stringByReplacingCharactersInRange:range withString:@" .  "];
        if (isEmpty) {
            text = [NSString stringWithFormat:@"0%@", text];
        }
        if (textField == hobbsOut) {
            hobbsOut.text = text;
        }else if (textField == hobbsIn) {
            hobbsIn.text = text;
        }else if (textField == landingsDay) {
            landingsDay.text = text;
        }else if (textField == landingsNight) {
            landingsNight.text = text;
        }else if (textField == nightTime) {
            nightTime.text = text;
        }else if (textField == picTime) {
            picTime.text = text;
        }else if (textField == sicTime) {
            sicTime.text = text;
        }else if (textField == soloTime) {
            soloTime.text = text;
        }else if (textField == xcDayTime) {
            xcDayTime.text = text;
        }else if (textField == xcSolo) {
            xcSolo.text = text;
        }else if (textField == xcPIC) {
            xcPIC.text = text;
        }else if (textField == xcNightTime) {
            xcNightTime.text = text;
        }else if (textField == recreationalTime) {
            recreationalTime.text = text;
        }else if (textField == sportTime) {
            sportTime.text = text;
        }else if (textField == highPerfTime) {
            highPerfTime.text = text;
        }else if (textField == complexTime) {
            complexTime.text = text;
        }else if (textField == taildraggerTime) {
            taildraggerTime.text = text;
        }else if (textField == gliderTime) {
            gliderTime.text = text;
        }else if (textField == ultraLightTime) {
            ultraLightTime.text = text;
        }else if (textField == helicopterTime) {
            helicopterTime.text = text;
        }else if (textField == turbopropTime) {
            turbopropTime.text = text;
        }else if (textField == jetTime) {
            jetTime.text = text;
        }else if (textField == groundTime) {
            groundTime.text = text;
        }else if (textField == dualReceived) {
            dualReceived.text = text;
        }else if (textField == nightDualReceived) {
            nightDualReceived.text = text;
        }else if (textField == xcDualReceived) {
            xcDualReceived.text = text;
        }else if (textField == xcNightDualReceived) {
            xcNightDualReceived.text = text;
        }else if (textField == instrumentActual) {
            instrumentActual.text = text;
        }else if (textField == instrumentHood) {
            instrumentHood.text = text;
        }else if (textField == instrumentSim) {
            instrumentSim.text = text;
        }else if (textField == approachesCount) {
            approachesCount.text = text;
        }else if (textField == holds) {
            holds.text = text;
        }else if (textField == tracking) {
            tracking.text = text;
        }else if (textField == dualGiven) {
            dualGiven.text = text;
        }else if (textField == xcDualGiven) {
            xcDualGiven.text = text;
        }else if (textField == dualGivenInstrument) {
            dualGivenInstrument.text = text;
        }else if (textField == dualGivenCommercial) {
            dualGivenCommercial.text = text;
        }else if (textField == dualGivenCFI) {
            dualGivenCFI.text = text;
        }else if (textField == dualGivenSport) {
            dualGivenSport.text = text;
        }else if (textField == dualGivenRecreational) {
            dualGivenRecreational.text = text;
        }else if (textField == dualGivenGlider) {
            dualGivenGlider.text = text;
        }else if (textField == dualGivenOther) {
            dualGivenOther.text = text;
        }
        
        return NO;
    }
    
    return YES;
}


#pragma mark UITextViewDelegate
-(void)textViewDidBeginEditing:(UITextView *)textView{
//    if (textView == endorsementCategoriesTxtView) {
//        if ([endorsementCategoriesTxtView.text isEqualToString:@"+ Add Endorsement"]) {
//            [self onShowViewToSelectFromPicker:3];
//            [self endEditing:YES];
//        }
//    }
}
- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == remarks){
        CGFloat fixedWidth = textView.frame.size.width;
        CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = textView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
        textView.frame = newFrame;
        
        CGRect remarksLogViewFrame = remarksLogView.frame;
        remarksLogViewFrame.size.height = 25.0f + newFrame.size.height;
        [remarksLogView setFrame:remarksLogViewFrame];
        
        CGRect instructorSignatureViewFrame = instructorSignatureView.frame;
        instructorSignatureViewFrame.origin.y = remarksLogViewFrame.origin.y + 50.0f + newFrame.size.height;
        [instructorSignatureView setFrame:instructorSignatureViewFrame];
        
        CGRect endorsementTableViewFrame = EndorsementTableView.frame;
        endorsementTableViewFrame.origin.y = instructorSignatureViewFrame.origin.y + 211;
        [EndorsementTableView setFrame:endorsementTableViewFrame];
        
        CGRect addEndorsementFirstFrame = addEndorsementFirst.frame;
        addEndorsementFirstFrame.origin.y = endorsementTableViewFrame.origin.y;
        [addEndorsementFirst setFrame:addEndorsementFirstFrame];
        
        self.contentSize = CGSizeMake(self.frame.size.width, endorsementTableViewFrame.origin.y + endorsementTableViewFrame.size.height + 50.0f);
        
        [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = self.contentSize.height;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
    }
}
- (void)onShowViewToSelectFromPicker:(NSInteger)type{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showPickerViewToSelectItem:type  withIndex:0];
    }
}
- (void)setCurrentItemFromPicker:(NSString *)componentStr withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index{
    isShownPickerView = NO;
    if (_type == 1) {
        [aircraftCategoryBtn setTitle:componentStr forState:UIControlStateNormal];
        [self endEditing:YES];
    }else if(_type == 2){
        [aircraftClassBtn setTitle:componentStr forState:UIControlStateNormal];
        [self endEditing:YES];
    }else if(_type == 3){
        NSMutableDictionary *endorsementToUpdateText = [arrFlagToEditLog objectAtIndex:index];
        [endorsementToUpdateText setObject:componentStr forKey:@"name"];
        [endorsementToUpdateText setObject:_text forKey:@"text"];
        [arrFlagToEditLog replaceObjectAtIndex:index withObject:endorsementToUpdateText];
        
        CGFloat heightToCancel = 280.0f;
        if (![[endorsementToUpdateText objectForKey:@"name"] isEqualToString:@""] && ![[endorsementToUpdateText objectForKey:@"text"] isEqualToString:@""]) {
            heightToCancel = [self getHeightFromString:[endorsementToUpdateText objectForKey:@"name"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableView.frame.size.width] + [self getHeightFromString:[endorsementToUpdateText objectForKey:@"text"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableView.frame.size.width] + 230.0f ;
        }
        
        [EndorsementTableView setFrame:CGRectMake(25, EndorsementTableView.frame.origin.y, self.bounds.size.width-50, [self getHeightOfEndorsementTableView:arrFlagToEditLog])];
        [self setContentSize:CGSizeMake(self.frame.size.width, self.contentSize.height +  heightToCancel - 280)];
        
        [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = self.contentSize.height;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
        
        
        [EndorsementTableView reloadData];
    }
}
- (void)ableToShowOtherView{
    isShownPickerView = NO;
}

#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [arrFlagToEditLog count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   NSMutableDictionary *endorsementDict = [arrFlagToEditLog objectAtIndex:indexPath.row];
    if (![[endorsementDict objectForKey:@"name"] isEqualToString:@""] && ![[endorsementDict objectForKey:@"text"] isEqualToString:@""]) {
        return [self getHeightFromString:[endorsementDict objectForKey:@"name"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableView.frame.size.width] + [self getHeightFromString:[endorsementDict objectForKey:@"text"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableView.frame.size.width] + 230.0f ;
    }else{
        return 280.0f;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *simpleTableIdentifier = @"EndorsementItem";
    LogEndorsementCell *cell = (LogEndorsementCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [LogEndorsementCell sharedCell];
    }
    cell.backgroundColor = cell.contentView.backgroundColor;
    cell.endorsementDelegate = self;
    NSMutableDictionary *endorsementDict = [arrFlagToEditLog objectAtIndex:indexPath.row];
    
    if (indexPath.row == arrFlagToEditLog.count-1) {
        cell.btnAdditionalEndorsement.hidden = NO;
    }else{
        cell.btnAdditionalEndorsement.hidden = YES;
    }
    
    cell.endorsementTxtView.delegate = cell;
    cell.endorsementTxtView.textAlignment = NSTextAlignmentLeft;
    if (![[endorsementDict objectForKey:@"name"] isEqualToString:@""] && ![[endorsementDict objectForKey:@"text"] isEqualToString:@""]) {
        cell.btnAddEndorsement.hidden = YES;
        cell.btnChangeEndorsement.hidden = NO;
        UIFont *text1Font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
        NSMutableAttributedString *attributedString1 =
        [[NSMutableAttributedString alloc] initWithString:[endorsementDict objectForKey:@"name"] attributes:@{ NSFontAttributeName : text1Font }];
        NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle1 setLineSpacing:4];
        [attributedString1 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, [attributedString1 length])];
        
        UIFont *text2Font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        NSMutableAttributedString *attributedString2 =
        [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@", [endorsementDict objectForKey:@"text"]] attributes:@{NSFontAttributeName : text2Font }];
        NSMutableParagraphStyle *paragraphStyle2 = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle2 setLineSpacing:4];
        [attributedString2 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle2 range:NSMakeRange(0, [attributedString2 length])];
        
        [attributedString1 appendAttributedString:attributedString2];
        [cell.endorsementTxtView setAttributedText:attributedString1];
    }else{
        [cell.endorsementTxtView setText:@""];
        cell.btnAddEndorsement.hidden = NO;
        cell.btnChangeEndorsement.hidden = YES;
    }
    
    if (![[endorsementDict objectForKey:@"cfiSignature"] isEqualToString:@""]) {
        UIImage * signatureImage = [self decodeBase64ToImage:[endorsementDict objectForKey:@"cfiSignature"]];
        [cell.btnSingature setImage:signatureImage forState:UIControlStateNormal];
        cell.btnSingature.backgroundColor = [UIColor clearColor];
        [cell.btnSingature setTitle:@"" forState:UIControlStateNormal];
    } else {
        [cell.btnSingature setImage:nil forState:UIControlStateNormal];
        [cell.btnSingature setTitle:@"Tap to Sign" forState:UIControlStateNormal];
        [cell.btnSingature setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
        cell.btnSingature.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
        cell.btnSingature.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
        cell.btnSingature.layer.cornerRadius = 10.0f;
    }
    
    if (![[endorsementDict objectForKey:@"endorsementDate"] isEqualToString:@""]) {
        [cell.btnEndorsementDate setTitle:[endorsementDict objectForKey:@"endorsementDate"] forState:UIControlStateNormal];
        [cell.btnEndorsementDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        cell.btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        cell.btnEndorsementDate.backgroundColor = [UIColor clearColor];
    } else {
        [cell.btnEndorsementDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
        [cell.btnEndorsementDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
        cell.btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        cell.btnEndorsementDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
        cell.btnEndorsementDate.layer.cornerRadius = 10.0f;
    }
    
    if (![[endorsementDict objectForKey:@"cfiNumber"] isEqualToString:@""]) {
        cell.lblCFINumber.text = [endorsementDict objectForKey:@"cfiNumber"];
    }else{
        cell.lblCFINumber.text = @"";
    }
    
    if (![[endorsementDict objectForKey:@"endorsementExpDate"] isEqualToString:@""]) {
        [cell.btnEndorsementExpDate setTitle:[endorsementDict objectForKey:@"endorsementExpDate"] forState:UIControlStateNormal];
        [cell.btnEndorsementExpDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        cell.btnEndorsementExpDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        cell.btnEndorsementExpDate.backgroundColor = [UIColor clearColor];
    } else {
        [cell.btnEndorsementExpDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
        [cell.btnEndorsementExpDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
        cell.btnEndorsementExpDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        cell.btnEndorsementExpDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
        cell.btnEndorsementExpDate.layer.cornerRadius = 10.0f;
    }
    if ([[endorsementDict objectForKey:@"isSupersed"] integerValue] == 1) {
        cell.supersedMaskView.hidden = NO;
        cell.btnSuporsed.hidden = YES;
        cell.btnCancel.hidden = YES;
        cell.btnChangeEndorsement.hidden = YES;
    }else{
        cell.supersedMaskView.hidden = YES;
    }
    if ([[endorsementDict objectForKey:@"text"] isEqualToString:@""]) {
        cell.endorsementTxtView.editable = YES;
    }else{
        cell.btnChangeEndorsement.hidden = YES;
    }
    if ([[endorsementDict objectForKey:@"cfiSignature"] isEqualToString:@""]) {
        cell.btnSingature.enabled = YES;
    }else{
    }
    if ([[endorsementDict objectForKey:@"endorsementDate"]  isEqualToString:@""]) {
        cell.btnEndorsementDate.enabled = YES;
    }else{
    }
    if ([[endorsementDict objectForKey:@"endorsementExpDate"]  isEqualToString:@""]) {
        cell.btnEndorsementExpDate.enabled = YES;
    }else{
    }
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            cell.btnAddEndorsement.hidden = YES;
            cell.btnSuporsed.hidden = YES;
            cell.btnCancel.hidden = YES;
            cell.btnAdditionalEndorsement.hidden = YES;
        }
    }
    if ([[endorsementDict objectForKey:@"endorsementID"] integerValue] != 0) {
        cell.btnCancel.hidden = YES;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark LogEndorsementCellDelegate
-(void)didSignatureWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showEndorsementSignatureView:indexpath.row];
    }
}

-(void)didEndorsementDateWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showEndorsementDateView:1 withIndex:indexpath.row];
    }
}

-(void)didEndorsementExpDateWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showEndorsementDateView:2 withIndex:indexpath.row];
    }
}
- (void)didCancelEndorsementWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    NSMutableDictionary *endorsementToDelete = [arrFlagToEditLog objectAtIndex:indexpath.row];
    if ([[endorsementToDelete objectForKey:@"endorsementID"] integerValue] != 0) {
        DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
        deleteQuery.type = @"logbook_endorsement";
        deleteQuery.idToDelete = [endorsementToDelete objectForKey:@"endorsementID"];
    }
    CGFloat heightToCancel = 280.0f;
    [arrFlagToEditLog removeObjectAtIndex:indexpath.row];
    
    if (![[endorsementToDelete objectForKey:@"name"] isEqualToString:@""] && ![[endorsementToDelete objectForKey:@"text"] isEqualToString:@""]) {
        heightToCancel = [self getHeightFromString:[endorsementToDelete objectForKey:@"name"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableView.frame.size.width] + [self getHeightFromString:[endorsementToDelete objectForKey:@"text"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableView.frame.size.width] + 230.0f ;
    }
    
    [EndorsementTableView setFrame:CGRectMake(25, EndorsementTableView.frame.origin.y, self.bounds.size.width-50, [self getHeightOfEndorsementTableView:arrFlagToEditLog])];
    
    [self setContentSize:CGSizeMake(self.frame.size.width, self.contentSize.height -heightToCancel)];
    if (arrFlagToEditLog.count == 0) {
        [self setContentSize:CGSizeMake(self.frame.size.width, 1011.0f)];
        CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
        [self setContentOffset:bottomOffset animated:YES];
        EndorsementTableView.hidden = YES;
        addEndorsementFirst.hidden = NO;
    }
    
    [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = self.contentSize.height;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
    [EndorsementTableView reloadData];
}
-(void)didAdditionalEndorsementWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSMutableDictionary *endorsementEelement = [[NSMutableDictionary alloc] init];
    [endorsementEelement setObject:@0 forKey:@"endorsementID"];
    [endorsementEelement setObject:@"" forKey:@"text"];
    [endorsementEelement setObject:@"" forKey:@"name"];
    if (currentLogCfiNum && ![currentLogCfiNum isEqualToString:@""]) {
        [endorsementEelement setObject:currentLogCfiNum forKey:@"cfiNumber"];
    }else{
        [endorsementEelement setObject:@"" forKey:@"cfiNumber"];
    }
    [endorsementEelement setObject:@"" forKey:@"endorsementDate"];
    [endorsementEelement setObject:@"" forKey:@"endorsementExpDate"];
    [endorsementEelement setObject:@"" forKey:@"cfiSignature"];
    [endorsementEelement setObject:@0 forKey:@"isSupersed"];
    [endorsementEelement setObject:@1 forKey:@"type"];
    
    [arrFlagToEditLog addObject:endorsementEelement];
    
    [EndorsementTableView setFrame:CGRectMake(25, EndorsementTableView.frame.origin.y, self.bounds.size.width-50, [self getHeightOfEndorsementTableView:arrFlagToEditLog])];
    [self setContentSize:CGSizeMake(self.frame.size.width, self.contentSize.height + 280)];
    CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
    [self setContentOffset:bottomOffset animated:YES];
    [EndorsementTableView reloadData];
    
    [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = self.contentSize.height;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
}

-(void)didAddEndorsementWithCell:(LogEndorsementCell *)cell{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    if (!isShownPickerView) {
        isShownPickerView = YES;
        [self.endorsementViewDelegate showPickerViewToSelectItem:3 withIndex:indexpath.row];
    }
}

-(void)didSupersedWithCell:(LogEndorsementCell *)cell withFlag:(BOOL)isFlag{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Are you sure you want to \"Superseded\" this endorsement? This cannot be undone!" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             
                             NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
                             NSMutableDictionary *endorsementWithCell = [arrFlagToEditLog objectAtIndex:indexpath.row];
                             if (cell.supersedMaskView.hidden) {
                                 [endorsementWithCell setObject:@1 forKey:@"isSupersed"];
                             }else{
                                 [endorsementWithCell setObject:@0 forKey:@"isSupersed"];
                             }
                             
                             [arrFlagToEditLog replaceObjectAtIndex:indexpath.row withObject:endorsementWithCell];
                             [EndorsementTableView reloadData];
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                             {
                             }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

-(void)didEndEditingWithTextView:(LogEndorsementCell *)cell withText:(NSString *)_text{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    NSIndexPath *indexpath = [EndorsementTableView indexPathForCell:cell];
    NSMutableDictionary *endorsementWithCell = [arrFlagToEditLog objectAtIndex:indexpath.row];
    NSArray *arrParseEndorsement = [_text componentsSeparatedByString:@".\n\n "];
    if (arrParseEndorsement.count < 2) {
        NSLog(@"failed");
    }else{
        [endorsementWithCell setObject:arrParseEndorsement[0] forKey:@"name"];
        [endorsementWithCell setObject:arrParseEndorsement[1] forKey:@"text"];
    }
    [arrFlagToEditLog replaceObjectAtIndex:indexpath.row withObject:endorsementWithCell];
    
    [EndorsementTableView reloadData];
}
- (void)didSelectToAutoFillWithFlightTotal:(UIButton *)sender{
    if (totalFlightTime.text.length == 0) {
        return;
    }
    switch (sender.tag) {
        case 1501:{//EXPERIENCE1 - NITE
                nightTime.text = totalFlightTime.text;
            break;
        }
        case 1502:{//EXPERIENCE1 - PIC
            picTime.text = totalFlightTime.text;
            break;
        }
        case 1503:{//EXPERIENCE1 - SIC
            sicTime.text = totalFlightTime.text;
            break;
        }
        case 1504:{//EXPERIENCE1 - SOLO
            soloTime.text = totalFlightTime.text;
            break;
        }
        case 1505:{//EXPERIENCE1 - X-C
            xcDayTime.text = totalFlightTime.text;
            break;
        }
        case 1506:{//EXPERIENCE1 - X-C SOLO
            xcSolo.text = totalFlightTime.text;
            break;
        }
        case 1507:{//EXPERIENCE1 - X-C PIC
            xcPIC.text = totalFlightTime.text;
            break;
        }
        case 1508:{//EXPERIENCE1 - X-C NITE
            xcNightTime.text = totalFlightTime.text;
            break;
        }
        case 1509:{//EXPERIENCE2 - REC
            recreationalTime.text = totalFlightTime.text;
            break;
        }
        case 1510:{//EXPERIENCE2 - SPORT
            sportTime.text = totalFlightTime.text;
            break;
        }
        case 1511:{//EXPERIENCE2 - HI-PERF
            highPerfTime.text = totalFlightTime.text;
            break;
        }
        case 1512:{//EXPERIENCE2 - CMPLX
            complexTime.text = totalFlightTime.text;
            break;
        }
        case 1513:{//EXPERIENCE2 - TAIL
            taildraggerTime.text = totalFlightTime.text;
            break;
        }
        case 1514:{//EXPERIENCE2 - GLIDE
            gliderTime.text = totalFlightTime.text;
            break;
        }
        case 1515:{//EXPERIENCE2 - ULGHT
            ultraLightTime.text = totalFlightTime.text;
            break;
        }
        case 1516:{//EXPERIENCE2 - HELO
            helicopterTime.text = totalFlightTime.text;
            break;
        }
        case 1517:{//EXPERIENCE2 - TPROP
            turbopropTime.text = totalFlightTime.text;
            break;
        }
        case 1518:{//EXPERIENCE2 - JET
            jetTime.text = totalFlightTime.text;
            break;
        }
        case 1519:{//TRAINING - GRND RCVD
            groundTime.text = totalFlightTime.text;
            break;
        }
        case 1520:{//TRAINING - DUAL RCVD
            dualReceived.text = totalFlightTime.text;
            break;
        }
        case 1521:{//TRAINING - NITE DUAL RCVD
            nightDualReceived.text = totalFlightTime.text;
            break;
        }
        case 1522:{//TRAINING - XC DUAL RCVD
            xcDualReceived.text = totalFlightTime.text;
            break;
        }
        case 1523:{//TRAINING - XC NITE DUAL RCVD
            xcNightDualReceived.text = totalFlightTime.text;
            break;
        }
        case 1524:{//INSTRUMENT - ACTUAL
            instrumentActual.text = totalFlightTime.text;
            break;
        }
        case 1525:{//INSTRUMENT - HOOD
            instrumentHood.text = totalFlightTime.text;
            break;
        }
        case 1526:{//INSTRUMENT - SIM
            instrumentSim.text = totalFlightTime.text;
            break;
        }
        case 1527:{//AS INSTRUCTOR - DUAL GIVEN
            dualGiven.text = totalFlightTime.text;
            break;
        }
        case 1528:{//AS INSTRUCTOR - X-C DUAL GIVEN
            xcDualGiven.text = totalFlightTime.text;
            break;
        }
        case 1529:{//AS INSTRUCTOR - X-C DUAL INSTRUMENT
            dualGivenInstrument.text = totalFlightTime.text;
            break;
        }
        case 1530:{//AS INSTRUCTOR - DUAL GIVEN COMMERCIAL
            dualGivenCommercial.text = totalFlightTime.text;
            break;
        }
        case 1531:{//AS INSTRUCTOR - DUAL GIVEN CFI
            dualGivenCFI.text = totalFlightTime.text;
            break;
        }
        case 1532:{//AS INSTRUCTOR - DUAL GIVEN SPORT
            dualGivenSport.text = totalFlightTime.text;
            break;
        }
        case 1533:{//AS INSTRUCTOR - DUAL GIVEN RECREAT
            dualGivenRecreational.text = totalFlightTime.text;
            break;
        }
        case 1534:{//AS INSTRUCTOR - DUAL GIVEN GLIDER
            dualGivenGlider.text = totalFlightTime.text;
            break;
        }
        case 1535:{//AS INSTRUCTOR - DUAL GIVEN OTHER
            dualGivenOther.text = totalFlightTime.text;
            break;
        }
        default:
            break;
    }
    
}
- (void)onAddedOneEndorsementFirst:(UIButton *)sender{
    addEndorsementFirst.hidden = YES;
    EndorsementTableView.hidden = NO;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
    }else{
        if (lessonToContainLog == nil || (currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.lesson == nil)) {
        }else{
            return;
        }
    }
    
    NSMutableDictionary *endorsementEelement = [[NSMutableDictionary alloc] init];
    [endorsementEelement setObject:@0 forKey:@"endorsementID"];
    [endorsementEelement setObject:@"" forKey:@"text"];
    [endorsementEelement setObject:@"" forKey:@"name"];
    [endorsementEelement setObject:@"" forKey:@"endorsementDate"];
    [endorsementEelement setObject:@"" forKey:@"endorsementExpDate"];
    if (currentLogCfiNum && ![currentLogCfiNum isEqualToString:@""]) {
        [endorsementEelement setObject:currentLogCfiNum forKey:@"cfiNumber"];
    }else{
        [endorsementEelement setObject:@"" forKey:@"cfiNumber"];
    }
    [endorsementEelement setObject:@"" forKey:@"cfiSignature"];
    [endorsementEelement setObject:@0 forKey:@"isSupersed"];
    [endorsementEelement setObject:@1 forKey:@"type"];
    
    [arrFlagToEditLog addObject:endorsementEelement];
    
    [EndorsementTableView setFrame:CGRectMake(25, EndorsementTableView.frame.origin.y, self.bounds.size.width-50, [self getHeightOfEndorsementTableView:arrFlagToEditLog])];
    [self setContentSize:CGSizeMake(self.frame.size.width, self.contentSize.height + 280)];
    CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
    [self setContentOffset:bottomOffset animated:YES];
    [EndorsementTableView reloadData];
    
    
    [AppDelegate sharedDelegate].heightCurrentLogBookToUpdate = self.contentSize.height;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil userInfo:nil];
}
- (CGFloat)getHeightOfEndorsementTableView:(NSMutableArray *)currentLog{
    CGFloat calculatedHeightOfTable = 0;
    for (NSDictionary *endorsementDic in currentLog) {
        if (![[endorsementDic objectForKey:@"name"] isEqualToString:@""] && ![[endorsementDic objectForKey:@"text"] isEqualToString:@""]) {
            calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:[endorsementDic objectForKey:@"name"] withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableView.frame.size.width] + [self getHeightFromString:[endorsementDic objectForKey:@"text"]  withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableView.frame.size.width] + 230.0f ;
        }else{
            calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
        }
    }
    return calculatedHeightOfTable;
}
@end
