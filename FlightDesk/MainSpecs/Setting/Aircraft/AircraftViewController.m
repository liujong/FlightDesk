//
//  AircraftViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AircraftViewController.h"
#import "AircraftCell.h"
#import "ItemCell.h"
#import "PersistentCoreDataStack.h"
#import "DateViewController.h"
#import "PickerWithDataViewController.h"
#import "SquawksCell.h"

#import "UIView+Badge.h"

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
@implementation UploadMaintenanceLogsInfo
@synthesize urlRequest;
@synthesize uploadTask;
@synthesize currentCell;
@synthesize maintenanceLog;

- (id)initWithCoreDataMaintenanceLogs:(MaintenanceLogs *)maintenanceLog{
    self = [super init];
    if (self) {
        urlRequest = nil;
        uploadTask = nil;
        currentCell = nil;
        maintenanceLog = maintenanceLog;
    }
    return self;
}
@end

@interface AircraftViewController ()<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SWTableViewCellDelegate, DateViewControllerDelegate, PickerWithDataViewControllerDelegate, ItemCellDelegate, UIPopoverControllerDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UICollectionViewDelegate,UICollectionViewDataSource, KNWaterflowLayoutDelegate,KNPhotoBrowerDelegate, RecordsFileCellDelegate,NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, PhotoTweaksViewControllerDelegate, UIPopoverPresentationControllerDelegate>{
    
    NSMutableArray *arrAircraft;
    NSMutableArray *arrAircraftItems;
    NSMutableArray *arrMaintainesItems;
    NSMutableArray *arrAvionics;
    NSMutableArray *arrLifeLimitedPartItems;
    NSMutableArray *arrOtherItems;
    NSMutableArray *arrSquawks;
    
    BOOL isCheckedMNC;
    BOOL isCheckedAlpha;
    BOOL isCheckedLetterOnly;
    BOOL isCheckedLetterCAPs;
    BOOL isCheckedNumOnly;
    BOOL isCheckedTachBasedNoti;
    NSInteger typeOfTach;
    BOOL isCheckedSD;
    BOOL isCheckedNNDpD;
    BOOL isCheckedNNDAD;
    BOOL isCheckedMultiDate;
    BOOL isCheckedMultiNNDAD;
    BOOL isCheckedMultiNDPED;
    
    BOOL isClickedImportBtn;
    
    BOOL isShownPickerView;
    
    BOOL isAnnualInspection;
    
    UIView *paintView;
    
    NSInteger filledType;//1: Value 2: Date 3: Lookup
    NSInteger typeToAddItem; //1:Maintenance 2:Avionics 3:life limited part 4:other
    
    NSManagedObjectContext *contextRecords;
    
    Aircraft *aircraftToEdit;
    SWTableViewCell *craftItemToEdit;
    ItemCell *annualEdit;
    
    int pickerType;
    
    ItemCell *currentDateDialogSuper;
    UITextField *currentDateDialog;
    
    NSInteger currentSquawkItemToEdit;
    
    //maintenance logs
    NSLock *uploadTasksLock;
    NSMutableDictionary *uploadTasksWithLocalID;
    NSMutableDictionary *uploadFileInfosWithUploadTask;
    NSURLSession *backgroundSession;
    NSMutableArray *recordsFilesArray;
    NSMutableDictionary *uploadFileInfoWithLocalID;
    
    BOOL isDeleteMode;
    
    NSString *imageNameToUpload;
    NSNumber *currentSelectedAircraftLocalID;
    
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
    MaintenanceLogs *currentSelectedrecordsFile;
    
    MBProgressHUD *downloadProgressHUD;
    
    NSNumber *currentRecordsLocalIdToUpload;
    
    NSInteger imageType;
    NSURL *currentTempImageUrl;
    
    NSURL *currentTempFileUrl;
    NSString *currentRemoteTempUrl;
    NSString *currentTempType;
    
    BOOL isExpanedOfmaintenanceLogsView;
}

@end

@implementation AircraftViewController

@synthesize playerVC;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //SquawksTableView.translatesAutoresizingMaskIntoConstraints = NO;
    currentSquawkItemToEdit = -1;
    addSquawkItemView.hidden = YES;
    
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    isCheckedMNC = NO;
    isCheckedAlpha = NO;
    isCheckedLetterOnly = NO;
    isCheckedLetterCAPs = NO;
    isCheckedNumOnly = NO;
    isCheckedTachBasedNoti = NO;
    typeOfTach = 1;
    isCheckedSD = NO;
    isCheckedNNDpD = NO;
    isCheckedNNDAD = NO;
    isCheckedMultiDate = NO;
    isCheckedMultiNNDAD = NO;
    isCheckedMultiNDPED = NO;
    isClickedImportBtn = NO;
    isAnnualInspection = NO;
    
    filledType = 1;
    typeToAddItem = 0;
    
    showKeyboard = NO;
    aircraftToEdit = nil;
    craftItemToEdit = nil;
    
    
    recordsFilesArray = [[NSMutableArray alloc] init];
    itemsArr = [[NSMutableArray alloc] init];
    tempArr = [[NSMutableArray alloc] init];
    collectionPrepareArr = [[NSMutableArray alloc] init];
    selectedThumbViews = [[NSMutableArray alloc] init];
    isDeleteMode = NO;
    isExpanedOfmaintenanceLogsView = NO;
    uploadFileInfoWithLocalID = [[NSMutableDictionary alloc] init];
    uploadTasksWithLocalID = [[NSMutableDictionary alloc] init];
    uploadFileInfosWithUploadTask = [[NSMutableDictionary alloc] init];
    uploadTasksLock = [[NSLock alloc] init];
    backgroundSession = nil;
    [[SDWebImageManager sharedManager].imageCache clearMemory];
    UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
    btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
    
    UIImage *btnAddImage = [[UIImage imageNamed:@"addbtn"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnAddLogs setImage:btnAddImage forState:UIControlStateNormal];
    btnAddLogs.tintColor = COLOR_BUTTON_BLUE;
    
    
    btnCloseOfLogs.hidden = YES;
    imageNameToUpload = @"";
    currentSelectedAircraftLocalID = @0;
    
    KNWaterflowLayout *waterFlowLayout = [[KNWaterflowLayout alloc] init];
    [waterFlowLayout setDelegate:self];
    MaintenanceCollectionView.collectionViewLayout = waterFlowLayout;
    [MaintenanceCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([RecordsFileCell class]) bundle:nil] forCellWithReuseIdentifier:@"RecordsFileItem"];
    
    //show selected files
    vwCoverOfWebView.hidden = YES;
    [webView  setScalesPageToFit:YES];

    UITapGestureRecognizer *tapGestureToWebView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverOfWebView)];
    [vwCoverOfWebView addGestureRecognizer:tapGestureToWebView];
    
    [self initViewForRenaming];
    
    
    
    UIImage *btnShareImage = [[UIImage imageNamed:@"share_nav.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnShareCurrentAircraft setImage:btnShareImage forState:UIControlStateNormal];
    btnShareCurrentAircraft.tintColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    addAircraftView.hidden = YES;
    addAircraftItemView.hidden = YES;
    AddOtherItemView.hidden = YES;
    aircraftAddingDialog.autoresizesSubviews = NO;
    aircraftAddingDialog.contentMode = UIViewContentModeRedraw;
    aircraftAddingDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    aircraftAddingDialog.layer.masksToBounds = YES;
    aircraftAddingDialog.layer.shadowRadius = 3.0f;
    aircraftAddingDialog.layer.shadowOpacity = 1.0f;
    aircraftAddingDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    aircraftAddingDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:aircraftAddingDialog.bounds].CGPath;
    aircraftAddingDialog.layer.cornerRadius = 15.0f;
    
    maintenanceLogsView.layer.cornerRadius = 15.0f;
    maintenanceLogsView.layer.masksToBounds = YES;
    
    addAircraftitemDialog.autoresizesSubviews = NO;
    addAircraftitemDialog.contentMode = UIViewContentModeRedraw;
    addAircraftitemDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    addAircraftitemDialog.layer.masksToBounds = YES;
    addAircraftitemDialog.layer.shadowRadius = 20.0f;
    addAircraftitemDialog.layer.shadowOpacity = 1.0f;
    addAircraftitemDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    addAircraftitemDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:addAircraftitemDialog.bounds].CGPath;
    addAircraftitemDialog.layer.cornerRadius = 20.0f;
//    addAircraftitemDialog.layer.borderColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0].CGColor;
    
    
    AddOtherItemDialog.autoresizesSubviews = NO;
    AddOtherItemDialog.contentMode = UIViewContentModeRedraw;
    AddOtherItemDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    AddOtherItemDialog.layer.shadowRadius = 3.0f;
    AddOtherItemDialog.layer.shadowOpacity = 1.0f;
    AddOtherItemDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    AddOtherItemDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:AddOtherItemDialog.bounds].CGPath;
    AddOtherItemDialog.layer.cornerRadius = 5.0f;
    
    addSquawkDialog.autoresizesSubviews = NO;
    addSquawkDialog.contentMode = UIViewContentModeRedraw;
    addSquawkDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    addSquawkDialog.layer.masksToBounds = YES;
    addSquawkDialog.layer.shadowRadius = 3.0f;
    addSquawkDialog.layer.shadowOpacity = 1.0f;
    addSquawkDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    addSquawkDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:addSquawkDialog.bounds].CGPath;
    addSquawkDialog.layer.cornerRadius = 15.0f;
    addSquawkDialog.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 960.0f;
    [scrView setContentSize:scrSize];
    
    scrSize = scrAircraft.contentSize;
    scrSize.height = 1150.0f;
    [scrAircraft setContentSize:scrSize];
    
    scrSize = scrAircraftItem.contentSize;
    scrSize.height = 920.0f;
    [scrAircraftItem setContentSize:scrSize];
    
    //option group init
    
    optionValue.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    
    
    lblAircraftTitle.text = @"";
    arrAircraft = [[NSMutableArray alloc] init];
    arrAircraftItems = [[NSMutableArray alloc] init];
    arrMaintainesItems = [[NSMutableArray alloc] init];
    arrAvionics = [[NSMutableArray alloc] init];
    arrLifeLimitedPartItems = [[NSMutableArray alloc] init];
    
    [self initAircraftWithTempData];
    
    arrOtherItems = [[NSMutableArray alloc] init];
    arrSquawks = [[NSMutableArray alloc] init];
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    
    
    
    
}
- (void)initAircraftWithTempData{
    NSMutableDictionary *initSettingDicTmp = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *initSettingDic = [[NSMutableDictionary alloc] init];
    [initSettingDicTmp setObject:@1 forKey:@"type"];
    
    [initSettingDicTmp setObject:@0 forKey:@"MaxNumberOfCharacters"];      //NSInteger
    [initSettingDicTmp setObject:@0 forKey:@"Alphanumeric"];                 //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"lettersOnly"];                  //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"lettersCAPS"];                  //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"NumbersOnly"];                  //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"TachBasedNoti"];                //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"TachType"];                       //Integer   1:25 2:50 3:100 4:2000
    [initSettingDicTmp setObject:@0 forKey:@"TachValue"];                      //Decimal
    
    [initSettingDicTmp setObject:@0 forKey:@"singleDate"];                 //BOOL
    [initSettingDicTmp setObject:@0 forKey:@"notiNumberOfDaysPrior"];        //NSInteger
    [initSettingDicTmp setObject:@0 forKey:@"notiNumberOfDaysAfter"];        //NSInteger
    [initSettingDicTmp setObject:@0 forKey:@"multiDate"];                  //BOOL
    [initSettingDicTmp setObject:@"" forKey:@"startDate"];                   //String
    [initSettingDicTmp setObject:@"" forKey:@"endDate"];                     //String
    [initSettingDicTmp setObject:@0 forKey:@"multiDateNotifiNumPrior"];      //NSInteger
    [initSettingDicTmp setObject:@0 forKey:@"multiDateNotifiNumAfter"];      //NSInteger
    
    [initSettingDicTmp setObject:@"" forKey:@"lookupV1"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV2"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV3"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV4"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV5"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV6"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV7"];                     //String
    [initSettingDicTmp setObject:@"" forKey:@"lookupV8"];                     //String
    
    
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"lettersCAPS"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Registration",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"Alphanumeric"];
    [initSettingDic setObject:@1 forKey:@"lettersCAPS"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Model",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"Alphanumeric"];
    [initSettingDic setObject:@1 forKey:@"lettersCAPS"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Variant",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@4 forKey:@"MaxNumberOfCharacters"];
    [initSettingDic setObject:@1 forKey:@"NumbersOnly"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Year",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Category",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Class",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"NumbersOnly"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MTOW",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"Alphanumeric"];
    [initSettingDic setObject:@1 forKey:@"lettersCAPS"];
    [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Serial No.",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@1 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"NumbersOnly"];
    [initSettingDic setObject:@1 forKey:@"TachBasedNoti"];
    [initSettingDic setObject:@1 forKey:@"TachType"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"TACH",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Annual Inspection",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ELT Inspection",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ELT Battery Exp.",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Pitot-Static",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"TxPDR",@"fieldName", @"", @"content",initSettingDic, @"setting",@1, @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrAvionics addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"VOR Test",@"fieldName", @"", @"content",initSettingDic, @"setting",@(1), @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrAvionics addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"NavData",@"fieldName", @"", @"content",initSettingDic, @"setting",@(1), @"isDelete", nil]];
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrAvionics addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Charts",@"fieldName", @"", @"content" ,initSettingDic, @"setting",@(1), @"isDelete", nil]];
    
    
    
    initSettingDic = [initSettingDicTmp mutableCopy];
    [initSettingDic setObject:@2 forKey:@"type"];
    [initSettingDic setObject:@1 forKey:@"multiDate"];
    [arrLifeLimitedPartItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"ELT Battery",@"fieldName", @"", @"content", initSettingDic, @"setting",@(1), @"isDelete", nil]];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"AircraftViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [self reloadData];
    [[AppDelegate sharedDelegate] startThreadToSyncData:5];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[AppDelegate sharedDelegate] stopThreadToSyncData:5];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)reloadData{
    [arrAircraft removeAllObjects];
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    // add students assigned to the current user (and their lesson groups)
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Aircraft" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Aircraft!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Aircrafts found!");
    } else {
        FDLogDebug(@"%lu Aircrafts found", (unsigned long)[objects count]);
        NSMutableArray *tempAircrafts = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"valueForSort" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedAircrafts = [tempAircrafts sortedArrayUsingDescriptors:sortDescriptors];
        for (Aircraft *aircraft in sortedAircrafts) {
            [arrAircraft addObject:aircraft];
        }
    }
    [self resizeAircraftView];
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    
    [AirCraftTableView reloadData];
    
    
}

- (void)deviceOrientationDidChange{
    
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!showKeyboard)
    {
        showKeyboard = YES;
        [self resizeAddingAircraftView];
        [self resizeAddingAircraftItemView];
        
        if (CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)) {

            if (txtFieldName.isEditing || txtValueMaxNum.isEditing) {
                
            }else{
                //[scrAircraftItem setContentOffset:CGPointMake(0, 250) animated:YES];
            }
        }
        
        

    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (showKeyboard)
    {
        
        [self.view endEditing:YES];
        showKeyboard = NO;
        [self resizeAddingAircraftView];
        [self resizeAddingAircraftItemView];
        
    }
}
- (CGFloat)getLabelHeight:(UILabel*)label
{
    CGSize constraint = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
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
        if (currentSelectedrecordsFile.maintenancelog_id != nil && tmptext.text.length > 0) {
            [coverViewForRenameText removeFromSuperview];
            currentSelectedrecordsFile.file_name = tmptext.text;
            currentSelectedrecordsFile.lastUpdate = @(0);
            indexToEdit = -1;
            [MaintenanceCollectionView reloadData];
            [context save:&error];
            [[AppDelegate sharedDelegate] startThreadToSyncData:5];
        }
    }];
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        [coverViewForRenameText removeFromSuperview];
        tmptext.text = @"";
        indexToEdit = -1;
        [MaintenanceCollectionView reloadData];
        [[AppDelegate sharedDelegate] startThreadToSyncData:5];
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

