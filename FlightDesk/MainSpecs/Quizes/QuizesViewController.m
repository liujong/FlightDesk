//
//  QuizesViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "QuizesViewController.h"
#import "FirstViewController.h"
#import "SecondViewController.h"
#import "AddingQuizViewController.h"
#import "PersistentCoreDataStack.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "Student+CoreDataClass.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"

#import "StutdentCell.h"
#import "QuizCourseCell.h"
#import "StageCell.h"
#import "QuizCell.h"

@interface QuizesViewController () <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate>

@end

@implementation QuizesViewController
{
    UITableView *QuizTableView;
    bool privatePilot;
    
    // lesson groups & lessons
    NSMutableArray *visibleCells;
    
    NSInteger deepCount;
    
    BOOL hasStudentWithInstructorLevel;
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
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Program's Quizes";
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    // add the "Add Lesson" button
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 40, 40)];
    [addButton addTarget:self action:@selector(addQuizByInstructor) forControlEvents:UIControlEventTouchUpInside];
    [addButton setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    UIView *containsViewOfAdd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [containsViewOfAdd addSubview:addButton];
    UIBarButtonItem *addBtnItem = [[UIBarButtonItem alloc] initWithCustomView:containsViewOfAdd];
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:addBtnItem];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        addButton.hidden = NO;
    }else{
        addButton.hidden = YES;
    }
    
    //init
    deepCount = 0;
    hasStudentWithInstructorLevel = NO;
    
    QuizTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    //sectionHeaderButtons = [[NSDictionary alloc] init];
    privatePilot = false;
    QuizTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    QuizTableView.delegate = self;
    QuizTableView.dataSource = self;
    
    [QuizTableView registerNib:[UINib nibWithNibName:@"QuizCell" bundle:nil] forCellReuseIdentifier:@"QuizItem"];
    
    [self.view addSubview:QuizTableView];
    QuizTableView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *viewsDic = @{@"table": QuizTableView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[table]|" options:kNilOptions metrics:0 views:viewsDic]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[table]|" options:kNilOptions metrics:0 views:viewsDic]];
    NSLayoutConstraint *_tableWidth = [NSLayoutConstraint constraintWithItem:QuizTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.bounds.size.width];
    NSLayoutConstraint *_tableHeight = [NSLayoutConstraint constraintWithItem:QuizTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.bounds.size.height];
    [QuizTableView addConstraint:_tableWidth];
    [QuizTableView addConstraint:_tableHeight];
    
    privatePilot = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        QuizTableView.contentInset = UIEdgeInsetsMake(-34.0f, 0.0f, 0.0f, 0.0f);
    }else{
        QuizTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"QuizesViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    
    [self populateQuizes];
    [self setNavigationColorWithGradiant];
    
    [[AppDelegate sharedDelegate] startThreadToSyncData:4];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:4];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
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
- (void)deviceOrientationDidChange{
    [QuizTableView reloadData];
    [self setNavigationColorWithGradiant];
    [self superClassDeviceOrientationDidChange];
}
- (void)setNavigationColorWithGradiant{
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:233.0f/255.0f green:244.0f/255.0f blue:0.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:24.0f/255.0f green:140.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)addQuizByInstructor{
    if (hasStudentWithInstructorLevel) {
        AddingQuizViewController *addLesView = [[AddingQuizViewController alloc] initWithNibName:@"AddingQuizViewController" bundle:nil];
        addLesView.currentStudent = visibleCells[0];
        [self.navigationController pushViewController:addLesView animated:YES];
    }else{
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            AddingQuizViewController *addLesView = [[AddingQuizViewController alloc] initWithNibName:@"AddingQuizViewController" bundle:nil];
            [self.navigationController pushViewController:addLesView animated:YES];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"You do not have any Students enrolled to create Courses, Lessons or Quizzes for,  go to the \"Training\" function under Settings and add a student to your app." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}
- (BOOL)populateQuizes
{
    BOOL requireRepopulate = NO;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    // add students assigned to the current user (and their lesson groups)
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
    visibleCells = [NSMutableArray arrayWithCapacity:30];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve students!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid students found!");
    } else {
        FDLogDebug(@"%lu students found", (unsigned long)[objects count]);
        hasStudentWithInstructorLevel = YES;
        NSMutableArray *tempStudents = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedStudents = [tempStudents sortedArrayUsingDescriptors:sortDescriptors];
        // loop through expanded root groups and add sub-groups and lessons
        for (Student *student in sortedStudents) {
            [visibleCells addObject:student];
            if ([student.expanded boolValue] == YES) {
                [self expandStudent:student withCells:visibleCells];
            }
        }
        
        requireRepopulate = YES;
    }
    if (visibleCells.count == 0) {
        // add lesson groups assigned to the current user
        entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        // load the remaining lesson groups
        request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        // only grab root lesson groups (where there is no parent)
        NSPredicate *predicate;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL"];
        }else {
            predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL AND student == NULL AND isShown = YES"];
        }
        [request setPredicate:predicate];
        objects = [context executeFetchRequest:request error:&error];
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
                [visibleCells addObject:rootGroup];
                if ([rootGroup.expanded boolValue] == YES) {
                    [self expandGroup:rootGroup withCells:visibleCells];
                }
            }
            requireRepopulate = YES;
        }
    }
    
    [QuizTableView reloadData];
    return requireRepopulate;
}

