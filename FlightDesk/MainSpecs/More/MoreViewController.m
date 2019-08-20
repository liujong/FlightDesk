//
//  MoreViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 2/8/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "MoreViewController.h"
#import "Document+CoreDataClass.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "FlightDesk-Swift.h"
#import "NavLogViewController.h"
#import "ConversionsViewController.h"
#import "PaDaViewController.h"
#import "IsaViewController.h"
#import "SpeedViewController.h"
#import "CloudsViewController.h"
#import "TimeDistanceViewController.h"
#import "FuelViewController.h"
#import "ToldViewController.h"
#import "WeightAndBalanceViewController.h"
#import "LegViewController.h"
#import "GlideViewController.h"
#import "FreezingLevelViewController.h"
#import "WindViewController.h"
#import "MainCheckListsViewController.h"
#import "FlightTrackingMainViewController.h"

@interface MoreViewController ()
@end

@implementation MoreViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Tools";
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"MoreViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:1.0f green:140.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
    
    btnNavLog.animation = @"slideDown";
    btnNavLog.delay = 0.0f;
    btnNavLog.duration = 1.8f;
    btnNavLog.autostart = YES;
    [btnNavLog animate];
    
    btnTOLD.animation = @"slideDown";
    btnTOLD.delay = 0.0f;
    btnTOLD.duration = 1.6f;
    btnTOLD.autostart = YES;
    [btnTOLD animate];
    
    btnWB.animation = @"slideDown";
    btnWB.delay = 0.0f;
    btnWB.duration = 1.4f;
    btnWB.autostart = YES;
    [btnWB animate];
    
    btnChecklists.animation = @"slideDown";
    btnChecklists.delay = 0.0f;
    btnChecklists.duration = 1.6f;
    btnChecklists.autostart = YES;
    [btnChecklists animate];
    
    btnFlightTracking.animation = @"slideDown";
    btnFlightTracking.delay = 0.0f;
    btnFlightTracking.duration = 1.8f;
    btnFlightTracking.autostart = YES;
    [btnFlightTracking animate];
    
    btnWind.animation = @"slideRight";
    btnWind.delay = 0.0f;
    btnWind.duration = 1.4f;
    btnWind.autostart = YES;
    [btnWind animate];
    
    btnFuel.animation = @"slideRight";
    btnFuel.delay = 0.0f;
    btnFuel.duration = 1.6f;
    btnFuel.autostart = YES;
    [btnFuel animate];
    
    btnPaDa.animation = @"slideUp";
    btnPaDa.delay = 0.0f;
    btnPaDa.duration = 1.4f;
    btnPaDa.autostart = YES;
    [btnPaDa animate];
    
    btnIsa.animation = @"slideLeft";
    btnIsa.delay = 0.0f;
    btnIsa.duration = 1.6f;
    btnIsa.autostart = YES;
    [btnIsa animate];
    
    btnConversion.animation = @"slideLeft";
    btnConversion.delay = 0.0f;
    btnConversion.duration = 1.4f;
    btnConversion.autostart = YES;
    [btnConversion animate];
    
    btnSpeed.animation = @"slideRight";
    btnSpeed.delay = 0.0f;
    btnSpeed.duration = 1.4f;
    btnSpeed.autostart = YES;
    [btnSpeed animate];
    
    btnClouds.animation = @"slideRight";
    btnClouds.delay = 0.0f;
    btnClouds.duration = 1.6f;
    btnClouds.autostart = YES;
    [btnClouds animate];
    
    btnTimeDistance.animation = @"slideUp";
    btnTimeDistance.delay = 0.0f;
    btnTimeDistance.duration = 1.4f;
    btnTimeDistance.autostart = YES;
    [btnTimeDistance animate];
    
    btnLeg.animation = @"slideLeft";
    btnLeg.delay = 0.0f;
    btnLeg.duration = 1.6f;
    btnLeg.autostart = YES;
    [btnLeg animate];
    
    btnGuide.animation = @"slideLeft";
    btnGuide.delay = 0.0f;
    btnGuide.duration = 1.4f;
    btnGuide.autostart = YES;
    [btnGuide animate];
    
    btnFreezingLevel.animation = @"slideRight";
    btnFreezingLevel.delay = 0.0f;
    btnFreezingLevel.duration = 1.4f;
    btnFreezingLevel.autostart = YES;
    [btnFreezingLevel animate];
    
    [[AppDelegate sharedDelegate] startThreadToSyncData:6];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:6];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [self superClassDeviceOrientationDidChange];
