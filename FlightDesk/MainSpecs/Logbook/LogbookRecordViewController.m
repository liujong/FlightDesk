//
//  LogbookRecordViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 4/6/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "Logging.h"
#import "LogbookRecordViewController.h"
#import "LogbookRecordView.h"
#import "EndorsementViewController.h"
#import "LogEntry+CoreDataClass.h"
#import "LessonRecord.h"
#import "DateViewController.h"
#import "SignatureViewController.h"
#import "PickerWithDataViewController.h"
@interface LogbookRecordViewController () <EndorsementViewDelegate, DateViewControllerDelegate, SignatureViewControllerDelegate, PickerWithDataViewControllerDelegate>

@end

@implementation LogbookRecordViewController
{
    LogbookRecordView *recordView;
    LogEntry *currentLogEntry;
    NSInteger typeOfEndorsementDate;
}
@synthesize isTotal;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithLogEntry:(LogEntry*)logEntry
{
    self = [super init];
    if (self) {
        currentLogEntry = logEntry;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = [NSString stringWithFormat:@"%@", @"Logbook Entry"];
    
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse lessons update without being logged in!");
    }
    // determine if this entry is editable by the current user
    BOOL editable = YES;
    if (currentLogEntry.logLessonRecord != nil && [userID intValue] == [currentLogEntry.logLessonRecord.userID intValue]) {
        editable = NO;
    }
    
    CGRect frameOfLogBook = self.view.bounds;
    frameOfLogBook.size.height = frameOfLogBook.size.height - 64.0f;
    
    NSString *insCertNum;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        insCertNum = [AppDelegate sharedDelegate].pilotCert;
    }
    
    if (currentLogEntry.logLessonRecord.lesson) {
        NSNumber *instructorID = nil;
        if (currentLogEntry.logLessonRecord.lesson.lessonGroup.parentGroup == nil) {
            instructorID = currentLogEntry.logLessonRecord.lesson.lessonGroup.instructorID;
            insCertNum = currentLogEntry.logLessonRecord.lesson.lessonGroup.instructorPilotCert;
        }else{
            instructorID = currentLogEntry.logLessonRecord.lesson.lessonGroup.parentGroup.instructorID;
            insCertNum = currentLogEntry.logLessonRecord.lesson.lessonGroup.parentGroup.instructorPilotCert;
        }
        recordView = [[LogbookRecordView alloc] initWithFrame:frameOfLogBook andLogEntry:currentLogEntry andRecordLesson:currentLogEntry.logLessonRecord andLesson:currentLogEntry.logLessonRecord.lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:NO withTotalEngry:isTotal];
    }else{
        if (currentLogEntry.lessonId != nil) {
            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:context];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSError *error;
            [request setEntity:entityDesc];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonID == %@", currentLogEntry.lessonId];
            [request setPredicate:predicate];
            NSArray *objectsLesson = [context executeFetchRequest:request error:&error];
            
            Lesson *lesson = nil;
            if (objectsLesson == nil) {
            } else if (objectsLesson.count == 0) {
            } else {
                lesson = objectsLesson[0];
            }
            
            NSNumber *instructorID = nil;
            if (lesson != nil) {
                if (lesson.lessonGroup.parentGroup == nil) {
                    instructorID = lesson.lessonGroup.instructorID;
                    insCertNum = lesson.lessonGroup.instructorPilotCert;
                }else{
                    instructorID = lesson.lessonGroup.parentGroup.instructorID;
                    insCertNum = lesson.lessonGroup.parentGroup.instructorPilotCert;
                }
            }
            
            recordView = [[LogbookRecordView alloc] initWithFrame:frameOfLogBook andLogEntry:currentLogEntry andRecordLesson:lesson.record andLesson:lesson andInstructorID:instructorID andUserID:userID CFInumber:insCertNum fromLesson:NO withTotalEngry:isTotal];
            
        }else{
            recordView = [[LogbookRecordView alloc] initWithFrame:frameOfLogBook andLogEntry:currentLogEntry andRecordLesson:nil andLesson:nil andInstructorID:nil andUserID:nil CFInumber:nil fromLesson:NO withTotalEngry:isTotal];
        }
    }
    recordView.endorsementViewDelegate = self;
    [self.view addSubview:recordView];
    
    if (self.isOpenFromLogBook) {
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"LogbookRecordViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // save current lesson records
    [recordView save];
    if (self.isOpenFromLogBook) {
    }
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogBookHeight) name:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil];
}
- (void)updateLogBookHeight{
    if (self.isOpenFromLogBook) {
    }
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
}
- (void)setNavigationColorWithGradiant{
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor lightGrayColor].CGColor,
                              (__bridge id)[UIColor darkGrayColor].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Endorsement view delegate

