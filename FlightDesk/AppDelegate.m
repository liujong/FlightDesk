//
//  AppDelegate.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "DocumentsViewController.h"
#import "QuizesViewController.h"
#import "LogbookViewController.h"
#import "MoreViewController.h"
#import "LessonGroup+CoreDataClass.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "Document+CoreDataClass.h"
#import "MainSpecs/Calendar/CalendarKit/CalendarKit.h"
#import "WelcomeViewController.h"
#import "CommsMainViewController.h"
#import "JCNotificationCenter.h"
#import "JCNotificationBannerPresenterSmokeStyle.h"
#import "ReaderDocument.h"

#import "AddCheckListsViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
@import Firebase;
#endif

@interface AppDelegate ()<UNUserNotificationCenterDelegate>
{
    
    
    AVAudioPlayer *player;
    AVAudioPlayer *christmasPlayer;
}
@end

@implementation AppDelegate

@synthesize navAppearance;
@synthesize records_vc;
@synthesize documents_vc;
@synthesize quizses_VC;
@synthesize logbook_vc;
@synthesize liveChat_vc;
@synthesize commsMain_vc, comms_nc;
@synthesize navLog_VC;
@synthesize checklist_VC;
@synthesize more_VC;
@synthesize splitViewControllerOfChatting;
@synthesize persistentCoreDataStack = _persistentCoreDataStack;
@synthesize isSelectedLandscape;
@synthesize deviceTokenOfSupport;
@synthesize heightCurrentLogBookToUpdate;
@synthesize train_VC;
@synthesize studentTrain_VC;
@synthesize reloadDashBoard_V;
@synthesize recordsfile_VC;
@synthesize setting_VC, general_VC;
@synthesize scheduleMain_VC;

@synthesize filePathToImportMyDocs;

@synthesize isOpenFirstWithDash;
@synthesize isUpdatedMiniMonthBySelection;

@synthesize rootViewControllerForTab, navigationControllerForTab;

@synthesize syncManagerLessonLog = _syncManagerLessonLog;
@synthesize syncManagerDocument = _syncManagerDocument;
@synthesize syncManagerQuiz = _syncManagerQuiz;
@synthesize syncNamagerNoUpload = _syncNamagerNoUpload;
@synthesize syncManagerAirCraft = _syncManagerAirCraft;
@synthesize syncManagerMoreTools = _syncManagerMoreTools;
@synthesize syncManagerSupport = _syncManagerSupport;
@synthesize syncManagerRecordsFiles = _syncManagerRecordsFiles;
@synthesize syncManagerGeneral = _syncManagerGeneral;
@synthesize syncManagerResourcesCalendar = _syncManagerResourcesCalendar;

@synthesize currentSyncingIndex;
@synthesize isSelectedDayViewForBooking, isSelectedWeekViewForBooking;

//coms
@synthesize unreadData;
@synthesize bubbleData;
@synthesize isActivedUsersData;
@synthesize bannerDetails;
@synthesize rootR;
@synthesize tmpBubbleTableView;
@synthesize unreadGeneralCount;

//Setting
@synthesize clientFirstName, clientMiddleName, clientLastName;
@synthesize instructorId, instructorName;
@synthesize userId, userEmail, userName, userLevel, userPhoneNum,userPassword,pilotCert, pilotCertIssueDate, medicalCertExpDate, cfiCertExpDate, question, answer, groupIdsStr, isVerify, verificationCode, device_token, medicalCertIssueDate;

@synthesize currentTabItemIndex;
@synthesize isLogin, isBackPreUser, isRegister;

@synthesize currentQuizId, isTestingScreen;

@synthesize arrayMydoc;

@synthesize isStartPerformSyncCheck;

@synthesize countRedBadge, countRedBadgeForUnreadMessage;

@synthesize currentBoardID;
@synthesize isShownChatBoard;
@synthesize selectedNavLogIndex;

@synthesize isSelectedIosCalendar;
@synthesize deviationOfResources, preallDayEventsViewHeight;
@synthesize isShownScheduleView;
@synthesize isLoadedScheduleViewAtOnce;

@synthesize trainingHud;
@synthesize programName;


NSString *const kGCMMessageIDKey = @"gcm.message_id";
FIRDatabaseReference *rootR;

+(AppDelegate*)sharedDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