//    shake
//    pop
//    morph
//    squeeze
//    wobble
//    swing
//    flipX
//    flipY
//    fall
//    squeezeLeft
//    squeezeRight
//    squeezeDown
//    squeezeUp
//    slideLeft
//    slideRight
//    slideDown
//    slideUp
//    fadeIn
//    fadeOut
//    fadeInLeft
//    fadeInRight
//    fadeInDown
//    fadeInUp
//    zoomIn
//    zoomOut
//    flash
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:1.0f green:140.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
    btnNavLog.animation = @"pop";
    btnNavLog.delay = 0.0f;
    btnNavLog.duration = 1.4f;
    btnNavLog.autostart = YES;
    [btnNavLog animate];
    
    btnTOLD.animation = @"pop";
    btnTOLD.delay = 0.0f;
    btnTOLD.duration = 1.4f;
    btnTOLD.autostart = YES;
    [btnTOLD animate];
    
    btnWB.animation = @"pop";
    btnWB.delay = 0.0f;
    btnWB.duration = 1.4f;
    btnWB.autostart = YES;
    [btnWB animate];
    
    btnChecklists.animation = @"pop";
    btnChecklists.delay = 0.0f;
    btnChecklists.duration = 1.4f;;
    btnChecklists.autostart = YES;
    [btnChecklists animate];
    
    btnFlightTracking.animation = @"pop";
    btnFlightTracking.delay = 0.0f;
    btnFlightTracking.duration = 1.4f;
    btnFlightTracking.autostart = YES;
    [btnFlightTracking animate];
    
    btnWind.animation = @"pop";
    btnWind.delay = 0.0f;
    btnWind.duration = 1.4f;
    btnWind.autostart = YES;
    [btnWind animate];
    
    btnFuel.animation = @"pop";
    btnFuel.delay = 0.0f;
    btnFuel.duration = 1.4f;
    btnFuel.autostart = YES;
    [btnFuel animate];
    
    btnPaDa.animation = @"pop";
    btnPaDa.delay = 0.0f;
    btnPaDa.duration = 1.4f;
    btnPaDa.autostart = YES;
    [btnPaDa animate];
    
    btnIsa.animation = @"pop";
    btnIsa.delay = 0.0f;
    btnIsa.duration = 1.4f;
    btnIsa.autostart = YES;
    [btnIsa animate];
    
    btnConversion.animation = @"pop";
    btnConversion.delay = 0.0f;
    btnConversion.duration = 1.4f;
    btnConversion.autostart = YES;
    [btnConversion animate];
    
    btnSpeed.animation = @"pop";
    btnSpeed.delay = 0.0f;
    btnSpeed.duration = 1.4f;
    btnSpeed.autostart = YES;
    [btnSpeed animate];
    
    btnClouds.animation = @"pop";
    btnClouds.delay = 0.0f;
    btnClouds.duration = 1.4f;
    btnClouds.autostart = YES;
    [btnClouds animate];
    
    btnTimeDistance.animation = @"pop";
    btnTimeDistance.delay = 0.0f;
    btnTimeDistance.duration = 1.4f;
    btnTimeDistance.autostart = YES;
    [btnTimeDistance animate];
    
    btnLeg.animation = @"pop";
    btnLeg.delay = 0.0f;
    btnLeg.duration = 1.4f;
    btnLeg.autostart = YES;
    [btnLeg animate];
    
    btnGuide.animation = @"pop";
    btnGuide.delay = 0.0f;
    btnGuide.duration = 1.4f;
    btnGuide.autostart = YES;
    [btnGuide animate];
    
    btnFreezingLevel.animation = @"pop";
    btnFreezingLevel.delay = 0.0f;
    btnFreezingLevel.duration = 1.4f;
    btnFreezingLevel.autostart = YES;
    [btnFreezingLevel animate];
}
- (void)logoutButtonPressed
{
    // set user variables to nil
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"userName"];
    [userDefaults synchronize];
    // reload view
    [self viewWillDisappear:NO];
    [self viewWillAppear:NO];
}


