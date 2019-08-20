//
//  NavLogViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "NavLogViewController.h"
#import <UIKit/UIKit.h>
#import "NavLogCell.h"
#import "preNovLogCell.h"
#import "SavedFileCollectionCell.h"
#import "TimeViewController.h"
#import "DateViewController.h"
#import <QuartzCore/QuartzCore.h>

#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"


#define NAVLOG_TABLE_COORD_Y 285

@interface NavLogViewController ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NavLogCellDelegate, preNovLogCellDelegate, TimeViewControllerDelegate, DateViewControllerDelegate, UIPopoverControllerDelegate, UITextViewDelegate>
{
    NSMutableArray *arr_CheckPoint;
    
    NSMutableArray *preNavLogArray;
    NSMutableArray *navLogRecordArray;
    NSMutableArray *savedNavLogsArray;
    
    NSManagedObjectContext *context;
    
    NavLog *currentSelectedNavLog;
    
    UIView *containsViewOfAdd;
    
    BOOL isOpenPicker;
    
    BOOL isChanged;
    
    CGFloat keyboardHeight;
    
    BOOL isSaving;
}

@end

@implementation NavLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"NAVLOG";
    [self.navigationItem setHidesBackButton:YES animated:YES];
    showKeyboard = NO;
    isChanged = NO;
    isSaving = NO;
    NavLogTableView.scrollEnabled = NO;
    preNavLogTableView.scrollEnabled = NO;
    
    preNavLogArray = [[NSMutableArray alloc] init];
    navLogRecordArray = [[NSMutableArray alloc] init];
    savedNavLogsArray = [[NSMutableArray alloc] init];

    keyboardHeight = 0;
    
    currentSelectedNavLog = nil;
    isOpenPicker = NO;
    context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    [SavedFilesCollectionView registerNib:[UINib nibWithNibName:@"SavedFileCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"SavedFileCollectionItem"];
    
    //for new NavLog
    arr_CheckPoint=[[NSMutableArray alloc]initWithObjects:@"",@"",@"",@"", nil];
    
    txtAirCraft.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    [txtAirCraft addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    
    [navView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, navView.frame.size.height)];
}
- (void)avoidToBeRotatedView{
    //[AppDelegate sharedDelegate].isSelectedLandscape = YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"NavlogViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar addSubview:navView];
    [self getNavLogsFromLocal];
    
    [SavedFilesCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:[AppDelegate sharedDelegate].selectedNavLogIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionRight];
}
- (void)reloadNavLogs{
    [self getNavLogsFromLocal];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [AppDelegate sharedDelegate].isSelectedLandscape = NO;
    [navView removeFromSuperview];
    [AppDelegate sharedDelegate].navLog_VC = nil;
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)deviceOrientationDidChange{
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
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
   [self resizeTableViewAndScrollPosition];
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!showKeyboard)
    {
        showKeyboard = YES;
        CGSize scrSize = scrView.contentSize;
        scrSize.height = scrSize.height + 342.0f;
        [scrView setContentSize:scrSize];
    }
    
    NSDictionary* keyboardInfo = [aNotification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (showKeyboard)
    {
        [self.view endEditing:YES];
        showKeyboard = NO;
        [self resizeTableViewAndScrollPosition];
        
    }
}
- (void)textFieldDidChange:(UITextField *)textField {
    NSRange range = [textField.text rangeOfString : @"-"];
    if (range.location != NSNotFound) {
        txtAirCraft.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    }
}
- (void)getNavLogsFromLocal{
    [savedNavLogsArray removeAllObjects];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve NavLogs!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid NavLogs found!");
    } else {
        FDLogDebug(@"%lu NavLogs found", (unsigned long)[objects count]);
        NSMutableArray *tempNavLogs = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"navLogLocalID" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedNavLogs = [tempNavLogs sortedArrayUsingDescriptors:sortDescriptors];
        
        
        for (NavLog *navLog in sortedNavLogs) {
            [savedNavLogsArray addObject:navLog];
        }
    }
    [SavedFilesCollectionView reloadData];
}