- (void)clearLessons
{
    FDLogDebug(@"clearing all lesson data and records");
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // delete all the lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *lessonGroupArray = [context executeFetchRequest:request error:&error];
    for (LessonGroup *lessonGroup in lessonGroupArray){
        [context deleteObject:lessonGroup];
    }
    request = nil;
    entityDescription = nil;
    // delete all the lessons
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *lessonArray = [context executeFetchRequest:request error:&error];
    for (Lesson *lesson in lessonArray){
        [context deleteObject:lesson];
    }
    request = nil;
    entityDescription = nil;
    // delete all the assignments
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Assignment" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *assignmentArray = [context executeFetchRequest:request error:&error];
    for (Assignment *assignment in assignmentArray){
        [context deleteObject:assignment];
    }
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Content" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *contentArray = [context executeFetchRequest:request error:&error];
    for (Content *content in contentArray){
        [context deleteObject:content];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *quizArray = [context executeFetchRequest:request error:&error];
    for (Quiz *qui in quizArray){
        [context deleteObject:qui];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Question" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *questionArray = [context executeFetchRequest:request error:&error];
    for (Question *ques in questionArray){
        [context deleteObject:ques];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *logEntryArray = [context executeFetchRequest:request error:&error];
    for (LogEntry *logentry in logEntryArray){
        [context deleteObject:logentry];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *endorsementArray = [context executeFetchRequest:request error:&error];
    for (Endorsement *endorsement in endorsementArray){
        [context deleteObject:endorsement];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *studentArray = [context executeFetchRequest:request error:&error];
    for (Student *student in studentArray){
        [context deleteObject:student];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"LessonRecord" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *lessonRecordArray = [context executeFetchRequest:request error:&error];
    for (LessonRecord *lessonRecord in lessonRecordArray){
        [context deleteObject:lessonRecord];
    }
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"ContentRecord" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *contentRecordArray = [context executeFetchRequest:request error:&error];
    for (ContentRecord *contentRecord in contentRecordArray){
        [context deleteObject:contentRecord];
    }
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *chathistoryArray = [context executeFetchRequest:request error:&error];
    for (ChatHistory *chathistory in chathistoryArray){
        [context deleteObject:chathistory];
    }
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"ChatBoard" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *chatBoardArray = [context executeFetchRequest:request error:&error];
    for (ChatBoard *chatBoard in chatBoardArray){
        [context deleteObject:chatBoard];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *navLogArray = [context executeFetchRequest:request error:&error];
    for (NavLog *navLog in navLogArray){
        for (NavLogRecord *navLogRecord in navLog.navLogRecords) {
            [context deleteObject:navLogRecord];
        }
        [context deleteObject:navLog];
    }
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"NavLogRecord" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *navLogRecordArray = [context executeFetchRequest:request error:&error];
    for (NavLogRecord *navLogRecord in navLogRecordArray) {
        [context deleteObject:navLogRecord];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *checklistsArray = [context executeFetchRequest:request error:&error];
    for (Checklists *checklist in checklistsArray) {
        for (ChecklistsContent *checklistContentToDelete in checklist.checklists) {
            [context deleteObject:checklistContentToDelete];
        }
        [context deleteObject:checklist];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"ChecklistsContent" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *checklistContentArray = [context executeFetchRequest:request error:&error];
    for (ChecklistsContent *checklistContentToDelete in checklistContentArray) {
        [context deleteObject:checklistContentToDelete];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *usersArray = [context executeFetchRequest:request error:&error];
    for (Users *usersToDelete in usersArray) {
        [context deleteObject:usersToDelete];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *recordFileArray = [context executeFetchRequest:request error:&error];
    for (RecordsFile *recordsFileToDelete in recordFileArray) {
        [context deleteObject:recordsFileToDelete];
    }
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *maintenanceLogsArray = [context executeFetchRequest:request error:&error];
    for (MaintenanceLogs *maintenanceLogsToDelete in maintenanceLogsArray) {
        [context deleteObject:maintenanceLogsToDelete];
    }
    
    
    request = nil;
    entityDescription = nil;
    // delete all the content
    request = [[NSFetchRequest alloc] init];
    entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *resourcesCalendarArray = [context executeFetchRequest:request error:&error];
    for (ResourcesCalendar *resouresCalendarToDelete in resourcesCalendarArray) {
        [context deleteObject:resouresCalendarToDelete];
    }
    
    //delete current calendars from ios-calendar
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    for (EKCalendar *currentCalendar in [eventStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSString *prefixOfCalendar = @"";
        if (currentCalendar.title.length > 3) {
            prefixOfCalendar = [currentCalendar.title substringToIndex:3];
        }
        if ([prefixOfCalendar isEqualToString:@"FD-"]) {
            BOOL success= [eventStore removeCalendar:currentCalendar commit:YES error:&error];
            if (error != nil)
            {
                NSLog(@"%@", error.description);
                // TODO: error handling here
            }
            if (success) {
                NSLog(@"Removed %@ from iOS-Calendar", currentCalendar.title);
            }
        }
    }
    
    [context save:&error];
}


- (void)clearDocuments
{
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // delete all the documents
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *documentArray = [context executeFetchRequest:request error:&error];
    for (Document *document in documentArray){
        // delete the ReaderDocument archive (bookmarks etc)
        // delete the underlying PDFs
        // delete the database entry
        [context deleteObject:document];
    }
    [context save:&error];
    request = nil;
    entityDescription = nil;
    
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:documentDirectory error:&error]) {
        NSArray *arrayToParseFileName = [fileName componentsSeparatedByString:@"."];
        NSString *fileType =arrayToParseFileName[arrayToParseFileName.count-1];
        if ([fileType.lowercaseString isEqualToString:@"pdf"]) {
            [fm removeItemAtPath:[documentDirectory stringByAppendingPathComponent:fileName] error:&error];
        }
    }
    
    // delete all the lesson groups with no sub-lesson groups, lessons, or documents
    /*request = [[NSFetchRequest alloc] init];
     entityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
     [request setEntity:entityDescription];
     NSArray *groupArray = [context executeFetchRequest:request error:&error];
     for (LessonGroup *group in groupArray){
     // delete the ReaderDocument archive (bookmarks etc)
     // delete the underlying PDFs
     // delete the database entry
     [context deleteObject:group];
     }*/
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    //init
    clientFirstName = @"";
    clientMiddleName = @"";
    clientLastName = @"";
    instructorName = @"";
    instructorId = @"";
    userId = @"";
    userName = @"";
    userLevel = @"";
    userPhoneNum = @"";
    userEmail = @"";
    userPassword = @"";
    pilotCert = @"";
    pilotCertIssueDate = @"";
    medicalCertIssueDate = @"";
    medicalCertExpDate = @"";
    cfiCertExpDate = @"";
    question = @"";
    answer = @"";
    currentTabItemIndex = 0;
    groupIdsStr = @"";
    isLogin = NO;
    isRegister = NO;
    isBackPreUser = YES;
    device_token = @"";
    isOpenFirstWithDash = NO;
    
    currentQuizId = nil;
    isTestingScreen = NO;
    isVerify = 0;
    
    currentSyncingIndex = -1;
    
    isSelectedLandscape = NO;
    
    countRedBadge = 0;
    countRedBadgeForUnreadMessage = 0;
    currentBoardID = 0;
    isShownChatBoard = NO;
    unreadGeneralCount = 0;
    
    selectedNavLogIndex = 0;
    
    heightCurrentLogBookToUpdate = 0.0f;
    deviationOfResources = 0.0f;
    preallDayEventsViewHeight = 24.0f;
    
    arrayMydoc = [[NSMutableArray alloc] init];
    isStartPerformSyncCheck = NO;
    
    bubbleData = [[NSMutableArray alloc] init];
    unreadData = [[NSMutableArray alloc] init];
    isActivedUsersData = [[NSMutableArray alloc] init];
    bannerDetails = [[NSMutableDictionary alloc] init];
    
    isSelectedIosCalendar = NO;
    isSelectedDayViewForBooking = NO;
    isSelectedWeekViewForBooking = NO;
    isShownScheduleView = NO;
    isLoadedScheduleViewAtOnce = NO;
    
    isUpdatedMiniMonthBySelection = NO;
    programName = @"";
    for (NSString* family in [UIFont familyNames])
    {
        NSLog(@"%@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"  %@", name);
        }
    }
    
    [Fabric with:@[[Crashlytics class]]];
    
    // [START configure_firebase]
    [FIRApp configure];
    // [END configure_firebase]
    
    // [START set_messaging_delegate]
    [FIRMessaging messaging].delegate = self;
    // [END set_messaging_delegate]
    
    // Register for remote notifications. This shows a permission dialog on first run, to
    // show the dialog at a more appropriate time move this registration accordingly.
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        // iOS 7.1 or earlier. Disable the deprecation warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType allNotificationTypes =
        (UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeBadge);
        [application registerForRemoteNotificationTypes:allNotificationTypes];
#pragma clang diagnostic pop
    } else {
        // iOS 8 or later
        // [START register_for_notifications]
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
            UIUserNotificationType allNotificationTypes =
            (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
            UIUserNotificationSettings *settings =
            [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        } else {
            // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
            // For iOS 10 display notification (sent via APNS)
            [UNUserNotificationCenter currentNotificationCenter].delegate = self;
            UNAuthorizationOptions authOptions =
            UNAuthorizationOptionAlert
            | UNAuthorizationOptionSound
            | UNAuthorizationOptionBadge;
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
            }];
#endif
        }
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        // [END register_for_notifications]
    }
    
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (granted) {
            
        }
    }];
    
    
    //[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0 green:140.0f/255.0f blue:1.0f alpha:1.0f]];
    //[[UINavigationBar appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor]}];
//    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
//    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    //[[UINavigationBar appearance] setBackgroundImage:[self gradientImageWithColor:[UIColor colorWithRed:0 green:140.0f/255.0f blue:1.0f alpha:1.0f] :[UIColor blueColor]] forBarMetrics:UIBarMetricsDefault];
    self.persistentCoreDataStack = [[PersistentCoreDataStack alloc] initWithStoreURL:self.storeURL modelURL:self.modelURL];
    
#ifdef DEVENV
    [[NSUserDefaults standardUserDefaults] setObject:@"http://tmp.flightdeskapp.com" forKey:@"server_name"];
#else
    [[NSUserDefaults standardUserDefaults] setObject:@"http://flightdeskapp.com" forKey:@"server_name"];
#endif
    
    
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    if (serverName == nil) {
        // possible defaults for this could be the following:
        // https://www.nova.aero
        // http://www.flightdeskapp.com
        // http://www.gpbayard.com
        //[[NSUserDefaults standardUserDefaults] setObject:@"http://flightdeskapp.com" forKey:@"server_name"];
    }
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    if (webAppDir == nil) {
        // possible defaults for this could be the following:
        // flightdesk
        // nova
        [[NSUserDefaults standardUserDefaults] setObject:@"flightdesk" forKey:@"web_app_dir"];
    }
    id clearLessons = [[NSUserDefaults standardUserDefaults] objectForKey:@"clear_lessons"];
    if ([clearLessons boolValue] == YES) {
        [self clearLessons];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"clear_lessons"];
    id clearDocuments = [[NSUserDefaults standardUserDefaults] objectForKey:@"clear_documents"];
    if ([clearDocuments boolValue] == YES) {
        [self clearDocuments];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"clear_documents"];
    
    FDLogDebug(@"server_name=%@,clear_ lessons=%hhd,clear_documents=%hhd", serverName, [clearLessons boolValue], [clearDocuments boolValue]);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSMutableArray *tabItems = [[NSMutableArray alloc] initWithCapacity:4];
    
    // Setup records view controller
    records_vc = [[RecordsViewController alloc] init];
    UINavigationController *records_nc = [[UINavigationController alloc] initWithRootViewController:records_vc];
    records_nc.tabBarItem.title = @"Programs";
    records_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Programs" ofType:@"png"]];
    [tabItems addObject:records_nc];
    
    // Setup documents view controller
    documents_vc = [[DocumentsViewController alloc] init];
    UINavigationController *documents_nc = [[UINavigationController alloc] initWithRootViewController:documents_vc];
    documents_nc.tabBarItem.title = @"Materials";
    documents_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Materials" ofType:@"png"]];
    documents_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)[AppDelegate sharedDelegate].countRedBadge];
    [tabItems addObject:documents_nc];
    
    // Setup quizes view controller
    quizses_VC = [[QuizesViewController alloc] init];
    UINavigationController *quizes_nc = [[UINavigationController alloc] initWithRootViewController:quizses_VC];
    quizes_nc.tabBarItem.title = @"Quizzes";
    quizes_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Quizes" ofType:@"png"]];
    [tabItems addObject:quizes_nc];
    
    // Setup logbook view controller
    logbook_vc = [[LogbookViewController alloc] init];
    UINavigationController *logbook_nc = [[UINavigationController alloc] initWithRootViewController:logbook_vc];
    logbook_nc.tabBarItem.title = @"Logbook";
    logbook_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Logbook" ofType:@"png"]];
    [tabItems addObject:logbook_nc];
    
    
    commsMain_vc = [[CommsMainViewController alloc] init];
    
    NSArray *controllers = @[commsMain_vc];
    splitViewControllerOfChatting = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewControllerOfChatting.delegate =  self;
    comms_nc = [[UINavigationController alloc] initWithRootViewController:splitViewControllerOfChatting];
    comms_nc.tabBarItem.title = @"Comms";
    comms_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NewComms" ofType:@"png"]];
    //NSInteger unReadMessageCount = [self getChattingMessageUnreadCount];
    [tabItems addObject:comms_nc];
    
    scheduleMain_VC = [[ScheduleMainViewController alloc] init];
    UINavigationController *schedule_nc = [[UINavigationController alloc] initWithRootViewController:scheduleMain_VC];
    schedule_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Calendar" ofType:@"png"]];
    schedule_nc.tabBarItem.title = @"Schedule";
    [tabItems addObject:schedule_nc];
    
    
    // Setup more view controller
    more_VC = [[MoreViewController alloc] init];
    UINavigationController *more_nc = [[UINavigationController alloc] initWithRootViewController:more_VC];
    more_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Calcs" ofType:@"png"]];
    more_nc.tabBarItem.title = @"More";
    [tabItems addObject:more_nc];
    
    // Setup the root view controller
    rootViewControllerForTab = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    rootViewControllerForTab.viewControllers = tabItems;
    rootViewControllerForTab.delegate = self;
    // Assign root view controller
    self.window.rootViewController = rootViewControllerForTab;
    
    [self.window makeKeyAndVisible];
    
    //Register Aircraft Local Notifications
    
    [self cleanAllLocalNotifications];
    [self registerLocalNotifications];
    
    // make sure the sync manager is initialized with the background managed object context
    NSString *usernameStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userName"];
    NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    if (usernameStr && userIdStr && ![usernameStr isEqualToString:@""] && ![userIdStr isEqualToString:@""]) {
        [[AppDelegate sharedDelegate] loadPilotProfileFromLocal];
    }
    
    [AppDelegate sharedDelegate].countRedBadge = [self getDocumentDownloadCount] + [self getBadgeCountForExpiredAircraft:nil];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[AppDelegate sharedDelegate].countRedBadge];
    
    if ([userLevel isEqualToString:@"Support"]) {
        self.syncManagerSupport = [[SyncManageSupport alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
    }
    [self getDeviceTokenOfSupport];
    
    
    GAI *gai = [GAI sharedInstance];
    [gai trackerWithTrackingId:@"UA-108893236-1"];
    
    // Optional: automatically report uncaught exceptions.
    gai.trackUncaughtExceptions = YES;
    
    // Optional: set Logger to VERBOSE for debug information.
    // Remove before app release.
    gai.logger.logLevel = kGAILogLevelVerbose;
    
    NSString *path;
    NSURL *url;
    //where you are about to add sound
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
//    
//    path =[[NSBundle mainBundle] pathForResource:@"christmas" ofType:@"mp3"];
//    url = [NSURL fileURLWithPath:path];
//    
//    christmasPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
//    [christmasPlayer setVolume:1.0];
//    [christmasPlayer prepareToPlay];
//    christmasPlayer.numberOfLoops = 1;
//    [christmasPlayer play];
    return YES;
}

- (UIImage *)gradientImageWithColor:(UIColor *)firstColor :(UIColor *)secondColor
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)firstColor.CGColor,
                              (__bridge id)secondColor.CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return gradientImage;
}
- (void) logUser {
    // TODO: Use the current user's information
    // You can call any combination of these three methods
    [CrashlyticsKit setUserIdentifier:[AppDelegate sharedDelegate].userId];
    [CrashlyticsKit setUserEmail:[AppDelegate sharedDelegate].userEmail];
    [CrashlyticsKit setUserName:[AppDelegate sharedDelegate].userName];
}

/*
- (NSInteger)getDocumentDownloadCount{
    NSInteger count = 0;
    
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
    NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
    [documentRequest setEntity:documentEntityDescription];
    
    
    NSArray *documentArray = [context executeFetchRequest:documentRequest error:&error];
    if (documentArray == nil) {
    } else if (documentArray.count == 0) {
    } else if (documentArray.count > 0) {
        NSMutableArray *documentArrayIds = [[NSMutableArray alloc] init];
        for (Document *document in documentArray) {
            if (![documentArrayIds containsObject:document.documentID]) {
                [documentArrayIds addObject:document.documentID];
                if ([document.downloaded boolValue] == NO ) {
                    count = count + 1;
                }
            }
        }
    }
    if (count == 0) {
        documents_vc.navigationController.tabBarItem.badgeValue = nil;
    }else{
        documents_vc.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
    }
    return count;
}
 */

- (NSInteger)getMyDocDocumentCount{
    NSInteger count = 0;
    
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
    NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
    [documentRequest setEntity:documentEntityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == 1"];
    [documentRequest setPredicate:predicate];
    
    NSArray *documentArray = [context executeFetchRequest:documentRequest error:&error];
    if (documentArray == nil) {
    } else if (documentArray.count == 0) {
    } else if (documentArray.count > 0) {
        NSMutableArray *documentArrayIds = [[NSMutableArray alloc] init];
        for (Document *document in documentArray) {
            if (![documentArrayIds containsObject:document.documentID]) {
                [documentArrayIds addObject:document.documentID];
                if ([document.downloaded boolValue] == NO ) {
                    count = count + 1;
                }
            }
        }
    }
    return count;
}

- (void) setDocumentNavigationBadge {
    countRedBadge = [self getDocumentDownloadCount] + [self getBadgeCountForExpiredAircraft:nil];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:countRedBadge];
}

- (NSInteger) getDocumentDownloadCount {
    NSInteger count = 0;
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] && ![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isShown == 1"];
        [groupRequest setPredicate:predicate];
    }
    
    NSError *error;
    NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
    if (groupArray == nil) {
        FDLogError(@"Unable to retrieve lesson group!");
    } else if (groupArray.count == 0) {
        FDLogDebug(@"No groups stored!");
    } else {
        NSMutableArray *arraryDocIds = [[NSMutableArray alloc] init];
        for (LessonGroup *group in groupArray) {
            if (group.parentGroup == nil) {
                for (Document *document in group.documents) {
                    BOOL isExist = NO;
                    for (NSNumber *docID in arraryDocIds) {
                        if ([document.documentID integerValue] == [docID integerValue]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [arraryDocIds addObject:document.documentID];
                        if ([document.downloaded boolValue] == NO ) {
                            count = count + 1;
                        }
                    }
                }
            }
        }
        
        count += [self getMyDocDocumentCount];
    }
    
    if (count == 0) {
        documents_vc.navigationController.tabBarItem.badgeValue = nil;
    }else{
        documents_vc.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
    }
    
    return count;
}



- (NSInteger)getChattingMessageUnreadCount{
    NSInteger count = 0;
    
    for (NSDictionary *dict in [AppDelegate sharedDelegate].unreadData) {
        count = count + [[dict objectForKey:@"unreadCount"] integerValue];
    }
    count = count + unreadGeneralCount;
    if (count == 0) {
        comms_nc.tabBarItem.badgeValue = nil;
    }else{
        comms_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
    }
    countRedBadgeForUnreadMessage = count;
    [AppDelegate sharedDelegate].countRedBadge = [self getDocumentDownloadCount] + [self getBadgeCountForExpiredAircraft:nil];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[AppDelegate sharedDelegate].countRedBadge + countRedBadgeForUnreadMessage];
    [commsMain_vc reloadTableViewWithPush];
    
    [self updateDeviceToken];
    return count;
}

- (void)playingAndStopForMessageToSend{
    NSString *path;
    NSURL *url;
    //where you are about to add sound
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    path =[[NSBundle mainBundle] pathForResource:@"message_send_sound" ofType:@"mp3"];
    url = [NSURL fileURLWithPath:path];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
    [player setVolume:1.0];
    [player prepareToPlay];
    player.numberOfLoops = 1;
    [player play];
}

- (void)playingAndStopForMessageToBeArrived{
    NSString *path;
    NSURL *url;
    
    //where you are about to add sound
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    path =[[NSBundle mainBundle] pathForResource:@"message_arrive_sound" ofType:@"mp3"];
    url = [NSURL fileURLWithPath:path];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
    [player setVolume:1.0];
    [player prepareToPlay];
    player.numberOfLoops = 1;
    [player play];
}

#pragma  mark UITabBarControllerDelegate Methods

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(nonnull UIViewController *)viewController{
    NSLog(@"current selected tab item : %ld", (long)tabBarController.selectedIndex);
    if (currentTabItemIndex != tabBarController.selectedIndex) {
        currentTabItemIndex = rootViewControllerForTab.selectedIndex;
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TAP_TABITEM object:nil userInfo:nil];
    }
    switch (tabBarController.selectedIndex) {
        case 0:
            [tabBarController.tabBar setTintColor:[UIColor blueColor]];
            break;
        case 1:
            [tabBarController.tabBar setTintColor:[UIColor orangeColor]];
            break;
        case 2:
            [tabBarController.tabBar setTintColor:[UIColor colorWithRed:24.0f/255.0f green:140.0f/255.0f blue:0 alpha:1.0f]];
            break;
        case 3:
            [tabBarController.tabBar setTintColor:[UIColor darkGrayColor]];
            break;
        case 4:
            [tabBarController.tabBar setTintColor:[UIColor colorWithRed:190.0f/255.0f green:0.0f blue:1.0f alpha:1.0f]];
            break;
        case 5:
            [tabBarController.tabBar setTintColor:[UIColor purpleColor]];
            break;
        case 6:
            [tabBarController.tabBar setTintColor:[UIColor colorWithRed:1.0f green:140.0f/255.0f blue:0 alpha:1.0f]];
            break;
            
        default:
            break;
    }
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    if ([[url scheme] isEqualToString:@"file"]) {
        if (isLogin) {
            //check aircraft
            NSString *fileNameForAir = [url lastPathComponent];
            NSArray *parseFileNameforAir = [fileNameForAir componentsSeparatedByString:@"."];
            if (parseFileNameforAir.count > 1) {
                NSString *lastString = parseFileNameforAir[parseFileNameforAir.count-1];
                if ([lastString.lowercaseString isEqualToString:@"aircraft"]) {
                    [self parseAircraftFileFromUrl:url];
                    return YES;
                }
            }
            
            NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
            NSError* error = nil;
            NSURLResponse* response = nil;
            [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
            NSString* mimeType = [response MIMEType];
            NSArray *parseFileName = [mimeType componentsSeparatedByString:@"/"];
            if (parseFileName.count > 1) {
                NSString *lastString = parseFileName[parseFileName.count-1];
                if ([lastString.lowercaseString isEqualToString:@"octet-stream"] || [lastString.lowercaseString isEqualToString:@"plain"]){
                    //[rootViewController setSelectedIndex:6];
                    //[more_VC gotoChecklistViewFromImportFunc:url];
                    UINavigationController *currentVC = (UINavigationController *)rootViewControllerForTab.selectedViewController;
                    NSArray *viewconrollerArray  = currentVC.viewControllers;
                    
                    UIViewController *fouceVC = [viewconrollerArray objectAtIndex:[viewconrollerArray count]-1];
                    if ([fouceVC isKindOfClass:[AddCheckListsViewController class]]) {
                        AddCheckListsViewController *addCheckListVC =(AddCheckListsViewController *)fouceVC;
                        [addCheckListVC parseACEFileFromUrl:url];
                    }else{
                        AddCheckListsViewController *mainCheckListVC = [[AddCheckListsViewController alloc] init];
                        mainCheckListVC.isImporedFromOther = YES;
                        mainCheckListVC.importedUrl = url;
                        [currentVC pushViewController:mainCheckListVC animated:YES];
                    }
                    
                }else{
                    [rootViewControllerForTab setSelectedIndex:1];
                    NSString *pdfName = [url lastPathComponent];
                    [documents_vc uploadFileToRedirect:url withRedirectPad:NO];
                }
            }
        }
    }
    return YES;
}
- (void)parseAircraftFileFromUrl:(NSURL *)fileUrl{
    [[AppDelegate sharedDelegate] stopThreadToSyncData:currentSyncingIndex];
    NSData *dataOfAircraft = [NSData dataWithContentsOfURL:fileUrl];
    NSString *strToParseAircraftData = [[NSString alloc] initWithData:dataOfAircraft encoding:NSUTF8StringEncoding];
    NSMutableArray *arrayToParseWithLine = [[strToParseAircraftData componentsSeparatedByString:@"*!*END*!*"] mutableCopy];
    NSError *error;
    NSManagedObjectContext *contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    //save created aircraft into local
    Aircraft *aircraft = [NSEntityDescription insertNewObjectForEntityForName:@"Aircraft" inManagedObjectContext:contextRecords];
    aircraft.aircraftID = @(0);
    aircraft.aircraftItems = arrayToParseWithLine[0];
    aircraft.maintenanceItems = arrayToParseWithLine[3];
    aircraft.avionicsItems = arrayToParseWithLine[1];
    aircraft.liftLimitedParts = arrayToParseWithLine[2];
    aircraft.otherItems = arrayToParseWithLine[4];
    aircraft.squawksItems = arrayToParseWithLine[5];
    
    aircraft.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    aircraft.valueForSort = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    aircraft.aircraft_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    aircraft.lastUpdate = @(0);
    
    NSString *maintenceLogsStr = arrayToParseWithLine[6];
    NSData *data = [maintenceLogsStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *maintenceLogsArray = [[NSMutableArray alloc] init];
    if (data != nil){
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]  ;
        maintenceLogsArray = [json mutableCopy];
    }
    for (NSDictionary *oneMainLog in maintenceLogsArray) {
        MaintenanceLogs *maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:contextRecords];
        maintenanceLogs.maintenancelog_id = @0;
        maintenanceLogs.recordsLocal_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        maintenanceLogs.file_url = [oneMainLog objectForKey:@"file_url"];
        maintenanceLogs.local_url = @"";
        maintenanceLogs.file_name = [oneMainLog objectForKey:@"file_name"];
        maintenanceLogs.fileSize = [oneMainLog objectForKey:@"fileSize"];
        maintenanceLogs.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        maintenanceLogs.lastUpdate = @0;
        maintenanceLogs.user_id = [oneMainLog objectForKey:@"user_id"];
        maintenanceLogs.aircraft_local_id = aircraft.aircraft_local_id;
        maintenanceLogs.fileType = [oneMainLog objectForKey:@"fileType"];
        maintenanceLogs.thumb_url = [oneMainLog objectForKey:@"thumb_url"];
        maintenanceLogs.isUploaded = @1;
        [contextRecords save:&error];
    }
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [_aircraft_vc reloadData];
    [self showAlert:@"Imported successfully, Please check the Aircrafts of Settings" :@"FlightDesk"];
    [[AppDelegate sharedDelegate] startThreadToSyncData:currentSyncingIndex];
}
-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        //NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    
    if (isLogin) {
        [self Logout];
    }
    //[self removeAllCalendarForResources];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [christmasPlayer stop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    //[self removeAllCalendarForResources];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if (isLogin) {
        [self getUnreadMessagesCount];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (isLogin) {
        [self returnToActivity];
        [self getUnreadMessagesCount];
//        if ([AppDelegate sharedDelegate].scheduleMain_VC && [AppDelegate sharedDelegate].isLoadedScheduleViewAtOnce == YES) {
//            if ([AppDelegate sharedDelegate].isShownScheduleView == YES) {
//                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
//                NSString *loadingMsg = @"Please wait, your data is being restored";
//                hud.label.text = loadingMsg;
//            }
//            [[AppDelegate sharedDelegate].scheduleMain_VC getInitialDataFromLocal];
//        }
    }
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    if (isLogin) {
        [self Logout];
    }
    
    //[self removeAllCalendarForResources];
    
    [christmasPlayer stop];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}