- (void)getMaintenanceLogs:(NSNumber *)aircraftLocalID{
    currentSelectedAircraftLocalID = aircraftLocalID;
    [recordsFilesArray removeAllObjects];
    [collectionPrepareArr removeAllObjects];
    [itemsArr removeAllObjects];
    [tempArr removeAllObjects];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aircraft_local_id == %@",aircraftLocalID];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve RecordsFile!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid RecordsFile found!");
    } else {
        NSMutableArray *tempRecordsFies = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recordsLocal_id" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedRecordsFiles = [tempRecordsFies sortedArrayUsingDescriptors:sortDescriptors];
        BOOL ableUploaded = NO;
        for (MaintenanceLogs *maintenanceLogs in objects) {
            if ([maintenanceLogs.isUploaded integerValue] == 0) {
                ableUploaded = YES;
            }
            UploadMaintenanceLogsInfo *uploadFileInfo = [uploadFileInfoWithLocalID objectForKey:maintenanceLogs.recordsLocal_id];
            if (uploadFileInfo == nil) {
                uploadFileInfo = [[UploadMaintenanceLogsInfo alloc] initWithCoreDataMaintenanceLogs:maintenanceLogs];
                [uploadFileInfoWithLocalID setObject:uploadFileInfo forKey:maintenanceLogs.recordsLocal_id];
            }
            uploadFileInfo.maintenanceLog = maintenanceLogs;
            [recordsFilesArray addObject:uploadFileInfo];
            
            //if ([recordsFile.fileType isEqualToString:@"image"]) {
            KNPhotoItems *items = [[KNPhotoItems alloc] init];
            items.url = maintenanceLogs.file_url;
            items.sourceView = nil;
            items.itemType =maintenanceLogs.fileType;
            [collectionPrepareArr addObject:items];
            //}
        }
        if (ableUploaded) {
            [[AppDelegate sharedDelegate] stopThreadToSyncData:5];
        }else{
            [[AppDelegate sharedDelegate] startThreadToSyncData:5];
        }
    }
    [MaintenanceCollectionView reloadData];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == AirCraftTableView) {
        return [arrAircraft count];
    }else if (tableView == AirCraftItemTableView){
        return [arrAircraftItems count];
    }else if (tableView == MaintaineTableView){
        return [arrMaintainesItems count];
    }else if (tableView == AvionicsTableView){
        return [arrAvionics count];
    }else if (tableView == limitedPartTableView){
        return [arrLifeLimitedPartItems count];
    }else if (tableView == otherPartTableView){
        return [arrOtherItems count];
    }else if (tableView == SquawksTableView){
        return [arrSquawks count];
    }
    return 0;
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
    CGRect rect ;
    if (tableView == AirCraftTableView) {
        rect = btnAddAirCraft.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnAddAirCraft setFrame:rect];
        [view addSubview:btnAddAirCraft];
    }else if (tableView == MaintaineTableView){
        rect = btnAddNewMaintenance.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnAddNewMaintenance setFrame:rect];
        [view addSubview:btnAddNewMaintenance];
    }else if (tableView == AvionicsTableView){
        rect = btnAvionics.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnAvionics setFrame:rect];
        [view addSubview:btnAvionics];
    }else if (tableView == AirCraftItemTableView){
        rect = btnAddAirCraftItem.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnAddAirCraftItem setFrame:rect];
        [view addSubview:btnAddAirCraftItem];
    }else if (tableView == limitedPartTableView){
        rect = btnLimitedPart.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnLimitedPart setFrame:rect];
        [view addSubview:btnLimitedPart];
    }else if (tableView == otherPartTableView){
        rect = btnOtherItem.frame;
        rect.origin.x = 5;
        rect.size.width = tableView.bounds.size.width - 10;
        [btnOtherItem setFrame:rect];
        [view addSubview:btnOtherItem];
    }
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
    
    // Set the background color of our header/footer.
    header.contentView.backgroundColor = [UIColor whiteColor];

}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (tableView == AirCraftTableView) {
        return 44.0f;
    }else if (tableView == SquawksTableView){
        return 0.0f;
    }else {
        return 30.0f;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == AirCraftTableView) {
        return 58.0f;
    }else if (tableView == SquawksTableView){
        NSString *oneSquawk = [arrSquawks objectAtIndex:indexPath.row];
        UILabel *lblToGetHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 487.0f, 50.0f)];
        lblToGetHeight.text = oneSquawk;
        lblToGetHeight.font = [UIFont fontWithName:@"Helvetica" size:14];
        return [self getLabelHeight:lblToGetHeight] + 20.0f;
    }else {
        return 30.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == AirCraftTableView) {
        static NSString *simpleTableIdentifier = @"AircraftItem";
        AircraftCell *cell = (AircraftCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [AircraftCell sharedCell];
        }
        cell.delegate = self;
        cell.rightUtilityButtons = [self rightButtons];
        
        Aircraft *aircraft = [arrAircraft objectAtIndex:indexPath.row];
        
        NSString *aircraftItems = aircraft.aircraftItems;
        NSData *data = [aircraftItems dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSInteger badgeCount = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:aircraft];
        if (badgeCount > 0) {
            cell.lblReg.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:aircraft];
            cell.lblReg.badge.badgeColor = [UIColor redColor];
        }else{
            cell.lblReg.badge.badgeValue = 0;
            cell.lblReg.badge.badgeColor = [UIColor redColor];
        }
        for (NSDictionary *fieldInfo in json) {
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
                cell.lblReg.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Model"]) {
                cell.lblModel.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Variant"]) {
                cell.lblVariant.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Year"]) {
                cell.lblYear.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Category"]) {
                cell.lblCategory.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Class"]) {
                cell.lblClass.text = [fieldInfo objectForKey:@"content"];
            }
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"MTOW"]) {
                cell.lblMTOW.text = [fieldInfo objectForKey:@"content"];
            }
        }
        return cell;
    }else if (tableView == AirCraftItemTableView){
        
        static NSString *simpleTableIdentifier = @"ItemCellIdentifier";
        ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ItemCell sharedCell];
        }
        cell.itemDelegate = self;
        cell.txtContent.delegate = cell;
        cell.btnAnnual.hidden = YES;
        cell.btnPopupLook.hidden = YES;
        cell.lblBannerAlertCount.hidden = YES;
        cell.currentReading.hidden = YES;
        cell.btnPopup.hidden = YES;
        
        NSDictionary *dict = [arrAircraftItems objectAtIndex:indexPath.row];
        
        cell.delegate = self;
        if (![[dict objectForKey:@"fieldName"] isEqualToString:@"Registration"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"Model"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"Variant"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"Year"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"Category"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"Class"] && ![[dict objectForKey:@"fieldName"] isEqualToString:@"MTOW"] ) {
            cell.leftUtilityButtons = [self leftButtons];
        }
        if ([[dict objectForKey:@"isDelete"] boolValue]){
            cell.rightUtilityButtons = [self rightButtons];
        }
        
        cell.lblFieldName.text = [dict objectForKey:@"fieldName"];
        cell.txtContent.text = [dict objectForKey:@"content"];
        cell.txtContent.enabled = YES;
        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            cell.btnPopup.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    
                    if((long)[components day] + 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                        
                    }else if ((long)[components day] + 1 > 10){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day]+ 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if((long)[components day] + 1 > 0 && (long)[components day] + 1 <= 10){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day] + 1 == 0){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.txtContent.textColor = [UIColor redColor];
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    cell.btnPopup.hidden = YES;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    NSDate *date2 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"startDate"] ];
                    NSDateComponents *componentsBetween = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:date2
                                                                          toDate:date1
                                                                         options:0];
                    NSInteger betweenDays = [componentsBetween day] * 0.1;
                    
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    if((long)[components day]+ 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                    }else if ((long)[components day]+ 1 > betweenDays){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                    }else if((long)[components day]+ 1 > 0 && (long)[components day]+ 1 <= betweenDays){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day]+ 1 == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                    cell.btnAnnual.hidden = NO;
                    NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    float benchmark = 0;
                    switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                        case 1:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 2.5f;
                            break;
                        }
                        case 2:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 5;
                            break;
                        }
                        case 3:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 10;
                            break;
                        }
                        case 4:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 200;
                            break;
                        }
                        default:
                            break;
                    }
                    NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                        if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                            parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                            break;
                        }
                    }
                    
                    NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                    if([differenceTach floatValue] < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        NSDecimalNumber *absDifferenceTach = [parentTach decimalNumberBySubtracting:currentTach];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [absDifferenceTach stringValue]];
                        
                    }else if ([differenceTach floatValue] > benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] > 0 && [differenceTach floatValue] <= benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
            
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 3){
            cell.btnPopupLook.hidden = NO;
        }
        if ([[dict objectForKey:@"fieldName"] isEqualToString:@"Category"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"Class"] ) {
            cell.btnPopupLook.hidden = NO;
        }
        return cell;
    }else if (tableView == MaintaineTableView){
        static NSString *simpleTableIdentifier = @"ItemCellIdentifier";
        ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ItemCell sharedCell];
        }
        
        cell.itemDelegate = self;
        cell.txtContent.delegate = cell;
        
        NSDictionary *dict = [arrMaintainesItems objectAtIndex:indexPath.row];
        cell.delegate = self;
        cell.leftUtilityButtons = [self leftButtons];
        if ([[dict objectForKey:@"isDelete"] boolValue]){
            cell.rightUtilityButtons = [self rightButtons];
        }
        cell.btnAnnual.hidden = YES;
        if ([[dict objectForKey:@"fieldName"] isEqualToString:@"Annual Inspection"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"ELT Inspection"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"Pitot-Static"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"ELT Battery Exp."]){
            cell.btnAnnual.hidden = NO;
        }
        
        
        cell.lblBannerAlertCount.hidden = YES;
        cell.btnPopup.hidden = YES;
        cell.currentReading.hidden = YES;
        cell.btnPopupLook.hidden = YES;
        cell.lblFieldName.text = [dict objectForKey:@"fieldName"];
        cell.txtContent.text = [dict objectForKey:@"content"];
        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        if (indexPath.row == 0){
            cell.currentReading.hidden = NO;
        }
        
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            cell.btnPopup.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    
                    if((long)[components day] + 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                        
                    }else if ((long)[components day] + 1 > 10){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day]+ 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if((long)[components day] + 1 > 0 && (long)[components day] + 1 <= 10){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day] + 1 == 0){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.txtContent.textColor = [UIColor redColor];
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    cell.btnPopup.hidden = YES;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    NSDate *date2 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"startDate"] ];
                    NSDateComponents *componentsBetween = [gregorianCalendar components:NSCalendarUnitDay
                                                                               fromDate:date2
                                                                                 toDate:date1
                                                                                options:0];
                    NSInteger betweenDays = [componentsBetween day] * 0.1;
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    if((long)[components day]+ 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                    }else if ((long)[components day]+ 1 > betweenDays){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                    }else if((long)[components day]+ 1 > 0 && (long)[components day]+ 1 <= betweenDays){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day]+ 1 == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            cell.btnAnnual.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                    NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    float benchmark = 0;
                    switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                        case 1:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 2.5f;
                            break;
                        }
                        case 2:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 5;
                            break;
                        }
                        case 3:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 10;
                            break;
                        }
                        case 4:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 200;
                            break;
                        }
                        default:
                            break;
                    }
                    NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                        if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                            parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                            break;
                        }
                    }
                    
                    NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                    if([differenceTach floatValue] < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        NSDecimalNumber *absDifferenceTach = [parentTach decimalNumberBySubtracting:currentTach];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [absDifferenceTach stringValue]];
                        
                    }else if ([differenceTach floatValue] > benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] > 0 && [differenceTach floatValue] <= benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
            
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 3){
            cell.btnPopupLook.hidden = NO;
        }
        return cell;
    }else if (tableView == AvionicsTableView){
        
        
        static NSString *simpleTableIdentifier = @"ItemCellIdentifier";
        ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ItemCell sharedCell];
        }
        cell.itemDelegate = self;
        cell.txtContent.delegate = cell;
        
        NSDictionary *dict = [arrAvionics objectAtIndex:indexPath.row];
        cell.delegate = self;
        cell.leftUtilityButtons = [self leftButtons];
        if ([[dict objectForKey:@"isDelete"] boolValue]){
            cell.rightUtilityButtons = [self rightButtons];
        }
        
        cell.btnAnnual.hidden = YES;
        if ([[dict objectForKey:@"fieldName"] isEqualToString:@"VOR Test"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"NavData"] || [[dict objectForKey:@"fieldName"] isEqualToString:@"Charts"]){
            cell.btnAnnual.hidden = NO;
        }
        
        cell.lblFieldName.text = [dict objectForKey:@"fieldName"];
        cell.txtContent.text = [dict objectForKey:@"content"];
        cell.txtContent.placeholder = @"Optional";
        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        
        cell.lblBannerAlertCount.hidden = YES;
        cell.btnPopup.hidden = YES;
        cell.btnPopupLook.hidden = YES;
        cell.currentReading.hidden = YES;
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            cell.btnPopup.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    
                    if((long)[components day] + 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                        
                    }else if ((long)[components day] + 1 > 10){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day]+ 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if((long)[components day] + 1 > 0 && (long)[components day] + 1 <= 10){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day] + 1 == 0){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.txtContent.textColor = [UIColor redColor];
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    cell.btnPopup.hidden = YES;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    NSDate *date2 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"startDate"] ];
                    NSDateComponents *componentsBetween = [gregorianCalendar components:NSCalendarUnitDay
                                                                               fromDate:date2
                                                                                 toDate:date1
                                                                                options:0];
                    NSInteger betweenDays = [componentsBetween day] * 0.1;
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    if((long)[components day]+ 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                    }else if ((long)[components day]+ 1 > betweenDays){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                    }else if((long)[components day]+ 1 > 0 && (long)[components day]+ 1 <= betweenDays){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day]+ 1 == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            cell.btnAnnual.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                    NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    float benchmark = 0;
                    switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                        case 1:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 2.5f;
                            break;
                        }
                        case 2:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 5;
                            break;
                        }
                        case 3:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 10;
                            break;
                        }
                        case 4:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 200;
                            break;
                        }
                        default:
                            break;
                    }
                    NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                        if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                            parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                            break;
                        }
                    }
                    
                    NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                    if([differenceTach floatValue] < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        NSDecimalNumber *absDifferenceTach = [parentTach decimalNumberBySubtracting:currentTach];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [absDifferenceTach stringValue]];
                        
                    }else if ([differenceTach floatValue] > benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] > 0 && [differenceTach floatValue] <= benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
            
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 3){
            cell.btnPopupLook.hidden = NO;
        }
        return cell;
    }else if (tableView == limitedPartTableView){
        static NSString *simpleTableIdentifier = @"ItemCellIdentifier";
        ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ItemCell sharedCell];
        }
        cell.itemDelegate = self;
        cell.btnAnnual.hidden = YES;
        cell.txtContent.delegate = cell;
        NSDictionary *dict = [arrLifeLimitedPartItems objectAtIndex:indexPath.row];
        if ([[dict objectForKey:@"isDelete"] boolValue]){
            cell.delegate = self;
            cell.leftUtilityButtons = [self leftButtons];
            cell.rightUtilityButtons = [self rightButtons];
        }
        
        
        cell.lblFieldName.text = [dict objectForKey:@"fieldName"];
        cell.txtContent.text = [dict objectForKey:@"content"];
        cell.txtContent.placeholder = @"Optional";
        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        
        cell.lblBannerAlertCount.hidden = YES;
        cell.btnPopup.hidden = YES;
        cell.btnPopupLook.hidden = YES;
        cell.currentReading.hidden = YES;
        
        if ([[dict objectForKey:@"fieldName"] isEqualToString:@"ELT Battery"]){
            cell.btnAnnual.hidden = NO;
        }
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            cell.btnPopup.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    
                    if((long)[components day] + 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                        
                    }else if ((long)[components day] + 1 > 10){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day]+ 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if((long)[components day] + 1 > 0 && (long)[components day] + 1 <= 10){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day] + 1 == 0){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.txtContent.textColor = [UIColor redColor];
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    cell.btnPopup.hidden = YES;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    NSDate *date2 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"startDate"] ];
                    NSDateComponents *componentsBetween = [gregorianCalendar components:NSCalendarUnitDay
                                                                               fromDate:date2
                                                                                 toDate:date1
                                                                                options:0];
                    NSInteger betweenDays = [componentsBetween day] * 0.1;
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    if((long)[components day]+ 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                    }else if ((long)[components day]+ 1 > betweenDays){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                    }else if((long)[components day]+ 1 > 0 && (long)[components day]+ 1 <= betweenDays){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day]+ 1 == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            cell.btnAnnual.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                    NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    float benchmark = 0;
                    switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                        case 1:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 2.5f;
                            break;
                        }
                        case 2:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 5;
                            break;
                        }
                        case 3:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 10;
                            break;
                        }
                        case 4:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 200;
                            break;
                        }
                        default:
                            break;
                    }
                    NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                        if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                            parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                            break;
                        }
                    }
                    
                    NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                    if([differenceTach floatValue] < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        NSDecimalNumber *absDifferenceTach = [parentTach decimalNumberBySubtracting:currentTach];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [absDifferenceTach stringValue]];
                        
                    }else if ([differenceTach floatValue] > benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] > 0 && [differenceTach floatValue] <= benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
            
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 3){
            cell.btnPopupLook.hidden = NO;
        }
        return cell;
    }else if (tableView == otherPartTableView){
        static NSString *simpleTableIdentifier = @"ItemCellIdentifier";
        ItemCell *cell = (ItemCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [ItemCell sharedCell];
        }
        cell.btnAnnual.hidden = YES;
        cell.delegate = self;
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.itemDelegate = self;
        cell.txtContent.delegate = cell;
        NSDictionary *dict = [arrOtherItems objectAtIndex:indexPath.row];
        cell.lblFieldName.text = [dict objectForKey:@"fieldName"];
        cell.txtContent.text = [dict objectForKey:@"content"];
        cell.txtContent.placeholder = @"Optional";
        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        
        cell.lblBannerAlertCount.hidden = YES;
        cell.btnPopup.hidden = YES;
        cell.btnPopupLook.hidden = YES;
        cell.currentReading.hidden = YES;
        if (([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 2)){
            cell.btnPopup.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"singleDate"] integerValue] != 0){
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[dict objectForKey:@"content"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    
                    if((long)[components day] + 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                        
                    }else if ((long)[components day] + 1 > 10){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day]+ 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if((long)[components day] + 1 > 0 && (long)[components day] + 1 <= 10){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day] + 1 == 0){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.txtContent.textColor = [UIColor redColor];
                    }
                }
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDate"] integerValue] != 0){
                    cell.btnPopup.hidden = YES;
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"endDate"] ];
                    
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    NSDate *date2 = [dateFormat dateFromString:[[dict objectForKey:@"setting"] objectForKey:@"startDate"] ];
                    NSDateComponents *componentsBetween = [gregorianCalendar components:NSCalendarUnitDay
                                                                               fromDate:date2
                                                                                 toDate:date1
                                                                                options:0];
                    NSInteger betweenDays = [componentsBetween day] * 0.1;
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1];
                    if((long)[components day]+ 1 < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", -1 * ((long)[components day] + 1)];
                    }else if ((long)[components day]+ 1 > betweenDays){
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                    }else if((long)[components day]+ 1 > 0 && (long)[components day]+ 1 <= betweenDays){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                        if ((long)[components day] + 1 == (int)[[[dict objectForKey:@"setting"] objectForKey:@"multiDateNotifiNumPrior"] integerValue]){
                            [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                    }else if ((long)[components day]+ 1 == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dict objectForKey:@"fieldName"] isEqual:@"TACH"]){
            cell.btnAnnual.hidden = NO;
            if (![[dict objectForKey:@"content"] isEqualToString:@""]) {
                if((int)[[[dict objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                    NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    float benchmark = 0;
                    switch ([[[dict objectForKey:@"setting"] objectForKey:@"TachType"] integerValue]) {
                        case 1:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 2.5f;
                            break;
                        }
                        case 2:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 5;
                            break;
                        }
                        case 3:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 10;
                            break;
                        }
                        case 4:{
                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:[[[dict objectForKey:@"setting"] objectForKey:@"TachValue"] stringValue]];
                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                currentTach = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                            }
                            benchmark = 200;
                            break;
                        }
                        default:
                            break;
                    }
                    NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                        if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                            parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                            break;
                        }
                    }
                    
                    NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                    differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                    
                    cell.lblBannerAlertCount.hidden = NO;
                    cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                    if([differenceTach floatValue] < 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        NSDecimalNumber *absDifferenceTach = [parentTach decimalNumberBySubtracting:currentTach];
                        cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [absDifferenceTach stringValue]];
                        
                    }else if ([differenceTach floatValue] > benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] > 0 && [differenceTach floatValue] <= benchmark){
                        cell.txtContent.textColor = [UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:1.0f green:194.0f/255.0f blue:0 alpha:1.0f]];
                        
                    }else if ([differenceTach floatValue] == 0){
                        cell.txtContent.textColor = [UIColor redColor];
                        [cell.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                    }
                }
            }
            
        }
        if ([[dict objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dict objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dict objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 3){
            cell.btnPopupLook.hidden = NO;
        }
        return cell;
    }else if (tableView == SquawksTableView){
        static NSString *simpleTableIdentifier = @"SquawksItem";
        SquawksCell *cell = (SquawksCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [SquawksCell sharedCell];
        }
        cell.delegate = self;
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        cell.lblSquawks.text = [arrSquawks objectAtIndex:indexPath.row];
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == AirCraftTableView) {
        aircraftToEdit = [arrAircraft objectAtIndex:indexPath.row];
        
        addAircraftView.hidden = NO;
        [[AppDelegate sharedDelegate] stopThreadToSyncData:5];
        
        [arrAircraftItems removeAllObjects];
        NSData *data = [aircraftToEdit.aircraftItems dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        arrAircraftItems = [json mutableCopy];
        for (NSDictionary *fieldInfo in arrAircraftItems) {
            if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
                lblAircraftTitle.text = [fieldInfo objectForKey:@"content"];
            }
        }
        
        [arrMaintainesItems removeAllObjects];
        data = [aircraftToEdit.maintenanceItems dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil){
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]    ;
        arrMaintainesItems = [json mutableCopy];
        }
        
        [arrAvionics removeAllObjects];
        data = [aircraftToEdit.avionicsItems dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil){
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        arrAvionics = [json mutableCopy];
        }
        
        [arrLifeLimitedPartItems removeAllObjects];
        data = [aircraftToEdit.liftLimitedParts dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil){
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        arrLifeLimitedPartItems = [json mutableCopy];
        }
        
        [arrOtherItems removeAllObjects];
        data = [aircraftToEdit.otherItems dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil){
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        arrOtherItems = [json mutableCopy];
        }
        
        [arrSquawks removeAllObjects];
        data = [aircraftToEdit.squawksItems dataUsingEncoding:NSUTF8StringEncoding];
        if (data != nil){
            json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            arrSquawks = [NSMutableArray arrayWithArray:json];
        }
//        if (json != nil) {
//            arrSquawks = [NSMutableArray arrayWithArray:json];
//        }
        
        [self resizeAddingAircraftView];
        [self resizeAddingAircraftItemView];
        
        [AirCraftItemTableView reloadData];
        [MaintaineTableView reloadData];
        [AvionicsTableView reloadData];
        [limitedPartTableView reloadData];
        [otherPartTableView reloadData];
        [SquawksTableView reloadData];
        
        aircraftAddingDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.2 delay:0 options:    UIViewAnimationOptionCurveEaseOut animations:^{
            // animate it to the identity transform (100% scale)
            aircraftAddingDialog.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
        }];
        
    }else if (tableView == MaintaineTableView){
        
    }else if (tableView == AvionicsTableView){
        
    }else if (tableView == AirCraftItemTableView){
        
    }else if (tableView == limitedPartTableView){
        
    }else if (tableView == otherPartTableView){
        
    }
}
// popup for Category and Class
- (void) popUpPickerDialog:(NSInteger)type withIndex:(NSInteger)index{
    PickerWithDataViewController *pickView = [[PickerWithDataViewController alloc] initWithNibName:@"PickerWithDataViewController" bundle:nil];
    [pickView.view setFrame:self.view.bounds];
    pickView.delegate = self;
    pickView.pickerType = type;
    pickView.cellIndexForEndorsement = index;
    [self displayContentController:pickView];
    [pickView animateShow];
}

- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}

#pragma  mark DateViewContrllerDelegate
- (void)didCancelDateView:(DateViewController *)dateView{
    currentDateDialogSuper.btnPopup.hidden = NO;
    currentDateDialogSuper.txtContent.hidden = NO;
    
    [btnStartDate setEnabled:YES];
    [btnEndDate setEnabled:YES];
    txtStartDate.hidden = NO;
    txtEndDate.hidden = NO;
    
}
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    currentDateDialogSuper.btnPopup.hidden = NO;
    currentDateDialogSuper.txtContent.hidden = NO;
    if (currentDateDialogSuper != nil && addAircraftItemView.hidden){
        currentDateDialogSuper.txtContent.text = _strDate;
        
        UITableView *tableview;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
            tableview = (UITableView *)[(UITableViewCell *)currentDateDialogSuper superview];
        }else{
            tableview = (UITableView *)[[(UITableViewCell *)currentDateDialogSuper superview] superview];
        }
        
        NSIndexPath *indexPath = [tableview indexPathForCell:currentDateDialogSuper];
        
        id tmp;
        
        NSString *filedName;
        
        if (tableview == AirCraftItemTableView){
            tmp = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            filedName = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        }else if (tableview == MaintaineTableView){
            tmp = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            filedName = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        }else if (tableview == AvionicsTableView){
            tmp = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
            filedName = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        }else if (tableview == limitedPartTableView){
            tmp = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            filedName = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        }else if (tableview == otherPartTableView){
            tmp = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            filedName = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        }
        
        if ([tmp isKindOfClass:[NSDictionary class]]) {
            NSDictionary *tmpDic = tmp;
            if (tmpDic != nil) {
                if((int)[[tmpDic objectForKey:@"singleDate"] integerValue] != 0){
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM/dd/yyyy"];
                    NSDate *date1 = [dateFormat dateFromString:_strDate];
                    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                                        fromDate:[NSDate date]
                                                                          toDate:date1
                                                                         options:0];
                    
                    [currentDateDialogSuper.lblBannerAlertCount setBackgroundColor:[UIColor greenColor]];
                    
                    if((long)[components day] + 1 < 0){
                        currentDateDialogSuper.txtContent.textColor = [UIColor redColor];
                        
                    }else if ((long)[components day] + 1 > 0){
                        currentDateDialogSuper.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                        
                        if ((long)[components day] + 1 == (int)[[tmpDic objectForKey:@"notiNumberOfDaysPrior"] integerValue]){
                            [currentDateDialogSuper.lblBannerAlertCount setBackgroundColor:[UIColor redColor]];
                        }
                        
                        
                        currentDateDialogSuper.lblBannerAlertCount.hidden = NO;
                        currentDateDialogSuper.lblBannerAlertCount.text = [NSString stringWithFormat:@"%ld", (long)[components day] + 1 ];
                        
                    }else if ((long)[components day] + 1 == 0){
                        
                    }
                    
                }
            }
        }
        currentDateDialogSuper = nil;
    }else{
        
        [btnStartDate setEnabled:YES];
        [btnEndDate setEnabled:YES];
        [txtStartDate setEnabled:NO];
        [txtEndDate setEnabled:NO];
        
        currentDateDialog.text = _strDate;
    }
    
    
}

#pragma mark PickerWithDataViewController
- (void)didCancelPickerView:(PickerWithDataViewController *)pickerView{
    currentDateDialogSuper.btnPopupLook.hidden = NO;
    currentDateDialogSuper.txtContent.hidden = NO;
    [self removeCurrentViewFromSuper:pickerView];
}
- (void)returnValueFromPickerView:(PickerWithDataViewController *)pickerView withSelectedString:(NSString *)toString withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index{
    currentDateDialogSuper.btnPopupLook.hidden = NO;
    currentDateDialogSuper.txtContent.hidden = NO;
    [self removeCurrentViewFromSuper:pickerView];
    [self setCurrentItemFromPicker:toString withType:_type withText:_text withIndex:index];
}


- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}

