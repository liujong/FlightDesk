//
//  CKViewController.m
//   MBCalendarKit
//
//  Created by Moshe Berman on 4/10/13.
//  Copyright (c) 2013 Moshe Berman. All rights reserved.
//

#import "CKCalendarViewControllerInternal.h"

#import "CKCalendarView.h"

#import "CKCalendarEvent.h"

#import "NSCalendarCategories.h"
#import "DashboardView.h"
#import "SettingViewController.h"
#import "UIView+Badge.h"

@interface CKCalendarViewControllerInternal () <CKCalendarViewDataSource, CKCalendarViewDelegate, TOSplitViewControllerDelegate>
{
    UIButton *settingsButton;
    DashboardView *dashboardView;
}

@property (nonatomic, strong) CKCalendarView *calendarView;

@property (nonatomic, strong) UISegmentedControl *modePicker;

@property (nonatomic, strong) NSMutableArray *events;

@end

@implementation CKCalendarViewControllerInternal 

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    /* iOS 7 hack*/
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    [self setTitle:NSLocalizedString(@"Schedule", @"A title for the calendar view.")];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    /* Prepare the events array */
    
    [self setEvents:[NSMutableArray new]];
    
    /* Calendar View */

    [self setCalendarView:[CKCalendarView new]];
    [[self calendarView] setDataSource:self];
    [[self calendarView] setDelegate:self];
    [[self view] addSubview:[self calendarView]];

    [[self calendarView] setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] animated:NO];
    [[self calendarView] setDisplayMode:CKCalendarViewModeMonth animated:NO];
    
    /* Mode Picker */
    
    NSArray *items = @[NSLocalizedString(@"Month", @"A title for the month view button."), NSLocalizedString(@"Week",@"A title for the week view button."), NSLocalizedString(@"Day", @"A title for the day view button.")];
    
    [self setModePicker:[[UISegmentedControl alloc] initWithItems:items]];
    [[self modePicker] addTarget:self action:@selector(modeChangedUsingControl:) forControlEvents:UIControlEventValueChanged];
    [[self modePicker] setSelectedSegmentIndex:0];
    
    /* Toolbar setup */
    
    NSString *todayTitle = NSLocalizedString(@"Today", @"A button which sets the calendar to today.");
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:todayTitle style:UIBarButtonItemStyleBordered target:self action:@selector(todayButtonTapped:)];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:[self modePicker]];
    
    [self setToolbarItems:@[todayButton, item] animated:NO];
    [[self navigationController] setToolbarHidden:NO animated:NO];
    
    /* Remove bar translucency. */
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
    
    // add the dashboard button
    UIImage *dashImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Dashboard" ofType:@"png"]];
    CGRect dashImageFrame = CGRectMake(0, 0, dashImage.size.width, dashImage.size.height);
    UIButton *dashButton = [[UIButton alloc] initWithFrame:dashImageFrame];
    [dashButton setBackgroundImage:dashImage forState:UIControlStateNormal];
    [dashButton addTarget:self action:@selector(showDashboard) forControlEvents:UIControlEventTouchUpInside];
    [dashButton setShowsTouchWhenHighlighted:YES];
    UIView *containsViewOfDashboard = [[UIView alloc] initWithFrame:CGRectMake(5, 0, dashImage.size.width+10, dashImage.size.height)];
    [containsViewOfDashboard addSubview:dashButton];
    
    UIBarButtonItem *dashButtonItem =[[UIBarButtonItem alloc] initWithCustomView:containsViewOfDashboard];
    
    UIImage *settingsImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Settings_nav" ofType:@"png"]];
    CGRect settingsImageFrame = CGRectMake(0, 0, settingsImage.size.width, settingsImage.size.height);
    settingsButton = [[UIButton alloc] initWithFrame:settingsImageFrame];
    [settingsButton setBackgroundImage:settingsImage forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setShowsTouchWhenHighlighted:YES];
    UIView *containsViewOfSetting = [[UIView alloc] initWithFrame:CGRectMake(5, 0, settingsImage.size.width+10, settingsImage.size.height)];
    [containsViewOfSetting addSubview:settingsButton];
    UIBarButtonItem *settingsButtonItem =[[UIBarButtonItem alloc] initWithCustomView:containsViewOfSetting];
    //self.navigationItem.rightBarButtonItem=dashButtonItem;
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects:dashButtonItem, settingsButtonItem, nil];
}
-(void)hideSettingBtn{
    settingsButton.hidden = YES;
}