- (void)showEndorsement
{
    FDLogDebug(@"add endorsement to log entry!");
    EndorsementViewController *endorsementViewController = [[EndorsementViewController alloc] init];
    [self.navigationController pushViewController:endorsementViewController animated:YES];
}

- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}
- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}
#pragma mark DateViewControllerDelegate
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    [recordView setDateFromDatePicker:_strDate type:_type withIndex:index];
    [self removeCurrentViewFromSuper:dateView];
    [recordView ableToShowOtherView];
}
- (void)didCancelDateView:(DateViewController *)dateView{
    [self removeCurrentViewFromSuper:dateView];
    [recordView ableToShowOtherView];
}

#pragma mark SignatureViewControllerDelegate
- (void)returnValueFromSignView:(SignatureViewController *)signView signatureImage:(UIImage *)_signImage withIndex:(NSInteger)index{
    [recordView setSignature:_signImage withIndex:index];
    [self removeCurrentViewFromSuper:signView];
}
- (void)didCancelSignView:(SignatureViewController *)signView{
    [self removeCurrentViewFromSuper:signView];
    [recordView ableToShowOtherView];
}

#pragma mark PickerWithDataViewController
- (void)didCancelPickerView:(PickerWithDataViewController *)pickerView{
    [self removeCurrentViewFromSuper:pickerView];
    [recordView ableToShowOtherView];
}
- (void)returnValueFromPickerView:(PickerWithDataViewController *)pickerView withSelectedString:(NSString *)toString withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index{
    [self removeCurrentViewFromSuper:pickerView];
    [recordView setCurrentItemFromPicker:toString withType:_type withText:_text withIndex:index];
}
#pragma mrak EndorsementViewDelegate
- (void)showEndorsementDateView:(NSInteger)type withIndex:(NSInteger)index{
    typeOfEndorsementDate = type;
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = type;
    if (type == 1) {
        dateView.pickerTitle = @"Date";
    }else if (type == 2){
        dateView.pickerTitle = @"Expiration";
    }else if (type == 3){
        dateView.pickerTitle = @"DATE";
    }
    dateView.indexForEndorsementCell = index;
    [self displayContentController:dateView];
    [dateView animateShow];
}
- (void)showEndorsementSignatureView:(NSInteger)index{
    SignatureViewController *signView = [[SignatureViewController alloc] initWithNibName:@"SignatureViewController" bundle:nil];
    [signView.view setFrame:self.view.bounds];
    signView.delegate = self;
    signView.currentCellIndex = index;
    [self displayContentController:signView];
    [signView animateShow];
}
- (void)showPickerViewToSelectItem:(NSInteger)type withIndex:(NSInteger)index{
    PickerWithDataViewController *pickView = [[PickerWithDataViewController alloc] initWithNibName:@"PickerWithDataViewController" bundle:nil];
    [pickView.view setFrame:self.view.bounds];
    pickView.delegate = self;
    pickView.pickerType = type;
    pickView.cellIndexForEndorsement = index;
    [self displayContentController:pickView];
    [pickView animateShow];
}

@end