- (void)initAllItemsWithCheckPoints{
    [preNavLogArray removeAllObjects];
    [navLogRecordArray removeAllObjects];
    if (currentSelectedNavLog != nil) {
        txtNovlogName.text = currentSelectedNavLog.navLogName;
        txtAirCraft.text = currentSelectedNavLog.aircraftNum;
        txtDate.text = currentSelectedNavLog.navLogDate;
        txtViewNotes.text = currentSelectedNavLog.notes;
        txtHeaderCasTas.text = currentSelectedNavLog.casTasVal;
        txtHeaderDistRem.text = [currentSelectedNavLog.distLeg stringValue];
        txtHeaderTimeOff.text = currentSelectedNavLog.timeOff;
        txtHeaderFuel.text = [currentSelectedNavLog.fuel stringValue];
        txtHeaderGPH.text = [currentSelectedNavLog.gph stringValue];
        
        for (int i = 0; i < currentSelectedNavLog.navLogRecords.count - 1; i ++) {
            NavLogRecord *navLogRecord = [currentSelectedNavLog.navLogRecords objectAtIndex:i];
            NSMutableDictionary *preNavLogDict = [[NSMutableDictionary alloc] init];
            [preNavLogDict setValue:navLogRecord.checkPoint forKey:@"checkPoint"];
            [preNavLogDict setValue:navLogRecord.vorIdent forKey:@"vorIdent"];
            [preNavLogDict setValue:navLogRecord.vorFreq forKey:@"vorFreq"];
            [preNavLogDict setValue:navLogRecord.vorTo forKey:@"vorTo"];
            [preNavLogDict setValue:navLogRecord.vorFrom forKey:@"vorFrom"];
            [preNavLogDict setValue:navLogRecord.ordering forKey:@"ordering"];
            
            [preNavLogArray addObject:preNavLogDict];
            
            NSMutableDictionary *navLogDict = [[NSMutableDictionary alloc] init];
            [navLogDict setValue:navLogRecord.course forKey:@"course"];
            [navLogDict setValue:[navLogRecord.attitude stringValue] forKey:@"Att"];
            [navLogDict setValue:[navLogRecord.windDir stringValue] forKey:@"WindDir"];
            [navLogDict setValue:[navLogRecord.windVel stringValue] forKey:@"WindVel"];
            [navLogDict setValue:[navLogRecord.windTemp stringValue] forKey:@"WindTemp"];
            [navLogDict setValue:[navLogRecord.casTas stringValue] forKey:@"CasTas"];
            [navLogDict setValue:navLogRecord.tc forKey:@"Tc"];
            [navLogDict setValue:navLogRecord.lrWca forKey:@"Wca"];
            [navLogDict setValue:navLogRecord.th forKey:@"Th"];
            [navLogDict setValue:navLogRecord.lwVar forKey:@"Var"];
            [navLogDict setValue:navLogRecord.mh forKey:@"Mh"];
            [navLogDict setValue:navLogRecord.dev forKey:@"Dev"];
            [navLogDict setValue:navLogRecord.ch forKey:@"CHAns"];
            [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:[navLogRecord.distLeg stringValue]] forKey:@"distLeg"];
            [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:[navLogRecord.distRem stringValue]] forKey:@"LegSum"];
            [navLogDict setValue:navLogRecord.gsEst forKey:@"Est"];
            [navLogDict setValue:navLogRecord.gsAct forKey:@"Act"];
            [navLogDict setValue:navLogRecord.timeOffATE forKey:@"TimeOffATE"];
            [navLogDict setValue:navLogRecord.fuelATA forKey:@"fuelATA"];
            [navLogDict setValue:navLogRecord.timeOffETE forKey:@"TimeOff"];
            [navLogDict setValue:navLogRecord.fuelETA forKey:@"Fuel"];
            [navLogDict setValue:navLogRecord.gphFuel forKey:@"Gph"];
            [navLogDict setValue:navLogRecord.gphRem forKey:@"GphRem"];
            [navLogDict setValue:navLogRecord.ordering forKey:@"ordering"];
            
            [navLogRecordArray addObject:navLogDict];
        }
        
        //add last prenavlog
        NavLogRecord *navLogRecord = [currentSelectedNavLog.navLogRecords objectAtIndex:currentSelectedNavLog.navLogRecords.count-1];
        NSMutableDictionary *preNavLogDict = [[NSMutableDictionary alloc] init];
        [preNavLogDict setValue:navLogRecord.checkPoint forKey:@"checkPoint"];
        [preNavLogDict setValue:navLogRecord.vorIdent forKey:@"vorIdent"];
        [preNavLogDict setValue:navLogRecord.vorFreq forKey:@"vorFreq"];
        [preNavLogDict setValue:navLogRecord.vorTo forKey:@"vorTo"];
        [preNavLogDict setValue:navLogRecord.vorFrom forKey:@"vorFrom"];
        [preNavLogDict setValue:navLogRecord.ordering forKey:@"ordering"];
        
        [preNavLogArray addObject:preNavLogDict];
        
    }else{
        txtNovlogName.text = @"";
        txtAirCraft.text = @"";
        txtDate.text = @"";
        txtViewNotes.text = @"";
        txtHeaderCasTas.text = @"";
        txtHeaderDistRem.text = @"";
        txtHeaderTimeOff.text = @"";
        txtHeaderFuel.text = @"";
        txtHeaderGPH.text = @"";
        
        txtGPHTotal.text = @"";
        txtDistTotal.text = @"";
        txtTimeOffTotal.text = @"";
        int index = 1;
        for (NSString *checkPoints in arr_CheckPoint) {
            NSMutableDictionary *preNavLogDict = [[NSMutableDictionary alloc] init];
            [preNavLogDict setValue:checkPoints forKey:@"checkPoint"];
            [preNavLogDict setValue:@"" forKey:@"vorIdent"];
            [preNavLogDict setValue:@"" forKey:@"vorFreq"];
            [preNavLogDict setValue:@"" forKey:@"vorTo"];
            [preNavLogDict setValue:@"" forKey:@"vorFrom"];
            [preNavLogDict setValue:@(index) forKey:@"ordering"];
            
            [preNavLogArray addObject:preNavLogDict];
            index = index + 1;
        }
        
        for (int i = 0 ; i < arr_CheckPoint.count - 1; i ++) {
            NSMutableDictionary *navLogDict = [[NSMutableDictionary alloc] init];
            [navLogDict setValue:@"" forKey:@"course"];
            [navLogDict setValue:@"" forKey:@"Att"];
            [navLogDict setValue:@"" forKey:@"WindDir"];
            [navLogDict setValue:@"" forKey:@"WindVel"];
            [navLogDict setValue:@"" forKey:@"WindTemp"];
            [navLogDict setValue:@"" forKey:@"CasTas"];
            [navLogDict setValue:@"" forKey:@"Tc"];
            [navLogDict setValue:@"" forKey:@"Wca"];
            [navLogDict setValue:@"" forKey:@"Th"];
            [navLogDict setValue:@"" forKey:@"Var"];
            [navLogDict setValue:@"" forKey:@"Mh"];
            [navLogDict setValue:@"" forKey:@"Dev"];
            [navLogDict setValue:@"" forKey:@"CHAns"];
            [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"distLeg"];
            [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"LegSum"];
            [navLogDict setValue:@"" forKey:@"Est"];
            [navLogDict setValue:@"" forKey:@"Act"];
            [navLogDict setValue:@"" forKey:@"TimeOffATE"];
            [navLogDict setValue:@"" forKey:@"fuelATA"];
            [navLogDict setValue:@"" forKey:@"TimeOff"];
            [navLogDict setValue:@"" forKey:@"Fuel"];
            [navLogDict setValue:@"" forKey:@"Gph"];
            [navLogDict setValue:@"" forKey:@"GphRem"];
            [navLogDict setValue:@(i+1) forKey:@"ordering"];
            
            [navLogRecordArray addObject:navLogDict];
        }
    }
    [self resizeTableViewAndScrollPosition];
    [self totalWithNavLog];
    [preNavLogTableView reloadData];
    [NavLogTableView reloadData];
}
- (void)addOneRowInCurrentNavLog{
    isChanged = YES;
    NSMutableDictionary *preNavLogDict = [[NSMutableDictionary alloc] init];
    [preNavLogDict setValue:@"" forKey:@"checkPoint"];
    [preNavLogDict setValue:@"" forKey:@"vorIdent"];
    [preNavLogDict setValue:@"" forKey:@"vorFreq"];
    [preNavLogDict setValue:@"" forKey:@"vorTo"];
    [preNavLogDict setValue:@"" forKey:@"vorFrom"];
    [preNavLogDict setValue:@(preNavLogArray.count + 1) forKey:@"ordering"];
    
    [preNavLogArray addObject:preNavLogDict];
    
    NSMutableDictionary *navLogDict = [[NSMutableDictionary alloc] init];
    [navLogDict setValue:@"" forKey:@"course"];
    [navLogDict setValue:@"" forKey:@"Att"];
    [navLogDict setValue:@"" forKey:@"WindDir"];
    [navLogDict setValue:@"" forKey:@"WindVel"];
    [navLogDict setValue:@"" forKey:@"WindTemp"];
    [navLogDict setValue:@"" forKey:@"CasTas"];
    [navLogDict setValue:@"" forKey:@"Tc"];
    [navLogDict setValue:@"" forKey:@"Wca"];
    [navLogDict setValue:@"" forKey:@"Th"];
    [navLogDict setValue:@"" forKey:@"Var"];
    [navLogDict setValue:@"" forKey:@"Mh"];
    [navLogDict setValue:@"" forKey:@"Dev"];
    [navLogDict setValue:@"" forKey:@"CHAns"];
    [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"distLeg"];
    [navLogDict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"LegSum"];
    [navLogDict setValue:@"" forKey:@"Est"];
    [navLogDict setValue:@"" forKey:@"Act"];
    [navLogDict setValue:@"" forKey:@"TimeOffATE"];
    [navLogDict setValue:@"" forKey:@"fuelATA"];
    [navLogDict setValue:@"" forKey:@"TimeOff"];
    [navLogDict setValue:@"" forKey:@"Fuel"];
    [navLogDict setValue:@"" forKey:@"Gph"];
    [navLogDict setValue:@"" forKey:@"GphRem"];
    [navLogDict setValue:@(navLogRecordArray.count + 1) forKey:@"ordering"];
    
    [navLogRecordArray addObject:navLogDict];
    [self resizeTableViewAndScrollPosition];
    [preNavLogTableView reloadData];
    [NavLogTableView reloadData];
}
- (void)resizeTableViewAndScrollPosition{
    CGSize scrSize = scrView.contentSize;
    scrSize.height = 77.0f + preNavLogArray.count * 52.0f + 70.0f;
    [scrView setContentSize:scrSize];
    //resize tableview
    CGRect tableRect = NavLogTableView.frame;
    tableRect.size.height = navLogRecordArray.count * 52.0f;
    NavLogTableView.frame = tableRect;
    tableRect = preNavLogTableView.frame;
    tableRect.size.height = preNavLogArray.count * 52.0f;
    preNavLogTableView.frame = tableRect;
    
    //resize coverview
    [preNavLogCoverView setFrame:CGRectMake(preNavLogCoverView.frame.origin.x, preNavLogCoverView.frame.origin.y, preNavLogCoverView.frame.size.width, scrSize.height-70.0f)];
    [navLogCoverView setFrame:CGRectMake(navLogCoverView.frame.origin.x, navLogCoverView.frame.origin.y, navLogCoverView.frame.size.width, scrSize.height-70.0f)];
    [navLogSrollingView setFrame:CGRectMake(navLogSrollingView.frame.origin.x, navLogSrollingView.frame.origin.y, self.view.frame.size.width - preNavLogCoverView.frame.size.width, scrSize.height-70.0f)];
    CGSize navLogSrollingViewSize = navLogSrollingView.contentSize;
    navLogSrollingViewSize.width = 734.0f;
    [navLogSrollingView setContentSize:navLogSrollingViewSize];
    
    [coverViewToAddRo setFrame:CGRectMake(0, scrSize.height-70.0f, coverViewToAddRo.frame.size.width, 34.0f)];
    [totalCoverView setFrame:CGRectMake(totalCoverView.frame.origin.x, 102 + navLogRecordArray.count * 52.0f, totalCoverView.frame.size.width, totalCoverView.frame.size.height)];
}

- (void) calculateValue
{
    //float Answer = asin(((13.0/90.0)*sin((180/M_PI)*(240-229))));
}

