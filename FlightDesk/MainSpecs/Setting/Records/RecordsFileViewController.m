//
//  RecordsFileViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//
#define kScreenSize           [[UIScreen mainScreen] bounds].size
#define kScreenWidth          [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight         [[UIScreen mainScreen] bounds].size.height

#import "RecordsFileViewController.h"
#import "RecordsUsersCell.h"
#import "UIImage+Resize.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "RecordsFileCell.h"
#import "KNWaterflowLayout.h"
#import "UIImageView+WebCache.h"
#import "KNPhotoBrower.h"

#import "PhotoTweaksViewController.h"


#import "UIImage+animatedGIF.h"

#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define COLOR_BUTTON_BLUE RGBA(16, 114, 189, 1)

@implementation UploadFileInfo
@synthesize urlRequest;
@synthesize uploadTask;
@synthesize currentCell;
@synthesize recordsFile;

- (id)initWithCoreDataRecordsFile:(RecordsFile *)record{
    self = [super init];
    if (self) {
        urlRequest = nil;
        uploadTask = nil;
        currentCell = nil;
        recordsFile = record;
    }
    return self;
}
@end

@interface RecordsFileViewController ()<UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UICollectionViewDelegate,UICollectionViewDataSource, KNWaterflowLayoutDelegate,KNPhotoBrowerDelegate, RecordsFileCellDelegate, UIDocumentPickerDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, PhotoTweaksViewControllerDelegate>
{
    NSLock *uploadTasksLock;
    NSMutableDictionary *uploadTasksWithLocalID;
    NSMutableDictionary *uploadFileInfosWithUploadTask;
    NSURLSession *backgroundSession;
    NSMutableArray *recordsFilesArray;
    NSMutableDictionary *uploadFileInfoWithLocalID;
    
    NSMutableArray *usersArray;
    BOOL isDeleteMode;
    
    NSString *imageNameToUpload;
    NSNumber *currentSelectedStudentID;
    
    NSMutableArray *itemsArr;
    NSMutableArray *tempArr;
    NSMutableArray *collectionPrepareArr;
    BOOL     _ApplicationStatusIsHidden;
    
    NSMutableArray *selectedThumbViews;
    
    //re-naming spec
    UIView *coverViewForRenameText;
    UITextField *tmptext;
    UIView *renameTxtDialog;
    UIView *tmpCV;
    UITextField *lblRenameView;
    UIImageView *gradiantImageView;
    NSInteger indexToEdit;
    RecordsFile *currentSelectedrecordsFile;
    
    MBProgressHUD *downloadProgressHUD;
    
    NSNumber *currentRecordsLocalIdToUpload;
    
    NSInteger imageType;
    NSURL *currentTempImageUrl;
    
    NSURL *currentTempFileUrl;
    NSString *currentRemoteTempUrl;
    NSString *currentTempType;
}
@end

@implementation RecordsFileViewController

@synthesize playerVC;
- (void)viewDidLoad {
    [super viewDidLoad];
    usersArray = [[NSMutableArray alloc] init];
    recordsFilesArray = [[NSMutableArray alloc] init];
    itemsArr = [[NSMutableArray alloc] init];
    tempArr = [[NSMutableArray alloc] init];
    collectionPrepareArr = [[NSMutableArray alloc] init];
    selectedThumbViews = [[NSMutableArray alloc] init];
    recordsFileCV.hidden = YES;
    isDeleteMode = NO;
    
    uploadFileInfoWithLocalID = [[NSMutableDictionary alloc] init];
    uploadTasksWithLocalID = [[NSMutableDictionary alloc] init];
    uploadFileInfosWithUploadTask = [[NSMutableDictionary alloc] init];
    uploadTasksLock = [[NSLock alloc] init];
    backgroundSession = nil;
    
    [[SDWebImageManager sharedManager].imageCache clearMemory];
    
    UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnDeleteRecords setImage:btnEditImage forState:UIControlStateNormal];
    btnDeleteRecords.tintColor = COLOR_BUTTON_BLUE;
    
    UIImage *btnAddImage = [[UIImage imageNamed:@"addbtn"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnAddRecords setImage:btnAddImage forState:UIControlStateNormal];
    btnAddRecords.tintColor = COLOR_BUTTON_BLUE;
    
    lblMyName.text = [NSString stringWithFormat:@"%@ %@ %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientMiddleName, [AppDelegate sharedDelegate].clientLastName];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        lblTableTitle.text = @"USERS";
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        lblTableTitle.text = @"STUDENTS";
    }else{
        studentsView.hidden = YES;
        lblTableTitle.text = @"";
    }
    imageNameToUpload = @"";
    currentSelectedStudentID = @0;
    
    KNWaterflowLayout *waterFlowLayout = [[KNWaterflowLayout alloc] init];
    [waterFlowLayout setDelegate:self];
    
    RecordsCollectionView.collectionViewLayout = waterFlowLayout;
    [RecordsCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([RecordsFileCell class]) bundle:nil] forCellWithReuseIdentifier:@"RecordsFileItem"];
    
    //show selected files
    vwCoverOfWebView.hidden = YES;
    [webView  setScalesPageToFit:YES];
    
    UITapGestureRecognizer *tapGestureToWebView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverOfWebView)];
    [vwCoverOfWebView addGestureRecognizer:tapGestureToWebView];
    
    [self initViewForRenaming];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"RecordsFileViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        [self getUserInfo];
    }else{
        
    }
    
    [self reloadViewsForRenaming];
    [[AppDelegate sharedDelegate] startThreadToSyncData:7];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[SDWebImageManager sharedManager].imageCache clearMemory];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:7];
    
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [self reloadViewsForRenaming];
}
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if (indexToEdit != -1) {
        [[AppDelegate sharedDelegate] startThreadToSyncData:7];
        [coverViewForRenameText removeFromSuperview];
        indexToEdit = -1;
        [RecordsCollectionView reloadData];
    }
}
- (void)initViewForRenaming{
    indexToEdit = -1;
    coverViewForRenameText = [[UIView alloc] initWithFrame:self.view.frame];
    [coverViewForRenameText setBackgroundColor:[UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:0.5f]];
    renameTxtDialog = [[UIView alloc] initWithFrame:CGRectMake((coverViewForRenameText.frame.size.width-350.0f)/2, coverViewForRenameText.frame.size.height-500.0f, 350.0f, 80.0f)];
    renameTxtDialog.autoresizesSubviews = NO;
    renameTxtDialog.contentMode = UIViewContentModeRedraw;
    renameTxtDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    renameTxtDialog.backgroundColor = [UIColor whiteColor];
    renameTxtDialog.layer.shadowRadius = 3.0f;
    renameTxtDialog.layer.shadowOpacity = 1.0f;
    renameTxtDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    renameTxtDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:renameTxtDialog.bounds].CGPath;
    renameTxtDialog.layer.cornerRadius = 5.0f;
    
    tmpCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 35)];
    [renameTxtDialog addSubview:tmpCV];
    gradiantImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tmpCV.frame.size.width, tmpCV.frame.size.height)];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:229.0f/255.0f green:45.0f/255.0f blue:39.0f/2551.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:179.0f/255.0f green:18.0f/255.0f blue:23.0f/255.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [gradiantImageView setImage:gradientImage];
    [tmpCV addSubview:gradiantImageView];
    
    lblRenameView = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 40)];
    lblRenameView.text = @"Please rename current file in here.";
    lblRenameView.textAlignment = NSTextAlignmentCenter;
    lblRenameView.textColor = [UIColor whiteColor];
    [tmpCV addSubview:lblRenameView];
    
    tmptext = [[UITextField alloc] initWithFrame:CGRectMake(5, 40, renameTxtDialog.frame.size.width-10, 35)];
    tmptext.delegate = self;
    tmptext.textAlignment = NSTextAlignmentCenter;
    tmptext.font = [UIFont systemFontOfSize:13.0f];
    tmptext.textColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
    tmptext.backgroundColor = [UIColor whiteColor];
    tmptext.layer.cornerRadius = 5.0f;
    tmptext.layer.borderColor = [UIColor blackColor].CGColor;
    tmptext.layer.borderWidth = 1.0f;
    [renameTxtDialog addSubview:tmptext];
    
    [coverViewForRenameText addSubview:renameTxtDialog];
    
    UITapGestureRecognizer *tapGestureToPreViewImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCoverViewForRemaing)];
    [coverViewForRenameText addGestureRecognizer:tapGestureToPreViewImage];

}

