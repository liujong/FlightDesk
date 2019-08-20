//
//  TrainingViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "TrainingViewController.h"
#import "StudentCell.h"
#import "ProgramCell.h"
#import "ManagedObjectCloner.h"

@interface TrainingViewController ()<UITableViewDelegate, UITableViewDataSource, StudentCellDelegate, SWTableViewCellDelegate>{
    NSMutableArray *arrayProgramsAndStudents;
    NSDictionary *currentLessonGroupWithStudents;
}

@end

@implementation TrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 960.0f;
    [scrView setContentSize:scrSize];
    
    studentAddView.hidden = YES;
    arrayProgramsAndStudents = [[NSMutableArray alloc] init];
    
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getPrograms) name:NOTIFICATION_FLIGHTDESK_FIND_INSTRUCTOR object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_FLIGHTDESK_FIND_INSTRUCTOR object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)deviceOrientationDidChange{
    [scrView setContentSize:CGSizeMake(scrView.frame.size.width, 960.0f)];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"TrainingviewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [AppDelegate sharedDelegate].train_VC = self;
    [self getPrograms];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [AppDelegate sharedDelegate].train_VC = nil;
}
- (void)resizeViewWithArray{
    
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 400.0f + arrayProgramsAndStudents.count * 38.0f;
    [scrView setContentSize:scrSize];
    
    CGRect tableRect = programTableView.frame;
    tableRect.size.height = arrayProgramsAndStudents.count * 38.0f + 50.0f;// + 70.0f;
    programTableView.frame = tableRect;
//    [programTableView setFrame:tableRect];
}
- (void)getPrograms{
    [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
    [arrayProgramsAndStudents removeAllObjects];
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
    [groupRequest setPredicate:predicate];
    
    NSSortDescriptor *groupSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [groupRequest setSortDescriptors:@[groupSortDescriptor]];
    NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
    if (groupArray == nil) {
        FDLogError(@"Unable to retrieve lesson group!");
    } else if (groupArray.count == 0) {
        FDLogDebug(@"No groups stored!");
    } else {
        for (LessonGroup *group in groupArray) {
            if (group.parentGroup == nil) {
                BOOL isExist = NO;
                for (int i = 0; i < arrayProgramsAndStudents.count; i++) {
                    id oneElement = [arrayProgramsAndStudents objectAtIndex:i];
                    if ([oneElement isMemberOfClass:[LessonGroup class]]) {
                        LessonGroup *lesGroupToCheck = oneElement;
                        if ([group.name.lowercaseString isEqualToString:lesGroupToCheck.name.lowercaseString]) {
                            isExist = YES;
                            break;
                        }
                    }
                }
                if (!isExist) {
                    [arrayProgramsAndStudents addObject:group];
                    
                    if ([group.expanded boolValue] == YES){
                        
                        NSMutableArray *studentIDs = [[NSMutableArray alloc] init];
                        for (LessonGroup *lesGroupToAddStudent in groupArray) {
                            if ([group.name.lowercaseString isEqualToString:lesGroupToAddStudent.name.lowercaseString] && lesGroupToAddStudent.student != nil) {
                                [arrayProgramsAndStudents addObject:lesGroupToAddStudent.student];
                                [studentIDs addObject:lesGroupToAddStudent.student.studentEmail];
                            }
                        }
                        NSMutableDictionary *dictWithLessongroup = [[NSMutableDictionary alloc] init];
                        [dictWithLessongroup setObject:group forKey:@"lessongroup"];
                        [dictWithLessongroup setObject:studentIDs forKey:@"studentIDs"];
                        [arrayProgramsAndStudents addObject:dictWithLessongroup];
                    }
                    
                    
                }
                
            }
        }
    }
    [self resizeViewWithArray];
    [programTableView reloadData];
}
-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [arrayProgramsAndStudents count];
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    if (tableView == programTableView) {
        [view addSubview:footerViewOfAddProgram];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (tableView == programTableView) {
        return 50.0f;
    }
    
    return 0.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 38.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id rowElement = [arrayProgramsAndStudents objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[Student class]]) {
        static NSString *simpleTableIdentifier = @"StudentItem";
        StudentCell *cell = (StudentCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [StudentCell sharedCell];
        }
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            cell.rightUtilityButtons = [self rightButtons];
            cell.delegate = self;
        }
        
        Student *student = rowElement;
        cell.txtStudentName.text = [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
        return cell;
    }else if([rowElement isMemberOfClass:[LessonGroup class]]) {
        static NSString *simpleTableIdentifier = @"ProgramItem";
        ProgramCell *cell = (ProgramCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ProgramCell sharedCell];
        }
        LessonGroup *lessonGroup = rowElement;
        cell.lblProgramTitle.text = lessonGroup.name;
        
        return cell;
    }else{
        static NSString *simpleTableIdentifier = @"StudentItem";
        StudentCell *cell = (StudentCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [StudentCell sharedCell];
        }
        cell.delegateWithStudent = self;
        cell.txtStudentName.text = @"";
        return cell;
    }
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}
#pragma mark - Table view delegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FDLogDebug(@"will select row %ld", (long)indexPath.row);
    id rowElement = [arrayProgramsAndStudents objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[Student class]]) {
        //Student *student = rowElement;
    }else if([rowElement isMemberOfClass:[LessonGroup class]]) {
        //LessonGroup *lessonGroup = rowElement;
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
        }else {
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
    }else{
    }
    return indexPath;
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Remove"];
    
    return rightUtilityButtons;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *indexPath = [programTableView indexPathForCell:cell];
            id rowElement = [arrayProgramsAndStudents objectAtIndex:indexPath.row];
            if ([rowElement isMemberOfClass:[Student class]]) {
                Student *student = rowElement;
                LessonGroup *lesGroupToContainStudent = nil;
                NSInteger index = indexPath.row - 1;
                int lessonGroupIndex = 0;
                for (int i = 0; i < arrayProgramsAndStudents.count; i ++) {
                    id oneElementToFindLessonGroup = [arrayProgramsAndStudents objectAtIndex:index];
                    if ([oneElementToFindLessonGroup isMemberOfClass:[Student class]]) {
                        index = index - 1;
                        if (index < 0) {
                            break;
                        }
                    }else if ([oneElementToFindLessonGroup isMemberOfClass:[LessonGroup class]]) {
                        lessonGroupIndex = (int)index;
                        lesGroupToContainStudent = oneElementToFindLessonGroup;
                        break;
                    }
                }
                
                NSInteger studentCountOfCurrentLessonGroup = 0;
                for (int i = lessonGroupIndex + 1; i < [arrayProgramsAndStudents count]; ++i) {
                    id rowElement = [arrayProgramsAndStudents objectAtIndex:i];
                    // determine if this element is a lesson group or a lesson
                    if ([rowElement isMemberOfClass:[Student class]]) {
                        // just remove the row
                        studentCountOfCurrentLessonGroup ++;
                    }else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
                        break;
                    }
                }
                
                
                
                
                NSNumber *programID = nil;
                for (LessonGroup *lesGroup in student.subGroups) {
                    if ([lesGroup.name.lowercaseString isEqualToString:lesGroupToContainStudent.name.lowercaseString]) {
                        programID = lesGroup.groupID;
                    }
                }
                
                NSString *msg = [NSString stringWithFormat:@"Do you want to remove %@ %@ from %@?", student.firstName, student.lastName, lesGroupToContainStudent.name];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:msg preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    
                    [arrayProgramsAndStudents removeObjectAtIndex:indexPath.row];
                    [programTableView deleteRowsAtIndexPaths:@[indexPath]
                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    NSError *error = nil;
//                    if (studentCountOfCurrentLessonGroup > 1) { //studentCountOfCurrentLessonGroup=1 means current student to delete
                    
                        InsAndStdAndProgamQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"InsAndStdAndProgamQuery" inManagedObjectContext:context];
                        deleteQuery.queryType = @"removeStudent";
                        deleteQuery.instructorID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                        deleteQuery.studentID = student.userID;
                        deleteQuery.programID = programID;
                        [context save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                        
                        if (student.subGroups.count > 0) {
                            for (LessonGroup *lesGroupToDelete in student.subGroups) {
                                if ([lesGroupToDelete.name.lowercaseString isEqualToString:lesGroupToContainStudent.name.lowercaseString]) {
                                    if (lesGroupToDelete.subGroups.count > 0) {
                                        for (LessonGroup *subLesGroup in lesGroupToDelete.subGroups) {
                                            if (subLesGroup.lessons.count>0) {
                                                for (Lesson *lesToDelete in subLesGroup.lessons) {
                                                    [context deleteObject:lesToDelete];
                                                }
                                            }
                                            
                                            [context deleteObject:subLesGroup];
                                        }
                                    }
                                    if (lesGroupToDelete.lessons.count> 0) {
                                        for (Lesson *lesPToDelete in lesGroupToDelete.lessons) {
                                            [context deleteObject:lesPToDelete];
                                        }
                                    }
                                    [context deleteObject:lesGroupToDelete];
                                    break;
                                }
                            }
                        }
                        
                        if (student.subGroups.count == 0) {
                            [context deleteObject:student];
                        }
//                    }else{
//                        InsAndStdAndProgamQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"InsAndStdAndProgamQuery" inManagedObjectContext:context];
//                        deleteQuery.queryType = @"removeStudentWithOut";
//                        deleteQuery.instructorID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
//                        deleteQuery.studentID = student.userID;
//                        deleteQuery.programID = programID;
//                        [context save:&error];
//                        if (error) {
//                            NSLog(@"Error when saving managed object context : %@", error);
//                        }
//
//                        if (student.subGroups.count > 0) {
//                            for (LessonGroup *lesGroupToDelete in student.subGroups) {
//                                if ([lesGroupToDelete.name.lowercaseString isEqualToString:lesGroupToContainStudent.name.lowercaseString]) {
//
//                                    LessonGroup *lessonGroupToCreateParent = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:context];
//                                    lessonGroupToCreateParent.groupID = lesGroupToDelete.groupID;
//                                    lessonGroupToCreateParent.indentation =[NSNumber numberWithInteger:[lesGroupToDelete.indentation integerValue]-2];
//                                    lessonGroupToCreateParent.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
//                                    lessonGroupToCreateParent.lastUpdate = @(0);
//                                    lessonGroupToCreateParent.name = lesGroupToDelete.name;
//                                    lessonGroupToCreateParent.expanded = @(0);
//
//                                    if (lesGroupToDelete.subGroups.count > 0) {
//                                        for (LessonGroup *subLesGroup in lesGroupToDelete.subGroups) {
//                                            LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:context];
//                                            lessonGroupToCreate.groupID = subLesGroup.groupID;
//                                            lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[subLesGroup.indentation integerValue]-2];
//                                            lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
//                                            lessonGroupToCreate.lastUpdate = @(0);
//                                            lessonGroupToCreate.name = subLesGroup.name;
//                                            lessonGroupToCreate.expanded = @(0);
//
//
//                                            if (subLesGroup.lessons.count>0) {
//                                                for (Lesson *lesToDelete in subLesGroup.lessons) {
//                                                    Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:context];
//                                                    lesson.title = lesToDelete.title;
//                                                    lesson.studentUserID = @0;
//                                                    lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue]-2];
//                                                    lesson.flightCompletionStds = lesToDelete.flightCompletionStds;
//                                                    lesson.flightDescription = lesToDelete.flightDescription;
//                                                    lesson.flightObjective = lesToDelete.flightObjective;
//                                                    lesson.groundCompletionStds = lesToDelete.groundCompletionStds;
//                                                    lesson.groundDescription = lesToDelete.groundDescription;
//                                                    lesson.groundObjective = lesToDelete.groundObjective;
//                                                    lesson.minDual = lesToDelete.minDual;
//                                                    lesson.minGround = lesToDelete.minGround;
//                                                    lesson.minInstrument = lesToDelete.minInstrument;
//                                                    lesson.minSolo = lesToDelete.minSolo;
//                                                    lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
//                                                    lesson.lastUpdate = @(0);
//                                                    lesson.lessonNumber = lesToDelete.lessonNumber;
//                                                    lesson.lessonID = lesToDelete.lessonID;
//                                                    lesson.lesson_local_id = lesToDelete.lesson_local_id;
//                                                    lesson.groupIdToSave = lesToDelete.groupIdToSave;
//                                                    for (Assignment *assignmentToCopy in lesToDelete.assignments) {
//                                                        Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:context];
//                                                        assignment.chapters = assignmentToCopy.chapters;
//                                                        assignment.referenceID = assignmentToCopy.referenceID;
//                                                        assignment.title = assignmentToCopy.title;
//                                                        assignment.assignmentID = assignmentToCopy.assignmentID;
//                                                        assignment.groundOrFlight = assignmentToCopy.groundOrFlight;
//                                                        assignment.studentUserID = @0;
//                                                        assignment.assignment_local_id = assignmentToCopy.assignment_local_id;
//                                                        [lesson addAssignmentsObject:assignment];
//                                                    }
//
//                                                    for (Content *contentToCopy in lesToDelete.content) {
//                                                        //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
//                                                        Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:context];
//                                                        content.name = contentToCopy.name;
//                                                        content.hasCheck = contentToCopy.hasCheck;
//                                                        content.hasRemarks = contentToCopy.hasRemarks;
//                                                        content.contentID = contentToCopy.contentID;
//                                                        content.groundOrFlight = contentToCopy.groundOrFlight;
//                                                        content.orderNumber = contentToCopy.orderNumber;
//                                                        content.studentUserID = @0;
//                                                        content.content_local_id = contentToCopy.content_local_id;
//                                                        content.depth = contentToCopy.depth;
//
//                                                        [lesson addContentObject:content];
//                                                    }
//
//                                                    [lessonGroupToCreate addLessonsObject:lesson];
//                                                }
//                                            }
//
//                                            [lessonGroupToCreateParent addSubGroupsObject:lessonGroupToCreate];
//                                        }
//                                    }
//                                    if (lesGroupToDelete.lessons.count> 0) {
//                                        for (Lesson *lesPToDelete in lesGroupToDelete.lessons) {
//                                            Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:context];
//                                            lesson.title = lesPToDelete.title;
//                                            lesson.studentUserID = @0;
//                                            lesson.flightCompletionStds = lesPToDelete.flightCompletionStds;
//                                            lesson.flightDescription = lesPToDelete.flightDescription;
//                                            lesson.flightObjective = lesPToDelete.flightObjective;
//                                            lesson.groundCompletionStds = lesPToDelete.groundCompletionStds;
//                                            lesson.groundDescription = lesPToDelete.groundDescription;
//                                            lesson.groundObjective = lesPToDelete.groundObjective;
//                                            lesson.minDual = lesPToDelete.minDual;
//                                            lesson.minGround = lesPToDelete.minGround;
//                                            lesson.minInstrument = lesPToDelete.minInstrument;
//                                            lesson.minSolo = lesPToDelete.minSolo;
//                                            lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
//                                            lesson.lastUpdate = @(0);
//                                            lesson.lessonNumber = lesPToDelete.lessonNumber;
//                                            lesson.lessonID = lesPToDelete.lessonID;
//                                            lesson.lesson_local_id = lesPToDelete.lesson_local_id;
//                                            lesson.groupIdToSave = lesPToDelete.groupIdToSave;
//                                            lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreateParent.indentation integerValue]-2];
//                                            for (Assignment *assignmentToCopy in lesPToDelete.assignments) {
//                                                Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:context];
//                                                assignment.chapters = assignmentToCopy.chapters;
//                                                assignment.referenceID = assignmentToCopy.referenceID;
//                                                assignment.title = assignmentToCopy.title;
//                                                assignment.assignmentID = assignmentToCopy.assignmentID;
//                                                assignment.groundOrFlight = assignmentToCopy.groundOrFlight;
//                                                assignment.studentUserID = @0;
//                                                assignment.assignment_local_id = assignmentToCopy.assignment_local_id;
//                                                [lesson addAssignmentsObject:assignment];
//                                            }
//
//                                            for (Content *contentToCopy in lesPToDelete.content) {
//                                                //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
//                                                Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:context];
//                                                content.name = contentToCopy.name;
//                                                content.hasCheck = contentToCopy.hasCheck;
//                                                content.hasRemarks = contentToCopy.hasRemarks;
//                                                content.contentID = contentToCopy.contentID;
//                                                content.groundOrFlight = contentToCopy.groundOrFlight;
//                                                content.orderNumber = contentToCopy.orderNumber;
//                                                content.studentUserID = @0;
//                                                content.content_local_id = contentToCopy.content_local_id;
//                                                content.depth = contentToCopy.depth;
//
//                                                [lesson addContentObject:content];
//                                            }
//
//                                            [lessonGroupToCreateParent addLessonsObject:lesson];
//                                        }
//                                    }
//
//
//                                    [student removeSubGroupsObject:lesGroupToDelete];
//                                    break;
//                                }
//                            }
//                        }
//
//                        if (student.subGroups.count == 0) {
//                            [context deleteObject:student];
//                        }
//                    }
                    
                    
                    [context save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                    
//                    [self getPrograms];
                    [self resizeViewWithArray];
                    [programTableView reloadData];
                    
//                    [AppDelegate sharedDelegate].isStartPerformSyncCheck = NO;
//                    [[[AppDelegate sharedDelegate] syncManager] performSyncCheck];
                    studentAddView.hidden = YES;
                    
//                    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
//                    {
//                        if ([[_responseObject objectForKey:@"success"] boolValue]) {
//                            [AppDelegate sharedDelegate].isStartPerformSyncCheck = NO;
//                            [[[AppDelegate sharedDelegate] syncManager] performSyncCheck];
//                            studentAddView.hidden = YES;
//                        }else if ( ![[_responseObject objectForKey:@"success"] boolValue]){
//                            [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
//                            [self  showAlert: [NSString stringWithFormat:@"Can't find %@, Please try with other Student.", txtStudentId.text] :@"FlightDesk"];
//                        }
//                    };
//                    
//                    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
//                    {
//                        [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
//                        [ self  showAlert: @"Internet connection error!" :@"Failed!"] ;
//                        
//                    } ;
//                    [[Communication sharedManager] ActionFlightDeskRemoveStudent:@"remove_student_from_current_program" userId:[AppDelegate sharedDelegate].userId studentID:student.userID programID:programID successed:successed failure:failure];
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                    
                }];
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
            }else{
            }
            
            
        }
            break;
        default:
            break;
    }
}
- (IBAction)onAddPrograms:(id)sender {
}