#pragma mark : Collection View Datasource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (savedNavLogsArray.count == 0) {
        return 1;
    }
    return [savedNavLogsArray count];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    return CGSizeMake(240, 35);
}
-(SavedFileCollectionCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentfier = @"SavedFileCollectionItem";
    SavedFileCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentfier forIndexPath:indexPath];
    cell.lblSavedFileName.layer.masksToBounds = YES;
    if (savedNavLogsArray.count == 0) {
        cell.lblSavedFileName.text = @"New Navigation Log";
        cell.lblSavedFileName.backgroundColor = [UIColor clearColor];
        cell.lblSavedFileName.textColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f];
        cell.lblSavedFileName.layer.borderColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f].CGColor;
        currentSelectedNavLog = nil;
        btnDel.enabled = NO;
        [self initAllItemsWithCheckPoints];
        return cell;
    }else{
        id navLogElement = [savedNavLogsArray objectAtIndex:indexPath.row];
        if ([navLogElement isKindOfClass:[NavLog class]]) {
            NavLog * currentNavLog = (NavLog *)navLogElement;
            cell.lblSavedFileName.text = currentNavLog.navLogName;
            cell.lblSavedFileName.backgroundColor = [UIColor clearColor];
            cell.lblSavedFileName.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
            cell.lblSavedFileName.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
            if ([AppDelegate sharedDelegate].selectedNavLogIndex == indexPath.row) {
                btnDel.enabled = YES;
                cell.lblSavedFileName.backgroundColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                cell.lblSavedFileName.textColor = [UIColor whiteColor];
                cell.lblSavedFileName.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                currentSelectedNavLog = currentNavLog;
                [self initAllItemsWithCheckPoints];
            }
            return cell;
        }else if ([navLogElement isKindOfClass:[NSString class]]) {
            cell.lblSavedFileName.text = @"New Navigation Log";
            cell.lblSavedFileName.backgroundColor = [UIColor clearColor];
            cell.lblSavedFileName.textColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f];
            cell.lblSavedFileName.layer.borderColor = [UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f].CGColor;
            currentSelectedNavLog = nil;
            [self initAllItemsWithCheckPoints];
            btnDel.enabled = NO;
            return cell;
        }
        
        
       
    }
    
    return nil;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([AppDelegate sharedDelegate].selectedNavLogIndex == indexPath.row) {
        return;
    }
    [self.view endEditing:YES];
    id navLogElement = [savedNavLogsArray objectAtIndex:0];
    if ([navLogElement isKindOfClass:[NSString class]]) {
        if (isChanged) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save current NavLog?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                isChanged = NO;
                if (!txtNovlogName.text.length)
                {
                    [self showAlert:@"Please input Navlog Name" :@"Input Error"];
                    return;
                }
                if (!txtAirCraft.text.length)
                {
                    [self showAlert:@"Please input Aircraft Number" :@"Input Error"];
                    return;
                }
                if (!txtDate.text.length)
                {
                    [self showAlert:@"Please setup Date" :@"Input Error"];
                    return;
                }
                
                [self saveNewNavLogOnLocal];
                [AppDelegate sharedDelegate].selectedNavLogIndex = indexPath.row;
                [SavedFilesCollectionView reloadData];
                
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                isChanged = NO;
                [savedNavLogsArray removeObjectAtIndex:0];
                [AppDelegate sharedDelegate].selectedNavLogIndex = indexPath.row-1;
                [SavedFilesCollectionView reloadData];
            }];
            
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            isChanged = NO;
            [savedNavLogsArray removeObjectAtIndex:0];
            [AppDelegate sharedDelegate].selectedNavLogIndex = indexPath.row-1;
            [SavedFilesCollectionView reloadData];
        }
    }else{
        if (isChanged) {
            //save current NavLog
            
            NSError *error;
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogName == %@ && navLogLocalID != %@", txtNovlogName.text, currentSelectedNavLog.navLogLocalID];
            [request setPredicate:predicate];
            NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
            if (fetchedNavLogs.count > 0) {
                [self showAlert:[NSString stringWithFormat:@"%@ already exists, Check NavLog Name and try again.", txtNovlogName.text] :@"FlightDesk"];
                return ;
            }
            isChanged = NO;
            [self updateCurrentNavLogOnLocal];
        }
        [AppDelegate sharedDelegate].selectedNavLogIndex = indexPath.row;
        [SavedFilesCollectionView reloadData];
    }
}
#pragma mark UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == NavLogTableView) {
        return navLogRecordArray.count;
    }else if (tableView == preNavLogTableView){
        return preNavLogArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == NavLogTableView) {
        static NSString *simpleTableIdentifier = @"NavLogItem";
        NavLogCell *cell = (NavLogCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [NavLogCell sharedCell];
            cell.courseTextField.delegate = cell;
            cell.attitudeTextField.delegate = cell;
            cell.windDirTextField.delegate = cell;
            cell.windVelTextField.delegate = cell;
            cell.windTempTextField.delegate = cell;
            cell.casTasValueTextField.delegate = cell;
            cell.tcTextField.delegate = cell;
            cell.varTextField.delegate = cell;
            cell.devTextField.delegate = cell;
            cell.leg12TextField.delegate = cell;
            cell.actTextField.delegate = cell;
        }
        cell.delegate = self;
        NSMutableDictionary *navLogRecordDict = [navLogRecordArray objectAtIndex:indexPath.row];
        [cell saveNavLogRecord:navLogRecordDict];
        
        
        cell.windDirTextField.tag = 1+(indexPath.row+1)*100;
        cell.windVelTextField.tag = 2+(indexPath.row+1)*100;
        cell.windTempTextField.tag = 3+(indexPath.row+1)*100;
        cell.casTasValueTextField.tag = 4+(indexPath.row+1)*100;
        cell.tcTextField.tag = 5+(indexPath.row+1)*100;
        cell.varTextField.tag = 6+(indexPath.row+1)*100;
        cell.devTextField.tag = 7+(indexPath.row+1)*100;
        cell.leg12TextField.tag = 8+(indexPath.row+1)*100;
        cell.actTextField.tag = 9 +(indexPath.row+1)*100;
        
        if (indexPath.row == 0) {
            cell.distRem = txtHeaderDistRem.text;
            cell.headerTimeOff = txtHeaderTimeOff.text;
            cell.headerFuelLoad = txtHeaderFuel.text;
            cell.headerGPH = txtHeaderGPH.text;
        }else{
            cell.distRem = [[[navLogRecordArray objectAtIndex:indexPath.row-1] objectForKey:@"LegSum"] stringValue];
            cell.headerTimeOff = [[navLogRecordArray objectAtIndex:indexPath.row-1] objectForKey:@"Fuel"];
            cell.headerFuelLoad = [[navLogRecordArray objectAtIndex:indexPath.row-1] objectForKey:@"GphRem"];
            cell.headerGPH = txtHeaderGPH.text;
        }
        
        return cell;
    }else if(tableView == preNavLogTableView){
        
        static NSString *simpleTableIdentifier = @"preNovLogItem";
        preNovLogCell *cell = (preNovLogCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [preNovLogCell sharedCell];
            cell.txtViewCheckPoint.delegate = cell;
            cell.identTextField.delegate = cell;
            cell.identTextField.delegate = cell;
            cell.freqTextField.delegate = cell;
            cell.toTextField.delegate = cell;
            cell.fromTextField.delegate = cell;
        }
        cell.delegate = self;
        NSMutableDictionary *preNavLogDict = [preNavLogArray objectAtIndex:indexPath.row];
        [cell savePreNavLog:preNavLogDict];
        return cell;
    }
    return nil;
}

#pragma mark NavLogCellDelegate
- (void)startedToEditCurrentCell:(NavLogCell *)_cell{
    NSIndexPath *indexPath = [NavLogTableView indexPathForCell:_cell];
    
    if (self.view.frame.size.height > self.view.frame.size.width) {
        CGFloat coordYOfCurrentSelectedCell = NAVLOG_TABLE_COORD_Y + 52.0f * indexPath.row;
         if ((self.view.frame.size.height - keyboardHeight) < coordYOfCurrentSelectedCell ) {
             [scrView setContentOffset:CGPointMake(0,50.0f + 52.0f * (indexPath.row - 5)) animated:YES];
         }
        
    }else{
        [scrView setContentOffset:CGPointMake(0,50.0f + 52.0f * indexPath.row) animated:YES];
    }
    
}
- (void)returnedToEditCurrentCell:(NavLogCell *)_cell{
    NSIndexPath *indexPath = [NavLogTableView indexPathForCell:_cell];
    indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0];
    preNovLogCell *cellToUpdate = [preNavLogTableView cellForRowAtIndexPath:indexPath];
    [cellToUpdate.txtViewCheckPoint becomeFirstResponder];
}
- (void)didUpdateNavLogRecord:(NSMutableDictionary *)contentInfo cell:(NavLogCell *)_cell{
    
    isChanged = YES;
    NSIndexPath *indexPath = [NavLogTableView indexPathForCell:_cell];
    [navLogRecordArray replaceObjectAtIndex:indexPath.row withObject:contentInfo];
    
    for (int i = indexPath.row + 1; i < navLogRecordArray.count; i ++) {
        NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
        NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
        
        
        
        NSString *timOffToChanged = @"";
        NSInteger mins = [[dictToUpdate objectForKey:@"TimeOff"] integerValue];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSDate *preTimeOff = [dateFormatter dateFromString:[preDict objectForKey:@"Fuel"]];
        NSTimeInterval secondsInMins = mins * 60;
        NSDate *dateToCalcuated = [preTimeOff dateByAddingTimeInterval:secondsInMins];
        timOffToChanged = [dateFormatter stringFromDate:dateToCalcuated];
        if (timOffToChanged != nil) {
            [dictToUpdate setValue:timOffToChanged forKey:@"Fuel"];
        }
        
        float gphRem = 0;
        gphRem = [[preDict objectForKey:@"GphRem"] floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
        [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]] forKey:@"GphRem"];
        
        float gpuValue = [[dictToUpdate objectForKey:@"distLeg"] floatValue] / [[dictToUpdate objectForKey:@"Est"] floatValue] * [txtHeaderGPH.text floatValue];
        if (!isnan(gpuValue)) {
            [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gpuValue uptoDecimal:1]] forKey:@"Gph"];
        }
        
        
        [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
        
        NavLogCell *cellToUpdate = [NavLogTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cellToUpdate.distRem = [[dictToUpdate objectForKey:@"LegSum"] stringValue];
        cellToUpdate.headerTimeOff = [dictToUpdate objectForKey:@"Fuel"];
        cellToUpdate.headerFuelLoad = [dictToUpdate objectForKey:@"GphRem"];
        if (![[[preDict objectForKey:@"LegSum"] stringValue] isEqualToString:@""] && ![[[preDict objectForKey:@"distLeg"] stringValue] isEqualToString:@""]) {
            NSDecimalNumber *sumLeg = [[NSDecimalNumber decimalNumberWithString:[[preDict objectForKey:@"LegSum"] stringValue]] decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:[[dictToUpdate objectForKey:@"distLeg"] stringValue]]];
            [dictToUpdate setValue:sumLeg forKey:@"LegSum"];
            cellToUpdate.legSumTextField.text = [NSString stringWithFormat:@"%@", sumLeg];
        }
        
        
        
        NSInteger hours = 0;
        if (mins > 60) {
            hours = (mins / 60 ) % 60;
        }
        NSString *timeOffStr = @"";
        if (mins < 10) {
            if (hours < 10) {
                timeOffStr = [NSString stringWithFormat:@"0%ld:0%ld", (long)hours, (long)mins%60];
            }else{
                timeOffStr = [NSString stringWithFormat:@"%ld:0%ld", (long)hours, (long)mins%60];
            }
        }else{
            if (hours < 10) {
                timeOffStr = [NSString stringWithFormat:@"0%ld:%ld", (long)hours, (long)mins%60];
            }else{
                timeOffStr = [NSString stringWithFormat:@"%ld:%ld", (long)hours, (long)mins%60];
            }
        }
        cellToUpdate.timeOffTextField.text = timeOffStr;
        cellToUpdate.fuelTextField.text = timOffToChanged;
        if (!isnan(gpuValue)) {
            cellToUpdate.gphTextField.text = [NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gpuValue uptoDecimal:1]];
        }
        cellToUpdate.gphRemTextField.text = [NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]];
    }
    
    [self totalWithNavLog];
    NSLog(@"");
}

