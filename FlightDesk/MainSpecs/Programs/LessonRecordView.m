//
//  LessonRecordView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 4/11/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "LessonRecordView.h"
#import "FlightDesk-Swift.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "Student+CoreDataClass.h"
#import "LogEntry+CoreDataClass.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "LogbookRecordView.h"


// structure to store info on content
@interface ContentInfo : NSObject

@property Content *content;
@property M13Checkbox *contentItem;
@property UITextView *contentRemarks;

@end

@implementation ContentInfo

@synthesize content;
@synthesize contentItem;
@synthesize contentRemarks;

@end

@implementation LessonRecordView
{
    Lesson *currentLesson;
    UITextField *updateDate;
    UITextView *instructorNotes;
    UITextView *flightInstructorNotes;
    
    UITextView *studentNotes;
    UITextView *flightStudentNotes;
    
    NSMutableArray *groundContent;
    NSMutableArray *flightContent;
    // log book fields
    UITextField *flightDate;
    UIDatePicker *flightDatePicker;
    UITextField *totalFlightTime;
    UITextField *dualFlightTime;
    UITextField *soloFlightTime;
    UITextField *picFlightTime;
    UITextField *dualXCFlightTime;
    UITextField *soloXCFlightTime;
    UITextField *picXCFlightTime;
    UITextField *nightFlightTime;
    UITextField *simInstrumentTime;
    UITextField *hoodInstrumentTime;
    UITextField *actInstrumentTime;
    UITextField *dayTakeoffsLandings;
    UITextField *nightTakeoffsLandings;
    UITextField *hobbsOut;
    UITextField *hobbsIn;
    UITextField *hiPer; // TODO: make this a checkbox
    UITextField *route;
    UITextField *remarks;
    UITextField *numberOfApproaches;
    UITextField *approachesType;
    UITextField *holds;
    UITextField *navTrack;
    
    UIView *viewToContainLogBook;
    
    NSLayoutConstraint *viewToContrainLogBookHeightAnchor;
    NSLayoutConstraint *viewBottomAnchor;
}

@synthesize userFieldColor;
@synthesize placeholderFieldColor;

@synthesize logBookView;

// called from 550, the user ID is for the logged in user
- (NSLayoutYAxisAnchor*)addContent:(Content*)content currentUserID:(NSNumber *)userID withDepth:(int)depth andPlaceholderAttrs:(NSDictionary*)placeholderAttrs withTopAnchor:(NSLayoutYAxisAnchor*)topAnchor
{
    ContentInfo *contentInfo = [[ContentInfo alloc] init];
    contentInfo.content = content;
    NSLayoutYAxisAnchor *result;
    NSLayoutXAxisAnchor *remarksLeading;
    if ([content.hasCheck boolValue] == YES) {
        // add content with check boxes
        M13Checkbox *contentItem = [[M13Checkbox alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
        if (content.record != nil && content.record.completed != nil && [content.record.completed boolValue] == YES)
        {
            //[contentItem setCheckState:M13CheckboxStateChecked];
            [contentItem set_IBCheckState:@"Checked"];
        }
        contentInfo.contentItem = contentItem;
        contentItem.tintColor = self.userFieldColor;
        contentItem.secondaryTintColor = self.userFieldColor;
        if ([currentLesson.studentUserID intValue] == [userID intValue]) {
            contentItem.enabled = NO;
            if ([contentItem._IBCheckState  isEqualToString:@"Checked"]) {
                contentItem.tintColor = [UIColor greenColor];
                contentItem.secondaryTintColor = [UIColor greenColor];
                contentItem.secondaryCheckmarkTintColor = [UIColor greenColor];
            }else{
                contentItem.tintColor = [UIColor blackColor];
                contentItem.secondaryTintColor = [UIColor blackColor];
                contentItem.secondaryCheckmarkTintColor = [UIColor blackColor];
            }
            //contentItem.strokeColor = [UIColor blackColor];
            //contentItem.checkColor =  [UIColor blackColor];
        }
        contentItem.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:contentItem];
        
        UILabel *contentItemLabel = [[UILabel alloc] init];
        contentItemLabel.font = [UIFont fontWithName:@"Helvetica" size:16];
        contentItemLabel.text = content.name;
        contentItemLabel.textColor = [UIColor blackColor];
        contentItemLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:contentItemLabel];
        
        [contentItem.topAnchor constraintEqualToAnchor:topAnchor constant:15.0].active = YES;
        [contentItemLabel.topAnchor constraintEqualToAnchor:topAnchor constant:17.0].active = YES;
        [contentItem.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0 + (depth * 20.0)].active = YES;
        [contentItem.heightAnchor constraintEqualToConstant:25.0].active = YES;
        [contentItem.widthAnchor constraintEqualToConstant:25.0].active = YES;
        [contentItemLabel.leadingAnchor constraintEqualToAnchor:contentItem.trailingAnchor constant:10.0].active = YES;
        result = contentItem.bottomAnchor;
        remarksLeading = contentItem.leadingAnchor;
    } else {
        // add static label content
        UILabel *contentItem = [[UILabel alloc] init];
        contentInfo.contentItem = nil;
        contentItem.font = [UIFont fontWithName:@"Helvetica-Oblique" size:16];
        contentItem.text = content.name;
        contentItem.textColor = [UIColor blackColor];
        contentItem.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:contentItem];
        
        [contentItem.topAnchor constraintEqualToAnchor:topAnchor constant:10.0].active = YES;
        [contentItem.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0 + (depth * 20.0)].active = YES;
        result = contentItem.bottomAnchor;
        remarksLeading = contentItem.leadingAnchor;
    }
    if ([content.hasRemarks boolValue] == YES) {
        UITextView *contentRemarks = [[UITextView alloc] init];
        contentRemarks.delegate = self;
        if (content.record != nil && content.record.remarks != nil) {
            contentRemarks.text = content.record.remarks;
        }else{
            contentRemarks.text = @"Remarks";
        }
        contentInfo.contentRemarks = contentRemarks;
        contentRemarks.font = [UIFont fontWithName:@"Noteworthy-Bold" size:16];
        if ([currentLesson.studentUserID intValue] == [userID intValue]) {
            contentRemarks.editable = NO;
            //contentRemarks.textColor = [UIColor blackColor];
            contentRemarks.textColor = [UIColor colorWithRed:189.0f/255.0f green:110.0f/255.0f blue:2.0f/255.0f alpha:1];
        } else {
            //contentRemarks.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Remarks" attributes:placeholderAttrs];
            //contentRemarks.textColor = self.userFieldColor;
            contentRemarks.textColor = [UIColor orangeColor];
        }
        contentRemarks.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:contentRemarks];
        
        [contentRemarks.topAnchor constraintEqualToAnchor:result constant:5.0].active = YES;
        [contentRemarks.leadingAnchor constraintEqualToAnchor:remarksLeading].active = YES;
        [contentRemarks.heightAnchor constraintEqualToConstant:35.0].active = YES;
        [contentRemarks.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        result = contentRemarks.bottomAnchor;
    } else {
        contentInfo.contentRemarks = nil;
    }
    [flightContent addObject:contentInfo];
    return result;
}