- (void)messaging:(nonnull FIRMessaging *)messaging didRefreshRegistrationToken:(nonnull NSString *)fcmToken {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSLog(@"FCM registration token: %@", fcmToken);
     [self connectToFcm];
    // TODO: If necessary send token to application server.
    if (isLogin) {
        [self savePilotProfileToLocal];
        [self updateDeviceToken];
    }
}
- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
//    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
//    NSLog(@"InstanceID token: %@", refreshedToken);
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    
    // TODO: If necessary send token to application server.
    if (isLogin) {
        [self savePilotProfileToLocal];
        [self updateDeviceToken];
    }
}
- (void)connectToFcm {
    NSString *fcmToken = [FIRMessaging messaging].FCMToken;
    NSLog(@"fcmToken : %@", fcmToken);
    // Won't connect since there is no token
//    if (![[FIRInstanceID instanceID] token]) {
//        return;
//    }
    if (fcmToken != nil) {
        device_token = fcmToken;
    }
    if (isLogin) {
        [self savePilotProfileToLocal];
        [self updateDeviceToken];
    }
//    [[FIRMessaging messaging] disconnect];
    // connect to fcm.
    [[FIRMessaging messaging] setShouldEstablishDirectChannel:YES];
}

- (void)updateDeviceToken{
    NSError *error;
    [AppDelegate sharedDelegate].countRedBadge = [self getDocumentDownloadCount];
    NSInteger countOfBadge = [AppDelegate sharedDelegate].countRedBadge + countRedBadgeForUnreadMessage;
    
    NSDateFormatter *localTimeZoneFormatter = [NSDateFormatter new];
    localTimeZoneFormatter.timeZone = [NSTimeZone localTimeZone];
    localTimeZoneFormatter.dateFormat = @"Z";
    NSString *localTimeZoneOffset = [localTimeZoneFormatter stringFromDate:[NSDate date]];
    NSLog(@"%@", localTimeZoneOffset);
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"update_device_token", @"action", [AppDelegate sharedDelegate].userId, @"user_id", device_token, @"device_token", @(countOfBadge), @"badgeCount", nil];
    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"success");
                });
                
            }else{
                //FDLogError(@"failed to update deivce token");
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
}

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Receive data message on iOS 10 devices while app is in the foreground.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    // Print full message
    NSLog(@"%@", remoteMessage.appData);
    
    [self HandlePushNotificationWithRemoteMessage:remoteMessage.appData];
}
#endif