- (IBAction)onCancelAddView:(id)sender {
    studentAddView.hidden = YES;
    [self.view endEditing:YES];
}

- (IBAction)onFindStudent:(id)sender {
    studentAddView.hidden = YES;
    if (currentLessonGroupWithStudents) {
        NSArray *studentsIds = [currentLessonGroupWithStudents objectForKey:@"studentIDs"];
        for (NSString *stdEmail in studentsIds) {
            if ([stdEmail.lowercaseString isEqualToString:txtStudentId.text.lowercaseString]) {
                [ self  showAlert: @"You already work with this Student." :@"FlightDesk"] ;
                return;
            }
        }
    }
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Error" message:@"You must be connected to the internet." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSLog(@"you pressed Yes, please button");
        }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
        
    }
    
    [self.view endEditing:YES];
    LessonGroup *lesGroup = [currentLessonGroupWithStudents objectForKey:@"lessongroup"];
    [AppDelegate sharedDelegate].programName = lesGroup.name;
    [AppDelegate sharedDelegate].trainingHud = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
    [AppDelegate sharedDelegate].trainingHud.label.text = @"Finding student…";
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            [AppDelegate sharedDelegate].trainingHud.label.text = @"User Found";
            
            [[AppDelegate sharedDelegate] stopThreadToSyncData:[AppDelegate sharedDelegate].currentSyncingIndex];
            [[AppDelegate sharedDelegate] startThreadToSyncData:1];
            studentAddView.hidden = YES;
            [self resizeViewWithArray];
            [programTableView reloadData];
        }else if ( ![[_responseObject objectForKey:@"success"] boolValue]){
            [[AppDelegate sharedDelegate].trainingHud hideAnimated:YES];
            [self  showAlert: [_responseObject objectForKey:@"error_str"] :@"FlightDesk"];
        }
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [[AppDelegate sharedDelegate].trainingHud hideAnimated:YES];
        [ self  showAlert: @"Internet connection error!" :@"Failed!"] ;
        
    } ;
    [[Communication sharedManager] ActionFlightDeskFindStudent:@"find_student" userId:[AppDelegate sharedDelegate].userId studentID:txtStudentId.text programID:lesGroup.groupID successed:successed failure:failure];
}