- (id)initWithLesson:(Lesson*)lesson;
{
    self = [super init];
    if (self) {
        BOOL isInstructorOrStudent = YES;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            isInstructorOrStudent = YES;
        }else{
            isInstructorOrStudent = NO;
        }
        //self.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        self.userFieldColor = [UIColor colorWithRed:0.02 green:0.47 blue:1 alpha:1];
        //self.placeholderFieldColor = [UIColor colorWithRed:0.03 green:0.53 blue:1 alpha:1];
        self.placeholderFieldColor = [UIColor orangeColor];
        
        NSDictionary *placeholderAttrs = @{
                                           NSForegroundColorAttributeName: self.placeholderFieldColor,
                                           NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Oblique" size:14.0]
                                           };
        
        currentLesson = lesson;
        groundContent = [[NSMutableArray alloc] init];
        flightContent = [[NSMutableArray alloc] init];
        
        // grab the current user's ID
        NSString *userIDKey = @"userId";
        NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
        NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to modify lessons without being logged in!");
            userID = [NSNumber numberWithInt:[currentLesson.studentUserID intValue]];
        }
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Lesson header
        UIView *headerView = [[UIView alloc] init];
        headerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:headerView];
        [headerView.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:1.0 constant:-20.0].active = YES;
        [headerView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10.0].active = YES;
        [headerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        
        //lesson title
        UILabel *title = [[UILabel alloc] init];
        title.font = [UIFont fontWithName:@"Helvetica-Bold" size:36];
        title.text = [NSString stringWithFormat:@"Lesson %@", [lesson.lessonNumber stringValue]];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:title];
        
        [title.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:10.0].active = YES;
        [title.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor].active = YES;
        
        UILabel *aatdLessonLabel = [[UILabel alloc] init];
        aatdLessonLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
        aatdLessonLabel.text = lesson.title;
        aatdLessonLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:aatdLessonLabel];

        [aatdLessonLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10.0].active = YES;
        [aatdLessonLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor].active = YES;

        UIView *minimumsView = [[UIView alloc] init];
        minimumsView.translatesAutoresizingMaskIntoConstraints  = NO;
        
        UILabel *minimumReqLabel = [[UILabel alloc] init];
        minimumReqLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        minimumReqLabel.text = @"Minimum Requirements:";
        minimumReqLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:minimumReqLabel];
        
        [minimumReqLabel.leadingAnchor constraintEqualToAnchor:minimumsView.leadingAnchor].active = YES;
        [minimumReqLabel.topAnchor constraintEqualToAnchor:minimumsView.topAnchor constant:10.0].active = YES;
        
        // dual requirements
        UILabel *dualRequirementsLabel = [[UILabel alloc] init];
        dualRequirementsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualRequirementsLabel.text = @"Dual:";
        dualRequirementsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:dualRequirementsLabel];
        
        [dualRequirementsLabel.leadingAnchor constraintEqualToAnchor:minimumReqLabel.trailingAnchor constant:10.0].active = YES;
        [dualRequirementsLabel.topAnchor constraintEqualToAnchor:minimumReqLabel.topAnchor].active = YES;
        
        // dual flight
        UILabel *dualFlightRequired = [[UILabel alloc] init];
        dualFlightRequired.font = [UIFont fontWithName:@"Helvetica" size:10];
        dualFlightRequired.text=lesson.minDual;
        dualFlightRequired.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:dualFlightRequired];
        
        UILabel *dualFlightRequiredLabel = [[UILabel alloc] init];
        dualFlightRequiredLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualFlightRequiredLabel.text = @"Flight";
        dualFlightRequiredLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:dualFlightRequiredLabel];
        
        [dualFlightRequired.trailingAnchor constraintEqualToAnchor:dualFlightRequiredLabel.leadingAnchor constant:-10.0].active = YES;
        [dualFlightRequired.topAnchor constraintEqualToAnchor:minimumReqLabel.topAnchor].active = YES;
        
        [dualFlightRequiredLabel.leadingAnchor constraintEqualToAnchor:dualRequirementsLabel.trailingAnchor constant:50.0].active = YES;
        [dualFlightRequiredLabel.topAnchor constraintEqualToAnchor:minimumReqLabel.topAnchor].active = YES;
        
        // dual instrument
        UILabel *dualInstrumentRequired = [[UILabel alloc] init];
        dualInstrumentRequired.font = [UIFont fontWithName:@"Helvetica" size:10];
        dualInstrumentRequired.text=lesson.minInstrument;
        dualInstrumentRequired.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:dualInstrumentRequired];
        
        UILabel *dualInstrumentRequiredLabel = [[UILabel alloc] init];
        dualInstrumentRequiredLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        dualInstrumentRequiredLabel.text = @"Instrument";
        dualInstrumentRequiredLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:dualInstrumentRequiredLabel];
        
        [dualInstrumentRequired.trailingAnchor constraintEqualToAnchor:dualFlightRequired.trailingAnchor].active = YES;
        [dualInstrumentRequired.topAnchor constraintEqualToAnchor:dualFlightRequired.bottomAnchor constant:5.0].active = YES;
        
        [dualInstrumentRequiredLabel.leadingAnchor constraintEqualToAnchor:dualFlightRequiredLabel.leadingAnchor].active = YES;
        [dualInstrumentRequiredLabel.topAnchor constraintEqualToAnchor:dualInstrumentRequired.topAnchor].active = YES;
        
        // dual ground
        UILabel *groundRequired = [[UILabel alloc] init];
        groundRequired.font = [UIFont fontWithName:@"Helvetica" size:10];
        groundRequired.backgroundColor=[UIColor whiteColor];
        groundRequired.text=lesson.minGround;
        groundRequired.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:groundRequired];
        
        UILabel *groundRequiredLabel = [[UILabel alloc] init];
        groundRequiredLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        groundRequiredLabel.text = @"Ground";
        groundRequiredLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:groundRequiredLabel];
        
        [groundRequired.trailingAnchor constraintEqualToAnchor:dualInstrumentRequired.trailingAnchor].active = YES;
        [groundRequired.topAnchor constraintEqualToAnchor:dualInstrumentRequired.bottomAnchor constant:5.0].active = YES;
        
        [groundRequiredLabel.leadingAnchor constraintEqualToAnchor:dualFlightRequiredLabel.leadingAnchor].active = YES;
        [groundRequiredLabel.topAnchor constraintEqualToAnchor:groundRequired.topAnchor].active = YES;
        
        // solo flight
        UILabel *soloRequirementsLabel = [[UILabel alloc] init];
        soloRequirementsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        soloRequirementsLabel.text = @"Solo:";
        soloRequirementsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:soloRequirementsLabel];
        
        UILabel *soloFlightRequired = [[UILabel alloc] init];
        soloFlightRequired.font = [UIFont fontWithName:@"Helvetica" size:10];
        soloFlightRequired.text=lesson.minSolo;
        soloFlightRequired.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:soloFlightRequired];
        UILabel *soloFlightRequiredLabel = [[UILabel alloc] init];
        soloFlightRequiredLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        soloFlightRequiredLabel.text = @"Flight";
        soloFlightRequiredLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [minimumsView addSubview:soloFlightRequiredLabel];
        
        [soloRequirementsLabel.leadingAnchor constraintEqualToAnchor:dualRequirementsLabel.leadingAnchor].active = YES;
        [soloRequirementsLabel.topAnchor constraintEqualToAnchor:soloFlightRequired.topAnchor].active = YES;
        
        [soloFlightRequired.trailingAnchor constraintEqualToAnchor:groundRequired.trailingAnchor].active = YES;
        [soloFlightRequired.topAnchor constraintEqualToAnchor:groundRequired.bottomAnchor constant:5.0].active = YES;
        
        [soloFlightRequiredLabel.leadingAnchor constraintEqualToAnchor:dualFlightRequiredLabel.leadingAnchor].active = YES;
        [soloFlightRequiredLabel.topAnchor constraintEqualToAnchor:soloFlightRequired.topAnchor].active = YES;
        
        [headerView addSubview:minimumsView];
        
        [minimumsView.topAnchor constraintEqualToAnchor:aatdLessonLabel.bottomAnchor constant:5.0].active = YES;
        [minimumsView.leadingAnchor constraintEqualToAnchor:aatdLessonLabel.leadingAnchor].active = YES;
        
        // participants frame
        UIView *headerRightView = [[UIView alloc] init];
        headerRightView.layer.borderColor = [UIColor blackColor].CGColor;
        headerRightView.layer.borderWidth = 1.0;
        headerRightView.translatesAutoresizingMaskIntoConstraints  = NO;
        
        // client
        UILabel *clientLabel = [[UILabel alloc] init];
        clientLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        clientLabel.text = @"Client:";
        clientLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:clientLabel];
        
        UITextField *clientName = [[UITextField alloc] init];
        clientName.font = [UIFont fontWithName:@"Helvetica" size:18];
        clientName.backgroundColor=[UIColor whiteColor];
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
            NSError *error;
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", lesson.studentUserID];
            [request setPredicate:predicate];
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects == nil) {
                //FDLogError(@"Unable to retrieve lessons!");
            } else if (objects.count == 0) {
                //FDLogDebug(@"No valid Student found!");
            } else {
                if (objects.count > 0) {
                    Student *student  = objects[0];
                    clientName.text = [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
                }
            }
            
        }
        else{
            if ([[AppDelegate sharedDelegate].clientMiddleName isEqualToString:@""]) {
                clientName.text = [NSString stringWithFormat:@"%@ %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName];
            }else{
                clientName.text = [NSString stringWithFormat:@"%@ %@ %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientMiddleName, [AppDelegate sharedDelegate].clientLastName];
            }
        }
        
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            clientName.enabled = NO;
            clientName.textColor = [UIColor blackColor];
        } else {
            clientName.textColor = self.userFieldColor;
        }
        clientName.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:clientName];
        
        [clientLabel.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor constant:10.0].active = YES;
        [clientLabel.topAnchor constraintEqualToAnchor:headerRightView.topAnchor constant:10.0].active = YES;
        
        [clientName.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor constant:120.0].active = YES;
        [clientName.topAnchor constraintEqualToAnchor:headerRightView.topAnchor constant:10.0].active = YES;
        
        // instructor
        UILabel *instructorLabel = [[UILabel alloc] init];
        instructorLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        instructorLabel.text = @"Instructor:";
        instructorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorLabel];
        UITextField *instructorName = [[UITextField alloc] init];
        instructorName.font = [UIFont fontWithName:@"Helvetica" size:18];
        instructorName.backgroundColor=[UIColor whiteColor];
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            if ([[AppDelegate sharedDelegate].clientMiddleName isEqualToString:@""]) {
                instructorName.text = [NSString stringWithFormat:@"%@ %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName];
            }else{
                instructorName.text = [NSString stringWithFormat:@"%@ %@ %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientMiddleName, [AppDelegate sharedDelegate].clientLastName];
            }
        }
        else{
            instructorName.text = currentLesson.lessonGroup.instructorName;
        }
        
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            instructorName.enabled = NO;
            instructorName.textColor = [UIColor blackColor];
        } else {
            instructorName.textColor = self.userFieldColor;
        }
        instructorName.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorName];
        
        [instructorLabel.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor constant:10.0].active = YES;
        [instructorLabel.topAnchor constraintEqualToAnchor:clientLabel.bottomAnchor constant:10.0].active = YES;
        
        [instructorName.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor constant:120.0].active = YES;
        [instructorName.topAnchor constraintEqualToAnchor:clientLabel.bottomAnchor constant:10.0].active = YES;
        
        UILabel *instructorCertLabel = [[UILabel alloc] init];
        instructorCertLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        
        instructorCertLabel.text = @"Instructor Cert. No.:";
        
        instructorCertLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorCertLabel];

        UITextField *instructorCert = [[UITextField alloc] init];
        instructorCert.font = [UIFont fontWithName:@"Helvetica" size:10];
        instructorCert.backgroundColor=[UIColor whiteColor];
        //instructorCert.text=@"12345678-A";
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            instructorCert.text = [NSString stringWithFormat:@"%@", [AppDelegate sharedDelegate].pilotCert];
        }
        else{
            instructorCert.text = [NSString stringWithFormat:@"%@", currentLesson.lessonGroup.instructorPilotCert];
        }
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            instructorCert.enabled = NO;
            instructorCert.textColor = [UIColor blackColor];
        } else {
            instructorCert.textColor = self.userFieldColor;
        }
        instructorCert.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorCert];
        
        UILabel *instructorCertExpLabel = [[UILabel alloc] init];
        instructorCertExpLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
        instructorCertExpLabel.text = @"Exp:";
        instructorCertExpLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorCertExpLabel];
        
        UITextField *instructorCertExp = [[UITextField alloc] init];
        instructorCertExp.font = [UIFont fontWithName:@"Helvetica" size:10];
        instructorCertExp.backgroundColor=[UIColor whiteColor];
        
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM/dd/yyyy"];
            NSDate *updatedNSDate = [dateFormat dateFromString:[AppDelegate sharedDelegate].cfiCertExpDate];
            [dateFormat setDateFormat:@"MM/yy"];
            instructorCertExp.text = [dateFormat stringFromDate:updatedNSDate];
        }
        else{
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM/dd/yyyy"];
            NSDate *updatedNSDate = [dateFormat dateFromString:currentLesson.lessonGroup.instructorCfiCertExpDate];
            [dateFormat setDateFormat:@"MM/yy"];
            instructorCertExp.text = [dateFormat stringFromDate:updatedNSDate];
        }
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            instructorCertExp.enabled = NO;
            instructorCertExp.textColor = [UIColor blackColor];
        } else {
            instructorCertExp.textColor = self.userFieldColor;
        }
        instructorCertExp.translatesAutoresizingMaskIntoConstraints = NO;
        [headerRightView addSubview:instructorCertExp];
        
        [instructorCertLabel.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor constant:10.0].active = YES;
        [instructorCertLabel.topAnchor constraintEqualToAnchor:instructorLabel.bottomAnchor constant:10.0].active = YES;
        
        [instructorCert.leadingAnchor constraintEqualToAnchor:instructorCertLabel.trailingAnchor constant:10.0].active = YES;
        [instructorCert.topAnchor constraintEqualToAnchor:instructorCertLabel.topAnchor].active = YES;
        
        [instructorCertExpLabel.leadingAnchor constraintEqualToAnchor:instructorCert.trailingAnchor constant:10.0].active = YES;
        [instructorCertExpLabel.topAnchor constraintEqualToAnchor:instructorCertLabel.topAnchor].active = YES;
        
        [instructorCertExp.leadingAnchor constraintEqualToAnchor:instructorCertExpLabel.trailingAnchor constant:10.0].active = YES;
        [instructorCertExp.topAnchor constraintEqualToAnchor:instructorCertLabel.topAnchor].active = YES;
        
        [headerRightView.bottomAnchor constraintEqualToAnchor:instructorCertLabel.bottomAnchor constant:10.0].active = YES;
        
        [headerView addSubview:headerRightView];
        
        [headerRightView.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:10.0].active = YES;
        [headerRightView.leadingAnchor constraintEqualToAnchor:headerView.centerXAnchor constant:5.0].active = YES;
        [headerRightView.widthAnchor constraintEqualToAnchor:headerView.widthAnchor multiplier:0.5 constant:-10.0].active = YES;
        
        // updated date
        UILabel *updateDateLabel = [[UILabel alloc] init];
        updateDateLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        updateDateLabel.text = @"Date:";
        updateDateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:updateDateLabel];
        
        NSDate *updated;
        if (lesson.record != nil) {
            updated = lesson.record.lessonDate;
        } else {
            updated = [NSDate date];
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy"];
        updateDate = [[UITextField alloc] init];
        updateDate.font = [UIFont fontWithName:@"Helvetica" size:18];
        updateDate.backgroundColor=[UIColor whiteColor];
        updateDate.text = [formatter stringFromDate:updated];
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            updateDate.enabled = NO;
            updateDate.textColor = [UIColor blackColor];
        } else {
            updateDate.textColor = self.userFieldColor;
        }
        updateDate.translatesAutoresizingMaskIntoConstraints = NO;
        [headerView addSubview:updateDate];
        
        [updateDateLabel.leadingAnchor constraintEqualToAnchor:headerRightView.leadingAnchor].active = YES;
        [updateDateLabel.topAnchor constraintEqualToAnchor:headerRightView.bottomAnchor constant:10.0].active = YES;
        
        [updateDate.leadingAnchor constraintEqualToAnchor:updateDateLabel.trailingAnchor constant:10.0].active = YES;
        [updateDate.topAnchor constraintEqualToAnchor:updateDateLabel.topAnchor].active = YES;
        
        // divider line
        UIView *dividerLine = [[UIView alloc] init];
        dividerLine.backgroundColor = [UIColor blackColor];
        dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:dividerLine];
        
        [dividerLine.heightAnchor constraintEqualToConstant:2.0].active = YES;
        [dividerLine.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [dividerLine.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        [dividerLine.topAnchor constraintEqualToAnchor:soloRequirementsLabel.bottomAnchor constant:10.0].active = YES;
        
        // ground label
        UILabel *groundLabel = [[UILabel alloc] init];
        groundLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28];
        groundLabel.text = @"Ground";
        groundLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:groundLabel];
        
        [groundLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [groundLabel.topAnchor constraintEqualToAnchor:dividerLine.topAnchor constant:10.0].active = YES;
        
        //ground lesson section
        UILabel *groundLessonSection = [[UILabel alloc] init];
        groundLessonSection.font = [UIFont fontWithName:@"Helvetica" size:20];
        groundLessonSection.text = lesson.groundDescription;
        groundLessonSection.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:groundLessonSection];
        
        [groundLessonSection.leadingAnchor constraintEqualToAnchor:groundLabel.trailingAnchor constant:10.0].active = YES;
        [groundLessonSection.topAnchor constraintEqualToAnchor:dividerLine.topAnchor constant:14.0].active = YES;
        [groundLessonSection.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        // ground lesson title
        UILabel *groundLessonLabel = [[UILabel alloc] init];
        groundLessonLabel.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:28];
        groundLessonLabel.text = [NSString stringWithFormat:@"Lesson %@ '", lesson.lessonNumber];
        groundLessonLabel.textAlignment = NSTextAlignmentRight;
        groundLessonLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:groundLessonLabel];
        
        [groundLessonLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [groundLessonLabel.topAnchor constraintEqualToAnchor:dividerLine.topAnchor constant:10.0].active = YES;
        [groundLessonLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-5.0].active = YES;
        
        // objectives
        UIView *groundObjectivesView = [[UIView alloc] init];
        groundObjectivesView.layer.borderColor = [UIColor blackColor].CGColor;
        groundObjectivesView.layer.borderWidth = 1.0;
        groundObjectivesView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:groundObjectivesView];
        
        [groundObjectivesView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [groundObjectivesView.topAnchor constraintEqualToAnchor:groundLessonLabel.bottomAnchor constant:10.0].active = YES;
        [groundObjectivesView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        //UILabel *groundObjectivesLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, self.bounds.size.width - 60, 25)];
        UILabel *groundObjectivesLabel = [[UILabel alloc] init];
        groundObjectivesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        groundObjectivesLabel.text = @"Objectives:";
        groundObjectivesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [groundObjectivesView addSubview:groundObjectivesLabel];
        
        [groundObjectivesLabel.leadingAnchor constraintEqualToAnchor:groundObjectivesView.leadingAnchor constant:10.0].active = YES;
        [groundObjectivesLabel.topAnchor constraintEqualToAnchor:groundObjectivesView.topAnchor constant:10.0].active = YES;
        
        // objectives text
        UILabel *groundObjectivesText = [[UILabel alloc] init];
        groundObjectivesText.font = [UIFont fontWithName:@"Helvetica" size:18];
        groundObjectivesText.text = lesson.groundObjective;
        groundObjectivesText.lineBreakMode = NSLineBreakByWordWrapping;
        groundObjectivesText.numberOfLines = 0;
        groundObjectivesText.translatesAutoresizingMaskIntoConstraints = NO;
        [groundObjectivesView addSubview:groundObjectivesText];
        
        [groundObjectivesText.leadingAnchor constraintEqualToAnchor:groundObjectivesView.leadingAnchor constant:10.0].active = YES;
        [groundObjectivesText.topAnchor constraintEqualToAnchor:groundObjectivesLabel.bottomAnchor constant:10.0].active = YES;
        [groundObjectivesText.widthAnchor constraintEqualToAnchor:groundObjectivesView.widthAnchor constant:-20.0].active = YES;
        
        [groundObjectivesView.bottomAnchor constraintEqualToAnchor:groundObjectivesText.bottomAnchor constant:10.0].active = YES;
        
        UILabel *contentLabel = [[UILabel alloc] init];
        contentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        contentLabel.text = @"Content:";
        contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [groundObjectivesView addSubview:contentLabel];
        
        [contentLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [contentLabel.topAnchor constraintEqualToAnchor:groundObjectivesView.bottomAnchor constant:10.0].active = YES;
        
        NSLayoutYAxisAnchor *contentTop = contentLabel.bottomAnchor;
        // ground content only (stored sorted)
        // ground content only (stored sorted)
        for (Content *content in lesson.content) {
            if ([content.groundOrFlight intValue] != 1) {
                // skip content which is not for ground instruction
                continue;
            }
            contentTop = [self addContent:content currentUserID:userID withDepth:[content.depth integerValue] andPlaceholderAttrs:placeholderAttrs withTopAnchor:contentTop];
        }
        
        
        // completion standards
        UIView *completionStandardsView = [[UIView alloc] init];
        completionStandardsView.layer.borderColor = [UIColor blackColor].CGColor;
        completionStandardsView.layer.borderWidth = 1.0;
        completionStandardsView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:completionStandardsView];
        
        // completion standards label
        UILabel *completionStandardsLabel = [[UILabel alloc] init];
        completionStandardsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        completionStandardsLabel.text = @"Completion Standards:";
        completionStandardsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [completionStandardsView addSubview:completionStandardsLabel];
        
        UILabel *completionStandardsText = [[UILabel alloc] init];
        completionStandardsText.font = [UIFont fontWithName:@"Helvetica" size:18];
        completionStandardsText.text = lesson.groundCompletionStds;
        completionStandardsText.lineBreakMode = NSLineBreakByWordWrapping;
        completionStandardsText.numberOfLines = 0;
        completionStandardsText.translatesAutoresizingMaskIntoConstraints = NO;
        [completionStandardsView addSubview:completionStandardsText];
        
        [completionStandardsView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [completionStandardsView.topAnchor constraintEqualToAnchor:contentTop constant:10.0].active = YES;
        [completionStandardsView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        [completionStandardsLabel.leadingAnchor constraintEqualToAnchor:completionStandardsView.leadingAnchor constant:10.0].active = YES;
        [completionStandardsLabel.topAnchor constraintEqualToAnchor:completionStandardsView.topAnchor constant:10.0].active = YES;
        
        [completionStandardsText.leadingAnchor constraintEqualToAnchor:completionStandardsView.leadingAnchor constant:10.0].active = YES;
        [completionStandardsText.topAnchor constraintEqualToAnchor:completionStandardsLabel.bottomAnchor constant:10.0].active = YES;
        [completionStandardsText.widthAnchor constraintEqualToAnchor:completionStandardsView.widthAnchor constant:-20.0].active = YES;
        
        [completionStandardsView.bottomAnchor constraintEqualToAnchor:completionStandardsText.bottomAnchor constant:10.0].active = YES;
        
        // assignments
        UILabel *assignmentsLabel = [[UILabel alloc] init];
        assignmentsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        assignmentsLabel.text = @"Assignments & Required Reading:";
        assignmentsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:assignmentsLabel];
        
        [assignmentsLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [assignmentsLabel.topAnchor constraintEqualToAnchor:completionStandardsView.bottomAnchor constant:10.0].active = YES;
        [assignmentsLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        NSLayoutYAxisAnchor *assignmentTop = assignmentsLabel.bottomAnchor;
        for (Assignment *assignment in lesson.assignments) {
            if ([assignment.groundOrFlight intValue] != 1) {
                // skip content which is not for ground instruction
                continue;
            }
            UILabel *assignmentRefLabel = [[UILabel alloc] init];
            assignmentRefLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
            assignmentRefLabel.text = assignment.referenceID;
            assignmentRefLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentRefLabel];
            
            UILabel *assignmentTitleLabel = [[UILabel alloc] init];
            assignmentTitleLabel.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14];
            assignmentTitleLabel.text = assignment.title;
            assignmentTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentTitleLabel];
            
            UILabel *assignmentSectionLabel = [[UILabel alloc] init];
            assignmentSectionLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
            assignmentSectionLabel.text = assignment.chapters;
            assignmentSectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentSectionLabel];
            
            [assignmentRefLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [assignmentRefLabel.topAnchor constraintEqualToAnchor:assignmentTop constant:10.0].active = YES;
            
            [assignmentTitleLabel.leadingAnchor constraintEqualToAnchor:assignmentRefLabel.trailingAnchor constant:10.0].active = YES;
            [assignmentTitleLabel.topAnchor constraintEqualToAnchor:assignmentRefLabel.topAnchor].active = YES;
            
            [assignmentSectionLabel.leadingAnchor constraintEqualToAnchor:assignmentTitleLabel.trailingAnchor constant:10.0].active = YES;
            [assignmentSectionLabel.topAnchor constraintEqualToAnchor:assignmentTitleLabel.topAnchor].active = YES;
            
            assignmentTop = assignmentRefLabel.bottomAnchor;
        }

        // instructor notes
        UILabel *instructorNotesLabel = [[UILabel alloc] init];
        instructorNotesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        instructorNotesLabel.text = @"Instructor Notes:";
        instructorNotesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:instructorNotesLabel];
        
        [instructorNotesLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [instructorNotesLabel.topAnchor constraintEqualToAnchor:assignmentTop constant:10.0].active = YES;
        [instructorNotesLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;

        instructorNotes = [[UITextView alloc] init];
        instructorNotes.delegate = self;
        instructorNotes.font = [UIFont fontWithName:@"Noteworthy-Bold" size:16];
        if (lesson.record != nil && [lesson.record.groundNotes length] > 0) {
            instructorNotes.text = lesson.record.groundNotes;
        } else if ([lesson.studentUserID intValue] != [userID intValue]) {
            instructorNotes.text = @"Add notes here";
            //instructorNotes.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Add notes here" attributes:placeholderAttrs];
        }
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            instructorNotes.editable = NO;
            //instructorNotes.textColor = [UIColor blackColor];
            instructorNotes.textColor = [UIColor colorWithRed:189.0f/255.0f green:110.0f/255.0f blue:2.0f/255.0f alpha:1];
        } else {
            //instructorNotes.textColor = self.userFieldColor;
            instructorNotes.textColor = [UIColor orangeColor];
        }
        instructorNotes.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:instructorNotes];
        
        [instructorNotes.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [instructorNotes.topAnchor constraintEqualToAnchor:instructorNotesLabel.bottomAnchor constant:10.0].active = YES;
        [instructorNotes.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        [instructorNotes.heightAnchor constraintEqualToConstant:50.0].active = YES;
        
        if (!isInstructorOrStudent) {
            // Student notes
            UILabel *studentNotesLabel = [[UILabel alloc] init];
            studentNotesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
            studentNotesLabel.text = @"Student Notes:";
            studentNotesLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:studentNotesLabel];
            
            [studentNotesLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [studentNotesLabel.topAnchor constraintEqualToAnchor:instructorNotes.bottomAnchor constant:10.0].active = YES;
            [studentNotesLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
            
            studentNotes = [[UITextView alloc] init];
            studentNotes.delegate = self;
            studentNotes.font = [UIFont fontWithName:@"Noteworthy-Bold" size:16];
            if (lesson.record != nil && [lesson.record.groundCompleted length] > 0) {
                studentNotes.text = lesson.record.groundCompleted;
                NSLog(@"%@", lesson.record.groundCompleted);
            } else {
                studentNotes.text = @"Add notes here";
                //instructorNotes.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Add notes here" attributes:placeholderAttrs];
            }
            studentNotes.textColor = [UIColor orangeColor];
            studentNotes.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:studentNotes];
            
            [studentNotes.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [studentNotes.topAnchor constraintEqualToAnchor:studentNotesLabel.bottomAnchor constant:10.0].active = YES;
            [studentNotes.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
            [studentNotes.heightAnchor constraintEqualToConstant:50.0].active = YES;
            
        }
        
        
        
        // flying
        // flight label
        UILabel *flightLabel = [[UILabel alloc] init];
        flightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:28];
        flightLabel.text = @"Flight";
        flightLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightLabel];
        
        [flightLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        if (isInstructorOrStudent) {
            [flightLabel.topAnchor constraintEqualToAnchor:instructorNotes.bottomAnchor constant:10.0].active = YES;
        }else{
            [flightLabel.topAnchor constraintEqualToAnchor:studentNotes.bottomAnchor constant:10.0].active = YES;
        }
        [flightLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        //flight lesson section
        UILabel *flightLessonSection = [[UILabel alloc] init];
        flightLessonSection.font = [UIFont fontWithName:@"Helvetica" size:20];
        flightLessonSection.text = lesson.flightDescription;
        flightLessonSection.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightLessonSection];
        
        if (isInstructorOrStudent) {
            [flightLessonSection.topAnchor constraintEqualToAnchor:instructorNotes.bottomAnchor constant:15.0].active = YES;
        }else{
            [flightLessonSection.topAnchor constraintEqualToAnchor:studentNotes.bottomAnchor constant:15.0].active = YES;
        }
        [flightLessonSection.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        
        // flight lesson label
        UILabel *flightLessonLabel = [[UILabel alloc] init];
        flightLessonLabel.font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:28];
        flightLessonLabel.text = [NSString stringWithFormat:@"Lesson %@ '", lesson.lessonNumber];
        flightLessonLabel.textAlignment = NSTextAlignmentRight;
        flightLessonLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightLessonLabel];
        
        [flightLessonLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightLessonLabel.topAnchor constraintEqualToAnchor:flightLabel.topAnchor constant:10.0].active = YES;
        [flightLessonLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-5.0].active = YES;
        
        // flying objectives
        UIView *flightObjectivesView = [[UIView alloc] init];
        flightObjectivesView.layer.borderColor = [UIColor blackColor].CGColor;
        flightObjectivesView.layer.borderWidth = 1.0;
        flightObjectivesView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightObjectivesView];
        
        // objectives label
        UILabel *flightObjectivesLabel = [[UILabel alloc] init];
        flightObjectivesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        flightObjectivesLabel.text = @"Objectives:";
        flightObjectivesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [flightObjectivesView addSubview:flightObjectivesLabel];
        
        // objectives text needs to be created first since it determines the size
        UILabel *flightObjectivesText = [[UILabel alloc] init];
        flightObjectivesText.font = [UIFont fontWithName:@"Helvetica" size:18];
        flightObjectivesText.text = lesson.flightObjective;
        flightObjectivesText.lineBreakMode = NSLineBreakByWordWrapping;
        flightObjectivesText.numberOfLines = 0;
        flightObjectivesText.translatesAutoresizingMaskIntoConstraints = NO;
        [flightObjectivesView addSubview:flightObjectivesText];
        
        [flightObjectivesView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightObjectivesView.topAnchor constraintEqualToAnchor:flightLessonLabel.bottomAnchor constant:10.0].active = YES;
        [flightObjectivesView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        [flightObjectivesLabel.leadingAnchor constraintEqualToAnchor:flightObjectivesView.leadingAnchor constant:10.0].active = YES;
        [flightObjectivesLabel.topAnchor constraintEqualToAnchor:flightObjectivesView.topAnchor constant:10.0].active = YES;
        
        [flightObjectivesText.leadingAnchor constraintEqualToAnchor:flightObjectivesView.leadingAnchor constant:10.0].active = YES;
        [flightObjectivesText.topAnchor constraintEqualToAnchor:flightObjectivesLabel.bottomAnchor constant:10.0].active = YES;
        [flightObjectivesText.widthAnchor constraintEqualToAnchor:flightObjectivesView.widthAnchor constant:-20.0].active = YES;
        
        [flightObjectivesView.bottomAnchor constraintEqualToAnchor:flightObjectivesText.bottomAnchor constant:10.0].active = YES;
        
        // content
        UILabel *flightContentLabel = [[UILabel alloc] init];
        flightContentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        flightContentLabel.text = @"Content:";
        flightContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightContentLabel];
        
        [flightContentLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightContentLabel.topAnchor constraintEqualToAnchor:flightObjectivesView.bottomAnchor constant:10.0].active = YES;
        [flightContentLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        contentTop = flightContentLabel.bottomAnchor;
        // flight content only (stored sorted)
        for (Content *content in lesson.content) {
            if ([content.groundOrFlight intValue] != 2) {
                // skip content which is not for flight instruction
                continue;
            }
            contentTop = [self addContent:content currentUserID:userID withDepth:[content.depth integerValue] andPlaceholderAttrs:placeholderAttrs withTopAnchor:contentTop];
        }
        
        // completion standards
        UIView *flightCompletionStandardsView = [[UIView alloc] init];
        flightCompletionStandardsView.layer.borderColor = [UIColor blackColor].CGColor;
        flightCompletionStandardsView.layer.borderWidth = 1.0;
        flightCompletionStandardsView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightCompletionStandardsView];
        
        UILabel *flightCompletionStandardsLabel = [[UILabel alloc] init];
        flightCompletionStandardsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        flightCompletionStandardsLabel.text = @"Completion Standards:";
        flightCompletionStandardsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [flightCompletionStandardsView addSubview:flightCompletionStandardsLabel];
        
        UILabel *flightCompletionStandardsText = [[UILabel alloc] init];
        flightCompletionStandardsText.font = [UIFont fontWithName:@"Helvetica" size:18];
        flightCompletionStandardsText.text = lesson.flightCompletionStds;
        flightCompletionStandardsText.lineBreakMode = NSLineBreakByWordWrapping;
        flightCompletionStandardsText.numberOfLines = 0;
        flightCompletionStandardsText.translatesAutoresizingMaskIntoConstraints = NO;
        [flightCompletionStandardsView addSubview:flightCompletionStandardsText];
        
        [flightCompletionStandardsView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightCompletionStandardsView.topAnchor constraintEqualToAnchor:contentTop constant:10.0].active = YES;
        [flightCompletionStandardsView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        [flightCompletionStandardsLabel.leadingAnchor constraintEqualToAnchor:flightCompletionStandardsView.leadingAnchor constant:10.0].active = YES;
        [flightCompletionStandardsLabel.topAnchor constraintEqualToAnchor:flightCompletionStandardsView.topAnchor constant:10.0].active = YES;
        
        [flightCompletionStandardsText.leadingAnchor constraintEqualToAnchor:flightCompletionStandardsView.leadingAnchor constant:10.0].active = YES;
        [flightCompletionStandardsText.topAnchor constraintEqualToAnchor:flightCompletionStandardsLabel.bottomAnchor constant:10.0].active = YES;
        [flightCompletionStandardsText.widthAnchor constraintEqualToAnchor:flightCompletionStandardsView.widthAnchor constant:-20.0].active = YES;
        
        [flightCompletionStandardsView.bottomAnchor constraintEqualToAnchor:flightCompletionStandardsText.bottomAnchor constant:10.0].active = YES;
        
        UILabel *flightAssignmentsLabel = [[UILabel alloc] init];
        flightAssignmentsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        flightAssignmentsLabel.text = @"Assignments & Required Reading:";
        flightAssignmentsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightAssignmentsLabel];
        
        [flightAssignmentsLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightAssignmentsLabel.topAnchor constraintEqualToAnchor:flightCompletionStandardsView.bottomAnchor constant:10.0].active = YES;
        [flightAssignmentsLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        assignmentTop = flightAssignmentsLabel.bottomAnchor;
        for (Assignment *assignment in lesson.assignments) {
            if ([assignment.groundOrFlight intValue] != 2) {
                // skip content which is not for flight instruction
                continue;
            }
            UILabel *assignmentRefLabel = [[UILabel alloc] init];
            assignmentRefLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
            assignmentRefLabel.text = assignment.referenceID;
            assignmentRefLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentRefLabel];
            
            UILabel *assignmentTitleLabel = [[UILabel alloc] init];
            assignmentTitleLabel.font = [UIFont fontWithName:@"Helvetica-Oblique" size:14];
            assignmentTitleLabel.text = assignment.title;
            assignmentTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentTitleLabel];
            
            UILabel *assignmentSectionLabel = [[UILabel alloc] init];
            assignmentSectionLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
            assignmentSectionLabel.text = assignment.chapters;
            assignmentSectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:assignmentSectionLabel];
            
            [assignmentRefLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [assignmentRefLabel.topAnchor constraintEqualToAnchor:assignmentTop constant:10.0].active = YES;
            
            [assignmentTitleLabel.leadingAnchor constraintEqualToAnchor:assignmentRefLabel.trailingAnchor constant:10.0].active = YES;
            [assignmentTitleLabel.topAnchor constraintEqualToAnchor:assignmentRefLabel.topAnchor].active = YES;
            
            [assignmentSectionLabel.leadingAnchor constraintEqualToAnchor:assignmentTitleLabel.trailingAnchor constant:10.0].active = YES;
            [assignmentSectionLabel.topAnchor constraintEqualToAnchor:assignmentTitleLabel.topAnchor].active = YES;
            
            assignmentTop = assignmentRefLabel.bottomAnchor;
        }
        
        // flight time instructor notes
        UILabel *flightInstructorNotesLabel = [[UILabel alloc] init];
        flightInstructorNotesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        flightInstructorNotesLabel.text = @"Instructor Notes:";
        flightInstructorNotesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightInstructorNotesLabel];
        
        [flightInstructorNotesLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightInstructorNotesLabel.topAnchor constraintEqualToAnchor:assignmentTop constant:10.0].active = YES;
        [flightInstructorNotesLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        
        flightInstructorNotes = [[UITextView alloc] init];
        flightInstructorNotes.delegate = self;
        flightInstructorNotes.font = [UIFont fontWithName:@"Noteworthy-Bold" size:16];
        flightInstructorNotes.textColor = userFieldColor;
        if (lesson.record != nil && [lesson.record.flightNotes length] > 0) {
            flightInstructorNotes.text = lesson.record.flightNotes;
        } else if ([lesson.studentUserID intValue] != [userID intValue]) {
            flightInstructorNotes.text = @"Add notes here";
            //flightInstructorNotes.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Add notes here" attributes:placeholderAttrs];
        }
        if ([lesson.studentUserID intValue] == [userID intValue]) {
            flightInstructorNotes.editable = NO;
            //flightInstructorNotes.textColor = [UIColor blackColor];
            flightInstructorNotes.textColor = [UIColor colorWithRed:189.0f/255.0f green:110.0f/255.0f blue:2.0f/255.0f alpha:1];
        } else {
            //flightInstructorNotes.textColor = self.userFieldColor;
            flightInstructorNotes.textColor = [UIColor orangeColor];
        }
        flightInstructorNotes.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:flightInstructorNotes];
        
        [flightInstructorNotes.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
        [flightInstructorNotes.topAnchor constraintEqualToAnchor:flightInstructorNotesLabel.bottomAnchor constant:10.0].active = YES;
        [flightInstructorNotes.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
        [flightInstructorNotes.heightAnchor constraintEqualToConstant:50.0].active = YES;
        
        if (!isInstructorOrStudent) {
            // Student notes
            UILabel *flightStudentNotesLabel = [[UILabel alloc] init];
            flightStudentNotesLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
            flightStudentNotesLabel.text = @"Student Notes:";
            flightStudentNotesLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:flightStudentNotesLabel];
            
            [flightStudentNotesLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [flightStudentNotesLabel.topAnchor constraintEqualToAnchor:flightInstructorNotes.bottomAnchor constant:10.0].active = YES;
            [flightStudentNotesLabel.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
            
            flightStudentNotes = [[UITextView alloc] init];
            flightStudentNotes.delegate = self;
            flightStudentNotes.font = [UIFont fontWithName:@"Noteworthy-Bold" size:16];
            if (lesson.record != nil && [lesson.record.flightCompleted length] > 0) {
                flightStudentNotes.text = lesson.record.flightCompleted;
            } else {
                flightStudentNotes.text = @"Add notes here";
                //instructorNotes.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Add notes here" attributes:placeholderAttrs];
            }
            flightStudentNotes.textColor = [UIColor orangeColor];
            flightStudentNotes.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:flightStudentNotes];
            
            [flightStudentNotes.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10.0].active = YES;
            [flightStudentNotes.topAnchor constraintEqualToAnchor:flightStudentNotesLabel.bottomAnchor constant:10.0].active = YES;
            [flightStudentNotes.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:-20.0].active = YES;
            [flightStudentNotes.heightAnchor constraintEqualToConstant:50.0].active = YES;
            
            
           // [self.bottomAnchor constraintEqualToAnchor:flightStudentNotes.bottomAnchor constant:10.0].active = YES;
            
        }
        
        //if (isInstructorOrStudent) {
        
        // log book entry
        // TODO: make height dynamic
        //if (lesson.record.lessonLog != nil || isInstructorOrStudent) {
        viewToContainLogBook = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 1175)];
        CGSize constraint = CGSizeMake(self.frame.size.width - 50.0f, CGFLOAT_MAX);
        CGSize size;
        
        NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
        CGSize boundingBox = [lesson.record.lessonLog.remarks boundingRectWithSize:constraint
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Noteworthy-Bold" size:14]}
                                                      context:context].size;
        size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
        
