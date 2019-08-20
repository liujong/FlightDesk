//
//  AddLessonViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddLessonViewController.h"
#import "PersistentCoreDataStack.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
#import "LessonRecord.h"
#import "LogEntry+CoreDataClass.h"
#import "AddAssignmentViewController.h"

#import "ContentEditCell.h"


@interface AddLessonViewController ()<UITableViewDelegate, UITableViewDataSource, MKDropdownMenuDelegate, MKDropdownMenuDataSource, UITextFieldDelegate, UITextViewDelegate, AddAssignmentViewControllerDelegate, ContentEditCellDelegate, SWTableViewCellDelegate>{
    
    NSMutableArray *arrGroundContent;
    NSMutableArray *arrFlightContent;
    NSMutableArray *arrGroundAssignment;
    NSMutableArray *arrFlightAssignment;
    
    NSString *currentCourseName;
    
    BOOL isAdminLevel;
    
    NSManagedObjectContext *contextRecords;
    NSMutableArray *arrayLessonGroupName;
    
    BOOL isAssignedTo;
}

@end

@implementation AddLessonViewController
@synthesize currentLesson, isEditOldLesson;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    showKeyboard = NO;
    isAdminLevel = NO;
    
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    arrayLessonGroupName = [[NSMutableArray alloc] init];
    
    self.title = @"Adding New Lesson";
    txtNewCourse.hidden = YES;
    arrGroundContent = [[NSMutableArray alloc] init];
    arrFlightContent = [[NSMutableArray alloc] init];
    arrGroundAssignment = [[NSMutableArray alloc] init];
    arrFlightAssignment = [[NSMutableArray alloc] init];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        isAdminLevel = YES;
    }else{
        isAdminLevel = NO;
    }
    
    isAssignedTo = NO;
    btnCheckAssignTo.hidden = YES;
    lblAssignToUser.hidden = YES;
    [btnCheckAssignTo setImage:nil forState:UIControlStateNormal];
    
    corseDropmenu.dataSource = self;
    corseDropmenu.delegate = self;

    [self reSizeAllComponentInView];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [scrView addGestureRecognizer:gesture];
    
    if (isEditOldLesson && currentLesson) {
        btnCheckAssignTo.hidden = YES;
        lblAssignToUser.hidden = YES;
        txtViewCompletionFlight.text = currentLesson.flightCompletionStds;
        txtViewObjectivesFlight.text = currentLesson.flightObjective;
        txtViewCompletionObjectives.text = currentLesson.groundCompletionStds;
        txtViewObjectivesGround.text = currentLesson.groundObjective;
        txtDualFlight.text = currentLesson.minDual;
        txtDualGround.text = currentLesson.minGround;
        txtDualInstrument.text = currentLesson.minInstrument;
        txtSoloFlight.text = currentLesson.minSolo;
        txtLessonNumber.text = [NSString stringWithFormat:@"%@", [currentLesson.lessonNumber stringValue]];
        txtLessonTitle.text = currentLesson.title;
        txtLessonGroundSec.text = currentLesson.groundDescription;
        txtLessonSectionFlight.text = currentLesson.flightDescription;
        
        if (currentLesson.record) {
            txtViewInstructorNotesGround.text = currentLesson.record.groundNotes;
            txtViewStudentNotesGround.text = currentLesson.record.groundCompleted;
            txtViewInstructorNotesFlight.text = currentLesson.record.flightNotes;
            txtViewStudentNotesFlight.text = currentLesson.record.flightCompleted;
        }
        if (currentLesson.lessonGroup.parentGroup) {
            currentCourseName = currentLesson.lessonGroup.parentGroup.name;
            [corseDropmenu reloadAllComponents];
        }else{
            currentCourseName = currentLesson.lessonGroup.name;
            [corseDropmenu reloadAllComponents];
        }
        
        if ([currentLesson.lessonGroup.name.lowercaseString containsString:@"stage"]) {
            NSArray *parseName = [currentLesson.lessonGroup.name componentsSeparatedByString:@" "];
            if (parseName.count == 2) {
                txtStageNumber.text = [NSString stringWithFormat:@"%@", parseName[1]];
            }
        }
        
        if (currentLesson.assignments.count > 0) {
            for (Assignment *assignment in currentLesson.assignments) {
                if ([assignment.groundOrFlight integerValue] == 1) {
                    NSMutableDictionary *dictForGround = [[NSMutableDictionary alloc] init];
                    [dictForGround setObject:assignment.referenceID forKey:@"reference"];
                    [dictForGround setObject:assignment.title forKey:@"title"];
                    [dictForGround setObject:assignment.chapters forKey:@"chapters"];
                    [dictForGround setObject:assignment.assignment_local_id forKey:@"assignment_local_id"];
                    [dictForGround setObject:assignment.assignmentID forKey:@"id"];
                    [arrGroundAssignment addObject:dictForGround];
                }else if ([assignment.groundOrFlight integerValue] == 2){
                    NSMutableDictionary *dictForFlight = [[NSMutableDictionary alloc] init];
                    [dictForFlight setObject:assignment.referenceID forKey:@"reference"];
                    [dictForFlight setObject:assignment.title forKey:@"title"];
                    [dictForFlight setObject:assignment.chapters forKey:@"chapters"];
                    [dictForFlight setObject:assignment.assignment_local_id forKey:@"assignment_local_id"];
                    [dictForFlight setObject:assignment.assignmentID forKey:@"id"];
                    [arrFlightAssignment addObject:dictForFlight];
                }
            }
            
            NSString *assignmentStr = @"";
            for (NSDictionary *dict in arrGroundAssignment) {
                if ([assignmentStr isEqualToString:@""]) {
                    assignmentStr = [NSString stringWithFormat:@"%@ %@ : %@", [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
                }else{
                    assignmentStr = [NSString stringWithFormat:@"%@\n%@ %@ : %@",assignmentStr, [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
                }
            }
            txtViewAssignObjectives.text = assignmentStr;
            if (![assignmentStr isEqualToString:@""]) {
                lblARPlaceHoderGround.hidden = YES;
            }
            
            assignmentStr = @"";
            for (NSDictionary *dict in arrFlightAssignment) {
                if ([assignmentStr isEqualToString:@""]) {
                    assignmentStr = [NSString stringWithFormat:@"%@ %@ : %@", [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
                }else{
                    assignmentStr = [NSString stringWithFormat:@"%@\n%@ %@ : %@",assignmentStr, [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
                }
            }
            txtViewAssignFlight.text = assignmentStr;
            if (![assignmentStr isEqualToString:@""]) {
                lblARPlaceHolderFlight.hidden = YES;
            }
        }
        
    
        if (currentLesson.content.count > 0) {
            for (Content * content in currentLesson.content) {
                if ([content.groundOrFlight integerValue] == 1) {
                    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] init];
                    
                    [contentDict setObject:content.contentID forKey:@"contentID"];
                    [contentDict setObject:content.content_local_id forKey:@"content_local_id"];
                    if (content.groundOrFlight) {
                        [contentDict setObject:content.groundOrFlight forKey:@"groundOrFlight"];
                    }else{
                        [contentDict setObject:@(1) forKey:@"groundOrFlight"];
                    }
                    if (content.hasCheck) {
                        [contentDict setObject:content.hasCheck forKey:@"hasCheck"];
                    }else{
                        [contentDict setObject:@NO forKey:@"hasCheck"];
                    }
                    if (content.hasRemarks) {
                        [contentDict setObject:content.hasRemarks forKey:@"hasRemarks"];
                    }else{
                        [contentDict setObject:@NO forKey:@"hasRemarks"];
                    }
                    [contentDict setObject:content.name forKey:@"contentName"];
                    if (content.orderNumber) {
                        [contentDict setObject:content.orderNumber forKey:@"orderNumber"];
                    }else{
                        [contentDict setObject:@(0)forKey:@"orderNumber"];
                    }
                    [contentDict setObject:content.studentUserID forKey:@"studentUserID"];
                    [contentDict setObject:content.depth forKey:@"depth"];
                    
                    [arrGroundContent addObject:contentDict];
                }
            }
            for (int index = 0; index < arrGroundContent.count; index++) {
                NSMutableDictionary *dictToReplace = [[arrGroundContent objectAtIndex:index] mutableCopy];
                [dictToReplace setObject:@(index) forKey:@"index"];
                [arrGroundContent replaceObjectAtIndex:index withObject:dictToReplace];
            }
            [self reSizeAllComponentInView];
            [groundContentAddingTableView reloadData];
            
            
            for (Content * content in currentLesson.content) {
                if ([content.groundOrFlight integerValue] == 2){
                    NSMutableDictionary *contentDict = [[NSMutableDictionary alloc] init];
                    [contentDict setObject:content.contentID forKey:@"contentID"];
                    [contentDict setObject:content.content_local_id forKey:@"content_local_id"];
                    if (content.groundOrFlight) {
                        [contentDict setObject:content.groundOrFlight forKey:@"groundOrFlight"];
                    }else{
                        [contentDict setObject:@(2) forKey:@"groundOrFlight"];
                    }
                    if (content.hasCheck) {
                        [contentDict setObject:content.hasCheck forKey:@"hasCheck"];
                    }else{
                        [contentDict setObject:@NO forKey:@"hasCheck"];
                    }
                    if (content.hasRemarks) {
                        [contentDict setObject:content.hasRemarks forKey:@"hasRemarks"];
                    }else{
                        [contentDict setObject:@NO forKey:@"hasRemarks"];
                    }
                    [contentDict setObject:content.name forKey:@"contentName"];
                    if (content.orderNumber) {
                        [contentDict setObject:content.orderNumber forKey:@"orderNumber"];
                    }else{
                        [contentDict setObject:@(0)forKey:@"orderNumber"];
                    }
                    [contentDict setObject:content.studentUserID forKey:@"studentUserID"];
                    [contentDict setObject:content.depth forKey:@"depth"];
                    [arrFlightContent addObject:contentDict];
                }
            }
            for (int index = 0; index < arrFlightContent.count; index++) {
                NSMutableDictionary *dictToReplace = [[arrFlightContent objectAtIndex:index] mutableCopy];
                [dictToReplace setObject:@(index) forKey:@"index"];
                [arrFlightContent replaceObjectAtIndex:index withObject:dictToReplace];
            }
            [self reSizeAllComponentInView];
            [flightContentAddingTableView reloadData];
        }
        
        if (![txtViewObjectivesGround.text isEqualToString:@""]) {
            lblObjectivesPlaceHolderGround.hidden = YES;
        }
        if (![txtViewCompletionObjectives.text isEqualToString:@""]) {
            lblCSPlaceHolderGround.hidden = YES;
        }
        if (![txtViewAssignObjectives.text isEqualToString:@""]) {
            lblARPlaceHoderGround.hidden = YES;
        }
        if (![txtViewInstructorNotesGround.text isEqualToString:@""]) {
            lblINPlaceHoderGround.hidden = YES;
        }
        if (![txtViewStudentNotesGround.text isEqualToString:@""]) {
            lblSNPlaceHoderGround.hidden = YES;
        }
        if (![txtViewObjectivesFlight.text isEqualToString:@""]) {
            lblObjectivesPlaceHolderFlight.hidden = YES;
        }
        if (![txtViewCompletionFlight.text isEqualToString:@""]) {
            lblCSPlaceHolderFlight.hidden = YES;
        }
        if (![txtViewAssignFlight.text isEqualToString:@""]) {
            lblARPlaceHolderFlight.hidden = YES;
        }
        if (![txtViewInstructorNotesFlight.text isEqualToString:@""]) {
            lblINPlaceHolderFlight.hidden = YES;
        }
        if (![txtViewStudentNotesFlight.text isEqualToString:@""]) {
            lblSNPlaceHolderFlight.hidden = YES;
        }
        
        [btnAssignmentToAddAndEditForGround setTitle:@"+ Add or Edit Assignment" forState:UIControlStateNormal];
        [btnAssignmentToAddAndEditForFlight setTitle:@"+ Add or Edit Assignment" forState:UIControlStateNormal];
    }else{
        [btnAssignmentToAddAndEditForGround setTitle:@"+ Add Assignment" forState:UIControlStateNormal];
        [btnAssignmentToAddAndEditForFlight setTitle:@"+ Add Assignment" forState:UIControlStateNormal];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"AddLessonViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    
    CGRect sizeRect = [UIScreen mainScreen].bounds;
    [navView setFrame:CGRectMake(0, 0, sizeRect.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    
    [self getLessonGroup];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self setNavigationColorWithGradiant];
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
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!showKeyboard)
    {
        showKeyboard = YES;
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, lessonThirdView.frame.origin.y + lessonThirdView.frame.size.height + 270)];
        //[scrView setContentSize:CGSizeMake(scrView.frame.size.width, scrView.frame.size.height + 216.0f)];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (showKeyboard)
    {
        [self.view endEditing:YES];
        [self reSizeAllComponentInView];
        showKeyboard = NO;
    }
}
-(void)handleTap
{
    [self.view endEditing:YES];
}

- (void)getLessonGroup{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve students!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid students found!");
    } else {
        for (LessonGroup *lessonGroup in objects) {
            if (![arrayLessonGroupName containsObject:lessonGroup.name]) {
                [arrayLessonGroupName addObject:lessonGroup.name];
            }
        }
        [corseDropmenu reloadAllComponents];
    }
}

- (void)reSizeAllComponentInView{
    if (isEditOldLesson) {
        [groundContentAddingTableView setFrame:CGRectMake(groundContentAddingTableView.frame.origin.x, groundContentAddingTableView.frame.origin.y, groundContentAddingTableView.frame.size.width, arrGroundContent.count * 44.0f + contentAddView.frame.size.height)];
        [lessonSecondView setFrame:CGRectMake(0, groundContentAddingTableView.frame.origin.y + groundContentAddingTableView.frame.size.height, lessonSecondView.frame.size.width, lessonSecondView.frame.size.height)];
        [flightContentAddingTableView setFrame:CGRectMake(flightContentAddingTableView.frame.origin.x,lessonSecondView.frame.origin.y + lessonSecondView.frame.size.height, flightContentAddingTableView.frame.size.width, arrFlightContent.count * 44.0f + contentAddView.frame.size.height)];
        [lessonThirdView setFrame:CGRectMake(0, flightContentAddingTableView.frame.origin.y + flightContentAddingTableView.frame.size.height, lessonThirdView.frame.size.width, lessonThirdView.frame.size.height)];
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, lessonThirdView.frame.origin.y + lessonThirdView.frame.size.height + 90)];
    }else{
        [groundContentAddingTableView setFrame:CGRectMake(groundContentAddingTableView.frame.origin.x, groundContentAddingTableView.frame.origin.y, groundContentAddingTableView.frame.size.width, arrGroundContent.count * 44.0f + contentAddView.frame.size.height)];
        [lessonSecondView setFrame:CGRectMake(0, groundContentAddingTableView.frame.origin.y + groundContentAddingTableView.frame.size.height, lessonSecondView.frame.size.width, lessonSecondView.frame.size.height)];
        [flightContentAddingTableView setFrame:CGRectMake(flightContentAddingTableView.frame.origin.x,lessonSecondView.frame.origin.y + lessonSecondView.frame.size.height, flightContentAddingTableView.frame.size.width, arrFlightContent.count * 44.0f + contentAddView.frame.size.height)];
        [lessonThirdView setFrame:CGRectMake(0, flightContentAddingTableView.frame.origin.y + flightContentAddingTableView.frame.size.height, lessonThirdView.frame.size.width, lessonThirdView.frame.size.height)];
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, lessonThirdView.frame.origin.y + lessonThirdView.frame.size.height + 90)];
    }
    
    if (arrGroundContent.count > 0) {
        [btnAddContentSectionGround setTitle:@"+ Add other section title" forState:UIControlStateNormal];
    }else{
        for (int i= 0; i < arrGroundContent.count; i ++) {
            NSMutableDictionary *tmpDic = [arrGroundContent objectAtIndex:i];
            [tmpDic setValue:@(i) forKey:@"index"];
            [arrGroundContent replaceObjectAtIndex:i withObject:tmpDic];
        }
        [btnAddContentSectionGround setTitle:@"+ Add section title" forState:UIControlStateNormal];
    }
    if (arrFlightContent.count > 0) {
        [btnAddContentSectionFlight setTitle:@"+ Add other section title" forState:UIControlStateNormal];
    }else {
        for (int i= 0; i < arrFlightContent.count; i ++) {
            NSMutableDictionary *tmpDic = [arrFlightContent objectAtIndex:i];
            [tmpDic setValue:@(i) forKey:@"index"];
            [arrFlightContent replaceObjectAtIndex:i withObject:tmpDic];
        }
        [btnAddContentSectionFlight setTitle:@"+ Add section title" forState:UIControlStateNormal];
    }
}
- (void)saveLesson{
    if (corseDropmenu.hidden == YES) {
        if (!txtNewCourse.text.length)
        {
            [self showAlert:@"Please input Corse Name" title:@"Input Error"];
            return;
        }
    }else{
        if (!currentCourseName.length)
        {
            [self showAlert:@"Please input Corse Name" title:@"Input Error"];
            return;
        }
    }
    if (!txtLessonTitle.text.length)
    {
        [self showAlert:@"Please input Sim Appropriate Lesson" title:@"Input Error"];
        return;
    }
    if (!txtLessonNumber.text.length)
    {
        [self showAlert:@"Please input Lesson Number" title:@"Input Error"];
        return;
    }
    if (!txtDualFlight.text.length)
    {
        [self showAlert:@"Please input Dual Flight" title:@"Input Error"];
        return;
    }
    if (!txtDualGround.text.length)
    {
        [self showAlert:@"Please input Dual Ground" title:@"Input Error"];
        return;
    }
    if (!txtDualInstrument.text.length)
    {
        [self showAlert:@"Please input Dual Instrument" title:@"Input Error"];
        return;
    }
    if (!txtSoloFlight.text.length)
    {
        [self showAlert:@"Please input Solo Flight" title:@"Input Error"];
        return;
    }
    if (!txtLessonGroundSec.text.length)
    {
        [self showAlert:@"Please input Ground Lesson" title:@"Input Error"];
        return;
    }
    
//    if (!txtLessonSectionFlight.text.length)
//    {
//        [self showAlert:@"Please input Flight Section" title:@"Input Error"];
//        return;
//    }
    
    
    NSError *error = nil;
    if (isEditOldLesson) {
        if ([currentLesson.lessonNumber floatValue] != [txtLessonNumber.text floatValue]) {
            LessonGroup *parentGroup = nil;
            if (currentLesson.lessonGroup.parentGroup) {
                parentGroup = currentLesson.lessonGroup.parentGroup;
            }else{
                parentGroup = currentLesson.lessonGroup;
            }
            
            BOOL isExist  = NO;
            for (LessonGroup *subLessonGroup in parentGroup.subGroups) {
                for (Lesson *subLesson in subLessonGroup.lessons) {
                    if ([subLesson.lessonNumber integerValue] == [txtLessonNumber.text integerValue]) {
                        isExist = YES;
                        break;
                    }
                }
            }
            if (!isExist) {
                for (Lesson *subLesson in parentGroup.lessons) {
                    if ([subLesson.lessonNumber integerValue] == [txtLessonNumber.text integerValue]) {
                        isExist = YES;
                        break;
                    }
                }
            }
            
            if (isExist) {
                [self showAlert:[NSString stringWithFormat:@"Lesson %@ already exists, please check number and try again.", txtLessonNumber.text] title:@"Input Error"];
                return;
            }
            
        }
        currentLesson.title = txtLessonTitle.text;
        currentLesson.flightCompletionStds = txtViewCompletionFlight.text;
        currentLesson.flightObjective = txtViewObjectivesFlight.text;
        currentLesson.groundCompletionStds = txtViewCompletionObjectives.text;
        currentLesson.groundObjective = txtViewObjectivesGround.text;
        currentLesson.groundDescription = txtLessonGroundSec.text;
        currentLesson.flightDescription = txtLessonSectionFlight.text;
        currentLesson.minDual = txtDualFlight.text;
        currentLesson.minGround = txtDualGround.text;
        currentLesson.minInstrument = txtDualInstrument.text;
        currentLesson.minSolo = txtSoloFlight.text;
        currentLesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        currentLesson.lastUpdate = @(0);
        
        currentLesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
        for (NSDictionary *dictForGround in arrGroundAssignment) {
            Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
            assignment.chapters = [dictForGround objectForKey:@"chapters"];
            assignment.referenceID = [dictForGround objectForKey:@"reference"];
            assignment.title = [dictForGround objectForKey:@"title"];
            assignment.groundOrFlight = @(1);
            assignment.studentUserID = currentLesson.studentUserID;
            
            if ([dictForGround objectForKey:@"id"]) {
                assignment.assignmentID = [NSNumber numberWithInteger:[[dictForGround objectForKey:@"id"] integerValue]];
                for (int i = 0; i < currentLesson.assignments.count; i ++) {
                    Assignment *assignToCheck = [currentLesson.assignments objectAtIndex:i];
                    if ([assignment.assignmentID integerValue] == [assignToCheck.assignmentID integerValue]) {
                        [currentLesson replaceObjectInAssignmentsAtIndex:i withObject:assignment];
                    }
                }
            }else{
                assignment.assignmentID = @(0);
                [currentLesson addAssignmentsObject:assignment];
            }
        }
        for (NSDictionary *dictForFlight in arrFlightAssignment) {
            Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
            assignment.chapters = [dictForFlight objectForKey:@"chapters"];
            assignment.referenceID = [dictForFlight objectForKey:@"reference"];
            assignment.title = [dictForFlight objectForKey:@"title"];
            assignment.groundOrFlight = @(2);
            assignment.studentUserID = currentLesson.studentUserID;
            if ([dictForFlight objectForKey:@"id"]) {
                assignment.assignmentID = [NSNumber numberWithInteger:[[dictForFlight objectForKey:@"id"] integerValue]];
                for (int i = 0; i < currentLesson.assignments.count; i ++) {
                    Assignment *assignToCheck = [currentLesson.assignments objectAtIndex:i];
                    if ([assignment.assignmentID integerValue] == [assignToCheck.assignmentID integerValue]) {
                        [currentLesson replaceObjectInAssignmentsAtIndex:i withObject:assignment];
                    }
                }
            }else{
                assignment.assignmentID = @(0);
                [currentLesson addAssignmentsObject:assignment];
            }
        }
        
        for (Content *contentToDelete in currentLesson.content) {
            [contextRecords deleteObject:contentToDelete];
        }
        [contextRecords save:&error];
        
        for (NSDictionary *dict in arrGroundContent){
            NSNumber *contentID = [dict objectForKey:@"contentID"];
            NSNumber *content_local_id = [dict objectForKey:@"content_local_id"];
            NSNumber *orderNumber = [dict objectForKey:@"orderNumber"];
            NSNumber *hasRemarks = [dict objectForKey:@"hasRemarks"];
            NSNumber *hasCheck = [dict objectForKey:@"hasCheck"];
            NSString *name = [dict objectForKey:@"contentName"];
            NSNumber *depth = [dict objectForKey:@"depth"];
            
            Content *content = [NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
            content.content_local_id = content_local_id;
            content.depth = depth;
            content.orderNumber = orderNumber;
            content.groundOrFlight = @(1);
            content.hasRemarks = hasRemarks;
            content.hasCheck = hasCheck;
            content.name = name;
            content.studentUserID = currentLesson.studentUserID;
            content.contentID = contentID;
            [currentLesson addContentObject:content];
        }
        for (NSDictionary *dict in arrFlightContent){
            NSNumber *contentID = [dict objectForKey:@"contentID"];
            NSNumber *content_local_id = [dict objectForKey:@"content_local_id"];
            NSNumber *orderNumber = [dict objectForKey:@"orderNumber"];
            NSNumber *hasRemarks = [dict objectForKey:@"hasRemarks"];
            NSNumber *hasCheck = [dict objectForKey:@"hasCheck"];
            NSString *name = [dict objectForKey:@"contentName"];
            NSNumber *depth = [dict objectForKey:@"depth"];
            
            
            Content *content = [NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
            content.content_local_id = content_local_id;
            content.depth = depth;
            content.orderNumber = orderNumber;
            content.groundOrFlight = @(2);
            content.hasRemarks = hasRemarks;
            content.hasCheck = hasCheck;
            content.name = name;
            content.studentUserID = currentLesson.studentUserID;
            content.contentID = contentID;
            [currentLesson addContentObject:content];
        }
        
        LessonGroup *lessonGroupToContainCurrentLesson = currentLesson.lessonGroup;
        LessonGroup *parentLesGroupForCurrentLesson = currentLesson.lessonGroup;
        if (lessonGroupToContainCurrentLesson.parentGroup != nil) {
            parentLesGroupForCurrentLesson = lessonGroupToContainCurrentLesson.parentGroup;
        }
        
        if ([parentLesGroupForCurrentLesson.name isEqualToString:currentCourseName]) {
            if ([txtStageNumber.text isEqualToString:@""]) {
                [lessonGroupToContainCurrentLesson removeLessonsObject:currentLesson];
                [parentLesGroupForCurrentLesson addLessonsObject:currentLesson];
                currentLesson.lessonGroup = parentLesGroupForCurrentLesson;
            }else {
                LessonGroup *subLessonGroup = nil;
                for (LessonGroup *subLessonGroupToUpdate in parentLesGroupForCurrentLesson.subGroups) {
                    if ([[NSString stringWithFormat:@"Stage %@", txtStageNumber.text] isEqualToString:subLessonGroupToUpdate.name]){
                        subLessonGroup = subLessonGroupToUpdate;
                        break;
                    }
                }
                
                [lessonGroupToContainCurrentLesson removeLessonsObject:currentLesson];
                if (subLessonGroup == nil) {
                    LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                    lessonGroupToCreate.groupID = @(0);
                    lessonGroupToCreate.indentation = lessonGroupToContainCurrentLesson.indentation;
                    lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    lessonGroupToCreate.lastUpdate = @(0);
                    lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                    lessonGroupToCreate.expanded = @(0);
                    [lessonGroupToCreate addLessonsObject:currentLesson];
                    currentLesson.lessonGroup = lessonGroupToCreate;
                    if (parentLesGroupForCurrentLesson != nil) {
                        [parentLesGroupForCurrentLesson addSubGroupsObject:lessonGroupToCreate];
                    }
                }else{
                    [subLessonGroup addLessonsObject:currentLesson];
                    currentLesson.lessonGroup = subLessonGroup;
                    if (parentLesGroupForCurrentLesson != nil) {
                        [parentLesGroupForCurrentLesson addSubGroupsObject:subLessonGroup];
                    }
                }
            }
        }else{
            NSEntityDescription *entityDescToCheckOfLessonGroup= [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
            NSFetchRequest *requestToCheckOfLessonNumber = [[NSFetchRequest alloc] init];
            [requestToCheckOfLessonNumber setEntity:entityDescToCheckOfLessonGroup];
            NSPredicate *predicateToCheckLessonNumber = [NSPredicate predicateWithFormat:@"name == %@ && parentGroup == NULL", currentCourseName];
            [requestToCheckOfLessonNumber setPredicate:predicateToCheckLessonNumber];
            NSArray *objects = [contextRecords executeFetchRequest:requestToCheckOfLessonNumber error:&error];
            if (objects.count>0) {
                for (LessonGroup *LessonGroupToUpdate in objects) {
                    if ([txtStageNumber.text isEqualToString:@""]) {
                        [lessonGroupToContainCurrentLesson removeLessonsObject:currentLesson];
                        [LessonGroupToUpdate addLessonsObject:currentLesson];
                        currentLesson.lessonGroup = LessonGroupToUpdate;
                    }else{
                        LessonGroup *subLessonGroup = nil;
                        for (LessonGroup *subLessonGroupToUpdate in LessonGroupToUpdate.subGroups) {
                            if ([[NSString stringWithFormat:@"Stage %@", txtStageNumber.text] isEqualToString:subLessonGroupToUpdate.name]){
                                subLessonGroup = subLessonGroupToUpdate;
                                break;
                            }
                        }
                        
                        [lessonGroupToContainCurrentLesson removeLessonsObject:currentLesson];
                        if (subLessonGroup == nil) {
                            LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                            lessonGroupToCreate.groupID = @(0);
                            lessonGroupToCreate.indentation = lessonGroupToContainCurrentLesson.indentation;
                            lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            lessonGroupToCreate.lastUpdate = @(0);
                            lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                            lessonGroupToCreate.expanded = @(0);
                            [lessonGroupToCreate addLessonsObject:currentLesson];
                            currentLesson.lessonGroup = lessonGroupToCreate;
                            if (LessonGroupToUpdate != nil) {
                                [LessonGroupToUpdate addSubGroupsObject:lessonGroupToCreate];
                            }
                        }else{
                            [subLessonGroup addLessonsObject:currentLesson];
                            currentLesson.lessonGroup = subLessonGroup;
                            if (LessonGroupToUpdate != nil) {
                                [LessonGroupToUpdate addSubGroupsObject:subLessonGroup];
                            }
                        }
                        
                        
                    }
                }
            }
        }
    }else{
        NSEntityDescription *entityDescToCheckOfLessonNumber = [NSEntityDescription entityForName:@"Lesson" inManagedObjectContext:contextRecords];
        NSFetchRequest *requestToCheckOfLessonNumber = [[NSFetchRequest alloc] init];
        [requestToCheckOfLessonNumber setEntity:entityDescToCheckOfLessonNumber];
        NSPredicate *predicateToCheckLessonNumber = [NSPredicate predicateWithFormat:@"lessonNumber == %@", [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]]];
        [requestToCheckOfLessonNumber setPredicate:predicateToCheckLessonNumber];
        NSArray *objects = [contextRecords executeFetchRequest:requestToCheckOfLessonNumber error:&error];
        if (objects.count>0) {
            BOOL isExist  = NO;
            for (Lesson *lessonToCheckGroup in objects) {
                if (lessonToCheckGroup.lessonGroup.parentGroup) {
                    if ([lessonToCheckGroup.lessonGroup.parentGroup.name.lowercaseString isEqualToString:currentCourseName.lowercaseString]) {
                        isExist = YES;
                    }
                }else{
                    if ([lessonToCheckGroup.lessonGroup.name.lowercaseString  isEqualToString:currentCourseName.lowercaseString]) {
                        isExist = YES;
                    }
                }
            }
            
            if (isExist) {
                [self showAlert:[NSString stringWithFormat:@"Lesson %@ already exists, please check number and try again.", txtLessonNumber.text] title:@"Input Error"];
                return;
            }
        }
        
        if (txtNewCourse.hidden == YES) {
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:contextRecords];
            NSError *error;
            // load the remaining lesson groups
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            NSArray *objectsForStudent = [contextRecords executeFetchRequest:request error:&error];
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                //Meaning Admin level account
                [self saveLessonWithAdminAccount];
            }else if (objectsForStudent == nil) {
                FDLogError(@"Unable to retrieve students!");
            } else if (objectsForStudent.count == 0) {
                FDLogDebug(@"No valid students found!");
            } else {
                FDLogDebug(@"%lu students found", (unsigned long)[objectsForStudent count]);
                BOOL isExistStudentOfLessonGroup = NO;
                for (Student *student in objectsForStudent) {
                    for (LessonGroup *lessonGroup in student.subGroups) {
                        if ([lessonGroup.name isEqualToString:currentCourseName]) {
                            isExistStudentOfLessonGroup = YES;
                            Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:contextRecords];
                            lesson.title = txtLessonTitle.text;
                            lesson.studentUserID = student.userID;
                            lesson.flightCompletionStds = txtViewCompletionFlight.text;
                            lesson.flightDescription = txtLessonSectionFlight.text;
                            lesson.flightObjective = txtViewObjectivesFlight.text;
                            lesson.groundCompletionStds = txtViewCompletionObjectives.text;
                            lesson.groundDescription = txtLessonGroundSec.text;
                            lesson.groundObjective = txtViewObjectivesGround.text;
                            lesson.minDual = txtDualFlight.text;
                            lesson.minGround = txtDualGround.text;
                            lesson.minInstrument = txtDualInstrument.text;
                            lesson.minSolo = txtSoloFlight.text;
                            lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            lesson.lastUpdate = @(0);
                            lesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
                            lesson.lessonID = @(0);
                            lesson.lesson_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            lesson.groupIdToSave = lessonGroup.groupID;
                            for (NSDictionary *dictForGround in arrGroundAssignment) {
                                Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                                assignment.chapters = [dictForGround objectForKey:@"chapters"];
                                assignment.referenceID = [dictForGround objectForKey:@"reference"];
                                assignment.title = [dictForGround objectForKey:@"title"];
                                assignment.assignmentID = @(0);
                                assignment.groundOrFlight = @(1);
                                assignment.studentUserID = student.userID;
                                assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                [lesson addAssignmentsObject:assignment];
                            }
                            for (NSDictionary *dictForGround in arrFlightAssignment) {
                                Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                                assignment.chapters = [dictForGround objectForKey:@"chapters"];
                                assignment.referenceID = [dictForGround objectForKey:@"reference"];
                                assignment.title = [dictForGround objectForKey:@"title"];
                                assignment.assignmentID = @(0);
                                assignment.groundOrFlight = @(2);
                                assignment.studentUserID = student.userID;
                                assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                [lesson addAssignmentsObject:assignment];
                            }
                            
                            for (NSDictionary *dict in arrGroundContent){
                                //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                                Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                                content.name = [dict objectForKey:@"contentName"];
                                if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                                    content.hasCheck = @(1);
                                }else{
                                    content.hasCheck = @(0);
                                }
                                if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                                    content.hasRemarks = @(1);
                                }else{
                                    content.hasRemarks = @(0);
                                }
                                content.contentID = @(0);
                                content.groundOrFlight = @(1);
                                content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                                content.studentUserID = student.userID;
                                content.content_local_id = [dict objectForKey:@"content_local_id"];
                                content.depth = [dict objectForKey:@"depth"];
                                
                                [lesson addContentObject:content];
                            }
                            for (NSDictionary *dict in arrFlightContent){
                                //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                                Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                                content.name = [dict objectForKey:@"contentName"];
                                if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                                    content.hasCheck = @(1);
                                }else{
                                    content.hasCheck = @(0);
                                }
                                if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                                    content.hasRemarks = @(1);
                                }else{
                                    content.hasRemarks = @(0);
                                }
                                content.contentID = @(0);
                                content.groundOrFlight = @(2);
                                content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                                content.studentUserID = student.userID;
                                content.content_local_id = [dict objectForKey:@"content_local_id"];
                                content.depth = [dict objectForKey:@"depth"];
                                
                                [lesson addContentObject:content];
                            }
                            
                            if ([txtStageNumber.text isEqualToString:@""]) {
                                [lessonGroup addLessonsObject:lesson];
                                lesson.indentation = [NSNumber numberWithInteger:[lessonGroup.indentation integerValue] + 2];
                            }else{
                                BOOL isExistSubGroup = NO;
                                NSString *stageName = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                                for (LessonGroup *subLessonGroup in lessonGroup.subGroups) {
                                    if ([subLessonGroup.name isEqualToString:stageName]) {
                                        lesson.indentation = [NSNumber numberWithInteger:[subLessonGroup.indentation integerValue] + 2];
                                        [subLessonGroup addLessonsObject:lesson];
                                        isExistSubGroup = YES;
                                    }
                                }
                                if (!isExistSubGroup) {
                                    LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                                    lessonGroupToCreate.groupID = @(0);
                                    lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[lessonGroup.indentation integerValue] + 2];
                                    lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                    lessonGroupToCreate.lastUpdate = @(0);
                                    lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                                    lessonGroupToCreate.expanded = @(0);
                                    lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue] + 2];
                                    [lessonGroupToCreate addLessonsObject:lesson];
                                    
                                    [lessonGroup addSubGroupsObject:lessonGroupToCreate];
                                }
                            }
                        }
                    }
                }
                if (isExistStudentOfLessonGroup == NO) {//Lesson group to be not assigned to student
                    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                    NSError *error;
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    [request setEntity:entityDesc];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
                    [request setPredicate:predicate];
                    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
                    LessonGroup *lessonGroupForNoStudent = nil;
                    if (objects == nil) {
                        FDLogError(@"Unable to retrieve students!");
                    } else if (objects.count == 0) {
                        FDLogDebug(@"No valid students found!");
                    } else {
                        for (LessonGroup *lessonGroup in objects) {
                            if ([lessonGroup.name isEqualToString:currentCourseName]) {
                                lessonGroupForNoStudent = lessonGroup;
                            }
                        }
                    }
                    if (lessonGroupForNoStudent != nil) {
                        Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:contextRecords];
                        lesson.title = txtLessonTitle.text;
                        lesson.studentUserID = lessonGroupForNoStudent.studentUserID;
                        lesson.flightCompletionStds = txtViewCompletionFlight.text;
                        lesson.flightDescription = txtLessonSectionFlight.text;
                        lesson.flightObjective = txtViewObjectivesFlight.text;
                        lesson.groundCompletionStds = txtViewCompletionObjectives.text;
                        lesson.groundDescription = txtLessonGroundSec.text;
                        lesson.groundObjective = txtViewObjectivesGround.text;
                        lesson.minDual = txtDualFlight.text;
                        lesson.minGround = txtDualGround.text;
                        lesson.minInstrument = txtDualInstrument.text;
                        lesson.minSolo = txtSoloFlight.text;
                        lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                        lesson.lastUpdate = @(0);
                        lesson.lesson_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                        lesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
                        lesson.lessonID = @(0);
                        lesson.groupIdToSave = lessonGroupForNoStudent.groupID;
                        for (NSDictionary *dictForGround in arrGroundAssignment) {
                            Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                            assignment.chapters = [dictForGround objectForKey:@"chapters"];
                            assignment.referenceID = [dictForGround objectForKey:@"reference"];
                            assignment.title = [dictForGround objectForKey:@"title"];
                            assignment.assignmentID = @(0);
                            assignment.groundOrFlight = @(1);
                            assignment.studentUserID = lessonGroupForNoStudent.studentUserID;
                            assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            [lesson addAssignmentsObject:assignment];
                        }
                        for (NSDictionary *dictForGround in arrFlightAssignment) {
                            Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                            assignment.chapters = [dictForGround objectForKey:@"chapters"];
                            assignment.referenceID = [dictForGround objectForKey:@"reference"];
                            assignment.title = [dictForGround objectForKey:@"title"];
                            assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            assignment.assignmentID = @(0);
                            assignment.groundOrFlight = @(2);
                            assignment.studentUserID = lessonGroupForNoStudent.studentUserID;
                            [lesson addAssignmentsObject:assignment];
                        }
                        
                        for (NSDictionary *dict in arrGroundContent){
                            //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                            Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                            content.name = [dict objectForKey:@"contentName"];
                            if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                                content.hasCheck = @(1);
                            }else{
                                content.hasCheck = @(0);
                            }
                            if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                                content.hasRemarks = @(1);
                            }else{
                                content.hasRemarks = @(0);
                            }
                            content.contentID = @(0);
                            content.groundOrFlight = @(1);
                            content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                            content.studentUserID = lessonGroupForNoStudent.studentUserID;
                            content.content_local_id = [dict objectForKey:@"content_local_id"];
                            content.depth = [dict objectForKey:@"depth"];
                            
                            [lesson addContentObject:content];
                        }
                        for (NSDictionary *dict in arrFlightContent){
                            //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                            Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                            content.name = [dict objectForKey:@"contentName"];
                            if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                                content.hasCheck = @(1);
                            }else{
                                content.hasCheck = @(0);
                            }
                            if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                                content.hasRemarks = @(1);
                            }else{
                                content.hasRemarks = @(0);
                            }
                            content.contentID = @(0);
                            content.groundOrFlight = @(2);
                            content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                            content.studentUserID = lessonGroupForNoStudent.studentUserID;
                            content.content_local_id = [dict objectForKey:@"content_local_id"];
                            content.depth = [dict objectForKey:@"depth"];
                            
                            [lesson addContentObject:content];
                        }
                        
                        if ([txtStageNumber.text isEqualToString:@""]) {
                            [lessonGroupForNoStudent addLessonsObject:lesson];
                            lesson.indentation = [NSNumber numberWithInteger:[lessonGroupForNoStudent.indentation integerValue] + 2];
                        }else{
                            BOOL isExistSubGroup = NO;
                            NSString *stageName = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                            for (LessonGroup *subLessonGroup in lessonGroupForNoStudent.subGroups) {
                                if ([subLessonGroup.name isEqualToString:stageName]) {
                                    lesson.indentation = [NSNumber numberWithInteger:[subLessonGroup.indentation integerValue] + 2];
                                    [subLessonGroup addLessonsObject:lesson];
                                    isExistSubGroup = YES;
                                }
                            }
                            if (!isExistSubGroup) {
                                LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                                lessonGroupToCreate.groupID = @(0);
                                lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[lessonGroupForNoStudent.indentation integerValue] + 2];
                                lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                lessonGroupToCreate.lastUpdate = @(0);
                                lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                                lessonGroupToCreate.expanded = @(0);
                                lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue] + 2];
                                [lessonGroupToCreate addLessonsObject:lesson];
                                
                                [lessonGroupForNoStudent addSubGroupsObject:lessonGroupToCreate];
                            }
                        }
                    }else{
                        [self showAlert:[NSString stringWithFormat:@"%@ doesn't exists, please input New Course", currentCourseName] title:@"Lesson Creating error"];
                    }
                }
            }
        }else{
            if (!txtNewCourse.text.length)
            {
                [self showAlert:@"Please input Course name" title:@"Input Error"];
                return;
            }
            
            // add lesson groups assigned to the current user
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
            // load the remaining lesson groups
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            // only grab root lesson groups (where there is no parent)
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", txtNewCourse.text];
            [request setPredicate:predicate];
            NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
            if (objects == nil) {
                FDLogError(@"Unable to retrieve lessons!");
            } else if (objects.count == 0) {
                Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:contextRecords];
                lesson.title = txtLessonTitle.text;
                lesson.studentUserID = @(0);
                lesson.flightCompletionStds = txtViewCompletionFlight.text;
                lesson.flightDescription = txtLessonSectionFlight.text;
                lesson.flightObjective = txtViewObjectivesFlight.text;
                lesson.groundCompletionStds = txtViewCompletionObjectives.text;
                lesson.groundDescription = txtLessonGroundSec.text;
                lesson.groundObjective = txtViewObjectivesGround.text;
                lesson.minDual = txtDualFlight.text;
                lesson.minGround = txtDualGround.text;
                lesson.minInstrument = txtDualInstrument.text;
                lesson.minSolo = txtSoloFlight.text;
                lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                lesson.lastUpdate = @(0);
                lesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
                lesson.lessonID = @(0);
                lesson.lesson_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                for (NSDictionary *dictForGround in arrGroundAssignment) {
                    Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                    assignment.chapters = [dictForGround objectForKey:@"chapters"];
                    assignment.referenceID = [dictForGround objectForKey:@"reference"];
                    assignment.title = [dictForGround objectForKey:@"title"];
                    assignment.assignmentID = @(0);
                    assignment.groundOrFlight = @(1);
                    assignment.studentUserID = @(0);
                    assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    [lesson addAssignmentsObject:assignment];
                }
                for (NSDictionary *dictForGround in arrFlightAssignment) {
                    Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                    assignment.chapters = [dictForGround objectForKey:@"chapters"];
                    assignment.referenceID = [dictForGround objectForKey:@"reference"];
                    assignment.title = [dictForGround objectForKey:@"title"];
                    assignment.assignmentID = @(0);
                    assignment.groundOrFlight = @(2);
                    assignment.studentUserID = @(0);
                    assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    [lesson addAssignmentsObject:assignment];
                }
                
                for (NSDictionary *dict in arrGroundContent){
                    //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                    Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                    content.name = [dict objectForKey:@"contentName"];
                    if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                        content.hasCheck = @(1);
                    }else{
                        content.hasCheck = @(0);
                    }
                    if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                        content.hasRemarks = @(1);
                    }else{
                        content.hasRemarks = @(0);
                    }
                    content.contentID = @(0);
                    content.groundOrFlight = @(1);
                    content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                    content.studentUserID = @(0);
                    content.depth = [dict objectForKey:@"depth"];
                    content.content_local_id = [dict objectForKey:@"content_local_id"];
                    
                    [lesson addContentObject:content];
                }
                for (NSDictionary *dict in arrFlightContent){
                    //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                    Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                    content.name = [dict objectForKey:@"contentName"];
                    if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                        content.hasCheck = @(1);
                    }else{
                        content.hasCheck = @(0);
                    }
                    if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                        content.hasRemarks = @(1);
                    }else{
                        content.hasRemarks = @(0);
                    }
                    content.contentID = @(0);
                    content.groundOrFlight = @(2);
                    content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                    content.studentUserID = @(0);
                    content.depth = [dict objectForKey:@"depth"];
                    content.content_local_id = [dict objectForKey:@"content_local_id"];
                    [lesson addContentObject:content];
                }
                
                LessonGroup *lessonGroupToCreateForCourse = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                lessonGroupToCreateForCourse.groupID = @(0);
                if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                    lessonGroupToCreateForCourse.indentation = @(0);
                }else{
                    lessonGroupToCreateForCourse.indentation = @(2);
                }
                lessonGroupToCreateForCourse.studentUserID = @(0);
                lessonGroupToCreateForCourse.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                lessonGroupToCreateForCourse.lastUpdate = @(0);
                lessonGroupToCreateForCourse.name = txtNewCourse.text;
                lessonGroupToCreateForCourse.expanded = @(0);
                lessonGroupToCreateForCourse.isShown = @(1);
                
                if ([txtStageNumber.text isEqualToString:@""]) {
                    lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreateForCourse.indentation integerValue] + 2];
                    [lessonGroupToCreateForCourse addLessonsObject:lesson];
                    
                    lesson.groupIdToSave = lessonGroupToCreateForCourse.groupID;
                }else{
                    LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                    lessonGroupToCreate.groupID = @(0);
                    lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[lessonGroupToCreateForCourse.indentation integerValue] + 2];
                    lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    lessonGroupToCreate.lastUpdate = @(0);
                    lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                    lessonGroupToCreate.expanded = @(0);
                    
                    lesson.groupIdToSave = lessonGroupToCreate.groupID;
                    lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue] + 2];
                    [lessonGroupToCreate addLessonsObject:lesson];
                    [lessonGroupToCreateForCourse addSubGroupsObject:lessonGroupToCreate];
                }
            } else {
                [self showAlert:@"This Course already exists, Please input other Course name" title:@"Input Error"];
                return;
                
            }
        }
    }
    
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Lesson Saved." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             [self.navigationController popViewControllerAnimated:YES];
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
    
}
- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveLessonWithAdminAccount{
    if (txtNewCourse.hidden) {
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            for (LessonGroup *lessonGroup in objects) {
                if ([lessonGroup.name.lowercaseString isEqualToString:currentCourseName.lowercaseString]) {
                    Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:contextRecords];
                    lesson.title = txtLessonTitle.text;
                    lesson.studentUserID = @(0);
                    lesson.flightCompletionStds = txtViewCompletionFlight.text;
                    lesson.flightDescription = txtLessonSectionFlight.text;
                    lesson.flightObjective = txtViewObjectivesFlight.text;
                    lesson.groundCompletionStds = txtViewCompletionObjectives.text;
                    lesson.groundDescription = txtLessonGroundSec.text;
                    lesson.groundObjective = txtViewObjectivesGround.text;
                    lesson.minDual = txtDualFlight.text;
                    lesson.minGround = txtDualGround.text;
                    lesson.minInstrument = txtDualInstrument.text;
                    lesson.minSolo = txtSoloFlight.text;
                    lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    lesson.lastUpdate = @(0);
                    lesson.lesson_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    lesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
                    lesson.lessonID = @(0);
                    lesson.groupIdToSave = lessonGroup.groupID;
                    for (NSDictionary *dictForGround in arrGroundAssignment) {
                        Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                        assignment.chapters = [dictForGround objectForKey:@"chapters"];
                        assignment.referenceID = [dictForGround objectForKey:@"reference"];
                        assignment.title = [dictForGround objectForKey:@"title"];
                        assignment.assignmentID = @(0);
                        assignment.groundOrFlight = @(1);
                        assignment.studentUserID = @(0);
                        assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                        [lesson addAssignmentsObject:assignment];
                    }
                    for (NSDictionary *dictForGround in arrFlightAssignment) {
                        Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                        assignment.chapters = [dictForGround objectForKey:@"chapters"];
                        assignment.referenceID = [dictForGround objectForKey:@"reference"];
                        assignment.title = [dictForGround objectForKey:@"title"];
                        assignment.assignmentID = @(0);
                        assignment.groundOrFlight = @(2);
                        assignment.studentUserID = @(0);
                        assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                        [lesson addAssignmentsObject:assignment];
                    }
                    for (NSDictionary *dict in arrGroundContent){
                        //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                        Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                        content.name = [dict objectForKey:@"contentName"];
                        if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                            content.hasCheck = @(1);
                        }else{
                            content.hasCheck = @(0);
                        }
                        if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                            content.hasRemarks = @(1);
                        }else{
                            content.hasRemarks = @(0);
                        }
                        content.contentID = @(0);
                        content.groundOrFlight = @(1);
                        content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                        content.studentUserID = (0);
                        content.depth = [dict objectForKey:@"depth"];
                        content.content_local_id = [dict objectForKey:@"content_local_id"];
                        
                        [lesson addContentObject:content];
                    }
                    for (NSDictionary *dict in arrFlightContent){
                        //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                        Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                        content.name = [dict objectForKey:@"contentName"];
                        if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                            content.hasCheck = @(1);
                        }else{
                            content.hasCheck = @(0);
                        }
                        if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                            content.hasRemarks = @(1);
                        }else{
                            content.hasRemarks = @(0);
                        }
                        content.contentID = @(0);
                        content.groundOrFlight = @(2);
                        content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                        content.studentUserID = @(0);
                        content.depth = [dict objectForKey:@"depth"];
                        content.content_local_id = [dict objectForKey:@"content_local_id"];
                        [lesson addContentObject:content];
                    }
                    
                    if ([txtStageNumber.text isEqualToString:@""]) {
                        [lessonGroup addLessonsObject:lesson];
                        lesson.indentation = [NSNumber numberWithInteger:[lessonGroup.indentation integerValue] + 2];
                    }else{
                        BOOL isExistSubGroup = NO;
                        NSString *stageName = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                        for (LessonGroup *subLessonGroup in lessonGroup.subGroups) {
                            if ([subLessonGroup.name isEqualToString:stageName]) {
                                lesson.indentation = [NSNumber numberWithInteger:[subLessonGroup.indentation integerValue] + 2];
                                [subLessonGroup addLessonsObject:lesson];
                                isExistSubGroup = YES;
                            }
                        }
                        if (!isExistSubGroup) {
                            LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                            lessonGroupToCreate.groupID = @(0);
                            lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[lessonGroup.indentation integerValue] + 2];
                            lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            lessonGroupToCreate.lastUpdate = @(0);
                            lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                            lessonGroupToCreate.expanded = @(0);
                            lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue] + 2];
                            [lessonGroupToCreate addLessonsObject:lesson];
                            
                            [lessonGroup addSubGroupsObject:lessonGroupToCreate];
                        }
                    }
                }
            }
            
            [corseDropmenu reloadAllComponents];
        }
    }else{
        if (!txtNewCourse.text.length)
        {
            [self showAlert:@"Please input Course name" title:@"Input Error"];
            return;
        }
        NSError *error;
        // add lesson groups assigned to the current user
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        // only grab root lesson groups (where there is no parent)
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", txtNewCourse.text];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve lessons!");
        } else if (objects.count == 0) {
            Lesson *lesson = [NSEntityDescription insertNewObjectForEntityForName:@"Lesson" inManagedObjectContext:contextRecords];
            lesson.title = txtLessonTitle.text;
            lesson.studentUserID = @(0);
            lesson.flightCompletionStds = txtViewCompletionFlight.text;
            lesson.flightDescription = txtLessonSectionFlight.text;
            lesson.flightObjective = txtViewObjectivesFlight.text;
            lesson.groundCompletionStds = txtViewCompletionObjectives.text;
            lesson.groundDescription = txtLessonGroundSec.text;
            lesson.groundObjective = txtViewObjectivesGround.text;
            lesson.minDual = txtDualFlight.text;
            lesson.minGround = txtDualGround.text;
            lesson.minInstrument = txtDualInstrument.text;
            lesson.minSolo = txtSoloFlight.text;
            lesson.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            lesson.lastUpdate = @(0);
            lesson.lessonNumber = [NSNumber numberWithFloat:[txtLessonNumber.text floatValue]];
            lesson.lessonID = @(0);
            lesson.lesson_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            for (NSDictionary *dictForGround in arrGroundAssignment) {
                Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                assignment.chapters = [dictForGround objectForKey:@"chapters"];
                assignment.referenceID = [dictForGround objectForKey:@"reference"];
                assignment.title = [dictForGround objectForKey:@"title"];
                assignment.assignmentID = @(0);
                assignment.groundOrFlight = @(1);
                assignment.studentUserID = @(0);
                assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                [lesson addAssignmentsObject:assignment];
            }
            for (NSDictionary *dictForGround in arrFlightAssignment) {
                Assignment *assignment =[NSEntityDescription insertNewObjectForEntityForName:@"Assignment" inManagedObjectContext:contextRecords];
                assignment.chapters = [dictForGround objectForKey:@"chapters"];
                assignment.referenceID = [dictForGround objectForKey:@"reference"];
                assignment.title = [dictForGround objectForKey:@"title"];
                assignment.assignmentID = @(0);
                assignment.groundOrFlight = @(2);
                assignment.studentUserID = @(0);
                assignment.assignment_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                [lesson addAssignmentsObject:assignment];
            }
            
            for (NSDictionary *dict in arrGroundContent){
                //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                content.name = [dict objectForKey:@"contentName"];
                if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                    content.hasCheck = @(1);
                }else{
                    content.hasCheck = @(0);
                }
                if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                    content.hasRemarks = @(1);
                }else{
                    content.hasRemarks = @(0);
                }
                content.contentID = @(0);
                content.groundOrFlight = @(1);
                content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                content.studentUserID = @(0);
                content.depth = [dict objectForKey:@"depth"];
                content.content_local_id = [dict objectForKey:@"content_local_id"];
                
                [lesson addContentObject:content];
            }
            for (NSDictionary *dict in arrFlightContent){
                //NSDictionary *dict = [arrGroundContent objectAtIndex:i] ;
                Content *content =[NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:contextRecords];
                content.name = [dict objectForKey:@"contentName"];
                if ([[dict objectForKey:@"hasCheck"] boolValue]) {
                    content.hasCheck = @(1);
                }else{
                    content.hasCheck = @(0);
                }
                if ([[dict objectForKey:@"hasRemarks"] boolValue]) {
                    content.hasRemarks = @(1);
                }else{
                    content.hasRemarks = @(0);
                }
                content.contentID = @(0);
                content.groundOrFlight = @(2);
                content.orderNumber = [NSNumber numberWithInteger:[[dict objectForKey:@"index"] integerValue]];
                content.studentUserID = @(0);
                content.depth = [dict objectForKey:@"depth"];
                content.content_local_id = [dict objectForKey:@"content_local_id"];
                [lesson addContentObject:content];
            }
            
            LessonGroup *lessonGroupToCreateForCourse = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
            lessonGroupToCreateForCourse.groupID = @(0);
            lessonGroupToCreateForCourse.indentation = @(0);
            lessonGroupToCreateForCourse.studentUserID = @(0);
            lessonGroupToCreateForCourse.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            lessonGroupToCreateForCourse.lastUpdate = @(0);
            lessonGroupToCreateForCourse.name = txtNewCourse.text;
            lessonGroupToCreateForCourse.expanded = @(0);
            
            if ([txtStageNumber.text isEqualToString:@""]) {
                lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreateForCourse.indentation integerValue] + 2];
                [lessonGroupToCreateForCourse addLessonsObject:lesson];
                
                lesson.groupIdToSave = lessonGroupToCreateForCourse.groupID;
            }else{
                LessonGroup *lessonGroupToCreate = [NSEntityDescription insertNewObjectForEntityForName:@"LessonGroup" inManagedObjectContext:contextRecords];
                lessonGroupToCreate.groupID = @(0);
                lessonGroupToCreate.indentation = [NSNumber numberWithInteger:[lessonGroupToCreateForCourse.indentation integerValue] + 2];
                lessonGroupToCreate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                lessonGroupToCreate.lastUpdate = @(0);
                lessonGroupToCreate.name = [NSString stringWithFormat:@"Stage %@", txtStageNumber.text];
                lessonGroupToCreate.expanded = @(0);
                
                lesson.groupIdToSave = lessonGroupToCreate.groupID;
                lesson.indentation = [NSNumber numberWithInteger:[lessonGroupToCreate.indentation integerValue] + 2];
                [lessonGroupToCreate addLessonsObject:lesson];
                [lessonGroupToCreateForCourse addSubGroupsObject:lessonGroupToCreate];
            }
        } else {
            [self showAlert:@"This Course already exists, Please input other Course name" title:@"Input Error"];
            return;
            
        }
    }
}