- (void)reloadData
{
    [QuizTableView reloadData];
}

- (void)expandGroup:(LessonGroup*)group withCells:(NSMutableArray*)cells
{
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    // only grab root lesson groups (where there is no parent)
    NSPredicate *predicate;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@", group.groupID];
    }else{
        predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@ AND studentUserID == %@", group.groupID, group.studentUserID];
    }
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Quizes!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Quiz groups found!");
    } else {
        FDLogDebug(@"%lu Quiz groups found", (unsigned long)[objects count]);
        NSMutableArray *tempQuizes = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"quizNumber" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedQuizes = [tempQuizes sortedArrayUsingDescriptors:sortDescriptors];
        
        for (Quiz *rootQuiz in sortedQuizes) {
            [visibleCells addObject:rootQuiz];
        }
    }
}

- (void)expandStudent:(Student*)student withCells:(NSMutableArray*)cells
{
    // loop through sub-groups
    for (LessonGroup *subGroup in student.subGroups) {
        [cells addObject:subGroup];
        // expand the sub-group if needed
        if ([subGroup.expanded boolValue] == YES) {
            [self expandGroup:subGroup withCells:cells];
        }
    }
}


-(NSArray*) indexPathsForSection:(int)section withNumberOfRows:(int)numberOfRows {
    NSMutableArray* indexPaths = [NSMutableArray new];
    for (int i = 0; i < numberOfRows; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [visibleCells count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id rowElement = [visibleCells objectAtIndex:indexPath.row];
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
        static NSString *simpleTableIdentifier = @"QuizItem";
        QuizCell *quizCell = (QuizCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (quizCell == nil) {
            quizCell = [QuizCell sharedCell];
        }
        quizCell.quizTitle.text = lesson.name;
        return quizCell;
    } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        
        LessonGroup *lessonGroup = rowElement;
            // row is a lesson group
            static NSString *simpleTableIdentifier = @"QuizCourseItem";
            QuizCourseCell *courseCell = (QuizCourseCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
            if (courseCell == nil) {
                courseCell = [QuizCourseCell sharedCell];
            }
            courseCell.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
            
            UIImage *sectionImage = nil;
            
            if ([lessonGroup.expanded boolValue] == YES) {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowUp.png"];
            } else {
                sectionImage = [UIImage imageNamed:@"UIButtonBarArrowDown.png"];
            }
            [courseCell.expandableImageView setImage:sectionImage];
            courseCell.corseTitle.text = lessonGroup.name;
        
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        // only grab root lesson groups (where there is no parent)
        NSPredicate *predicate;
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@", lessonGroup.groupID];
        }else{
            predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@ AND studentUserID == %@", lessonGroup.groupID, lessonGroup.studentUserID];
        }
        [request setPredicate:predicate];
        NSError *error;
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve Quizes!");
            courseCell.quizCountLbl.text = @"0 Quiz";
        } else if (objects.count == 1 || objects.count == 0) {
            courseCell.quizCountLbl.text = [NSString stringWithFormat:@"%lu Quiz", objects.count];
        } else {
            courseCell.quizCountLbl.text = [NSString stringWithFormat:@"%lu Quizes", objects.count];
        }
            
            return courseCell;
    }else if ([rowElement isMemberOfClass:[Quiz class]]){
        Quiz *quizGroup = rowElement;
        
        static NSString *cellIdentifier = @"QuizItem";
        QuizCell *cell = (QuizCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                                             forIndexPath:indexPath];
//        static NSString *simpleTableIdentifier = @"QuizItem";
//        QuizCell *cell = (QuizCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
//        if (cell == nil) {
//            cell = [QuizCell sharedCell];
//        }
        
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            cell.delegate = self;
            cell.leftUtilityButtons = [self leftButtons];
            cell.rightUtilityButtons = [self rightButtons];
        }
        cell.backgroundColor = [UIColor whiteColor];
        
        id rowElementToMarkNumber = [visibleCells objectAtIndex:indexPath.row-1];
        if ([rowElementToMarkNumber isMemberOfClass:[LessonGroup class]]) {
            deepCount = indexPath.row-1;
        }
        
        cell.quizTitle.text = [NSString stringWithFormat:@"Quiz %ld - %@",[quizGroup.quizNumber integerValue], quizGroup.name];
        if ([quizGroup.quizTaken integerValue] == 0) {
            cell.lblQuizStatus.text = @"Pending";
        }else{
            if ([quizGroup.gotScore integerValue] > [quizGroup.passingScore integerValue]) {
                cell.lblQuizStatus.text = @"Completed";
            }else{
                cell.lblQuizStatus.text = @"Failed";
            }
        }
        
        cell.lblQuizTaken.text = [NSString stringWithFormat:@"%ld", [quizGroup.quizTaken integerValue]];
        if ([quizGroup.gotScore integerValue] == 0) {
            cell.lblQuizScore.text = @"-";
        }else{
            cell.lblQuizScore.text = [NSString stringWithFormat:@"%ld", [quizGroup.gotScore integerValue]];
        }
        
        if ([quizGroup.gotScore integerValue] < 70) {
            [cell.lblQuizScore setTextColor:[UIColor redColor]];
        }else if ([quizGroup.gotScore integerValue] < 80) {
            [cell.lblQuizScore setTextColor:[UIColor colorWithRed:1.0f green:183.0f/255.0f blue:50.0f/255.0f alpha:1.0f]];
        }else if ([quizGroup.gotScore integerValue] < 90) {
            [cell.lblQuizScore setTextColor:[UIColor blueColor]];
        }else if ([quizGroup.gotScore integerValue] <= 100) {
            [cell.lblQuizScore setTextColor:[UIColor greenColor]];
        }
        
        return cell;
    }
    
    return cell;
}