- (void)reloadDataWithTraining{
    [self getPrograms];
}
#pragma mrak StudentCellDelegate
- (void)didRequestStudent:(StudentCell *)_cell{
    NSIndexPath *indexPath = [programTableView indexPathForCell:_cell];
    id rowElement = [arrayProgramsAndStudents objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[Student class]]) {
    }else if ([rowElement isMemberOfClass:[LessonGroup class]]) {
    }else{
        NSDictionary *dict = rowElement;
        currentLessonGroupWithStudents = dict;
        LessonGroup *lesGroup = [currentLessonGroupWithStudents objectForKey:@"lessongroup"];
        lblProgramName.text = lesGroup.name;
    }
    studentAddView.hidden = NO;
    txtStudentId.text = @"";
    // instantaneously make the image view small (scaled to 1% of its actual size)
    studentFindDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        studentFindDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
        [txtStudentId becomeFirstResponder];
    }];
}

-(void)expandLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row {
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    NSPredicate *predicate;
    predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
    [groupRequest setPredicate:predicate];
    
    NSSortDescriptor *groupSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [groupRequest setSortDescriptors:@[groupSortDescriptor]];
    NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
    
    
    int rowsExpanded = 0;
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    NSMutableArray *studentIDs = [[NSMutableArray alloc] init];
    for (LessonGroup *lesGroupToAddStudent in groupArray) {
        if ([lessonGroup.name.lowercaseString isEqualToString:lesGroupToAddStudent.name.lowercaseString] && lesGroupToAddStudent.student != nil) {
            ++rowsExpanded;
            [arrayProgramsAndStudents insertObject:lesGroupToAddStudent.student atIndex:row + rowsExpanded];
            [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:0]];
            
            [studentIDs addObject:lesGroupToAddStudent.student.studentEmail];
        }
    }
    NSMutableDictionary *dictWithLessongroup = [[NSMutableDictionary alloc] init];
    [dictWithLessongroup setObject:lessonGroup forKey:@"lessongroup"];
    [dictWithLessongroup setObject:studentIDs forKey:@"studentIDs"];
    ++rowsExpanded;
    [arrayProgramsAndStudents insertObject:dictWithLessongroup atIndex:row + rowsExpanded];
    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row + rowsExpanded inSection:0]];
    
    lessonGroup.expanded = [NSNumber numberWithBool:YES];
    if ([insertIndexPaths count] > 0) {
        [programTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }

    
    [self resizeViewWithArray];
}
-(void)collapseLessonGroup:(LessonGroup*)lessonGroup atRow:(int)row {
    FDLogDebug(@"collapsing lesson group %@: cells %lu", lessonGroup.name, (unsigned long)[arrayProgramsAndStudents count]);
    
    NSMutableArray *deleteIndexPaths = [NSMutableArray array];
    int i;
    // loop through all subsequent visible cells until end of array or new parent lesson group
    for (i = row + 1; i < [arrayProgramsAndStudents count]; ++i) {
        id rowElement = [arrayProgramsAndStudents objectAtIndex:i];
        // determine if this element is a lesson group or a lesson
        if ([rowElement isMemberOfClass:[Student class]]) {
            // just remove the row
            [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        if ([rowElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dictToCheck = [rowElement copy];
            if ([dictToCheck objectForKey:@"studentIDs"]) {
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                break;
            }
        }
    }
    // remove collapsed rows from array of visible objects
    int rowsCollapsed = i - (row + 1);
    FDLogDebug(@"rows collapsed: %d index paths to delete: %d", rowsCollapsed, [deleteIndexPaths count]);
    if (rowsCollapsed >= 0 && [deleteIndexPaths count] > 0) {
        [arrayProgramsAndStudents removeObjectsInRange:(NSRange){row + 1, [deleteIndexPaths count]}];
        [programTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    
    lessonGroup.expanded = [NSNumber numberWithBool:NO];
    
}

@end