//NavLog
- (void)onNavLog{
    NavLogViewController *navLogVC = [[NavLogViewController alloc] init];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
    [AppDelegate sharedDelegate].navLog_VC = navLogVC;
    [self.navigationController pushViewController:navLogVC animated:YES];
}

- (void)clearDocumentsButtonPressed
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
    request = nil;
    entityDescription = nil;
    // delete all the lesson group if there's no child lesson groups, lessons, or documents
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

- (void)clearLessonsButtonPressed
{
    NSLog(@"clearing all lesson data and records");
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
    [context save:&error];
}
- (IBAction)onTools:(UIButton *)sender {
    switch (sender.tag) {
        case 101://navlog
        {
            [self onNavLog];
            break;
        }
        case 102://T.O.L.D
        {
            ToldViewController *toldVC = [[ToldViewController alloc] init];
            [self.navigationController pushViewController:toldVC animated:YES];
            break;
        }
        case 103://W & B
        {
            WeightAndBalanceViewController *wbVC = [[WeightAndBalanceViewController alloc] init];
            [self.navigationController pushViewController:wbVC animated:YES];
            break;
        }
        case 104://CHECKLISTS
        {
            MainCheckListsViewController *mainCheckListVC = [[MainCheckListsViewController alloc] init];
            [AppDelegate sharedDelegate].checklist_VC = mainCheckListVC;
            [self.navigationController pushViewController:mainCheckListVC animated:YES];
            break;
        }
        case 105://FLIGHT TRACKING
        {
            FlightTrackingMainViewController *fTrackVC = [[FlightTrackingMainViewController alloc] init];
            [self.navigationController pushViewController:fTrackVC animated:YES];
            break;
        }
        default:
            break;
    }
}

- (IBAction)onCalculation:(UIButton *)sender {
    switch (sender.tag) {
        case 106://WIND
        {
            WindViewController *windVC = [[WindViewController alloc] init];
            [self.navigationController pushViewController:windVC animated:YES];
            break;
        }
        case 107://FUEL
        {
            FuelViewController *fuelVC = [[FuelViewController alloc] init];
            [self.navigationController pushViewController:fuelVC animated:YES];
            break;
        }
        case 108://PA/DA
        {
            PaDaViewController *padaVC = [[PaDaViewController alloc] init];
            [self.navigationController pushViewController:padaVC animated:YES];
            break;
        }
        case 109://ISA
        {
            IsaViewController *isaVC = [[IsaViewController alloc] init];
            [self.navigationController pushViewController:isaVC animated:YES];
            break;
        }
        case 110://CONVERSIONS
        {
            ConversionsViewController *conversionsVC = [[ConversionsViewController alloc] init];
            [self.navigationController pushViewController:conversionsVC animated:YES];
            break;
        }
        case 111://SPEED
        {
            SpeedViewController *speedVC = [[SpeedViewController alloc] init];
            [self.navigationController pushViewController:speedVC animated:YES];
            break;
        }
        case 112://CLOUDS
        {
            CloudsViewController *cloudVC = [[CloudsViewController alloc] init];
            [self.navigationController pushViewController:cloudVC animated:YES];
            break;
        }
        case 113://TIMEDISTANCE
        {
            TimeDistanceViewController *timedistanceVC = [[TimeDistanceViewController alloc] init];
            [self.navigationController pushViewController:timedistanceVC animated:YES];
            break;
        }
        case 114://LEG
        {
            LegViewController *legVC = [[LegViewController alloc] init];
            [self.navigationController pushViewController:legVC animated:YES];
            break;
        }
        case 115://GLIDE
        {
            GlideViewController *glideVC = [[GlideViewController alloc] init];
            [self.navigationController pushViewController:glideVC animated:YES];
            break;
        }
        case 116://FREEZINGLEVEL
        {
            FreezingLevelViewController *freezingVC = [[FreezingLevelViewController alloc] init];
            [self.navigationController pushViewController:freezingVC animated:YES];
            break;
        }
        default:
            break;
    }
}

@end