//        if (lesson.record.lessonLog != nil) {
//            CGFloat heightOfRemarks = [self getHeightFromString:lesson.record.lessonLog.remarks withFont:[UIFont fontWithName:@"Noteworthy-Bold" size:14] withWidth:self.frame.size.width - 60.0f] + 80.0f;
//            CGFloat calculatedHeightOfTable = 0;
//            for (Endorsement *oneEndorsement in lesson.record.lessonLog.endorsements) {
//                if (oneEndorsement && oneEndorsement.name && oneEndorsement.text && ![oneEndorsement.name isEqualToString:@""] && ![oneEndorsement.text isEqualToString:@""]) {
//                    calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:oneEndorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:self.frame.size.width-60.0f] + [self getHeightFromString:oneEndorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:self.frame.size.width-60.0f] + 230.0f ;
//                }else{
//                    calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
//                }
//            }
//            [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 920.0f + heightOfRemarks+ calculatedHeightOfTable)];
//        }else{
//            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
//            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
//            NSFetchRequest *request = [[NSFetchRequest alloc] init];
//            NSError *error;
//            [request setEntity:entityDesc];
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonId == %@", currentLesson.lessonID];
//            [request setPredicate:predicate];
//            NSArray *objects = [context executeFetchRequest:request error:&error];
//            if (objects == nil) {
//                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 1175)];
//            } else if (objects.count == 0) {
//                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 1175)];
//            } else {
//                LogEntry *logentry = objects[0];
//                if (logentry.endorsements.count > 0) {
//                    CGFloat heightOfRemarks = [self getHeightFromString:logentry.remarks withFont:[UIFont fontWithName:@"Noteworthy-Bold" size:14] withWidth:self.frame.size.width - 60.0f] + 80.0f;
//                    CGFloat calculatedHeightOfTable = 0;
//                    for (Endorsement *oneEndorsement in logentry.endorsements) {
//                        if (oneEndorsement && oneEndorsement.name && oneEndorsement.text && ![oneEndorsement.name isEqualToString:@""] && ![oneEndorsement.text isEqualToString:@""]) {
//                            calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:oneEndorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:self.frame.size.width-60.0f] + [self getHeightFromString:oneEndorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:self.frame.size.width-60.0f] + 230.0f ;
//                        }else{
//                            calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
//                        }
//                    }
//                    [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 920 +heightOfRemarks + calculatedHeightOfTable)];
//                }else{
//                    [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 1175)];
//                }
//            }
//        }
        
        NSString *insCertNum;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            insCertNum = [AppDelegate sharedDelegate].pilotCert;
        }
        else{
            insCertNum = currentLesson.lessonGroup.instructorPilotCert;
        }
        NSNumber *instructorID = nil;
        if (lesson.lessonGroup.parentGroup == nil) {
            instructorID = lesson.lessonGroup.instructorID;
        }else{
            instructorID = lesson.lessonGroup.parentGroup.instructorID;
        }
            
        if (lesson.record.lessonLog != nil) {
            CGFloat heightOfRemarks = [self getHeightFromString:lesson.record.lessonLog.remarks withFont:[UIFont fontWithName:@"Noteworthy-Bold" size:14] withWidth:self.frame.size.width - 50.0f] + 80.0f;
            if (lesson.record.lessonLog.endorsements.count > 0) {
                CGFloat calculatedHeightOfTable = 0;
                for (Endorsement *oneEndorsement in lesson.record.lessonLog.endorsements) {
                    if (oneEndorsement && oneEndorsement.name && oneEndorsement.text && ![oneEndorsement.name isEqualToString:@""] && ![oneEndorsement.text isEqualToString:@""]) {
                        calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:oneEndorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:self.frame.size.width-60.0f] + [self getHeightFromString:oneEndorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:self.frame.size.width-60.0f] + 260.0f ;
                    }else{
                        calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
                    }
                }
                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 920.0f + heightOfRemarks+ calculatedHeightOfTable)];
                viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:920.0f + heightOfRemarks+ calculatedHeightOfTable];
                viewToContrainLogBookHeightAnchor.active = YES;
                logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, 920.0f + heightOfRemarks+ calculatedHeightOfTable) andLogEntry:lesson.record.lessonLog andRecordLesson:currentLesson.record andLesson:lesson andInstructorID:instructorID andUserID:userID  CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
            }else{
                
                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 920.0f + heightOfRemarks+ 50.0f)];
                viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:920.0f + heightOfRemarks + 50.0f];
                viewToContrainLogBookHeightAnchor.active = YES;
                logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width, 920.0f + heightOfRemarks + 50.0f) andLogEntry:lesson.record.lessonLog andRecordLesson:currentLesson.record andLesson:lesson andInstructorID:instructorID andUserID:userID  CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
            }
        } else {
            
            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSError *error;
            [request setEntity:entityDesc];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonId == %@", currentLesson.lessonID];
            [request setPredicate:predicate];
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects == nil) {
                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width,1011.0f)];
                viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:1011.0f];
                viewToContrainLogBookHeightAnchor.active = YES;
                logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1011.0f) andLogEntry:nil andRecordLesson:currentLesson.record andLesson:lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
            } else if (objects.count == 0) {
                [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width,1011.0f)];
                viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:1011.0f];
                viewToContrainLogBookHeightAnchor.active = YES;
                logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1011.0f) andLogEntry:nil andRecordLesson:currentLesson.record andLesson:lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
            } else {
                LogEntry *logentry = objects[0];
                if (logentry.endorsements.count > 0) {
                    CGFloat heightOfRemarks = [self getHeightFromString:logentry.remarks withFont:[UIFont fontWithName:@"Noteworthy-Bold" size:14] withWidth:self.frame.size.width - 50.0f] + 50.0f;
                    CGFloat calculatedHeightOfTable = 0;
                    for (Endorsement *oneEndorsement in logentry.endorsements) {
                        if (oneEndorsement && oneEndorsement.name && oneEndorsement.text && ![oneEndorsement.name isEqualToString:@""] && ![oneEndorsement.text isEqualToString:@""]) {
                            calculatedHeightOfTable = calculatedHeightOfTable + [self getHeightFromString:oneEndorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:self.frame.size.width-60.0f] + [self getHeightFromString:oneEndorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:self.frame.size.width-60.0f] + 260.0f ;
                        }else{
                            calculatedHeightOfTable = calculatedHeightOfTable + 280.0f;
                        }
                    }
                    [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width, 920.0f + heightOfRemarks+ calculatedHeightOfTable)];
                    viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:920.0f + heightOfRemarks+ calculatedHeightOfTable];
                    viewToContrainLogBookHeightAnchor.active = YES;
                    logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 920.0f + heightOfRemarks+ calculatedHeightOfTable) andLogEntry:logentry andRecordLesson:logentry.logLessonRecord andLesson:lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
                }else{
                    [viewToContainLogBook setFrame:CGRectMake(0, 0, self.frame.size.width,1011.0f)];
                    viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:1011.0f];
                    viewToContrainLogBookHeightAnchor.active = YES;
                    logBookView = [[LogbookRecordView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1011.0f) andLogEntry:logentry andRecordLesson:logentry.logLessonRecord andLesson:lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:YES withTotalEngry:NO];
                }
            }
        }
        logBookView.layer.borderColor = [UIColor blackColor].CGColor;
        logBookView.layer.borderWidth = 1.0;
        // add the logbook entry view
        [viewToContainLogBook addSubview:logBookView];
        
        viewToContainLogBook.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:viewToContainLogBook];
        
        [viewToContainLogBook.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        if (!isInstructorOrStudent) {
            [viewToContainLogBook.topAnchor constraintEqualToAnchor:flightStudentNotes.bottomAnchor constant:10.0].active = YES;
        }else{
            [viewToContainLogBook.topAnchor constraintEqualToAnchor:flightInstructorNotes.bottomAnchor constant:10.0].active = YES;
        }
        [viewToContainLogBook.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        viewBottomAnchor = [self.bottomAnchor constraintEqualToAnchor:viewToContainLogBook.bottomAnchor constant:10.0];
        viewBottomAnchor.active = YES;
        //        }else{
        //            if (!isInstructorOrStudent) {
        //                [self.bottomAnchor constraintEqualToAnchor:flightStudentNotes.bottomAnchor constant:10.0].active = YES;
        //            }else{
        //                [self.bottomAnchor constraintEqualToAnchor:flightInstructorNotes.bottomAnchor constant:10.0].active = YES;
        //            }
        //        }
        
        //}
        
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
-(void)onDatePickerValueChanged:(UIDatePicker *)datePicker
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    flightDate.text = [dateFormat stringFromDate:flightDatePicker.date];
}

- (void)save
{
    NSLog(@"Save current state of the view!");
    NSError *error;
    // get the context
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    // loop through all the content
    BOOL validContent = NO;
    for (ContentInfo *contentInfo in groundContent) {
        if ([contentInfo.contentItem._IBCheckState  isEqualToString:@"Checked"] || [contentInfo.contentRemarks.text length] > 0)
        {
            NSLog(@"GREGDEBUG valid ground content");
            validContent = YES;
            break;
        }
    }
    if (validContent == NO) {
        for (ContentInfo *contentInfo in flightContent) {
            if ([contentInfo.contentItem._IBCheckState isEqualToString:@"Checked"] || [contentInfo.contentRemarks.text length] > 0)
            {
                NSLog(@"GREGDEBUG valid flight content");
                validContent = YES;
                break;
            }
        }
    }
    
    // check if the lesson record needs to be created
    if (currentLesson.record == nil) {
        // make sure there's at least something to save
        if ([instructorNotes.text length] > 0 ||
            [flightInstructorNotes.text length] > 0 || validContent == YES)
        {
            // create the lesson record
            NSLog(@"Adding new lesson record for lesson ID %@", currentLesson.lessonID);
            LessonRecord *lessonRecord = [NSEntityDescription insertNewObjectForEntityForName:@"LessonRecord" inManagedObjectContext:context];
            lessonRecord.lesson = currentLesson;
        }
    }
    if (currentLesson.record != nil) {
        // grab the current user's ID
        NSString *userIDKey = @"userId";
        NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
        NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to modify lessons without being logged in!");
            return;
        }
        // student cannot save updates to lesson
        if ([userID intValue] == [currentLesson.studentUserID intValue]) {
            FDLogError(@"Student cannot save his or her own lesson!");
            //return;
        }
        // set user and instructor
        currentLesson.record.userID = currentLesson.studentUserID;
        currentLesson.record.instructorID = userID;
        // save the lesson record, starting with ground completed
        currentLesson.record.groundCompleted = @"";
        // ground notes
        if ([instructorNotes.text isEqualToString:@"Add notes here"]) {
            currentLesson.record.groundNotes = @"";
        }else{
            currentLesson.record.groundNotes = instructorNotes.text;
        }
        // flight completed
        currentLesson.record.flightCompleted = @"";
        // flight notes
        if ([flightInstructorNotes.text isEqualToString:@"Add notes here"]) {
            currentLesson.record.flightNotes = @"";
        }else{
            currentLesson.record.flightNotes = instructorNotes.text;
        }
        if ([userID intValue] == [currentLesson.studentUserID intValue]) {
            if ([studentNotes.text isEqualToString:@"Add notes here"]) {
                currentLesson.record.groundCompleted = @"";
            }else{
                currentLesson.record.groundCompleted = studentNotes.text;
            }
            if ([flightStudentNotes.text isEqualToString:@"Add notes here"]) {
                currentLesson.record.flightCompleted = @"";
            }else{
                currentLesson.record.flightCompleted = flightStudentNotes.text;
            }
        }
        
        // save the lesson date
        NSInteger countOfUnchecked = 0;
        NSInteger countAllContent = 0;
        
        for (Content *content in currentLesson.content) {
            if ([content.groundOrFlight intValue] != 1 && [content.groundOrFlight intValue] != 2 ) { //ground
                continue;
            }
            if ([content.hasCheck boolValue] == YES) {
                BOOL isChecked = NO;
                if (content.record != nil && content.record.completed != nil && [content.record.completed boolValue] == YES)
                {
                    isChecked = YES;
                }
                if (!isChecked) {
                    countOfUnchecked = countOfUnchecked + 1;
                }
                
                countAllContent = countAllContent + 1;
            }
        }
        
        //FDLogDebug(@"%d/%d are uncheked on %@", countOfUnchecked, countAllContent, currentLesson.name);
        if (countAllContent == countOfUnchecked) {
            
        }else{
            if (countOfUnchecked == 0) {//completed status
                currentLesson.record.lessonDate =  [NSDate date];
            }else{
                
            }
        }
        
        // set the last update time to 0 for uploading
        currentLesson.record.lastUpdate = [NSNumber numberWithInt:0];
        // save the content records if content exists
        // ground content
        for (ContentInfo *contentInfo in groundContent) {
            ContentRecord *contentRecord;
            if (contentInfo.content.record == nil) {
                if ([contentInfo.contentItem._IBCheckState isEqualToString:@"Checked"] || [contentInfo.contentRemarks.text length] > 0)
                {
                    contentRecord = [NSEntityDescription insertNewObjectForEntityForName:@"ContentRecord" inManagedObjectContext:context];
                    [contentInfo.content setRecord:contentRecord];
                    [contentRecord setContent:contentInfo.content];
                } else {
                    contentRecord = nil;
                }
            } else {
                contentRecord = contentInfo.content.record;
            }
            // save completed state
            if (contentRecord != nil) {
                if (contentInfo.contentItem != nil && [contentInfo.contentItem._IBCheckState isEqualToString:@"Checked"]) {
                    contentRecord.completed = [NSNumber numberWithBool:YES];
                } else {
                    contentRecord.completed = [NSNumber numberWithBool:NO];
                }
                // save remarks
                if (contentInfo.contentRemarks != nil && [contentInfo.contentRemarks.text length] > 0) {
                    if (![contentInfo.contentRemarks.text isEqualToString:@"Remarks"]) {
                        contentRecord.remarks = contentInfo.contentRemarks.text;
                    }
                }
            }
        }
        // flight content
        for (ContentInfo *contentInfo in flightContent) {
            ContentRecord *contentRecord;
            if (contentInfo.content.record == nil) {
                if ([contentInfo.contentItem._IBCheckState isEqualToString:@"Checked"] || [contentInfo.contentRemarks.text length] > 0)
                {
                    contentRecord = [NSEntityDescription insertNewObjectForEntityForName:@"ContentRecord" inManagedObjectContext:context];
                    [contentInfo.content setRecord:contentRecord];
                    [contentRecord setContent:contentInfo.content];
                } else {
                    contentRecord = nil;
                }
            } else {
                contentRecord = contentInfo.content.record;
            }
            // save completed state
            if (contentRecord != nil) {
                if (contentInfo.contentItem != nil && [contentInfo.contentItem._IBCheckState isEqualToString:@"Checked"]) {
                    contentRecord.completed = [NSNumber numberWithBool:YES];
                } else {
                    contentRecord.completed = [NSNumber numberWithBool:NO];
                }
                // save remarks
                if (contentInfo.contentRemarks != nil && [contentInfo.contentRemarks.text length] > 0) {
                    if (![contentInfo.contentRemarks.text isEqualToString:@"Remarks"]) {
                        contentRecord.remarks = contentInfo.contentRemarks.text;
                    }
                }
            }
        }
        
        // save changes to logbook
        [logBookView save];
        
        if (currentLesson.record != nil) {
            LogEntry *logBookViewEntry = [logBookView getCurrentEntry];
            if (logBookViewEntry != nil) {
                // attach the log entry to the lesson
                if (!logBookViewEntry.isFault) {
                    currentLesson.record.lessonLog = logBookViewEntry;
                }
            }
        }
    } else {
        FDLogError(@"unable to create entry for new LessonRecord!");
    }
    
    // save changes to disk
    [context save:&error];
    // TODO: sync this lesson back to the server
    
    if (error != nil) {
        FDLogError(@"Unable to save user lesson record changes to context: %@", [error localizedDescription]);
    }
    
}

