//
//  AppDelegate.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RecordsViewController.h"
#import "DocumentsViewController.h"
#import "QuizesViewController.h"
#import "LogbookViewController.h"
#import <UserNotifications/UserNotifications.h>
#import "TOSplitViewController.h"
#import "CommsMainViewController.h"
#import "UIBubbleTableViewDataSource.h"
#import "AircraftViewController.h"
#import "LiveChatViewController.h"
#import "NavLogViewController.h"
#import "MoreViewController.h"
#import "MainCheckListsViewController.h"
#import "RecordsFileViewController.h"
#import "SettingViewController.h"
#import "GeneralViewController.h"
#import "ScheduleMainViewController.h"

#import "syncManagerLessonLog.h"
#import "SyncManagerDocument.h"
#import "SyncManagerQuiz.h"
#import "SyncManagerAircraft.h"
#import "SyncManagerMoreTools.h"
#import "syncManagerNoUpload.h"
#import "SyncManageSupport.h"
#import "SyncManagerRecordsFiles.h"
#import "SyncManagerGeneral.h"
#import "SyncManagerResourcesCalendar.h"

#import "Aircraft+CoreDataClass.h"

#import "DashboardView.h"

#import "TrainingViewController.h"
#import "StudentTrainingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MBProgressHUD/MBProgressHUD.h>



@import Firebase;
@class PersistentCoreDataStack;
@class WelcomeViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UNUserNotificationCenterDelegate, TOSplitViewControllerDelegate, FIRMessagingDelegate>

+(AppDelegate*)sharedDelegate;
@property (strong, nonatomic) WelcomeViewController *viewController;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RecordsViewController *records_vc;
@property (strong, nonatomic) DocumentsViewController *documents_vc;
@property (strong, nonatomic) QuizesViewController * quizses_VC;
@property (strong, nonatomic) LogbookViewController * logbook_vc;
@property (strong, nonatomic) CommsMainViewController *commsMain_vc;
@property (strong, nonatomic) LiveChatViewController *liveChat_vc;
@property (strong, nonatomic) UINavigationController *comms_nc;
@property (strong, nonatomic) NavLogViewController *navLog_VC;
@property (strong, nonatomic) MoreViewController *more_VC;
@property (strong, nonatomic) MainCheckListsViewController *checklist_VC;
@property (strong, nonatomic) RecordsFileViewController *recordsfile_VC;
@property (strong, nonatomic) SettingViewController *setting_VC;
@property (strong, nonatomic) GeneralViewController *general_VC;
@property (strong, nonatomic) ScheduleMainViewController *scheduleMain_VC;

@property (strong, nonatomic) DashboardView *reloadDashBoard_V;

@property (strong, nonatomic) TrainingViewController *train_VC;

@property (strong, nonatomic) StudentTrainingViewController *studentTrain_VC;

@property (strong, nonatomic) UITabBarController *rootViewControllerForTab;
@property (strong, nonatomic) UINavigationController *navigationControllerForTab;

@property (strong, nonatomic) AircraftViewController *aircraft_vc;


@property (strong, nonatomic) TOSplitViewController *splitViewControllerOfChatting;

//comms
@property (strong, nonatomic) NSMutableArray *bubbleData;
@property (strong, nonatomic) NSMutableArray *unreadData;
@property  NSInteger unreadGeneralCount;
@property (strong, nonatomic) NSMutableArray *isActivedUsersData;
@property (strong, nonatomic) NSMutableDictionary *bannerDetails;


@property (strong, nonatomic) FIRDatabaseReference *rootR;
@property (strong, nonatomic) UIBubbleTableView *tmpBubbleTableView;

@property (nonatomic, strong) PersistentCoreDataStack *persistentCoreDataStack;

@property (nonatomic, strong) SyncManagerNoUpload *syncNamagerNoUpload;
@property (nonatomic, strong) SyncManagerLessonLog *syncManagerLessonLog;
@property (nonatomic, strong) SyncManagerDocument *syncManagerDocument;
@property (nonatomic, strong) SyncManagerQuiz *syncManagerQuiz;
@property (nonatomic, strong) SyncManagerAircraft *syncManagerAirCraft;
@property (nonatomic, strong) SyncManagerMoreTools *syncManagerMoreTools;
@property (nonatomic, strong) SyncManageSupport *syncManagerSupport;
@property (nonatomic, strong) SyncManagerRecordsFiles *syncManagerRecordsFiles;
@property (nonatomic, strong) SyncManagerGeneral *syncManagerGeneral;
@property (nonatomic, strong) SyncManagerResourcesCalendar *syncManagerResourcesCalendar;


@property (nonatomic, strong) NSString *deviceTokenOfSupport;

