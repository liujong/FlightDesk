//
//  RecordsViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "AppDelegate.h"
#import "RecordsViewController.h"
#import "LessonRecordViewController.h"
#import "PersistentCoreDataStack.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "Student+CoreDataClass.h"

#import "AddLessonViewController.h"
#import "StutdentCell.h"
#import "PilotGroupCell.h"
#import "StageCell.h"
#import "LessonCell.h"

#define FOREGROUND_UPDATE_INTERVAL 60 // 1 minute

@interface RecordsViewController () <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate>{
    
    UIRefreshControl *refreshControl;
    BOOL hasStudentsWithInstructorLevel;
    
    NSManagedObjectContext *contextRecords;
    
    BOOL isInstructorOrStudent;
}

//@property (strong, nonatomic) NSTimer *lessonsForegroundUpdateTimer;

@end

@implementation RecordsViewController
{
    UITableView *programLessonTableView;
    
    // lesson groups & lessons
    NSMutableArray *visibleCells;
    NSMutableArray *visibleCellsOnlyPrograms;
}

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
    
    
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Program's Lessons";
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    // add the "Add Lesson" button
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 40, 40)];
    [addButton addTarget:self action:@selector(addLessonByInstructor) forControlEvents:UIControlEventTouchUpInside];
    [addButton setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    UIView *containsViewOfAdd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [containsViewOfAdd addSubview:addButton];
    UIBarButtonItem *addBtnItem = [[UIBarButtonItem alloc] initWithCustomView:containsViewOfAdd];
        NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:addBtnItem];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    hasStudentsWithInstructorLevel = NO;
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        isInstructorOrStudent = YES;
    }else{
        isInstructorOrStudent = NO;
    }
    
    // Initialize the lesson table
    programLessonTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    programLessonTableView.delegate = self;
    programLessonTableView.dataSource = self;
    
    
    [programLessonTableView registerNib:[UINib nibWithNibName:@"LessonCell" bundle:nil] forCellReuseIdentifier:@"LessonItem"];
    
    [self.view addSubview:programLessonTableView];
    programLessonTableView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDic = @{@"table": programLessonTableView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[table]|" options:kNilOptions metrics:0 views:viewsDic]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[table]|" options:kNilOptions metrics:0 views:viewsDic]];
    NSLayoutConstraint *_tableWidth = [NSLayoutConstraint constraintWithItem:programLessonTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.bounds.size.width];
    NSLayoutConstraint *_tableHeight = [NSLayoutConstraint constraintWithItem:programLessonTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.bounds.size.height];
    [programLessonTableView addConstraint:_tableWidth];
    [programLessonTableView addConstraint:_tableHeight];
    
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [programLessonTableView addSubview:refreshControl];
    
    if (isInstructorOrStudent == YES) {
    }else{
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            programLessonTableView.contentInset = UIEdgeInsetsMake(-34.0f, 0.0f, 0.0f, 0.0f);
        }else{
            programLessonTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        }
    }
    
    visibleCells = [[NSMutableArray alloc] init];
    visibleCellsOnlyPrograms = [[NSMutableArray alloc] init];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"RecordsViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self setNavigationColorWithGradiant];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        isInstructorOrStudent = YES;
    }else{
        isInstructorOrStudent = NO;
    }
    
    [self receiveNotification];
    if ([AppDelegate sharedDelegate].isLogin == YES) {
        [self populateLessons];
    }else{
        [visibleCells removeAllObjects];
        [visibleCellsOnlyPrograms removeAllObjects];
        [programLessonTableView reloadData];
    }
    if ([AppDelegate sharedDelegate].currentSyncingIndex != 1 && [AppDelegate sharedDelegate].isLogin && ![AppDelegate sharedDelegate].isStartPerformSyncCheck) {
        if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"SyncedAllDataFromServer"]==YES) {
            [[AppDelegate sharedDelegate] startThreadToSyncData:2];
        }else{
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
            NSString *loadingMsg = @"You don't sync your data from Flightdesk, please wait for it.";
            hud.label.text = loadingMsg;
            [[AppDelegate sharedDelegate] startThreadToSyncData:1];
        }
    }
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:2];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification) name:NOTIFICATION_FLIGHTDESK_LOGIN_SUCCESSFUL_SNYC object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FLIGHTDESK_LOGIN_SUCCESSFUL_SNYC object:nil];
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
    [self superClassDeviceOrientationDidChange];
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:0 green:140.0f/255.0f blue:1.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor blueColor].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)receiveNotification{
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        addButton.hidden = NO;
    }else{
        addButton.hidden = YES;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    FDLogDebug(@"GREGDEBUG view transition! New size: %f x %f", size.width, size.height);
    // TODO: change the size of the UITableView (programLessonTableView) here!
}