- (void)Logout{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"logout", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
    NSData *logoutJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveRequest = [NSMutableURLRequest requestWithURL:saveURL];
    [saveRequest setHTTPMethod:@"POST"];
    [saveRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)logoutJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveRequest setHTTPBody:logoutJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([[results objectForKey:@"success"] boolValue]) {
                
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while logout";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    
    [self sendPushForLogInOut:0];
    [uploadQuizRecordsTask resume];
}

- (void)sendPushForLogInOut:(int)online{
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]) {
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve LessonGroups!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid LessonGroup found!");
        } else {
            for (LessonGroup *lessonGroup in objects) {
                if ([lessonGroup.instructorID integerValue] != 0 && ![lessonGroup.instructorName.lowercaseString isEqualToString:@"admin"]) {
                    
                    NSMutableDictionary *dicToSendPush = [[NSMutableDictionary alloc] init];
                    [dicToSendPush setObject:device_token forKey:@"fromToken"];
                    [dicToSendPush setObject:[NSNumber numberWithInt:online] forKey:@"onOffStatus"];
                    [dicToSendPush setObject:@"loginout" forKey:@"pushType"];
                    [dicToSendPush setObject:@"" forKey:@"title"];
                    
                    NSError *error;
                    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:lessonGroup.instructorDeviceToken, @"to", dicToSendPush, @"notification", nil];
                    NSLog(@"LogOut Devicetoken:%@", lessonGroup.instructorDeviceToken);
                    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
                    NSString *apiURLString = @"https://fcm.googleapis.com/fcm/send";
                    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
                    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
                    [saveLessonsRequest setHTTPMethod:@"POST"];
                    [saveLessonsRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                    [saveLessonsRequest setValue:@"key=AAAALU8yQXs:APA91bGpmsPOYmhm7IyldmsgDSAedCMjxvEOEYN_0zzSecQn67ZUWTdZ_3PlUY-CPlfqPkFzvZHmlzh2XeguVbrxLo7h7OOtQdodWipTdhvv44-AMVpKxz1EKFP0aTW0WTD52TSEcX9e" forHTTPHeaderField:@"Authorization"];
                    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
                    
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
                        // handle the documents update
                        if (data != nil) {
                            NSError *error;
                            // parse the query results
                            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                            if (error != nil) {
                                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                                return;
                            }
                            if ([[queryResults objectForKey:@"success"] boolValue]) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    //NSLog(@"success");
                                });
                                
                            }else{
                                //FDLogError(@"failed to update deivce token");
                            }
                        } else {
                            NSString *errorText;
                            if (responseError != nil) {
                                errorText = [responseError localizedDescription];
                            } else {
                                errorText = @"An unknown error occurred while uploading queries";
                            }
                            FDLogError(@"%@", errorText);
                        }
                    }];
                    [uploadLessonRecordsTask resume];

                    }
                }
            
        }
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            for (Student *student in objects) {
                NSMutableDictionary *dicToSendPush = [[NSMutableDictionary alloc] init];
                [dicToSendPush setObject:device_token forKey:@"fromToken"];
                [dicToSendPush setObject:[NSNumber numberWithInt:online] forKey:@"onOffStatus"];
                [dicToSendPush setObject:@"loginout" forKey:@"pushType"];
                [dicToSendPush setObject:@"" forKey:@"title"];
                
                NSError *error;
                NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:student.deviceToken, @"to", dicToSendPush, @"notification", nil];
                
                NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
                NSString *apiURLString = @"https://fcm.googleapis.com/fcm/send";
                NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
                NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
                [saveLessonsRequest setHTTPMethod:@"POST"];
                [saveLessonsRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [saveLessonsRequest setValue:@"key=AAAALU8yQXs:APA91bGpmsPOYmhm7IyldmsgDSAedCMjxvEOEYN_0zzSecQn67ZUWTdZ_3PlUY-CPlfqPkFzvZHmlzh2XeguVbrxLo7h7OOtQdodWipTdhvv44-AMVpKxz1EKFP0aTW0WTD52TSEcX9e" forHTTPHeaderField:@"Authorization"];
                [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
                
                NSURLSession *session = [NSURLSession sharedSession];
                NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
                    // handle the documents update
                    if (data != nil) {
                        NSError *error;
                        // parse the query results
                        NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                        if (error != nil) {
                            NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                            return;
                        }
                        if ([[queryResults objectForKey:@"success"] boolValue]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //NSLog(@"success");
                            });
                            
                        }else{
                            //FDLogError(@"failed to update deivce token");
                        }
                    } else {
                        NSString *errorText;
                        if (responseError != nil) {
                            errorText = [responseError localizedDescription];
                        } else {
                            errorText = @"An unknown error occurred while uploading queries";
                        }
                        FDLogError(@"%@", errorText);
                    }
                }];
                [uploadLessonRecordsTask resume];

            }
        }
    }
}