-(void)handleDashboardTap:(UIGestureRecognizer *)gestureRecognizer {
    if (dashboardView != nil) {
        dashboardView.hidden = YES;
        [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:dashboardView];
        [dashboardView removeFromSuperview];
        dashboardView = nil;
        // enable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = YES;
        }
    }
}

-(void)showDashboard
{
    if (dashboardView != nil) {
        NSLog(@"Dashboard already displayed!");
        return;
    }
    // disable naviation bar
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    // create a new dashboard view
    dashboardView = [[DashboardView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
    if (currentScreenRect.size.height<currentScreenRect.size.width) {
        [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
    }else{
        [dashboardView setContentSize:CGSizeMake(0,0)];
    }
    // use tap gesture to close view
    UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDashboardTap:)];
    [dashboardView addGestureRecognizer:tapToClose];
    // add the view to the root view controller
    
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:dashboardView];
}

-(void)showSettings
{
    SettingViewController *settingVc = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    NSArray *controllers = @[settingVc];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewController.delegate = self;
    splitViewController.title = @"Settings";
    splitViewController.isShowFromSetting = YES;
    [self.navigationController pushViewController:splitViewController animated:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
    if (dashboardView != nil) {
        [dashboardView setFrame:[[UIScreen mainScreen] bounds]];
        CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
        if (currentScreenRect.size.height<currentScreenRect.size.width) {
            [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
        }else{
            [dashboardView setContentSize:CGSizeMake(0,0)];
        }
        [dashboardView reloadViewsWithCurrentScreen];
    }
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:210.0f/255.0f green:50.0f/255.0f blue:140.0f/255.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:80.0f/255.0f green:0 blue:80.0f/255.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setNavigationColorWithGradiant];
    settingsButton.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:nil];
    settingsButton.badge.badgeColor = [UIColor redColor];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"CKCalendarViewControllerInternal"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Toolbar Items

- (void)modeChangedUsingControl:(id)sender
{
    [[self calendarView] setDisplayMode:(CKCalendarDisplayMode)[[self modePicker] selectedSegmentIndex]];
}

- (void)todayButtonTapped:(id)sender
{
    [[self calendarView] setDate:[NSDate date] animated:NO];
}

#pragma mark - CKCalendarViewDataSource

- (NSArray *)calendarView:(CKCalendarView *)CalendarView eventsForDate:(NSDate *)date
{
    if ([[self dataSource] respondsToSelector:@selector(calendarView:eventsForDate:)]) {
        return [[self dataSource] calendarView:CalendarView eventsForDate:date];
    }
    return nil;
}

#pragma mark - CKCalendarViewDelegate

// Called before the selected date changes
- (void)calendarView:(CKCalendarView *)calendarView willSelectDate:(NSDate *)date
{
    if ([self isEqual:[self delegate]]) {
        return;
    }
    
    if ([[self delegate] respondsToSelector:@selector(calendarView:willSelectDate:)]) {
        [[self delegate] calendarView:calendarView willSelectDate:date];
    }
}

// Called after the selected date changes
- (void)calendarView:(CKCalendarView *)calendarView didSelectDate:(NSDate *)date
{
    if ([self isEqual:[self delegate]]) {
        return;
    }
    
    if ([[self delegate] respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [[self delegate] calendarView:calendarView didSelectDate:date];
    }
}

//  A row is selected in the events table. (Use to push a detail view or whatever.)
- (void)calendarView:(CKCalendarView *)calendarView didSelectEvent:(CKCalendarEvent *)event
{
    if ([self isEqual:[self delegate]]) {
        return;
    }
    
    if ([[self delegate] respondsToSelector:@selector(calendarView:didSelectEvent:)]) {
        [[self delegate] calendarView:calendarView didSelectEvent:event];
    }
}

#pragma mark - Calendar View

- (CKCalendarView *)calendarView
{
    return _calendarView;
}

#pragma mark - Orientation Support

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [[self calendarView] reloadAnimated:NO];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
//    [[[self calendarView] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)] reloadAnimated:NO];
    //[[self calendarView] reloadAnimated:NO];
}


@end