#pragma mark preNovLogCellDelegate
- (void)beginedToEditCurrentCell:(preNovLogCell *)_cell{
    NSIndexPath *indexPath = [preNavLogTableView indexPathForCell:_cell];
    if (self.view.frame.size.height > self.view.frame.size.width) {
        CGFloat coordYOfCurrentSelectedCell = NAVLOG_TABLE_COORD_Y + 52.0f * indexPath.row;
        if ((self.view.frame.size.height - keyboardHeight) < coordYOfCurrentSelectedCell ) {
            [scrView setContentOffset:CGPointMake(0,50.0f + 52.0f * (indexPath.row - 5)) animated:YES];
        }
        
    }else{
        [scrView setContentOffset:CGPointMake(0,50.0f + 52.0f * indexPath.row) animated:YES];
    }
}
- (void)didUpdatePreNavLog:(NSMutableDictionary *)contentInfo cell:(preNovLogCell *)_cell{
    
    isChanged = YES;
    NSIndexPath *indexPath = [preNavLogTableView indexPathForCell:_cell];
    [preNavLogArray replaceObjectAtIndex:indexPath.row withObject:contentInfo];
}
- (void)returnLastTextfield:(preNovLogCell *)_cell{
    NSIndexPath *indexPath = [preNavLogTableView indexPathForCell:_cell];
    if (indexPath.row < navLogRecordArray.count) {
        NavLogCell *cellToUpdate = [NavLogTableView cellForRowAtIndexPath:indexPath];
        [cellToUpdate.courseTextField becomeFirstResponder];
    }else{
        [self addOneRowInCurrentNavLog];
    }
}

#pragma mark UITextfieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == txtHeaderDistRem) {
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            CGFloat sumLeg = 0;
            if (i == 0) {
                sumLeg = [txtHeaderDistRem.text floatValue] - [[dictToUpdate objectForKey:@"distLeg"] floatValue];
            }else {
                NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
                sumLeg = [[preDict objectForKey:@"LegSum"] floatValue] - [[dictToUpdate objectForKey:@"distLeg"] floatValue];
            }
            [dictToUpdate setValue:[[NSDecimalNumber alloc] initWithFloat:sumLeg] forKey:@"LegSum"];
            [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
        }
    }else if (textField == txtHeaderFuel) {
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            float gphRem = 0;
            if (i == 0) {
                gphRem = [txtHeaderFuel.text floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
            }else {
                NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
                gphRem = [[preDict objectForKey:@"GphRem"] floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
            }
            [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]] forKey:@"GphRem"];
            [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
        }
    }else if (textField == txtHeaderGPH) {
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            float gpuValue = [[dictToUpdate objectForKey:@"distLeg"] floatValue] / [[dictToUpdate objectForKey:@"Est"] floatValue] * [txtHeaderGPH.text floatValue];
            if (!isnan(gpuValue)) {
                [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gpuValue uptoDecimal:1]] forKey:@"Gph"];
                [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
            }
        }
    }
    [self totalWithNavLog];
    [NavLogTableView reloadData];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtNovlogName) {
        [txtAirCraft becomeFirstResponder];
    }else if (textField == txtAirCraft) {
        [txtHeaderCasTas becomeFirstResponder];
    }else if (textField == txtHeaderCasTas) {
        [txtHeaderDistRem becomeFirstResponder];
    }else if (textField == txtHeaderDistRem) {
        [txtHeaderFuel becomeFirstResponder];
    }else if (textField == txtHeaderFuel) {
        [txtHeaderGPH becomeFirstResponder];
    }else if (textField == txtHeaderGPH) {
        preNovLogCell *cell = [preNavLogTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [cell.txtViewCheckPoint becomeFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    isChanged = YES;
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField == txtHeaderDistRem) {
        BOOL valid = NO;
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        for (int i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if ([myCharSet characterIsMember:c]) {
                valid = YES;
            }
        }
        
        if (!valid && range.length != 1){
            return NO;
        }
        
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            CGFloat sumLeg = 0;
            if (i == 0) {
                sumLeg = [text integerValue] - [[dictToUpdate objectForKey:@"distLeg"] floatValue];
            }else {
                NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
                sumLeg = [[preDict objectForKey:@"LegSum"] floatValue] - [[dictToUpdate objectForKey:@"distLeg"] floatValue];
            }
            [dictToUpdate setValue:[[NSDecimalNumber alloc] initWithFloat:sumLeg] forKey:@"LegSum"];
            [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
        }
        
        
    }else if(textField == txtHeaderFuel) {
        BOOL valid = NO;
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        for (int i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if ([myCharSet characterIsMember:c]) {
                valid = YES;
            }
        }
        
        if (!valid && range.length != 1){
            return NO;
        }
        
        NSCharacterSet *cs = [myCharSet invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
        if ([string isEqualToString:@"."] && range.length<1 && [textField.text containsString:@"."]) {
            finalString=[finalString substringToIndex:[finalString length]-1];
        }
        textField.text = finalString;
        
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            float gphRem = 0;
            if (i == 0) {
                gphRem = [text floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
            }else {
                NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
                gphRem = [[preDict objectForKey:@"GphRem"] floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
            }
            [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]] forKey:@"GphRem"];
            [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
        }
        [self totalWithNavLog];
        [NavLogTableView reloadData];
        return NO;
    }else if(textField == txtHeaderGPH) {
        BOOL valid = NO;
        NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
        for (int i = 0; i < [string length]; i++) {
            unichar c = [string characterAtIndex:i];
            if ([myCharSet characterIsMember:c]) {
                valid = YES;
            }
        }
        
        if (!valid && range.length != 1){
            return NO;
        }
        NSCharacterSet *cs = [myCharSet invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
        if ([string isEqualToString:@"."] && range.length<1 && [textField.text containsString:@"."]) {
            finalString=[finalString substringToIndex:[finalString length]-1];
        }
        textField.text = finalString;
        for (int i = 0; i < navLogRecordArray.count; i ++) {
            NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
            float gpuValue = [[dictToUpdate objectForKey:@"distLeg"] floatValue] / [[dictToUpdate objectForKey:@"Est"] floatValue] * [text floatValue];
            if (!isnan(gpuValue)) {
                [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gpuValue uptoDecimal:1]] forKey:@"Gph"];
                
                float gphRem = 0;
                if (i == 0) {
                    gphRem = [txtHeaderFuel.text floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
                }else {
                    NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
                    gphRem = [[preDict objectForKey:@"GphRem"] floatValue] - [[dictToUpdate objectForKey:@"Gph"] floatValue];
                }
                [dictToUpdate setValue:[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]] forKey:@"GphRem"];
                [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
            }
        }
        
        
        [self totalWithNavLog];
        [NavLogTableView reloadData];
        return NO;
    }
    
    [self totalWithNavLog];
    [NavLogTableView reloadData];
    return YES;
}

#pragma mark UITextviewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    isChanged = YES;
    return YES;
}

- (double)getRoundedForValue:(double)value uptoDecimal:(int)decimalPlaces{
    int divisor = pow(10, decimalPlaces);
    NSLog(@"%.02f",roundf(value * divisor) / divisor);
    return roundf(value * divisor) / divisor;
}
- (void) displayContentController: (UIViewController*) content;
{
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:content.view];
    [[AppDelegate sharedDelegate].window.rootViewController addChildViewController:content];
    [content didMoveToParentViewController:[AppDelegate sharedDelegate].window.rootViewController];
}
- (void)removeContentcontroller:(UIViewController *)content{
    
    isOpenPicker = NO;
    [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:content.view];
    [content willMoveToParentViewController:nil];  // 1
    [content.view removeFromSuperview];            // 2
    [content removeFromParentViewController];
}
- (IBAction)onAddWayPoint:(id)sender {
    
    [self addOneRowInCurrentNavLog];
}