-(void)tapCoverViewForRemaing
{
    [self.view endEditing:YES];
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Do you want to change current file's name?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        if (currentSelectedrecordsFile.records_id != nil && tmptext.text.length > 0) {
            [[AppDelegate sharedDelegate] startThreadToSyncData:7];
            [coverViewForRenameText removeFromSuperview];
            currentSelectedrecordsFile.file_name = tmptext.text;
            currentSelectedrecordsFile.lastUpdate = @(0);
            indexToEdit = -1;
            [RecordsCollectionView reloadData];
            [context save:&error];
        }
    }];
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        [[AppDelegate sharedDelegate] startThreadToSyncData:7];
        [coverViewForRenameText removeFromSuperview];
        tmptext.text = @"";
        indexToEdit = -1;
        [RecordsCollectionView reloadData];
    }];
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)reloadViewsForRenaming{
    [coverViewForRenameText setFrame:self.view.frame];
    [coverViewForRenameText setBackgroundColor:[UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:0.5f]];
    [renameTxtDialog setFrame:CGRectMake((coverViewForRenameText.frame.size.width-350.0f)/2, coverViewForRenameText.frame.size.height-500.0f, 350.0f, 80.0f)];
    [tmpCV setFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 35)];
    [gradiantImageView setFrame:CGRectMake(0, 0, tmpCV.frame.size.width, tmpCV.frame.size.height)];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:229.0f/255.0f green:45.0f/255.0f blue:39.0f/2551.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:179.0f/255.0f green:18.0f/255.0f blue:23.0f/255.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIGraphicsEndImageContext();
    [gradiantImageView setImage:gradientImage];
    [lblRenameView setFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 40)];
    [tmptext setFrame:CGRectMake(5, 40, renameTxtDialog.frame.size.width-10, 35)];
    
}
- (void)reloadUsersAndFiles{
    if (recordsFileCV.hidden == YES) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
            [self getUserInfo];
        }else{
            
        }
    }else{
        [self getRecrodsFileFromUserID:currentSelectedStudentID];
    }
}
- (void)getUserInfo{
    [usersArray removeAllObjects];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Users" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Users!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Users found!");
    } else {
        NSMutableArray *tempUsers= [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedUsers = [tempUsers sortedArrayUsingDescriptors:sortDescriptors];
        for (Users *users in sortedUsers) {
            BOOL isExit = NO;
            for (Users *userToCheck in usersArray) {
                if ([userToCheck.userID integerValue] == [users.userID integerValue]) {
                    isExit = YES;
                    break;
                }
            }
            if (!isExit) {
                [usersArray addObject:users];
            }
        }
        [UsersTableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [usersArray count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"RecordsUsersItem";
    RecordsUsersCell *cell = (RecordsUsersCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [RecordsUsersCell sharedCell];
    }
    Users *userInfo = [usersArray objectAtIndex:indexPath.row];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        cell.lblUserName.text = [NSString stringWithFormat:@"%@ %@ %@ (%@)",userInfo.firstName,userInfo.middleName,userInfo.lastName,userInfo.level];
    }else{
        cell.lblUserName.text = [NSString stringWithFormat:@"%@ %@ %@",userInfo.firstName,userInfo.middleName,userInfo.lastName];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Users *userInfo = [usersArray objectAtIndex:indexPath.row];
    [self getRecrodsFileFromUserID:userInfo.userID];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        userNameLbl.text = [NSString stringWithFormat:@"%@ %@ %@ (%@)",userInfo.firstName,userInfo.middleName,userInfo.lastName,userInfo.level];
    }else{
        userNameLbl.text = [NSString stringWithFormat:@"%@ %@ %@",userInfo.firstName,userInfo.middleName,userInfo.lastName];
    }
    recordsFileCV.hidden = NO;
    recordsFileDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        recordsFileDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}
- (void)getRecrodsFileFromUserID:(NSNumber *)userId{
    currentSelectedStudentID = userId;
    [recordsFilesArray removeAllObjects];
    [collectionPrepareArr removeAllObjects];
    [itemsArr removeAllObjects];
    [tempArr removeAllObjects];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user_id == %@ AND student_id == %@",[NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]], userId];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve RecordsFile!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid RecordsFile found!");
    } else {
        NSMutableArray *tempRecordsFies = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"records_id" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedRecordsFiles = [tempRecordsFies sortedArrayUsingDescriptors:sortDescriptors];
        BOOL ableUploaded = NO;
        for (RecordsFile *recordsFile in objects) {
            if ([recordsFile.isUploaded integerValue] == 0) {
                ableUploaded = YES;
            }
            UploadFileInfo *uploadFileInfo = [uploadFileInfoWithLocalID objectForKey:recordsFile.recordsLocal_id];
            if (uploadFileInfo == nil) {
                uploadFileInfo = [[UploadFileInfo alloc] initWithCoreDataRecordsFile:recordsFile];
                [uploadFileInfoWithLocalID setObject:uploadFileInfo forKey:recordsFile.recordsLocal_id];
            }
            uploadFileInfo.recordsFile = recordsFile;
            [recordsFilesArray addObject:uploadFileInfo];
            
            //if ([recordsFile.fileType isEqualToString:@"image"]) {
                KNPhotoItems *items = [[KNPhotoItems alloc] init];
                items.url = recordsFile.file_url;
                items.sourceView = nil;
                items.itemType =recordsFile.fileType;
                [collectionPrepareArr addObject:items];
            //}
        }
        if (ableUploaded) {
            [[AppDelegate sharedDelegate] stopThreadToSyncData:7];
        }else{
            [[AppDelegate sharedDelegate] startThreadToSyncData:7];
        }
    }
    [RecordsCollectionView reloadData];
}
- (IBAction)onDeleteRecordsFile:(id)sender {
    if (!isDeleteMode) {
        isDeleteMode = YES;
        UIImage *btnEditImage = [[UIImage imageNamed:@"delete_doc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [btnDeleteRecords setImage:btnEditImage forState:UIControlStateNormal];
        btnDeleteRecords.tintColor = COLOR_BUTTON_BLUE;
        [RecordsCollectionView reloadData];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete the selected document(s)?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            [self deleteRecordsToBeSelected];
            
            isDeleteMode = NO;
            UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [btnDeleteRecords setImage:btnEditImage forState:UIControlStateNormal];
            btnDeleteRecords.tintColor = COLOR_BUTTON_BLUE;
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
            
        }];
        [alert addAction:cancel];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}
- (void)deleteRecordsToBeSelected{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    for (RecordsFile *recordsFileToDelete in selectedThumbViews) {
        DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
        deleteQueryForAssignment.type = @"RecordsFiles";
        deleteQueryForAssignment.idToDelete = recordsFileToDelete.records_id;
        
        [context deleteObject:recordsFileToDelete];
        [context save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
    }
    
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [selectedThumbViews removeAllObjects];
    [self getRecrodsFileFromUserID:currentSelectedStudentID];
}
- (IBAction)onAddRecordsFile:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionTakeProfilePhoto = [UIAlertAction actionWithTitle:@"Take Document Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //imgPicker.allowsEditing = YES;
        imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4, (NSString*)kUTTypeImage, (NSString*)kUTTypePNG, (NSString*)kUTTypeJPEG, (NSString*)kUTTypeJPEG2000, nil];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }];
    UIAlertAction* actionChooseFromLib = [UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //imgPicker.allowsEditing = YES;
        imgPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4, (NSString*)kUTTypeImage, (NSString*)kUTTypePNG, (NSString*)kUTTypeJPEG, (NSString*)kUTTypeJPEG2000];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
        
    }];
    UIAlertAction* actionChooseFromDoc = [UIAlertAction actionWithTitle:@"Choose from Document" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]                                                                                                                inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:documentPicker animated:YES completion:nil];
        
        UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:documentPicker];
        [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
        [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionTakeProfilePhoto];
    [alert addAction:actionChooseFromLib];
    [alert addAction:actionChooseFromDoc];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = btnAddRecords;
    popPresenter.sourceRect = btnAddRecords.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)presentPhotoTweaksView:(UIImage *)image{
    PhotoTweaksViewController *photoTweaksViewController = [[PhotoTweaksViewController alloc] initWithImage:image];
    photoTweaksViewController.delegate = self;
    photoTweaksViewController.autoSaveToLibray = NO;
    photoTweaksViewController.maxRotationAngle = M_PI_2;
    [self presentViewController:photoTweaksViewController animated:YES completion:nil];
}
#pragma mark UIDocumentPickerDelgate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    NSString *fileName = [url lastPathComponent];
    imageNameToUpload = fileName;
    NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
    NSError* error = nil;
    NSURLResponse* response = nil;
    [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
    NSString* mimeType = [response MIMEType];
    NSArray *parseFileName = [mimeType componentsSeparatedByString:@"/"];
    if (parseFileName.count > 1) {
        NSString *lastString = parseFileName[parseFileName.count-1];
        NSInteger fileType = 0;
        //1: image, 2: tif, 3:gif, 4:video, 5:pdf, 6:txt/doc, 7:ppt/pptx 8: other
        if ([lastString.lowercaseString isEqualToString:@"png"] || [lastString.lowercaseString isEqualToString:@"jpg"] || [lastString.lowercaseString isEqualToString:@"jpeg"] || [lastString.lowercaseString isEqualToString:@"bmp"]) {
            fileType = 1;
        }else if([lastString.lowercaseString isEqualToString:@"tif"] || [lastString.lowercaseString isEqualToString:@"tiff"]){
            fileType = 2;
        }else if ([lastString.lowercaseString isEqualToString:@"gif"]){
            fileType = 3;
        }else if([lastString.lowercaseString isEqualToString:@"mov"] || [lastString.lowercaseString isEqualToString:@"avi"] || [lastString.lowercaseString isEqualToString:@"mp4"]){
            fileType = 4;
        }else if ([lastString.lowercaseString isEqualToString:@"pdf"]){
            fileType = 5;
        }else if ([lastString.lowercaseString isEqualToString:@"txt"] || [lastString.lowercaseString isEqualToString:@"doc"]){
            fileType = 6;
        }else if ([lastString.lowercaseString isEqualToString:@"ppt"] || [lastString.lowercaseString isEqualToString:@"pptx"]){
            fileType = 7;
        }else {
            fileType = 8;
        }
        
        switch (fileType) {
            case 1://jpeg, jpg, png, bmp
            {
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
                imageNameToUpload = [url lastPathComponent];
                
                imageType = 1;
                currentTempImageUrl = url;
                [self presentPhotoTweaksView:[UIImage imageWithData:imageData]];
                break;
            }
            case 2://TIF, TIFF file
            {
                
                UIImage *thumbnailImage = [self generateThumbImageOfTif:url];
                imageType = 2;
                currentTempFileUrl = url;
                currentTempType = @"tif";
                [self presentPhotoTweaksView:thumbnailImage];
                break;
            }
            case 3://gif
            {
                UIImage *thumbnailImage = [self generateThumbImageOfGif:url];
                imageType = 2;
                currentTempFileUrl = url;
                currentTempType = @"gif";
                [self presentPhotoTweaksView:thumbnailImage];
                break;
            }
            case 4://video
            {
                UIImage *thumbnailImage = [self generateThumbImageOfVideo:url];
                imageType = 2;
                currentTempFileUrl = url;
                currentTempType = @"video";
                [self presentPhotoTweaksView:thumbnailImage];
                break;
            }
            case 5://pdf
            {
                UIImage *thumbnailImage = [self generateThumbImageOfPdf:url];
                imageType = 2;
                currentTempFileUrl = url;
                currentTempType = @"pdf";
                [self presentPhotoTweaksView:thumbnailImage];
                break;
            }
            case 6://txt & doc
            {
                [self uploadFile:url withType:@"text" withThumbImage:nil];
                break;
            }
            case 7://ppt & pptx
            {
                [self uploadFile:url withType:@"ppt" withThumbImage:nil];
                break;
            }
            case 8://other
            {
                [self uploadFile:url withType:@"other" withThumbImage:nil];
                break;
            }
            default:
                break;
        }
        
    }
    
}
#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    imageNameToUpload = [NSString stringWithFormat:@"Camera%.f.jpg",[[NSDate date] timeIntervalSince1970] * 1000000];
    if ([[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeAVIMovie] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeVideo] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMPEG4]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        imageNameToUpload = [videoURL lastPathComponent];
        [picker dismissViewControllerAnimated:YES completion:^(void){
            UIImage *thumbnailImage = [self generateThumbImageOfVideo:videoURL];
            imageType = 2;
            currentTempFileUrl = videoURL;
            currentTempType = @"video";
            [self presentPhotoTweaksView:thumbnailImage];
        }];
    }else{
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        if (![UIImageJPEGRepresentation(image, 0.5f) writeToFile:[NSTemporaryDirectory() stringByAppendingString:@"/image.jpg"] atomically:YES]) {
            [self showAlert:@"Failed to save information. Please try again." title:@"Error"];
            return;
        }
        NSURL *imagePathToGet = [info objectForKey:UIImagePickerControllerReferenceURL];
        NSString *imageNameToGet = [imagePathToGet lastPathComponent];
        if (imageNameToGet && ![imageNameToGet isEqualToString:@""]) {
            imageNameToUpload = imageNameToGet;
        }
        
        imageType = 1;
        PhotoTweaksViewController *photoTweaksViewController = [[PhotoTweaksViewController alloc] initWithImage:image];
        photoTweaksViewController.delegate = self;
        photoTweaksViewController.autoSaveToLibray = NO;
        photoTweaksViewController.maxRotationAngle = M_PI_2;
        [picker pushViewController:photoTweaksViewController animated:YES];
    }
}
#pragma mark PhotoTweaksViewController
- (void)photoTweaksController:(PhotoTweaksViewController *)controller didFinishWithCroppedImage:(UIImage *)croppedImage
{
    NSURL *imageUrl;
    NSData *imageData = UIImageJPEGRepresentation(croppedImage,0.2);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%.f%@", [[NSDate date] timeIntervalSince1970] * 1000000, imageNameToUpload]];
    if (imageType == 2){
        imagePath =[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"thmub%.f.jpg", [[NSDate date] timeIntervalSince1970] * 1000000]];
    }
    if (![imageData writeToFile:imagePath atomically:NO])
    {
        NSLog(@"Failed to cache image data to disk");
    }
    
    imageUrl = [NSURL URLWithString:imagePath];
    
    if (imageType == 1) {
        [self uploadPhoto:imageUrl];
    }else if (imageType == 2){
        [self uploadFile:currentTempFileUrl withType:currentTempType withThumbImage:imageUrl];
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
    // cropped image
}
- (void)photoTweaksControllerDidCancel:(PhotoTweaksViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
- (void)uploadPhoto:(NSURL *)photoUrl{
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[photoUrl path]];
//    if (imageData != nil)
//    {
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        /*
         NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
        
        NSURL *saveURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [photoUrl lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:imageData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];    */
        
        
        // save tmp Records on local
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        RecordsFile *recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
        recordsFile.records_id = @0;
        recordsFile.recordsLocal_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        recordsFile.file_url = [NSString stringWithFormat:@"%@/%@/figureimages/%@",serverName, webAppDir, [photoUrl lastPathComponent]];
        recordsFile.local_url = [photoUrl path];
        recordsFile.file_name = imageNameToUpload;
        recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
        recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        recordsFile.lastUpdate = @0;
        recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
        recordsFile.student_id = currentSelectedStudentID;
        recordsFile.fileType = @"image";
        recordsFile.thumb_url = @"";
        recordsFile.isUploaded = @0;
        NSError *error;
        [context save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
        [self getRecrodsFileFromUserID:currentSelectedStudentID];
        //////////////////////////////////
        /*
        UploadFileInfo *uploadFileInfo = [[UploadFileInfo alloc] initWithCoreDataRecordsFile:recordsFile];
        uploadFileInfo.urlRequest = request;
        
        // now lets make the connection to the web
        if (backgroundSession == nil) {
            backgroundSession = [NSURLSession sharedSession];
            backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
        }
        uploadFileInfo.uploadTask = [backgroundSession dataTaskWithRequest:uploadFileInfo.urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                        NSError *error;
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
                        [request setEntity:entityDescription];
                        // all lesson records with lastUpdate == 0 need to be uploaded
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", currentRecordsLocalIdToUpload];
                        [request setPredicate:predicate];
                        NSArray *fetchedRecordsFile = [context executeFetchRequest:request error:&error];
                        RecordsFile *recordsFile = nil;
                        if (fetchedRecordsFile.count == 0) {
                            recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
                            recordsFile.records_id = @0;
                            recordsFile.file_url = [queryResults objectForKey:@"imageurl"];
                            recordsFile.file_name = imageNameToUpload;
                            recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
                            recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            recordsFile.lastUpdate = @0;
                            recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                            recordsFile.student_id = currentSelectedStudentID;
                            recordsFile.fileType = @"image";
                            recordsFile.thumb_url = @"";
                            recordsFile.isUploaded = @1;
                        }else if(fetchedRecordsFile.count == 1){
                            recordsFile = fetchedRecordsFile[0];
                            recordsFile.records_id = @0;
                            recordsFile.file_url = [queryResults objectForKey:@"imageurl"];
                            recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                            recordsFile.lastUpdate = @0;
                            recordsFile.isUploaded = @1;
                        }
                        
                        [context save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                        [self getRecrodsFileFromUserID:currentSelectedStudentID];
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Please try again" title:@"Failed!"] ;
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
                
                UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:errorText preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    NSLog(@"you pressed Yes, please button");
                }];
                [alert addAction:yesButton];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
        [uploadFileInfo.uploadTask resume];
        
        [uploadTasksLock lock];
        [uploadTasksWithLocalID setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
        [uploadTasksLock unlock];
         */
}

/*- (void)uploadPhoto:(NSURL *)photoUrl{
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[photoUrl path]];
    //    if (imageData != nil)
    //    {
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
 
     NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
     
     NSURL *saveURL = [NSURL URLWithString:apiURLString];
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
     [request setHTTPMethod:@"POST"];
     
     NSString *boundary = @"---------------------------14737809831466499882746641449";
     NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
     [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
     
     NSMutableData *body = [NSMutableData data];
     
     [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
     
     [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [photoUrl lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
     
     [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
     [body appendData:[NSData dataWithData:imageData]];
     [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
     // setting the body of the post to the reqeust
     [request setHTTPBody:body];
    
    
    // save tmp Records on local
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    RecordsFile *recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
    recordsFile.records_id = @0;
    recordsFile.recordsLocal_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    recordsFile.file_url = [NSString stringWithFormat:@"%@/%@/figureimages/%@",serverName, webAppDir, [photoUrl lastPathComponent]];
    recordsFile.local_url = [photoUrl path];
    recordsFile.file_name = imageNameToUpload;
    recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
    recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    recordsFile.lastUpdate = @0;
    recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    recordsFile.student_id = currentSelectedStudentID;
    recordsFile.fileType = @"image";
    recordsFile.thumb_url = @"";
    recordsFile.isUploaded = @0;
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self getRecrodsFileFromUserID:currentSelectedStudentID];
    //////////////////////////////////
     UploadFileInfo *uploadFileInfo = [[UploadFileInfo alloc] initWithCoreDataRecordsFile:recordsFile];
     uploadFileInfo.urlRequest = request;
     
     // now lets make the connection to the web
     if (backgroundSession == nil) {
     backgroundSession = [NSURLSession sharedSession];
     backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
     }
     uploadFileInfo.uploadTask = [backgroundSession dataTaskWithRequest:uploadFileInfo.urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
     NSError *error;
     NSFetchRequest *request = [[NSFetchRequest alloc] init];
     NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
     [request setEntity:entityDescription];
     // all lesson records with lastUpdate == 0 need to be uploaded
     NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", currentRecordsLocalIdToUpload];
     [request setPredicate:predicate];
     NSArray *fetchedRecordsFile = [context executeFetchRequest:request error:&error];
     RecordsFile *recordsFile = nil;
     if (fetchedRecordsFile.count == 0) {
     recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
     recordsFile.records_id = @0;
     recordsFile.file_url = [queryResults objectForKey:@"imageurl"];
     recordsFile.file_name = imageNameToUpload;
     recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
     recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
     recordsFile.lastUpdate = @0;
     recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
     recordsFile.student_id = currentSelectedStudentID;
     recordsFile.fileType = @"image";
     recordsFile.thumb_url = @"";
     recordsFile.isUploaded = @1;
     }else if(fetchedRecordsFile.count == 1){
     recordsFile = fetchedRecordsFile[0];
     recordsFile.records_id = @0;
     recordsFile.file_url = [queryResults objectForKey:@"imageurl"];
     recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
     recordsFile.lastUpdate = @0;
     recordsFile.isUploaded = @1;
     }
     
     [context save:&error];
     if (error) {
     NSLog(@"Error when saving managed object context : %@", error);
     }
     [self getRecrodsFileFromUserID:currentSelectedStudentID];
     });
     
     }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
     dispatch_async(dispatch_get_main_queue(), ^{
     [ self  showAlert: @"Please try again" title:@"Failed!"] ;
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
     
     UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:errorText preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
     NSLog(@"you pressed Yes, please button");
     }];
     [alert addAction:yesButton];
     [self presentViewController:alert animated:YES completion:nil];
     }
     }];
     [uploadFileInfo.uploadTask resume];
     
     [uploadTasksLock lock];
     [uploadTasksWithLocalID setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
     [uploadTasksLock unlock];
}
*/
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}
- (void)uploadFile:(NSURL *)fileUrl withType:(NSString *)type withThumbImage:(NSURL *)thumbLocalUrl{
    imageNameToUpload = [fileUrl lastPathComponent];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    
    NSURL *fileLocalUrl;
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath =[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%.f%@", [[NSDate date] timeIntervalSince1970] * 1000000, [fileUrl lastPathComponent]]];
    if (![fileData writeToFile:filePath atomically:NO])
    {
        NSLog(@"Failed to cache data to disk");
    }
    
    fileLocalUrl = [NSURL URLWithString:filePath];
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    RecordsFile *recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
    recordsFile.records_id = @0;
    currentRecordsLocalIdToUpload = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    recordsFile.recordsLocal_id = currentRecordsLocalIdToUpload;
    recordsFile.file_url = [NSString stringWithFormat:@"%@/%@/videos/file%.f%@",serverName, webAppDir, [[NSDate date] timeIntervalSince1970] * 1000000, imageNameToUpload];
    recordsFile.local_url = [fileLocalUrl path];
    recordsFile.file_name = imageNameToUpload;
    if (thumbLocalUrl != nil) {
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[thumbLocalUrl path]];
        if (image) {
            recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
        }else{
            recordsFile.fileSize = @"1024:1024";
        }
    }else{
        recordsFile.fileSize = @"1024:1024";
    }
    recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    recordsFile.lastUpdate = @0;
    recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    recordsFile.student_id = currentSelectedStudentID;
    recordsFile.fileType = type;
    recordsFile.thumb_url = @"";
    if (thumbLocalUrl != nil) {
        recordsFile.thumb_url = [NSString stringWithFormat:@"%@/%@/figureimages/%@",serverName, webAppDir, [thumbLocalUrl lastPathComponent]];
    }
    recordsFile.isUploaded = @0;
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self getRecrodsFileFromUserID:currentSelectedStudentID];
    //////////////////////////////////
}
/*- (void)uploadFile:(NSURL *)fileUrl withType:(NSString *)type withThumbImage:(NSURL *)thumbLocalUrl{
    [[AppDelegate sharedDelegate] stopThreadToSyncData:7];
    imageNameToUpload = [fileUrl lastPathComponent];
    NSString *filePath = fileUrl.absoluteString;
    NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
    if (fileData != nil) {
            // save tmp Records on local
            UIImage *thumbnailImage = nil;
            if ([type isEqualToString:@"video"]) {
                thumbnailImage = [self generateThumbImageOfVideo:fileUrl];
            }else if([type isEqualToString:@"pdf"]){
                thumbnailImage = [self generateThumbImageOfPdf:fileUrl];
            }else if([type isEqualToString:@"gif"]){
                thumbnailImage = [self generateThumbImageOfGif:fileUrl];
            }else if([type isEqualToString:@"tif"]){
                thumbnailImage = [self generateThumbImageOfTif:fileUrl];
            }
            
            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            RecordsFile *recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
            recordsFile.records_id = @0;
            currentRecordsLocalIdToUpload = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            recordsFile.recordsLocal_id = currentRecordsLocalIdToUpload;
            recordsFile.file_url = fileUrl.absoluteString;
            recordsFile.file_name = imageNameToUpload;
            if (thumbnailImage != nil) {
                recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", thumbnailImage.size.width, thumbnailImage.size.height];
            }else{
                recordsFile.fileSize = @"1024:1024";
            }
            recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            recordsFile.lastUpdate = @0;
            recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
            recordsFile.student_id = currentSelectedStudentID;
            recordsFile.fileType = type;
            recordsFile.thumb_url = @"";
            recordsFile.isUploaded = @0;
            NSError *error;
            [context save:&error];
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
            [self getRecrodsFileFromUserID:currentSelectedStudentID];
            //////////////////////////////////
        
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_video.php", serverName, webAppDir];
        
        NSURL *saveURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *fileName =[NSString stringWithFormat:@"%@_%.f_%@",type, [[NSDate date] timeIntervalSince1970] * 1000000, [fileUrl lastPathComponent]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:fileData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];
        // now lets make the connection to the web
        if (backgroundSession == nil) {
            backgroundSession = [NSURLSession sharedSession];
            backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
        }
        
        NSURLSessionDataTask *uploadVideoTask = [backgroundSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                        
                        NSString *currentUrl = [queryResults objectForKey:@"videoUrl"];
                        if ([type isEqualToString:@"video"] || [type isEqualToString:@"pdf"] || [type isEqualToString:@"gif"] || [type isEqualToString:@"tif"]) {
                            
                            [self uploadThumbnailImage:fileUrl withRemoteUrl:currentUrl withType:type withUpload:NO withCropedImage:nil];
                        }else{
                            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                            NSError *error;
                            NSFetchRequest *request = [[NSFetchRequest alloc] init];
                            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
                            [request setEntity:entityDescription];
                            // all lesson records with lastUpdate == 0 need to be uploaded
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", currentRecordsLocalIdToUpload];
                            [request setPredicate:predicate];
                            NSArray *fetchedRecordsFile = [context executeFetchRequest:request error:&error];
                            RecordsFile *recordsFile = nil;
                            if (fetchedRecordsFile.count == 0) {
                                recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
                                recordsFile.records_id = @0;
                                recordsFile.file_url = currentUrl;
                                recordsFile.file_name = imageNameToUpload;
                                recordsFile.fileSize = @"1024:1024";
                                recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                recordsFile.lastUpdate = @0;
                                recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                                recordsFile.student_id = currentSelectedStudentID;
                                recordsFile.fileType = type;
                                recordsFile.thumb_url = @"";
                                recordsFile.isUploaded = @1;
                            }else if(fetchedRecordsFile.count == 1){
                                recordsFile = fetchedRecordsFile[0];
                                recordsFile.records_id = @0;
                                recordsFile.file_url = currentUrl;
                                recordsFile.file_name = imageNameToUpload;
                                recordsFile.fileSize = @"1024:1024";
                                recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                recordsFile.lastUpdate = @0;
                                recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                                recordsFile.student_id = currentSelectedStudentID;
                                recordsFile.fileType = type;
                                recordsFile.thumb_url = @"";
                                recordsFile.isUploaded = @1;
                            }
                            
                            [context save:&error];
                            if (error) {
                                NSLog(@"Error when saving managed object context : %@", error);
                            }
                            [self getRecrodsFileFromUserID:currentSelectedStudentID];
                            [[AppDelegate sharedDelegate] startThreadToSyncData:7];
                        }
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlert:@"Please try again" title:@"Failed!"] ;
                        
                    });
                }else{
                }
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading queries";
                }
                UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:errorText preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    NSLog(@"you pressed Yes, please button");
                }];
                [alert addAction:yesButton];
                [self presentViewController:alert animated:YES completion:nil];
                FDLogError(@"%@", errorText);
            }
        }];
        [uploadVideoTask resume];
    }
}
*/
#pragma mark UIsession Delegate

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    float progress = [[NSNumber numberWithInteger:totalBytesSent] floatValue];
    float total = [[NSNumber numberWithInteger: totalBytesExpectedToSend] floatValue];
    NSLog(@"progress/total %f",progress/total);
    dispatch_async(dispatch_get_main_queue(), ^{
        [uploadTasksLock lock];
        UploadFileInfo *uploadfileInfo = [uploadFileInfosWithUploadTask objectForKey:task];
        [uploadTasksLock unlock];
        if (uploadfileInfo.currentCell != nil) {
            if ([uploadfileInfo.recordsFile.fileType isEqualToString:@"video"] || [uploadfileInfo.recordsFile.fileType isEqualToString:@"pdf"] || [uploadfileInfo.recordsFile.fileType isEqualToString:@"gif"] || [uploadfileInfo.recordsFile.fileType isEqualToString:@"tif"]) {
                if ([uploadfileInfo.recordsFile.isUploaded integerValue] == 2) {
                    [uploadfileInfo.currentCell.progressView setProgress:1.0f animated:YES];
                }else{
                    [uploadfileInfo.currentCell.progressView setProgress:progress/total animated:YES];
                }
            }else{
                [uploadfileInfo.currentCell.progressView setProgress:progress/total animated:YES];
            }
        }
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics{
    dispatch_async(dispatch_get_main_queue(), ^{
        [uploadTasksLock lock];
        UploadFileInfo *uploadfileInfo = [uploadFileInfosWithUploadTask objectForKey:task];
        [uploadFileInfosWithUploadTask removeObjectForKey:task];
        [uploadTasksLock unlock];
        
        uploadfileInfo.uploadTask = nil;
        
        if (uploadfileInfo.recordsFile != nil) {
            [uploadTasksWithLocalID removeObjectForKey:uploadfileInfo.recordsFile.recordsLocal_id];
            [uploadFileInfoWithLocalID removeObjectForKey:uploadfileInfo.recordsFile.recordsLocal_id];
            if (uploadfileInfo.currentCell != nil) {
                if ([uploadfileInfo.currentCell.progressView progress] >= 1.0f) {
                    NSError *error;
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    
                    NSEntityDescription *recordsFileEntityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
                    NSFetchRequest *recordsFileRequest = [[NSFetchRequest alloc] init];
                    [recordsFileRequest setEntity:recordsFileEntityDescription];
                    NSPredicate *recordsFilePredicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", uploadfileInfo.recordsFile.recordsLocal_id];
                    [recordsFileRequest setPredicate:recordsFilePredicate];
                    NSArray *recordsFileArray = [context executeFetchRequest:recordsFileRequest error:&error];
                    if (recordsFileArray == nil) {
                    } else if (recordsFileArray.count == 0) {
                    } else if (recordsFileArray.count > 0) {
                        for (RecordsFile *recordsFile in recordsFileArray) {
                            if ([recordsFile.fileType isEqualToString:@"video"] || [recordsFile.fileType isEqualToString:@"pdf"] || [recordsFile.fileType isEqualToString:@"gif"] || [recordsFile.fileType isEqualToString:@"tif"]) {
                                if ([recordsFile.isUploaded integerValue] == 0) {
                                    recordsFile.isUploaded = @2;
                                }else{
                                    uploadfileInfo.currentCell.progressMaskView.hidden = YES;
                                    [uploadfileInfo.currentCell.progressView setProgress:0.0f animated:YES];
                                    recordsFile.isUploaded = @1;
                                }
                            }else{
                                uploadfileInfo.currentCell.progressMaskView.hidden = YES;
                                [uploadfileInfo.currentCell.progressView setProgress:0.0f animated:YES];
                                recordsFile.isUploaded = @1;
                            }
                        }
                    }
                    
                    [context save:&error];
                }
            }
            [self performSelector:@selector(getRecrodsFileRunningAfterDelay) withObject:nil afterDelay:7.0f];
        } else {
            FDLogDebug(@"invalid RecordsFile pointer for task %p", task);
        }
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    if (error != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorStr = [NSString stringWithFormat:@"Error downloading '%@", [error userInfo]];
            FDLogError(errorStr);
//            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Document Upload Failed" message:errorStr preferredStyle:UIAlertControllerStyleAlert];
//            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//                NSLog(@"you pressed Yes, please button");
//            }];
//            [alert addAction:yesButton];
//            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}
- (void)getRecrodsFileRunningAfterDelay{
    [self getRecrodsFileFromUserID:currentSelectedStudentID];
}
-(UIImage *)generateThumbImageOfVideo : (NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    NSError *error;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    UIImage *_thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return _thumbnail;
}
- (UIImage *)generateThumbImageOfPdf:(NSURL *)url{
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(contextRef);
    CGContextTranslateCTM(contextRef, 0.0, rect.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    CGContextSetGrayFillColor(contextRef, 1.0, 1.0);
    CGContextFillRect(contextRef, rect);
    
    CGAffineTransform transform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, rect, 0, true);
    CGContextConcatCTM(contextRef, transform);
    CGContextDrawPDFPage(contextRef, page);
    
    UIImage *image= UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(contextRef);
    UIGraphicsEndImageContext();
    CGPDFDocumentRelease(pdf);
    
    return image;
}
- (UIImage *)generateThumbImageOfTif:(NSURL *)url{
    
    NSDataReadingOptions dataReadingOptions = NSDataReadingMappedIfSafe;
    NSData* data = [[NSData alloc] initWithContentsOfURL:url options:dataReadingOptions error:nil];
    
    // Create a CGImageSourceRef that do not cache the decompressed result:
    NSDictionary* sourcOptions =
    @{(id)kCGImageSourceShouldCache: (id)kCFBooleanFalse,
      (id)kCGImageSourceTypeIdentifierHint: (id)@"jellaTIFF"
      };
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data,(CFDictionaryRef)sourcOptions);
    
    // Create a thumbnail without caching the decompressed result:
    NSDictionary* thumbOptions = @{(id)kCGImageSourceShouldCache: (id)kCFBooleanFalse,
                                   (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue,
                                   (id)kCGImageSourceCreateThumbnailFromImageIfAbsent:  (id)kCFBooleanTrue,
                                   (id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanFalse,
                                   (id)kCGImageSourceThumbnailMaxPixelSize:[NSNumber numberWithInteger:1024]};
    
    CGImageRef result = CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)thumbOptions);
    UIImage *image = [[UIImage alloc] initWithCGImage:result];
    return image;
}
- (UIImage *)generateThumbImageOfGif:(NSURL *)url{
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
    UIImage *image = [UIImage animatedImageWithAnimatedGIFData:imageData];
    return image;
}
- (void)uploadThumbnailImage:(NSURL *)fileUrl withRemoteUrl:(NSString *)remoteFileUrl withType:(NSString *)type withUpload:(BOOL)isUpload withCropedImage:(UIImage *)cropImage{
    
    UIImage *thumbnailImage = nil;
    if ([type isEqualToString:@"video"]) {
        thumbnailImage = [self generateThumbImageOfVideo:fileUrl];
    }else if([type isEqualToString:@"pdf"]){
        thumbnailImage = [self generateThumbImageOfPdf:fileUrl];
    }else if([type isEqualToString:@"gif"]){
        thumbnailImage = [self generateThumbImageOfGif:fileUrl];
    }else if([type isEqualToString:@"tif"]){
        thumbnailImage = [self generateThumbImageOfTif:fileUrl];
    }
    
    if (isUpload == NO) {
        imageType = 2;
        currentTempFileUrl = fileUrl;
        currentRemoteTempUrl = remoteFileUrl;
        currentTempType = type;
        
        [self presentPhotoTweaksView:thumbnailImage];
    }else{
        
        NSData *imageData = UIImageJPEGRepresentation(cropImage,0.2);     //change Image to NSData
        
        if (imageData != nil)
        {
            NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
            NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
            NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
            
            NSURL *saveURL = [NSURL URLWithString:apiURLString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
            [request setHTTPMethod:@"POST"];
            
            NSString *boundary = @"---------------------------14737809831466499882746641449";
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
            [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            NSMutableData *body = [NSMutableData data];
            
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
            
            
            NSDate *currentime = [NSDate date];
            NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
            [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
            NSString *imagefileName = [dateformatter stringFromDate:currentime];
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"flightdesk_t_%@.jpg\"\r\n", imagefileName] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSData dataWithData:imageData]];
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            // setting the body of the post to the reqeust
            [request setHTTPBody:body];
            // now lets make the connection to the web
            if (backgroundSession == nil) {
                backgroundSession = [NSURLSession sharedSession];
                backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
            }
            NSURLSessionDataTask *uploadThumbImageTask = [backgroundSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                            NSString *currentImageUrl = [queryResults objectForKey:@"imageurl"];
                            
                            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                            NSError *error;
                            NSFetchRequest *request = [[NSFetchRequest alloc] init];
                            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"RecordsFile" inManagedObjectContext:context];
                            [request setEntity:entityDescription];
                            // all lesson records with lastUpdate == 0 need to be uploaded
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", currentRecordsLocalIdToUpload];
                            [request setPredicate:predicate];
                            NSArray *fetchedRecordsFile = [context executeFetchRequest:request error:&error];
                            RecordsFile *recordsFile = nil;
                            if (fetchedRecordsFile.count == 0) {
                                recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
                                recordsFile.records_id = @0;
                                recordsFile.file_url = remoteFileUrl;
                                recordsFile.file_name = imageNameToUpload;
                                recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", cropImage.size.width, cropImage.size.height];
                                recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                recordsFile.lastUpdate = @0;
                                recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                                recordsFile.student_id = currentSelectedStudentID;
                                recordsFile.fileType = type;
                                recordsFile.thumb_url = currentImageUrl;
                                recordsFile.isUploaded = @1;
                            }else if(fetchedRecordsFile.count == 1){
                                recordsFile = fetchedRecordsFile[0];
                                recordsFile.file_url = remoteFileUrl;
                                recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", cropImage.size.width, cropImage.size.height];
                                recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                recordsFile.lastUpdate = @0;
                                recordsFile.thumb_url = currentImageUrl;
                                recordsFile.isUploaded = @1;
                            }
                            
                            [context save:&error];
                            if (error) {
                                NSLog(@"Error when saving managed object context : %@", error);
                            }
                            [self getRecrodsFileFromUserID:currentSelectedStudentID];
                            [[AppDelegate sharedDelegate] startThreadToSyncData:7];
                        });
                        
                    }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [ self  showAlert: @"Please try again" title:@"Failed!"] ;
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
            [uploadThumbImageTask resume];
        }else{
        }
    }
    
}
- (IBAction)onCloseOrCancelEditMode:(id)sender {
    if (isDeleteMode) {
        isDeleteMode = NO;
        UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [btnDeleteRecords setImage:btnEditImage forState:UIControlStateNormal];
        btnDeleteRecords.tintColor = COLOR_BUTTON_BLUE;
        [selectedThumbViews removeAllObjects];
        [RecordsCollectionView reloadData];
    }else{
        recordsFileCV.hidden = YES;
    }
}

- (IBAction)onMyRecords:(id)sender {
    [self getRecrodsFileFromUserID:@0];
    userNameLbl.text = @"MY RECORDS";
    recordsFileCV.hidden = NO;
    recordsFileDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        recordsFileDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}

- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark UICollectionViewDelegate
- (CGFloat)waterflowLayout:(KNWaterflowLayout *)waterflowLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth{
    UploadFileInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    NSString *fileSizeStr = uploadFileInfo.recordsFile.fileSize;
    NSArray *fileWidthAndHeight =[fileSizeStr componentsSeparatedByString:@":"];
    float imageWidth = 250;
    float imageHeight = 339;
    if (fileWidthAndHeight.count == 2) {
        imageWidth = [fileWidthAndHeight[0] floatValue];
        imageHeight = [fileWidthAndHeight[1] floatValue];
    }
    return [fileWidthAndHeight[1] floatValue] / [fileWidthAndHeight[0] floatValue] * itemWidth + 40.0f;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return recordsFilesArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    RecordsFileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"RecordsFileItem" forIndexPath:indexPath];
    if (!cell) {
        cell = [[RecordsFileCell alloc]init];
    }
    cell.delegate = self;
    UploadFileInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    uploadFileInfo.currentCell = cell;
    cell.progressMaskView.hidden = YES;
    
    if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"image"]){
        if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 0) {
            cell.progressMaskView.hidden = NO;
            NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.recordsFile.recordsLocal_id];
            if (tmpUploadTask == nil) {
                NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
                NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
                NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
                
                NSURL *saveURL = [NSURL URLWithString:apiURLString];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
                [request setHTTPMethod:@"POST"];
                
                NSString *boundary = @"---------------------------14737809831466499882746641449";
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
                [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
                
                NSMutableData *body = [NSMutableData data];
                
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
                
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.recordsFile.file_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
                
                [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[NSData dataWithData:imageData]];
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                // setting the body of the post to the reqeust
                [request setHTTPBody:body];
                
                uploadFileInfo.urlRequest = request;
                
                // now lets make the connection to the web
                if (backgroundSession == nil) {
                    backgroundSession = [NSURLSession sharedSession];
                    backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
                }
                uploadFileInfo.uploadTask = [backgroundSession dataTaskWithRequest:uploadFileInfo.urlRequest];
                [uploadFileInfo.uploadTask resume];
                
                [uploadTasksLock lock];
                [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.recordsFile.recordsLocal_id];
                [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                [uploadTasksLock unlock];
            }
        }
    }else{
        if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 0) {
            cell.progressMaskView.hidden = NO;
            NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.recordsFile.recordsLocal_id];
            if (tmpUploadTask == nil) {
                NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
                NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
                NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_video.php", serverName, webAppDir];
                
                NSURL *saveURL = [NSURL URLWithString:apiURLString];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
                [request setHTTPMethod:@"POST"];
                
                NSString *boundary = @"---------------------------14737809831466499882746641449";
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
                [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
                
                NSMutableData *body = [NSMutableData data];
                
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
                
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.recordsFile.file_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *filePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                NSData *fileData = [NSData dataWithContentsOfFile:filePath];
                
                [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[NSData dataWithData:fileData]];
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                
                [request setHTTPBody:body];
                
                uploadFileInfo.urlRequest = request;
                if (backgroundSession == nil) {
                    backgroundSession = [NSURLSession sharedSession];
                    backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
                }
                uploadFileInfo.uploadTask = [backgroundSession dataTaskWithRequest:uploadFileInfo.urlRequest];
                [uploadFileInfo.uploadTask resume];
                
                [uploadTasksLock lock];
                [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.recordsFile.recordsLocal_id];
                [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                [uploadTasksLock unlock];
            }
        }else if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 2) {
            if([uploadFileInfo.recordsFile.fileType isEqualToString:@"video"] || [uploadFileInfo.recordsFile.fileType isEqualToString:@"pdf"] || [uploadFileInfo.recordsFile.fileType isEqualToString:@"gif"] || [uploadFileInfo.recordsFile.fileType isEqualToString:@"tif"]){
                cell.progressMaskView.hidden = NO;
                NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.recordsFile.recordsLocal_id];
                if (tmpUploadTask == nil) {
                    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
                    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
                    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
                    
                    NSURL *saveURL = [NSURL URLWithString:apiURLString];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
                    [request setHTTPMethod:@"POST"];
                    
                    NSString *boundary = @"---------------------------14737809831466499882746641449";
                    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
                    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
                    
                    NSMutableData *body = [NSMutableData data];
                    
                    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
                    
                    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.recordsFile.thumb_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.thumb_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
                    
                    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                    [body appendData:[NSData dataWithData:imageData]];
                    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                    // setting the body of the post to the reqeust
                    [request setHTTPBody:body];
                    
                    uploadFileInfo.urlRequest = request;
                    
                    // now lets make the connection to the web
                    if (backgroundSession == nil) {
                        backgroundSession = [NSURLSession sharedSession];
                        backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
                    }
                    uploadFileInfo.uploadTask = [backgroundSession dataTaskWithRequest:uploadFileInfo.urlRequest];
                    [uploadFileInfo.uploadTask resume];
                    
                    [uploadTasksLock lock];
                    [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.recordsFile.recordsLocal_id];
                    [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                    [uploadTasksLock unlock];
                }
            }
        }
    }
    cell.lblRecordsName.text = uploadFileInfo.recordsFile.file_name;
    [cell.recordsImageView setImage:[UIImage imageNamed:@"default_image"]];
    if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"image"] && ![uploadFileInfo.recordsFile.file_url isEqualToString:@""]) {
        if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
            [cell.recordsImageView setImageWithURL:[NSURL URLWithString:uploadFileInfo.recordsFile.file_url]];
            NSString *cachedPath = [LocalDBManager checkCachedFileExist:uploadFileInfo.recordsFile.file_url];
            if (cachedPath) {
                // load from cache
                UIImage *image = [UIImage imageWithContentsOfFile:cachedPath];
                [cell.recordsImageView setImage:image];
            } else {
                // save to temp directory
                NSURL *url = [NSURL URLWithString:uploadFileInfo.recordsFile.file_url];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
                NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
                    
                } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    
                    return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.recordsFile.file_url]];
                    
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    
                    [downloadProgressHUD hideAnimated:YES];
                    if (!error) {
                        UIImage *image = [UIImage imageWithContentsOfFile:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.recordsFile.file_url]];
                        [cell.recordsImageView setImage:image];
                    } else {
                        
                    }
                }];
                
                [downloadTask resume];
            }
        }else{
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            [cell.recordsImageView setImage:image];
        }
        
    }else{
        if (![uploadFileInfo.recordsFile.thumb_url isEqualToString:@""]) {
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [cell.recordsImageView setImageWithURL:[NSURL URLWithString:uploadFileInfo.recordsFile.thumb_url]];
                NSString *cachedPath = [LocalDBManager checkCachedFileExist:uploadFileInfo.recordsFile.thumb_url];
                if (cachedPath) {
                    // load from cache
                    UIImage *image = [UIImage imageWithContentsOfFile:cachedPath];
                    [cell.recordsImageView setImage:image];
                } else {
                    // save to temp directory
                    NSURL *url = [NSURL URLWithString:uploadFileInfo.recordsFile.thumb_url];
                    NSURLRequest *request = [NSURLRequest requestWithURL:url];
                    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
                    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
                        
                    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                        
                        return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.recordsFile.thumb_url]];
                        
                    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                        
                        [downloadProgressHUD hideAnimated:YES];
                        if (!error) {
                            UIImage *image = [UIImage imageWithContentsOfFile:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.recordsFile.thumb_url]];
                            [cell.recordsImageView setImage:image];
                        } else {
                            
                        }
                    }];
                    
                    [downloadTask resume];
                }
            }else{
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.thumb_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [cell.recordsImageView setImageWithURL:[NSURL URLWithString:imagePath]];
            }
        }
    }
    
    NSString *bmiddleUrl = uploadFileInfo.recordsFile.file_url;
    
    KNPhotoItems *items = [[KNPhotoItems alloc] init];
    items.url = bmiddleUrl;
    items.sourceView = cell.recordsImageView;
    items.itemType = uploadFileInfo.recordsFile.fileType;
    if(![tempArr containsObject:bmiddleUrl]){
        [itemsArr addObject:items];
        [tempArr addObject:bmiddleUrl];
    }
    
    if (isDeleteMode) {
        cell.maskView.hidden = NO;
        
        if ([selectedThumbViews containsObject:uploadFileInfo.recordsFile]) {
            cell.selectedImageView.hidden = NO;
        }else{
            cell.selectedImageView.hidden = YES;
        }
    }else{
        cell.maskView.hidden = YES;
    }
    
    [uploadFileInfoWithLocalID setObject:uploadFileInfo forKey:uploadFileInfo.recordsFile.recordsLocal_id];
    [recordsFilesArray replaceObjectAtIndex:indexPath.row withObject:uploadFileInfo];
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UploadFileInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (isDeleteMode) {
        if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
            if ([selectedThumbViews containsObject:uploadFileInfo.recordsFile]) {
                [selectedThumbViews removeObject:uploadFileInfo.recordsFile];
            }else{
                [selectedThumbViews addObject:uploadFileInfo.recordsFile];
            }
            [RecordsCollectionView reloadData];
        }
    }else{
        if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"image"]) {
            KNPhotoBrower *photoBrower = [[KNPhotoBrower alloc] init];
            [photoBrower setDelegate:self];
            [photoBrower setItemsArr:[itemsArr copy]];
            [photoBrower setCurrentIndex:indexPath.row];
            [photoBrower setDataSourceUrlArr:[collectionPrepareArr copy]];
            [photoBrower setSourceViewForCellReusable:RecordsCollectionView];
            [photoBrower present];
            _ApplicationStatusIsHidden = YES;
            [self setNeedsStatusBarAppearanceUpdate];
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"video"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self videoTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                 [self playVideoAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"pdf"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self pdfTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPDFAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"tif"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self tifTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"text"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self docTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewDocAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"gif"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self gifTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"ppt"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                [self pptTouched:uploadFileInfo.recordsFile.file_url withFileName:uploadFileInfo.recordsFile.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.recordsFile.fileType isEqualToString:@"other"]){
            if ([uploadFileInfo.recordsFile.isUploaded integerValue] == 1) {
                
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.recordsFile.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                
                
            }
            
        }
    }
}
#pragma mark RecordsFileCellDelegate
- (void)pressedLongTouchToRename:(RecordsFileCell *)_cell{
    [[AppDelegate sharedDelegate] stopThreadToSyncData:7];
    NSIndexPath *indexpath = [RecordsCollectionView indexPathForCell:_cell];
    UploadFileInfo *uploadFileInfoToUpdate = [recordsFilesArray objectAtIndex:indexpath.row];
    currentSelectedrecordsFile = uploadFileInfoToUpdate.recordsFile;
    
    indexToEdit = indexpath.row;
    tmptext.text = uploadFileInfoToUpdate.recordsFile.file_name;
    [tmptext becomeFirstResponder];
    [self reloadViewsForRenaming];
    [self.view addSubview:coverViewForRenameText];
    
    renameTxtDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        renameTxtDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
- (BOOL)prefersStatusBarHidden{
    if(_ApplicationStatusIsHidden){
        return YES;
    }
    return NO;
}

#pragma mark - Delegate
- (void)photoBrowerWillDismiss{
    NSLog(@"Will Dismiss");
    _ApplicationStatusIsHidden = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}
- (void)photoBrowerRightOperationActionWithIndex:(NSInteger)index{
    NSLog(@"operation:%zd",index);
}
- (void)photoBrowerRightOperationDeleteImageSuccessWithRelativeIndex:(NSInteger)index{
    NSLog(@"delete-Relative:%zd",index);
}
- (void)photoBrowerRightOperationDeleteImageSuccessWithAbsoluteIndex:(NSInteger)index{
    NSLog(@"delete-Absolute:%zd",index);
}
- (void)photoBrowerWriteToSavedPhotosAlbumStatus:(BOOL)success{
    NSLog(@"saveImage:%zd",success);
}
#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    textField.returnKeyType = UIReturnKeyDone;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    if (currentSelectedrecordsFile.records_id != nil && textField.text.length > 0) {
        [coverViewForRenameText removeFromSuperview];
        currentSelectedrecordsFile.file_name = tmptext.text;
        currentSelectedrecordsFile.lastUpdate = @(0);
        [self.view endEditing:YES];
        indexToEdit = -1;
        [context save:&error];
        [RecordsCollectionView reloadData];
        [[AppDelegate sharedDelegate] startThreadToSyncData:7];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    if (currentSelectedrecordsFile.records_id != nil && text.length > 0) {
        currentSelectedrecordsFile.file_name = text;
        currentSelectedrecordsFile.lastUpdate = @(0);
        [context save:&error];
    }
    return YES;
}

