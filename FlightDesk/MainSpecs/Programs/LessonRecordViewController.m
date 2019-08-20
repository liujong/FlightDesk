//
//  LessonRecordViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 4/6/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "LessonRecordViewController.h"
#import "LessonRecordView.h"
#import "Lesson+CoreDataClass.h"
#import "LogbookRecordView.h"
#import "DateViewController.h"
#import "SignatureViewController.h"
#import "PickerWithDataViewController.h"

@interface LessonRecordViewController ()<EndorsementViewDelegate, DateViewControllerDelegate, SignatureViewControllerDelegate, PickerWithDataViewControllerDelegate>

@end

@implementation LessonRecordViewController
{
    LessonRecordView *recordView;
    Lesson *currentLesson;
    
    NSInteger typeOfEndorsementDate;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
@synthesize lessonNavTitle;

- (id)initWithLesson:(Lesson*)lesson
{
    self = [super init];
    if (self) {
        currentLesson = lesson;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.navigationItem.title = [NSString stringWithFormat:@"%@", currentLesson.title];
    self.navigationItem.title = lessonNavTitle;
    recordView = [[LessonRecordView alloc] initWithLesson:currentLesson];
    recordView.logBookView.endorsementViewDelegate = self;
    [self.view addSubview:recordView];
    // enable auto-layout
    recordView.translatesAutoresizingMaskIntoConstraints = NO;
    [recordView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [recordView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [recordView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [recordView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [recordView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"LessonRecordViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // save current lesson records
        [recordView save];
    }
    [super viewWillDisappear:animated];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogBookHeight) name:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_UPDATE_LOGBOOK_HEIGHT object:nil];
}
- (void)updateLogBookHeight{
    [recordView updateLogBookHeight:[AppDelegate sharedDelegate].heightCurrentLogBookToUpdate];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [recordView.logBookView setDateFromDatePicker:_strDate type:_type withIndex:index];
    [self removeCurrentViewFromSuper:dateView];
}
- (void)didCancelDateView:(DateViewController *)dateView{
    [self removeCurrentViewFromSuper:dateView];
    [recordView.logBookView ableToShowOtherView];
}

#pragma mark SignatureViewControllerDelegate
- (void)returnValueFromSignView:(SignatureViewController *)signView signatureImage:(UIImage *)_signImage withIndex:(NSInteger)index{
    [recordView.logBookView setSignature:_signImage withIndex:index];
    [self removeCurrentViewFromSuper:signView];
}
- (void)didCancelSignView:(SignatureViewController *)signView{
    [self removeCurrentViewFromSuper:signView];
    [recordView.logBookView ableToShowOtherView];
}

#pragma mark PickerWithDataViewController
- (void)didCancelPickerView:(PickerWithDataViewController *)pickerView{
    [self removeCurrentViewFromSuper:pickerView];
    [recordView.logBookView ableToShowOtherView];
}
- (void)returnValueFromPickerView:(PickerWithDataViewController *)pickerView withSelectedString:(NSString *)toString withType:(NSInteger)_type  withText:(NSString *)_text withIndex:(NSInteger)index{
    [self removeCurrentViewFromSuper:pickerView];

    [recordView.logBookView setCurrentItemFromPicker:toString withType:_type withText:_text withIndex:index];
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