- (IBAction)onGetDateNavLog:(id)sender {
    if (isOpenPicker) {
        return;
    }
    isOpenPicker = YES;
    [self.view endEditing:YES];
    DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
    [dateView.view setFrame:self.view.bounds];
    dateView.delegate = self;
    dateView.type = 5;
    dateView.pickerTitle = @"NavLog Date";
    [self displayContentController:dateView];
    [dateView animateShow];
}
#pragma mark DateViewControllerDelegate
- (void)didCancelDateView:(DateViewController *)dateView{
    [self removeContentcontroller:dateView];

}
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    
    isChanged = YES;
    txtDate.text = _strDate;
    [self removeContentcontroller:dateView];
}

- (IBAction)onGetTimeOff:(id)sender {
    if (isOpenPicker) {
        return;
    }
    isOpenPicker = YES;
    [self.view endEditing:YES];
    TimeViewController *timeVc = [[TimeViewController alloc] initWithNibName:@"TimeViewController" bundle:nil];
    [timeVc.view setFrame:self.view.bounds];
    timeVc.delegate = self;
    timeVc.pickerTitle = @"TimeOff";
    [self displayContentController:timeVc];
    [timeVc animateShow];
}

#pragma mark TimeViewControllerDelegate
-(void)returnValueFromTimeView:(TimeViewController *)timeView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    
    isChanged = YES;
    txtHeaderTimeOff.text = _strDate;
    [self removeContentcontroller:timeView];
    for (int i = 0; i < navLogRecordArray.count; i ++) {
        NSMutableDictionary *dictToUpdate = [navLogRecordArray objectAtIndex:i];
        NSString *timOffToChanged = @"";
        if (i == 0) {
            NSInteger mins = [[dictToUpdate objectForKey:@"TimeOff"] integerValue];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm"];
            NSDate *preTimeOff = [dateFormatter dateFromString:txtHeaderTimeOff.text];
            
            NSTimeInterval secondsInMins = mins * 60;
            NSDate *dateToCalcuated = [preTimeOff dateByAddingTimeInterval:secondsInMins];
            
            timOffToChanged = [dateFormatter stringFromDate:dateToCalcuated];
            
        }else {
            NSMutableDictionary *preDict = [navLogRecordArray objectAtIndex:i-1];
            NSInteger mins = [[dictToUpdate objectForKey:@"TimeOff"] integerValue];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm"];
            NSDate *preTimeOff = [dateFormatter dateFromString:[preDict objectForKey:@"Fuel"]];
            
            NSTimeInterval secondsInMins = mins * 60;
            NSDate *dateToCalcuated = [preTimeOff dateByAddingTimeInterval:secondsInMins];
            
            timOffToChanged = [dateFormatter stringFromDate:dateToCalcuated];
        }
        [dictToUpdate setValue:timOffToChanged forKey:@"Fuel"];
        [navLogRecordArray replaceObjectAtIndex:i withObject:dictToUpdate];
    }
    [self totalWithNavLog];
    [NavLogTableView reloadData];
}
- (void)didCancelTimeView:(TimeViewController *)timeView{
    [self removeContentcontroller:timeView];
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
- (IBAction)onSave:(id)sender {
    [self.view endEditing:YES];
    if (!txtNovlogName.text.length)
    {
        [self showAlert:@"Please input Navlog Name" :@"Input Error"];
        return;
    }
    if (!txtAirCraft.text.length)
    {
        [self showAlert:@"Please input Aircraft Number" :@"Input Error"];
        return;
    }
    if (!txtDate.text.length)
    {
        [self showAlert:@"Please set Date" :@"Input Error"];
        return;
    }
    
    if (isSaving) {
        return;
    }
    isSaving = YES;
    if (currentSelectedNavLog) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save changes to current file" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            NSError *error;
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
            [request setEntity:entityDescription];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogName == %@ && navLogLocalID != %@", txtNovlogName.text, currentSelectedNavLog.navLogLocalID];
            [request setPredicate:predicate];
            NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
            if (fetchedNavLogs.count > 0) {
                [self showAlert:[NSString stringWithFormat:@"%@ already exists, Check NavLog Name and try again.", txtNovlogName.text] :@"FlightDesk"];
                isSaving = NO;
                return ;
            }
            [self updateCurrentNavLogOnLocal];
            [self showAlert:@"Updated!" :@"FlightDesk"];
            isChanged = NO;
        }];
        UIAlertAction *reUse = [UIAlertAction actionWithTitle:@"Save as new file" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            if ([txtNovlogName.text isEqualToString:currentSelectedNavLog.navLogName]) {
                [self showAlert:[NSString stringWithFormat:@"%@ already exists, Check NavLog Name and try again.", txtNovlogName.text] :@"FlightDesk"];
                isSaving = NO;
                return ;
            }
            [AppDelegate sharedDelegate].selectedNavLogIndex = 0;
            [self saveNewNavLogOnLocal];
            isChanged = NO;
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
            
        }];
        [alert addAction:ok];
        if (currentSelectedNavLog) {
            [alert addAction:reUse];
        }
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
        
        
    }else{
        isChanged = NO;
        [self saveNewNavLogOnLocal];
    }
}
- (void)updateCurrentNavLogOnLocal{
    NSError *error;
    currentSelectedNavLog.navLogName = txtNovlogName.text;
    currentSelectedNavLog.aircraftNum = txtAirCraft.text;
    currentSelectedNavLog.navLogDate = txtDate.text;
    currentSelectedNavLog.notes = txtViewNotes.text;
    currentSelectedNavLog.casTasVal = txtHeaderCasTas.text;
    currentSelectedNavLog.distLeg = [NSNumber numberWithFloat:[txtHeaderDistRem.text floatValue]];
    currentSelectedNavLog.timeOff = txtHeaderTimeOff.text;
    currentSelectedNavLog.fuel = [NSNumber numberWithFloat:[txtHeaderFuel.text floatValue]];
    currentSelectedNavLog.gph = [NSNumber numberWithFloat:[txtHeaderGPH.text floatValue]];
    currentSelectedNavLog.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    currentSelectedNavLog.lastUpdate = @0;
    for (int i = 0; i < navLogRecordArray.count; i ++) {
        NSDictionary *onePreNav = [preNavLogArray objectAtIndex:i];
        NSDictionary *oneNavLogItems = [navLogRecordArray objectAtIndex:i];
        if ([[onePreNav objectForKey:@"ordering"] integerValue] <= currentSelectedNavLog.navLogRecords.count) {
            for (NavLogRecord *navLogRecordToUpdate in currentSelectedNavLog.navLogRecords) {
                if ([navLogRecordToUpdate.ordering integerValue] == [[onePreNav objectForKey:@"ordering"] integerValue]) {
                    navLogRecordToUpdate.checkPoint = [onePreNav objectForKey:@"checkPoint"];
                    navLogRecordToUpdate.vorIdent = [onePreNav objectForKey:@"vorIdent"];
                    navLogRecordToUpdate.vorFreq = [onePreNav objectForKey:@"vorFreq"];
                    navLogRecordToUpdate.vorTo = [onePreNav objectForKey:@"vorTo"];
                    navLogRecordToUpdate.vorFrom = [onePreNav objectForKey:@"vorFrom"];
                    
                    navLogRecordToUpdate.course = [oneNavLogItems objectForKey:@"course"];
                    navLogRecordToUpdate.attitude = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"Att"] integerValue]];
                    navLogRecordToUpdate.windDir = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindDir"] integerValue]];
                    navLogRecordToUpdate.windVel = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindVel"] integerValue]];
                    navLogRecordToUpdate.windTemp = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindTemp"] integerValue]];
                    navLogRecordToUpdate.casTas = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"CasTas"] integerValue]];
                    navLogRecordToUpdate.tc = [oneNavLogItems objectForKey:@"Tc"];
                    navLogRecordToUpdate.th = [oneNavLogItems objectForKey:@"Th"];
                    navLogRecordToUpdate.mh = [oneNavLogItems objectForKey:@"Mh"];
                    navLogRecordToUpdate.lrWca = [oneNavLogItems objectForKey:@"Wca"];
                    navLogRecordToUpdate.lwVar = [oneNavLogItems objectForKey:@"Var"];
                    navLogRecordToUpdate.dev = [oneNavLogItems objectForKey:@"Dev"];
                    navLogRecordToUpdate.ch = [oneNavLogItems objectForKey:@"CHAns"];
                    navLogRecordToUpdate.distLeg = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"distLeg"] floatValue]];
                    navLogRecordToUpdate.distRem = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"LegSum"] floatValue]];
                    navLogRecordToUpdate.gsEst = [oneNavLogItems objectForKey:@"Est"];
                    navLogRecordToUpdate.gsAct = [oneNavLogItems objectForKey:@"Act"];
                    navLogRecordToUpdate.timeOffETE = [oneNavLogItems objectForKey:@"TimeOff"];
                    navLogRecordToUpdate.timeOffATE = [oneNavLogItems objectForKey:@"TimeOffATE"];
                    navLogRecordToUpdate.fuelETA = [oneNavLogItems objectForKey:@"Fuel"];
                    navLogRecordToUpdate.fuelATA = [oneNavLogItems objectForKey:@"fuelATA"];
                    navLogRecordToUpdate.gphFuel = [oneNavLogItems objectForKey:@"Gph"];
                    navLogRecordToUpdate.gphRem = [oneNavLogItems objectForKey:@"GphRem"];
                    navLogRecordToUpdate.navLogID = currentSelectedNavLog.navLogLocalID;
                    navLogRecordToUpdate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    
                    break;
                }
            }
        }else{
            NavLogRecord *navLogRecordNew = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
            
            navLogRecordNew.checkPoint = [onePreNav objectForKey:@"checkPoint"];
            navLogRecordNew.vorIdent = [onePreNav objectForKey:@"vorIdent"];
            navLogRecordNew.vorFreq = [onePreNav objectForKey:@"vorFreq"];
            navLogRecordNew.vorTo = [onePreNav objectForKey:@"vorTo"];
            navLogRecordNew.vorFrom = [onePreNav objectForKey:@"vorFrom"];
            
            navLogRecordNew.course = [oneNavLogItems objectForKey:@"course"];
            navLogRecordNew.attitude = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"Att"] integerValue]];
            navLogRecordNew.windDir = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindDir"] integerValue]];
            navLogRecordNew.windVel = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindVel"] integerValue]];
            navLogRecordNew.windTemp = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindTemp"] integerValue]];
            navLogRecordNew.casTas = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"CasTas"] integerValue]];
            navLogRecordNew.tc = [oneNavLogItems objectForKey:@"Tc"];
            navLogRecordNew.th = [oneNavLogItems objectForKey:@"Th"];
            navLogRecordNew.mh = [oneNavLogItems objectForKey:@"Mh"];
            navLogRecordNew.lrWca = [oneNavLogItems objectForKey:@"Wca"];
            navLogRecordNew.lwVar = [oneNavLogItems objectForKey:@"Var"];
            navLogRecordNew.dev = [oneNavLogItems objectForKey:@"Dev"];
            navLogRecordNew.ch = [oneNavLogItems objectForKey:@"CHAns"];
            navLogRecordNew.distLeg = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"distLeg"] floatValue]];
            navLogRecordNew.distRem = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"LegSum"] floatValue]];
            navLogRecordNew.gsEst = [oneNavLogItems objectForKey:@"Est"];
            navLogRecordNew.gsAct = [oneNavLogItems objectForKey:@"Act"];
            navLogRecordNew.timeOffETE = [oneNavLogItems objectForKey:@"TimeOff"];
            navLogRecordNew.timeOffATE = [oneNavLogItems objectForKey:@"TimeOffATE"];
            navLogRecordNew.fuelETA = [oneNavLogItems objectForKey:@"Fuel"];
            navLogRecordNew.fuelATA = [oneNavLogItems objectForKey:@"fuelATA"];
            navLogRecordNew.gphFuel = [oneNavLogItems objectForKey:@"Gph"];
            navLogRecordNew.gphRem = [oneNavLogItems objectForKey:@"GphRem"];
            navLogRecordNew.navLogID = currentSelectedNavLog.navLogLocalID;
            navLogRecordNew.navLogRecordID = @0;
            navLogRecordNew.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
            
            navLogRecordNew.ordering = @(i);
            
            [currentSelectedNavLog addNavLogRecordsObject:navLogRecordNew];
        }
    }
    
    //check last prenavlog
    NSDictionary *onePreNav = [preNavLogArray objectAtIndex:(preNavLogArray.count-1)];
    if ([[onePreNav objectForKey:@"ordering"] integerValue] <= currentSelectedNavLog.navLogRecords.count) {
        for (NavLogRecord *navLogRecordToUpdate in currentSelectedNavLog.navLogRecords) {
            if ([navLogRecordToUpdate.ordering integerValue] == [[onePreNav objectForKey:@"ordering"] integerValue]) {
                navLogRecordToUpdate.checkPoint = [onePreNav objectForKey:@"checkPoint"];
                navLogRecordToUpdate.vorIdent = [onePreNav objectForKey:@"vorIdent"];
                navLogRecordToUpdate.vorFreq = [onePreNav objectForKey:@"vorFreq"];
                navLogRecordToUpdate.vorTo = [onePreNav objectForKey:@"vorTo"];
                navLogRecordToUpdate.vorFrom = [onePreNav objectForKey:@"vorFrom"];
                
                navLogRecordToUpdate.course = @"";
                navLogRecordToUpdate.attitude = @0;
                navLogRecordToUpdate.windDir = @0;
                navLogRecordToUpdate.windVel = @0;
                navLogRecordToUpdate.windTemp = @0;
                navLogRecordToUpdate.casTas = @0;
                navLogRecordToUpdate.tc = @"";
                navLogRecordToUpdate.th = @"";
                navLogRecordToUpdate.mh = @"";
                navLogRecordToUpdate.lrWca = @"";
                navLogRecordToUpdate.lwVar = @"";
                navLogRecordToUpdate.dev = @"";
                navLogRecordToUpdate.ch = @"";
                navLogRecordToUpdate.distLeg = @0;
                navLogRecordToUpdate.distRem = @0;
                navLogRecordToUpdate.gsEst = @"";
                navLogRecordToUpdate.gsAct = @"";
                navLogRecordToUpdate.timeOffETE = @"";
                navLogRecordToUpdate.timeOffATE = @"";
                navLogRecordToUpdate.fuelETA = @"";
                navLogRecordToUpdate.fuelATA = @"";
                navLogRecordToUpdate.gphFuel = @"";
                navLogRecordToUpdate.gphRem = @"";
                navLogRecordToUpdate.navLogID = currentSelectedNavLog.navLogLocalID;
                navLogRecordToUpdate.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                
                break;
            }
        }
    }else{
        NavLogRecord *navLogRecordNew = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
        
        navLogRecordNew.checkPoint = [onePreNav objectForKey:@"checkPoint"];
        navLogRecordNew.vorIdent = [onePreNav objectForKey:@"vorIdent"];
        navLogRecordNew.vorFreq = [onePreNav objectForKey:@"vorFreq"];
        navLogRecordNew.vorTo = [onePreNav objectForKey:@"vorTo"];
        navLogRecordNew.vorFrom = [onePreNav objectForKey:@"vorFrom"];
        
        navLogRecordNew.course = @"";
        navLogRecordNew.attitude = @0;
        navLogRecordNew.windDir = @0;
        navLogRecordNew.windVel = @0;
        navLogRecordNew.windTemp = @0;
        navLogRecordNew.casTas = @0;
        navLogRecordNew.tc = @"";
        navLogRecordNew.th = @"";
        navLogRecordNew.mh = @"";
        navLogRecordNew.lrWca = @"";
        navLogRecordNew.lwVar = @"";
        navLogRecordNew.dev = @"";
        navLogRecordNew.ch = @"";
        navLogRecordNew.distLeg = @0;
        navLogRecordNew.distRem = @0;
        navLogRecordNew.gsEst = @"";
        navLogRecordNew.gsAct = @"";
        navLogRecordNew.timeOffETE = @"";
        navLogRecordNew.timeOffATE = @"";
        navLogRecordNew.fuelETA = @"";
        navLogRecordNew.fuelATA = @"";
        navLogRecordNew.gphFuel = @"";
        navLogRecordNew.gphRem = @"";
        navLogRecordNew.navLogID = currentSelectedNavLog.navLogLocalID;
        navLogRecordNew.navLogRecordID = @0;
        navLogRecordNew.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        
        navLogRecordNew.ordering = @(preNavLogArray.count-1);
        
        [currentSelectedNavLog addNavLogRecordsObject:navLogRecordNew];
    }
    
    isSaving = NO;
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    
    [self getNavLogsFromLocal];
}
- (void)saveNewNavLogOnLocal{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogName == %@", txtNovlogName.text];
    [request setPredicate:predicate];
    NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
    if (fetchedNavLogs.count > 0) {
        [self showAlert:[NSString stringWithFormat:@"%@ already exists, Check NavLog Name and try again.", txtNovlogName.text] :@"FlightDesk"];
        isSaving = NO;
        return ;
    }
    
    NavLog *navLog = [NSEntityDescription insertNewObjectForEntityForName:@"NavLog" inManagedObjectContext:context];
    navLog.navLogID = @0;
    navLog.navLogLocalID = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    navLog.navLogName = txtNovlogName.text;
    navLog.aircraftNum = txtAirCraft.text;
    navLog.navLogDate = txtDate.text;
    navLog.notes = txtViewNotes.text;
    navLog.casTasVal = txtHeaderCasTas.text;
    navLog.distLeg = [NSNumber numberWithFloat:[txtHeaderDistRem.text floatValue]];
    navLog.timeOff = txtHeaderTimeOff.text;
    navLog.fuel = [NSNumber numberWithFloat:[txtHeaderFuel.text floatValue]];
    navLog.gph = [NSNumber numberWithFloat:[txtHeaderGPH.text floatValue]];
    navLog.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    navLog.lastUpdate = @0;
    navLog.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    for (int i = 0; i < navLogRecordArray.count; i ++) {
        NavLogRecord *navLogRecord = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
        NSDictionary *onePreNav = [preNavLogArray objectAtIndex:i];
        
        navLogRecord.checkPoint = [onePreNav objectForKey:@"checkPoint"];
        navLogRecord.vorIdent = [onePreNav objectForKey:@"vorIdent"];
        navLogRecord.vorFreq = [onePreNav objectForKey:@"vorFreq"];
        navLogRecord.vorTo = [onePreNav objectForKey:@"vorTo"];
        navLogRecord.vorFrom = [onePreNav objectForKey:@"vorFrom"];
        
        NSDictionary *oneNavLogItems = [navLogRecordArray objectAtIndex:i];
        
        navLogRecord.course = [oneNavLogItems objectForKey:@"course"];
        navLogRecord.attitude = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"Att"] integerValue]];
        navLogRecord.windDir = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindDir"] integerValue]];
        navLogRecord.windVel = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindVel"] integerValue]];
        navLogRecord.windTemp = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"WindTemp"] integerValue]];
        navLogRecord.casTas = [NSNumber numberWithInteger:[[oneNavLogItems objectForKey:@"CasTas"] integerValue]];
        navLogRecord.tc = [oneNavLogItems objectForKey:@"Tc"];
        navLogRecord.th = [oneNavLogItems objectForKey:@"Th"];
        navLogRecord.mh = [oneNavLogItems objectForKey:@"Mh"];
        navLogRecord.lrWca = [oneNavLogItems objectForKey:@"Wca"];
        navLogRecord.lwVar = [oneNavLogItems objectForKey:@"Var"];
        navLogRecord.dev = [oneNavLogItems objectForKey:@"Dev"];
        navLogRecord.ch = [oneNavLogItems objectForKey:@"CHAns"];
        navLogRecord.distLeg = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"distLeg"] floatValue]];
        navLogRecord.distRem = [NSNumber numberWithFloat:[[oneNavLogItems objectForKey:@"LegSum"] floatValue]];
        navLogRecord.gsEst = [oneNavLogItems objectForKey:@"Est"];
        navLogRecord.gsAct = [oneNavLogItems objectForKey:@"Act"];
        navLogRecord.timeOffETE = [oneNavLogItems objectForKey:@"TimeOff"];
        navLogRecord.timeOffATE = [oneNavLogItems objectForKey:@"TimeOffATE"];
        navLogRecord.fuelETA = [oneNavLogItems objectForKey:@"Fuel"];
        navLogRecord.fuelATA = [oneNavLogItems objectForKey:@"fuelATA"];
        navLogRecord.gphFuel = [oneNavLogItems objectForKey:@"Gph"];
        navLogRecord.gphRem = [oneNavLogItems objectForKey:@"GphRem"];
        navLogRecord.navLogID = navLog.navLogLocalID;
        navLogRecord.navLogRecordID = @0;
        navLogRecord.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        
        navLogRecord.ordering = @(i);
        
        [navLog addNavLogRecordsObject:navLogRecord];
    }
    
    //save last prenavlog
    NavLogRecord *navLogRecord = [NSEntityDescription insertNewObjectForEntityForName:@"NavLogRecord" inManagedObjectContext:context];
    NSDictionary *onePreNav = [preNavLogArray objectAtIndex:(preNavLogArray.count -1)];
    
    navLogRecord.checkPoint = [onePreNav objectForKey:@"checkPoint"];
    navLogRecord.vorIdent = [onePreNav objectForKey:@"vorIdent"];
    navLogRecord.vorFreq = [onePreNav objectForKey:@"vorFreq"];
    navLogRecord.vorTo = [onePreNav objectForKey:@"vorTo"];
    navLogRecord.vorFrom = [onePreNav objectForKey:@"vorFrom"];
    
    navLogRecord.course = @"";
    navLogRecord.attitude = @0;
    navLogRecord.windDir = @0;
    navLogRecord.windVel = @0;
    navLogRecord.windTemp = @0;
    navLogRecord.casTas = @0;
    navLogRecord.tc = @"";
    navLogRecord.th = @"";
    navLogRecord.mh = @"";
    navLogRecord.lrWca = @"";
    navLogRecord.lwVar = @"";
    navLogRecord.dev = @"";
    navLogRecord.ch = @"";
    navLogRecord.distLeg = @0;
    navLogRecord.distRem = @0;
    navLogRecord.gsEst = @"";
    navLogRecord.gsAct = @"";
    navLogRecord.timeOffETE = @"";
    navLogRecord.timeOffATE = @"";
    navLogRecord.fuelETA = @"";
    navLogRecord.fuelATA = @"";
    navLogRecord.gphFuel = @"";
    navLogRecord.gphRem = @"";
    navLogRecord.navLogID = navLog.navLogLocalID;
    navLogRecord.navLogRecordID = @0;
    navLogRecord.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    
    navLogRecord.ordering = @(navLogRecordArray.count);
    
    [navLog addNavLogRecordsObject:navLogRecord];
    
    
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    
    isSaving = NO;
    [self showAlert:@"Saved!" :@"FlightDesk"];
    [self getNavLogsFromLocal];
}
- (IBAction)onClearNavLog:(id)sender {
    [self.view endEditing:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to clear Current NavLog?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        
        isChanged = NO;
        txtNovlogName.text = @"";
        txtAirCraft.text = @"";
        txtDate.text = @"";
        txtViewNotes.text = @"";
        txtHeaderGPH.text = @"";
        txtHeaderFuel.text = @"";
        txtHeaderDistRem.text = @"";
        txtHeaderCasTas.text = @"";
        txtHeaderTimeOff.text = @"";
        txtDistTotal.text = @"";
        txtGPHTotal.text = @"";
        txtTimeOffTotal.text = @"";
        
        if (savedNavLogsArray.count == 0) {
            
        }else{
            id elementToCheck = [savedNavLogsArray objectAtIndex:0];
            if ([elementToCheck isKindOfClass:[NSString class]]) {
                
            }else if ([elementToCheck isKindOfClass:[NavLog class]]){
                [savedNavLogsArray insertObject:@"Empty NavLog" atIndex:0];
            }
        }
        [AppDelegate sharedDelegate].selectedNavLogIndex = 0;
        [SavedFilesCollectionView reloadData];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        
    }];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onDelNavLog:(id)sender {
    if (currentSelectedNavLog == nil) {
        return;
    }
    [self.view endEditing:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete the current Navlog?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        NSError *error;
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogLocalID == %@", currentSelectedNavLog.navLogLocalID];
        [request setPredicate:predicate];
        NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
        if (fetchedNavLogs.count > 0) {
            for (NavLog *navLogToDelete in fetchedNavLogs) {
                if ([navLogToDelete.navLogID integerValue] != 0) {
                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                    deleteQuery.type = @"navlog";
                    deleteQuery.idToDelete = navLogToDelete.navLogID;
                    [context save:&error];
                }
                
                for (NavLogRecord *navLogRecordToDelete in navLogToDelete.navLogRecords) {
                    [context deleteObject:navLogRecordToDelete];
                }
                [context deleteObject:navLogToDelete];
            }
        }
        [context save:&error];
        if (error) {
            NSLog(@"Error when saving managed object context : %@", error);
        }
        
        if ([AppDelegate sharedDelegate].selectedNavLogIndex != 0 && [AppDelegate sharedDelegate].selectedNavLogIndex == savedNavLogsArray.count-1) {
            [AppDelegate sharedDelegate].selectedNavLogIndex = [AppDelegate sharedDelegate].selectedNavLogIndex - 1;
        }
        [self getNavLogsFromLocal];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        
    }];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)totalWithNavLog{
    NSDecimalNumber *distTotal = [NSDecimalNumber decimalNumberWithString:@"0"];
    NSInteger timeOffTotal = 0;
    float dfhTotal = 0;
    for (NSDictionary *dict in navLogRecordArray) {
        if ([dict objectForKey:@"distLeg"] && ![[[dict objectForKey:@"distLeg"] stringValue] isEqualToString:@""] && [[dict objectForKey:@"distLeg"] floatValue]>=0) {
            distTotal = [distTotal decimalNumberByAdding:[dict objectForKey:@"distLeg"]];
        }
        if ([dict objectForKey:@"TimeOff"] && ![[dict objectForKey:@"TimeOff"] isEqualToString:@""] && [[dict objectForKey:@"TimeOff"] integerValue]>=0) {
            timeOffTotal = timeOffTotal + [[dict objectForKey:@"TimeOff"] integerValue];
        }
        if ([dict objectForKey:@"Gph"] && ![[dict objectForKey:@"Gph"] isEqualToString:@""] && [[dict objectForKey:@"Gph"] floatValue]>=0) {
            dfhTotal = dfhTotal + [[dict objectForKey:@"Gph"] floatValue];
        }
    }
    txtDistTotal.text = [NSString stringWithFormat:@"%@", distTotal];
    NSInteger hours = 0;
    if (timeOffTotal > 60) {
        hours = (timeOffTotal / 60 ) % 60;
    }
    NSString *timeOffStr = @"";
    if (timeOffTotal < 10) {
        if (hours < 10) {
            timeOffStr = [NSString stringWithFormat:@"0%ld:0%ld", (long)hours, (long)timeOffTotal%60];
        }else{
            timeOffStr = [NSString stringWithFormat:@"%ld:0%ld", (long)hours, (long)timeOffTotal%60];
        }
    }else{
        if (hours < 10) {
            timeOffStr = [NSString stringWithFormat:@"0%ld:%ld", (long)hours, (long)timeOffTotal%60];
        }else{
            timeOffStr = [NSString stringWithFormat:@"%ld:%ld", (long)hours, (long)timeOffTotal%60];
        }
    }
    txtTimeOffTotal.text = timeOffStr;
    
    txtGPHTotal.text = [NSString stringWithFormat:@"%.01f", [self getRoundedForValue:dfhTotal uptoDecimal:1]];
}