- (void)hideCoverOfWebView{
    vwCoverOfWebView.hidden = YES;
}
- (void)viewDocAtLocalPath:(NSString *)docPath {
    NSURL *url = [NSURL fileURLWithPath:docPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView  loadRequest:request];
    vwCoverOfWebView.hidden = NO;
}
- (void)viewPPTAtLocalPath:(NSString *)docPath {
    NSURL *url = [NSURL fileURLWithPath:docPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView  loadRequest:request];
    vwCoverOfWebView.hidden = NO;
}
- (void)viewPDFAtLocalPath:(NSString *)docPath {
    NSString *documentDirectory = @"";
    documentDirectory = [NSString stringWithFormat:@"file://%@", docPath];
    NSURL *documentUrl =  [[NSURL alloc] initWithString:[documentDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    MFDocumentManager *aDocManager = [[MFDocumentManager alloc]initWithFileUrl:documentUrl];
    
    ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithDocumentManager:aDocManager];
    readerViewController.pathOfCurrentPDF =documentUrl;
    [readerViewController setDocumentId:[documentUrl lastPathComponent]];
    [readerViewController setDocumentDelegate:readerViewController];
    //    readerViewController.hidesBottomBarWhenPushed = YES;
    [[AppDelegate sharedDelegate].setting_VC.navigationController pushViewController:readerViewController animated:YES];
}
- (void)playVideoAtLocalPath:(NSString *)videoPath {
    playerVC = [[MPMoviePlayerViewController alloc] init];
    
    playerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    playerVC.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    playerVC.moviePlayer.contentURL = [NSURL fileURLWithPath:videoPath];
    
    [self presentMoviePlayerViewControllerAnimated:playerVC];
}
- (void)videoTouched:(NSString*)videoPath withFileName:(NSString *)fileName{
    // Check cache first
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:videoPath];
    
    if (cachedPath) {
        // load from cache
        [self playVideoAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:videoPath];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:videoPath]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self playVideoAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:videoPath]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
    
}
- (void)pdfTouched:(NSString*)pdfPath withFileName:(NSString *)fileName{
    // Check cache first
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if (cachedPath) {
        [self viewPDFAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self viewPDFAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
- (void)docTouched:(NSString*)pdfPath withFileName:(NSString *)fileName{
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:pdfPath];
    
    if (cachedPath) {
        [self viewDocAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self viewDocAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
- (void)pptTouched:(NSString*)pdfPath withFileName:(NSString *)fileName{
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:pdfPath];
    
    if (cachedPath) {
        [self viewPPTAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self viewPPTAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
- (void)gifTouched:(NSString*)pdfPath withFileName:(NSString *)fileName{
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:pdfPath];
    
    if (cachedPath) {
        [self viewPPTAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self viewPPTAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
- (void)tifTouched:(NSString*)pdfPath withFileName:(NSString *)fileName{
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:pdfPath];
    
    if (cachedPath) {
        [self viewPPTAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self viewPPTAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            } else {
                [self showAlert:[NSString stringWithFormat:@"Could not download %@, please try again.", fileName] title:@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
@end