-(void)collapseLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row {
    FDLogDebug(@"collapsing lesson group %@: cells %lu", lessonGroup.name, (unsigned long)[visibleCells count]);
    NSMutableArray *deleteIndexPaths = [NSMutableArray array];
    int i;
    // loop through all subsequent visible cells until end of array or new parent lesson group
    for (i = row + 1; i < [visibleCells count]; ++i) {
        id rowElement = [visibleCells objectAtIndex:i];
        // determine if this element is a lesson group or a lesson
        if ([rowElement isMemberOfClass:[Quiz class]]) {
            // just remove the row
            [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
            // check if this is a sub-lesson group of this lesson group
            LessonGroup *subLessonGroup = rowElement;
            if (subLessonGroup.parentGroup == lessonGroup) {
                if ([subLessonGroup.expanded boolValue] == YES) {
                    subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                }
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
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
        [QuizTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    lessonGroup.expanded = [NSNumber numberWithBool:NO];
}

-(void)expandLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row {
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Quiz" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    // only grab root lesson groups (where there is no parent)
    NSPredicate *predicate;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@", lessonGroup.groupID];
    }else{
        predicate = [NSPredicate predicateWithFormat:@"courseGroupID == %@ AND studentUserID == %@", lessonGroup.groupID, lessonGroup.studentUserID];
    }
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Quizes!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Quiz groups found!");
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"No Quizes created for this course" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSLog(@"you pressed Yes, please button");
            }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"No tests created for this program yet. Your instructor needs to add a test to this course" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSLog(@"you pressed Yes, please button");
            }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else {
        FDLogDebug(@"%lu Quiz groups found", (unsigned long)[objects count]);
        int rowsExpanded = 0;
        NSMutableArray *insertIndexPaths = [NSMutableArray array];
        NSMutableArray *tempQuizes = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"quizNumber" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedQuizes = [tempQuizes sortedArrayUsingDescriptors:sortDescriptors];
        
        for (Quiz *rootQuiz in sortedQuizes) {
            ++rowsExpanded;
            [visibleCells insertObject:rootQuiz atIndex:row + rowsExpanded];
            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:0]];
        }
        lessonGroup.expanded = [NSNumber numberWithBool:YES];
        if ([insertIndexPaths count] > 0) {
            [QuizTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

-(void)collapseStudent:(Student*)student atRow:(int)row {
    FDLogDebug(@"collapsing student %@ %@: cells %lu", student.firstName, student.lastName, (unsigned long)[visibleCells count]);
    NSMutableArray *deleteIndexPaths = [NSMutableArray array];
    int i;
    // loop through all subsequent visible cells until end of array or new parent lesson group
    for (i = row + 1; i < [visibleCells count]; ++i) {
        id rowElement = [visibleCells objectAtIndex:i];
        // determine if this element is a lesson group or a lesson
        if ([rowElement isMemberOfClass:[Quiz class]]) {
            // just remove the row
            [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
            // check if this is a sub-lesson group of this lesson group
            LessonGroup *subLessonGroup = rowElement;
            if (subLessonGroup.student == student) {
                if ([subLessonGroup.expanded boolValue] == YES) {
                    subLessonGroup.expanded = [NSNumber numberWithBool:NO];
                }
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
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
        [QuizTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    student.expanded = [NSNumber numberWithBool:NO];
}

-(void)expandStudent:(Student*)student atRow:(int)row {
    int rowsExpanded = 0;
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    // check if sub-sections need to be expanded, expand recursively
    if (student.subGroups != NULL && [student.subGroups count] > 0) {
        // loop through each child group and expand it if it was already expanded
        for (LessonGroup *subLessonGroup in student.subGroups) {
            ++rowsExpanded;
            [visibleCells insertObject:subLessonGroup atIndex:row + rowsExpanded];
            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:0]];
        }
    }
    student.expanded = [NSNumber numberWithBool:YES];
    if ([insertIndexPaths count] > 0) {
        [QuizTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - Table view delegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FDLogDebug(@"will select row %ld", (long)indexPath.row);
    id rowElement = [visibleCells objectAtIndex:indexPath.row];
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
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            [self collapseStudent:student atRow:(int)indexPath.row];
            [tableView endUpdates];
            [CATransaction commit];
        } else {
            // expand lesson group
            FDLogDebug(@"Student %@ %@ expanding", student.firstName, student.lastName);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            [self expandStudent:student atRow:(int)indexPath.row];
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
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            [self collapseLessonGroup:lessonGroup atRow:(int)indexPath.row];
            [tableView endUpdates];
            [CATransaction commit];
        } else {
            // expand lesson group
            FDLogDebug(@"LessonGroup %@ expanding", lessonGroup.name);
            [CATransaction begin];
            [tableView beginUpdates];
            [CATransaction setCompletionBlock:^{
                // update the lesson group image
                [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            [self expandLessonGroup:lessonGroup atRow:(int)indexPath.row];
            [tableView endUpdates];
            [CATransaction commit];
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id rowElement = [visibleCells objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if ([rowElement isMemberOfClass:[Lesson class]]) {
        FirstViewController *quizViewController = [[FirstViewController alloc] init];
        //[self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController pushViewController:quizViewController animated:YES];
    } else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lessonGroup = rowElement;
        if (lessonGroup.lessons.count == 0 && lessonGroup.subGroups.count) {
            
        }
    } else if ([rowElement isMemberOfClass:[Quiz class]]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        Quiz *quiz = rowElement;
        if (quiz.questions.count == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"This quiz has no questions. Admin needs to add one and more question at least" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){ }];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            if ([quiz.quizTaken integerValue] == 0) {
                FirstViewController *quizViewController = [[FirstViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                
                for (id itemToCheckStudent in visibleCells) {
                    if ([itemToCheckStudent isMemberOfClass:[Student class]]){
                        Student *currentStudent = itemToCheckStudent;
                        for (LessonGroup *lessonGroup in currentStudent.subGroups) {
                            if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                                quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                            }
                        }
                    }
                }
                
                //[self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController pushViewController:quizViewController animated:YES];
            }else{
                SecondViewController *quizViewController = [[SecondViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                //[self.navigationController setNavigationBarHidden:YES animated:YES];
                for (id itemToCheckStudent in visibleCells) {
                    if ([itemToCheckStudent isMemberOfClass:[Student class]]){
                        Student *currentStudent = itemToCheckStudent;
                        for (LessonGroup *lessonGroup in currentStudent.subGroups) {
                            if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                                quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                            }
                        }
                    }
                }
                [self.navigationController pushViewController:quizViewController animated:YES];
            }
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]){
            if (quiz.gotScore && [quiz.quizTaken integerValue] > 0) {
                SecondViewController *quizViewController = [[SecondViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                for (id itemToCheckLessonGroup in visibleCells) {
                    if ([itemToCheckLessonGroup isMemberOfClass:[LessonGroup class]]) {
                        LessonGroup *lessonGroup = itemToCheckLessonGroup;
                        
                        if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                            quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                        }
                    }
                }
                [self.navigationController pushViewController:quizViewController animated:YES];
                
            }else{
                FirstViewController *quizViewController = [[FirstViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                for (id itemToCheckLessonGroup in visibleCells) {
                    if ([itemToCheckLessonGroup isMemberOfClass:[LessonGroup class]]) {
                        LessonGroup *lessonGroup = itemToCheckLessonGroup;
                        
                        if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                            quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                        }
                    }
                }
                //[self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController pushViewController:quizViewController animated:YES];
            }
        }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            if ([quiz.quizTaken integerValue] == 0) {
                FirstViewController *quizViewController = [[FirstViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                
                for (id itemToCheckLessonGroup in visibleCells) {
                    if ([itemToCheckLessonGroup isMemberOfClass:[LessonGroup class]]){
                        LessonGroup *lessonGroup = itemToCheckLessonGroup;
                        if (lessonGroup.parentGroup ==  nil) {
                            if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                                quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                            }
                        }
                    }
                }
                
                //[self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController pushViewController:quizViewController animated:YES];
            }else{
                SecondViewController *quizViewController = [[SecondViewController alloc] init];
                quizViewController.currentQuiz = quiz;
                //[self.navigationController setNavigationBarHidden:YES animated:YES];
                for (id itemToCheckLessonGroup in visibleCells) {
                    if ([itemToCheckLessonGroup isMemberOfClass:[LessonGroup class]]){
                        LessonGroup *lessonGroup = itemToCheckLessonGroup;
                        if (lessonGroup.parentGroup ==  nil) {
                            if ([lessonGroup.groupID integerValue] == [quiz.courseGroupID integerValue]) {
                                quizViewController.quizDes = [NSString stringWithFormat:@"%@ (%@)", lessonGroup.name, quiz.name];
                            }
                        }
                    }
                }
                [self.navigationController pushViewController:quizViewController animated:YES];
            }
        }
        
    }
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
            NSIndexPath *indexPath = [QuizTableView indexPathForCell:cell];
            id rowElement = [visibleCells objectAtIndex:indexPath.row];
            if ([rowElement isMemberOfClass:[Quiz class]]) {
                AddingQuizViewController *addLesView = [[AddingQuizViewController alloc] initWithNibName:@"AddingQuizViewController" bundle:nil];
                Quiz *currentQuiz = rowElement;
                addLesView.currentQuiz = currentQuiz;
                
                for (id itemOfCell in visibleCells) {
                    if ([itemOfCell isMemberOfClass:[Student class]]) {
                        Student *studentToCheckId = itemOfCell;
                        if ([studentToCheckId.userID integerValue] == [currentQuiz.studentUserID integerValue]) {
                            addLesView.currentStudent = studentToCheckId;
                        }
                    }
                }
                addLesView.isEditOldQuiz = YES;
                [self.navigationController pushViewController:addLesView animated:YES];
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
            NSIndexPath *indexPath = [QuizTableView indexPathForCell:cell];
            id rowElement = [visibleCells objectAtIndex:indexPath.row];
            if ([rowElement isMemberOfClass:[Quiz class]]) {
                Quiz *quiz = rowElement;
                NSString *msg = [NSString stringWithFormat:@"Do you want to delete %@", quiz.name];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    //NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                    
                    [visibleCells removeObjectAtIndex:indexPath.row];
                    [QuizTableView deleteRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    NSError *error = nil;
                    
                    if (quiz.quizId && [quiz.quizId integerValue] != 0) {
                        DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                        deleteQuery.type = @"quiz";
                        deleteQuery.idToDelete = quiz.recordId;
                        [context save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                        if (quiz.questions.count > 0) {
                            for (Question *question in quiz.questions) {
                                if (question.questionId && [question.questionId integerValue] != 0) {
                                    DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                                    deleteQueryForAssignment.type = @"question";
                                    deleteQueryForAssignment.idToDelete = question.recodeId;
                                    [context save:&error];
                                    if (error) {
                                        NSLog(@"Error when saving managed object context : %@", error);
                                    }
                                }
                            }
                        }
                    }
                    for (Question *question in quiz.questions) {
                        [context deleteObject:question];
                    }
                    [context deleteObject:quiz];
                    [context save:&error];
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
            break;
        default:
            break;
    }
}

@end
