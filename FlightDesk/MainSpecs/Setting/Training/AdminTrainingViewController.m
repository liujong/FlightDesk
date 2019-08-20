//
//  AdminTrainingViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/25/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AdminTrainingViewController.h"
#import "ProgramCell.h"
@interface AdminTrainingViewController ()<UITableViewDelegate, UITableViewDataSource>{
    
    NSMutableArray *arrayPrograms;
    NSMutableArray *unUsedProgramsArray;
    NSMutableArray *selectedPrograms;
}

@end

@implementation AdminTrainingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 960.0f;
    [scrView setContentSize:scrSize];
    
    arrayPrograms = [[NSMutableArray alloc] init];
    unUsedProgramsArray = [[NSMutableArray alloc] init];
    selectedPrograms = [[NSMutableArray alloc] init];
    
    programSelectView.hidden = YES;
    selectedProgramDialogView.autoresizesSubviews = NO;
    selectedProgramDialogView.contentMode = UIViewContentModeRedraw;
    selectedProgramDialogView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    selectedProgramDialogView.layer.shadowRadius = 3.0f;
    selectedProgramDialogView.layer.shadowOpacity = 1.0f;
    selectedProgramDialogView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    selectedProgramDialogView.layer.shadowPath = [UIBezierPath bezierPathWithRect:selectedProgramDialogView.bounds].CGPath;
    selectedProgramDialogView.layer.cornerRadius = 5.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
- (void)deviceOrientationDidChange{
    [scrView setContentSize:CGSizeMake(scrView.frame.size.width, 960.0f)];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"AdminTrainingViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [self getPrograms];
}
- (void)getPrograms{
    [MBProgressHUD hideHUDForView:[AppDelegate sharedDelegate].window animated:YES];
    [arrayPrograms removeAllObjects];
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
            if (group.parentGroup == nil && [group.ableByAdmin integerValue] == 1) {
                BOOL isExist = NO;
                for (int i = 0; i < arrayPrograms.count; i++) {
                    id oneElement = [arrayPrograms objectAtIndex:i];
                    if ([oneElement isMemberOfClass:[LessonGroup class]]) {
                        LessonGroup *lesGroupToCheck = oneElement;
                        if ([group.name.lowercaseString isEqualToString:lesGroupToCheck.name.lowercaseString]) {
                            isExist = YES;
                            break;
                        }
                    }
                }
                if (!isExist) {
                    [arrayPrograms addObject:group];
                }
                
            }
        }
    }
    
    [ProgramsTableView reloadData];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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
    if (tableView == unUsedProgramsTableView) {
        return [unUsedProgramsArray count];
    }
    return [arrayPrograms count];
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    if (tableView == ProgramsTableView) {
        [view addSubview:addProgramView];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (tableView == ProgramsTableView) {
        return 50.0f;
    }
    
    return 0.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == unUsedProgramsTableView) {
        return 44.0f;
    }
    return 38.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == unUsedProgramsTableView) {
        static NSString *sortTableViewIdentifier = @"unusedProgramItem";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sortTableViewIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:sortTableViewIdentifier];
        }
        LessonGroup *lessonGroup = [unUsedProgramsArray objectAtIndex:indexPath.row];
        cell.textLabel.text =lessonGroup.name;
        if ([selectedPrograms containsObject:lessonGroup]) {
            cell.backgroundColor = [UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f];
        }else{
            cell.backgroundColor = [UIColor clearColor];
        }
        return cell;
    }
    id rowElement = [arrayPrograms objectAtIndex:indexPath.row];
    
    static NSString *simpleTableIdentifier = @"ProgramItem";
    ProgramCell *cell = (ProgramCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [ProgramCell sharedCell];
    }
    LessonGroup *lessonGroup = rowElement;
    cell.lblProgramTitle.text = lessonGroup.name;
    
    return cell;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == unUsedProgramsTableView) {
        LessonGroup *lessonGroup = [unUsedProgramsArray objectAtIndex:indexPath.row];
        if ([selectedPrograms containsObject:lessonGroup]) {
            [selectedPrograms removeObject:lessonGroup];
        }else{
            [selectedPrograms addObject:lessonGroup];
        }
        [unUsedProgramsTableView reloadData];
    }else{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        id rowElement = [arrayPrograms objectAtIndex:indexPath.row];
        if([rowElement isMemberOfClass:[LessonGroup class]]) {
            //LessonGroup *lessonGroup = rowElement;
        }else{
        }
    }
}

- (IBAction)onAddPrograms:(id)sender {
    programSelectView.hidden = NO;
    
    //get unused programs from local
    [unUsedProgramsArray removeAllObjects];
    [selectedPrograms removeAllObjects];
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
            if (group.parentGroup == nil && [group.ableByAdmin integerValue] == 0) {
                BOOL isExist = NO;
                for (int i = 0; i < unUsedProgramsArray.count; i++) {
                    id oneElement = [unUsedProgramsArray objectAtIndex:i];
                    if ([oneElement isMemberOfClass:[LessonGroup class]]) {
                        LessonGroup *lesGroupToCheck = oneElement;
                        if ([group.name.lowercaseString isEqualToString:lesGroupToCheck.name.lowercaseString]) {
                            isExist = YES;
                            break;
                        }
                    }
                }
                if (!isExist) {
                    [unUsedProgramsArray addObject:group];
                }
                
            }
        }
    }
    
    [unUsedProgramsTableView reloadData];
    
    selectedProgramDialogView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        selectedProgramDialogView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}

- (IBAction)onCancel:(id)sender {
    programSelectView.hidden = YES;
}

- (IBAction)onDone:(id)sender {
    if (selectedPrograms.count > 0) {
        NSError *error;
        NSMutableArray *arrayGroupIDs = [[NSMutableArray alloc] init];
        for (LessonGroup *lessongroup in selectedPrograms) {
            [arrayGroupIDs addObject:lessongroup.groupID];
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"update_lessongroups_admin", @"action", [AppDelegate sharedDelegate].userId, @"user_id", arrayGroupIDs, @"group_ids", nil];
        NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveLessonsRequest setHTTPMethod:@"POST"];
        [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                NSError *error;
                // parse the query results
                NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil) {
                    NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                    return;
                }
                if ([[queryResults objectForKey:@"success"] boolValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                        for (LessonGroup *lessongroup in selectedPrograms) {
                            lessongroup.ableByAdmin = @(1);
                        }
                        NSError *error;
                        [context save:&error];
                        programSelectView.hidden = YES;
                        [ProgramsTableView reloadData];
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Incorrect verification code, Please try again" :@"Failed!"] ;
                    });
                }
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading queries";
                }
                FDLogError(@"%@", errorText);
            }
        }];
        [uploadLessonRecordsTask resume];
    }
}
@end