- (void)returnToActivity{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"returnLogin", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
    NSData *logoutJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveRequest = [NSMutableURLRequest requestWithURL:saveURL];
    [saveRequest setHTTPMethod:@"POST"];
    [saveRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)logoutJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveRequest setHTTPBody:logoutJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([[results objectForKey:@"success"] boolValue]) {
                
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while logout";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadQuizRecordsTask resume];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.persistentCoreDataStack.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            FDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    NSLog( @"Handle push from foreground" );
    // custom code to handle push while app is in the foreground
    NSLog(@"userinfo----%@",notification.request.content.userInfo);
    
    [self HandlePushNotification:notification.request.content.userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler
{
    NSLog( @"Handle push from background or closed" );
    // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
    NSLog(@"%@", response.notification.request.content.userInfo);
    
    [self HandlePushNotification:response.notification.request.content.userInfo];
}
-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"here");
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [FIRMessaging messaging].APNSToken = deviceToken;
    [self connectToFcm];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    
    // Print message ID.
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
    }
    
    // Print full message.
    [self HandlePushNotification:userInfo];
    
    completionHandler(UIBackgroundFetchResultNewData);
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //[self application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
    
    // iOS 10 will handle notifications through other methods
    
    if( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO( @"10.0" ) )
    {
        NSLog( @"iOS version >= 10. Let NotificationCenter handle this one." );
        // set a member variable to tell the new delegate that this is background
        //return;
    }
    // Print message ID.
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
    }
    [self HandlePushNotification:userInfo];
    
    
    //}];
}
- (void)HandlePushNotificationWithRemoteMessage:(NSDictionary *)userInfo{
    NSString *titleFromNote = [[userInfo objectForKey:@"notification"]  objectForKey:@"title"];
    NSString *bodyFromNote = [[userInfo objectForKey:@"notification"]  objectForKey:@"body"];
    NSString *pushType = [[userInfo objectForKey:@"notification"] objectForKey:@"pushType"];
    if ([pushType isEqualToString:@"loginout"]) {
        NSString *fromToken = [[userInfo objectForKey:@"notification"] objectForKey:@"fromToken"];
        NSNumber *mStatus = [[userInfo objectForKey:@"notification"] objectForKey:@"onOffStatus"];
        [commsMain_vc reloadTableViewWithOnlineStatus:fromToken onLinevalue:mStatus];
    }
    else if ([pushType isEqualToString:@"chat"]) {
        NSNumber *boardID =[NSNumber numberWithInteger:[[[userInfo objectForKey:@"notification"] objectForKey:@"boardID"] integerValue]];
        NSString *searchKey = [[userInfo objectForKey:@"notification"] objectForKey:@"seachKey"];
        NSNumber *messageIDToCheck = [NSNumber numberWithInteger:[[[userInfo objectForKey:@"notification"] objectForKey:@"message_id"] integerValue]];
        NSNumber *userIDToUpdate = [NSNumber numberWithInteger:[[[userInfo objectForKey:@"notification"] objectForKey:@"sent_user_id"] integerValue]];
        NSNumber *targetIDToUpdate = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
        NSString *messageType = [[userInfo objectForKey:@"notification"] objectForKey:@"messageType"];
        NSString *dateString = [[userInfo objectForKey:@"notification"] objectForKey:@"lastupdate"];
        
        
        if ([AppDelegate sharedDelegate].isShownChatBoard == NO || ([boardID integerValue] != currentBoardID && [AppDelegate sharedDelegate].isShownChatBoard == YES)) {
            [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
            
            [JCNotificationCenter
             enqueueNotificationWithTitle:titleFromNote
             message:bodyFromNote
             tapHandler:^{
                 
             }];
            
            [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
            
        }
        NSMutableDictionary *dictToReplaceWithCount;
        NSInteger indexToReplace = 0;
        for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
            NSDictionary *dict = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
            if ([[dict objectForKey:@"userID"] integerValue] == [userIDToUpdate integerValue]) {
                dictToReplaceWithCount = [dict mutableCopy];
                indexToReplace = i;
            }
        }
        
        if ([boardID integerValue] == 999999) {
            unreadGeneralCount = unreadGeneralCount + 1;
        }else{
            
            if (dictToReplaceWithCount) {
                NSInteger count = [[dictToReplaceWithCount objectForKey:@"unreadCount"] integerValue];
                [dictToReplaceWithCount setObject:@(count + 1) forKey:@"unreadCount"];
                [[AppDelegate sharedDelegate].unreadData replaceObjectAtIndex:indexToReplace withObject:dictToReplaceWithCount];
            }else{
                
                NSMutableDictionary *dictToAddWithBadgesCountAndUserID = [[NSMutableDictionary alloc] init];
                [dictToAddWithBadgesCountAndUserID setObject:userIDToUpdate forKey:@"userID"];
                NSInteger count = 0;
                [dictToAddWithBadgesCountAndUserID setObject:@(count + 1) forKey:@"unreadCount"];
                [[AppDelegate sharedDelegate].unreadData addObject:dictToAddWithBadgesCountAndUserID];
            }
        }
        
        
        //        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:self.persistentCoreDataStack.managedObjectContext];
        //        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        //        [request setEntity:entityDesc];
        //        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageID == %@", messageIDToCheck];
        //        [request setPredicate:predicate];
        //        NSError *error;
        //        NSArray *objects = [self.persistentCoreDataStack.managedObjectContext executeFetchRequest:request error:&error];
        //
        //        ChatHistory *chatHistory = nil;
        //        if (objects == nil) {
        //            FDLogError(@"Unable to retrieve Board!");
        //        } else if (objects.count == 0) {
        //            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:self.persistentCoreDataStack.managedObjectContext];
        //            chatHistory.boardID = boardID;
        //            chatHistory.messageID = messageIDToCheck;
        //            chatHistory.userID = userIDToUpdate;
        //            chatHistory.target_userID = targetIDToUpdate;
        //            chatHistory.type = messageType;
        //            chatHistory.sentTime = dateString;
        //            chatHistory.searchKey = searchKey;
        //            chatHistory.isRead = @(0);
        //
        //            if ([userInfo objectForKey:@"gcm.notification.fromName"]) {
        //                chatHistory.targetName = [userInfo objectForKey:@"gcm.notification.fromName"];
        //            }
        //
        //            if ([messageType isEqualToString:@"text"]) {
        //                chatHistory.message = [userInfo objectForKey:@"gcm.notification.message"];
        //            }else if ([messageType isEqualToString:@"image"]) {
        //                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
        //                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
        //            }else if ([messageType isEqualToString:@"video"]) {
        //                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
        //                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
        //                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
        //            }else if ([messageType isEqualToString:@"pdf"]) {
        //                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
        //                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
        //                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
        //            }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
        //                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
        //            }
        //        } else if (objects.count == 1){
        //            if ([boardID integerValue] != currentBoardID) {
        //                chatHistory = objects[0];
        //                chatHistory.isRead = @(0);
        //            }
        //        }else{
        //
        //        }
        //
        //
        //        if (chatHistory.message == nil) {
        //            chatHistory.message = @"";
        //        }
        //        if (chatHistory.fileUrl == nil) {
        //            chatHistory.fileUrl = @"";
        //        }
        //        if (chatHistory.thumbImageSize == nil) {
        //            chatHistory.thumbImageSize = @"";
        //        }
        //        if (chatHistory.thumbUrl == nil) {
        //            chatHistory.thumbUrl = @"";
        //        }
        //
        //        if (chatHistory != nil) {
        //            [self.persistentCoreDataStack.managedObjectContext save:&error];
        //            if (error) {
        //                NSLog(@"Error when saving managed object context : %@", error);
        //            }
        //        }
        if (commsMain_vc) {
            [commsMain_vc reloadTableViewWithPush];
        }
        [self getChattingMessageUnreadCount];
    }else if ([pushType isEqualToString:@"banner"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        NSString *messageType = [[userInfo objectForKey:@"notification"] objectForKey:@"messageType"];
        if ([messageType isEqualToString:@"text"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForText" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[[userInfo objectForKey:@"notification"] objectForKey:@"bannerColor"] forKey:@"bgColor"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[[userInfo objectForKey:@"notification"] objectForKey:@"message"] forKey:@"message"];
        }else if ([messageType isEqualToString:@"image"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForImage" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[[userInfo objectForKey:@"notification"] objectForKey:@"thumbUrl"] forKey:@"thumbURL"];
        }else if ([messageType isEqualToString:@"gifbanner"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForGif" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[[userInfo objectForKey:@"notification"] objectForKey:@"thumbUrl"] forKey:@"thumbURL"];
        }
        
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc reloadBannerView];
        }
    }else if ([pushType isEqualToString:@"bannerClear"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc clearBannerWithPush];
        }
    }else if ([pushType isEqualToString:@"messageClear"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc clearGeneralMessages];
        }
    }else if ([pushType isEqualToString:@"requestSupport"]) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            if (commsMain_vc != nil) {
                [commsMain_vc getUsersWhatRequestSupports];
            }
        }
    }else if ([pushType isEqualToString:@"cancelRequestSupport"]) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            if (commsMain_vc != nil) {
                [commsMain_vc getUsersWhatRequestSupports];
            }
        }
    }
}
- (void)HandlePushNotification:(NSDictionary *)userInfo{
    
    NSString *titleFromNote = [[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"title"];
    NSString *bodyFromNote = [[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"];
    
    NSString *pushType = [userInfo objectForKey:@"gcm.notification.pushType"];
    if ([pushType isEqualToString:@"loginout"]) {
        NSString *fromToken = [userInfo objectForKey:@"gcm.notification.fromToken"];
        NSNumber *mStatus = [userInfo objectForKey:@"gcm.notification.onOffStatus"];
        [commsMain_vc reloadTableViewWithOnlineStatus:fromToken onLinevalue:mStatus];
    }
    else if ([pushType isEqualToString:@"chat"]) {
        NSNumber *boardID =[NSNumber numberWithInteger:[[userInfo objectForKey:@"gcm.notification.boardID"] integerValue]];
        NSNumber *userIDToUpdate = [NSNumber numberWithInteger:[[userInfo objectForKey:@"gcm.notification.sent_user_id"] integerValue]];        
        
        if ([AppDelegate sharedDelegate].isShownChatBoard == NO || ([boardID integerValue] != currentBoardID && [AppDelegate sharedDelegate].isShownChatBoard == YES)) {
            [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
            
            [JCNotificationCenter
             enqueueNotificationWithTitle:titleFromNote
             message:bodyFromNote
             tapHandler:^{
                 
             }];
            
            [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];

        }
        NSMutableDictionary *dictToReplaceWithCount;
        NSInteger indexToReplace = 0;
        for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
            NSDictionary *dict = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
            if ([[dict objectForKey:@"userID"] integerValue] == [userIDToUpdate integerValue]) {
                dictToReplaceWithCount = [dict mutableCopy];
                indexToReplace = i;
            }
        }
        
        if ([boardID integerValue] == 999999) {
            unreadGeneralCount = unreadGeneralCount + 1;
        }else{
            
            if (dictToReplaceWithCount) {
                NSInteger count = [[dictToReplaceWithCount objectForKey:@"unreadCount"] integerValue];
                [dictToReplaceWithCount setObject:@(count + 1) forKey:@"unreadCount"];
                [[AppDelegate sharedDelegate].unreadData replaceObjectAtIndex:indexToReplace withObject:dictToReplaceWithCount];
            }else{
                
                NSMutableDictionary *dictToAddWithBadgesCountAndUserID = [[NSMutableDictionary alloc] init];
                [dictToAddWithBadgesCountAndUserID setObject:userIDToUpdate forKey:@"userID"];
                NSInteger count = 0;
                [dictToAddWithBadgesCountAndUserID setObject:@(count + 1) forKey:@"unreadCount"];
                [[AppDelegate sharedDelegate].unreadData addObject:dictToAddWithBadgesCountAndUserID];
            }
        }
        
        
//        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:self.persistentCoreDataStack.managedObjectContext];
//        NSFetchRequest *request = [[NSFetchRequest alloc] init];
//        [request setEntity:entityDesc];
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageID == %@", messageIDToCheck];
//        [request setPredicate:predicate];
//        NSError *error;
//        NSArray *objects = [self.persistentCoreDataStack.managedObjectContext executeFetchRequest:request error:&error];
//        
//        ChatHistory *chatHistory = nil;
//        if (objects == nil) {
//            FDLogError(@"Unable to retrieve Board!");
//        } else if (objects.count == 0) {
//            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:self.persistentCoreDataStack.managedObjectContext];
//            chatHistory.boardID = boardID;
//            chatHistory.messageID = messageIDToCheck;
//            chatHistory.userID = userIDToUpdate;
//            chatHistory.target_userID = targetIDToUpdate;
//            chatHistory.type = messageType;
//            chatHistory.sentTime = dateString;
//            chatHistory.searchKey = searchKey;
//            chatHistory.isRead = @(0);
//            
//            if ([userInfo objectForKey:@"gcm.notification.fromName"]) {
//                chatHistory.targetName = [userInfo objectForKey:@"gcm.notification.fromName"];
//            }
//            
//            if ([messageType isEqualToString:@"text"]) {
//                chatHistory.message = [userInfo objectForKey:@"gcm.notification.message"];
//            }else if ([messageType isEqualToString:@"image"]) {
//                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
//                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
//            }else if ([messageType isEqualToString:@"video"]) {
//                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
//                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
//                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
//            }else if ([messageType isEqualToString:@"pdf"]) {
//                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
//                chatHistory.thumbUrl = [userInfo objectForKey:@"gcm.notification.thumbUrl"];
//                chatHistory.thumbImageSize = [userInfo objectForKey:@"gcm.notification.thumbImageSize"];
//            }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
//                chatHistory.fileUrl = [userInfo objectForKey:@"gcm.notification.fileUrl"];
//            }
//        } else if (objects.count == 1){
//            if ([boardID integerValue] != currentBoardID) {
//                chatHistory = objects[0];
//                chatHistory.isRead = @(0);
//            }
//        }else{
//            
//        }
//        
//        
//        if (chatHistory.message == nil) {
//            chatHistory.message = @"";
//        }
//        if (chatHistory.fileUrl == nil) {
//            chatHistory.fileUrl = @"";
//        }
//        if (chatHistory.thumbImageSize == nil) {
//            chatHistory.thumbImageSize = @"";
//        }
//        if (chatHistory.thumbUrl == nil) {
//            chatHistory.thumbUrl = @"";
//        }
//        
//        if (chatHistory != nil) {
//            [self.persistentCoreDataStack.managedObjectContext save:&error];
//            if (error) {
//                NSLog(@"Error when saving managed object context : %@", error);
//            }
//        }
        if (commsMain_vc) {
            [commsMain_vc reloadTableViewWithPush];
        }
        [self getChattingMessageUnreadCount];
    }else if ([pushType isEqualToString:@"banner"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        NSString *messageType = [userInfo objectForKey:@"gcm.notification.messageType"];
        if ([messageType isEqualToString:@"text"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForText" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[userInfo objectForKey:@"gcm.notification.bannerColor"] forKey:@"bgColor"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[userInfo objectForKey:@"gcm.notification.message"] forKey:@"message"];
        }else if ([messageType isEqualToString:@"image"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForImage" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[userInfo objectForKey:@"gcm.notification.thumbUrl"] forKey:@"thumbURL"];
        }else if ([messageType isEqualToString:@"gifbanner"]) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:@"bannerForGif" forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[userInfo objectForKey:@"gcm.notification.thumbUrl"] forKey:@"thumbURL"];
        }
        
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc reloadBannerView];
        }
    }else if ([pushType isEqualToString:@"bannerClear"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc clearBannerWithPush];
        }
    }else if ([pushType isEqualToString:@"messageClear"]) {
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
        
        [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
        if ([AppDelegate sharedDelegate].liveChat_vc) {
            [[AppDelegate sharedDelegate].liveChat_vc clearGeneralMessages];
        }
    }else if ([pushType isEqualToString:@"requestSupport"]) {
        
    }else if ([pushType isEqualToString:@"cancelRequestSupport"]) {
        
    }else if([pushType isEqualToString:@"addedReservation"]){
        
        [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterSmokeStyle new];
        
        [JCNotificationCenter
         enqueueNotificationWithTitle:titleFromNote
         message:bodyFromNote
         tapHandler:^{
             
         }];
    }else if(pushType == nil){
        NSString *pushTypeForOther = [userInfo objectForKey:@"pushType"];
        if ([pushTypeForOther isEqualToString:@"reservationNotification"]) {
            NSString *eventIdentify = [userInfo objectForKey:@"eventIdentify"];
            if (eventIdentify != nil && ![eventIdentify isEqualToString:@""]) {
                [rootViewControllerForTab setSelectedIndex:5];
                [self performSelector:@selector(redirectToScheduleView:) withObject:eventIdentify afterDelay:0.5];
            }
        }
    }
}
- (void)redirectToScheduleView:(NSString*)eventIdentify{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CLOSE_DASHBOARD object:nil userInfo:nil];
    [scheduleMain_VC redirectFromPush:eventIdentify];
}
#pragma mark - Core Data stack

- (NSURL*)storeURL
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"FlightDesk.sqlite"];
}