- (IBAction)onAddContentSecForflight:(id)sender {
    NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
    [subContentInfo setObject:@(arrFlightContent.count) forKey:@"index"];
    [subContentInfo setObject:@"" forKey:@"contentName"];
    [subContentInfo setObject:@0 forKey:@"depth"];
    [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
    [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
    [subContentInfo setObject:@(0) forKey:@"hasCheck"];
    [subContentInfo setObject:@(0) forKey:@"contentID"];
    
    NSInteger maxOrderNumber = 0;
    for (NSMutableDictionary *dict in arrFlightContent) {
        if (maxOrderNumber < [[dict objectForKey:@"orderNumber"] integerValue]) {
            maxOrderNumber = [[dict objectForKey:@"orderNumber"] integerValue];
        }
    }
    [subContentInfo setObject:@(maxOrderNumber + 1) forKey:@"orderNumber"];
    [subContentInfo setObject:@(0) forKey:@"studentUserID"];
    [subContentInfo setObject:@(2) forKey:@"groundOrFlight"];
    [arrFlightContent addObject:subContentInfo];
    
    [self reSizeAllComponentInView];
    [flightContentAddingTableView reloadData];
}

- (IBAction)onAddContentSec:(UIButton *)sender {
    NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
    [subContentInfo setObject:@(arrGroundContent.count) forKey:@"index"];
    [subContentInfo setObject:@"" forKey:@"contentName"];
    [subContentInfo setObject:@0 forKey:@"depth"];
    [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
    [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
    [subContentInfo setObject:@(0) forKey:@"hasCheck"];
    [subContentInfo setObject:@(0) forKey:@"contentID"];
    NSInteger maxOrderNumber = 0;
    for (NSMutableDictionary *dict in arrGroundContent) {
        if (maxOrderNumber < [[dict objectForKey:@"orderNumber"] integerValue]) {
            maxOrderNumber = [[dict objectForKey:@"orderNumber"] integerValue];
        }
    }
    [subContentInfo setObject:@(maxOrderNumber + 1) forKey:@"orderNumber"];
    [subContentInfo setObject:@(0) forKey:@"studentUserID"];
    [subContentInfo setObject:@(1) forKey:@"groundOrFlight"];
    [arrGroundContent addObject:subContentInfo];
    
    [self reSizeAllComponentInView];
    [groundContentAddingTableView reloadData];
}

- (IBAction)onAddAssignmentForGround:(id)sender {
    AddAssignmentViewController *assignmentView = [[AddAssignmentViewController alloc] initWithNibName:@"AddAssignmentViewController" bundle:nil];
    [assignmentView.view setFrame:self.view.bounds];
    assignmentView.delegate = self;
    assignmentView.assignmentType = 1;
    assignmentView.assignmentArray = arrGroundAssignment;
    [self displayContentController:assignmentView];
    [assignmentView animateShow];
}

- (IBAction)onAddAssignmentForFlight:(id)sender {
    AddAssignmentViewController *assignmentView = [[AddAssignmentViewController alloc] initWithNibName:@"AddAssignmentViewController" bundle:nil];
    [assignmentView.view setFrame:self.view.bounds];
    assignmentView.delegate = self;
    assignmentView.assignmentType = 2;
    assignmentView.assignmentArray = arrFlightAssignment;
    [self displayContentController:assignmentView];
    [assignmentView animateShow];
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

#pragma mark AddAssignmentsViewControllerDelegate
- (void)didCancelAddAssignmentView:(AddAssignmentViewController *)assignmentView{
    [self removeCurrentViewFromSuper:assignmentView];
}
- (void)didDoneAddAssignmentView:(AddAssignmentViewController *)assignmentView assignmentInfo:(NSMutableArray *)_assignmentInfo type:(NSInteger)_type{
    if (_type == 1) {
        NSMutableArray *tmparry = [[NSMutableArray alloc] initWithArray:_assignmentInfo];
        [arrGroundAssignment removeAllObjects];
        [arrGroundAssignment addObjectsFromArray:tmparry];
        NSString *assignmentStr = @"";
        for (NSDictionary *dict in arrGroundAssignment) {
            if ([assignmentStr isEqualToString:@""]) {
                assignmentStr = [NSString stringWithFormat:@"%@ %@ : %@", [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
            }else{
                assignmentStr = [NSString stringWithFormat:@"%@\n%@ %@ : %@",assignmentStr, [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
            }
        }
        txtViewAssignObjectives.text = assignmentStr;
        if (![assignmentStr isEqualToString:@""]) {
            lblARPlaceHoderGround.hidden = YES;
        }
    }else if (_type == 2){
        NSMutableArray *tmparry = [[NSMutableArray alloc] initWithArray:_assignmentInfo];
        [arrFlightAssignment removeAllObjects];
        [arrFlightAssignment addObjectsFromArray:tmparry];
        NSString *assignmentStr = @"";
        for (NSDictionary *dict in arrFlightAssignment) {
            if ([assignmentStr isEqualToString:@""]) {
                assignmentStr = [NSString stringWithFormat:@"%@ %@ : %@", [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
            }else{
                assignmentStr = [NSString stringWithFormat:@"%@\n%@ %@ : %@",assignmentStr, [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
            }
        }
        txtViewAssignFlight.text = assignmentStr;
        if (![assignmentStr isEqualToString:@""]) {
            lblARPlaceHolderFlight.hidden = YES;
        }
        
    }
    [self removeCurrentViewFromSuper:assignmentView];
}
#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == flightContentAddingTableView) {
        return arrFlightContent.count;
    }else if (tableView == groundContentAddingTableView) {
        return arrGroundContent.count;
    }
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *simpleTableIdentifier = @"ContentEditItem";
    ContentEditCell *cell = (ContentEditCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [ContentEditCell sharedCell];
    }
    cell.contentDelegate = self;
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    if (tableView == groundContentAddingTableView) {
        NSMutableDictionary *dict = [arrGroundContent objectAtIndex:indexPath.row];
        [cell saveContentInfo:dict type:1];
        cell.txtContent.text = [dict objectForKey:@"contentName"];
        [cell.txtContent setFrame:CGRectMake(25 * [[dict objectForKey:@"depth"] integerValue], cell.txtContent.frame.origin.y, groundContentAddingTableView.frame.size.width - 135.0f - 25 * [[dict objectForKey:@"depth"] integerValue], cell.txtContent.frame.size.height)];
        if ([[dict objectForKey:@"depth"] integerValue] == 0) {
            cell.txtContent.placeholder = @"Section Title";
        }else{
            cell.txtContent.placeholder = @"Content Item";
        }
        cell.txtContent.tag = 1000 + [[dict objectForKey:@"index"] integerValue];
        if ([[dict objectForKey:@"hasRemarks"] integerValue] == 1) {
            [cell.imgRemark setImage:[UIImage imageNamed:@"right.png"]];
            cell.btnRemark.selected = YES;
        }else{
            [cell.imgRemark setImage:nil];
            cell.btnRemark.selected = NO;
        }
        if ([[dict objectForKey:@"hasCheck"] integerValue] == 1) {
            [cell.imgCheck setImage:[UIImage imageNamed:@"right.png"]];
            cell.btnCheck.selected = YES;
        }else{
            [cell.imgCheck setImage:nil];
            cell.btnCheck.selected = NO;
        }
    }else if (tableView == flightContentAddingTableView)
    {
        NSMutableDictionary *dict = [arrFlightContent objectAtIndex:indexPath.row];
        [cell saveContentInfo:dict type:2];
        cell.txtContent.text = [dict objectForKey:@"contentName"];
        [cell.txtContent setFrame:CGRectMake(25 * [[dict objectForKey:@"depth"] integerValue], cell.txtContent.frame.origin.y, flightContentAddingTableView.frame.size.width - 135.0f - 25 * [[dict objectForKey:@"depth"] integerValue], cell.txtContent.frame.size.height)];
        if ([[dict objectForKey:@"depth"] integerValue] == 0) {
            cell.txtContent.placeholder = @"Section Title";
        }else{
            cell.txtContent.placeholder = @"Content Item";
        }
        cell.txtContent.tag = 3000 + [[dict objectForKey:@"index"] integerValue];
        if ([[dict objectForKey:@"hasRemarks"] integerValue] == 1) {
            [cell.imgRemark setImage:[UIImage imageNamed:@"right.png"]];
            cell.btnRemark.selected = YES;
        }else{
            [cell.imgRemark setImage:nil];
            cell.btnRemark.selected = NO;
        }
        if ([[dict objectForKey:@"hasCheck"] integerValue] == 1) {
            [cell.imgCheck setImage:[UIImage imageNamed:@"right.png"]];
            cell.btnCheck.selected = YES;
        }else{
            [cell.imgCheck setImage:nil];
            cell.btnCheck.selected = NO;
        }
    }
    return cell;
    
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    if (tableView == flightContentAddingTableView) {        
        [view addSubview:contentAddViewForFlight];
    }else if (tableView == groundContentAddingTableView) {
        [view addSubview:contentAddView];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 44.0f;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

#pragma mark - SWTableViewDelegate
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            UITableView *tableView;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                tableView = (UITableView *)[(ContentEditCell *)cell superview];
            }else{
                tableView = (UITableView *)[[(ContentEditCell *)cell superview] superview];
            }
            if (tableView == groundContentAddingTableView) {
                NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:(ContentEditCell *)cell];
                NSMutableDictionary *contentInfo = [arrGroundContent objectAtIndex:indexPath.row];
                NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithArray:arrGroundContent];
                if (isEditOldLesson) {
                    if ([[contentInfo objectForKey:@"contentID"] integerValue] != 0) {
                        
                        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                        NSError *error;
                        
                        for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                            NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                            if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                                if ([[contentInfoToCompare objectForKey:@"contentID"] integerValue] != 0) {
                                    DeleteQuery *deleteQueryForContent = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                                    deleteQueryForContent.type = @"content";
                                    deleteQueryForContent.idToDelete = [contentInfoToCompare objectForKey:@"contentID"];
                                    [context save:&error];
                                }
                                [arrGroundContent removeObject:contentInfoToCompare];
                            }else{
                                break;
                            }
                        }
                        DeleteQuery *deleteQueryForContent = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                        deleteQueryForContent.type = @"content";
                        deleteQueryForContent.idToDelete = [contentInfo objectForKey:@"contentID"];
                        [context save:&error];
                        [arrGroundContent removeObjectAtIndex:indexPath.row];
                    }else{
                        for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                            NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                            if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                                [arrGroundContent removeObject:contentInfoToCompare];
                            }else{
                                break;
                            }
                        }
                        [arrGroundContent removeObjectAtIndex:indexPath.row];
                    }
                }else{
                    for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                        NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                        if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                            [arrGroundContent removeObject:contentInfoToCompare];
                        }else{
                            break;
                        }
                    }
                    [arrGroundContent removeObjectAtIndex:indexPath.row];
                }
                
                for (int i = 0; i < arrGroundContent.count; i ++) {
                    NSMutableDictionary *contentInfo = [arrGroundContent objectAtIndex:i];
                    [contentInfo setObject:@(i + 1) forKey:@"orderNumber"];
                    [arrGroundContent replaceObjectAtIndex:i withObject:contentInfo];
                }
                [self reSizeAllComponentInView];
                [groundContentAddingTableView reloadData];
            }else if (tableView == flightContentAddingTableView) {
                NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:(ContentEditCell *)cell];
                NSMutableDictionary *contentInfo = [arrFlightContent objectAtIndex:indexPath.row];
                NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithArray:arrFlightContent];
                if (isEditOldLesson) {
                    if ([[contentInfo objectForKey:@"contentID"] integerValue] != 0) {
                        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                        NSError *error;
                        
                        for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                            NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                            if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                                if ([[contentInfoToCompare objectForKey:@"contentID"] integerValue] != 0) {
                                    DeleteQuery *deleteQueryForContent = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                                    deleteQueryForContent.type = @"content";
                                    deleteQueryForContent.idToDelete = [contentInfoToCompare objectForKey:@"contentID"];
                                    [context save:&error];
                                }
                                [arrFlightContent removeObject:contentInfoToCompare];
                            }else{
                                break;
                            }
                        }
                        DeleteQuery *deleteQueryForContent = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                        deleteQueryForContent.type = @"content";
                        deleteQueryForContent.idToDelete = [contentInfo objectForKey:@"contentID"];
                        [context save:&error];
                        [arrFlightContent removeObjectAtIndex:indexPath.row];
                    }else{
                        for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                            NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                            if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                                [arrFlightContent removeObject:contentInfoToCompare];
                            }else{
                                break;
                            }
                        }
                        [arrFlightContent removeObjectAtIndex:indexPath.row];
                    }
                }else{
                    for (int i = indexPath.row + 1; i < tmpArray.count; i ++) {
                        NSMutableDictionary *contentInfoToCompare = [tmpArray objectAtIndex:i];
                        if ([[contentInfo objectForKey:@"depth"] integerValue] < [[contentInfoToCompare objectForKey:@"depth"] integerValue]) {
                            [arrFlightContent removeObject:contentInfoToCompare];
                        }else{
                            break;
                        }
                    }
                    [arrFlightContent removeObjectAtIndex:indexPath.row];
                }
                
                for (int i = 0; i < arrFlightContent.count; i ++) {
                    NSMutableDictionary *contentInfo = [arrFlightContent objectAtIndex:i];
                    [contentInfo setObject:@(i + 1) forKey:@"orderNumber"];
                    [arrFlightContent replaceObjectAtIndex:i withObject:contentInfo];
                }
                [self reSizeAllComponentInView];
                [flightContentAddingTableView reloadData];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mrak - ContentEditCellDelegate