-(void)addLessonByInstructor{
    if (hasStudentsWithInstructorLevel) {
        AddLessonViewController *addLesView = [[AddLessonViewController alloc] initWithNibName:@"AddLessonViewController" bundle:nil];
        [self.navigationController pushViewController:addLesView animated:YES];
    }else{
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            AddLessonViewController *addLesView = [[AddLessonViewController alloc] initWithNibName:@"AddLessonViewController" bundle:nil];
            [self.navigationController pushViewController:addLesView animated:YES];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"You do not have any Students enrolled to create Courses, Lessons or Quizzes for,  go to the \"Training\" function under Settings and add a student to your app." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)expandGroup:(LessonGroup*)group withCells:(NSMutableArray*)cells
{
    // loop through sub-groups
    for (LessonGroup *subGroup in group.subGroups) {
        [cells addObject:subGroup];
        // expand the sub-group if needed
        if ([subGroup.expanded boolValue] == YES) {
            [self expandGroup:subGroup withCells:cells];
            
            NSArray *sortedLessons = [self sortLessonByNumber:subGroup.lessons];
            for (Lesson *lesson in sortedLessons) {
                [cells addObject:lesson];
            }
        }
    }
}
- (NSArray *)sortLessonByNumber:(NSOrderedSet<Lesson *> *)lessons{
    NSMutableArray *tempLessons = [NSMutableArray arrayWithArray:[lessons array]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lessonNumber" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedLessons = [tempLessons sortedArrayUsingDescriptors:sortDescriptors];
    return sortedLessons;
}
- (void)expandStudent:(Student*)student withCells:(NSMutableArray*)cells
{
    // loop through sub-groups
    for (LessonGroup *subGroup in student.subGroups) {
        if ([subGroup.isShown boolValue] == YES) {
            [cells addObject:subGroup];
            // expand the sub-group if needed
            if ([subGroup.expanded boolValue] == YES) {
                [self expandGroup:subGroup withCells:cells];
                // add any lessons
                NSArray *sortedLessons = [self sortLessonByNumber:subGroup.lessons];
                for (Lesson *lesson in sortedLessons) {
                    [cells addObject:lesson];
                }
            }
        }
    }
}

- (BOOL)populateLessons
{
    BOOL requireRepopulate = NO;
    // add students assigned to the current user (and their lesson groups)
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:contextRecords];
    [visibleCells removeAllObjects];
    [visibleCellsOnlyPrograms removeAllObjects];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve students!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid students found!");
    } else {
        FDLogDebug(@"%lu students found", (unsigned long)[objects count]);
        hasStudentsWithInstructorLevel = YES;
        NSMutableArray *tempStudents = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedStudents = [tempStudents sortedArrayUsingDescriptors:sortDescriptors];
        // loop through expanded root groups and add sub-groups and lessons
        for (Student *student in sortedStudents) {
            if (student.subGroups.count > 0) {
                [visibleCells addObject:student];
                if ([student.expanded boolValue] == YES) {
                    [self expandStudent:student withCells:visibleCells];
                }
            }
        }
        requireRepopulate = YES;
    }
//    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        // add lesson groups assigned to the current user
        entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
        // load the remaining lesson groups
        request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        // only grab root lesson groups (where there is no parent)
        NSPredicate *predicate;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL"];
        }else{
            predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL AND isShown = YES"];
        }
        [request setPredicate:predicate];
        objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve lessons!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid lesson groups found!");
        } else {
            FDLogDebug(@"%lu lesson groups found", (unsigned long)[objects count]);
            NSMutableArray *tempLessonGroups = [NSMutableArray arrayWithArray:objects];
            // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            NSArray *sortedRootGroups = [tempLessonGroups sortedArrayUsingDescriptors:sortDescriptors];
            //visibleCells = [NSMutableArray arrayWithCapacity:[sortedRootGroups count]];
            // loop through expanded root groups and add sub-groups and lessons
            for (LessonGroup *rootGroup in sortedRootGroups) {
                BOOL isExistLessonGroupWithStd = [self isExistLessonGruopWithStudent:rootGroup];
                if (isInstructorOrStudent == YES) {
                    if (!isExistLessonGroupWithStd) {
                        [visibleCellsOnlyPrograms addObject:rootGroup];
                    }
                }else{
                    [visibleCells addObject:rootGroup];
                }
                if ([rootGroup.expanded boolValue] == YES) {
                    if (isInstructorOrStudent == YES) {
                        if (!isExistLessonGroupWithStd) {
                            [self expandGroup:rootGroup withCells:visibleCellsOnlyPrograms];
                        }
                    }else{
                        [self expandGroup:rootGroup withCells:visibleCells];
                    }
                    
                    if (rootGroup.lessons.count > 0) {
                        NSArray *sortedLessons = [self sortLessonByNumber:rootGroup.lessons];
                        for (Lesson *lesson in sortedLessons) {
                            if (isInstructorOrStudent == YES) {
                                if (!isExistLessonGroupWithStd) {
                                    [visibleCellsOnlyPrograms addObject:lesson];
                                }
                            }else{
                                [visibleCells addObject:lesson];
                            }
                        }
                    }
                }
            }
            requireRepopulate = YES;
        }

//    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
//        // add lesson groups assigned to the current user
//        entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
//        // load the remaining lesson groups
//        request = [[NSFetchRequest alloc] init];
//        [request setEntity:entityDesc];
//        // only grab root lesson groups (where there is no parent)
//        NSPredicate *predicate;
//        predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL AND isShown = YES"];
//        [request setPredicate:predicate];
//        objects = [contextRecords executeFetchRequest:request error:&error];
//        if (objects == nil) {
//            FDLogError(@"Unable to retrieve lessons!");
//        } else if (objects.count == 0) {
//            FDLogDebug(@"No valid lesson groups found!");
//        } else {
//            FDLogDebug(@"%lu lesson groups found", (unsigned long)[objects count]);
//            NSMutableArray *tempLessonGroups = [NSMutableArray arrayWithArray:objects];
//            // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
//            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
//            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
//            NSArray *sortedRootGroups = [tempLessonGroups sortedArrayUsingDescriptors:sortDescriptors];
//            //visibleCells = [NSMutableArray arrayWithCapacity:[sortedRootGroups count]];
//            // loop through expanded root groups and add sub-groups and lessons
//            for (LessonGroup *rootGroup in sortedRootGroups) {
//                [visibleCells addObject:rootGroup];
//                if ([rootGroup.expanded boolValue] == YES) {
//                    [self expandGroup:rootGroup withCells:visibleCells];
//
//                    if (rootGroup.lessons.count > 0) {
//                        for (Lesson *lesson in rootGroup.lessons) {
//                            [visibleCells addObject:lesson];
//                        }
//                    }
//                }
//            }
//            requireRepopulate = YES;
//        }
//    }
    
    [programLessonTableView reloadData];
    return requireRepopulate;
}