- (void)setCurrentItemFromPicker:(NSString *)componentStr withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index{
    
    if (_type == 1) {
        currentDateDialogSuper.txtContent.text = componentStr;
    }else if(_type == 2){
        currentDateDialogSuper.txtContent.text = componentStr;
    }else if(_type == 3){
        
    }else if(_type == 4){
        currentDateDialogSuper.txtContent.text = componentStr;
    }
    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[currentDateDialogSuper superview];
    }else{
        tableview = (UITableView *)[[currentDateDialogSuper superview] superview];
    }
    NSIndexPath *indexPath = [tableview indexPathForCell:currentDateDialogSuper];
    NSDictionary *dictToCheck;
    if (tableview == AirCraftItemTableView) {
        indexPath = [AirCraftItemTableView indexPathForCell:currentDateDialogSuper];
        dictToCheck = [arrAircraftItems objectAtIndex:indexPath.row];
        [arrAircraftItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", currentDateDialogSuper.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == MaintaineTableView) {
        indexPath = [MaintaineTableView indexPathForCell:currentDateDialogSuper];
        dictToCheck = [arrMaintainesItems objectAtIndex:indexPath.row];
        [arrMaintainesItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", currentDateDialogSuper.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == AvionicsTableView) {
        indexPath = [AvionicsTableView indexPathForCell:currentDateDialogSuper];
        dictToCheck = [arrAvionics objectAtIndex:indexPath.row];
        [arrAvionics replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", currentDateDialogSuper.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == limitedPartTableView) {
        indexPath = [limitedPartTableView indexPathForCell:currentDateDialogSuper];
        dictToCheck = [arrLifeLimitedPartItems objectAtIndex:indexPath.row];
        [arrLifeLimitedPartItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", currentDateDialogSuper.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == otherPartTableView) {
        indexPath = [otherPartTableView indexPathForCell:currentDateDialogSuper];
        dictToCheck = [arrOtherItems objectAtIndex:indexPath.row];
        [arrOtherItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", currentDateDialogSuper.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
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
- (NSArray *)rightButtonsForSetting
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Setting"];
    
    return rightUtilityButtons;
}
- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor greenColor] title:@"Edit"];
    
    return leftUtilityButtons;
}

- (void)reloadTachTextViewsWithType:(NSInteger)type{
    txt25TachLastDone.text = @"";
    txt50TachLastDone.text = @"";
    txt100TachLastDone.text = @"";
    txt2000TachLastDone.text = @"";
    txt25TachNextDue.text = @"";
    txt50TachNextDue.text = @"";
    txt100TachNextDue.text = @"";
    txt2000TachNextDue.text = @"";
    txt25TachNextDue.text = @"";
    
    switch (type) {
        case 1:
        {
            txt25TachLastDone.enabled = YES;
            txt50TachLastDone.enabled = NO;
            txt100TachLastDone.enabled = NO;
            txt2000TachLastDone.enabled = NO;
        }
            break;
        case 2:
        {
            txt25TachLastDone.enabled = NO;
            txt50TachLastDone.enabled = YES;
            txt100TachLastDone.enabled = NO;
            txt2000TachLastDone.enabled = NO;
        }
            break;
        case 3:
        {
            txt25TachLastDone.enabled = NO;
            txt50TachLastDone.enabled = NO;
            txt100TachLastDone.enabled = YES;
            txt2000TachLastDone.enabled = NO;
        }
            break;
        case 4:
        {
            txt25TachLastDone.enabled = NO;
            txt50TachLastDone.enabled = NO;
            txt100TachLastDone.enabled = NO;
            txt2000TachLastDone.enabled = YES;
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            if ([cell.reuseIdentifier  isEqual: @"ItemCellIdentifier"]){
                
                [self initNewAircraftItemForm];
                craftItemToEdit = cell;
                
                UITableView *tableview;
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                    tableview = (UITableView *)[(UITableViewCell *)cell superview];
                }else{
                    tableview = (UITableView *)[[(UITableViewCell *)cell superview] superview];
                }
                NSIndexPath *indexPath = [tableview indexPathForCell:cell];
                
                id tmp;
                
                BOOL existSetting = NO;
                
                isAnnualInspection = NO;
                if (tableview == AirCraftItemTableView){
                    typeToAddItem = 1;
                    if (![[[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
                        existSetting = YES;
                        tmp = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
                    }
                    txtFieldName.text = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
                    lblTitleToAddNewItem.text = @"Edit Aircraft Item";
                }else if (tableview == MaintaineTableView){
                    typeToAddItem = 2;
                    if (![[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
                        existSetting = YES;
                        tmp = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
                    }
                    txtFieldName.text = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
                    lblTitleToAddNewItem.text = @"Edit Maintenance";
                    if ([[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"Annual Inspection"] || [[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"ELT Inspection"] || [[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"Pitot-Static"] || [[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"ELT Battery Exp."]){
                        isAnnualInspection = YES;
                    }
                }else if (tableview == AvionicsTableView){
                    typeToAddItem = 3;
                    if (![[[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
                        existSetting = YES;
                        tmp = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
                    }
                    txtFieldName.text = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
                    lblTitleToAddNewItem.text = @"Edit Avionics";
                    if ([[[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"VOR Test"] || [[[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"NavData"] || [[[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"Charts"]){
                        isAnnualInspection = YES;
                    }
                }else if (tableview == limitedPartTableView){
                    typeToAddItem = 4;
                    if (![[[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
                        existSetting = YES;
                        tmp = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
                    }
                    txtFieldName.text = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
                    lblTitleToAddNewItem.text = @"Edit Life Limited Part";
                    if ([[[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"ELT Battery"]){
                        isAnnualInspection = YES;
                    }
                }else if (tableview == otherPartTableView){
                    typeToAddItem = 5;
                    if (![[[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
                        existSetting = YES;
                        tmp = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
                    }
                    txtFieldName.text = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
                    lblTitleToAddNewItem.text = @"Edit Other Item";
                }
                
                addAircraftItemView.hidden = NO;
                
                if (existSetting){
                    if((int)[[tmp objectForKey:@"type"] integerValue] == 1){
                        optionValue.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
                        optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        filledType = 1;
                        txtValueMaxNum.text = [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"MaxNumberOfCharacters"] integerValue]];
                        if ([[tmp objectForKey:@"TachBasedNoti"] boolValue] == 1) {
                            if ([[tmp objectForKey:@"TachType"] integerValue] > 0) {
                                [self reloadTachTextViewsWithType:[[tmp objectForKey:@"TachType"] integerValue]];
                                if ([tmp objectForKey:@"TachValue"] && [[tmp objectForKey:@"TachValue"] floatValue] > 0) {
                                    switch ([[tmp objectForKey:@"TachType"] integerValue]) {
                                        case 1:{
                                            txt25TachLastDone.text = [[tmp objectForKey:@"TachValue"] stringValue];
                                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:txt25TachLastDone.text];
                                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
                                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                                NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                                                txt25TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
                                            }
                                            break;
                                        }
                                        case 2:{
                                            txt50TachLastDone.text = [[tmp objectForKey:@"TachValue"] stringValue];
                                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:txt50TachLastDone.text];
                                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
                                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                                NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                                                txt50TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
                                            }
                                            break;
                                        }
                                        case 3:{
                                            txt100TachLastDone.text = [[tmp objectForKey:@"TachValue"] stringValue];
                                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:txt100TachLastDone.text];
                                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
                                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                                NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                                                txt100TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
                                            }
                                            break;
                                        }
                                        case 4:{
                                            txt2000TachLastDone.text = [[tmp objectForKey:@"TachValue"] stringValue];
                                            NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:txt2000TachLastDone.text];
                                            NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
                                            if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
                                                NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
                                                txt2000TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
                                            }
                                            break;
                                        }
                                        default:
                                            break;
                                    }
                                }
                                
                            }
                        }
                    }else if ((int)[[tmp objectForKey:@"type"] integerValue] == 2){
                        optionValue.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        optionDate.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
                        optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        filledType = 2;
                        txtStartDate.text = [tmp objectForKey:@"startDate"];
                        txtEndDate.text = [tmp objectForKey:@"endDate"];
                    }else{
                        optionValue.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
                        optionLookUp.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
                        filledType = 3;
                        txtLookupValue1.text = [tmp objectForKey:@"lookupV1"];
                        txtLookupValue2.text = [tmp objectForKey:@"lookupV2"];
                        txtLookupValue3.text = [tmp objectForKey:@"lookupV3"];
                        txtLookupValue4.text = [tmp objectForKey:@"lookupV4"];
                        txtLookupValue5.text = [tmp objectForKey:@"lookupV5"];
                        txtLookupValue6.text = [tmp objectForKey:@"lookupV6"];
                        txtLookupValue7.text = [tmp objectForKey:@"lookupV7"];
                        txtLookupValue8.text = [tmp objectForKey:@"lookupV8"];
                    }
                    [btnCheckMNC setImage:nil forState:UIControlStateNormal];
                    
                    if ([[tmp objectForKey:@"MaxNumberOfCharacters"]  integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        txtValueMaxNum.text =  [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"MaxNumberOfCharacters"] integerValue] ];
                        isCheckedMNC = @"1";
                        if (isCheckedMNC) {
                            [btnCheckMNC setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckMNC setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    [btnCheckAlpha setImage:nil forState:UIControlStateNormal];
                    
                    if((int)[[tmp objectForKey:@"Alphanumeric"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        isCheckedAlpha = @"1";
                        if (isCheckedAlpha) {
                            [btnCheckAlpha setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckAlpha setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    [btnCheckLettersOnly setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"lettersOnly"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        isCheckedLetterOnly= @"1";
                        if (isCheckedLetterOnly) {
                            [btnCheckLettersOnly setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckLettersOnly setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    [btnCheckLettersCAPS setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"lettersCAPS"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        isCheckedLetterCAPs = @"1";
                        if (isCheckedLetterCAPs) {
                            [btnCheckLettersCAPS setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckLettersCAPS setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    [btnCheckNumbersOnly setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"NumbersOnly"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        isCheckedNumOnly= @"1";
                        if (isCheckedNumOnly) {
                            [btnCheckNumbersOnly setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckNumbersOnly setImage:nil forState:UIControlStateNormal];
                        }
                    }
                    [btnCheckTachBasedNoti setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"TachBasedNoti"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 1)) break;
                        isCheckedTachBasedNoti= @"1";
                        if (isCheckedTachBasedNoti) {
                            [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                            typeOfTach = [[tmp objectForKey:@"TachType"] integerValue];
                            [btnSubTach25 setImage:nil forState:UIControlStateNormal];
                            [btnSubTach50 setImage:nil forState:UIControlStateNormal];
                            [btnSubTach100 setImage:nil forState:UIControlStateNormal];
                            [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
                            switch (typeOfTach) {
                                case 1:
                                {
                                    [btnSubTach25 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                                    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
                                    break;
                                }
                                case 2:
                                {
                                    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach50 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                                    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
                                    break;
                                }
                                case 3:
                                {
                                    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach100 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                                    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
                                    break;
                                }
                                case 4:
                                {
                                    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
                                    [btnSubTach2000 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                                    break;
                                }
                                default:
                                    break;
                            }
                        }else{
                            [btnCheckTachBasedNoti setImage:nil forState:UIControlStateNormal];
                        }
                    }
                    [btnCheckSD setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"singleDate"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        
                        isCheckedSD= @"1";
                        if (isCheckedSD) {
                            [btnCheckSD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckSD setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    [btnCheckMultiDate setImage:nil forState:UIControlStateNormal];
                    if((int)[[tmp objectForKey:@"multiDate"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        isCheckedMultiDate = !isCheckedMultiDate;
                        if (isCheckedMultiDate) {
                            [btnCheckMultiDate setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckMultiDate setImage:nil forState:UIControlStateNormal];
                        }
                        
                    }
                    
                    [btnCkeckNNDpD setImage:nil forState:UIControlStateNormal];
                    if ([[tmp objectForKey:@"notiNumberOfDaysPrior"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        txtNotiNumOfDaysPrior.text =  [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"notiNumberOfDaysPrior"] integerValue] ];
                        isCheckedNNDpD = @"1";
                        if (isCheckedNNDpD) {
                            [btnCkeckNNDpD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCkeckNNDpD setImage:nil forState:UIControlStateNormal];
                        }
                    }
                    [btnCheckNNDAD setImage:nil forState:UIControlStateNormal];
                    if ([[tmp objectForKey:@"notiNumberOfDaysAfter"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        txtNotiNumberOfDaysAfter.text =  [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"notiNumberOfDaysAfter"] integerValue] ];
                        isCheckedNNDAD = @"1";
                        if (isCheckedNNDAD) {
                            [btnCheckNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckNNDAD setImage:nil forState:UIControlStateNormal];
                        }
                    }
                    [btnCheckMultiNNDAD setImage:nil forState:UIControlStateNormal];
                    if ([[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        txtMultiDateNotifiNumAfter.text =  [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue] ];
                        isCheckedMultiNNDAD = @"1";
                        if (isCheckedMultiNNDAD) {
                            [btnCheckMultiNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckMultiNNDAD setImage:nil forState:UIControlStateNormal];
                        }
                    }
                    [btnCheckMultiNDPED setImage:nil forState:UIControlStateNormal];
                    if ([[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue] != 0){
                        if(!((int)[[tmp objectForKey:@"type"] integerValue] == 2)) break;
                        txtMultiDateNotiNumPrior.text = [NSString stringWithFormat:@"%ld",[[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue] ];
                        isCheckedMultiNDPED = @"1";
                        if (isCheckedMultiNDPED) {
                            [btnCheckMultiNDPED setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                        }else{
                            [btnCheckMultiNDPED setImage:nil forState:UIControlStateNormal];
                        }
                    }
                }
                if (isAnnualInspection) {
                    isCheckedMultiNNDAD = YES;
                    [btnCheckMultiNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                    
                    isCheckedMultiNDPED = YES;
                    [btnCheckMultiNDPED setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                }
                
                addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    // animate it to the identity transform (100% scale)
                    addAircraftitemDialog.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    
                }];
            }else if ([cell.reuseIdentifier  isEqual: @"SquawksItem"]){
                NSIndexPath *indexPathForSquawk = [SquawksTableView indexPathForCell:cell];
                squawkTxtView.text = [arrSquawks objectAtIndex:indexPathForSquawk.row];
                lblSquawksTitle.text = @"Edit Squawk";
                [btnSaveUpdateSquawks setTitle:@"Update" forState:UIControlStateNormal];
                currentSquawkItemToEdit = indexPathForSquawk.row;
                addSquawkItemView.hidden = NO;
                [squawkTxtView becomeFirstResponder];
                addSquawkDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
                [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    // animate it to the identity transform (100% scale)
                    addSquawkDialog.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished){
                    
                }];
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
            if ([cell.reuseIdentifier  isEqual: @"ItemCellIdentifier"]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current item?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    
                    UITableView *tableview;
                    
                    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                        tableview = (UITableView *)[(UITableViewCell *)cell superview];
                    }else{
                        tableview = (UITableView *)[[(UITableViewCell *)cell superview] superview];
                    }
                    
                    NSIndexPath *indexPath = [tableview indexPathForCell:cell];
                    
                    if (tableview == AirCraftItemTableView) {
                        [arrAircraftItems removeObjectAtIndex:indexPath.row];
                    }else if(tableview == MaintaineTableView) {
                        [arrMaintainesItems removeObjectAtIndex:indexPath.row];
                    }else if(tableview == AvionicsTableView) {
                        [arrAvionics removeObjectAtIndex:indexPath.row];
                    }else if(tableview == limitedPartTableView) {
                        [arrLifeLimitedPartItems removeObjectAtIndex:indexPath.row];
                    }else if(tableview == otherPartTableView) {
                        [arrOtherItems removeObjectAtIndex:indexPath.row];
                    }
                    
                    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                        [(UITableView *)[(UITableViewCell *)cell superview] deleteRowsAtIndexPaths:[NSArray arrayWithObjects: indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
                    }else{
                        [(UITableView *)[[(UITableViewCell *)cell superview] superview] deleteRowsAtIndexPaths:[NSArray arrayWithObjects: indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
                    }
                    
                    [self initArrItems];
                    [self resizeAddingAircraftView];
                    [self resizeAddingAircraftItemView];
                    
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                    
                }];
                
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
                
            }else if ([cell.reuseIdentifier  isEqual: @"SquawksItem"]){
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current Squawk?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    NSIndexPath *indexPath = [SquawksTableView indexPathForCell:cell];
                    [arrSquawks removeObjectAtIndex:indexPath.row];
                    [SquawksTableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects: indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
                    
                    [self initArrItems];
                    [self resizeAddingAircraftView];
                    [self resizeAddingAircraftItemView];
                    
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                    
                }];
                
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
                
            }else{
                
                NSIndexPath *indexPath = [AirCraftTableView indexPathForCell:cell];
                Aircraft *aircraftToDelete = [arrAircraft objectAtIndex:indexPath.row];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current Aircraft?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    
                    NSError *error = nil;
                    [contextRecords deleteObject:aircraftToDelete];
                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                    deleteQuery.type = @"aircraft";
                    deleteQuery.idToDelete = aircraftToDelete.aircraftID;
                    [contextRecords save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                    
                    [self reloadData];
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

- (IBAction)onCancelAirCraftAdding:(id)sender {
    [self.view endEditing:YES];
    addAircraftView.hidden = YES;
    [arrAircraftItems removeAllObjects];
    [arrMaintainesItems removeAllObjects];
    [arrAvionics removeAllObjects];
    [arrLifeLimitedPartItems removeAllObjects];
    [arrOtherItems removeAllObjects];
    [arrSquawks removeAllObjects];
    
    aircraftToEdit = nil;
    btnAircraftSave.hidden = NO;
    [paintView removeFromSuperview];
    currentDateDialogSuper = nil;

    [[AppDelegate sharedDelegate] startThreadToSyncData:5];
    
    isExpanedOfmaintenanceLogsView = NO;
    CGRect rectOfLogs = maintenanceLogsView.frame;
    rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 50.0f;
    rectOfLogs.size.height = 50.0f;
    maintenanceLogsView.frame = rectOfLogs;
    MaintenanceCollectionView.hidden = YES;
    btnCloseOfLogs.hidden = YES;
    btnDeleteLogs.hidden = YES;
    btnAddLogs.hidden = YES;
    isDeleteMode = NO;
    UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
    btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
    [selectedThumbViews removeAllObjects];
}

- (IBAction)onSaveAirCraftAdding:(id)sender {
    [self.view endEditing:YES];
    if (arrAircraftItems == nil || arrAircraftItems.count == 0) {
        [self showAlert:@"Please input Registration" :@"Input Error"];
        return;
    }
    for (NSDictionary *fieldInfo in arrAircraftItems) {
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Registration" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Model"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Model" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Variant"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Variant" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Year"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Year" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Category"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Category" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"Class"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input Class" :@"Input Error"];
                return;
            }
        }
        if ([[fieldInfo objectForKey:@"fieldName"] isEqualToString:@"MTOW"]) {
            if ([[fieldInfo objectForKey:@"content"] isEqualToString:@""]) {
                [self showAlert:@"Please input MTOW" :@"Input Error"];
                return;
            }
        }
    }
    [self initArrItems];
    
    NSError *error;
    if (aircraftToEdit == nil) {
        
        //save created aircraft into local
        Aircraft *aircraft = [NSEntityDescription insertNewObjectForEntityForName:@"Aircraft" inManagedObjectContext:contextRecords];
        aircraft.aircraftID = @(0);
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arrAircraftItems
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.aircraftItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrMaintainesItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.maintenanceItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrAvionics
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.avionicsItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrLifeLimitedPartItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.liftLimitedParts = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrOtherItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.otherItems = jsonString;
        
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrSquawks
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraft.squawksItems = jsonString;
        
        aircraft.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.valueForSort = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.aircraft_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.lastUpdate = @(0);
    }else{
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arrAircraftItems
                                                           options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.aircraftItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrMaintainesItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.maintenanceItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrAvionics
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.avionicsItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrLifeLimitedPartItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.liftLimitedParts = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrOtherItems
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.otherItems = jsonString;
        
        jsonData = [NSJSONSerialization dataWithJSONObject:arrSquawks
                                                   options:NSJSONWritingPrettyPrinted error:&error];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        aircraftToEdit.squawksItems = jsonString;
        
        aircraftToEdit.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraftToEdit.lastUpdate = @(0);
        aircraftToEdit.valueForSort = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    }
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    
    [self reloadData];
    
    [self resizeAircraftView];
    
    [[AppDelegate sharedDelegate] cleanAllLocalNotifications];
    [[AppDelegate sharedDelegate] registerLocalNotifications];
    
    [self.view endEditing:YES];
    addAircraftView.hidden = YES;
    [arrAircraftItems removeAllObjects];
    [arrMaintainesItems removeAllObjects];
    [arrAvionics removeAllObjects];
    [arrLifeLimitedPartItems removeAllObjects];
    [arrOtherItems removeAllObjects];
    [arrSquawks removeAllObjects];
    aircraftToEdit = nil;
    currentDateDialogSuper = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_AIRCRAFT_BADGE object:nil userInfo:nil];
    
    [[AppDelegate sharedDelegate] startThreadToSyncData:5];
    
    isExpanedOfmaintenanceLogsView = NO;
    CGRect rectOfLogs = maintenanceLogsView.frame;
    rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 50.0f;
    rectOfLogs.size.height = 50.0f;
    maintenanceLogsView.frame = rectOfLogs;
    MaintenanceCollectionView.hidden = YES;
    btnCloseOfLogs.hidden = YES;
    btnDeleteLogs.hidden = YES;
    btnAddLogs.hidden = YES;
    isDeleteMode = NO;
    UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
    btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
    [selectedThumbViews removeAllObjects];
    
}
-(void)initArrItems
{
    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
    NSInteger rows =  [MaintaineTableView numberOfRowsInSection:0];
    for (int row = 0; row < rows; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        ItemCell *cell = (ItemCell *)[MaintaineTableView cellForRowAtIndexPath:indexPath];
        NSDictionary *dict = [arrMaintainesItems objectAtIndex:indexPath.row];
        
        [tmpArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:cell.lblFieldName.text,@"fieldName", cell.txtContent.text, @"content",[dict objectForKey:@"setting"], @"setting",[dict objectForKey:@"isDelete"], @"isDelete", nil]];
        
    }
    if (rows < arrMaintainesItems.count) {
        for (NSInteger i = rows; i < arrMaintainesItems.count; i ++) {
            NSDictionary *dict = [arrMaintainesItems objectAtIndex:i];
            [tmpArray addObject:dict];
        }
    }
    [arrMaintainesItems removeAllObjects];
    arrMaintainesItems = [tmpArray mutableCopy];
    
    [tmpArray removeAllObjects];
    rows =  [AirCraftItemTableView numberOfRowsInSection:0];
    for (int row = 0; row < rows; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        ItemCell *cell = (ItemCell *)[AirCraftItemTableView cellForRowAtIndexPath:indexPath];
        NSDictionary *dict = [arrAircraftItems objectAtIndex:indexPath.row];
        [tmpArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:cell.lblFieldName.text,@"fieldName", cell.txtContent.text, @"content",[dict objectForKey:@"setting"], @"setting",[dict objectForKey:@"isDelete"], @"isDelete", nil]];
        
    }
    if (rows < arrAircraftItems.count) {
        for (NSInteger i = rows; i < arrAircraftItems.count; i ++) {
            NSDictionary *dict = [arrAircraftItems objectAtIndex:i];
            [tmpArray addObject:dict];
        }
    }
    [arrAircraftItems removeAllObjects];
    arrAircraftItems = [tmpArray mutableCopy];
    
    [tmpArray removeAllObjects];
    rows =  [limitedPartTableView numberOfRowsInSection:0];
    for (int row = 0; row < rows; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        ItemCell *cell = (ItemCell *)[limitedPartTableView cellForRowAtIndexPath:indexPath];
        NSDictionary *dict = [arrLifeLimitedPartItems objectAtIndex:indexPath.row];
        [tmpArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:cell.lblFieldName.text,@"fieldName", cell.txtContent.text, @"content",[dict objectForKey:@"setting"], @"setting",[dict objectForKey:@"isDelete"], @"isDelete", nil]];
        
    }
    if (rows < arrLifeLimitedPartItems.count) {
        for (NSInteger i = rows; i < arrLifeLimitedPartItems.count; i ++) {
            NSDictionary *dict = [arrLifeLimitedPartItems objectAtIndex:i];
            [tmpArray addObject:dict];
        }
    }
    [arrLifeLimitedPartItems removeAllObjects];
    arrLifeLimitedPartItems = [tmpArray mutableCopy];
    
    [tmpArray removeAllObjects];
    rows =  [otherPartTableView numberOfRowsInSection:0];
    for (int row = 0; row < rows; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        ItemCell *cell = (ItemCell *)[otherPartTableView cellForRowAtIndexPath:indexPath];
        NSDictionary *dict = [arrOtherItems objectAtIndex:indexPath.row];
        [tmpArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:cell.lblFieldName.text,@"fieldName", cell.txtContent.text, @"content",[dict objectForKey:@"setting"], @"setting",[dict objectForKey:@"isDelete"], @"isDelete", nil]];
        
    }
    if (rows < arrOtherItems.count) {
        for (NSInteger i = rows; i < arrOtherItems.count; i ++) {
            NSDictionary *dict = [arrOtherItems objectAtIndex:i];
            [tmpArray addObject:dict];
        }
    }
    [arrOtherItems removeAllObjects];
    arrOtherItems = [tmpArray mutableCopy];
    
    [tmpArray removeAllObjects];
    rows =  [AvionicsTableView numberOfRowsInSection:0];
    for (int row = 0; row < rows; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        ItemCell *cell = (ItemCell *)[AvionicsTableView cellForRowAtIndexPath:indexPath];
        NSDictionary *dict = [arrAvionics objectAtIndex:indexPath.row];
        [tmpArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:cell.lblFieldName.text,@"fieldName", cell.txtContent.text, @"content",[dict objectForKey:@"setting"], @"setting",[dict objectForKey:@"isDelete"], @"isDelete", nil]];
        
    }
    if (rows < arrAvionics.count) {
        for (NSInteger i = rows; i < arrAvionics.count; i ++) {
            NSDictionary *dict = [arrAvionics objectAtIndex:i];
            [tmpArray addObject:dict];
        }
    }
    [arrAvionics removeAllObjects];
    arrAvionics = [tmpArray mutableCopy];
}
- (IBAction)onAddNewMaintenance:(id)sender {
    typeToAddItem = 2;
    [self resizeAddingAircraftItemView];
    [self initNewAircraftItemForm];
    
    addAircraftItemView.hidden = NO;
    lblTitleToAddNewItem.text = @"Add Maintenance";
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}

- (IBAction)onAddNewAvionics:(id)sender {
    typeToAddItem = 3;
    [self resizeAddingAircraftItemView];
    [self initNewAircraftItemForm];
    lblTitleToAddNewItem.text = @"Add Avionics Database";
    addAircraftItemView.hidden = NO;
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}
- (IBAction)onAddLimitedPart:(UIButton *)sender{
    typeToAddItem = 4;
    [self resizeAddingAircraftItemView];
    [self initNewAircraftItemForm];
    lblTitleToAddNewItem.text = @"Add Life Limited Part";
    addAircraftItemView.hidden = NO;
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}
- (IBAction)onAddAirCraft:(id)sender {
    [[AppDelegate sharedDelegate] stopThreadToSyncData:5];
    addAircraftView.hidden = NO;
    
    lblAircraftTitle.text = @"";
    [arrAircraftItems removeAllObjects];
    [arrMaintainesItems removeAllObjects];
    [arrAvionics removeAllObjects];
    [arrLifeLimitedPartItems removeAllObjects];
    [arrOtherItems removeAllObjects];
    [arrSquawks removeAllObjects];
    [self initAircraftWithTempData];
    
    [AirCraftItemTableView reloadData];
    [MaintaineTableView reloadData];
    [AvionicsTableView reloadData];
    [limitedPartTableView reloadData];
    [otherPartTableView reloadData];
    [SquawksTableView reloadData];
    
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    
    aircraftAddingDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        aircraftAddingDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}


- (IBAction)onAddnewAircraftItem:(UIButton *)sender {
    typeToAddItem = 1;
    [self resizeAddingAircraftItemView];
    [self initNewAircraftItemForm];
    addAircraftItemView.hidden = NO;
    lblTitleToAddNewItem.text = @"New Aircraft Item";
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}

- (IBAction)onCancelAddCraftItem:(UIButton *)sender {
    addAircraftItemView.hidden = YES;
    isAnnualInspection = NO;
    annualEdit = nil;
    craftItemToEdit = nil;
    txtFieldName.text = @"";
    txtValueMaxNum.text = @"";
    txtStartDate.text = @"";
    txtEndDate.text = @"";
    txtLookupValue1.text = @"";
    txtLookupValue2.text = @"";
    txtLookupValue3.text = @"";
    txtLookupValue4.text = @"";
    txtLookupValue5.text = @"";
    txtLookupValue6.text = @"";
    txtLookupValue7.text = @"";
    txtLookupValue8.text = @"";
}

- (IBAction)onSaveAddCraftItem:(UIButton *)sender {
    if (!txtFieldName.text.length)
    {
        [self showAlert:@"Please input Field name" :@"Input Error"];
        return;
    }
    if (filledType == 1) {
        if (isCheckedMNC) {
            if (!txtValueMaxNum.text.length)
            {
                [self showAlert:@"Please input Max Number of Characters" :@"Input Error"];
                return;
            }
        }
        
        if (isCheckedTachBasedNoti) {
            switch (typeOfTach) {
                case 1:
                    if (!txt25TachLastDone.text.length)
                    {
                        [self showAlert:@"Please input Last Done" :@"Input Error"];
                        return;
                    }
                    break;
                case 2:
                    if (!txt50TachLastDone.text.length)
                    {
                        [self showAlert:@"Please input Last Done" :@"Input Error"];
                        return;
                    }
                    break;
                case 3:
                    if (!txt100TachLastDone.text.length)
                    {
                        [self showAlert:@"Please input Last Done" :@"Input Error"];
                        return;
                    }
                    break;
                case 4:
                    if (!txt2000TachLastDone.text.length)
                    {
                        [self showAlert:@"Please input Last Done" :@"Input Error"];
                        return;
                    }
                    break;
                    
                default:
                    break;
            }
        }
    }else if (filledType == 2){
        if (isCheckedNNDpD) {
            if (!txtNotiNumOfDaysPrior.text.length)
            {
                [self showAlert:@"Please input Notification Number Of Days prior to Date" :@"Input Error"];
                return;
            }
        }
        if (isCheckedNNDAD) {
            if (!txtNotiNumberOfDaysAfter.text.length)
            {
                [self showAlert:@"Please input Notification Number of Days After the Date" :@"Input Error"];
                return;
            }
        }
        if (isCheckedMultiDate) {
            
            if (!txtStartDate.text.length || !txtEndDate.text.length)
            {
                [self showAlert:@"Please input Date" :@"Input Error"];
                return;
            }
        }
        if (isCheckedMultiNNDAD) {
            if (!txtMultiDateNotifiNumAfter.text.length)
            {
                [self showAlert:@"Please input Notification Number of Days Prior to End Date" :@"Input Error"];
                return;
            }
        }
        if (isCheckedMultiNDPED) {
            if (!txtMultiDateNotiNumPrior.text.length)
            {
                [self showAlert:@"Please input Notification Number of Days After the End Date" :@"Input Error"];
                return;
            }
        }
    }else if(filledType == 3){
        
    }
    
    NSMutableDictionary *oneAircraftItem = [[NSMutableDictionary alloc] init];
    [oneAircraftItem setObject:@(filledType) forKey:@"type"];
    [oneAircraftItem setObject:@([txtValueMaxNum.text integerValue]) forKey:@"MaxNumberOfCharacters"];
    [oneAircraftItem setObject:@(isCheckedAlpha) forKey:@"Alphanumeric"];
    [oneAircraftItem setObject:@(isCheckedLetterOnly) forKey:@"lettersOnly"];
    [oneAircraftItem setObject:@(isCheckedLetterCAPs) forKey:@"lettersCAPS"];
    [oneAircraftItem setObject:@(isCheckedNumOnly) forKey:@"NumbersOnly"];
    [oneAircraftItem setObject:@(isCheckedTachBasedNoti) forKey:@"TachBasedNoti"];
    [oneAircraftItem setObject:@(typeOfTach) forKey:@"TachType"];
    switch (typeOfTach) {
        case 1:
        {
            NSDecimalNumber *tachDecimal = [NSDecimalNumber decimalNumberWithString:txt25TachLastDone.text];
            if (![tachDecimal isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [oneAircraftItem setObject:tachDecimal forKey:@"TachValue"];
            }else{
                [oneAircraftItem setObject:@0 forKey:@"TachValue"];
            }
            break;
        }
        case 2:
        {
            NSDecimalNumber *tachDecimal = [NSDecimalNumber decimalNumberWithString:txt50TachLastDone.text];
            if (![tachDecimal isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [oneAircraftItem setObject:tachDecimal forKey:@"TachValue"];
            }else{
                [oneAircraftItem setObject:@0 forKey:@"TachValue"];
            }
            break;
        }
        case 3:
        {
            NSDecimalNumber *tachDecimal = [NSDecimalNumber decimalNumberWithString:txt100TachLastDone.text];
            if (![tachDecimal isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [oneAircraftItem setObject:tachDecimal forKey:@"TachValue"];
            }else{
                [oneAircraftItem setObject:@0 forKey:@"TachValue"];
            }
            break;
        }
        case 4:
        {
            NSDecimalNumber *tachDecimal = [NSDecimalNumber decimalNumberWithString:txt2000TachLastDone.text];
            if (![tachDecimal isEqualToNumber:[NSDecimalNumber notANumber]]) {
                [oneAircraftItem setObject:tachDecimal forKey:@"TachValue"];
            }else{
                [oneAircraftItem setObject:@0 forKey:@"TachValue"];
            }
            break;
        }
        default:
            break;
    }
    
    [oneAircraftItem setObject:@(isCheckedSD) forKey:@"singleDate"];
    [oneAircraftItem setObject:@([txtNotiNumOfDaysPrior.text integerValue]) forKey:@"notiNumberOfDaysPrior"];
    [oneAircraftItem setObject:@([txtNotiNumberOfDaysAfter.text integerValue]) forKey:@"notiNumberOfDaysAfter"];
    [oneAircraftItem setObject:txtStartDate.text forKey:@"startDate"];
    [oneAircraftItem setObject:txtEndDate.text forKey:@"endDate"];
    [oneAircraftItem setObject:@([txtMultiDateNotifiNumAfter.text integerValue]) forKey:@"multiDateNotifiNumAfter"];
    [oneAircraftItem setObject:@([txtMultiDateNotiNumPrior.text integerValue]) forKey:@"multiDateNotifiNumPrior"];
    [oneAircraftItem setObject:@(isCheckedMultiDate) forKey:@"multiDate"];
    
    [oneAircraftItem setObject:txtLookupValue1.text forKey:@"lookupV1"];
    [oneAircraftItem setObject:txtLookupValue2.text forKey:@"lookupV2"];
    [oneAircraftItem setObject:txtLookupValue3.text forKey:@"lookupV3"];
    [oneAircraftItem setObject:txtLookupValue4.text forKey:@"lookupV4"];
    [oneAircraftItem setObject:txtLookupValue5.text forKey:@"lookupV5"];
    [oneAircraftItem setObject:txtLookupValue6.text forKey:@"lookupV6"];
    [oneAircraftItem setObject:txtLookupValue7.text forKey:@"lookupV7"];
    [oneAircraftItem setObject:txtLookupValue8.text forKey:@"lookupV8"];
    
    if (craftItemToEdit != nil || annualEdit != nil){
        UITableView *tableview;
        NSIndexPath *indexPath;
        ItemCell *tmpItemCell;
        if (annualEdit != nil) {
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                tableview = (UITableView *)[(UITableViewCell *)annualEdit superview];
            }else{
                tableview = (UITableView *)[[(UITableViewCell *)annualEdit superview] superview];
            }
            
            indexPath = [tableview indexPathForCell:annualEdit];
            tmpItemCell = annualEdit;
        }else{
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
                tableview = (UITableView *)[(UITableViewCell *)craftItemToEdit superview];
            }else{
                tableview = (UITableView *)[[(UITableViewCell *)craftItemToEdit superview] superview];
            }
            
            indexPath = [tableview indexPathForCell:craftItemToEdit];
            tmpItemCell = (ItemCell *)craftItemToEdit;
        }
        
        NSString *tmpContent = @"";
        if (isCheckedMultiDate){
            tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",[oneAircraftItem objectForKey:@"startDate"],[oneAircraftItem objectForKey:@"endDate"] ];
            tmpItemCell.txtContent.text = tmpContent;
        }
        if (isCheckedTachBasedNoti && ![txtFieldName.text isEqualToString:@"TACH"]){
            switch (typeOfTach) {
                case 1:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt25TachLastDone.text,txt25TachNextDue.text];
                    break;
                case 2:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt50TachLastDone.text,txt50TachNextDue.text];
                    break;
                case 3:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt100TachLastDone.text,txt100TachNextDue.text];
                    break;
                case 4:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt2000TachLastDone.text,txt2000TachNextDue.text];
                    break;
                default:
                    break;
            }
            tmpItemCell.txtContent.text = tmpContent;
        }
        switch (typeToAddItem) {
            case 1:
                [arrAircraftItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
            case 2:
            {
                id delete = [[arrMaintainesItems objectAtIndex:indexPath.row] objectForKey:@"isDelete"];
                [arrMaintainesItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",delete, @"isDelete", nil]];
            }
                break;
            case 3:
            {
                [arrAvionics replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
            }
                
                break;
            case 4:
                [arrLifeLimitedPartItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
            case 5:
                [arrOtherItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
                
            default:
                break;
        }
        
    }else{
        NSString *tmpContent = @"";
        if (isCheckedMultiDate){
            tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",[oneAircraftItem objectForKey:@"startDate"],[oneAircraftItem objectForKey:@"endDate"] ];
            
        }
        if (isCheckedTachBasedNoti && ![txtFieldName.text isEqualToString:@"TACH"]){
            switch (typeOfTach) {
                case 1:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt25TachLastDone.text,txt25TachNextDue.text];
                    break;
                case 2:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt50TachLastDone.text,txt50TachNextDue.text];
                    break;
                case 3:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt100TachLastDone.text,txt100TachNextDue.text];
                    break;
                case 4:
                    tmpContent = [NSString stringWithFormat:@"Done Last: %@ Due Next: %@",txt2000TachLastDone.text,txt2000TachNextDue.text];
                    break;
                default:
                    break;
            }
        }
        switch (typeToAddItem) {
            case 1:
                [arrAircraftItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
            case 2:
                [arrMaintainesItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete",@(0), @"isannual", nil]];
                break;
            case 3:
                [arrAvionics addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete",@(0), @"isannual", nil]];
                break;
            case 4:
                [arrLifeLimitedPartItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
            case 5:
                [arrOtherItems addObject:[NSDictionary dictionaryWithObjectsAndKeys:txtFieldName.text, @"fieldName", tmpContent, @"content", oneAircraftItem, @"setting",@(1), @"isDelete", nil]];
                break;
                
            default:
                break;
        }
        
    }
    
    
    
    [self initArrItems];
    
    [AirCraftItemTableView reloadData];
    [MaintaineTableView reloadData];
    [AvionicsTableView reloadData];
    [limitedPartTableView reloadData];
    [otherPartTableView reloadData];
    [SquawksTableView reloadData];
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    
    addAircraftItemView.hidden = YES;
    isAnnualInspection = NO;
    annualEdit = nil;
    isCheckedMNC = NO;
    isCheckedAlpha = NO;
    isCheckedLetterOnly = NO;
    isCheckedLetterCAPs = NO;
    isCheckedNumOnly = NO;
    isCheckedTachBasedNoti = NO;
    typeOfTach = 1;
    isCheckedSD = NO;
    isCheckedNNDpD = NO;
    isCheckedNNDAD = NO;
    isCheckedMultiDate = NO;
    isCheckedMultiNNDAD = NO;
    txtFieldName.text = @"";
    txtValueMaxNum.text = @"";
    txtStartDate.text = @"";
    txtEndDate.text = @"";
    txtLookupValue1.text = @"";
    txtLookupValue2.text = @"";
    txtLookupValue3.text = @"";
    txtLookupValue4.text = @"";
    txtLookupValue5.text = @"";
    txtLookupValue6.text = @"";
    txtLookupValue7.text = @"";
    txtLookupValue8.text = @"";
    craftItemToEdit = nil;
    optionValue.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    filledType = 1;
    [btnCheckMNC setImage:nil forState:UIControlStateNormal];
    [btnCheckAlpha setImage:nil forState:UIControlStateNormal];
    [btnCheckLettersOnly setImage:nil forState:UIControlStateNormal];
    [btnCheckLettersCAPS setImage:nil forState:UIControlStateNormal];
    [btnCheckNumbersOnly setImage:nil forState:UIControlStateNormal];
    [btnCheckSD setImage:nil forState:UIControlStateNormal];
    [btnCkeckNNDpD setImage:nil forState:UIControlStateNormal];
    [btnCheckNNDAD setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiDate setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiNNDAD setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiNDPED setImage:nil forState:UIControlStateNormal];
    [btnCheckTachBasedNoti setImage:nil forState:UIControlStateNormal];
    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
    txt25TachLastDone.text = @"";
    txt50TachLastDone.text = @"";
    txt100TachLastDone.text = @"";
    txt2000TachLastDone.text = @"";
    txt25TachNextDue.text = @"";
    txt50TachNextDue.text = @"";
    txt100TachNextDue.text = @"";
    txt2000TachNextDue.text = @"";
    txt25TachLastDone.enabled = NO;
    txt50TachLastDone.enabled = NO;
    txt100TachLastDone.enabled = NO;
    txt2000TachLastDone.enabled = NO;
    [self.view endEditing:YES];
}
- (void)resizeAddingAircraftView{
    if (addAircraftView.hidden == YES) {
        return;
    }
    CGRect tableRect = AirCraftItemTableView.frame;
    tableRect.size.height = arrAircraftItems.count * 30.0f + 30.0f;
    AirCraftItemTableView.frame = tableRect;
    
    tableRect = MaintaineTableView.frame;
    tableRect.size.height = arrMaintainesItems.count * 30.0f + 30.0f;
    MaintaineTableView.frame = tableRect;
    CGRect viewRect = mainTenanceView.frame;
    viewRect.origin.y = AirCraftItemTableView.frame.origin.y + AirCraftItemTableView.frame.size.height;
    viewRect.size.height = 30.0f + MaintaineTableView.frame.size.height;
    mainTenanceView.frame = viewRect;
    
    tableRect = AvionicsTableView.frame;
    tableRect.size.height = arrAvionics.count * 30.0f + 30.0f;
    AvionicsTableView.frame = tableRect;
    viewRect = avionicsView.frame;
    viewRect.origin.y = mainTenanceView.frame.origin.y + mainTenanceView.frame.size.height;
    viewRect.size.height = 30.0f + AvionicsTableView.frame.size.height;
    avionicsView.frame = viewRect;
    
    tableRect = limitedPartTableView.frame;
    tableRect.size.height = arrLifeLimitedPartItems.count * 30.0f + 30.0f;
    limitedPartTableView.frame = tableRect;
    viewRect = lifeLimitedPartView.frame;
    viewRect.origin.y = avionicsView.frame.origin.y + avionicsView.frame.size.height;
    viewRect.size.height = 30.0f + limitedPartTableView.frame.size.height;
    lifeLimitedPartView.frame = viewRect;
    
    tableRect = otherPartTableView.frame;
    tableRect.size.height = arrOtherItems.count * 30.0f + 30.0f;
    otherPartTableView.frame = tableRect;
    viewRect = otherItemViews.frame;
    viewRect.origin.y = lifeLimitedPartView.frame.origin.y + lifeLimitedPartView.frame.size.height;
    viewRect.size.height = 30.0f + otherPartTableView.frame.size.height;
    otherItemViews.frame = viewRect;
    
    tableRect = SquawksTableView.frame;
    CGFloat squawkTableHeight = 0;
    for (NSString *squawkTxt in arrSquawks) {
        UILabel *lblToGetHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 487.0f, 50.0f)];
        lblToGetHeight.text = squawkTxt;
        lblToGetHeight.font = [UIFont fontWithName:@"Helvetica" size:14];
        squawkTableHeight = squawkTableHeight + [self getLabelHeight:lblToGetHeight] + 20.0f;
    }
    tableRect.size.height = squawkTableHeight;
    SquawksTableView.frame = tableRect;
    viewRect = squawksViews.frame;
    viewRect.origin.y = otherItemViews.frame.origin.y + otherItemViews.frame.size.height;
    viewRect.size.height = 30.0f + SquawksTableView.frame.size.height;
    squawksViews.frame = viewRect;
    
    CGRect scrRect = aircraftAddingDialog.frame;
    scrRect.size.height = addAircraftView.frame.size.height - 110.0f;
    [aircraftAddingDialog setFrame:scrRect];
    
    CGSize scrSize = scrAircraft.contentSize;
    scrSize.height = squawksViews.frame.origin.y + squawksViews.frame.size.height + 200.0f;
    
    CGRect rectOfLogs = maintenanceLogsView.frame;
    if (isExpanedOfmaintenanceLogsView) {
        rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 300.0f;
        rectOfLogs.size.height = 300.0f;
        MaintenanceCollectionView.hidden = NO;
        btnDeleteLogs.hidden = NO;
        btnAddLogs.hidden = NO;
    }else{
        rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 50.0f;
        rectOfLogs.size.height = 50.0f;
        MaintenanceCollectionView.hidden = YES;
        btnDeleteLogs.hidden = YES;
        btnAddLogs.hidden = YES;
    }
    maintenanceLogsView.frame = rectOfLogs;
    
    if (aircraftToEdit == nil) {
        maintenanceLogsView.hidden = YES;
    }else{
        maintenanceLogsView.hidden = NO;
    }
    
    
    if (CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds) || showKeyboard){
        scrSize.height += 400;
    }
    
    [scrAircraft setContentSize:scrSize];
    
}

- (void)resizeAircraftView{
    CGRect tableRect = AirCraftTableView.frame;
    tableRect.size.height = arrAircraft.count * 58.0f + 44.0f;
    AirCraftTableView.frame = tableRect;
    
    CGSize scrSize = scrAircraft.contentSize;
    scrSize.height = squawksViews.frame.origin.y + squawksViews.frame.size.height + 250.0f;
    [scrAircraft setContentSize:scrSize];
}

- (void)resizeAddingAircraftItemView{
    CGRect scrRect = addAircraftitemDialog.frame;
    scrRect.size.height = addAircraftView.frame.size.height - 170.0f;
    [addAircraftitemDialog setFrame:scrRect];
    
    CGSize scrSize = scrAircraftItem.contentSize;
    
    if (CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)){
        scrSize.height = 920.0f;
    }else{
        scrSize.height = 1200.0f;
    }
    [scrAircraftItem setContentSize:scrSize];
}

- (IBAction)onAddOtherItem:(UIButton *)sender {
    
    typeToAddItem = 5;
    [self resizeAddingAircraftItemView];
    [self initNewAircraftItemForm];
    lblTitleToAddNewItem.text = @"Add Other Item";
    addAircraftItemView.hidden = NO;
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}

- (IBAction)onCancelAddOther:(UIButton *)sender {
    AddOtherItemView.hidden = YES;
    txtOtherItem.text = @"";
    [self.view endEditing:YES];
}

- (IBAction)onAddOther:(UIButton *)sender {
    
    aircraftToEdit = nil;
    
    if (!txtOtherItem.text.length)
    {
        [self showAlert:@"Please input OtherItem" :@"Input Error"];
        return;
    }
    
    NSMutableDictionary *oneOtherItemDict = [[NSMutableDictionary alloc] init];
    [oneOtherItemDict setObject:txtOtherItem.text forKey:@"fieldName"];
    [oneOtherItemDict setObject:@"" forKey:@"content"];
    switch (typeToAddItem) {
        case 1:{
            [arrMaintainesItems addObject:oneOtherItemDict];
            [MaintaineTableView reloadData];
            break;
        }
        case 2:{
            [arrAvionics addObject:oneOtherItemDict];
            [AvionicsTableView reloadData];
            break;
        }
        case 3:{
            [arrLifeLimitedPartItems addObject:oneOtherItemDict];
            [limitedPartTableView reloadData];
            break;
        }
        case 4:{
            [arrOtherItems addObject:oneOtherItemDict];
            [otherPartTableView reloadData];
            break;
        }
        default:
            break;
    }
    
    AddOtherItemView.hidden = YES;
    txtOtherItem.text = @"";
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    [self.view endEditing:YES];
}
- (IBAction)onOptionValue:(UIButton *)sender {
    if (isAnnualInspection) return;
    optionValue.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    filledType = 1;
}

- (IBAction)onCheckMNC:(UIButton *)sender {
    
    if (isAnnualInspection) return;
    
    isCheckedMNC = !isCheckedMNC;
    if (isCheckedMNC) {
        [btnCheckMNC setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckMNC setImage:nil forState:UIControlStateNormal];
    }
    
}

- (IBAction)onCheckAlpha:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedAlpha = !isCheckedAlpha;
    if (isCheckedAlpha) {
        [btnCheckAlpha setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckAlpha setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckLettersOnly:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedLetterOnly= !isCheckedLetterOnly;
    if (isCheckedLetterOnly) {
        [btnCheckLettersOnly setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckLettersOnly setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckLettersCAPS:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedLetterCAPs = !isCheckedLetterCAPs;
    if (isCheckedLetterCAPs) {
        [btnCheckLettersCAPS setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckLettersCAPS setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckNumbersOnly:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedNumOnly= !isCheckedNumOnly;
    if (isCheckedNumOnly) {
        [btnCheckNumbersOnly setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckNumbersOnly setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckTachBasedNoti:(id)sender {
    if (isAnnualInspection) return;
    isCheckedTachBasedNoti= !isCheckedTachBasedNoti;
    if (isCheckedTachBasedNoti) {
        [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
        typeOfTach = 1;
        [self reloadTachTextViewsWithType:typeOfTach];
        [btnSubTach25 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckTachBasedNoti setImage:nil forState:UIControlStateNormal];
        txt25TachLastDone.enabled = NO;
        txt50TachLastDone.enabled = NO;
        txt100TachLastDone.enabled = NO;
        txt2000TachLastDone.enabled = NO;
        [btnSubTach25 setImage:nil forState:UIControlStateNormal];
        [btnSubTach50 setImage:nil forState:UIControlStateNormal];
        [btnSubTach100 setImage:nil forState:UIControlStateNormal];
        [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheck25Tach:(UIButton *)sender {
    isCheckedTachBasedNoti = YES;
    [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    typeOfTach = 1;
    [self reloadTachTextViewsWithType:typeOfTach];
    [btnSubTach25 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
}

- (IBAction)onCheck50Tach:(id)sender {
    isCheckedTachBasedNoti = YES;
    [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    typeOfTach = 2;
    [self reloadTachTextViewsWithType:typeOfTach];
    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
    [btnSubTach50 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
}

- (IBAction)onCheck100Tach:(id)sender {
    isCheckedTachBasedNoti = YES;
    [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    typeOfTach = 3;
    [self reloadTachTextViewsWithType:typeOfTach];
    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
    [btnSubTach100 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
}

- (IBAction)onCheck2000Tach:(id)sender {
    isCheckedTachBasedNoti = YES;
    [btnCheckTachBasedNoti setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    typeOfTach = 4;
    [self reloadTachTextViewsWithType:typeOfTach];
    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
    [btnSubTach2000 setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
}
- (IBAction)onOptionDate:(UIButton *)sender {
    optionValue.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    filledType = 2;
}

- (IBAction)onCheckSD:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedSD = !isCheckedSD;
    if (isCheckedSD) {
        [btnCheckSD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckSD setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCkeckNNDpD:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedNNDpD = !isCheckedNNDpD;
    if (isCheckedNNDpD) {
        [btnCkeckNNDpD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCkeckNNDpD setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckNNDAD:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedNNDAD = !isCheckedNNDAD;
    if (isCheckedNNDAD) {
        [btnCheckNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckNNDAD setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckMultiDate:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedMultiDate = !isCheckedMultiDate;
    if (isCheckedMultiDate) {
        [btnCheckMultiDate setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckMultiDate setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckMultiNNDAD:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedMultiNNDAD = !isCheckedMultiNNDAD;
    if (isCheckedMultiNNDAD) {
        [btnCheckMultiNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckMultiNNDAD setImage:nil forState:UIControlStateNormal];
    }
}

- (IBAction)onCheckMultiNDPED:(UIButton *)sender {
    if (isAnnualInspection) return;
    isCheckedMultiNDPED = !isCheckedMultiNDPED;
    if (isCheckedMultiNDPED) {
        [btnCheckMultiNDPED setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    }else{
        [btnCheckMultiNDPED setImage:nil forState:UIControlStateNormal];
    }
}
- (IBAction)onOptionLookUp:(UIButton *)sender {
    if (isAnnualInspection) return;
    optionValue.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    filledType = 3;
}

- (IBAction)onStartDate:(UIButton *)sender {
    currentDateDialog = txtStartDate;
    
    [sender setEnabled:NO];
    [txtStartDate setEnabled:NO];
    
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 5;
    dateView.pickerTitle = @"Start Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}

- (IBAction)onEndDate:(UIButton *)sender {
    currentDateDialog = txtEndDate;
    
    [sender setEnabled:NO];
    [txtEndDate setEnabled:NO];
    
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 5;
    dateView.pickerTitle = @"End Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}

- (IBAction)onAddSquawks:(UIButton *)sender {
    currentSquawkItemToEdit = -1;
    addSquawkItemView.hidden = NO;
    [squawkTxtView becomeFirstResponder];
    addSquawkDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addSquawkDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
    }];
}

- (IBAction)onImportAircraft:(id)sender {
    isClickedImportBtn = YES;
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data", @"public.content", @"public.item"] inMode:UIDocumentPickerModeImport];
    
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
    
    [documentPicker.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
    documentPicker.delegate = self;
    
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:documentPicker];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
#pragma mark UIDocumentPickerDelgate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    NSString *fileName = [url lastPathComponent];
    NSArray *parseFileName = [fileName componentsSeparatedByString:@"."];
    if (isClickedImportBtn == YES){
        isClickedImportBtn = NO;
        if (parseFileName.count > 1) {
            NSString *lastString = parseFileName[parseFileName.count-1];
            if ([lastString.lowercaseString isEqualToString:@"aircraft"]) {
                [self parseAircraftFileFromUrl:url];
                return;
            }else{
                [self showAlert:@"Failed importing from aircraft!" :@"Error!"];
            }
        }else{
            [self showAlert:@"Failed importing from aircraft!" :@"Error!"];
        }
    }
    
    imageNameToUpload = fileName;
    NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
    NSError* error = nil;
    NSURLResponse* response = nil;
    [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
    NSString* mimeType = [response MIMEType];
    parseFileName = [mimeType componentsSeparatedByString:@"/"];
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
- (void)parseAircraftFileFromUrl:(NSURL *)fileUrl{
    NSData *dataOfAircraft = [NSData dataWithContentsOfURL:fileUrl];
    NSString *strToParseAircraftData = [[NSString alloc] initWithData:dataOfAircraft encoding:NSUTF8StringEncoding];
    NSMutableArray *arrayToParseWithLine = [[strToParseAircraftData componentsSeparatedByString:@"*!*END*!*"] mutableCopy];
    NSError *error;
        //save created aircraft into local
        Aircraft *aircraft = [NSEntityDescription insertNewObjectForEntityForName:@"Aircraft" inManagedObjectContext:contextRecords];
        aircraft.aircraftID = @(0);
        aircraft.aircraftItems = arrayToParseWithLine[0];
        aircraft.maintenanceItems = arrayToParseWithLine[3];
        aircraft.avionicsItems = arrayToParseWithLine[1];
        aircraft.liftLimitedParts = arrayToParseWithLine[2];
        aircraft.otherItems = arrayToParseWithLine[4];
        aircraft.squawksItems = arrayToParseWithLine[5];
        
        aircraft.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.valueForSort = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.aircraft_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        aircraft.lastUpdate = @(0);
   
    
    NSString *maintenceLogsStr = arrayToParseWithLine[6];
    NSData *data = [maintenceLogsStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *maintenceLogsArray = [[NSMutableArray alloc] init];
    if (data != nil){
        NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]  ;
        maintenceLogsArray = [json mutableCopy];
    }
    for (NSDictionary *oneMainLog in maintenceLogsArray) {
        MaintenanceLogs *maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:contextRecords];
        maintenanceLogs.maintenancelog_id = @0;
        maintenanceLogs.recordsLocal_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        maintenanceLogs.file_url = [oneMainLog objectForKey:@"file_url"];
        maintenanceLogs.local_url = @"";
        maintenanceLogs.file_name = [oneMainLog objectForKey:@"file_name"];
        maintenanceLogs.fileSize = [oneMainLog objectForKey:@"fileSize"];
        maintenanceLogs.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        maintenanceLogs.lastUpdate = @0;
        maintenanceLogs.user_id = [oneMainLog objectForKey:@"user_id"];
        maintenanceLogs.aircraft_local_id = aircraft.aircraft_local_id;
        maintenanceLogs.fileType = [oneMainLog objectForKey:@"fileType"];
        maintenanceLogs.thumb_url = [oneMainLog objectForKey:@"thumb_url"];
        maintenanceLogs.isUploaded = @0;
        [contextRecords save:&error];
    }
    
    
    
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self showAlert:@"Imported successfully" :@"FlightDesk"];
    [self reloadData];
}
- (IBAction)onShareCurrentAircraft:(id)sender {
    NSString *currentPDFPath = [self convertStringToFile];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:[NSURL URLWithString:[[NSString stringWithFormat:@"file://%@", currentPDFPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], nil] applicationActivities:nil];
    UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:activityVC];
    nc.modalPresentationStyle = UIModalPresentationPopover;
    [self showDetailViewController:nc sender:self];
    UIPopoverPresentationController *popController = nc.popoverPresentationController;
    popController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popController.delegate = self;
    popController.sourceView = btnShareCurrentAircraft;
}

- (IBAction)onAddUpdateSquawk:(id)sender {
    if (currentSquawkItemToEdit == -1) {
        [arrSquawks addObject:squawkTxtView.text];
    }else{
        [arrSquawks replaceObjectAtIndex:currentSquawkItemToEdit withObject:squawkTxtView.text];
    }
    addSquawkItemView.hidden = YES;
    [self initArrItems];
    
    [AirCraftItemTableView reloadData];
    [MaintaineTableView reloadData];
    [AvionicsTableView reloadData];
    [limitedPartTableView reloadData];
    [otherPartTableView reloadData];
    [SquawksTableView reloadData];
    [self resizeAddingAircraftView];
    [self resizeAddingAircraftItemView];
    [self.view endEditing:YES];
    currentSquawkItemToEdit = -1;
    squawkTxtView.text = @"";
}

- (IBAction)onCancelSquawk:(id)sender {
    [self.view endEditing:YES];
    currentSquawkItemToEdit = -1;
    addSquawkItemView.hidden = YES;
}
- (NSString *)convertStringToFile{
    NSString *fullAircraftsToSaveLocalAsFile = @"";
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.aircraftItems];
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.avionicsItems];
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.liftLimitedParts];
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.maintenanceItems];
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.otherItems];
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, aircraftToEdit.squawksItems];
    
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"aircraft_local_id == %@",aircraftToEdit.aircraft_local_id];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSMutableArray *maintenanceArray = [[NSMutableArray alloc] init];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve RecordsFile!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid RecordsFile found!");
    } else {
        for (MaintenanceLogs *maintenanceLogs in objects) {
            NSMutableDictionary *maintenceOneDic = [[NSMutableDictionary alloc] init];
            [maintenceOneDic setObject:maintenanceLogs.file_name forKey:@"file_name"];
            [maintenceOneDic setObject:maintenanceLogs.file_url forKey:@"file_url"];
            [maintenceOneDic setObject:maintenanceLogs.fileSize forKey:@"fileSize"];
            [maintenceOneDic setObject:maintenanceLogs.fileType forKey:@"fileType"];
            [maintenceOneDic setObject:maintenanceLogs.thumb_url forKey:@"thumb_url"];
            [maintenceOneDic setObject:maintenanceLogs.user_id forKey:@"user_id"];
            [maintenanceArray addObject:maintenceOneDic];
        }
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:maintenanceArray
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonStringForMaintenanceLogs = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    fullAircraftsToSaveLocalAsFile = [NSString stringWithFormat:@"%@%@*!*END*!*",fullAircraftsToSaveLocalAsFile, jsonStringForMaintenanceLogs];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Aircrafts_Improt_%f.aircraft", [[NSDate date] timeIntervalSince1970] * 1000000]];
    NSData* dataAircraft = [fullAircraftsToSaveLocalAsFile dataUsingEncoding:NSUTF8StringEncoding];
    BOOL succeed = [dataAircraft writeToFile:filePath atomically:YES];
    //BOOL succeed = [fullAircraftsToSaveLocalAsFile writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!succeed){
        // Handle error here
    }
    
    return filePath;
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

#pragma mark ItemCellDelegate

- (void)textFieldDidBeginEditingWithItem:(ItemCell *)_cell{
    
    UITableView *tableview;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[_cell superview];
    }else{
        tableview = (UITableView *)[[_cell superview] superview];
    }
    NSIndexPath *indexPath = [tableview indexPathForCell:_cell];
    id tmpDic;
    
    if (tableview == AirCraftItemTableView) {
        tmpDic = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        if ([[[arrAircraftItems objectAtIndex:indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"Year"] || [[[arrAircraftItems objectAtIndex:indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"MTOW"]){
            [_cell.txtContent setKeyboardType:UIKeyboardTypeNumberPad];
        }
    }else if(tableview == MaintaineTableView) {
        tmpDic = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        if ([[[arrMaintainesItems objectAtIndex:indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"TACH"]){
            [_cell.txtContent setKeyboardType:UIKeyboardTypeNumberPad];
        }
    }else if(tableview == AvionicsTableView) {
        tmpDic = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }else if(tableview == limitedPartTableView) {
        tmpDic = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }else if(tableview == otherPartTableView) {
        tmpDic = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }
    if ([tmpDic isKindOfClass:[NSDictionary class]]) {
        NSDictionary *tmpDicOfSetting = tmpDic;
        if((int)[[tmpDicOfSetting objectForKey:@"lettersCAPS"] integerValue] != 0){
            _cell.txtContent.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        }
    }
}

- (void)didEndEditingTextFieldWithCell:(ItemCell *)_cell{
    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[_cell superview];
    }else{
        tableview = (UITableView *)[[_cell superview] superview];
    }
    NSDictionary *dictToCheck;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (tableview == AirCraftItemTableView) {
        indexPath = [AirCraftItemTableView indexPathForCell:_cell];
        dictToCheck = [arrAircraftItems objectAtIndex:indexPath.row];
        [arrAircraftItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", _cell.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == MaintaineTableView) {
        indexPath = [MaintaineTableView indexPathForCell:_cell];
        dictToCheck = [arrMaintainesItems objectAtIndex:indexPath.row];
        [arrMaintainesItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", _cell.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == AvionicsTableView) {
        indexPath = [AvionicsTableView indexPathForCell:_cell];
        dictToCheck = [arrAvionics objectAtIndex:indexPath.row];
        [arrAvionics replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", _cell.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == limitedPartTableView) {
        indexPath = [limitedPartTableView indexPathForCell:_cell];
        dictToCheck = [arrLifeLimitedPartItems objectAtIndex:indexPath.row];
        [arrLifeLimitedPartItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", _cell.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == otherPartTableView) {
        indexPath = [otherPartTableView indexPathForCell:_cell];
        dictToCheck = [arrOtherItems objectAtIndex:indexPath.row];
        [arrOtherItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", _cell.txtContent.text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }
    if ([[dictToCheck objectForKey:@"setting"]  isKindOfClass:[NSDictionary class]] && ![[[dictToCheck objectForKey:@"setting"] objectForKey:@"type"] isEqual:@""] && (int)[[[dictToCheck objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && ![[dictToCheck objectForKey:@"fieldName"] isEqual:@"TACH"]){
        if (![[dictToCheck objectForKey:@"content"] isEqualToString:@""]) {
            if((int)[[[dictToCheck objectForKey:@"setting"] objectForKey:@"TachBasedNoti"] integerValue] != 0 && [[[dictToCheck objectForKey:@"setting"] objectForKey:@"TachValue"] floatValue] >0){
                NSDecimalNumber *currentTach = [NSDecimalNumber decimalNumberWithString:[dictToCheck objectForKey:@"content"]];
                NSDecimalNumber *parentTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                for (NSDictionary *dictToGetTach in arrMaintainesItems) {
                    if ((int)[[[dictToGetTach objectForKey:@"setting"] objectForKey:@"type"] integerValue] == 1 && [[dictToGetTach objectForKey:@"fieldName"] isEqual:@"TACH"] && ![[dictToGetTach objectForKey:@"content"] isEqual:@""]){
                        parentTach = [NSDecimalNumber decimalNumberWithString:[dictToGetTach objectForKey:@"content"]];
                        break;
                    }
                }
                
                NSDecimalNumber *differenceTach = [NSDecimalNumber decimalNumberWithString:@"0"];
                differenceTach = [currentTach decimalNumberBySubtracting:parentTach];
                
                [_cell.lblBannerAlertCount setBackgroundColor:[UIColor colorWithRed:0 green:150.0f/255.0f blue:0 alpha:1.0f]];
                
                if([differenceTach floatValue] < 0){
                    _cell.txtContent.textColor = [UIColor redColor];
                    
                }else if ([differenceTach floatValue] > 0){
                    _cell.txtContent.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                    _cell.lblBannerAlertCount.hidden = NO;
                    _cell.lblBannerAlertCount.text = [NSString stringWithFormat:@"%@", [differenceTach stringValue]];
                    
                }else if ([differenceTach floatValue] == 0){
                    
                }
            }
        }
        
    }
}
- (BOOL)shouldChangeCharactersWithItem:(ItemCell *)_cell InRange:(NSRange)range replacementString:(NSString *)string{
    NSString *text = [_cell.txtContent.text stringByReplacingCharactersInRange:range withString:string];
    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[_cell superview];
    }else{
        tableview = (UITableView *)[[_cell superview] superview];
    }
    NSIndexPath *indexPath = [tableview indexPathForCell:_cell];
    NSDictionary *dictToCheck;
    if (tableview == AirCraftItemTableView) {
        indexPath = [AirCraftItemTableView indexPathForCell:_cell];
        dictToCheck = [arrAircraftItems objectAtIndex:indexPath.row];
        [arrAircraftItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == MaintaineTableView) {
        indexPath = [MaintaineTableView indexPathForCell:_cell];
        dictToCheck = [arrMaintainesItems objectAtIndex:indexPath.row];
        [arrMaintainesItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == AvionicsTableView) {
        indexPath = [AvionicsTableView indexPathForCell:_cell];
        dictToCheck = [arrAvionics objectAtIndex:indexPath.row];
        [arrAvionics replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == limitedPartTableView) {
        indexPath = [limitedPartTableView indexPathForCell:_cell];
        dictToCheck = [arrLifeLimitedPartItems objectAtIndex:indexPath.row];
        [arrLifeLimitedPartItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }else if(tableview == otherPartTableView) {
        indexPath = [otherPartTableView indexPathForCell:_cell];
        dictToCheck = [arrOtherItems objectAtIndex:indexPath.row];
        [arrOtherItems replaceObjectAtIndex:indexPath.row withObject:[NSDictionary dictionaryWithObjectsAndKeys:[dictToCheck objectForKey:@"fieldName"], @"fieldName", text, @"content", [dictToCheck objectForKey:@"setting"], @"setting",@(1), @"isDelete", nil]];
    }
    
    id tmp;
    
    if (text.length == 0){
        return YES;
    }
    
    if (tableview == AirCraftItemTableView) {
        tmp = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        if ([[[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"Registration"]) {
            lblAircraftTitle.text = text;
            return YES;
        }
    }else if(tableview == MaintaineTableView) {
        tmp = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        if ([[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"] isEqualToString:@"TACH"]){
            
            if (range.length == 1) return YES;
            if ([string isEqualToString:@"."]) return YES;
                BOOL valid = NO;
                
                NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
                for (int i = 0; i < [string length]; i++) {
                    unichar c = [string characterAtIndex:i];
                    if ([myCharSet characterIsMember:c]) {
                        valid = YES;
                    }
                }
                
                if (!valid){
                    return NO;
                }
        }
    }else if(tableview == AvionicsTableView) {
        tmp = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }else if(tableview == limitedPartTableView) {
        tmp = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }else if(tableview == otherPartTableView) {
        tmp = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
    }
    
    if ([tmp isKindOfClass:[NSDictionary class]]) {
        
        if ([[tmp objectForKey:@"type"] integerValue] == 2 || [[tmp objectForKey:@"type"] integerValue] == 3 || [[tmp objectForKey:@"isannual"] isEqual:@(1)]) return NO;
        
        NSDictionary *tmpDic = tmp;
        if ([[tmpDic objectForKey:@"MaxNumberOfCharacters"] integerValue] != 0){
            
            
            NSLog(@"%ld", [[tmpDic objectForKey:@"MaxNumberOfCharacters"] integerValue]);
            if (text.length > [[tmpDic objectForKey:@"MaxNumberOfCharacters"] integerValue]){
                return NO;
            }
            
        }
        
        
        if((int)[[tmpDic objectForKey:@"Alphanumeric"] integerValue] != 0){
            
            NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
            BOOL valid = [[string stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
            if (!valid) return NO;
            
        }
        if((int)[[tmpDic objectForKey:@"lettersOnly"] integerValue] != 0){
            
            BOOL valid = NO;
            
            NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
            for (int i = 0; i < [string length]; i++) {
                unichar c = [string characterAtIndex:i];
                if ([myCharSet characterIsMember:c]) {
                    valid = YES;
                }
            }
            
            if (valid){
                return NO;
            }
            
        }
        if((int)[[tmpDic objectForKey:@"lettersCAPS"] integerValue] != 0){
            
            
        }
        if((int)[[tmpDic objectForKey:@"NumbersOnly"] integerValue] != 0){
            
            
            if (range.length == 1) return YES;
            if ([string isEqualToString:@"."]) return YES;
            
            BOOL valid = NO;
            
            NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
            for (int i = 0; i < [string length]; i++) {
                unichar c = [string characterAtIndex:i];
                if ([myCharSet characterIsMember:c]) {
                    valid = YES;
                }
            }
            
            if (!valid){
                return NO;
            }
        }

    }
    return YES;
}
- (void)didPopupDateDialog:(ItemCell *)_cell{
    currentDateDialogSuper = _cell;
    
    _cell.btnPopup.hidden = YES;
    _cell.txtContent.hidden = YES;
    
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 5;
    dateView.pickerTitle = _cell.lblFieldName.text;
    [self displayContentController:dateView];
    [dateView animateShow];
    
}
- (void)didPopupLookDialog:(ItemCell *)_cell{
    currentDateDialogSuper = _cell;
    
    _cell.btnPopupLook.hidden = YES;
    _cell.txtContent.hidden = YES;
    
    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[(UITableViewCell *)currentDateDialogSuper superview];
    }else{
        tableview = (UITableView *)[[(UITableViewCell *)currentDateDialogSuper superview] superview];
    }
    NSIndexPath *indexPath = [tableview indexPathForCell:currentDateDialogSuper];
    
    id tmp;
    
    NSString *filedName;
    
    if (tableview == AirCraftItemTableView){
        tmp = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        filedName = [[arrAircraftItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        if ([filedName isEqualToString:@"Category"]) {
            [self popUpPickerDialog:1 withIndex:0];
            return;
        }
        if ([filedName isEqualToString:@"Class"]) {
            [self popUpPickerDialog:2 withIndex:0];
            return;
        }
    }else if (tableview == MaintaineTableView){
        tmp = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        filedName = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
    }else if (tableview == AvionicsTableView){
        tmp = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
        filedName = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
    }else if (tableview == limitedPartTableView){
        tmp = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        filedName = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
    }else if (tableview == otherPartTableView){
        tmp = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
        filedName = [[arrOtherItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
    }
    NSMutableArray *tmpLookUpCategories = [[NSMutableArray alloc] init];
    if ([tmp isKindOfClass:[NSDictionary class]]) {
        NSDictionary *tmpDic = tmp;
        if (tmpDic != nil) {
            if(![[tmpDic objectForKey:@"lookupV1"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV1"]];
            }
            if(![[tmpDic objectForKey:@"lookupV2"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV2"]];
            }
            if(![[tmpDic objectForKey:@"lookupV3"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV3"]];
            }
            if(![[tmpDic objectForKey:@"lookupV4"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV4"]];
            }
            if(![[tmpDic objectForKey:@"lookupV5"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV5"]];
            }
            if(![[tmpDic objectForKey:@"lookupV6"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV6"]];
            }
            if(![[tmpDic objectForKey:@"lookupV7"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV7"]];
            }
            if(![[tmpDic objectForKey:@"lookupV8"] isEqual:@""]){
                [tmpLookUpCategories addObject:[tmpDic objectForKey:@"lookupV8"]];
            }
        }
    }
    
    
    PickerWithDataViewController *pickView = [[PickerWithDataViewController alloc] initWithNibName:@"PickerWithDataViewController" bundle:nil];
    [pickView.view setFrame:self.view.bounds];
    pickView.delegate = self;
    pickView.pickerType = 4;
    if (tmpLookUpCategories != NULL){
        pickView.arrLookUpCategories = [tmpLookUpCategories mutableCopy];
        
    }else{
        [self showAlert:@"Please input Look Up Fields" :@"Input Error"];
        return;
    }
    pickView.cellIndexForEndorsement = 0;
    [self displayContentController:pickView];
    [pickView animateShow];
    
}
#pragma mark UITextFieldDelegate

-(BOOL)shouldReturnWithItem:(ItemCell *)_cell{
    
    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[(UITableViewCell *)_cell superview];
    }else{
        tableview = (UITableView *)[[(UITableViewCell *)_cell superview] superview];
    }
    
    NSIndexPath *indexPath = [tableview indexPathForCell:_cell];
    
    ItemCell *cell;
    
    if (tableview == AirCraftItemTableView){
        if (indexPath.row == [AirCraftItemTableView numberOfRowsInSection:0] - 1){
            cell = [MaintaineTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 70) animated:YES];
        }else{
            cell = [AirCraftItemTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 35) animated:YES];
        }
    }else if (tableview == MaintaineTableView){
        if (indexPath.row == [MaintaineTableView numberOfRowsInSection:0] - 1){
            cell = [AvionicsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 80) animated:YES];
        }else{
            cell = [MaintaineTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 35) animated:YES];
        }
        
    }else if (tableview == AvionicsTableView){
        if (indexPath.row == [AvionicsTableView numberOfRowsInSection:0] - 1){
            cell = [limitedPartTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 80) animated:YES];
        }else{
            cell = [AvionicsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 35) animated:YES];
        }
    }else if (tableview == limitedPartTableView){
        if (indexPath.row == [limitedPartTableView numberOfRowsInSection:0] - 1){
            cell = [otherPartTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            if (cell == nil){
                [scrAircraft setContentOffset:CGPointMake(0, 0) animated:YES];
                return YES;
            }
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 80) animated:YES];
        }else{
            cell = [limitedPartTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 35) animated:YES];
        }
    }else if (tableview == otherPartTableView){
        if (indexPath.row == [otherPartTableView numberOfRowsInSection:0] - 1){
            [scrAircraft setContentOffset:CGPointMake(0, 0) animated:YES];
        }else{
            cell = [otherPartTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 35) animated:YES];
        }
    }
    
    
    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField != txtMultiDateNotifiNumAfter && textField != txtMultiDateNotiNumPrior && isAnnualInspection) return NO;
    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField == tmptext) {
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        if (currentSelectedrecordsFile.maintenancelog_id != nil && text.length > 0) {
            currentSelectedrecordsFile.file_name = text;
            currentSelectedrecordsFile.lastUpdate = @(0);
            [context save:&error];
        }
        return YES;
    }
    
    
    if (textField == txtValueMaxNum || textField == txtNotiNumOfDaysPrior || textField == txtNotiNumberOfDaysAfter || textField == txtMultiDateNotiNumPrior || textField == txtMultiDateNotifiNumAfter) {
        if (range.length == 1) return YES;
        if ([string isEqualToString:@"."]) return YES;
        BOOL valid = NO;
        
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        for (int i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if ([myCharSet characterIsMember:c]) {
                valid = YES;
            }
        }
        
        if (!valid){
            return NO;
        }
    }
    if (textField == txt25TachLastDone || textField == txt50TachLastDone || textField == txt100TachLastDone || textField == txt2000TachLastDone) {
        if (range.length != 1){
            if ([string isEqualToString:@"."]) return YES;
            BOOL valid = NO;
            
            NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
            for (int i = 0; i < [string length]; i++) {
                unichar c = [string characterAtIndex:i];
                if ([myCharSet characterIsMember:c]) {
                    valid = YES;
                }
            }
            
            if (!valid){
                return NO;
            }
        }
    }
    if (textField == txt25TachLastDone) {
        NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:text];
        NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"25"];
        if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
            txt25TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
        }
    }
    if (textField == txt50TachLastDone) {
        NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:text];
        NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"50"];
        if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
            txt50TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
        }
    }
    if (textField == txt100TachLastDone) {
        NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:text];
        NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"100"];
        if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
            txt100TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
        }
    }
    if (textField == txt2000TachLastDone) {
        NSDecimalNumber *tachLastDue = [NSDecimalNumber decimalNumberWithString:text];
        NSDecimalNumber *nextDueToAdd = [NSDecimalNumber decimalNumberWithString:@"2000"];
        if (![tachLastDue isEqualToNumber:[NSDecimalNumber notANumber]]) {
            NSDecimalNumber *totalTimeNumber = [tachLastDue decimalNumberByAdding:nextDueToAdd];
            txt2000TachNextDue.text = [NSString stringWithFormat:@"%@", totalTimeNumber];
        }
    }
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtFieldName) {
        [txtValueMaxNum becomeFirstResponder];
    }else if (textField == txtValueMaxNum){
        if (isCheckedTachBasedNoti) {
            switch (typeOfTach) {
                case 1:
                    [txt25TachLastDone becomeFirstResponder];
                    break;
                case 2:
                    [txt50TachLastDone becomeFirstResponder];
                    break;
                case 3:
                    [txt100TachLastDone becomeFirstResponder];
                    break;
                case 4:
                    [txt2000TachLastDone becomeFirstResponder];
                    break;
                default:
                    [txtNotiNumOfDaysPrior becomeFirstResponder];
                    break;
            }
        }
    }else if (textField == txt25TachLastDone){
        [txtNotiNumOfDaysPrior becomeFirstResponder];
    }else if (textField == txt50TachLastDone){
        [txtNotiNumOfDaysPrior becomeFirstResponder];
    }else if (textField == txt100TachLastDone){
        [txtNotiNumOfDaysPrior becomeFirstResponder];
    }else if (textField == txt2000TachLastDone){
        [txtNotiNumOfDaysPrior becomeFirstResponder];
    }else if (textField == txtNotiNumOfDaysPrior){
        [txtNotiNumberOfDaysAfter becomeFirstResponder];
    }else if (textField == txtNotiNumberOfDaysAfter){
        [txtMultiDateNotiNumPrior becomeFirstResponder];
    }else if (textField == txtMultiDateNotiNumPrior){
        [txtMultiDateNotifiNumAfter becomeFirstResponder];
    }else if (textField == txtMultiDateNotifiNumAfter){
        [txtLookupValue1 becomeFirstResponder];
    }else if (textField == txtLookupValue1){
        [txtLookupValue2 becomeFirstResponder];
    }else if (textField == txtLookupValue2){
        [txtLookupValue3 becomeFirstResponder];
    }else if (textField == txtLookupValue3){
        [txtLookupValue4 becomeFirstResponder];
    }else if (textField == txtLookupValue4){
        [txtLookupValue5 becomeFirstResponder];
    }else if (textField == txtLookupValue5){
        [txtLookupValue6 becomeFirstResponder];
    }else if (textField == txtLookupValue6){
        [txtLookupValue7 becomeFirstResponder];
    }else if (textField == txtLookupValue7){
        [txtLookupValue8 becomeFirstResponder];
    }else if (textField == tmptext){
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        if (currentSelectedrecordsFile.maintenancelog_id != nil && textField.text.length > 0) {
            [coverViewForRenameText removeFromSuperview];
            currentSelectedrecordsFile.file_name = tmptext.text;
            currentSelectedrecordsFile.lastUpdate = @(0);
            [self.view endEditing:YES];
            indexToEdit = -1;
            [context save:&error];
            [MaintenanceCollectionView reloadData];
            [[AppDelegate sharedDelegate] startThreadToSyncData:5];
        }
    }else{
        ItemCell *cell;
        cell = [AirCraftItemTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (cell == nil){
            cell = [MaintaineTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 90) animated:YES];
        }else{
            [cell.txtContent becomeFirstResponder];
            [scrAircraft setContentOffset:CGPointMake(0, scrAircraft.contentOffset.y + 30) animated:YES];
        }
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (isAnnualInspection) return;
    if (textField == txtValueMaxNum) {
        [txtValueMaxNum becomeFirstResponder];
    }else if (textField == txtNotiNumOfDaysPrior){
        [txtNotiNumOfDaysPrior becomeFirstResponder];
    }else if (textField == txtNotiNumberOfDaysAfter){
        [txtNotiNumberOfDaysAfter becomeFirstResponder];
    }else if (textField == txtMultiDateNotiNumPrior){
        [txtMultiDateNotiNumPrior becomeFirstResponder];
    }else if (textField == txtMultiDateNotifiNumAfter){
        [txtMultiDateNotifiNumAfter becomeFirstResponder];
    }else if (textField == txtLookupValue1){
        [txtLookupValue1 becomeFirstResponder];
    }else if (textField == txtLookupValue2){
        [txtLookupValue2 becomeFirstResponder];
    }else if (textField == txtLookupValue3){
        [txtLookupValue3 becomeFirstResponder];
    }else if (textField == txtLookupValue4){
        [txtLookupValue4 becomeFirstResponder];
    }else if (textField == txtLookupValue5){
        [txtLookupValue5 becomeFirstResponder];
    }else if (textField == txtLookupValue6){
        [txtLookupValue6 becomeFirstResponder];
    }else if (textField == txtLookupValue7){
        [txtLookupValue7 becomeFirstResponder];
    }else if (textField == txtLookupValue8){
        [txtLookupValue8 becomeFirstResponder];
    }else if (textField == txt25TachLastDone){
        [txt25TachLastDone becomeFirstResponder];
    }else if (textField == txt50TachLastDone){
        [txt50TachLastDone becomeFirstResponder];
    }else if (textField == txt100TachLastDone){
        [txt100TachLastDone becomeFirstResponder];
    }else if (textField == txt2000TachLastDone){
        [txt2000TachLastDone becomeFirstResponder];
    }else if (textField == tmptext){
        textField.returnKeyType = UIReturnKeyDone;
    }
}
-(void)initNewAircraftItemForm{
    isCheckedMNC = NO;
    isCheckedAlpha = NO;
    isCheckedLetterOnly = NO;
    isCheckedLetterCAPs = NO;
    isCheckedNumOnly = NO;
    isCheckedTachBasedNoti = NO;
    typeOfTach = 1;
    isCheckedSD = NO;
    isCheckedNNDpD = NO;
    isCheckedNNDAD = NO;
    isCheckedMultiDate = NO;
    isCheckedMultiNNDAD = NO;
    isCheckedMultiNDPED = NO;
    txtFieldName.text = @"";
    txtValueMaxNum.text = @"";
    txtNotiNumOfDaysPrior.text = @"";
    txtNotiNumberOfDaysAfter.text = @"";
    txtStartDate.text = @"";
    txtEndDate.text = @"";
    txtNotiNumberOfDaysAfter.text = @"";
    txtNotiNumOfDaysPrior.text = @"";
    txtMultiDateNotifiNumAfter.text = @"";
    txtMultiDateNotiNumPrior.text = @"";
    txtLookupValue1.text = @"";
    txtLookupValue2.text = @"";
    txtLookupValue3.text = @"";
    txtLookupValue4.text = @"";
    txtLookupValue5.text = @"";
    txtLookupValue6.text = @"";
    txtLookupValue7.text = @"";
    txtLookupValue8.text = @"";
    optionValue.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    filledType = 1;
    craftItemToEdit = nil;
    [btnCheckMNC setImage:nil forState:UIControlStateNormal];
    [btnCheckAlpha setImage:nil forState:UIControlStateNormal];
    [btnCheckLettersOnly setImage:nil forState:UIControlStateNormal];
    [btnCheckLettersCAPS setImage:nil forState:UIControlStateNormal];
    [btnCheckNumbersOnly setImage:nil forState:UIControlStateNormal];
    [btnCheckSD setImage:nil forState:UIControlStateNormal];
    [btnCkeckNNDpD setImage:nil forState:UIControlStateNormal];
    [btnCheckNNDAD setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiDate setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiNNDAD setImage:nil forState:UIControlStateNormal];
    [btnCheckMultiNDPED setImage:nil forState:UIControlStateNormal];
    [btnCheckTachBasedNoti setImage:nil forState:UIControlStateNormal];
    [btnSubTach25 setImage:nil forState:UIControlStateNormal];
    [btnSubTach50 setImage:nil forState:UIControlStateNormal];
    [btnSubTach100 setImage:nil forState:UIControlStateNormal];
    [btnSubTach2000 setImage:nil forState:UIControlStateNormal];
    txt25TachLastDone.text = @"";
    txt50TachLastDone.text = @"";
    txt100TachLastDone.text = @"";
    txt2000TachLastDone.text = @"";
    txt25TachNextDue.text = @"";
    txt50TachNextDue.text = @"";
    txt100TachNextDue.text = @"";
    txt2000TachNextDue.text = @"";
    txt25TachLastDone.enabled = NO;
    txt50TachLastDone.enabled = NO;
    txt100TachLastDone.enabled = NO;
    txt2000TachLastDone.enabled = NO;
}

- (void) didAnnualDialog:(ItemCell *)_cell{
    [self initNewAircraftItemForm];
    
    isAnnualInspection = YES;
    annualEdit = _cell;

    UITableView *tableview;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0) {
        tableview = (UITableView *)[(UITableViewCell *)_cell superview];
    }else{
        tableview = (UITableView *)[[(UITableViewCell *)_cell superview] superview];
    }
    
        
    NSIndexPath *indexPath = [tableview indexPathForCell:_cell];
    
    id tmp;
    if (tableview == MaintaineTableView){
        typeToAddItem = 2;
        if (![[[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
            tmp = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            txtStartDate.text = [tmp objectForKey:@"startDate"];
            txtEndDate.text = [tmp objectForKey:@"endDate"];
            if ([[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue] != 0) {
                txtMultiDateNotifiNumAfter.text = [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue]] ;
            }
            if ([[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue] != 0) {
                txtMultiDateNotiNumPrior.text =  [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue]] ;
            }
        }
        txtFieldName.text = [[arrMaintainesItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        lblTitleToAddNewItem.text = @"Edit Maintenance";
    }else if (tableview == AvionicsTableView){
        typeToAddItem = 3;
        if (![[[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
            tmp = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"setting"];
            txtStartDate.text = [tmp objectForKey:@"startDate"];
            txtEndDate.text = [tmp objectForKey:@"endDate"];
            if ([[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue] != 0) {
                txtMultiDateNotifiNumAfter.text = [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue]] ;
            }
            if ([[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue] != 0) {
                txtMultiDateNotiNumPrior.text =  [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue]] ;
            }
        }
        txtFieldName.text = [[arrAvionics objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        lblTitleToAddNewItem.text = @"Edit Avionics";
    }else if (tableview == limitedPartTableView){
        typeToAddItem = 4;
        if (![[[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"] isEqual:@""]){
            tmp = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"setting"];
            txtStartDate.text = [tmp objectForKey:@"startDate"];
            txtEndDate.text = [tmp objectForKey:@"endDate"];
            if ([[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue] != 0) {
                txtMultiDateNotifiNumAfter.text = [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumAfter"] integerValue]] ;
            }
            if ([[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue] != 0) {
                txtMultiDateNotiNumPrior.text =  [NSString stringWithFormat:@"%ld", [[tmp objectForKey:@"multiDateNotifiNumPrior"] integerValue]] ;
            }
        }
        txtFieldName.text = [[arrLifeLimitedPartItems objectAtIndex: indexPath.row] objectForKey:@"fieldName"];
        lblTitleToAddNewItem.text = @"Edit Avionics";
    }
    
    addAircraftItemView.hidden = NO;
    
    optionValue.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    optionDate.backgroundColor = [UIColor colorWithRed:16/255.0 green:114/255.0 blue:189/255.0 alpha:1.0];
    optionLookUp.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    filledType = 2;
    
    isCheckedMultiDate = YES;
    [btnCheckMultiDate setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    
    
    isCheckedMultiNNDAD = YES;
    [btnCheckMultiNNDAD setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    
    isCheckedMultiNDPED = YES;
    [btnCheckMultiNDPED setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    
    
    addAircraftitemDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        addAircraftitemDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        
    }];
}

- (IBAction)onShowHideLogs:(UIButton *)sender {
    isExpanedOfmaintenanceLogsView = !isExpanedOfmaintenanceLogsView;
    
    CGSize scrSize = scrAircraft.contentSize;
    scrSize.height = squawksViews.frame.origin.y + squawksViews.frame.size.height + 150.0f;
    
    CGRect rectOfLogs = maintenanceLogsView.frame;
    if (isExpanedOfmaintenanceLogsView) {
        rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 300.0f;
        rectOfLogs.size.height = 300.0f;
        [self getMaintenanceLogs:aircraftToEdit.aircraft_local_id];
    }else{
        rectOfLogs.origin.y = aircraftAddingDialog.frame.size.height - 50.0f;
        rectOfLogs.size.height = 50.0f;
    }
    [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        maintenanceLogsView.frame = rectOfLogs;
    } completion:^(BOOL finished){
        if (isExpanedOfmaintenanceLogsView) {
            MaintenanceCollectionView.hidden = NO;
            btnDeleteLogs.hidden = NO;
            btnAddLogs.hidden = NO;
            btnCloseOfLogs.hidden = NO;
        }else{
            MaintenanceCollectionView.hidden = YES;
            btnCloseOfLogs.hidden = YES;
            btnDeleteLogs.hidden = YES;
            btnAddLogs.hidden = YES;
            isDeleteMode = NO;
            UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
            btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
            [selectedThumbViews removeAllObjects];
        }
    }];
    
}

- (IBAction)onCloseLogs:(UIButton *)sender {
    if (isDeleteMode) {
//        btnCloseOfLogs.hidden = YES;
        isDeleteMode = NO;
        UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
        btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
        [selectedThumbViews removeAllObjects];
        [MaintenanceCollectionView reloadData];
    }else{
        [self onShowHideLogs:nil];
    }
}

- (IBAction)onAddLogs:(UIButton *)sender {
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
    popPresenter.sourceView = btnAddLogs;
    popPresenter.sourceRect = btnAddLogs.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)presentPhotoTweaksView:(UIImage *)image{
    PhotoTweaksViewController *photoTweaksViewController = [[PhotoTweaksViewController alloc] initWithImage:image];
    photoTweaksViewController.delegate = self;
    photoTweaksViewController.autoSaveToLibray = NO;
    photoTweaksViewController.maxRotationAngle = M_PI_2;
    [self presentViewController:photoTweaksViewController animated:YES completion:nil];
}

- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
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
    
    
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    MaintenanceLogs *maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    maintenanceLogs.maintenancelog_id = @0;
    maintenanceLogs.recordsLocal_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    maintenanceLogs.file_url = [NSString stringWithFormat:@"%@/%@/figureimages/%@",serverName, webAppDir, [photoUrl lastPathComponent]];
    maintenanceLogs.local_url = [photoUrl path];
    maintenanceLogs.file_name = imageNameToUpload;
    maintenanceLogs.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
    maintenanceLogs.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    maintenanceLogs.lastUpdate = @0;
    maintenanceLogs.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    maintenanceLogs.aircraft_local_id = aircraftToEdit.aircraft_local_id;
    maintenanceLogs.fileType = @"image";
    maintenanceLogs.thumb_url = @"";
    maintenanceLogs.isUploaded = @0;
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self getMaintenanceLogs:currentSelectedAircraftLocalID];
    
}

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
    MaintenanceLogs *maintenanceLogs = [NSEntityDescription insertNewObjectForEntityForName:@"MaintenanceLogs" inManagedObjectContext:context];
    maintenanceLogs.maintenancelog_id = @0;
    currentRecordsLocalIdToUpload = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    maintenanceLogs.recordsLocal_id = currentRecordsLocalIdToUpload;
    maintenanceLogs.file_url = [NSString stringWithFormat:@"%@/%@/videos/file%.f%@",serverName, webAppDir, [[NSDate date] timeIntervalSince1970] * 1000000, imageNameToUpload];
    maintenanceLogs.local_url = [fileLocalUrl path];
    maintenanceLogs.file_name = imageNameToUpload;
    if (thumbLocalUrl != nil) {
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[thumbLocalUrl path]];
        if (image) {
            maintenanceLogs.fileSize = [NSString stringWithFormat:@"%.f:%.f", image.size.width, image.size.height];
        }else{
            maintenanceLogs.fileSize = @"1024:1024";
        }
    }else{
        maintenanceLogs.fileSize = @"1024:1024";
    }
    maintenanceLogs.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    maintenanceLogs.lastUpdate = @0;
    maintenanceLogs.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    maintenanceLogs.aircraft_local_id = aircraftToEdit.aircraft_local_id;
    maintenanceLogs.fileType = type;
    maintenanceLogs.thumb_url = @"";
    if (thumbLocalUrl != nil) {
        maintenanceLogs.thumb_url = [NSString stringWithFormat:@"%@/%@/figureimages/%@",serverName, webAppDir, [thumbLocalUrl lastPathComponent]];
    }
    maintenanceLogs.isUploaded = @0;
    NSError *error;
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self getMaintenanceLogs:currentSelectedAircraftLocalID];
    //////////////////////////////////
}

#pragma mark UIsession Delegate

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    float progress = [[NSNumber numberWithInteger:totalBytesSent] floatValue];
    float total = [[NSNumber numberWithInteger: totalBytesExpectedToSend] floatValue];
    NSLog(@"progress/total %f",progress/total);
    dispatch_async(dispatch_get_main_queue(), ^{
        [uploadTasksLock lock];
        UploadMaintenanceLogsInfo *uploadfileInfo = [uploadFileInfosWithUploadTask objectForKey:task];
        [uploadTasksLock unlock];
        if (uploadfileInfo.currentCell != nil) {
            if ([uploadfileInfo.maintenanceLog.fileType isEqualToString:@"video"] || [uploadfileInfo.maintenanceLog.fileType isEqualToString:@"pdf"] || [uploadfileInfo.maintenanceLog.fileType isEqualToString:@"gif"] || [uploadfileInfo.maintenanceLog.fileType isEqualToString:@"tif"]) {
                if ([uploadfileInfo.maintenanceLog.isUploaded integerValue] == 2) {
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
        UploadMaintenanceLogsInfo *uploadfileInfo = [uploadFileInfosWithUploadTask objectForKey:task];
        [uploadFileInfosWithUploadTask removeObjectForKey:task];
        [uploadTasksLock unlock];
        
        uploadfileInfo.uploadTask = nil;
        
        if (uploadfileInfo.maintenanceLog != nil) {
            [uploadTasksWithLocalID removeObjectForKey:uploadfileInfo.maintenanceLog.recordsLocal_id];
            [uploadFileInfoWithLocalID removeObjectForKey:uploadfileInfo.maintenanceLog.recordsLocal_id];
            if (uploadfileInfo.currentCell != nil) {
                if ([uploadfileInfo.currentCell.progressView progress] >= 1.0f) {
                    NSError *error;
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    
                    NSEntityDescription *recordsFileEntityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
                    NSFetchRequest *recordsFileRequest = [[NSFetchRequest alloc] init];
                    [recordsFileRequest setEntity:recordsFileEntityDescription];
                    NSPredicate *recordsFilePredicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", uploadfileInfo.maintenanceLog.recordsLocal_id];
                    [recordsFileRequest setPredicate:recordsFilePredicate];
                    NSArray *recordsFileArray = [context executeFetchRequest:recordsFileRequest error:&error];
                    if (recordsFileArray == nil) {
                    } else if (recordsFileArray.count == 0) {
                    } else if (recordsFileArray.count > 0) {
                        for (MaintenanceLogs *recordsFile in recordsFileArray) {
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
        });
    }
}
- (void)getRecrodsFileRunningAfterDelay{
    [self getMaintenanceLogs:currentSelectedAircraftLocalID];
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
                            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MaintenanceLogs" inManagedObjectContext:context];
                            [request setEntity:entityDescription];
                            // all lesson records with lastUpdate == 0 need to be uploaded
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordsLocal_id == %@", currentRecordsLocalIdToUpload];
                            [request setPredicate:predicate];
                            NSArray *fetchedRecordsFile = [context executeFetchRequest:request error:&error];
                            MaintenanceLogs *recordsFile = nil;
                            if (fetchedRecordsFile.count == 0) {
                                recordsFile = [NSEntityDescription insertNewObjectForEntityForName:@"RecordsFile" inManagedObjectContext:context];
                                recordsFile.maintenancelog_id = @0;
                                recordsFile.file_url = remoteFileUrl;
                                recordsFile.file_name = imageNameToUpload;
                                recordsFile.fileSize = [NSString stringWithFormat:@"%.f:%.f", cropImage.size.width, cropImage.size.height];
                                recordsFile.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                                recordsFile.lastUpdate = @0;
                                recordsFile.user_id = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                                recordsFile.aircraft_local_id = aircraftToEdit.aircraft_local_id;
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
                            [self getMaintenanceLogs:currentSelectedAircraftLocalID];
                            [[AppDelegate sharedDelegate] startThreadToSyncData:5];
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
- (IBAction)onDeleteLogs:(UIButton *)sender {
    if (!isDeleteMode) {
        isDeleteMode = YES;
        btnCloseOfLogs.hidden = NO;
        UIImage *btnEditImage = [[UIImage imageNamed:@"delete_doc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
        btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
        [MaintenanceCollectionView reloadData];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete the selected document(s)?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            [self deleteRecordsToBeSelected];
            
            btnCloseOfLogs.hidden = YES;
            isDeleteMode = NO;
            UIImage *btnEditImage = [[UIImage imageNamed:@"edit_file"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [btnDeleteLogs setImage:btnEditImage forState:UIControlStateNormal];
            btnDeleteLogs.tintColor = COLOR_BUTTON_BLUE;
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
    for (MaintenanceLogs *maintenanceToDelete in selectedThumbViews) {
        DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
        deleteQueryForAssignment.type = @"MaintenanceLogs";
        deleteQueryForAssignment.idToDelete = maintenanceToDelete.maintenancelog_id;
        
        [context deleteObject:maintenanceToDelete];
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
    [self getMaintenanceLogs:currentSelectedAircraftLocalID];
}
#pragma mark UICollectionViewDelegate
- (CGFloat)waterflowLayout:(KNWaterflowLayout *)waterflowLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath itemWidth:(CGFloat)itemWidth{
    UploadMaintenanceLogsInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    NSString *fileSizeStr = uploadFileInfo.maintenanceLog.fileSize;
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
    UploadMaintenanceLogsInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    uploadFileInfo.currentCell = cell;
    cell.progressMaskView.hidden = YES;
    
    if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"image"]){
        if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 0) {
            cell.progressMaskView.hidden = NO;
            NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
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
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.maintenanceLog.file_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
                [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
                [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                [uploadTasksLock unlock];
            }
        }
    }else{
        if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 0) {
            cell.progressMaskView.hidden = NO;
            NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
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
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.maintenanceLog.file_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *filePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
                [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
                [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                [uploadTasksLock unlock];
            }
        }else if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 2) {
            if([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"video"] || [uploadFileInfo.maintenanceLog.fileType isEqualToString:@"pdf"] || [uploadFileInfo.maintenanceLog.fileType isEqualToString:@"gif"] || [uploadFileInfo.maintenanceLog.fileType isEqualToString:@"tif"]){
                cell.progressMaskView.hidden = NO;
                NSURLSessionDataTask *tmpUploadTask = [uploadTasksWithLocalID objectForKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
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
                    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [[NSURL URLWithString:uploadFileInfo.maintenanceLog.thumb_url] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                    
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.thumb_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
                    [uploadTasksWithLocalID setObject:uploadFileInfo.uploadTask forKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
                    [uploadFileInfosWithUploadTask setObject:uploadFileInfo forKey:uploadFileInfo.uploadTask];
                    [uploadTasksLock unlock];
                }
            }
        }
    }
    cell.lblRecordsName.text = uploadFileInfo.maintenanceLog.file_name;
    [cell.recordsImageView setImage:[UIImage imageNamed:@"default_image"]];
    if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"image"] && ![uploadFileInfo.maintenanceLog.file_url isEqualToString:@""]) {
        if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
            [cell.recordsImageView setImageWithURL:[NSURL URLWithString:uploadFileInfo.maintenanceLog.file_url]];
            NSString *cachedPath = [LocalDBManager checkCachedFileExist:uploadFileInfo.maintenanceLog.file_url];
            if (cachedPath) {
                // load from cache
                UIImage *image = [UIImage imageWithContentsOfFile:cachedPath];
                [cell.recordsImageView setImage:image];
            } else {
                // save to temp directory
                NSURL *url = [NSURL URLWithString:uploadFileInfo.maintenanceLog.file_url];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
                NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
                    
                } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                    
                    return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.maintenanceLog.file_url]];
                    
                } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                    
                    [downloadProgressHUD hideAnimated:YES];
                    if (!error) {
                        UIImage *image = [UIImage imageWithContentsOfFile:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.maintenanceLog.file_url]];
                        [cell.recordsImageView setImage:image];
                    } else {
                        
                    }
                }];
                
                [downloadTask resume];
            }
        }else{
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            [cell.recordsImageView setImage:image];
        }
        
    }else{
        if (![uploadFileInfo.maintenanceLog.thumb_url isEqualToString:@""]) {
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [cell.recordsImageView setImageWithURL:[NSURL URLWithString:uploadFileInfo.maintenanceLog.thumb_url]];
                NSString *cachedPath = [LocalDBManager checkCachedFileExist:uploadFileInfo.maintenanceLog.thumb_url];
                if (cachedPath) {
                    // load from cache
                    UIImage *image = [UIImage imageWithContentsOfFile:cachedPath];
                    [cell.recordsImageView setImage:image];
                } else {
                    // save to temp directory
                    NSURL *url = [NSURL URLWithString:uploadFileInfo.maintenanceLog.thumb_url];
                    NSURLRequest *request = [NSURLRequest requestWithURL:url];
                    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
                    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
                        
                    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                        
                        return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.maintenanceLog.thumb_url]];
                        
                    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                        
                        [downloadProgressHUD hideAnimated:YES];
                        if (!error) {
                            UIImage *image = [UIImage imageWithContentsOfFile:[LocalDBManager getCachedFileNameFromRemotePath:uploadFileInfo.maintenanceLog.thumb_url]];
                            [cell.recordsImageView setImage:image];
                        } else {
                            
                        }
                    }];
                    
                    [downloadTask resume];
                }
            }else{
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *imagePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.thumb_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [cell.recordsImageView setImageWithURL:[NSURL URLWithString:imagePath]];
            }
        }
    }
    
    NSString *bmiddleUrl = uploadFileInfo.maintenanceLog.file_url;
    
    KNPhotoItems *items = [[KNPhotoItems alloc] init];
    items.url = bmiddleUrl;
    items.sourceView = cell.recordsImageView;
    items.itemType = uploadFileInfo.maintenanceLog.fileType;
    if(![tempArr containsObject:bmiddleUrl]){
        [itemsArr addObject:items];
        [tempArr addObject:bmiddleUrl];
    }
    
    if (isDeleteMode) {
        cell.maskView.hidden = NO;
        
        if ([selectedThumbViews containsObject:uploadFileInfo.maintenanceLog]) {
            cell.selectedImageView.hidden = NO;
        }else{
            cell.selectedImageView.hidden = YES;
        }
    }else{
        cell.maskView.hidden = YES;
    }
    
    [uploadFileInfoWithLocalID setObject:uploadFileInfo forKey:uploadFileInfo.maintenanceLog.recordsLocal_id];
    [recordsFilesArray replaceObjectAtIndex:indexPath.row withObject:uploadFileInfo];
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UploadMaintenanceLogsInfo *uploadFileInfo = [recordsFilesArray objectAtIndex:indexPath.row];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if (isDeleteMode) {
        if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
            if ([selectedThumbViews containsObject:uploadFileInfo.maintenanceLog]) {
                [selectedThumbViews removeObject:uploadFileInfo.maintenanceLog];
            }else{
                [selectedThumbViews addObject:uploadFileInfo.maintenanceLog];
            }
            [MaintenanceCollectionView reloadData];
        }
    }else{
        if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"image"]) {
            KNPhotoBrower *photoBrower = [[KNPhotoBrower alloc] init];
            [photoBrower setDelegate:self];
            [photoBrower setItemsArr:[itemsArr copy]];
            [photoBrower setCurrentIndex:indexPath.row];
            [photoBrower setDataSourceUrlArr:[collectionPrepareArr copy]];
            [photoBrower setSourceViewForCellReusable:MaintenanceCollectionView];
            [photoBrower present];
            _ApplicationStatusIsHidden = YES;
            [self setNeedsStatusBarAppearanceUpdate];
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"video"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self videoTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self playVideoAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"pdf"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self pdfTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPDFAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"tif"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self tifTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"text"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self docTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewDocAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"gif"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self gifTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"ppt"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                [self pptTouched:uploadFileInfo.maintenanceLog.file_url withFileName:uploadFileInfo.maintenanceLog.file_name];
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                [self viewPPTAtLocalPath:tmpFilePath];
            }
        }else if ([uploadFileInfo.maintenanceLog.fileType isEqualToString:@"other"]){
            if ([uploadFileInfo.maintenanceLog.isUploaded integerValue] == 1) {
                
            }else{
                NSString *tmpFilePath =[documentsDirectory stringByAppendingPathComponent:[[[NSURL URLWithString:uploadFileInfo.maintenanceLog.local_url] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                
                
            }
            
        }
    }
}
#pragma mark RecordsFileCellDelegate
- (void)pressedLongTouchToRename:(RecordsFileCell *)_cell{
    [[AppDelegate sharedDelegate] stopThreadToSyncData:5];
    NSIndexPath *indexpath = [MaintenanceCollectionView indexPathForCell:_cell];
    UploadMaintenanceLogsInfo *uploadFileInfoToUpdate = [recordsFilesArray objectAtIndex:indexpath.row];
    currentSelectedrecordsFile = uploadFileInfoToUpdate.maintenanceLog;
    
    indexToEdit = indexpath.row;
    tmptext.text = uploadFileInfoToUpdate.maintenanceLog.file_name;
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