- (void)didAddContent:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell withType:(NSInteger)_type{
    if (_type == 1) { // ground
        NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:_cell];
        if (isEditOldLesson) {
            if ([[contentInfo objectForKey:@"contentID"] integerValue] != 0) {
                NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
                [subContentInfo setObject:@(0) forKey:@"contentID"];
                [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
                [subContentInfo setObject:[contentInfo objectForKey:@"groundOrFlight"] forKey:@"groundOrFlight"];
                [subContentInfo setObject:@(0) forKey:@"hasCheck"];
                [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
                [subContentInfo setObject:@"" forKey:@"contentName"];
                [subContentInfo setObject:@(0)forKey:@"orderNumber"];
                [subContentInfo setObject:[contentInfo objectForKey:@"studentUserID"] forKey:@"studentUserID"];
                [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
                [subContentInfo setObject:@(arrGroundContent.count) forKey:@"index"];
                for (int i = 0; i < arrGroundContent.count; i ++) {
                    NSDictionary *dict = [arrGroundContent objectAtIndex:i];
                    if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                        int indexToInsert = i;
                        for (int j = i+1; j < arrGroundContent.count; j ++) {
                            NSDictionary *subDict = [arrGroundContent objectAtIndex:j];
                            if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                                indexToInsert = j;
                            }else{
                                break;
                            }
                        }
                        [arrGroundContent insertObject:subContentInfo atIndex:indexToInsert+1];
                        break;
                    }
                }
            }else{
                NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
                [subContentInfo setObject:@(0) forKey:@"contentID"];
                [subContentInfo setObject:[contentInfo objectForKey:@"groundOrFlight"] forKey:@"groundOrFlight"];
                [subContentInfo setObject:@(0) forKey:@"hasCheck"];
                [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
                [subContentInfo setObject:@"" forKey:@"contentName"];
                [subContentInfo setObject:@(0)forKey:@"orderNumber"];
                [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
                [subContentInfo setObject:[contentInfo objectForKey:@"studentUserID"] forKey:@"studentUserID"];
                [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
                [subContentInfo setObject:@(arrGroundContent.count) forKey:@"index"];

                for (int i = 0; i < arrGroundContent.count; i ++) {
                    NSDictionary *dict = [arrGroundContent objectAtIndex:i];
                    if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                        int indexToInsert = i;
                        for (int j = i+1; j < arrGroundContent.count; j ++) {
                            NSDictionary *subDict = [arrGroundContent objectAtIndex:j];
                            if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                                indexToInsert = j;
                            }else{
                                break;
                            }
                        }
                        [arrGroundContent insertObject:subContentInfo atIndex:indexToInsert+1];
                        break;
                    }
                }
            }
        }else{
            NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
            [subContentInfo setObject:@(arrGroundContent.count) forKey:@"index"];
            [subContentInfo setObject:@"" forKey:@"contentName"];
            [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
            [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
            [subContentInfo setObject:@(0) forKey:@"hasCheck"];
            [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
            [subContentInfo setObject:@(0) forKey:@"contentID"];
            [subContentInfo setObject:@(0) forKey:@"orderNumber"];
            [subContentInfo setObject:@(0) forKey:@"studentUserID"];
            [subContentInfo setObject:@(1) forKey:@"groundOrFlight"];
            
            for (int i = 0; i < arrGroundContent.count; i ++) {
                NSDictionary *dict = [arrGroundContent objectAtIndex:i];
                if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                    int indexToInsert = i;
                    for (int j = i+1; j < arrGroundContent.count; j ++) {
                        NSDictionary *subDict = [arrGroundContent objectAtIndex:j];
                        if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                            indexToInsert = j;
                        }else{
                            break;
                        }
                    }
                    [arrGroundContent insertObject:subContentInfo atIndex:indexToInsert+1];
                }
            }
        }
        
        for (int i = 0; i < arrGroundContent.count; i ++) {
            NSMutableDictionary *contentInfo = [arrGroundContent objectAtIndex:i];
            [contentInfo setObject:@(i + 1) forKey:@"orderNumber"];
            [arrGroundContent replaceObjectAtIndex:i withObject:contentInfo];
        }
        [self reSizeAllComponentInView];
        [groundContentAddingTableView reloadData];
    }else if(_type == 2){ // flight
        NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:_cell];
        if (isEditOldLesson) {
            if ([[contentInfo objectForKey:@"contentID"] integerValue] != 0) {
                NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
                [subContentInfo setObject:@(0) forKey:@"contentID"];
                [subContentInfo setObject:[contentInfo objectForKey:@"groundOrFlight"] forKey:@"groundOrFlight"];
                [subContentInfo setObject:@(0) forKey:@"hasCheck"];
                [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
                [subContentInfo setObject:@"" forKey:@"contentName"];
                [subContentInfo setObject:@(0)forKey:@"orderNumber"];
                [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
                [subContentInfo setObject:[contentInfo objectForKey:@"studentUserID"] forKey:@"studentUserID"];
                [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
                [subContentInfo setObject:@(arrFlightContent.count) forKey:@"index"];
                for (int i = 0; i < arrFlightContent.count; i ++) {
                    NSDictionary *dict = [arrFlightContent objectAtIndex:i];
                    if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                        int indexToInsert = i;
                        for (int j = i+1; j < arrFlightContent.count; j ++) {
                            NSDictionary *subDict = [arrFlightContent objectAtIndex:j];
                            if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                                indexToInsert = j;
                            }else{
                                break;
                            }
                        }
                        [arrFlightContent insertObject:subContentInfo atIndex:indexToInsert+1];
                        break;
                    }
                }
            }else{
                NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
                [subContentInfo setObject:@(0) forKey:@"contentID"];
                [subContentInfo setObject:[contentInfo objectForKey:@"groundOrFlight"] forKey:@"groundOrFlight"];
                [subContentInfo setObject:@(0) forKey:@"hasCheck"];
                [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
                [subContentInfo setObject:@"" forKey:@"contentName"];
                [subContentInfo setObject:@(0)forKey:@"orderNumber"];
                [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
                [subContentInfo setObject:[contentInfo objectForKey:@"studentUserID"] forKey:@"studentUserID"];
                [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
                [subContentInfo setObject:@(arrFlightContent.count) forKey:@"index"];
                
                for (int i = 0; i < arrFlightContent.count; i ++) {
                    NSDictionary *dict = [arrFlightContent objectAtIndex:i];
                    if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                        int indexToInsert = i;
                        for (int j = i+1; j < arrFlightContent.count; j ++) {
                            NSDictionary *subDict = [arrFlightContent objectAtIndex:j];
                            if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                                indexToInsert = j;
                            }else{
                                break;
                            }
                        }
                        [arrFlightContent insertObject:subContentInfo atIndex:indexToInsert+1];
                        break;
                    }
                }
            }
        }else{
            NSMutableDictionary *subContentInfo = [[NSMutableDictionary alloc] init];
            [subContentInfo setObject:@(arrFlightContent.count) forKey:@"index"];
            [subContentInfo setObject:@"" forKey:@"contentName"];
            [subContentInfo setObject:@([[contentInfo objectForKey:@"depth"] integerValue] + 1) forKey:@"depth"];
            [subContentInfo setObject:@(0) forKey:@"hasRemarks"];
            [subContentInfo setObject:@(0) forKey:@"hasCheck"];
            [subContentInfo setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"content_local_id"];
            
            [subContentInfo setObject:@(0) forKey:@"contentID"];
            [subContentInfo setObject:@(0) forKey:@"orderNumber"];
            [subContentInfo setObject:@(0) forKey:@"studentUserID"];
            [subContentInfo setObject:@(2) forKey:@"groundOrFlight"];
            
            for (int i = 0; i < arrFlightContent.count; i ++) {
                NSDictionary *dict = [arrFlightContent objectAtIndex:i];
                if ([[dict objectForKey:@"index"] integerValue] == [[contentInfo objectForKey:@"index"] integerValue]) {
                    int indexToInsert = i;
                    for (int j = i+1; j < arrFlightContent.count; j ++) {
                        NSDictionary *subDict = [arrFlightContent objectAtIndex:j];
                        if ([[subDict objectForKey:@"depth"] integerValue] > [[dict objectForKey:@"depth"] integerValue]) {
                            indexToInsert = j;
                        }else{
                            break;
                        }
                    }
                    [arrFlightContent insertObject:subContentInfo atIndex:indexToInsert+1];
                }
            }
        }
        
        for (int i = 0; i < arrFlightContent.count; i ++) {
            NSMutableDictionary *contentInfo = [arrFlightContent objectAtIndex:i];
            [contentInfo setObject:@(i + 1) forKey:@"orderNumber"];
            [arrFlightContent replaceObjectAtIndex:i withObject:contentInfo];
        }
        [self reSizeAllComponentInView];
        [flightContentAddingTableView reloadData];
    }
}
- (void)didCheckedRemarks:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell selected:(BOOL)_selected withType:(NSInteger)_type{
    if (_type == 1) {
        NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:_cell];
        NSMutableDictionary *focusContent = [arrGroundContent objectAtIndex:indexPath.row];
        [focusContent setObject:[NSNumber numberWithBool:_selected] forKey:@"hasRemarks"];
        [arrGroundContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
        [self reSizeAllComponentInView];
        [groundContentAddingTableView reloadData];
    }else if (_type == 2){
        NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:_cell];
        NSMutableDictionary *focusContent = [arrFlightContent objectAtIndex:indexPath.row];
        
        [focusContent setObject:[NSNumber numberWithBool:_selected] forKey:@"hasRemarks"];
        [arrFlightContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
        
        [self reSizeAllComponentInView];
        [flightContentAddingTableView reloadData];
    }
    
}
- (void)didCheckedCheckBox:(NSMutableDictionary *)contentInfo cell:(ContentEditCell *)_cell selected:(BOOL)_selected withType:(NSInteger)_type{
    if (_type == 1) {
        NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:_cell];
        NSMutableDictionary *focusContent = [arrGroundContent objectAtIndex:indexPath.row];
        [focusContent setObject:[NSNumber numberWithBool:_selected] forKey:@"hasCheck"];
        [arrGroundContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
        [self reSizeAllComponentInView];
        [groundContentAddingTableView reloadData];
    }else if (_type == 2){
        NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:_cell];
        NSMutableDictionary *focusContent = [arrFlightContent objectAtIndex:indexPath.row];
        
        [focusContent setObject:[NSNumber numberWithBool:_selected] forKey:@"hasCheck"];
        [arrFlightContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
        
        [self reSizeAllComponentInView];
        [flightContentAddingTableView reloadData];
    }
}
- (void)fieldTableCell:(ContentEditCell *)cell textDidChange:(NSString *)text withType:(NSInteger)_type{
    if (_type == 1) {
        NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:cell];
        NSMutableDictionary *focusContent = [arrGroundContent objectAtIndex:indexPath.row];
        [focusContent setObject:text forKey:@"contentName"];
        [arrGroundContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
    }else if (_type == 2){
        NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:cell];
        NSMutableDictionary *focusContent = [arrFlightContent objectAtIndex:indexPath.row];
        
        [focusContent setObject:text forKey:@"contentName"];
        [arrFlightContent replaceObjectAtIndex:indexPath.row withObject:focusContent];
    }
}
- (void)fieldTableCellTextFieldDidReturn:(ContentEditCell *)cell withType:(NSInteger)_type{
    if (_type == 1) {
        NSIndexPath *indexPath = [groundContentAddingTableView indexPathForCell:cell];
        if (indexPath && indexPath.row < [groundContentAddingTableView numberOfRowsInSection:indexPath.section] - 1) {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
            [groundContentAddingTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            UITableViewCell *cell = [groundContentAddingTableView cellForRowAtIndexPath:nextIndexPath];
            if (cell) {
                if ([cell isKindOfClass:[ContentEditCell class]])
                    [((ContentEditCell *)cell).txtContent becomeFirstResponder];
            } else {
                
            }
        }
    }else if (_type == 2){
        NSIndexPath *indexPath = [flightContentAddingTableView indexPathForCell:cell];
        if (indexPath && indexPath.row < [flightContentAddingTableView numberOfRowsInSection:indexPath.section] - 1) {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
            [flightContentAddingTableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            UITableViewCell *cell = [flightContentAddingTableView cellForRowAtIndexPath:nextIndexPath];
            if (cell) {
                if ([cell isKindOfClass:[ContentEditCell class]])
                    [((ContentEditCell *)cell).txtContent becomeFirstResponder];
            } else {
                
            }
        }
    }
}

#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    if (isEditOldLesson) {
        return arrayLessonGroupName.count;
    }else{
        return arrayLessonGroupName.count+1;
    }
}

#pragma mark - MKDropdownMenuDelegate

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
    return currentCourseName;
}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == arrayLessonGroupName.count) {
        return @"-New Course-";
    }
    return [arrayLessonGroupName objectAtIndex:row];
}