- (BOOL)isExistLessonGruopWithStudent:(LessonGroup *)lesGroup{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student != NULL AND name == %@", lesGroup.name];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        return NO;
    } else if (objects.count == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (void)endRefresh{
    [refreshControl endRefreshing];
}
- (void)reloadData
{
    // reseting context does not keep them in sync
    //AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //NSManagedObjectContext *context = appDelegate.persistentCoreDataStack.managedObjectContext;
    //[context reset];
    if ([AppDelegate sharedDelegate].isLogin == YES) {
        [refreshControl endRefreshing];
        [programLessonTableView reloadData];
    }else{
        [visibleCells removeAllObjects];
        [visibleCellsOnlyPrograms removeAllObjects];
        [programLessonTableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    FDLogError(@"RecordsViewController needs to handle memory warning!!!!");
}

-(NSArray*) indexPathsForSection:(int)section withNumberOfRows:(int)numberOfRows {
    NSMutableArray* indexPaths = [NSMutableArray new];
    for (int i = 0; i < numberOfRows; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

- (void)handleRefresh:(id)sender{
    [[AppDelegate sharedDelegate] startThreadToSyncData:2];;
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (isInstructorOrStudent == YES) {
        return 2;
    }else{
        return 1;
    }
}
- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (isInstructorOrStudent == YES) {
        if (section == 0) {
            return @"Students";
        }else{
            return @"Programs";
        }
    }else{
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isInstructorOrStudent == YES) {
        if (section == 0) {
            return [visibleCells count];
        }else{
            return [visibleCellsOnlyPrograms count];
        }
    }else{
        return [visibleCells count];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id rowElement;
    if (indexPath.section == 0) {
        rowElement = [visibleCells objectAtIndex:indexPath.row];
    }else{
        rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
    }
    UITableViewCell *cell = nil;
    if ([rowElement isMemberOfClass:[Student class]]) {
        // row is a student
        static NSString *simpleTableIdentifier = @"StudentItem";
        StutdentCell *studentCell = (StutdentCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (studentCell == nil) {
            studentCell = [StutdentCell sharedCell];
            studentCell.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
        }
        UIImage *sectionImage = nil;
        Student *student = rowElement;
        if ([student.expanded boolValue] == YES) {
            sectionImage = [UIImage imageNamed:@"UIButtonBarArrowUp.png"];
        } else {
            sectionImage = [UIImage imageNamed:@"UIButtonBarArrowDown.png"];
        }
        studentCell.imgStudentArrow.image = sectionImage;
        NSString *studentFullName = [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
        studentCell.lblStudentName.text = studentFullName;
        return studentCell;
    } else if ([rowElement isMemberOfClass:[Lesson class]]) {
        // row is a lesson
        
        Lesson *lesson = rowElement;
        
        static NSString *cellIdentifier = @"LessonItem";
        LessonCell *lessonCell = (LessonCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                                               forIndexPath:indexPath];
        
        //        static NSString *simpleTableIdentifier = @"LessonItem";
        //        LessonCell *lessonCell = (LessonCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        //        if (lessonCell == nil) {
        //            lessonCell = [LessonCell sharedCell];
        //        }
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            lessonCell.leftUtilityButtons = [self leftButtons];
            lessonCell.rightUtilityButtons = [self rightButtons];
            lessonCell.delegate = self;
        }
        int indexStep = [lesson.indentation intValue];
        lessonCell.positionLeftLessonNameCons.constant = 86 + (indexStep-2) * 15;
        //        if (lesson.name) {
        //            lessonCell.lessonTitle.text = [NSString stringWithFormat:@"%@ - %@", lesson.name, lesson.groundDescription];
        //        }else{
        lessonCell.lessonTitle.text = [NSString stringWithFormat:@"Lesson %@ - %@", [lesson.lessonNumber stringValue], lesson.groundDescription];
        //        }
        
        NSInteger lessonStatus = [self getStatusFromLesson:lesson];
        switch (lessonStatus) {
            case 1://in progress
                lessonCell.lessonStatus.text = @"In Progress";
                lessonCell.imgStatus.hidden = YES;
                lessonCell.lessonStatus.hidden = NO;
                lessonCell.lessonStatus.textColor = [UIColor blueColor];
                break;
            case 2:// completed
                lessonCell.lessonStatus.text = @"Completed";
                lessonCell.imgStatus.hidden = NO;
                lessonCell.lessonStatus.hidden = NO;
                lessonCell.lessonStatus.textColor = [UIColor greenColor];
                break;
            case 3:// isn't started
                
                lessonCell.lessonStatus.hidden = YES;
                lessonCell.imgStatus.hidden = YES;
                lessonCell.lessonStatus.textColor = [UIColor blackColor];
                break;
            default:
                break;
        }
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            lessonCell.postionLessonTitleWidth.constant = -400.0f;
        }
        
        return lessonCell;
    } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        
        LessonGroup *lessonGroup = rowElement;
        BOOL isTopLessonGroup = NO;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            if (lessonGroup.student && [lessonGroup.indentation integerValue] == 2) {
                isTopLessonGroup = YES;
            }else{
                isTopLessonGroup = NO;
            }
        }else{
            if ([lessonGroup.indentation integerValue] == 0) {
                isTopLessonGroup = YES;
            }else{
                isTopLessonGroup = NO;
            }
        }
        if (isTopLessonGroup) {
            // row is a lesson group
            static NSString *simpleTableIdentifier = @"PilotGroupItem";
            PilotGroupCell *pilotCell = (PilotGroupCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
            if (pilotCell == nil) {
                pilotCell = [PilotGroupCell sharedCell];
            }
            
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                pilotCell.rightUtilityButtons = [self rightButtons];
                pilotCell.delegate = self;
            }
            
            pilotCell.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
            
            UIImage *sectionImage = nil;
            
            if ([lessonGroup.expanded boolValue] == YES) {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowUp.png"];
            } else {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowDown.png"];
            }
            
            CGRect eximgRect = pilotCell.exImage.frame;
            CGRect titleRect = pilotCell.lblTitle.frame;
            int indexStep = [lessonGroup.indentation intValue];
            [pilotCell.exImage setFrame:CGRectMake(48 + indexStep * 15, eximgRect.origin.y, eximgRect.size.width, eximgRect.size.height)];
            [pilotCell.lblTitle setFrame:CGRectMake(86 + indexStep * 15, titleRect.origin.y, titleRect.size.width, titleRect.size.height)];
            [pilotCell.exImage setImage:sectionImage];
            pilotCell.lblTitle.text = lessonGroup.name;
            float pros = [self getStatusFromPilotType:lessonGroup];
            pilotCell.statusProgressView.progress = [self getStatusFromPilotType:lessonGroup];
            pilotCell.statusProgressLbl.text = [NSString stringWithFormat:@"%.1f %%", pros * 100];
            
            return pilotCell;
        }else{
            // row is a lesson group
            static NSString *simpleTableIdentifier = @"StageItem";
            StageCell *stageCell = (StageCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
            if (stageCell == nil) {
                stageCell = [StageCell sharedCell];
            }
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                stageCell.rightUtilityButtons = [self rightButtons];
                stageCell.delegate = self;
            }
            
            stageCell.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
            
            UIImage *sectionImage = nil;
            
            if ([lessonGroup.expanded boolValue] == YES) {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowUp.png"];
            } else {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowDown.png"];
            }
            CGRect eximgRect = stageCell.exImage.frame;
            CGRect titleRect = stageCell.stageTitle.frame;
            int indexStep = [lessonGroup.indentation intValue];
            [stageCell.exImage setFrame:CGRectMake(48 + indexStep * 15, eximgRect.origin.y, eximgRect.size.width, eximgRect.size.height)];
            [stageCell.stageTitle setFrame:CGRectMake(86 + indexStep * 15, titleRect.origin.y, titleRect.size.width, titleRect.size.height)];
            [stageCell.exImage setImage:sectionImage];
            stageCell.stageTitle.text = lessonGroup.name;
            
            NSInteger corseStatus = [self getStatusFromCorse:lessonGroup];
            switch (corseStatus) {
                case 1://in progress
                    stageCell.corseStatusLbl.text = @"In Progress";
                    stageCell.corseStatusLbl.textColor = [UIColor blueColor];
                    break;
                case 2:// completed
                    stageCell.corseStatusLbl.text = @"Completed";
                    stageCell.corseStatusLbl.textColor = [UIColor greenColor];
                    break;
                case 3:// isn't started
                    stageCell.corseStatusLbl.text = @"Not Started";
                    stageCell.corseStatusLbl.textColor = [UIColor blackColor];
                    break;
                default:
                    break;
            }
            
            
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                stageCell.corseStatusLbl.hidden = YES;
            }else{
                stageCell.corseStatusLbl.hidden = NO;
            }
            
            return stageCell;
        }
    }
    
    return cell;
}

-(void)collapseLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row withSection:(NSInteger)section{
    if (section == 0) {
        
        FDLogDebug(@"collapsing lesson group %@: cells %lu", lessonGroup.name, (unsigned long)[visibleCells count]);
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        int i;
        // loop through all subsequent visible cells until end of array or new parent lesson group
        for (i = row + 1; i < [visibleCells count]; ++i) {
            id rowElement = [visibleCells objectAtIndex:i];
            // determine if this element is a lesson group or a lesson
            if ([rowElement isMemberOfClass:[Lesson class]]) {
                // just remove the row
                if ([lessonGroup.indentation integerValue] < [((Lesson *)rowElement).indentation integerValue]) {
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                }
            } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                // check if this is a sub-lesson group of this lesson group
                LessonGroup *subLessonGroup = rowElement;
                if (subLessonGroup.parentGroup == lessonGroup) {
                    if ([subLessonGroup.expanded boolValue] == YES) {
                        subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                    }
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                } else {
                    break;
                }
            }
        }
        // remove collapsed rows from array of visible objects
        int rowsCollapsed = i - (row + 1);
        FDLogDebug(@"rows collapsed: %d index paths to delete: %d", rowsCollapsed, [deleteIndexPaths count]);
        if (rowsCollapsed > 0 && [deleteIndexPaths count] > 0) {
            [visibleCells removeObjectsInRange:(NSRange){row + 1, [deleteIndexPaths count]}];
            [programLessonTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
        lessonGroup.expanded = [NSNumber numberWithBool:NO];
    }else{
        
        FDLogDebug(@"collapsing lesson group %@: cells %lu", lessonGroup.name, (unsigned long)[visibleCellsOnlyPrograms count]);
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        int i;
        // loop through all subsequent visible cells until end of array or new parent lesson group
        for (i = row + 1; i < [visibleCellsOnlyPrograms count]; ++i) {
            id rowElement = [visibleCellsOnlyPrograms objectAtIndex:i];
            // determine if this element is a lesson group or a lesson
            if ([rowElement isMemberOfClass:[Lesson class]]) {
                // just remove the row
                if ([lessonGroup.indentation integerValue] < [((Lesson *)rowElement).indentation integerValue]) {
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                }
            } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                // check if this is a sub-lesson group of this lesson group
                LessonGroup *subLessonGroup = rowElement;
                if (subLessonGroup.parentGroup == lessonGroup) {
                    if ([subLessonGroup.expanded boolValue] == YES) {
                        subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                    }
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                } else {
                    break;
                }
            }
        }
        // remove collapsed rows from array of visible objects
        int rowsCollapsed = i - (row + 1);
        FDLogDebug(@"rows collapsed: %d index paths to delete: %d", rowsCollapsed, [deleteIndexPaths count]);
        if (rowsCollapsed > 0 && [deleteIndexPaths count] > 0) {
            [visibleCellsOnlyPrograms removeObjectsInRange:(NSRange){row + 1, [deleteIndexPaths count]}];
            [programLessonTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
        lessonGroup.expanded = [NSNumber numberWithBool:NO];
    }
}

-(void)expandLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row  withSection:(NSInteger)section{
    int rowsExpanded = 0;
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    if (section == 0) {
        
        // check if sub-sections need to be expanded, expand recursively
        if (lessonGroup.subGroups != NULL && [lessonGroup.subGroups count] > 0) {
            // loop through each child group and expand it if it was already expanded
            for (LessonGroup *subLessonGroup in lessonGroup.subGroups) {
                ++rowsExpanded;
                [visibleCells insertObject:subLessonGroup atIndex:row + rowsExpanded];
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:section]];
            }
        }
        // expand child lessons
        lessonGroup.expanded = [NSNumber numberWithBool:YES];
        if (lessonGroup.lessons != NULL && [lessonGroup.lessons count] > 0) {
            int i = 1;
            // sort the lessons
            
            NSArray *sortedLessons = [self sortLessonByNumber:lessonGroup.lessons];
            for (Lesson *lesson in sortedLessons) {
                [visibleCells insertObject:lesson atIndex:row + rowsExpanded + i];
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded + i inSection:section]];
                ++i;
            }
        }
    }else{
        
        // check if sub-sections need to be expanded, expand recursively
        if (lessonGroup.subGroups != NULL && [lessonGroup.subGroups count] > 0) {
            // loop through each child group and expand it if it was already expanded
            for (LessonGroup *subLessonGroup in lessonGroup.subGroups) {
                ++rowsExpanded;
                [visibleCellsOnlyPrograms insertObject:subLessonGroup atIndex:row + rowsExpanded];
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:1]];
            }
        }
        // expand child lessons
        lessonGroup.expanded = [NSNumber numberWithBool:YES];
        if (lessonGroup.lessons != NULL && [lessonGroup.lessons count] > 0) {
            int i = 1;
            // sort the lessons
            NSArray *sortedLessons = [self sortLessonByNumber:lessonGroup.lessons];
            for (Lesson *lesson in sortedLessons) {
                [visibleCellsOnlyPrograms insertObject:lesson atIndex:row + rowsExpanded + i];
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded + i inSection:section]];
                ++i;
            }
        }
    }
    if ([insertIndexPaths count] > 0) {
        [programLessonTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

-(void)collapseStudent:(Student*)student atRow:(int)row withSection:(NSInteger)section{
    if (section == 0) {
        
        FDLogDebug(@"collapsing student %@ %@: cells %lu", student.firstName, student.lastName, (unsigned long)[visibleCells count]);
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        int i;
        // loop through all subsequent visible cells until end of array or new parent lesson group
        for (i = row + 1; i < [visibleCells count]; ++i) {
            id rowElement = [visibleCells objectAtIndex:i];
            // determine if this element is a lesson group or a lesson
            if ([rowElement isMemberOfClass:[Lesson class]]) {
                // just remove the row
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
            } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                // check if this is a sub-lesson group of this lesson group
                LessonGroup *subLessonGroup = rowElement;
                if (subLessonGroup.student == student) {
                    if ([subLessonGroup.expanded boolValue] == YES) {
                        subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                    }
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                } else if (subLessonGroup.parentGroup){
                    if (subLessonGroup.parentGroup.student == student) {
                        if ([subLessonGroup.expanded boolValue] == YES) {
                            subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                        }
                        [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                    }else{
                        break;
                    }
                }else{
                    break;
                }
            }
        }
        // remove collapsed rows from array of visible objects
        int rowsCollapsed = i - (row + 1);
        FDLogDebug(@"rows collapsed: %d index paths to delete: %d", rowsCollapsed, [deleteIndexPaths count]);
        if (rowsCollapsed > 0 && [deleteIndexPaths count] > 0) {
            [visibleCells removeObjectsInRange:(NSRange){row + 1, [deleteIndexPaths count]}];
            [programLessonTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
        student.expanded = [NSNumber numberWithBool:NO];
    }else{
        
        FDLogDebug(@"collapsing student %@ %@: cells %lu", student.firstName, student.lastName, (unsigned long)[visibleCellsOnlyPrograms count]);
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        int i;
        // loop through all subsequent visible cells until end of array or new parent lesson group
        for (i = row + 1; i < [visibleCellsOnlyPrograms count]; ++i) {
            id rowElement = [visibleCellsOnlyPrograms objectAtIndex:i];
            // determine if this element is a lesson group or a lesson
            if ([rowElement isMemberOfClass:[Lesson class]]) {
                // just remove the row
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
            } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                // check if this is a sub-lesson group of this lesson group
                LessonGroup *subLessonGroup = rowElement;
                if (subLessonGroup.student == student) {
                    if ([subLessonGroup.expanded boolValue] == YES) {
                        subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                    }
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                } else if (subLessonGroup.parentGroup){
                    if (subLessonGroup.parentGroup.student == student) {
                        if ([subLessonGroup.expanded boolValue] == YES) {
                            subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                        }
                        [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                    }else{
                        break;
                    }
                }else{
                    break;
                }
            }
        }
        // remove collapsed rows from array of visible objects
        int rowsCollapsed = i - (row + 1);
        FDLogDebug(@"rows collapsed: %d index paths to delete: %d", rowsCollapsed, [deleteIndexPaths count]);
        if (rowsCollapsed > 0 && [deleteIndexPaths count] > 0) {
            [visibleCellsOnlyPrograms removeObjectsInRange:(NSRange){row + 1, [deleteIndexPaths count]}];
            [programLessonTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
        student.expanded = [NSNumber numberWithBool:NO];
    }
}

-(void)expandStudent:(Student*)student atRow:(int)row withSection:(NSInteger)section{
    int rowsExpanded = 0;
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    if (section == 0) {
        // check if sub-sections need to be expanded, expand recursively
        if (student.subGroups != NULL && [student.subGroups count] > 0) {
            // loop through each child group and expand it if it was already expanded
            for (LessonGroup *subLessonGroup in student.subGroups) {
                if ([subLessonGroup.isShown boolValue] == YES) {
                    ++rowsExpanded;
                    [visibleCells insertObject:subLessonGroup atIndex:row + rowsExpanded];
                    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:section]];
                }
            }
        }
    }else{
        // check if sub-sections need to be expanded, expand recursively
        if (student.subGroups != NULL && [student.subGroups count] > 0) {
            // loop through each child group and expand it if it was already expanded
            for (LessonGroup *subLessonGroup in student.subGroups) {
                if ([subLessonGroup.isShown boolValue] == YES) {
                    ++rowsExpanded;
                    [visibleCellsOnlyPrograms insertObject:subLessonGroup atIndex:row + rowsExpanded];
                    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:section]];
                }
            }
        }
    }
    student.expanded = [NSNumber numberWithBool:YES];
    if ([insertIndexPaths count] > 0) {
        [programLessonTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (isInstructorOrStudent == YES) {
        return 44.0f;
    }else{
        return 0;
    }
}

#pragma mark - Table view delegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FDLogDebug(@"will select row %ld", (long)indexPath.row);
    id rowElement;
    if (indexPath.section == 0) {
        rowElement = [visibleCells objectAtIndex:indexPath.row];
    }else{
        rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
    }
    
    
    if ([rowElement isMemberOfClass:[Lesson class]]) {
        // do nothing for now
        return indexPath;
    } else if ([rowElement isMemberOfClass:[Student class]]) {
        Student *student = rowElement;
        if ([student.expanded boolValue] == YES) {
            // collapse lesson group
            FDLogDebug(@"Student %@ %@ collapsing", student.firstName, student.lastName);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                if (indexPath) {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }];
            [self collapseStudent:student atRow:(int)indexPath.row withSection:indexPath.section];
            [tableView endUpdates];
            [CATransaction commit];
        } else {
            // expand lesson group
            FDLogDebug(@"Student %@ %@ expanding", student.firstName, student.lastName);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                if (indexPath) {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }];
            [self expandStudent:student atRow:(int)indexPath.row withSection:indexPath.section];
            [tableView endUpdates];
            [CATransaction commit];
        }
    } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lessonGroup = rowElement;
        if ([lessonGroup.expanded boolValue] == YES) {
            // collapse lesson group
            FDLogDebug(@"LessonGroup %@ collapsing", lessonGroup.name);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                if (indexPath) {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }];
            [self collapseLessonGroup:lessonGroup atRow:(int)indexPath.row withSection:indexPath.section];
            [tableView endUpdates];
            [CATransaction commit];
        } else {
            // expand lesson group
            FDLogDebug(@"LessonGroup %@ expanding", lessonGroup.name);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                if (indexPath) {
                    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }];
            [self expandLessonGroup:lessonGroup atRow:(int)indexPath.row withSection:indexPath.section];
            [tableView endUpdates];
            [CATransaction commit];
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id rowElement;
    if (indexPath.section == 0) {
        rowElement = [visibleCells objectAtIndex:indexPath.row];
    }else{
        rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
    }
    if ([rowElement isMemberOfClass:[Lesson class]]) {
        Lesson *lesson = rowElement;
        // TODO: change this to take an ObjectID and then it will load and save the lesson on its own
        LessonRecordViewController *lessonViewController = [[LessonRecordViewController alloc] initWithLesson:lesson];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        lessonViewController.lessonNavTitle = [self getTitleName:(int)indexPath.row withSection:indexPath.section];
        [self.navigationController pushViewController:lessonViewController animated:YES];
    } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lessonGroup = rowElement;
        if (lessonGroup.lessons.count == 0 && lessonGroup.subGroups.count) {
            
        }
    }
}