- (NSURL*)modelURL
{
    return [[NSBundle mainBundle] URLForResource:@"FlightDesk" withExtension:@"momd"];
}



//get unread badges count from server when you open app or active
- (void)getUnreadMessagesCount{
    
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *apiURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL];
    NSString *type;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        type = @"1";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]){
        type = @"3";
    }else{
        type = @"2";
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"getBadgeCount", @"action", userId, @"user_id", nil];
    NSError *error;
    NSData *jsonRequestData =[NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)jsonRequestData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonRequestData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *documentsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil) {
                    FDLogError(@"Unable to parse JSON for list!");
                    return;
                }
                
                if ([results objectForKey:@"success"]) {
                    id value = [results objectForKey:@"badges_users"];
                    if ([value isKindOfClass:[NSArray class]]) {
                        NSArray *badgesArray = value;
                        [[AppDelegate sharedDelegate].unreadData  removeAllObjects];
                        for (id badgesElement in badgesArray) {
                            if ([badgesElement isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *badgesDetails = badgesElement;
                                
                                NSMutableDictionary *dictToReplaceWithCount;
                                NSInteger indexToReplace = 0;
                                for (int i = 0; i < [[AppDelegate sharedDelegate].unreadData count]; i ++) {
                                    NSDictionary *dict = [[AppDelegate sharedDelegate].unreadData objectAtIndex:i];
                                    if ([[dict objectForKey:@"userID"] integerValue] == [[badgesDetails objectForKey:@"userID"] integerValue]) {
                                        dictToReplaceWithCount = [dict mutableCopy];
                                        indexToReplace = i;
                                    }
                                }
                                
                                if (dictToReplaceWithCount) {
                                    NSInteger count = [[dictToReplaceWithCount objectForKey:@"unreadCount"] integerValue];
                                    [dictToReplaceWithCount setObject:@(count + 1) forKey:@"unreadCount"];
                                    [[AppDelegate sharedDelegate].unreadData replaceObjectAtIndex:indexToReplace withObject:dictToReplaceWithCount];
                                }else{
                                    
                                    NSMutableDictionary *dictToAddWithBadgesCountAndUserID = [[NSMutableDictionary alloc] init];
                                    [dictToAddWithBadgesCountAndUserID setObject:[badgesDetails objectForKey:@"userID"] forKey:@"userID"];
                                    NSInteger count = 0;
                                    [dictToAddWithBadgesCountAndUserID setObject:@(count + 1) forKey:@"unreadCount"];
                                    [[AppDelegate sharedDelegate].unreadData addObject:dictToAddWithBadgesCountAndUserID];
                                }
                                
                            }
                        }
                    }
                    [AppDelegate sharedDelegate].unreadGeneralCount = [[results objectForKey:@"unread_general"] integerValue];
                    [[AppDelegate sharedDelegate] savePilotProfileToLocal];
                    [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
                }
            });
        } else {
            if (responseError != nil) {
                FDLogError(@"Unable to download documents: %@", [responseError localizedDescription]);
            } else {
                FDLogError(@"Unable to download documents due to unknown error!");
            }
        }
    }];
    [documentsTask resume];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"%@",[paths objectAtIndex:0]);
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


-(void)gotoMainView{
    NSMutableArray *tabItems = [[NSMutableArray alloc] initWithCapacity:4];
    
    // Setup records view controller
    records_vc = [[RecordsViewController alloc] init];
    UINavigationController *records_nc = [[UINavigationController alloc] initWithRootViewController:records_vc];
    records_nc.tabBarItem.title = @"Programs";
    records_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Programs" ofType:@"png"]];
    [tabItems addObject:records_nc];
    
    [AppDelegate sharedDelegate].countRedBadge = [self getDocumentDownloadCount] + [self getBadgeCountForExpiredAircraft:nil];
    // Setup documents view controller
    documents_vc = [[DocumentsViewController alloc] init];
    UINavigationController *documents_nc = [[UINavigationController alloc] initWithRootViewController:documents_vc];
    documents_nc = [[UINavigationController alloc] initWithRootViewController:documents_vc];
    documents_nc.tabBarItem.title = @"Materials";
    documents_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Materials" ofType:@"png"]];
    documents_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)[AppDelegate sharedDelegate].countRedBadge];
    [tabItems addObject:documents_nc];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[AppDelegate sharedDelegate].countRedBadge];
    // Setup quizes view controller
    quizses_VC = [[QuizesViewController alloc] init];
    UINavigationController *quizes_nc = [[UINavigationController alloc] initWithRootViewController:quizses_VC];
    quizes_nc.tabBarItem.title = @"Quizzes";
    quizes_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Quizes" ofType:@"png"]];
    [tabItems addObject:quizes_nc];
    
    // Setup logbook view controller
    logbook_vc = [[LogbookViewController alloc] init];
    UINavigationController *logbook_nc = [[UINavigationController alloc] initWithRootViewController:logbook_vc];
    logbook_nc.tabBarItem.title = @"Logbook";
    logbook_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Logbook" ofType:@"png"]];
    [tabItems addObject:logbook_nc];
    
    // Setup communication view controller
    commsMain_vc = [[CommsMainViewController alloc] initWithNibName:@"CommsMainViewController" bundle:nil];
    NSArray *controllers = @[commsMain_vc];
    splitViewControllerOfChatting = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewControllerOfChatting.delegate = self;
    comms_nc = [[UINavigationController alloc] initWithRootViewController:splitViewControllerOfChatting];
    comms_nc.tabBarItem.title = @"Comms";
    comms_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NewComms" ofType:@"png"]];
    
    NSInteger unReadMessageCount = [self getChattingMessageUnreadCount];
    if (unReadMessageCount != 0) {
        comms_nc.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)unReadMessageCount];
    }
    [tabItems addObject:comms_nc];
    
    
    // Setup calendar view controller
    // 1. Instantiate a CKCalendarViewController
//    CKCalendarViewController *calendar_vc = [CKCalendarViewController new];
//    //[calendar_vc setDelegate:self];
//    //[calendar_vc setDataSource:self];
//    calendar_vc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Calendar" ofType:@"png"]];
//    calendar_vc.tabBarItem.title = @"Schedule";
//    [tabItems addObject:calendar_vc];

    scheduleMain_VC = [[ScheduleMainViewController alloc] init];
    UINavigationController *schedule_nc = [[UINavigationController alloc] initWithRootViewController:scheduleMain_VC];
    schedule_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Calendar" ofType:@"png"]];
    schedule_nc.tabBarItem.title = @"Schedule";
    [tabItems addObject:schedule_nc];
    
    // Setup more view controller
    more_VC = [[MoreViewController alloc] init];
    UINavigationController *more_nc = [[UINavigationController alloc] initWithRootViewController:more_VC];
    more_nc.tabBarItem.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Calcs" ofType:@"png"]];
    more_nc.tabBarItem.title = @"More";
    [tabItems addObject:more_nc];
    
    // Setup the root view controller
    rootViewControllerForTab = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    rootViewControllerForTab.viewControllers = tabItems;
    rootViewControllerForTab.delegate = self;
    // Assign root view controller
    self.window.rootViewController = rootViewControllerForTab;
    
    if ([AppDelegate sharedDelegate].isLogin && [AppDelegate sharedDelegate].isVerify == 1) {
        if ([AppDelegate sharedDelegate].isBackPreUser == NO) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
            NSString *loadingMsg = @"Please wait, your data is being restored to this new app install or to this new login";
            if (isRegister == YES) {
                isRegister = NO;
                loadingMsg = @"Loading programs data...";
            }
            hud.label.text = loadingMsg;
        }
        // make sure the sync manager is initialized with the background managed object context
        [self startThreadToSyncData:1];
    }
}