- (BOOL)dropdownMenu:(MKDropdownMenu *)dropdownMenu shouldUseFullRowWidthForComponent:(NSInteger)component {
    return NO;
}
- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == arrayLessonGroupName.count) {
        txtNewCourse.hidden = NO;
        corseDropmenu.hidden = YES;
        
//        btnCheckAssignTo.hidden = NO;
//        lblAssignToUser.hidden = NO;
        
        
        [txtNewCourse becomeFirstResponder];
    }else{
        currentCourseName = [arrayLessonGroupName objectAtIndex:row];
    }
    
    [dropdownMenu closeAllComponentsAnimated:YES];
    [corseDropmenu reloadAllComponents];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtNewCourse) {
        [txtStageNumber becomeFirstResponder];
    }else if (textField == txtStageNumber) {
        [txtLessonTitle becomeFirstResponder];
    }else if (textField == txtLessonTitle) {
        [txtLessonNumber becomeFirstResponder];
    }else if (textField == txtLessonNumber){
        [txtDualFlight becomeFirstResponder];
    }else if (textField == txtDualFlight){
        [txtDualGround becomeFirstResponder];
    }else if (textField == txtDualGround){
        [txtDualInstrument becomeFirstResponder];
    }else if (textField == txtDualInstrument){
        [txtSoloFlight becomeFirstResponder];
    }else if (textField == txtLessonGroundSec){
        [txtViewObjectivesGround becomeFirstResponder];
    }
    return YES;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView{
    if (textView == txtViewObjectivesGround) {
        lblObjectivesPlaceHolderGround.hidden = YES;
    }else if (textView == txtViewCompletionObjectives) {
        lblCSPlaceHolderGround.hidden = YES;
    }else if (textView == txtViewAssignObjectives) {
        lblARPlaceHoderGround.hidden = YES;
    }else if (textView == txtViewInstructorNotesGround) {
        lblINPlaceHoderGround.hidden = YES;
    }else if (textView == txtViewStudentNotesGround) {
        lblSNPlaceHoderGround.hidden = YES;
    }else if (textView == txtViewObjectivesFlight) {
        lblObjectivesPlaceHolderFlight.hidden = YES;
    }else if (textView == txtViewCompletionFlight) {
        lblCSPlaceHolderFlight.hidden = YES;
    }else if (textView == txtViewAssignFlight) {
        lblARPlaceHolderFlight.hidden = YES;
    }else if (textView == txtViewInstructorNotesFlight) {
        lblINPlaceHolderFlight.hidden = YES;
    }else if (textView == txtViewStudentNotesFlight) {
        lblSNPlaceHolderFlight.hidden = YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if (textView == txtViewObjectivesGround) {
        if ([txtViewObjectivesGround.text isEqualToString:@""]) {
            lblObjectivesPlaceHolderGround.hidden = NO;
        }
    }else if (textView == txtViewCompletionObjectives) {
        if ([txtViewCompletionObjectives.text isEqualToString:@""]) {
            lblCSPlaceHolderGround.hidden = NO;
        }
    }else if (textView == txtViewAssignObjectives) {
        if ([txtViewAssignObjectives.text isEqualToString:@""]) {
            lblARPlaceHoderGround.hidden = NO;
        }
    }else if (textView == txtViewInstructorNotesGround) {
        if ([txtViewInstructorNotesGround.text isEqualToString:@""]) {
            lblINPlaceHoderGround.hidden = NO;
        }
    }else if (textView == txtViewStudentNotesGround) {
        if ([txtViewStudentNotesGround.text isEqualToString:@""]) {
            lblSNPlaceHoderGround.hidden = NO;
        }
    }else if (textView == txtViewObjectivesFlight) {
        if ([txtViewObjectivesFlight.text isEqualToString:@""]) {
            lblObjectivesPlaceHolderFlight.hidden = NO;
        }
    }else if (textView == txtViewCompletionFlight) {
        if ([txtViewCompletionFlight.text isEqualToString:@""]) {
            lblCSPlaceHolderFlight.hidden = NO;
        }
    }else if (textView == txtViewAssignFlight) {
        if ([txtViewAssignFlight.text isEqualToString:@""]) {
            lblARPlaceHolderFlight.hidden = NO;
        }
    }else if (textView == txtViewInstructorNotesFlight) {
        if ([txtViewInstructorNotesFlight.text isEqualToString:@""]) {
            lblINPlaceHolderFlight.hidden = NO;
        }
    }else if (textView == txtViewStudentNotesFlight) {
        if ([txtViewStudentNotesFlight.text isEqualToString:@""]) {
            lblSNPlaceHolderFlight.hidden = NO;
        }
    }
}

- (IBAction)onBack:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save your changes before exiting?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             [self saveLesson];
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
                             {
                                 [self.navigationController popViewControllerAnimated:YES];
                             }];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onSave:(id)sender {
    [self saveLesson];
    
}

- (IBAction)onCheckAssignTo:(id)sender {
    isAssignedTo = !isAssignedTo;
    if (isAssignedTo == YES) {
        [btnCheckAssignTo setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckAssignTo setImage:nil forState:UIControlStateNormal];
    }
}
@end