- (NSInteger)getStatusFromLesson:(Lesson *)currentLesson{
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
        return 3;//None
    }else{
        if (countOfUnchecked == 0) {
            return 2;//completed
        }else{
            return 1;//in progress
        }
    }
}
- (NSInteger)getStatusFromCorse:(LessonGroup *)currentCorse{
    NSInteger countOfLessonStatusForProgress = 0;
    NSInteger countOfLessonStatusForNone = 0;
    if (currentCorse.lessons.count>0) {
        for (Lesson *oneLesson in currentCorse.lessons) {
            if ([self getStatusFromLesson:oneLesson] == 1){
                countOfLessonStatusForProgress = countOfLessonStatusForProgress + 1;
            }else if([self getStatusFromLesson:oneLesson] == 3) {
                countOfLessonStatusForNone = countOfLessonStatusForNone + 1;
            }
            
        }
        
        //FDLogDebug(@"%d has in progress", countOfLessonStatus);
        
        if (countOfLessonStatusForProgress == 0 && countOfLessonStatusForNone == 0) {
            return 2;
        }else{
            if (countOfLessonStatusForProgress > 0) {
                return 1;
            }else if (currentCorse.lessons.count == countOfLessonStatusForNone){
                return 3;
            }else{
                return 1;
            }
        }
    }else{
        return 3;
    }
}
- (float)getStatusFromPilotType:(LessonGroup *)currentPilot{
    NSInteger countLessonStatus = 0;
    NSInteger countAllLesson = 0;
    for (LessonGroup *lessonGro in currentPilot.subGroups) {
        for (Lesson *oneLesson in lessonGro.lessons) {
            countAllLesson = countAllLesson +1;
            if ([self getStatusFromLesson:oneLesson] == 2){
                countLessonStatus = countLessonStatus + 1;
            }
        }
    }
    if (currentPilot.lessons.count>0) {
        for (Lesson *towLesson in currentPilot.lessons) {
            countAllLesson = countAllLesson +1;
            if ([self getStatusFromLesson:towLesson] == 2){
                countLessonStatus = countLessonStatus + 1;
            }
        }
    }
    
    float pros = (float)countLessonStatus / (float)countAllLesson;
    
    return pros;
}