- (void)startThreadToSyncData:(NSInteger)index{
    if ([userLevel isEqualToString:@"Support"] && index != 1) {
        return;
    }
    currentSyncingIndex = index;
    switch (index) {
        case 1://sync data from server first
            if (self.syncNamagerNoUpload == nil) {
                self.syncNamagerNoUpload = [[SyncManagerNoUpload alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
            
        case 2://sync lesson and logs
            if (self.syncManagerLessonLog == nil) {
                self.syncManagerLessonLog = [[SyncManagerLessonLog alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 3://sync document
            if (self.syncManagerDocument == nil) {
                self.syncManagerDocument = [[SyncManagerDocument alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 4://sync quiz
            if (self.syncManagerQuiz == nil) {
                self.syncManagerQuiz = [[SyncManagerQuiz alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 5://sync aircraft
            if (self.syncManagerAirCraft == nil) {
                self.syncManagerAirCraft = [[SyncManagerAircraft alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 6://sync more tools
            if (self.syncManagerMoreTools == nil) {
                self.syncManagerMoreTools = [[SyncManagerMoreTools alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 7://sync RecordsFiles
            if (self.syncManagerRecordsFiles == nil) {
                self.syncManagerRecordsFiles = [[SyncManagerRecordsFiles alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 8://sync Generalcontent
            if (self.syncManagerGeneral == nil) {
                self.syncManagerGeneral = [[SyncManagerGeneral alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        case 9://sync Resources calendar
            if (self.syncManagerResourcesCalendar == nil) {
                self.syncManagerResourcesCalendar = [[SyncManagerResourcesCalendar alloc] initWithContext:self.persistentCoreDataStack.managedObjectContext];
            }
            break;
        default:
            break;
    }
}
- (void)stopThreadToSyncData:(NSInteger)index{
    switch (index) {
        case 1://sync data from server first
            if (self.syncNamagerNoUpload != nil) {
                [self.syncNamagerNoUpload cancelSycnTimer];
                self.syncNamagerNoUpload = nil;
            }
            break;
            
        case 2://stop to sync lesson and logs
            if (self.syncManagerLessonLog != nil) {
                [self.syncManagerLessonLog cancelSycnTimer];
                self.syncManagerLessonLog = nil;
            }
            break;
        case 3://stop to sync document
            if (self.syncManagerDocument != nil) {
                [self.syncManagerDocument cancelSycnTimer];
                self.syncManagerDocument = nil;
            }
            break;
        case 4://stop to sync document
            if (self.syncManagerQuiz != nil) {
                [self.syncManagerQuiz cancelSycnTimer];
                self.syncManagerQuiz = nil;
            }
        case 5://stop to sync aircraft
            if (self.syncManagerAirCraft != nil) {
                [self.syncManagerAirCraft cancelSycnTimer];
                self.syncManagerAirCraft = nil;
            }
            break;
        case 6://stop to sync more tools
            if (self.syncManagerMoreTools != nil) {
                [self.syncManagerMoreTools cancelSycnTimer];
                self.syncManagerMoreTools = nil;
            }
            break;
        case 7://stop to sync RecordsFiles
            if (self.syncManagerRecordsFiles != nil) {
                [self.syncManagerRecordsFiles cancelSycnTimer];
                self.syncManagerRecordsFiles = nil;
            }
        case 8://stop to sync Generalcontent
            if (self.syncManagerGeneral != nil) {
                [self.syncManagerGeneral cancelSycnTimer];
                self.syncManagerGeneral = nil;
            }
            break;
        case 9://stop to sync Generalcontent
            if (self.syncManagerResourcesCalendar != nil) {
                [self.syncManagerResourcesCalendar cancelSycnTimer];
                self.syncManagerResourcesCalendar = nil;
            }
            break;
        default:
            break;
    }
    
}
- (void)gotoSplash{
    WelcomeViewController *viewcontroller = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:nil];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:viewcontroller];
    [controller.navigationBar setTranslucent:NO];
    self.window.rootViewController = controller;
}

//Methods for setting
-(void)savePilotProfileToLocal{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[AppDelegate sharedDelegate].clientFirstName forKey:@"clientFirstName"];
    [userDefaults setObject:[AppDelegate sharedDelegate].clientMiddleName forKey:@"clientMiddleName"];
    [userDefaults setObject:[AppDelegate sharedDelegate].clientLastName forKey:@"clientLastName"];
    [userDefaults setObject:[AppDelegate sharedDelegate].instructorName forKey:@"instructorName"];
    [userDefaults setObject:[AppDelegate sharedDelegate].instructorId forKey:@"instructorId"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userId forKey:@"userId"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userName forKey:@"userName"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userEmail forKey:@"userEmail"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userLevel forKey:@"userLevel"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userPhoneNum forKey:@"userPhoneNum"];
    [userDefaults setObject:[AppDelegate sharedDelegate].userPassword forKey:@"userPassword"];
    [userDefaults setObject:[AppDelegate sharedDelegate].pilotCert forKey:@"pilotCert"];
    [userDefaults setObject:[AppDelegate sharedDelegate].pilotCertIssueDate forKey:@"pilotCertIssueDate"];
    [userDefaults setObject:[AppDelegate sharedDelegate].medicalCertIssueDate forKey:@"medicalCertIssueDate"];
    [userDefaults setObject:[AppDelegate sharedDelegate].medicalCertExpDate forKey:@"medicalCertExpDate"];
    [userDefaults setObject:[AppDelegate sharedDelegate].cfiCertExpDate forKey:@"cfiCertExpDate"];
    [userDefaults setObject:[AppDelegate sharedDelegate].question forKey:@"question"];
    [userDefaults setObject:[AppDelegate sharedDelegate].answer forKey:@"answer"];
    
    [userDefaults setObject:[AppDelegate sharedDelegate].groupIdsStr forKey:@"groupIdsStr"];
    [userDefaults setObject:@([AppDelegate sharedDelegate].isVerify) forKey:@"isVerify"];
    [userDefaults setObject:[AppDelegate sharedDelegate].unreadData forKey:@"unreadDate"];
    [userDefaults setObject:@([AppDelegate sharedDelegate].unreadGeneralCount) forKey:@"unreadGeneralCount"];
    
    [userDefaults synchronize];
}
-(BOOL)loadPilotProfileFromLocal{
    [self getChattingMessageUnreadCount];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"userId"]) {
        [AppDelegate sharedDelegate].clientFirstName = [userDefaults objectForKey:@"clientFirstName"];
        [AppDelegate sharedDelegate].clientMiddleName = [userDefaults objectForKey:@"clientMiddleName"];
        [AppDelegate sharedDelegate].clientLastName = [userDefaults objectForKey:@"clientLastName"];
        [AppDelegate sharedDelegate].instructorName = [userDefaults objectForKey:@"instructorName"];
        [AppDelegate sharedDelegate].userId = [userDefaults objectForKey:@"userId"];
        [AppDelegate sharedDelegate].userName = [userDefaults objectForKey:@"userName"];
        [AppDelegate sharedDelegate].userEmail = [userDefaults objectForKey:@"userEmail"];
        [AppDelegate sharedDelegate].userLevel = [userDefaults objectForKey:@"userLevel"];
        [AppDelegate sharedDelegate].userPhoneNum = [userDefaults objectForKey:@"userPhoneNum"];
        [AppDelegate sharedDelegate].instructorId = [userDefaults objectForKey:@"instructorId"];
        [AppDelegate sharedDelegate].userPassword = [userDefaults objectForKey:@"userPassword"];
        [AppDelegate sharedDelegate].pilotCert = [userDefaults objectForKey:@"pilotCert"];
        [AppDelegate sharedDelegate].pilotCertIssueDate = [userDefaults objectForKey:@"pilotCertIssueDate"];
        [AppDelegate sharedDelegate].medicalCertIssueDate = [userDefaults objectForKey:@"medicalCertIssueDate"];
        [AppDelegate sharedDelegate].medicalCertExpDate = [userDefaults objectForKey:@"medicalCertExpDate"];
        [AppDelegate sharedDelegate].cfiCertExpDate = [userDefaults objectForKey:@"cfiCertExpDate"];
        [AppDelegate sharedDelegate].question = [userDefaults objectForKey:@"question"];
        [AppDelegate sharedDelegate].answer = [userDefaults objectForKey:@"answer"];
        [AppDelegate sharedDelegate].groupIdsStr = [userDefaults objectForKey:@"groupIdsStr"];
        [AppDelegate sharedDelegate].isVerify = [[userDefaults objectForKey:@"isVerify"] integerValue];
        if ([userDefaults objectForKey:@"unreadDate"]) {
            [AppDelegate sharedDelegate].unreadData = [[userDefaults objectForKey:@"unreadDate"] mutableCopy];
        }
        
        [AppDelegate sharedDelegate].unreadGeneralCount = [[userDefaults objectForKey:@"unreadGeneralCount"] integerValue];
        return YES;
    }
    return NO;
}
-(void)deletePilotProfileFromLocal{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"clientFirstName"];
    [userDefaults removeObjectForKey:@"clientMiddleName"];
    [userDefaults removeObjectForKey:@"clientLastName"];
    [userDefaults removeObjectForKey:@"instructorName"];
    [userDefaults removeObjectForKey:@"instructorId"];
    [userDefaults removeObjectForKey:@"userName"];
    [userDefaults removeObjectForKey:@"userEmail"];
    [userDefaults removeObjectForKey:@"userLevel"];
    [userDefaults removeObjectForKey:@"userPhoneNum"];
    [userDefaults removeObjectForKey:@"userPassword"];
    [userDefaults removeObjectForKey:@"pilotCert"];
    [userDefaults removeObjectForKey:@"pilotCertIssueDate"];
    [userDefaults removeObjectForKey:@"medicalCertIssueDate"];
    [userDefaults removeObjectForKey:@"medicalCertExpDate"];
    [userDefaults removeObjectForKey:@"cfiCertExpDate"];
    [userDefaults removeObjectForKey:@"question"];
    [userDefaults removeObjectForKey:@"answer"];
    [userDefaults removeObjectForKey:@"instructorInfo"];
    [userDefaults removeObjectForKey:@"groupIdsStr"];
    [userDefaults removeObjectForKey:@"isVerify"];
    [userDefaults removeObjectForKey:@"unreadDate"];
    [userDefaults removeObjectForKey:@"unreadGeneralCount"];
    [userDefaults removeObjectForKey:@"checklistHistories"];
    [userDefaults removeObjectForKey:@"selectedCategory"];
    [userDefaults removeObjectForKey:@"isSavedChecklist"];
    [userDefaults synchronize];
}
//end

//Aircraft Local Notifications

- (void) cleanAllLocalNotifications{
    
    [UIApplication.sharedApplication cancelAllLocalNotifications];
}

- (void) registerLocalNotifications{
    
    NSMutableArray *aircraftItems;
    NSMutableArray *maintainesItems;
    NSMutableArray *avionicsItems;
    NSMutableArray *lifeLimitedPartItems;
    NSMutableArray *otherItems;
    NSData *data;
    NSArray *json;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // register all aircraft notifications
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *aircraftArray = [context executeFetchRequest:request error:&error];
    for (Aircraft *aircraftItem in aircraftArray){
        data = [aircraftItem.aircraftItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        aircraftItems = [json mutableCopy];
        NSString *aircraftRegistration = @"";
        for (NSDictionary *fieldInfo in aircraftItems) {
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
                aircraftRegistration = [fieldInfo objectForKey:@"content"];
            }
        }
        [self makeNotification:aircraftItems withAircraftNum:aircraftRegistration];
        
        data = [aircraftItem.maintenanceItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        maintainesItems = [json mutableCopy];
        [self makeNotification:maintainesItems withAircraftNum:aircraftRegistration];
        
        data = [aircraftItem.avionicsItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        avionicsItems = [json mutableCopy];
        [self makeNotification:avionicsItems withAircraftNum:aircraftRegistration];
        
        data = [aircraftItem.liftLimitedParts dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        lifeLimitedPartItems = [json mutableCopy];
        [self makeNotification:lifeLimitedPartItems withAircraftNum:aircraftRegistration];
        
        data = [aircraftItem.otherItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        otherItems = [json mutableCopy];
        [self makeNotification:otherItems withAircraftNum:aircraftRegistration];
        
        
    }
}

- (void)makeNotification:(NSMutableArray *)mutableArray withAircraftNum:(NSString *)aircraftNum{
    for (NSDictionary *dict in mutableArray){
        if ([[dict objectForKey:@"setting"] isKindOfClass:[NSDictionary class]]){
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"MM/dd/yyyy"];
            NSDate *objectiveDate;
            
            if ([[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2  && [[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] == 1 && ![[dict objectForKey:@"content"] isEqual:@""]){
                objectiveDate = [dateFormat dateFromString:[dict objectForKey:@"content"]];
                [self constructNotificationBody:[NSString stringWithFormat:@"%@ - %@",aircraftNum, [dict objectForKey:@"fieldName"]] ObjectiveDate:objectiveDate PriorDays:(int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue] AfterDays:(int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysAfter"] integerValue]];
            }
            
            if ([[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2 && [[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] == 1){
                objectiveDate = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"]];
                [self constructNotificationBody:[NSString stringWithFormat:@"%@ - %@",aircraftNum, [dict objectForKey:@"fieldName"]] ObjectiveDate:objectiveDate PriorDays:(int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue] AfterDays:(int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumAfter"] integerValue]];
            }
            if ([[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] == 1 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0 && ![[dict objectForKey:@"content"] isEqual:@""]){
                NSDecimalNumber *contentNumber = [NSDecimalNumber decimalNumberWithString:[dict objectForKey:@"content"]];
                NSDecimalNumber *nextDueNumber = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                if (![contentNumber isEqualToNumber:[NSDecimalNumber notANumber]] && ![nextDueNumber isEqualToNumber:[NSDecimalNumber notANumber]]) {
                    NSDecimalNumber *addNumber = [NSDecimalNumber decimalNumberWithString:@"25"];
                    if ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue] == 2) {
                        addNumber = [NSDecimalNumber decimalNumberWithString:@"50"];
                    }else if ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue] == 3) {
                        addNumber = [NSDecimalNumber decimalNumberWithString:@"100"];
                    }else if ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue] == 4) {
                        addNumber = [NSDecimalNumber decimalNumberWithString:@"2000"];
                    }
                    nextDueNumber = [nextDueNumber decimalNumberByAdding:addNumber];
                    
                    NSDecimalNumber *differenceTach = [contentNumber decimalNumberBySubtracting:nextDueNumber];
                    if ([differenceTach floatValue] >= 0) {
                        NSString *notificationBody = [[NSString alloc] init];
                        notificationBody = [NSString stringWithFormat:@"Your %@ - %@ is due today.", aircraftNum, [dict objectForKey:@"fieldName"]];
                        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
                        NSCalendar *calendar = [NSCalendar currentCalendar];
                        NSDateComponents *cpnt = [calendar components:unitFlags fromDate:[NSDate date]];
                        cpnt.hour = 0;
                        cpnt.minute = 0;
                        cpnt.second = 1;
                        NSDate *fireTime = [calendar dateFromComponents:cpnt];
                        
                        localNotification.fireDate = fireTime;
                        localNotification.alertBody = notificationBody;
                        localNotification.repeatInterval = NSCalendarUnitDay;
                        localNotification.timeZone = [NSTimeZone localTimeZone];
                        
                        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    }
                }
            }
        }
    }
}

- (void)constructNotificationBody:(NSString *) headerStr ObjectiveDate:(NSDate *) objectiveDate PriorDays:(int) priordays AfterDays:(int) afterdays{
    
    NSString *notificationBody = [[NSString alloc] init];
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:objectiveDate
                                                          toDate:[NSDate date]
                                                         options:0];
    //NSLog(@"%ld", (long)[components day]);
    
    if ((long)[components day] < 0 && labs((long)[components day]) < priordays){
        notificationBody = [NSString stringWithFormat:@"Your %@ will expire in %ld day(s).", headerStr, labs((long)[components day])];
    }
    if ((long)[components day] > 0 && (long)[components day] < afterdays){
        notificationBody = [NSString stringWithFormat:@"Your %@ has expired.", headerStr];
    }
    if ((long)[components day] == 0){
        notificationBody = [NSString stringWithFormat:@"Your %@ is due today.", headerStr];
    }
    
    
    if (![notificationBody isEqualToString:@""]){
        NSCalendar *calendar = [NSCalendar currentCalendar];
//        NSDateComponents *cpnt = [calendar components:unitFlags fromDate:[objectiveDate dateByAddingTimeInterval:-priordays*24*60*60]];
        NSDateComponents *cpnt = [calendar components:unitFlags fromDate:[NSDate date]];
        cpnt.hour = 0;
        cpnt.minute = 0;
        cpnt.second = 1;
        NSDate *fireTime = [calendar dateFromComponents:cpnt];
        
        localNotification.fireDate = fireTime;//[NSDate dateWithTimeIntervalSinceNow:20];//fireTime;
        localNotification.alertBody = notificationBody;
        localNotification.repeatInterval = NSCalendarUnitDay;
        localNotification.timeZone = [NSTimeZone localTimeZone];
        
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
    }
    
}
- (void)getDeviceTokenOfSupport{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"get_device_token_support", @"action", nil];
    NSData *usersJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *usersRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [usersRequest setHTTPMethod:@"POST"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [usersRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)usersJSON.length] forHTTPHeaderField:@"Content-Length"];
    [usersRequest setHTTPBody:usersJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *usersTask = [session dataTaskWithRequest:usersRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    deviceTokenOfSupport = [queryResults objectForKey:@"device_token"];
                });
                
            }else{
                
            }
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [usersTask resume];
}

//get badage count for expired aircraft
- (NSInteger)getBadgeCountForExpiredAircraft:(Aircraft *)aircraftTCheck{
    NSInteger badageCount = 0;
    NSMutableArray *aircraftItems;
    NSMutableArray *maintainesItems;
    NSMutableArray *avionicsItems;
    NSMutableArray *lifeLimitedPartItems;
    NSMutableArray *otherItems;
    NSData *data;
    NSArray *json;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // register all aircraft notifications
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    if (aircraftTCheck != nil) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aircraftID == %@", aircraftTCheck.aircraftID];
        [request setPredicate:predicate];
    }
    NSArray *aircraftArray = [context executeFetchRequest:request error:&error];
    for (Aircraft *aircraftItem in aircraftArray){
        data = [aircraftItem.aircraftItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        aircraftItems = [json mutableCopy];
        badageCount += [self getExiredItemWithArray:aircraftItems];
        
        data = [aircraftItem.maintenanceItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        maintainesItems = [json mutableCopy];
        badageCount += [self getExiredItemWithArray:maintainesItems];
        
        data = [aircraftItem.avionicsItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        avionicsItems = [json mutableCopy];
        badageCount += [self getExiredItemWithArray:avionicsItems];
        
        data = [aircraftItem.liftLimitedParts dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        lifeLimitedPartItems = [json mutableCopy];
        badageCount += [self getExiredItemWithArray:lifeLimitedPartItems];
        
        data = [aircraftItem.otherItems dataUsingEncoding:NSUTF8StringEncoding];
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        otherItems = [json mutableCopy];
        badageCount += [self getExiredItemWithArray:otherItems];
    }
    return badageCount;
}
- (NSInteger)getExiredItemWithArray:(NSMutableArray *)itemArray{
    NSInteger count = 0;
    for (NSMutableDictionary *dict in itemArray) {
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    if((long)[components day] + 1 < 0){
                        count ++;
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    if((long)[components day] + 1 < 0){
                        count ++;
                    }
                }
            }
        }
        
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] &&[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] == 1 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0 && ![[dict objectForKey:@"content"] isEqual:@""] && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            
            NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
            switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                case 1:{
                    NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                    NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                    if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                        currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                    }
                    break;
                }
                case 2:{
                    NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                    NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                    if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                        currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                    }
                    break;
                }
                case 3:{
                    NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                    NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                    if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                        currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                    }
                    break;
                }
                case 4:{
                    NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                    NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                    if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                        currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                    }
                    break;
                }
                default:
                    break;
            }
            NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
            for (NSDictionary *dictToGetTach in itemArray) {
                if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                    parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                    break;
                }
            }
            if (![currentTach isEqualToNumber:[NSDecimalNumber notANumber]] && ![parentTach isEqualToNumber:[NSDecimalNumber notANumber]]) {
                
                NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                if ([differenceTach floatValue] <= 0) {
                    count ++;
                }
            }
        }
    }
    return count;
}
- (void)removeAllCalendarForResources{
    NSError *error;
    EKEventStore *eventStore = [[EKEventStore alloc]init];
    for (EKCalendar *currentCalendar in [eventStore calendarsForEntityType:EKEntityTypeEvent]) {
        NSString *prefixOfCalendar = @"";
        if (currentCalendar.title.length > 3) {
            prefixOfCalendar = [currentCalendar.title substringToIndex:3];
        }
        if ([prefixOfCalendar isEqualToString:@"FD-"]) {
            BOOL success= [eventStore removeCalendar:currentCalendar commit:YES error:&error];
            if (error != nil)
            {
                NSLog(@"%@", error.description);
                // TODO: error handling here
            }
            if (success) {
                NSLog(@"Removed %@ from iOS-Calendar", currentCalendar.title);
            }
        }
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSArray *fetchedResourcesCalendars = [context executeFetchRequest:request error:&error];
    for (ResourcesCalendar *resourcesCalendarToUpdate in fetchedResourcesCalendars) {
        resourcesCalendarToUpdate.event_identify = @"";
    }
    [context save:&error];
}
- (void)updateLocalNotificationWithReservation:(NSString *)notificationKey withTimeInterVal:(NSTimeInterval)alertTimeInterval  withAlertTitle:(NSString *)alertTitle withStartDate:(NSDate *)reservationStartDate withEventIdentify:(NSString *)eventIdentify{
    NSDate *today = [NSDate date]; // it will give you current date
    NSComparisonResult result;
    //has three possible values: NSOrderedSame,NSOrderedDescending, NSOrderedAscending
    
    result = [today compare:reservationStartDate]; // comparing two dates
    
    if(result==NSOrderedDescending){
        return;
    }
    
    
    
    
    NSArray *scheduledNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *notification in scheduledNotifications)
    {
        //Get the ID you set when creating the notification
        NSDictionary *userInfo = notification.userInfo;
        NSString *notificationKeyToBeSaved = [userInfo objectForKey:@"notificationKey"];
        
        if ([notificationKeyToBeSaved isEqualToString:notificationKey])
        {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [reservationStartDate dateByAddingTimeInterval:alertTimeInterval * (-1)];//fireTime;
    localNotification.alertLaunchImage = @"LaunchImage";
    localNotification.alertTitle = alertTitle;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    localNotification.alertBody = [dateFormatter stringFromDate:reservationStartDate];
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.repeatInterval = NSCalendarUnitDay;
    localNotification.timeZone = [NSTimeZone localTimeZone];
    
    NSString *eventIdentifyTmp = @"";
    if (eventIdentify != nil) {
        eventIdentifyTmp = eventIdentify;
    }
    NSDictionary *info  =  [NSDictionary dictionaryWithObjectsAndKeys:notificationKey, @"notificationKey", eventIdentifyTmp, @"eventIdentify",@"reservationNotification", @"pushType", nil];
    localNotification.userInfo = info;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}
- (BOOL)isShownHideCurrentEventFromLocal:(EKEvent *)eventToCheck{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event_identify == %@", eventToCheck.eventIdentifier];
    [request setPredicate:predicate];
    NSArray *fetchedResourcesCalendars = [context executeFetchRequest:request error:&error];
    ResourcesCalendar *resourcesCalendar = nil;
    if (fetchedResourcesCalendars == nil) {
        NSString *prefixOfCalendar = @"";
        if(eventToCheck.calendar.title.length > 3){
            prefixOfCalendar = [eventToCheck.calendar.title substringToIndex:3];
            if ([prefixOfCalendar isEqualToString:@"FD-"]) {
                return NO;
            }
        }
    } else if (fetchedResourcesCalendars.count == 0) {
        NSString *prefixOfCalendar = @"";
        if(eventToCheck.calendar.title.length > 3){
            prefixOfCalendar = [eventToCheck.calendar.title substringToIndex:3];
            if ([prefixOfCalendar isEqualToString:@"FD-"]) {
                return NO;
            }
        }
    } else{
        resourcesCalendar = [fetchedResourcesCalendars objectAtIndex:0];
        if ([resourcesCalendar.isEditable boolValue] == NO && [resourcesCalendar.user_id integerValue] != [[AppDelegate sharedDelegate].userId integerValue]) {
            if (![self isExistOnGroupCurrentUserID:resourcesCalendar.user_id withContext:context]) {
                return NO;
            }else{
                if (![self isCheckedInvitedUser:resourcesCalendar.group_id withContext:context]) {
                    return NO;
                }
            }
        }
    }
    return YES;
}
- (BOOL)isCheckedInvitedUser:(NSNumber *)reservationGroup_id withContext:(NSManagedObjectContext *)contextT{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:contextT];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"group_id == %@", reservationGroup_id];
    [request setPredicate:predicate];
    NSArray *fetchedResourcesCalendarsWithGroup = [contextT executeFetchRequest:request error:&error];
    if (fetchedResourcesCalendarsWithGroup.count >0){
        for (ResourcesCalendar *resourcesCalendarToCheck in fetchedResourcesCalendarsWithGroup) {
            if ([resourcesCalendarToCheck.invitedUser_id integerValue] > 0) {
                if ([resourcesCalendarToCheck.invitedUser_id integerValue] == [[AppDelegate sharedDelegate].userId integerValue]) {
                    return YES;
                    break;
                }
            }
        }
    }
    return NO;
}
- (BOOL)isExistOnGroupCurrentUserID:(NSNumber *)userIDToCheck withContext:(NSManagedObjectContext *)contextT{
    NSError *error;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:contextT];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", userIDToCheck];
    [request setPredicate:predicate];
    NSArray *objects = [contextT executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Users!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Users found!");
    } else {
        return YES;
    }
    return NO;
}
@end