- (void)onShareCurrentNavLog{
    NSString *currentPDFPath = [self createPDFfromUIView:self.view saveToDocumentsWithFileName:[NSString stringWithFormat:@"%@%ld.pdf", txtNovlogName.text, (long)[AppDelegate sharedDelegate].selectedNavLogIndex]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:[NSURL URLWithString:[[NSString stringWithFormat:@"file://%@", currentPDFPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], nil] applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeOpenInIBooks ];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    activityVC.popoverPresentationController.sourceView = self.view;
    activityVC.popoverPresentationController.sourceRect = btnShare.frame;
    UIPopoverController* _popover = [[UIPopoverController alloc] initWithContentViewController:activityVC];
    _popover.delegate = self;
    [self presentViewController:activityVC
                       animated:YES
                     completion:nil];
}
- (void)onPrintCurrentNavLog{
    NSString *currentPDFPath = [self createPDFfromUIView:self.view saveToDocumentsWithFileName:[NSString stringWithFormat:@"%@%ld.pdf", txtNovlogName.text, (long)[AppDelegate sharedDelegate].selectedNavLogIndex]];
    UIPrintInteractionController *pc = [UIPrintInteractionController
                                        sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.orientation = UIPrintInfoOrientationPortrait;
    printInfo.jobName =@"Report";
    
    pc.printInfo = printInfo;
    pc.showsPageRange = YES;
    pc.printingItem = [NSURL URLWithString:[[NSString stringWithFormat:@"file://%@", currentPDFPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    UIPrintInteractionCompletionHandler completionHandler =
    ^(UIPrintInteractionController *printController, BOOL completed,
      NSError *error) {
        if(!completed && error){
            NSLog(@"Print failed - domain: %@ error code %ld", error.domain,
                  (long)error.code);
        }
    };
    
    
    [pc presentFromRect:btnPrint.frame inView:self.view animated:YES completionHandler:completionHandler];
}
-(NSString *)createPDFfromUIView:(UIView*)aView saveToDocumentsWithFileName:(NSString*)aFilename
{
    //create view
    UIView *viewToConvertPDF = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width + 20, 160.0f + scrView.contentSize.height)];
    
    UILabel *headerLBL = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, self.view.frame.size.width, 30)];
    headerLBL.backgroundColor = [UIColor blackColor];
    headerLBL.textColor = [UIColor whiteColor];
    headerLBL.text = @"NAVIGATION LOG";
    headerLBL.textAlignment = NSTextAlignmentCenter;
    headerLBL.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    
    UILabel *navLogNameLBL = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, 280, 30)];
    navLogNameLBL.text = [NSString stringWithFormat:@"NavLog Name: %@", txtNovlogName.text];
    navLogNameLBL.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    
    UILabel *aircraftLBL = [[UILabel alloc] initWithFrame:CGRectMake(310, 55, 200, 30)];
    aircraftLBL.text = [NSString stringWithFormat:@"Aircraft: %@", txtAirCraft.text];
    aircraftLBL.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    
    UILabel *navLogDate = [[UILabel alloc] initWithFrame:CGRectMake(520, 55, 200, 30)];
    navLogDate.text = [NSString stringWithFormat:@"Date: %@", txtDate.text];
    navLogDate.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    
    UILabel *notesTitleLBL = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 50, 30)];
    notesTitleLBL.text = @"Notes:";
    notesTitleLBL.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    
    UITextView *notesTxtView = [[UITextView alloc] initWithFrame:CGRectMake(75, 90, self.view.frame.size.width - 95, 60)];
    notesTxtView.text = txtViewNotes.text;
    notesTxtView.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    
    UIImageView *imageViewScroll = [[UIImageView alloc] initWithFrame:CGRectMake(10, 160, self.view.frame.size.width, viewToConvertPDF.frame.size.height-160)];
    
    CGRect navlogScrRect = navLogSrollingView.frame;
    CGFloat orignalWidthOfNavLogScr = navlogScrRect.size.width;
    navlogScrRect.size.width = navLogSrollingView.contentSize.width;
    navLogSrollingView.frame = navlogScrRect;
    
    CGRect scrRect = scrView.frame;
    CGFloat orignalHeight = scrRect.size.height;
    CGFloat orignalWidth = scrRect.size.width;
    scrRect.size.height = scrView.contentSize.height;
    scrRect.size.width = preNavLogCoverView.frame.size.width + navlogScrRect.size.width;
    scrView.frame = scrRect;
    btnAddNewWayPoint.hidden = YES;
    
    UIGraphicsBeginImageContext(scrView.frame.size);
    [[scrView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [imageViewScroll setImage:screenshot];
    
    //return old height
    scrRect.size.height = orignalHeight;
    scrRect.size.width = orignalWidth;
    scrView.frame = scrRect;
    
    navlogScrRect.size.width = orignalWidthOfNavLogScr;
    navLogSrollingView.frame = navlogScrRect;
    btnAddNewWayPoint.hidden = NO;
    
    [viewToConvertPDF addSubview:headerLBL];
    [viewToConvertPDF addSubview:navLogNameLBL];
    [viewToConvertPDF addSubview:aircraftLBL];
    [viewToConvertPDF addSubview:navLogDate];
    [viewToConvertPDF addSubview:notesTitleLBL];
    [viewToConvertPDF addSubview:notesTxtView];
    [viewToConvertPDF addSubview:imageViewScroll];
    
    // Creates a mutable data object for updating with binary data, like a byte array
    NSMutableData *pdfData = [NSMutableData data];
    
    // Points the pdf converter to the mutable data object and to the UIView to be converted
    UIGraphicsBeginPDFContextToData(pdfData, viewToConvertPDF.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    
    
    // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData
    
    [viewToConvertPDF.layer renderInContext:pdfContext];
    
    // remove PDF rendering context
    UIGraphicsEndPDFContext();
    
    // Retrieves the document directories from the iOS device
    NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    
    NSString* documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent:aFilename];
    // instructs the mutable data object to write its context to a file on disk
    [pdfData writeToFile:documentDirectoryFilename atomically:YES];
    return documentDirectoryFilename;
}
- (IBAction)onBack:(id)sender {
    [self.view endEditing:YES];
    if (savedNavLogsArray.count > 0) {
        id navLogElement = [savedNavLogsArray objectAtIndex:0];
        if ([navLogElement isKindOfClass:[NSString class]] && [AppDelegate sharedDelegate].selectedNavLogIndex == 0) {
            if (isChanged == YES) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save the current Navlog?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    if (!txtNovlogName.text.length)
                    {
                        [self showAlert:@"Please input Navlog Name" :@"Input Error"];
                        return;
                    }
                    if (!txtAirCraft.text.length)
                    {
                        [self showAlert:@"Please input Aircraft Number" :@"Input Error"];
                        return;
                    }
                    if (!txtDate.text.length)
                    {
                        [self showAlert:@"Please set Date" :@"Input Error"];
                        return;
                    }
                    
                    [self saveNewNavLogOnLocal];
                    [self.navigationController popViewControllerAnimated:YES];
                    
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self.navigationController popViewControllerAnimated:YES];
            }
            
        }else{
            if (isChanged == YES) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save the current Navlog?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    NSError *error;
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"NavLog" inManagedObjectContext:context];
                    [request setEntity:entityDescription];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"navLogName == %@ && navLogLocalID != %@", txtNovlogName.text, currentSelectedNavLog.navLogLocalID];
                    [request setPredicate:predicate];
                    NSArray *fetchedNavLogs = [context executeFetchRequest:request error:&error];
                    if (fetchedNavLogs.count > 0) {
                        [self showAlert:[NSString stringWithFormat:@"%@ already exists, Check NavLog Name and try again.", txtNovlogName.text] :@"FlightDesk"];
                        return ;
                    }
                    [self updateCurrentNavLogOnLocal];
                    [self.navigationController popViewControllerAnimated:YES];
                    
                }];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                
                [alert addAction:cancel];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }else{
        if (isChanged == YES) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to save the current Navlog?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                if (!txtNovlogName.text.length)
                {
                    [self showAlert:@"Please input Navlog Name" :@"Input Error"];
                    return;
                }
                if (!txtAirCraft.text.length)
                {
                    [self showAlert:@"Please input Aircraft Number" :@"Input Error"];
                    return;
                }
                if (!txtDate.text.length)
                {
                    [self showAlert:@"Please setup Date" :@"Input Error"];
                    return;
                }
                
                [self saveNewNavLogOnLocal];
                [self.navigationController popViewControllerAnimated:YES];
                
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                [self.navigationController popViewControllerAnimated:YES];
            }];
            
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
        

    }
    
    
}

- (IBAction)onShare:(id)sender {
    [self onShareCurrentNavLog];
}

- (IBAction)onPrint:(id)sender {
    [self onPrintCurrentNavLog];
}
@end
