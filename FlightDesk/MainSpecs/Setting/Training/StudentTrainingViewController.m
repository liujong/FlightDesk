//
//  StudentTrainingViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "StudentTrainingViewController.h"
#import "StudentProgramCell.h"

@interface StudentTrainingViewController ()<UITableViewDataSource, UITableViewDelegate, StudentProgramCellDelegate>{
    NSMutableArray *arrayPrograms;
    LessonGroup *currentLessonGroup;
    
    NSManagedObjectContext *context;
}

@end

@implementation StudentTrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    instructorFindDialog.autoresizesSubviews = NO;
    instructorFindDialog.contentMode = UIViewContentModeRedraw;
    instructorFindDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    instructorFindDialog.layer.shadowRadius = 3.0f;
    instructorFindDialog.layer.shadowOpacity = 1.0f;
    instructorFindDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    instructorFindDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:instructorFindDialog.bounds].CGPath;
    instructorFindDialog.layer.cornerRadius = 5.0f;
    instructorFindView.hidden = YES;
    
    
    context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    arrayPrograms = [[NSMutableArray alloc] init];
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
    [self resizeViewWithArray];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"StudentTrainingviewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [AppDelegate sharedDelegate].studentTrain_VC = self;
    [self getPrograms];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [AppDelegate sharedDelegate].studentTrain_VC = nil;
}

- (void)getPrograms{
    [arrayPrograms removeAllObjects];
    [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
    
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    NSSortDescriptor *groupSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [groupRequest setSortDescriptors:@[groupSortDescriptor]];
    
    NSError *error;
    NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
    if (groupArray == nil) {
        FDLogError(@"Unable to retrieve lesson group!");
    } else if (groupArray.count == 0) {
        FDLogDebug(@"No groups stored!");
    } else {
        for (LessonGroup *group in groupArray) {
            if (group.parentGroup == nil) {
                BOOL isExist = NO;
                for (LessonGroup *lesGroupToCheck in arrayPrograms) {
                    if ([group.groupID integerValue] == [lesGroupToCheck.groupID integerValue]) {
                        isExist = YES;
                        break;
                    }
                }
                if (!isExist) {
                    [arrayPrograms addObject:group];
                }
            }
        }
    }
    
    if (arrayPrograms.count == 0) {
        [arrayPrograms addObject:@"new"];
    }
    [self resizeViewWithArray];
    [ProgramsShowTableView reloadData];
}

- (IBAction)onCancel:(id)sender {
    instructorFindView.hidden = YES;
}

- (void)reloadDataWithTraining{
    
    [self getPrograms];
}
- (void)resizeViewWithArray{
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 400.0f + arrayPrograms.count * 75.0f;
    [scrView setContentSize:scrSize];
    
    CGRect tableRect = ProgramsShowTableView.frame;
    tableRect.size.height = arrayPrograms.count * 75.0f + 50.0f;// + 70.0f;
    ProgramsShowTableView.frame = tableRect;
    //    [programTableView setFrame:tableRect];
}
- (IBAction)onFind:(id)sender {
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        [ self  showAlert: @"You can't use this function." :@"FlightDesk"] ;
        return;
    }
    if (currentLessonGroup) {
        if ([currentLessonGroup.instructorEmail isEqualToString:txtInsID.text]) {
            [ self  showAlert: @"You already work with this instructor." :@"FlightDesk"] ;
            return;
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
    
    [AppDelegate sharedDelegate].programName = currentLessonGroup.name;
    [AppDelegate sharedDelegate].trainingHud = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
    [AppDelegate sharedDelegate].trainingHud.label.text = @"Finding instructor…";
    
    void ( ^successed )( id _responseObject ) = ^( id _responseObject )
    {
        if ([[_responseObject objectForKey:@"success"] boolValue]) {
            
            [AppDelegate sharedDelegate].trainingHud.label.text = @"User Found";
            
            [[AppDelegate sharedDelegate] stopThreadToSyncData:[AppDelegate sharedDelegate].currentSyncingIndex];
            [[AppDelegate sharedDelegate] startThreadToSyncData:1];
            instructorFindView.hidden = YES;
        }else if ( ![[_responseObject objectForKey:@"success"] boolValue]){
            [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
            [self  showAlert: [NSString stringWithFormat:@"Can't find %@, Please try with other Instructor.", txtInsID.text] :@"FlightDesk"] ;
        }
        
    };
    
    void ( ^failure )( NSError* _error ) = ^( NSError* _error )
    {
        [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
        [ self  showAlert: @"Internet connection error!" :@"Failed!"] ;
        
    } ;
    if (currentLessonGroup) {
        [[Communication sharedManager] ActionFlightDeskFindInstructor:@"find_instructor" userId:[AppDelegate sharedDelegate].userId instructorID:txtInsID.text preInstructorID:currentLessonGroup.instructorEmail programID:currentLessonGroup.groupID successed:successed failure:failure];
    }else{
        [[Communication sharedManager] ActionFlightDeskFindInstructor:@"find_instructor" userId:[AppDelegate sharedDelegate].userId instructorID:txtInsID.text preInstructorID:@"" programID:currentLessonGroup.groupID successed:successed failure:failure];
    }
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
    return [arrayPrograms count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 75.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"StudentProgramItem";
    StudentProgramCell *cell = (StudentProgramCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [StudentProgramCell sharedCell];
    }
    cell.delegate = self;
    
    id rowElement = [arrayPrograms objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lessonGroup = rowElement;
        cell.lblProgramName.text = lessonGroup.name;
        if (![lessonGroup.instructorName.lowercaseString isEqualToString:@"admin"]) {
            cell.txtInstructorName.text = lessonGroup.instructorName; 
        }else{
            cell.txtInstructorName.text = @"";
        }
        if ([lessonGroup.isShown boolValue] == YES) {
            cell.btnSelect.selected = YES;
            [cell.selectImageView setImage:[UIImage imageNamed:@"right.png"]];
        }else{
            cell.btnSelect.selected = NO;
            [cell.selectImageView setImage:nil];
        }
    }else{
        cell.lblProgramName.text = @"";
        cell.txtInstructorName.text = @"";
    }
    
    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark PorgramCellDelegate Methods
- (void)didChecked:(StudentProgramCell *)_cell selected:(BOOL)_selected{
    NSIndexPath *indexPath = [ProgramsShowTableView indexPathForCell:_cell];
    id rowElement = [arrayPrograms objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lesGroup = rowElement;
        if (_selected) {
            lesGroup.isShown = @YES;
        }else{
            lesGroup.isShown = @NO;
        }
        lesGroup.lastUpdate = @(0);
        NSError *error;
        [context save:&error];
        if (error) {
            NSLog(@"%@", error);
        }
        
        [[AppDelegate sharedDelegate] setDocumentNavigationBadge];
    }else{
        txtInsID.text = @"";
    }
}
- (void)didRequestInstructor:(StudentProgramCell *)_cell{
    NSIndexPath *indexPath = [ProgramsShowTableView indexPathForCell:_cell];
    id rowElement = [arrayPrograms objectAtIndex:indexPath.row];
    if ([rowElement isMemberOfClass:[LessonGroup class]]) {
        LessonGroup *lesGroup = rowElement;
        currentLessonGroup = lesGroup;
    }else{
        txtInsID.text = @"";
    }
    
    txtInsID.text = currentLessonGroup.instructorEmail;
    
    instructorFindView.hidden = NO;
    // instantaneously make the image view small (scaled to 1% of its actual size)
    instructorFindDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        instructorFindDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}
@end