- (NSString *)getTitleName:(int)index withSection:(NSInteger)section{
    NSString *titleName = @"";
    for (int i = 0 ; i < index; i ++) {
        id rowElement;
        if (section == 0) {
            rowElement = [visibleCells objectAtIndex:i];
        }else{
            rowElement = [visibleCellsOnlyPrograms objectAtIndex:i];
        }
        if ([rowElement isMemberOfClass:[LessonGroup class]]) {
            LessonGroup *lessonGroup = rowElement;
            if (!lessonGroup.parentGroup && lessonGroup.subGroups.count) {
                titleName =  lessonGroup.name;
            }
        }
        
    }
    return titleName;
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor greenColor] title:@"Edit"];
    
    return leftUtilityButtons;
}
#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            if ([cell isKindOfClass:[LessonCell class]]) {
                NSIndexPath *indexPath = [programLessonTableView indexPathForCell:cell];
                id rowElement;
                if (isInstructorOrStudent) {
                    NSIndexPath *indexPath = [programLessonTableView indexPathForCell:cell];
                    if (indexPath.section == 0) {
                        rowElement = [visibleCells objectAtIndex:indexPath.row];
                    }else{
                        rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                    }
                }else{
                    rowElement = [visibleCells objectAtIndex:indexPath.row];
                }
                
                if ([rowElement isMemberOfClass:[Lesson class]]) {
                    AddLessonViewController *addLesView = [[AddLessonViewController alloc] initWithNibName:@"AddLessonViewController" bundle:nil];
                    Lesson *currentLesson = rowElement;
                    addLesView.currentLesson = currentLesson;
                    addLesView.isEditOldLesson = YES;
                    [self.navigationController pushViewController:addLesView animated:YES];
                }
            }else if ([cell isKindOfClass:[PilotGroupCell class]]) {
                
            }else if ([cell isKindOfClass:[StageCell class]]) {
                
            }
        }
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *indexPath = [programLessonTableView indexPathForCell:cell];
            id rowElement;
            if (isInstructorOrStudent) {
                if (indexPath.section == 0) {
                    rowElement = [visibleCells objectAtIndex:indexPath.row];
                }else{
                    rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                }
            }else{
                rowElement = [visibleCells objectAtIndex:indexPath.row];
            }
            
            if ([cell isKindOfClass:[LessonCell class]]) {
                if ([rowElement isMemberOfClass:[Lesson class]]) {
                    Lesson *lesson = rowElement;
                    NSString *msg = [NSString stringWithFormat:@"Do you want to delete %@", lesson.name];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                        //NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                        if (isInstructorOrStudent) {
                            if (indexPath.section == 0) {
                                [visibleCells removeObjectAtIndex:indexPath.row];
                            }else{
                                [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                            }
                        }else{
                            [visibleCells removeObjectAtIndex:indexPath.row];
                        }
                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self deleteCurrentLesson:lesson];
                        
                        NSError *error = nil;
                        [contextRecords save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                        
                    }];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                        
                    }];
                    [alert addAction:cancel];
                    [alert addAction:ok];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }else if ([cell isKindOfClass:[PilotGroupCell class]]) {
                if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                    LessonGroup *lessonGroupParent = rowElement;
                    NSString *msg = [NSString stringWithFormat:@"Do you want to delete %@", lessonGroupParent.name];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                        //NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                        
                        if (isInstructorOrStudent) {
                            if (indexPath.section == 0) {
                                [visibleCells removeObjectAtIndex:indexPath.row];
                            }else{
                                [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                            }
                        }else{
                            [visibleCells removeObjectAtIndex:indexPath.row];
                        }
                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                        DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                        deleteQuery.type = @"course";
                        deleteQuery.idToDelete = lessonGroupParent.groupID;
                        if (lessonGroupParent.subGroups.count>0) {
                            for (LessonGroup *lessonGroup in lessonGroupParent.subGroups) {
                                if (isInstructorOrStudent) {
                                    if (indexPath.section == 0) {
                                        if (visibleCells.count > indexPath.row) {
                                            id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                                LessonGroup *lessonGroupToCheck = rowElement;
                                                if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }else{
                                        if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                            id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                                LessonGroup *lessonGroupToCheck = rowElement;
                                                if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                    [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }
                                }else{
                                    if (visibleCells.count > indexPath.row) {
                                        id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                        if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                            LessonGroup *lessonGroupToCheck = rowElement;
                                            if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                [visibleCells removeObjectAtIndex:indexPath.row];
                                                [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                                            }
                                        }
                                    }
                                }
                                
                                DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                                deleteQuery.type = @"course";
                                deleteQuery.idToDelete = lessonGroup.groupID;
                                if (lessonGroup.lessons.count>0) {
                                    NSArray *sortedLessons = [self sortLessonByNumber:lessonGroup.lessons];
                                    for (Lesson *lessonToDeleteWithGroup in sortedLessons) {
                                        if (isInstructorOrStudent) {
                                            if (indexPath.section == 0) {
                                                if (visibleCells.count > indexPath.row) {
                                                    id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                    if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                        Lesson *lessonToCheck = rowElement;
                                                        if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                            [visibleCells removeObjectAtIndex:indexPath.row];
                                                            [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                                        }
                                                    }
                                                }
                                            }else{
                                                if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                                    id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                                    if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                        Lesson *lessonToCheck = rowElement;
                                                        if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                            [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                            [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                                        }
                                                    }
                                                }
                                            }
                                        }else{
                                            if (visibleCells.count > indexPath.row) {
                                                id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                    Lesson *lessonToCheck = rowElement;
                                                    if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCells removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }
                                        [self deleteCurrentLesson:lessonToDeleteWithGroup];
                                    }
                                }
                                
                                [contextRecords deleteObject:lessonGroup];
                            }
                        }
                        if (lessonGroupParent.lessons.count>0) {
                            NSArray *sortedLessons = [self sortLessonByNumber:lessonGroupParent.lessons];
                            for (Lesson *lessonToDeleteWithGroup in sortedLessons) {
                                if (isInstructorOrStudent) {
                                    if (indexPath.section == 0) {
                                        if (visibleCells.count > indexPath.row) {
                                            id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                Lesson *lessonToCheck = rowElement;
                                                if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }else{
                                        if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                            id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                Lesson *lessonToCheck = rowElement;
                                                if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                    [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }
                                }else{
                                    if (visibleCells.count > indexPath.row) {
                                        id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                        if ([rowElement isMemberOfClass:[Lesson class]]) {
                                            Lesson *lessonToCheck = rowElement;
                                            if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroupParent.groupID integerValue]) {
                                                [visibleCells removeObjectAtIndex:indexPath.row];
                                                [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                                            }
                                        }
                                    }
                                }
                                [self deleteCurrentLesson:lessonToDeleteWithGroup];
                            }
                        }
                        
                        NSError *error = nil;
                        [contextRecords deleteObject:lessonGroupParent];
                        [contextRecords save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                    }];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                        
                    }];
                    [alert addAction:cancel];
                    [alert addAction:ok];
                    [self presentViewController:alert animated:YES completion:nil];

                }
            }else if ([cell isKindOfClass:[StageCell class]]) {
                if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                    LessonGroup *lessonGroup = rowElement;
                    NSString *msg = [NSString stringWithFormat:@"Do you want to delete %@", lessonGroup.name];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                        
                        NSError *error = nil;
                        if (lessonGroup.parentGroup == nil) {
                            if (isInstructorOrStudent) {
                                if (indexPath.section == 0) {
                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                }else{
                                    [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                }
                            }else{
                                [visibleCells removeObjectAtIndex:indexPath.row];
                            }
                            [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                            DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                            deleteQuery.type = @"course";
                            deleteQuery.idToDelete = lessonGroup.groupID;
                            if (lessonGroup.subGroups.count>0) {
                                for (LessonGroup *subGroup in lessonGroup.subGroups) {
                                    if (isInstructorOrStudent) {
                                        if (indexPath.section == 0) {
                                            if (visibleCells.count > indexPath.row) {
                                                id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                                    LessonGroup *lessonGroupToCheck = rowElement;
                                                    if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCells removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }else{
                                            if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                                id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                                    LessonGroup *lessonGroupToCheck = rowElement;
                                                    if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }
                                    }else{
                                        if (visibleCells.count > indexPath.row) {
                                            id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                                                LessonGroup *lessonGroupToCheck = rowElement;
                                                if (lessonGroupToCheck.parentGroup && [lessonGroupToCheck.parentGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }
                                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                                    deleteQuery.type = @"course";
                                    deleteQuery.idToDelete = subGroup.groupID;
                                    if (subGroup.lessons.count>0) {
                                        NSArray *sortedLessons = [self sortLessonByNumber:subGroup.lessons];
                                        for (Lesson *lessonToDeleteWithGroup in sortedLessons) {
                                            if (isInstructorOrStudent) {
                                                if (indexPath.section == 0) {
                                                    if (visibleCells.count > indexPath.row) {
                                                        id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                        if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                            Lesson *lessonToCheck = rowElement;
                                                            if ([lessonToCheck.lessonGroup.groupID integerValue] == [subGroup.groupID integerValue]) {
                                                                [visibleCells removeObjectAtIndex:indexPath.row];
                                                                [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                                                            }
                                                        }
                                                    }
                                                }else{
                                                    if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                                        id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                                        if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                            Lesson *lessonToCheck = rowElement;
                                                            if ([lessonToCheck.lessonGroup.groupID integerValue] == [subGroup.groupID integerValue]) {
                                                                [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                                [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                                                            }
                                                        }
                                                    }
                                                }
                                            }else{
                                                if (visibleCells.count > indexPath.row) {
                                                    id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                    if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                        Lesson *lessonToCheck = rowElement;
                                                        if ([lessonToCheck.lessonGroup.groupID integerValue] == [subGroup.groupID integerValue]) {
                                                            [visibleCells removeObjectAtIndex:indexPath.row];
                                                            [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                                                        }
                                                    }
                                                }
                                            }
                                            [self deleteCurrentLesson:lessonToDeleteWithGroup];
                                        }
                                    }
                                    
                                    [contextRecords deleteObject:subGroup];
                                }
                            }
                            if (lessonGroup.lessons.count>0) {
                                NSArray *sortedLessons = [self sortLessonByNumber:lessonGroup.lessons];
                                for (Lesson *lessonToDeleteWithGroup in sortedLessons) {
                                    if (isInstructorOrStudent) {
                                        if (indexPath.section == 0) {
                                            if (visibleCells.count > indexPath.row) {
                                                id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                    Lesson *lessonToCheck = rowElement;
                                                    if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCells removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }else{
                                            if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                                id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                    Lesson *lessonToCheck = rowElement;
                                                    if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }
                                    }else{
                                        if (visibleCells.count > indexPath.row) {
                                            id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                Lesson *lessonToCheck = rowElement;
                                                if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }
                                    [self deleteCurrentLesson:lessonToDeleteWithGroup];
                                }
                            }
                        }else{
                            [visibleCells removeObjectAtIndex:indexPath.row];
                            [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                            DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                            deleteQuery.type = @"course";
                            deleteQuery.idToDelete = lessonGroup.groupID;
                            
                            if (lessonGroup.lessons.count>0) {
                                NSArray *sortedLessons = [self sortLessonByNumber:lessonGroup.lessons];
                                for (Lesson *lessonToDeleteWithGroup in sortedLessons) {
                                    if (isInstructorOrStudent) {
                                        if (indexPath.section == 0) {
                                            if (visibleCells.count > indexPath.row) {
                                                id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                    Lesson *lessonToCheck = rowElement;
                                                    if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCells removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }else{
                                            if (visibleCellsOnlyPrograms.count > indexPath.row) {
                                                id rowElement = [visibleCellsOnlyPrograms objectAtIndex:indexPath.row];
                                                if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                    Lesson *lessonToCheck = rowElement;
                                                    if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                        [visibleCellsOnlyPrograms removeObjectAtIndex:indexPath.row];
                                                        [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    }
                                                }
                                            }
                                        }
                                    }else{
                                        if (visibleCells.count > indexPath.row) {
                                            id rowElement = [visibleCells objectAtIndex:indexPath.row];
                                            if ([rowElement isMemberOfClass:[Lesson class]]) {
                                                Lesson *lessonToCheck = rowElement;
                                                if ([lessonToCheck.lessonGroup.groupID integerValue] == [lessonGroup.groupID integerValue]) {
                                                    [visibleCells removeObjectAtIndex:indexPath.row];
                                                    [programLessonTableView deleteRowsAtIndexPaths:@[indexPath]
                                                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                            }
                                        }
                                    }
                                    [self deleteCurrentLesson:lessonToDeleteWithGroup];
                                }
                            }
                        }
                        
                        [contextRecords deleteObject:lessonGroup];
                        [contextRecords save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                    }];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                        
                    }];
                    [alert addAction:cancel];
                    [alert addAction:ok];
                    [self presentViewController:alert animated:YES completion:nil];

                }
            }
        }
            break;
        default:
            break;
    }
}

- (void)deleteCurrentLesson:(Lesson *)lesson{
    if (lesson.lessonID && [lesson.lessonID integerValue] != 0) {
        DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
        deleteQuery.type = @"lesson";
        deleteQuery.idToDelete = lesson.lessonID;
        if (lesson.assignments.count > 0) {
            for (Assignment *assignment in lesson.assignments) {
                if (assignment.assignmentID && [assignment.assignmentID integerValue] != 0) {
                    DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                    deleteQueryForAssignment.type = @"assignment";
                    deleteQueryForAssignment.idToDelete = assignment.assignmentID;
                    [contextRecords deleteObject:assignment];
                }
            }
        }
        if (lesson.content.count>0) {
            for (Content *content in lesson.content) {
                [self saveContentsToDelete:content contextManage:contextRecords];
            }
        }
        
    }
    
    [contextRecords deleteObject:lesson];
}

- (void)saveContentsToDelete:(Content *)subContent contextManage:(NSManagedObjectContext *)context{
    if (subContent.contentID && [subContent.contentID integerValue] != 0) {
        DeleteQuery *deleteQueryForContent = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
        deleteQueryForContent.type = @"content";
        deleteQueryForContent.idToDelete = subContent.contentID;
    }
}
@end