@property NSInteger currentSyncingIndex;

@property NSInteger currentTabItemIndex;

@property BOOL isStartPerformSyncCheck;


- (NSURL *)applicationDocumentsDirectory;

- (void)clearLessons;
- (void)clearDocuments;

- (void)getDeviceTokenOfSupport;

- (void)gotoMainView;
- (void)gotoSplash;

//Setting
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPassword;
@property (nonatomic, strong) NSString *userLevel;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userPhoneNum;
@property (nonatomic, strong) NSString *clientFirstName;
@property (nonatomic, strong) NSString *clientMiddleName;
@property (nonatomic, strong) NSString *clientLastName;
@property (nonatomic, strong) NSString *instructorName;
@property (nonatomic, strong) NSString *instructorId;
@property (nonatomic, strong) NSString *pilotCert;
@property (nonatomic, strong) NSString *pilotCertIssueDate;
@property (nonatomic, strong) NSString *medicalCertIssueDate;
@property (nonatomic, strong) NSString *medicalCertExpDate;
@property (nonatomic, strong) NSString *cfiCertExpDate;
@property (nonatomic, strong) NSString *question;
@property (nonatomic, strong) NSString *answer;
@property (nonatomic, strong) NSString *groupIdsStr;
@property (nonatomic, strong) NSString *verificationCode;
@property (nonatomic, strong) NSString *device_token;
@property NSInteger isVerify;

@property (nonatomic, strong) NSURL *filePathToImportMyDocs;



//Loading.....
@property (nonatomic, strong) MBProgressHUD *trainingHud;
@property (nonatomic, strong) NSString *programName;


//helight of current logbook
@property CGFloat heightCurrentLogBookToUpdate;

@property (nonatomic, strong) UINavigationBar* navAppearance;

@property NSInteger currentBoardID;


@property NSInteger countRedBadge;
@property NSInteger countRedBadgeForUnreadMessage;
@property BOOL isShownChatBoard;

@property BOOL isLogin;
@property BOOL isBackPreUser;
@property BOOL isRegister;
@property BOOL isOpenFirstWithDash;
@property BOOL isSelectedIosCalendar;
@property BOOL isSelectedDayViewForBooking;
@property BOOL isSelectedWeekViewForBooking;


@property BOOL isUpdatedMiniMonthBySelection;


@property BOOL isShownScheduleView;
@property BOOL isLoadedScheduleViewAtOnce;

@property BOOL isSelectedLandscape;

@property CGFloat deviationOfResources; // calculate resources view from that value when alldayevetns's height is changed 
@property CGFloat preallDayEventsViewHeight;
//save the index what user works on current Navlog
@property NSInteger selectedNavLogIndex;

-(void)savePilotProfileToLocal;
-(BOOL)loadPilotProfileFromLocal;
-(void)deletePilotProfileFromLocal;
//end

- (NSInteger)getDocumentDownloadCount;
- (NSInteger)getChattingMessageUnreadCount;
- (void)sendPushForLogInOut:(int)online;
- (void)setDocumentNavigationBadge;
- (void)updateDeviceToken;

//Aircraft Notifications

- (void)cleanAllLocalNotifications;
- (void)registerLocalNotifications;
- (void)constructNotificationBody:(NSString *) headerStr ObjectiveDate:(NSDate *) objectiveDate PriorDays:(int) priordays AfterDays:(int) afterdays;
- (void)makeNotification: (NSMutableArray *) mutableArray;


//for quiz to be testing now.
@property (nonatomic, retain) NSNumber *currentQuizId;
@property BOOL isTestingScreen;


//array of pdf files's to get from other apps
@property (nonatomic, retain) NSMutableArray *arrayMydoc;

///  user for crash log
- (void)logUser;
///////////////
//

- (void)Logout;
- (void)returnToActivity;


- (void)playingAndStopForMessageToSend;
- (void)playingAndStopForMessageToBeArrived;

//sync
- (void)startThreadToSyncData:(NSInteger)index;
- (void)stopThreadToSyncData:(NSInteger)index;

//set background color of navigation
- (void)setNavigationBarBackGround:(NSInteger)type;

//get badage count for expired aircraft
- (NSInteger)getBadgeCountForExpiredAircraft:(Aircraft *)aircraftTCheck;
- (void)updateLocalNotificationWithReservation:(NSString *)notificationKey withTimeInterVal:(NSTimeInterval)alertTimeInterval  withAlertTitle:(NSString *)alertTitle withStartDate:(NSDate *)reservationStartDate withEventIdentify:(NSString *)eventIdentify;
- (BOOL)isShownHideCurrentEventFromLocal:(EKEvent *)eventToCheck;
@end