/*// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
 
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, 25, 140);
    CGContextAddLineToPoint(context, self.bounds.size.width - 50, 140);
    CGContextStrokePath(context);
    
    //[[UIColor blackColor] setFill];
    //UIRectFill(CGRectMake(25, 140, self.bounds.size.width - 50, 2));
}*/

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == hobbsIn || textField == hobbsOut) {
        NSDecimalNumber *hobbsOutNumber = [NSDecimalNumber decimalNumberWithString:hobbsOut.text];
        NSDecimalNumber *hobbsInNumber = [NSDecimalNumber decimalNumberWithString:hobbsIn.text];
        if (![hobbsOutNumber isEqualToNumber:[NSDecimalNumber notANumber]] && ![hobbsInNumber isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [hobbsInNumber decimalNumberBySubtracting:hobbsOutNumber];
            totalFlightTime.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    if (textView == flightInstructorNotes) {
        if ([flightInstructorNotes.text isEqualToString:@"Add notes here"]) {
            flightInstructorNotes.text = @"";
        }
    }else if (textView == instructorNotes) {
        if ([instructorNotes.text isEqualToString:@"Add notes here"]) {
            instructorNotes.text = @"";
        }
    }else if (textView == studentNotes) {
        if ([studentNotes.text isEqualToString:@"Add notes here"]) {
            studentNotes.text = @"";
        }
    }else if (textView == flightStudentNotes) {
        if ([flightStudentNotes.text isEqualToString:@"Add notes here"]) {
            flightStudentNotes.text = @"";
        }
    }else {
        if ([textView.text isEqualToString:@"Remarks"]) {
            textView.text = @"";
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if (textView == flightInstructorNotes) {
        if ([flightInstructorNotes.text isEqualToString:@""]) {
            flightInstructorNotes.text = @"Add notes here";
        }
    }else if (textView == instructorNotes) {
        if ([instructorNotes.text isEqualToString:@""]) {
            instructorNotes.text = @"Add notes here";
        }
    }else if (textView == studentNotes) {
        if ([studentNotes.text isEqualToString:@""]) {
            studentNotes.text = @"Add notes here";
        }
    }else if (textView == flightStudentNotes) {
        if ([flightStudentNotes.text isEqualToString:@""]) {
            flightStudentNotes.text = @"Add notes here";
        }
    }else {
        if ([textView.text isEqualToString:@""]) {
            textView.text = @"Remarks";
        }
    }
}
- (void)updateLogBookHeight:(CGFloat)_height{
    viewToContrainLogBookHeightAnchor.active = NO;
    viewBottomAnchor.active = NO;
    CGRect viewToContainLogBookRect = viewToContainLogBook.frame;
    viewToContainLogBookRect.size.height = _height;
    [viewToContainLogBook setFrame:viewToContainLogBookRect];
    viewToContrainLogBookHeightAnchor = [viewToContainLogBook.heightAnchor constraintEqualToConstant:_height];
    viewToContrainLogBookHeightAnchor.active = YES;

    CGRect logBookViewRect = logBookView.frame;
    logBookViewRect.size.height = _height;
    [logBookView setFrame:logBookViewRect];
    [logBookView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    viewBottomAnchor = [self.bottomAnchor constraintEqualToAnchor:viewToContainLogBook.bottomAnchor constant:10.0];
    viewBottomAnchor.active = YES;
//
//    CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
//    [self setContentOffset:bottomOffset animated:YES];
}
@end
