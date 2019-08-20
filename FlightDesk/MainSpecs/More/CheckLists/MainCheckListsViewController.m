//
//  MainCheckListsViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "MainCheckListsViewController.h"
#import "AddCheckListsViewController.h"

#import "CYLineLayout.h"
#import "CheckListsMainCell.h"

#import "CheckListContentCell.h"
#import "CheckListContentLabelCell.h"

#import "FlightDesk-Swift.h"

#import "WLColView.h"
#include <Quartzcore/Quartzcore.h>
#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define COLOR_STANDARD_CHECKLIST_BLUE_THEME RGBA(94, 156, 211, 1)
#define COLOR_STANDARD_CHECKLIST_GREEN_THEME RGBA(26, 175, 84, 1)
#define COLOR_STANDARD_CHECKLIST_SKY_THEME RGBA(30, 177, 237, 1)

#define COLOR_G1000_CHECKLIST_SKY_THEME RGBA(45, 255, 255, 1)
#define COLOR_G1000_CHECKLIST_RED_THEME RGBA(255, 126, 84, 1)
#define COLOR_G1000_CHECKLIST_GREEN_THEME RGBA(45, 255, 3, 1)
#define COLOR_G1000_CHECKLIST_ORANGE_THEME RGBA(255, 140, 0, 1)

#define FONT_STANDARD [UIFont fontWithName:@"Helvetica" size:17];
#define FONT_G1000 [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:18];
#define FONT_STANDARD_FOR_DROP [UIFont fontWithName:@"Helvetica" size:15];
#define FONT_G1000_FOR_DROP [UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:16];

@interface MainCheckListsViewController ()<UITableViewDelegate, UITableViewDataSource, MKDropdownMenuDelegate, MKDropdownMenuDataSource, CheckListContentCellDelegate, UIPopoverControllerDelegate, CheckListsMainCellDelegate, WLColViewDataSource,WLColViewDelegate, SWTableViewCellDelegate>
{
    NSManagedObjectContext *contextRecords;
    
    NSMutableArray *arrayCheckListCategories;
    NSMutableArray *arrayCheckListsGroups;
    NSMutableArray *arrayChecklists;
    
    NSMutableArray *checklistsHistories;
    
    NSString *currentSelectedCategory;
    NSString *currentSelectedGroup;
    NSString *currentSelectedCheckList;
    
    Checklists *currentCheckList;
    
    NSInteger currentFouceCategoryIndex;
    
    BOOL isStatusToDeleteCategories;
    
    NSInteger currentFouceGroupIndex;
    NSInteger currentFouceChecklistIndex;
    
    WLColView *categoryWlcolView;
    NSArray *typeArray;
    
    NSInteger currentFouceChecklistContentIndex;
    
    NSString *currentSelectedType;
    ChecklistsContent *currentChecklistContentToEdit;
    UIPopoverController *contentPickerPopoverToUpdate;
    
    NSTimer *highlightGoToNextTimer;
    BOOL isStatusTimer;
    BOOL stopTimerHighlight;
    
    BOOL isFullScreen;
    CGRect mainViewOldFrame;
    CGFloat oldTopPosition;
    CGFloat oldBottomPosition;
    BOOL isAllChecked;
}
//@property(nonatomic,strong)UICollectionView *collectionView;
@end

@implementation MainCheckListsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"CHECKLISTS";
    
    isAllChecked = NO;
    stopTimerHighlight = NO;
    isStatusTimer = NO;
    lblWarringConstrainsHeight.constant = 0.0f;
    currentFouceCategoryIndex = 0;
    isStatusToDeleteCategories = NO;
    currentSelectedGroup = @"";
    currentSelectedCheckList = @"";
    currentSelectedCategory = @"";
    currentFouceGroupIndex = 0;
    currentFouceChecklistIndex = 0;
    currentFouceChecklistContentIndex = 0;
    
    btnCancelDeleteMode.hidden = YES;
    lblStatus.hidden = YES;
    
    isFullScreen = NO;
    checklistsHistories = [[NSMutableArray alloc] init];
    typeArray = [[NSArray alloc] initWithObjects:@"W", @"N", @"C", @"P", nil];
    
    [btnNextCheckList setTitleColor:COLOR_G1000_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
    [nextBtnBackGroundView setBackgroundColor:[UIColor clearColor]];
    
    // add the "Add Lesson" button
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 40, 40)];
    [addButton addTarget:self action:@selector(addCheckLists) forControlEvents:UIControlEventTouchUpInside];
    [addButton setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    shareButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 5, 30, 30)];
    [shareButton addTarget:self action:@selector(shareCurrentCheckLists) forControlEvents:UIControlEventTouchUpInside];
    [shareButton setImage:[UIImage imageNamed:@"share_nav.png"] forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    UIView *containsViewOfAdd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [containsViewOfAdd addSubview:addButton];
    [containsViewOfAdd addSubview:shareButton];
    UIBarButtonItem *addBtnItem = [[UIBarButtonItem alloc] initWithCustomView:containsViewOfAdd];
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:addBtnItem];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    
    arrayCheckListCategories = [[NSMutableArray alloc] init];
    arrayCheckListsGroups = [[NSMutableArray alloc] init];
    arrayChecklists = [[NSMutableArray alloc] init];
    
    categoryWlcolView = [[WLColView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 130)];
    [self.view insertSubview:categoryWlcolView belowSubview:btnCancelDeleteMode];
    
    SideModel *sideModel = [[SideModel alloc] init];
    sideModel.cellSize = CGSizeMake(140, 100);
    sideModel.between = 30;
    sideModel.maxR = 0.2;
    sideModel.initOffSetX = CGRectGetWidth(categoryWlcolView.frame) / 2 - sideModel.cellSize.width / 2;
    categoryWlcolView.sideModel = sideModel;
    categoryWlcolView.dataSource = self;
    categoryWlcolView.delegate = self;
    [categoryWlcolView.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([CheckListsMainCell class]) bundle:nil] forCellWithReuseIdentifier:@"CheckListsMainItem"];
    
    ChecklistsContentsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //[categoryWlcolView.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([CheckListsMainCell class]) bundle:nil] forCellWithReuseIdentifier:@"CheckListsMainItem"];
    //[categoryWlcolView.collectionView setContentOffset:CGPointMake(0, 0)];
    
    
    groupsDropDownMenu.dataSource = self;
    groupsDropDownMenu.delegate = self;
    groupsDropDownMenu.componentTextAlignment =  NSTextAlignmentLeft;
    
    checkListsDropDownMenu.delegate = self;
    checkListsDropDownMenu.dataSource = self;
    checkListsDropDownMenu.componentTextAlignment =  NSTextAlignmentLeft;
    
    rCVDropDownToEdit.dataSource = self;
    rCVDropDownToEdit.delegate = self;
    
    otherCVDropDownToEdit.dataSource = self;
    otherCVDropDownToEdit.delegate = self;
    currentSelectedType = @"W";
    
    boardToChangeColor.layer.masksToBounds = YES;
    if ([styleChecklistSwitch isOn]) {
        [boardToChangeColor setBackgroundColor:[UIColor colorWithRed:32.0f/255.0f green:32.0f/255.0f blue:32.0f/255.0f alpha:1.0f]];
        [checklistCVToChangeColor setBackgroundColor:[UIColor blackColor]];
        [lblGroup setTextColor:[UIColor whiteColor]];
        [lblCheckList setTextColor:[UIColor whiteColor]];
        [lblStandard setTextColor:[UIColor whiteColor]];
        [lblG100 setTextColor:[UIColor whiteColor]];
        lblGroup.font = FONT_G1000;
        lblCheckList.font  = FONT_G1000;
        lblStatus.font = FONT_G1000;
        lblStandard.font = FONT_G1000;
        lblG100.font = FONT_G1000;
        btnNextCheckList.font = FONT_G1000;
        standardToolView.hidden = YES;
        boardToChangeColor.layer.cornerRadius = 0.0f;
        checklistCVToChangeColor.layer.borderWidth = 1.0f;
        boardToChangeColor.layer.borderWidth = 0.0f;
        seperatedLineView.hidden = NO;
        btnNextCheckList.layer.cornerRadius = 0.0f;
        groupsDropDownMenu.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        btnNextCheckList.layer.borderColor = [UIColor lightGrayColor].CGColor;
        checkListsDropDownMenu.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        groupsDropDownMenu.tintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        checkListsDropDownMenu.tintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        styleChecklistSwitch.thumbTintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        styleChecklistSwitch.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        styleChecklistSwitch.onTintColor = [UIColor blackColor];
        styleSwithCV.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        btnFullScreen.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        [btnFullScreen setTitleColor:COLOR_G1000_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        btnFullScreen.font = FONT_G1000;
    }else{
        [boardToChangeColor setBackgroundColor:[UIColor whiteColor]];
        [checklistCVToChangeColor setBackgroundColor:[UIColor whiteColor]];
        [lblGroup setTextColor:[UIColor blackColor]];
        [lblCheckList setTextColor:[UIColor blackColor]];
        [lblStandard setTextColor:[UIColor blackColor]];
        [lblG100 setTextColor:[UIColor blackColor]];
        standardToolView.hidden = NO;
        lblGroup.font = FONT_STANDARD;
        lblCheckList.font  = FONT_STANDARD;
        lblStatus.font = FONT_STANDARD;
        lblStandard.font = FONT_STANDARD;
        lblG100.font = FONT_STANDARD;
        btnNextCheckList.font = FONT_STANDARD;
        boardToChangeColor.layer.cornerRadius = 5.0f;
        boardToChangeColor.layer.borderColor = [UIColor grayColor].CGColor;
        boardToChangeColor.layer.borderWidth = 1.0f;
        checklistCVToChangeColor.layer.borderWidth = 0.0f;
        seperatedLineView.hidden = YES;
        btnNextCheckList.layer.cornerRadius = 5.0f;
        btnNextCheckList.layer.borderColor = COLOR_STANDARD_CHECKLIST_SKY_THEME.CGColor;
        groupsDropDownMenu.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        checkListsDropDownMenu.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        groupsDropDownMenu.tintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        checkListsDropDownMenu.tintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        styleChecklistSwitch.thumbTintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        styleChecklistSwitch.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        styleChecklistSwitch.onTintColor = [UIColor whiteColor];
        styleSwithCV.layer.borderColor = [UIColor clearColor].CGColor;
        btnFullScreen.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        [btnFullScreen setTitleColor:COLOR_STANDARD_CHECKLIST_BLUE_THEME forState:UIControlStateNormal];
        btnFullScreen.font = FONT_STANDARD;
    }
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToDelete:)];
    [categoryWlcolView.collectionView addGestureRecognizer:longPress];
    
    highlightGoToNextTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(hightlightGoToNextChecklist:) userInfo:nil repeats:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [AppDelegate sharedDelegate].checklist_VC = nil;
}
- (void)deviceOrientationDidChange{
    [self superClassDeviceOrientationDidChange];
    if (isFullScreen) {
        boardTopPositionCons.constant = 0;
    }
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
    
    [categoryWlcolView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 130.0f)];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self deviceOrientationDidChange];
    [self getCheckListsCategory];
    if (isFullScreen && categoryWlcolView.hidden == YES) {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"MainChecklistViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveCurrentStatus];
    [groupsDropDownMenu closeAllComponentsAnimated:YES];
    [checkListsDropDownMenu closeAllComponentsAnimated:YES];
    [rCVDropDownToEdit closeAllComponentsAnimated:YES];
    [otherCVDropDownToEdit closeAllComponentsAnimated:YES];
    [highlightGoToNextTimer invalidate];
    highlightGoToNextTimer = nil;
    
    if (isFullScreen) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}
- (void)saveCurrentStatus{
    [[NSUserDefaults standardUserDefaults] setObject:checklistsHistories forKey:@"checklistHistories"];
    [[NSUserDefaults standardUserDefaults] setObject:@(currentFouceCategoryIndex) forKey:@"selectedCategory"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSavedChecklist"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)longPressToDelete:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        btnCancelDeleteMode.hidden = NO;
        isStatusToDeleteCategories = YES;
        [categoryWlcolView.collectionView reloadData];
    }
}
- (void)getCheckListsCategory{
    [arrayCheckListCategories removeAllObjects];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"checklistsID = %@", checklistID];
//    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Checklists!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid checklists found!");
    } else {
        NSMutableArray *tempChecklists = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"checklistsLocalId" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedChecklists = [tempChecklists sortedArrayUsingDescriptors:sortDescriptors];

        
        for (Checklists *checklists in sortedChecklists) {
            if (![arrayCheckListCategories containsObject:checklists.category]) {
                [arrayCheckListCategories addObject:checklists.category];
            }
        }
    }
    
    for (NSString *fouceCategory in arrayCheckListCategories) {
        NSMutableDictionary *onechecklistHistory = [[NSMutableDictionary alloc] init];
        [onechecklistHistory setObject:@0 forKey:@"content"];
        [onechecklistHistory setObject:@0 forKey:@"checklist"];
        [onechecklistHistory setObject:@0 forKey:@"group"];
        [checklistsHistories addObject:onechecklistHistory];
    }
    
    if (arrayCheckListCategories.count > 0) {
        currentFouceCategoryIndex = 0;
        currentSelectedCategory = [arrayCheckListCategories objectAtIndex:0];
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"isSavedChecklist"] boolValue]) {
            currentFouceCategoryIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedCategory"] integerValue];
            currentSelectedCategory = [arrayCheckListCategories objectAtIndex:currentFouceCategoryIndex];
            checklistsHistories = [[[NSUserDefaults standardUserDefaults] objectForKey:@"checklistHistories"] mutableCopy];
            if (checklistsHistories.count < arrayCheckListCategories.count) {
                for (int i = checklistsHistories.count; i < arrayCheckListCategories.count; i++) {
                    NSMutableDictionary *onechecklistHistory = [[NSMutableDictionary alloc] init];
                    [onechecklistHistory setObject:@0 forKey:@"content"];
                    [onechecklistHistory setObject:@0 forKey:@"checklist"];
                    [onechecklistHistory setObject:@0 forKey:@"group"];
                    [checklistsHistories addObject:onechecklistHistory];
                }
            }
        }
        [self getCheckListGroupsWithCategory:[arrayCheckListCategories objectAtIndex:currentFouceCategoryIndex]];
    }else{
        currentSelectedCheckList = @"";
        currentSelectedGroup = @"";
        currentCheckList = nil;
        btnCancelDeleteMode.hidden = YES;
        
        [groupsDropDownMenu reloadAllComponents];
        [checkListsDropDownMenu reloadAllComponents];
        [ChecklistsContentsTableView reloadData];
    }
    [categoryWlcolView.collectionView reloadData];
}
- (void)getCheckListGroupsWithCategory:(NSString *)category{
    [arrayCheckListsGroups removeAllObjects];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", category];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Checklists!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid checklists found!");
    } else {
        NSMutableArray *tempChecklists = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"checklistsLocalId" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedChecklists = [tempChecklists sortedArrayUsingDescriptors:sortDescriptors];
        for (Checklists *checklists in sortedChecklists) {
            if (![arrayCheckListsGroups containsObject:checklists.groupChecklist]) {
                [arrayCheckListsGroups addObject:checklists.groupChecklist];
            }
        }
    }
    if (arrayCheckListsGroups.count > 0) {
        currentFouceGroupIndex = 0;
        currentSelectedGroup = [arrayCheckListsGroups objectAtIndex:0];
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"isSavedChecklist"] boolValue]) {
            NSMutableDictionary *currentChecklistHistoryDic = [checklistsHistories objectAtIndex:currentFouceCategoryIndex];
            currentFouceGroupIndex = [[currentChecklistHistoryDic objectForKey:@"group"] integerValue];
            currentSelectedGroup = [arrayCheckListsGroups objectAtIndex:currentFouceGroupIndex];
        }
        
        [groupsDropDownMenu closeAllComponentsAnimated:YES];
        [groupsDropDownMenu reloadAllComponents];
        
        [self getCheckListsWithGroup:[arrayCheckListsGroups objectAtIndex:currentFouceGroupIndex]];
    }
}
- (void)getCheckListsWithGroup:(NSString *)gropuCheckList{
    [arrayChecklists removeAllObjects];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@ AND groupChecklist = %@", currentSelectedCategory, gropuCheckList];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Checklists!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid checklists found!");
    } else {
        NSMutableArray *tempChecklists = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"checklistsLocalId" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedChecklists = [tempChecklists sortedArrayUsingDescriptors:sortDescriptors];
        for (Checklists *checklists in sortedChecklists) {
            if (![checklists.checklist isEqualToString:@""]) {
                [arrayChecklists addObject:checklists];
            }
        }
    }
    currentFouceChecklistIndex = 0;
    currentSelectedCheckList = ((Checklists *)[arrayChecklists objectAtIndex:0]).checklist;
    currentCheckList =[arrayChecklists objectAtIndex:0];
    currentFouceChecklistContentIndex = 0;
    
    lblWaring.text = currentCheckList.warning;
    if ([currentCheckList.warning isEqualToString:@""]) {
        lblWarringConstrainsHeight.constant = 0.0f;
    }else{
        lblWarringConstrainsHeight.constant = [self getLabelHeight:lblWaring] + 30.0f;
    }
    
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"isSavedChecklist"] boolValue]) {
        NSMutableDictionary *currentChecklistHistoryDic = [checklistsHistories objectAtIndex:currentFouceCategoryIndex];
        currentFouceChecklistIndex = [[currentChecklistHistoryDic objectForKey:@"checklist"] integerValue];
        currentSelectedCheckList = ((Checklists *)[arrayChecklists objectAtIndex:currentFouceChecklistIndex]).checklist;
        currentCheckList =[arrayChecklists objectAtIndex:currentFouceChecklistIndex];
        currentFouceChecklistContentIndex = [[currentChecklistHistoryDic objectForKey:@"content"] integerValue];;
    }
    
    [checkListsDropDownMenu closeAllComponentsAnimated:YES];
    [checkListsDropDownMenu reloadAllComponents];
    
    [ChecklistsContentsTableView reloadData];
    if (currentCheckList.checklists.count > 0) {
        [ChecklistsContentsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition: UITableViewScrollPositionMiddle];
        [ChecklistsContentsTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
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
- (CGFloat)widthOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

- (void)hightlightGoToNextChecklist:(NSTimer *)timer
{
    if (stopTimerHighlight == YES) {
        [highlightGoToNextTimer invalidate];
        stopTimerHighlight = nil;
    }
    
    if (!isStatusTimer){
        isStatusTimer = YES;
        nextBtnBackGroundView.hidden = NO;
        [btnNextCheckList setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }else{
        isStatusTimer = NO;
        nextBtnBackGroundView.hidden = YES;
        if ([styleChecklistSwitch isOn]) {
            [btnNextCheckList setTitleColor:COLOR_G1000_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        }else{
            [btnNextCheckList setTitleColor:COLOR_STANDARD_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        }
    }
}
- (void)renunciationNextColor{
}
- (void)addCheckLists{
    AddCheckListsViewController *mainCheckListVC = [[AddCheckListsViewController alloc] init];
    [self.navigationController pushViewController:mainCheckListVC animated:YES];
}
- (void)shareCurrentCheckLists{
    if (arrayCheckListCategories.count) {
        NSString *currentPDFPath = [self convertStringToFile];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:[NSURL URLWithString:[[NSString stringWithFormat:@"file://%@", currentPDFPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], nil] applicationActivities:nil];
        
        NSArray *excludeActivities = @[UIActivityTypeOpenInIBooks ];
        
        activityVC.excludedActivityTypes = excludeActivities;
        
        activityVC.popoverPresentationController.sourceView = shareButton;
        activityVC.popoverPresentationController.sourceRect = shareButton.frame;
        UIPopoverController* _popover = [[UIPopoverController alloc] initWithContentViewController:activityVC];
        _popover.delegate = self;
        [self presentViewController:activityVC
                           animated:YES
                         completion:nil];
    }
}
- (NSString *)convertStringToFile{
    NSString *fullChecklistsToSaveLocalAsFile = currentSelectedCategory;
    for (NSString *groupToSave in arrayCheckListsGroups) {
        fullChecklistsToSaveLocalAsFile = [NSString stringWithFormat:@"%@\n<0%@", fullChecklistsToSaveLocalAsFile, groupToSave];
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
        NSError *error;
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupChecklist = %@", groupToSave];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve Checklists!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid checklists found!");
        } else {
            NSMutableArray *tempChecklists = [NSMutableArray arrayWithArray:objects];
            // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"checklistsLocalId" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            NSArray *sortedChecklists = [tempChecklists sortedArrayUsingDescriptors:sortDescriptors];
            for (Checklists *checklistsToSave in sortedChecklists) {
                if (![checklistsToSave.checklist isEqualToString:@""]) {
                    fullChecklistsToSaveLocalAsFile = [NSString stringWithFormat:@"%@\n(0%@", fullChecklistsToSaveLocalAsFile, checklistsToSave.checklist];
                    for (ChecklistsContent *checklistContentToSave in checklistsToSave.checklists) {
                        NSString *contentType = checklistContentToSave.type;
                        NSString *preType = @"";
                        NSString *depth = @"0";
                        if (contentType.length > 1) {
                            preType = [contentType substringToIndex:1];
                            depth = [contentType substringFromIndex:1];
                        }else if (contentType.length == 1){
                            preType = [contentType substringToIndex:1];
                        }
                        if ([preType isEqualToString:@"r"]) {
                            fullChecklistsToSaveLocalAsFile = [NSString stringWithFormat:@"%@\n%@%@~%@", fullChecklistsToSaveLocalAsFile, checklistContentToSave.type, checklistContentToSave.content, checklistContentToSave.contentTail];
                        }else{
                            fullChecklistsToSaveLocalAsFile = [NSString stringWithFormat:@"%@\n%@%@", fullChecklistsToSaveLocalAsFile, checklistContentToSave.type, checklistContentToSave.content];
                        }
                    }
                }
            }
        }
    }
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents directory
    
    NSError *error;
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Checklist_%f.ace", [[NSDate date] timeIntervalSince1970] * 1000000]];
    BOOL succeed = [fullChecklistsToSaveLocalAsFile writeToFile:filePath
                              atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!succeed){
        // Handle error here
    }
    
    return filePath;
}
-(NSString *)createPDFfromUIView:(UIView*)aView saveToDocumentsWithFileName:(NSString*)aFilename
{
    //create view
    CGFloat heightCoverView = 0;
    for (ChecklistsContent *checklistsContent in currentCheckList.checklists) {
        NSString *contentType = checklistsContent.type;
        NSString *preType = @"";
        NSString *depth = @"0";
        if (contentType.length > 1) {
            preType = [contentType substringToIndex:1];
            depth = [contentType substringFromIndex:1];
        }else if (contentType.length == 1){
            preType = [contentType substringToIndex:1];
        }
        if ([preType isEqualToString:@"r"]) {
            heightCoverView = heightCoverView + 35.0f;
        }else{
            UILabel *lblToGetHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ChecklistsContentsTableView.frame.size.width, 50.0f)];
            lblToGetHeight.text = checklistsContent.content;
            heightCoverView = heightCoverView + [self getLabelHeight:lblToGetHeight] + 10.0f;
        }
    }
    
    UIView *viewToConvertPDF = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width+20, 180.0f + heightCoverView)];
    
    if ([styleChecklistSwitch isOn]) {
        [viewToConvertPDF setBackgroundColor:[UIColor blackColor]];
    }else{
        [viewToConvertPDF setBackgroundColor:[UIColor whiteColor]];
    }
    
    UILabel *headerLBL = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, self.view.frame.size.width, 30)];
    if ([styleChecklistSwitch isOn]) {
        headerLBL.backgroundColor = [UIColor whiteColor];
        headerLBL.textColor = [UIColor blackColor];
    }else{
        headerLBL.backgroundColor = [UIColor blackColor];
        headerLBL.textColor = [UIColor whiteColor];
    }
    headerLBL.text = @"CHECKLISTS";
    headerLBL.textAlignment = NSTextAlignmentCenter;
    
    UIFont *changeFont = FONT_STANDARD;
    if ([styleChecklistSwitch isOn]) {
        changeFont = FONT_G1000;
    }
    headerLBL.font = changeFont;
    
    UILabel *groupLBL = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, viewToConvertPDF.frame.size.width, 30)];
    groupLBL.text = [NSString stringWithFormat:@"Group %@", currentSelectedGroup];
    groupLBL.font = changeFont;
    groupLBL.textColor = COLOR_G1000_CHECKLIST_SKY_THEME;
    
    UILabel *checklistLBL = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, viewToConvertPDF.frame.size.width, 30)];
    checklistLBL.text = [NSString stringWithFormat:@"Checklist %@", currentSelectedCheckList];
    checklistLBL.font = changeFont;
    checklistLBL.textColor = COLOR_G1000_CHECKLIST_SKY_THEME;
    
    CGFloat positionY = 0;
    
    UILabel *warningLbl = [[UILabel alloc] initWithFrame:CGRectMake(40, 125, self.view.frame.size.width - 120, 30)];
    CGRect warningRect = CGRectMake(40, 125, self.view.frame.size.width - 120, 30);
    if ([lblWaring.text isEqualToString:@""]) {
        warningRect.size.height = 0;
    }else{
        warningRect.size.height = [self getLabelHeight:lblWaring] + 30.0f;
    }
    
    [warningLbl setFrame:warningRect];
    warningLbl.text = [NSString stringWithFormat:@"Date: %@", lblWaring.text];
    warningLbl.font = changeFont;
    warningLbl.textColor = COLOR_G1000_CHECKLIST_RED_THEME;
    positionY = 125.0f + warningRect.size.height + 20.0f;
    
    UIImageView *imageViewTableView = [[UIImageView alloc] initWithFrame:CGRectMake(10, positionY, self.view.frame.size.width, heightCoverView)];
    
    CGRect tableRect = ChecklistsContentsTableView.frame;
    CGFloat orignalHeight = tableRect.size.height;
    CGFloat orignalWidth = tableRect.size.width;
    
    tableRect.size.height = heightCoverView;
    ChecklistsContentsTableView.frame = tableRect;
    
    UIGraphicsBeginImageContext(ChecklistsContentsTableView.frame.size);
    [[ChecklistsContentsTableView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [imageViewTableView setImage:screenshot];
    
    //return old height
    tableRect.size.height = orignalHeight;
    tableRect.size.width = orignalWidth;
    ChecklistsContentsTableView.frame = tableRect;
    
    
    [viewToConvertPDF addSubview:headerLBL];
    [viewToConvertPDF addSubview:groupLBL];
    [viewToConvertPDF addSubview:checklistLBL];
    [viewToConvertPDF addSubview:warningLbl];
    [viewToConvertPDF addSubview:imageViewTableView];
    
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

#pragma mark - colViewDataSource

- (NSInteger)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [arrayCheckListCategories count];
}

- (CheckListsMainCell *)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentfier = @"CheckListsMainItem";
    CheckListsMainCell *cell = (CheckListsMainCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentfier forIndexPath:indexPath];
    
    cell.delegate = self;
    
    cell.lblChecklistCategory.text = [arrayCheckListCategories objectAtIndex:indexPath.row];
    cell.checklistCategoryTxtView.text = [arrayCheckListCategories objectAtIndex:indexPath.row];
    
    cell.categoryCV.layer.masksToBounds = YES;
    cell.lblChecklistCategory.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    cell.categoryCV.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
    cell.categoryCV.backgroundColor = [UIColor clearColor];
    if (currentFouceCategoryIndex == indexPath.row && !isStatusToDeleteCategories) {
        cell.lblChecklistCategory.textColor = [UIColor whiteColor];
        cell.categoryCV.backgroundColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    }
    if (isStatusToDeleteCategories) {
        cell.deleteView.hidden = NO;
    }else{
        cell.lblChecklistCategory.hidden = NO;
        cell.checklistCategoryTxtView.hidden = YES;
        cell.deleteView.hidden = YES;
        cell.editBtnCV.layer.borderColor = [UIColor colorWithRed:68.0f/255.0f green:68.0f/255.0f blue:68.0f/255.0f alpha:1.0f].CGColor;
        [cell.btnEdit setImage:[UIImage imageNamed:@"edit_checklist"] forState:UIControlStateNormal];
        [cell.btnDelete setImage:[UIImage imageNamed:@"del_checklist"] forState:UIControlStateNormal];
        cell.btnDelete.selected = NO;
    }
    
    return cell;
}

- (void)colView:(WLColView *)colView collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
//    if (isStatusToDeleteCategories) {
//        return;
//    }
//    [self.view endEditing:YES];
//    currentFouceCategoryIndex = indexPath.row;
//    currentSelectedCategory = [arrayCheckListCategories objectAtIndex:indexPath.row];
//    [self getCheckListGroupsWithCategory:[arrayCheckListCategories objectAtIndex:indexPath.row]];
//    [categoryWlcolView.collectionView reloadData];
}

- (void)colView:(WLColView *)colView didScrollToOtherCell:(NSIndexPath *)indexPath{
    if (isStatusToDeleteCategories) {
        return;
    }
    [self.view endEditing:YES];
    if (arrayCheckListCategories.count <= indexPath.row) {
        return;
    }
    currentFouceCategoryIndex = indexPath.row;
    currentSelectedCategory = [arrayCheckListCategories objectAtIndex:indexPath.row];
    [self getCheckListGroupsWithCategory:[arrayCheckListCategories objectAtIndex:indexPath.row]];
    [categoryWlcolView.collectionView reloadData];
    
    
    //[self getSavedChecklistStatus];
}

#pragma mark CheckListsMainCellDelegate
- (void)deleteCurrentCategory:(CheckListsMainCell *)_cell{
    NSIndexPath *indexPathTodelete = [categoryWlcolView.collectionView indexPathForCell:_cell];
    
    [self.view endEditing:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete Current Checklist?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        
        NSString *currentCategoryToDelete = [arrayCheckListCategories objectAtIndex:indexPathTodelete.row];
        
        [arrayCheckListCategories removeObjectAtIndex:indexPathTodelete.row];
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
        NSError *error;
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", currentCategoryToDelete];
        [request setPredicate:predicate];
        NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve Checklists!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid checklists found!");
        } else {
            for (Checklists *checklistsToDelete in objects) {
                if ([checklistsToDelete.checklistsID integerValue] != 0) {
                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:contextRecords];
                    deleteQuery.type = @"checklist";
                    deleteQuery.idToDelete = checklistsToDelete.checklistsID;
                    [contextRecords save:&error];
                }
                
                for (ChecklistsContent *checklistsContentToDelete in checklistsToDelete.checklists) {
                    [contextRecords deleteObject:checklistsContentToDelete];
                }
                [contextRecords deleteObject:checklistsToDelete];
            }
        }
        
        [contextRecords save:&error];
        
        [checklistsHistories removeObjectAtIndex:indexPathTodelete.row];
        if (currentFouceCategoryIndex == indexPathTodelete.row) {
            currentFouceCategoryIndex = 0;
        }
        isStatusToDeleteCategories = NO;
        [self saveCurrentStatus];
        [self getCheckListsCategory];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        
    }];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)updateCategory:(CheckListsMainCell *)_cell{
    NSIndexPath *indexPathToUpdate = [categoryWlcolView.collectionView indexPathForCell:_cell];
    NSString *oldCagtegory = [arrayCheckListCategories objectAtIndex:indexPathToUpdate.row];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", oldCagtegory];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Checklists!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid checklists found!");
    } else {
        for (Checklists *checklists in objects) {
            checklists.category = _cell.checklistCategoryTxtView.text;
            checklists.lastUpdate = @0;
            [contextRecords save:&error];
        }
    }
}
- (IBAction)onCancelDeleteMode:(id)sender {
    isStatusToDeleteCategories = NO;
    btnCancelDeleteMode.hidden = YES;
    [categoryWlcolView.collectionView reloadData];
}

- (IBAction)onChangedStyleChecklists:(id)sender {
    if ([styleChecklistSwitch isOn]) {
        [boardToChangeColor setBackgroundColor:[UIColor colorWithRed:32.0f/255.0f green:32.0f/255.0f blue:32.0f/255.0f alpha:1.0f]];
        [checklistCVToChangeColor setBackgroundColor:[UIColor blackColor]];
        [lblGroup setTextColor:[UIColor whiteColor]];
        [lblCheckList setTextColor:[UIColor whiteColor]];
        [lblStandard setTextColor:[UIColor whiteColor]];
        [lblG100 setTextColor:[UIColor whiteColor]];
        lblGroup.font = FONT_G1000;
        lblCheckList.font  = FONT_G1000;
        lblStatus.font = FONT_G1000;
        lblStandard.font = FONT_G1000;
        lblG100.font = FONT_G1000;
        btnNextCheckList.font = FONT_G1000;
        standardToolView.hidden = YES;
        boardToChangeColor.layer.cornerRadius = 0.0f;
        checklistCVToChangeColor.layer.borderWidth = 1.0f;
        boardToChangeColor.layer.borderWidth = 0.0f;
        seperatedLineView.hidden = NO;
        btnNextCheckList.layer.cornerRadius = 0.0f;
        groupsDropDownMenu.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        btnNextCheckList.layer.borderColor = [UIColor lightGrayColor].CGColor;
        checkListsDropDownMenu.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        groupsDropDownMenu.tintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        checkListsDropDownMenu.tintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        styleChecklistSwitch.thumbTintColor = COLOR_G1000_CHECKLIST_SKY_THEME;
        styleChecklistSwitch.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        styleChecklistSwitch.onTintColor = [UIColor blackColor];
        styleSwithCV.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        btnFullScreen.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
        [btnFullScreen setTitleColor:COLOR_G1000_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        btnFullScreen.font = FONT_G1000;
    }else{
        [boardToChangeColor setBackgroundColor:[UIColor whiteColor]];
        [checklistCVToChangeColor setBackgroundColor:[UIColor whiteColor]];
        [lblGroup setTextColor:[UIColor blackColor]];
        [lblCheckList setTextColor:[UIColor blackColor]];
        [lblStandard setTextColor:[UIColor blackColor]];
        [lblG100 setTextColor:[UIColor blackColor]];
        standardToolView.hidden = NO;
        lblGroup.font = FONT_STANDARD;
        lblCheckList.font  = FONT_STANDARD;
        lblStatus.font = FONT_STANDARD;
        lblStandard.font = FONT_STANDARD;
        lblG100.font = FONT_STANDARD;
        btnNextCheckList.font = FONT_STANDARD;
        boardToChangeColor.layer.cornerRadius = 5.0f;
        boardToChangeColor.layer.borderColor = [UIColor grayColor].CGColor;
        boardToChangeColor.layer.borderWidth = 1.0f;
        checklistCVToChangeColor.layer.borderWidth = 0.0f;
        seperatedLineView.hidden = YES;
        btnNextCheckList.layer.cornerRadius = 5.0f;
        btnNextCheckList.layer.borderColor = COLOR_STANDARD_CHECKLIST_SKY_THEME.CGColor;
        groupsDropDownMenu.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        checkListsDropDownMenu.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        groupsDropDownMenu.tintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        checkListsDropDownMenu.tintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        styleChecklistSwitch.thumbTintColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
        styleChecklistSwitch.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        styleChecklistSwitch.onTintColor = [UIColor whiteColor];
        styleSwithCV.layer.borderColor = [UIColor clearColor].CGColor;
        btnFullScreen.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
        [btnFullScreen setTitleColor:COLOR_STANDARD_CHECKLIST_BLUE_THEME forState:UIControlStateNormal];
        btnFullScreen.font = FONT_STANDARD;
    }
    [ChecklistsContentsTableView reloadData];
    [groupsDropDownMenu reloadAllComponents];
    [checkListsDropDownMenu reloadAllComponents];
}

- (IBAction)onGotoNextCheckLists:(id)sender {
    currentFouceChecklistIndex = currentFouceChecklistIndex + 1;
    if (arrayChecklists.count > currentFouceChecklistIndex) {
        currentSelectedCheckList = ((Checklists *)[arrayChecklists objectAtIndex:currentFouceChecklistIndex]).checklist;
        currentCheckList =[arrayChecklists objectAtIndex:currentFouceChecklistIndex];
        currentFouceChecklistContentIndex = 0;
        
        [checkListsDropDownMenu closeAllComponentsAnimated:YES];
        [checkListsDropDownMenu reloadAllComponents];
        
        [ChecklistsContentsTableView reloadData];
        if (currentCheckList.checklists.count > 0) {
            [ChecklistsContentsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition: UITableViewScrollPositionMiddle];
            [ChecklistsContentsTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
        }
    }else{
        currentFouceGroupIndex = currentFouceGroupIndex + 1;
        currentFouceChecklistIndex = 0;
        if (arrayCheckListsGroups.count > currentFouceGroupIndex) {
            currentSelectedGroup = [arrayCheckListsGroups objectAtIndex:currentFouceGroupIndex];
            
            [groupsDropDownMenu closeAllComponentsAnimated:YES];
            [groupsDropDownMenu reloadAllComponents];
            
            [self getCheckListsWithGroup:currentSelectedGroup];
        }
    }
    
    //shave current history
    NSMutableDictionary *currentCheckContentHistory = [[checklistsHistories objectAtIndex:currentFouceCategoryIndex] mutableCopy];
    [currentCheckContentHistory setObject:@(currentFouceChecklistContentIndex) forKey:@"content"];
    [currentCheckContentHistory setObject:@(currentFouceGroupIndex) forKey:@"group"];
    [currentCheckContentHistory setObject:@(currentFouceChecklistIndex) forKey:@"checklist"];
    [checklistsHistories removeObjectAtIndex:currentFouceCategoryIndex];
    [checklistsHistories insertObject:currentCheckContentHistory atIndex:currentFouceCategoryIndex];
    [self saveCurrentStatus];
}

- (IBAction)onExit:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to eixt on Current Checklist?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
        
    }];
    
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onClearAll:(id)sender {
    stopTimerHighlight = YES;
    for (Checklists *checklistToUnCheck in arrayChecklists) {
        [self unCheckMarkWithChecklist:checklistToUnCheck];
    }
    
    currentFouceChecklistIndex = 0;
    currentSelectedCheckList = ((Checklists *)[arrayChecklists objectAtIndex:0]).checklist;
    currentCheckList =[arrayChecklists objectAtIndex:0];
    currentFouceChecklistContentIndex = 0;
    
    [checkListsDropDownMenu closeAllComponentsAnimated:YES];
    [checkListsDropDownMenu reloadAllComponents];
    
    [ChecklistsContentsTableView reloadData];
    if (currentCheckList.checklists.count > 0) {
        [ChecklistsContentsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition: UITableViewScrollPositionMiddle];
        [ChecklistsContentsTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
    }
    
}

- (IBAction)onClear:(id)sender {
    stopTimerHighlight = YES;
    [self unCheckMarkWithChecklist:currentCheckList];
    currentFouceChecklistContentIndex = 0;
    [ChecklistsContentsTableView reloadData];
}
- (void)unCheckMarkWithChecklist:(Checklists *)checklist{
    for (int i = 0; i < checklist.checklists.count; i ++) {
        ChecklistsContent *checklistsContent = [checklist.checklists objectAtIndex:i];
        NSString *contentType = checklistsContent.type;
        NSString *preType = @"";
        NSString *depth = @"0";
        if (contentType.length > 1) {
            preType = [contentType substringToIndex:1];
            depth = [contentType substringFromIndex:1];
        }else if (contentType.length == 1){
            preType = [contentType substringToIndex:1];
        }
        if ([preType isEqualToString:@"r"]) {
            checklistsContent.isChecked = @0;
        }
    }
    NSError *error;
    [contextRecords save:&error];
}
- (IBAction)onEvergency:(id)sender {
    currentFouceGroupIndex = 0;
    currentSelectedGroup = [arrayCheckListsGroups objectAtIndex:0];
    
    [groupsDropDownMenu closeAllComponentsAnimated:YES];
    [groupsDropDownMenu reloadAllComponents];
    
    [self getCheckListsWithGroup:currentSelectedGroup];
}

- (IBAction)onCheckContent:(id)sender {
    NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:currentFouceChecklistContentIndex inSection:0];
    id selectedCell = [ChecklistsContentsTableView cellForRowAtIndexPath:currentIndexPath];
    if ([selectedCell isKindOfClass:[CheckListContentCell class]]) {
        CheckListContentCell *selectedCellToCheck = (CheckListContentCell *)selectedCell;
        
        ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:currentIndexPath.row];
        NSString *contentType = checklistsContent.type;
        NSString *preType = @"";
        NSString *depth = @"0";
        if (contentType.length > 1) {
            preType = [contentType substringToIndex:1];
            depth = [contentType substringFromIndex:1];
        }else if (contentType.length == 1){
            preType = [contentType substringToIndex:1];
        }
        if ([preType isEqualToString:@"r"]) {
            checklistsContent.isChecked = [NSNumber numberWithBool:@YES];
            
            NSError *error;
            [contextRecords save:&error];
            
            selectedCellToCheck.btnCheckListItem.selected = [checklistsContent.isChecked boolValue];
            UIColor *selectedColor;
            if ([styleChecklistSwitch isOn]) {
                selectedCellToCheck.btnCheckListItem.layer.cornerRadius = 0.0f;
                selectedCellToCheck.btnCheckWidthCons.constant = 16.0f;
                selectedCellToCheck.btnCheckHeightCons.constant = 16.0f;
                [selectedCellToCheck.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
                if (selectedCellToCheck.btnCheckListItem.selected) {
                    selectedColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                    [selectedCellToCheck.btnCheckListItem setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
                }else{
                    selectedColor = COLOR_G1000_CHECKLIST_SKY_THEME;
                    [selectedCellToCheck.btnCheckListItem setImage:nil forState:UIControlStateNormal];
                }
            }else{
                selectedCellToCheck.btnCheckListItem.layer.cornerRadius = 12.0f;
                selectedCellToCheck.btnCheckWidthCons.constant = 24.0f;
                selectedCellToCheck.btnCheckHeightCons.constant = 24.0f;
                [selectedCellToCheck.btnCheckListItem setImage:nil forState:UIControlStateNormal];
                if (selectedCellToCheck.btnCheckListItem.selected) {
                    [selectedCellToCheck.btnCheckListItem setBackgroundColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                    selectedColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME;
                }else{
                    [selectedCellToCheck.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
                    selectedColor = [UIColor blackColor];
                }
            }
            selectedCellToCheck.checkListContentLBL.textColor = selectedColor;
            selectedCellToCheck.lblBridge.textColor = selectedColor;
            selectedCellToCheck.lblCheckListContentValue.textColor = selectedColor;
            selectedCellToCheck.btnCheckListItem.layer.borderColor = selectedColor.CGColor;
            [self checkToBeCheckedAllContent];
        }
        
        if (currentCheckList.checklists.count > currentFouceChecklistContentIndex) {
            currentFouceChecklistContentIndex = currentFouceChecklistContentIndex + 1;
            [ChecklistsContentsTableView reloadData];
            if (currentCheckList.checklists.count > currentIndexPath.row) {
                [ChecklistsContentsTableView selectRowAtIndexPath:currentIndexPath animated:YES scrollPosition: UITableViewScrollPositionMiddle];
                [ChecklistsContentsTableView deselectRowAtIndexPath:currentIndexPath animated:NO];
            }
        }
    }else if ([selectedCell isKindOfClass:[CheckListContentLabelCell class]]) {
        if (currentCheckList.checklists.count > currentFouceChecklistContentIndex) {
            currentFouceChecklistContentIndex = currentFouceChecklistContentIndex + 1;
            [ChecklistsContentsTableView reloadData];
            if (currentCheckList.checklists.count > currentIndexPath.row) {
                [ChecklistsContentsTableView selectRowAtIndexPath:currentIndexPath animated:YES scrollPosition: UITableViewScrollPositionMiddle];
                [ChecklistsContentsTableView deselectRowAtIndexPath:currentIndexPath animated:NO];
            }
        }
    }
    
    if (currentCheckList.checklists.count == currentFouceChecklistContentIndex) {
        isAllChecked = YES;
    }else{
        isAllChecked = NO;
    }
}

- (IBAction)onRCVUpdate:(id)sender {
    if (currentChecklistContentToEdit != nil) {
        currentChecklistContentToEdit.type = [NSString stringWithFormat:@"%@%@", currentSelectedType.lowercaseString, rCVDeptTxtFieldToEdit.text];
        currentChecklistContentToEdit.content = rCVPreTxtFieldToEdit.text;
        currentChecklistContentToEdit.contentTail = rCVTailTxtViewToEdit.text;
        
        currentCheckList.lastUpdate = @0;
        NSError *error;
        [contextRecords save:&error];
        
        currentChecklistContentToEdit = nil;
        [ChecklistsContentsTableView reloadData];
    }
    
    
    [contentPickerPopoverToUpdate dismissPopoverAnimated:YES];
}

- (IBAction)onOtherCVUpdate:(id)sender {
    if (currentChecklistContentToEdit != nil) {
        currentChecklistContentToEdit.type = [NSString stringWithFormat:@"%@%@", currentSelectedType.lowercaseString, otherCVDeptTxtFieldToEdit.text];
        currentChecklistContentToEdit.content = otherCVTxtView.text;
        
        currentCheckList.lastUpdate = @0;
        NSError *error;
        [contextRecords save:&error];
        currentChecklistContentToEdit = nil;
        [ChecklistsContentsTableView reloadData];
    }
    
    
    [contentPickerPopoverToUpdate dismissPopoverAnimated:YES];
}

- (IBAction)onFullScreenMode:(id)sender {
    
    [groupsDropDownMenu closeAllComponentsAnimated:YES];
    [checkListsDropDownMenu closeAllComponentsAnimated:YES];
    
    if (isFullScreen) {
        isFullScreen = NO;
        [btnFullScreen setTitle:@"Full Screen" forState:UIControlStateNormal];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        boardTopPositionCons.constant = oldTopPosition;
        //boardBottomPostionCons.constant = oldBottomPosition;
        boardLeftPositionCons.constant = 5.0f;
        boardrightPositionCons.constant = 5.0f;
        categoryWlcolView .hidden = NO;
    }else{
        [btnFullScreen setTitle:@"Exit Full Screen" forState:UIControlStateNormal];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        isFullScreen = YES;
        mainViewOldFrame = boardToChangeColor.frame;
        oldTopPosition = boardTopPositionCons.constant;
        oldBottomPosition = boardBottomPostionCons.constant;
        boardTopPositionCons.constant = 0.0f;
        //boardBottomPostionCons.constant = 0;
        boardLeftPositionCons.constant = 0;
        boardrightPositionCons.constant = 0;
        categoryWlcolView.hidden = YES;
        
    }
    
//    [self setTabBarVisible:![self tabBarIsVisible] animated:YES completion:^(BOOL finished) {
//        NSLog(@"finished");
//    }];
}
// pass a param to describe the state change, an animated flag and a completion block matching UIView animations completion
- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    
    // bail if the current state matches the desired state
    if ([self tabBarIsVisible] == visible) return (completion)? completion(YES) : nil;
    
    // get a frame calculation ready
    CGRect frame = self.tabBarController.tabBar.frame;
    CGFloat height = frame.size.height;
    CGFloat offsetY = (visible)? -height : height;
    
    // zero duration means no animation
    CGFloat duration = (animated)? 0.3 : 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        self.tabBarController.tabBar.frame = CGRectOffset(frame, 0, offsetY);
    } completion:completion];
}

//Getter to know the current state
- (BOOL)tabBarIsVisible {
    return [AppDelegate sharedDelegate].rootViewControllerForTab.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame);
}

#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (currentCheckList == nil) {
        return 0;
    }
    return currentCheckList.checklists.count;
    //return arrayChecklistsContents.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:indexPath.row];
    NSString *contentType = checklistsContent.type;
    NSString *preType = @"";
    NSString *depth = @"0";
    if (contentType.length > 1) {
        preType = [contentType substringToIndex:1];
        depth = [contentType substringFromIndex:1];
    }else if (contentType.length == 1){
        preType = [contentType substringToIndex:1];
    }
    if ([preType isEqualToString:@"r"]) {
        return 35.0f;
    }else{
        UILabel *lblToGetHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ChecklistsContentsTableView.frame.size.width, 50.0f)];
        lblToGetHeight.text = checklistsContent.content;
        return [self getLabelHeight:lblToGetHeight] + 30.0f;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:indexPath.row];
    NSString *contentType = checklistsContent.type;
    NSString *preType = @"";
    NSString *depth = @"0";
    if (contentType.length > 1) {
        preType = [contentType substringToIndex:1];
        depth = [contentType substringFromIndex:1];
    }else if (contentType.length == 1){
        preType = [contentType substringToIndex:1];
    }
    
    if ([preType isEqualToString:@"r"]) {
        static NSString *simpleTableIdentifier = @"CheckListContentItem";
        CheckListContentCell *cell = (CheckListContentCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [CheckListContentCell sharedCell];
        }
        
        cell.backgroundColor = cell.contentView.backgroundColor;
        cell.delegate = self;
        //cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        
        cell.delegateToUpdate = self;
        
        cell.checkListContentLBL.text = checklistsContent.content;
        cell.lblCheckListContentValue.text = checklistsContent.contentTail;
        UIFont *lblFont = cell.checkListContentLBL.font;
        cell.contentLblConstraints.constant = [self widthOfString:checklistsContent.content withFont:lblFont] + 10.0f;
        cell.contentTailLblConstraints.constant = [self widthOfString:checklistsContent.contentTail withFont:lblFont] + 10.0f;
        cell.paddingLeftConstraints.constant = 10.0f + 10.0f * [depth integerValue];
        cell.btnCheckListItem.selected = [checklistsContent.isChecked boolValue];
        
        
        UIColor *selectedColor;
        if ([styleChecklistSwitch isOn]) {
            cell.btnCheckListItem.layer.cornerRadius = 0.0f;
            cell.btnCheckWidthCons.constant = 16.0f;
            cell.btnCheckHeightCons.constant = 16.0f;
            [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
            if (cell.btnCheckListItem.selected) {
                selectedColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                [cell.btnCheckListItem setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
            }else{
                selectedColor = COLOR_G1000_CHECKLIST_SKY_THEME;
                [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            }
        }else{
            cell.btnCheckListItem.layer.cornerRadius = 12.0f;
            cell.btnCheckWidthCons.constant = 24.0f;
            cell.btnCheckHeightCons.constant = 24.0f;
            [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            if (cell.btnCheckListItem.selected) {
                [cell.btnCheckListItem setBackgroundColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                selectedColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME;
            }else{
                [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
                selectedColor = [UIColor blackColor];
            }
        }
        cell.checkListContentLBL.textColor = selectedColor;
        cell.lblBridge.textColor = selectedColor;
        cell.lblCheckListContentValue.textColor = selectedColor;
        cell.btnCheckListItem.layer.borderColor = selectedColor.CGColor;
        UIFont *changeFont = FONT_STANDARD;
        if ([styleChecklistSwitch isOn]) {
            changeFont = FONT_G1000;
        }
        cell.checkListContentLBL.font = changeFont;
        cell.lblCheckListContentValue.font = changeFont;
        
        if (currentFouceChecklistContentIndex == indexPath.row) {
            cell.contentView.layer.borderColor = [UIColor darkGrayColor].CGColor;
            cell.contentView.layer.borderWidth = 1.0f;
            if (![styleChecklistSwitch isOn]) {
                if (!cell.btnCheckListItem.selected) {
                    cell.checkListContentLBL.textColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
                    cell.lblBridge.textColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
                    cell.lblCheckListContentValue.textColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
                    cell.btnCheckListItem.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
                }else{
                
                }
            }else{
                if (cell.btnCheckListItem.selected) {
                    cell.checkListContentLBL.textColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                    cell.lblBridge.textColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                    cell.lblCheckListContentValue.textColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                    cell.btnCheckListItem.layer.borderColor = [UIColor whiteColor].CGColor;
                }else{
                    cell.checkListContentLBL.textColor = [UIColor whiteColor];
                    cell.lblBridge.textColor = [UIColor whiteColor];
                    cell.lblCheckListContentValue.textColor = [UIColor whiteColor];
                    cell.btnCheckListItem.layer.borderColor = [UIColor whiteColor].CGColor;
                }
            }
        }else{
            cell.contentView.layer.borderColor = [UIColor clearColor].CGColor;
            cell.contentView.layer.borderWidth = 0.0f;
            
        }
        if ([styleChecklistSwitch isOn]) {
            cell.btnCheckListItem.layer.borderColor = [UIColor lightGrayColor].CGColor;
        }
        
        [self checkToBeCheckedAllContent];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }else{
        static NSString *simpleTableIdentifier = @"CheckListContentLabelItem";
        CheckListContentLabelCell *cell = (CheckListContentLabelCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [CheckListContentLabelCell sharedCell];
        }
        
        cell.backgroundColor = cell.contentView.backgroundColor;
        cell.delegate = self;
        //cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        
        if ([depth integerValue] == 0) {
            cell.paddingLeftLblConstraints.constant = 8.0f;
        }else{
            cell.paddingLeftLblConstraints.constant = 40.0f + [depth integerValue] * 10.0f;
        }
        UIFont *changeFont = FONT_STANDARD;
        if ([styleChecklistSwitch isOn]) {
            changeFont = FONT_G1000;
        }
        cell.lblContent.font = changeFont;
        
        if ([preType isEqualToString:@"n"]){
            cell.lblContent.textColor = COLOR_G1000_CHECKLIST_ORANGE_THEME;
        }else if ([preType isEqualToString:@"p"]){
            if ([styleChecklistSwitch isOn]) {
                cell.lblContent.textColor = [UIColor whiteColor];
            }else{
                cell.lblContent.textColor = [UIColor grayColor];
            }
        }else if ([preType isEqualToString:@"t"]){
            if ([styleChecklistSwitch isOn]) {
                cell.lblContent.textColor = [UIColor whiteColor];
            }else{
                cell.lblContent.textColor = [UIColor grayColor];
            }
            cell.lblContent.font = changeFont;
        }else if ([preType.lowercaseString isEqualToString:@"w"]){
            cell.lblContent.textColor = [UIColor redColor];
        }else{
            cell.lblContent.textColor = [UIColor darkGrayColor];
        }
        cell.lblContent.text = checklistsContent.content;
        if ([preType.lowercaseString isEqualToString:@"w"]){
            cell.lblContent.text = [NSString stringWithFormat:@"WARNING: %@", checklistsContent.content];
        }
        if (currentFouceChecklistContentIndex == indexPath.row) {
            
            if (![preType isEqualToString:@"n"] && ![preType isEqualToString:@"w"]){
                if (![styleChecklistSwitch isOn]) {
                    cell.lblContent.textColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
                }else{
                    cell.lblContent.textColor = [UIColor whiteColor];
                }
            }
            cell.contentView.layer.borderColor = [UIColor darkGrayColor].CGColor;
            cell.contentView.layer.borderWidth = 1.0f;
        }else{
            cell.contentView.layer.borderColor = [UIColor clearColor].CGColor;
            cell.contentView.layer.borderWidth = 0.0f;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self checkToBeCheckedAllContent];
        return cell;
    }
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    currentFouceChecklistContentIndex = indexPath.row;
    
    
    ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:indexPath.row];
    NSString *contentType = checklistsContent.type;
    NSString *preType = @"";
    NSString *depth = @"0";
    if (contentType.length > 1) {
        preType = [contentType substringToIndex:1];
        depth = [contentType substringFromIndex:1];
    }else if (contentType.length == 1){
        preType = [contentType substringToIndex:1];
    }
    if ([preType isEqualToString:@"r"]) {
        BOOL updatecheckedStatus = ![checklistsContent.isChecked boolValue];
        checklistsContent.isChecked = [NSNumber numberWithBool:updatecheckedStatus];
        
        NSError *error;
        [contextRecords save:&error];
        
        CheckListContentCell *cell = [ChecklistsContentsTableView cellForRowAtIndexPath:indexPath];
        cell.contentView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        cell.contentView.layer.borderWidth = 1.0f;
        
        cell.btnCheckListItem.selected = [checklistsContent.isChecked boolValue];
        UIColor *selectedColor;
        if ([styleChecklistSwitch isOn]) {
            cell.btnCheckListItem.layer.cornerRadius = 0.0f;
            cell.btnCheckWidthCons.constant = 16.0f;
            cell.btnCheckHeightCons.constant = 16.0f;
            [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
            if (cell.btnCheckListItem.selected) {
                selectedColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                [cell.btnCheckListItem setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
            }else{
                selectedColor = [UIColor whiteColor];
                [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            }
        }else{
            cell.btnCheckListItem.layer.cornerRadius = 12.0f;
            cell.btnCheckWidthCons.constant = 24.0f;
            cell.btnCheckHeightCons.constant = 24.0f;
            [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            if (cell.btnCheckListItem.selected) {
                [cell.btnCheckListItem setBackgroundColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                selectedColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME;
            }else{
                [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
                selectedColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
            }
        }
        cell.checkListContentLBL.textColor = selectedColor;
        cell.lblBridge.textColor = selectedColor;
        cell.lblCheckListContentValue.textColor = selectedColor;
        cell.btnCheckListItem.layer.borderColor = selectedColor.CGColor;
    }
    
    BOOL isUpdated = NO;
    for (int i = currentFouceChecklistContentIndex; i < currentCheckList.checklists.count; i ++) {
        ChecklistsContent *checklistsContentToCheck = [currentCheckList.checklists objectAtIndex:i];
        NSString *contentType = checklistsContentToCheck.type;
        NSString *preType = @"";
        NSString *depth = @"0";
        if (contentType.length > 1) {
            preType = [contentType substringToIndex:1];
            depth = [contentType substringFromIndex:1];
        }else if (contentType.length == 1){
            preType = [contentType substringToIndex:1];
        }
        if ([preType isEqualToString:@"r"]) {
            if (![checklistsContentToCheck.isChecked boolValue]) {
                currentFouceChecklistContentIndex = i;
                isUpdated = YES;
                break;
            }
        }
    }
    if (!isUpdated) {
        if (currentCheckList.checklists.count > currentFouceChecklistContentIndex) {
            currentFouceChecklistContentIndex = currentFouceChecklistContentIndex + 1;
        }
    }
    if (currentCheckList.checklists.count > currentFouceChecklistContentIndex) {
        [ChecklistsContentsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentFouceChecklistContentIndex inSection:0] animated:YES scrollPosition: UITableViewScrollPositionMiddle];
        [ChecklistsContentsTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:currentFouceChecklistContentIndex inSection:0] animated:NO];
    }
    if (currentCheckList.checklists.count == currentFouceChecklistContentIndex) {
        isAllChecked = YES;
    }else{
        isAllChecked = NO;
    }
    [ChecklistsContentsTableView reloadData];
    
    [self checkToBeCheckedAllContent];
    
    //shave current history
    NSMutableDictionary *currentCheckContentHistory = [[checklistsHistories objectAtIndex:currentFouceCategoryIndex] mutableCopy];
    [currentCheckContentHistory setObject:@(currentFouceChecklistContentIndex) forKey:@"content"];
    [currentCheckContentHistory setObject:@(currentFouceGroupIndex) forKey:@"group"];
    [currentCheckContentHistory setObject:@(currentFouceChecklistIndex) forKey:@"checklist"];
    [checklistsHistories removeObjectAtIndex:currentFouceCategoryIndex];
    [checklistsHistories insertObject:currentCheckContentHistory atIndex:currentFouceCategoryIndex];
    [self saveCurrentStatus];
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor greenColor] title:@"Edit"];
    
    return rightUtilityButtons;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *currentIndexPath = [ChecklistsContentsTableView indexPathForCell:cell];
            ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:currentIndexPath.row];
            currentChecklistContentToEdit = checklistsContent;
            NSString *contentType = checklistsContent.type;
            NSString *preType = @"";
            NSString *depth = @"0";
            if (contentType.length > 1) {
                preType = [contentType substringToIndex:1];
                depth = [contentType substringFromIndex:1];
            }else if (contentType.length == 1){
                preType = [contentType substringToIndex:1];
            }
            
            UIViewController* popoverContent = [[UIViewController alloc] init];
            UIView *popoverView = [[UIView alloc] init];   //view
            popoverView.backgroundColor = [UIColor clearColor];
            
            if ([preType isEqualToString:@"r"]) {
                [popoverView setFrame:rCoverViewToEdit.frame];
                [popoverView addSubview:rCoverViewToEdit];
                
                rCVDeptTxtFieldToEdit.text = depth;
                rCVPreTxtFieldToEdit.text = checklistsContent.content;
                rCVTailTxtViewToEdit.text = checklistsContent.contentTail;
                
                currentSelectedType = @"R";
                [rCVDropDownToEdit closeAllComponentsAnimated:YES];
                [rCVDropDownToEdit reloadAllComponents];
                
            }else{
                currentSelectedType = preType.uppercaseString;
                [rCVDropDownToEdit closeAllComponentsAnimated:YES];
                [rCVDropDownToEdit reloadAllComponents];
                [popoverView setFrame:otherCoverViewToEdit.frame];
                [popoverView addSubview:otherCoverViewToEdit];
                otherCVDeptTxtFieldToEdit.text = depth;
                otherCVTxtView.text = checklistsContent.content;
            }
            popoverContent.view = popoverView;
            contentPickerPopoverToUpdate = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
            contentPickerPopoverToUpdate.delegate = self;
            
            [contentPickerPopoverToUpdate setPopoverContentSize:CGSizeMake(popoverView.frame.size.width, popoverView.frame.size.height) animated:NO];
            [contentPickerPopoverToUpdate presentPopoverFromRect:[cell bounds] inView:cell permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
            break;
        }
        default:
            break;
    }
}

#pragma mark CheckListContentCellDelegate
- (void)didCheckedCheckListItem:(CheckListContentCell *)_cell withStatus:(BOOL)isChecked{
    NSIndexPath *indexPath = [ChecklistsContentsTableView indexPathForCell:_cell];
    currentFouceChecklistContentIndex = indexPath.row;
    
    ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:indexPath.row];
    NSString *contentType = checklistsContent.type;
    NSString *preType = @"";
    NSString *depth = @"0";
    if (contentType.length > 1) {
        preType = [contentType substringToIndex:1];
        depth = [contentType substringFromIndex:1];
    }else if (contentType.length == 1){
        preType = [contentType substringToIndex:1];
    }
    if ([preType isEqualToString:@"r"]) {
        BOOL updatecheckedStatus = ![checklistsContent.isChecked boolValue];
        checklistsContent.isChecked = [NSNumber numberWithBool:updatecheckedStatus];
        
        NSError *error;
        [contextRecords save:&error];
        
        CheckListContentCell *cell = [ChecklistsContentsTableView cellForRowAtIndexPath:indexPath];
        cell.contentView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        cell.contentView.layer.borderWidth = 1.0f;
        
        cell.btnCheckListItem.selected = [checklistsContent.isChecked boolValue];
        UIColor *selectedColor;
        if ([styleChecklistSwitch isOn]) {
            cell.btnCheckListItem.layer.cornerRadius = 0.0f;
            cell.btnCheckWidthCons.constant = 16.0f;
            cell.btnCheckHeightCons.constant = 16.0f;
            [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
            if (cell.btnCheckListItem.selected) {
                selectedColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
                [cell.btnCheckListItem setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
            }else{
                selectedColor = [UIColor whiteColor];
                [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            }
        }else{
            cell.btnCheckListItem.layer.cornerRadius = 12.0f;
            cell.btnCheckWidthCons.constant = 24.0f;
            cell.btnCheckHeightCons.constant = 24.0f;
            [cell.btnCheckListItem setImage:nil forState:UIControlStateNormal];
            if (cell.btnCheckListItem.selected) {
                [cell.btnCheckListItem setBackgroundColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                selectedColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME;
            }else{
                [cell.btnCheckListItem setBackgroundColor:[UIColor clearColor]];
                selectedColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME;
            }
        }
        cell.checkListContentLBL.textColor = selectedColor;
        cell.lblBridge.textColor = selectedColor;
        cell.lblCheckListContentValue.textColor = selectedColor;
        cell.btnCheckListItem.layer.borderColor = selectedColor.CGColor;
        
        [self checkToBeCheckedAllContent];
    }
    [ChecklistsContentsTableView reloadData];
    
    //shave current history
    NSMutableDictionary *currentCheckContentHistory = [[checklistsHistories objectAtIndex:currentFouceCategoryIndex] mutableCopy];
    [currentCheckContentHistory setObject:@(currentFouceChecklistContentIndex) forKey:@"content"];
    [currentCheckContentHistory setObject:@(currentFouceGroupIndex) forKey:@"group"];
    [currentCheckContentHistory setObject:@(currentFouceChecklistIndex) forKey:@"checklist"];
    [checklistsHistories removeObjectAtIndex:currentFouceCategoryIndex];
    [checklistsHistories insertObject:currentCheckContentHistory atIndex:currentFouceCategoryIndex];
    [self saveCurrentStatus];
}

- (void)checkToBeCheckedAllContent{
    
    BOOL isFinished = YES;
    NSInteger countR = 0;
    for (int i = 0; i < currentCheckList.checklists.count; i ++) {
        ChecklistsContent *checklistsContent = [currentCheckList.checklists objectAtIndex:i];
        NSString *contentType = checklistsContent.type;
        NSString *preType = @"";
        NSString *depth = @"0";
        if (contentType.length > 1) {
            preType = [contentType substringToIndex:1];
            depth = [contentType substringFromIndex:1];
        }else if (contentType.length == 1){
            preType = [contentType substringToIndex:1];
        }
        if ([preType isEqualToString:@"r"]) {
            countR = countR + 1;
            if ([checklistsContent.isChecked boolValue] == NO) {
                isFinished = NO;
            }
        }
    }
    if (isFinished && countR != 0 && isAllChecked) {
        lblStatus.hidden = NO;
        [btnNextCheckList setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if ([styleChecklistSwitch isOn]) {
            lblStatus.textColor = COLOR_G1000_CHECKLIST_GREEN_THEME;
            [nextBtnBackGroundView setBackgroundColor:COLOR_G1000_CHECKLIST_SKY_THEME];
            lblStatus.layer.shadowColor = COLOR_G1000_CHECKLIST_GREEN_THEME.CGColor;
            btnNextCheckList.layer.borderColor = [UIColor lightGrayColor].CGColor;
        }else{
            lblStatus.textColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME;
            [nextBtnBackGroundView setBackgroundColor:COLOR_STANDARD_CHECKLIST_SKY_THEME];
            lblStatus.layer.shadowColor = COLOR_STANDARD_CHECKLIST_GREEN_THEME.CGColor;
            btnNextCheckList.layer.borderColor = COLOR_STANDARD_CHECKLIST_SKY_THEME.CGColor;
        }
        
        lblStatus.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        lblStatus.layer.masksToBounds = NO;
        lblStatus.layer.shadowRadius = 1.0f;
        lblStatus.layer.shadowOpacity = 1.0f;
        if (highlightGoToNextTimer == nil) {
            highlightGoToNextTimer = [NSTimer scheduledTimerWithTimeInterval:0.4f target:self selector:@selector(hightlightGoToNextChecklist:) userInfo:nil repeats:YES];
        }
        stopTimerHighlight = NO;
    }else{
        [highlightGoToNextTimer invalidate];
        highlightGoToNextTimer = nil;
        stopTimerHighlight = YES;
        lblStatus.hidden = YES;
        lblStatus.textColor = [UIColor lightGrayColor];
        if ([styleChecklistSwitch isOn]) {
            [btnNextCheckList setTitleColor:COLOR_G1000_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        }else{
            [btnNextCheckList setTitleColor:COLOR_STANDARD_CHECKLIST_SKY_THEME forState:UIControlStateNormal];
        }
        [nextBtnBackGroundView setBackgroundColor:[UIColor clearColor]];
    }
}

#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    if (dropdownMenu == groupsDropDownMenu) {
        return arrayCheckListsGroups.count;
    }else if (dropdownMenu == checkListsDropDownMenu){
        return arrayChecklists.count;
    }else{
        return typeArray.count;
    }
}

#pragma mark - MKDropdownMenuDelegate

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
    if (dropdownMenu == groupsDropDownMenu) {
        return currentSelectedGroup;
    }else if (dropdownMenu == checkListsDropDownMenu) {
        return currentSelectedCheckList;
    }else{
        return currentSelectedType;
    }
    
    return @"";
}

//- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    if (dropdownMenu == groupsDropDownMenu) {
//        return [arrayCheckListsGroups objectAtIndex:row];
//    }else{
//        return ((Checklists *)[arrayChecklists objectAtIndex:row]).checklist;
//    }
//}
- (nullable NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForComponent:(NSInteger)component{
    UIFont *changeFont = FONT_STANDARD_FOR_DROP;
    if ([styleChecklistSwitch isOn]) {
        changeFont = FONT_G1000_FOR_DROP;
    }
    NSString *strSelected = @"";
    if (dropdownMenu == groupsDropDownMenu) {
        strSelected =  currentSelectedGroup;
    }else if (dropdownMenu == checkListsDropDownMenu) {
        strSelected =  currentSelectedCheckList;
    }else{
        
        NSAttributedString *attrFortype= [[NSAttributedString alloc] initWithString:currentSelectedType attributes:@{ NSFontAttributeName : changeFont}];
        return attrFortype;
    }
    UIColor *selectedColor;
    if ([styleChecklistSwitch isOn]) {
        selectedColor = COLOR_G1000_CHECKLIST_SKY_THEME;
    }else{
        selectedColor = [UIColor blackColor];
    }
    NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:strSelected attributes:@{ NSFontAttributeName : changeFont, NSForegroundColorAttributeName :selectedColor , NSBackgroundColorAttributeName : [UIColor clearColor]}];
    return attrForTextField;
}
- (nullable NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForSelectedComponent:(NSInteger)componen{
    UIFont *changeFont = FONT_STANDARD_FOR_DROP;
    if ([styleChecklistSwitch isOn]) {
        changeFont = FONT_G1000_FOR_DROP;
    }
    NSString *strSelected = @"";
    if (dropdownMenu == groupsDropDownMenu) {
        strSelected =  currentSelectedGroup;
    }else if (dropdownMenu == checkListsDropDownMenu) {
        strSelected =  currentSelectedCheckList;
    }else{
        NSAttributedString *attrFortype= [[NSAttributedString alloc] initWithString:currentSelectedType attributes:@{ NSFontAttributeName : changeFont}];
        return attrFortype;
    }
    UIColor *selectedColor;
    if ([styleChecklistSwitch isOn]) {
        selectedColor = COLOR_G1000_CHECKLIST_SKY_THEME;
    }else{
        selectedColor = [UIColor blackColor];
    }
    NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:strSelected attributes:@{ NSFontAttributeName : changeFont , NSForegroundColorAttributeName :selectedColor, NSBackgroundColorAttributeName : [UIColor clearColor] }];
    return attrForTextField;
}
- (BOOL)dropdownMenu:(MKDropdownMenu *)dropdownMenu shouldUseFullRowWidthForComponent:(NSInteger)component {
    return NO;
}
- (CGFloat)dropdownMenu:(MKDropdownMenu *)dropdownMenu rowHeightForComponent:(NSInteger)component {
    return 30.0f;
}
- (UIView *)dropdownMenu:(MKDropdownMenu *)dropdownMenu viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UIView *selectedView = view;
    if (selectedView == nil) {
        selectedView = [[UIView alloc] init];
    }
    UILabel *contentLabel = [[UILabel alloc] init];
    UIFont *changeFont = FONT_STANDARD_FOR_DROP;
    if ([styleChecklistSwitch isOn]) {
        changeFont = FONT_G1000_FOR_DROP;
    }
    contentLabel.font = changeFont;
    
    if (dropdownMenu == rCVDropDownToEdit || dropdownMenu == otherCVDropDownToEdit) {
        contentLabel.text = [typeArray objectAtIndex:row];
        contentLabel.textAlignment = NSTextAlignmentCenter;
        [contentLabel setFrame:CGRectMake(0, 0, rCVDropDownToEdit.frame.size.width, 35.0f)];
        [selectedView addSubview:contentLabel];
        return selectedView;
    }
    
    
    if ([styleChecklistSwitch isOn]) {
        [contentLabel setTextColor:COLOR_G1000_CHECKLIST_SKY_THEME];
        [selectedView setBackgroundColor:[UIColor blackColor]];
        selectedView.layer.borderColor = COLOR_G1000_CHECKLIST_SKY_THEME.CGColor;
    }else{
        [contentLabel setTextColor:[UIColor blackColor]];
        [selectedView setBackgroundColor:[UIColor whiteColor]];
        selectedView.layer.borderColor = COLOR_STANDARD_CHECKLIST_BLUE_THEME.CGColor;
    }
    
    [contentLabel setBackgroundColor:[UIColor clearColor]];
    if (dropdownMenu == groupsDropDownMenu) {
        contentLabel.text =  [arrayCheckListsGroups objectAtIndex:row];
        [contentLabel setFrame:CGRectMake(10, 0, groupsDropDownMenu.frame.size.width, 35.0f)];
        if ([contentLabel.text isEqualToString:currentSelectedGroup]) {
            [contentLabel setTextColor:[UIColor blackColor]];
            if ([styleChecklistSwitch isOn]) {
                [selectedView setBackgroundColor:COLOR_G1000_CHECKLIST_SKY_THEME];
            }else{
                [selectedView setBackgroundColor:COLOR_STANDARD_CHECKLIST_BLUE_THEME];
            }
        }
        [checkListsDropDownMenu closeAllComponentsAnimated:YES];
    }else  if (dropdownMenu == checkListsDropDownMenu) {
        contentLabel.text = ((Checklists *)[arrayChecklists objectAtIndex:row]).checklist;
        [contentLabel setFrame:CGRectMake(10, 0, checkListsDropDownMenu.frame.size.width, 35.0f)];
        if ([contentLabel.text isEqualToString:currentSelectedCheckList]) {
            [contentLabel setTextColor:[UIColor blackColor]];
            if ([styleChecklistSwitch isOn]) {
                [selectedView setBackgroundColor:COLOR_G1000_CHECKLIST_SKY_THEME];
            }else{
                [selectedView setBackgroundColor:COLOR_STANDARD_CHECKLIST_BLUE_THEME];
            }
        }
        
        Checklists *checklistToCheck = (Checklists *)[arrayChecklists objectAtIndex:row];
        BOOL isFinished = YES;
        NSInteger countR = 0;
        for (int i = 0; i < checklistToCheck.checklists.count; i ++) {
            ChecklistsContent *checklistsContent = [checklistToCheck.checklists objectAtIndex:i];
            NSString *contentType = checklistsContent.type;
            NSString *preType = @"";
            NSString *depth = @"0";
            if (contentType.length > 1) {
                preType = [contentType substringToIndex:1];
                depth = [contentType substringFromIndex:1];
            }else if (contentType.length == 1){
                preType = [contentType substringToIndex:1];
            }
            if ([preType isEqualToString:@"r"]) {
                countR = countR + 1;
                if ([checklistsContent.isChecked boolValue] == NO) {
                    isFinished = NO;
                }
            }
        }
        if (isFinished && countR != 0) {
            if ([styleChecklistSwitch isOn]) {
                if ([contentLabel.text isEqualToString:currentSelectedCheckList]) {
                    [contentLabel setTextColor:[UIColor blackColor]];
                     [selectedView setBackgroundColor:COLOR_G1000_CHECKLIST_GREEN_THEME];
                }else{
                    [contentLabel setTextColor:COLOR_G1000_CHECKLIST_GREEN_THEME];
                }
            }else{
                if ([contentLabel.text isEqualToString:currentSelectedCheckList]) {
                    [contentLabel setTextColor:COLOR_G1000_CHECKLIST_SKY_THEME];
                    [selectedView setBackgroundColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                }else{
                    [contentLabel setTextColor:COLOR_STANDARD_CHECKLIST_GREEN_THEME];
                }
            }
        }
    }
    
    [selectedView addSubview:contentLabel];
    selectedView.layer.borderWidth = 1.0f;
    
    return selectedView;
}
- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (dropdownMenu == groupsDropDownMenu) {
        currentFouceGroupIndex = row;
        currentSelectedGroup = [arrayCheckListsGroups objectAtIndex:row];
        
        [groupsDropDownMenu closeAllComponentsAnimated:YES];
        [groupsDropDownMenu reloadAllComponents];
        
        [self getCheckListsWithGroup:currentSelectedGroup];
        
    }else if (dropdownMenu == checkListsDropDownMenu) {
        currentFouceChecklistIndex = row;
        currentSelectedCheckList = ((Checklists *)[arrayChecklists objectAtIndex:row]).checklist;
        currentCheckList =[arrayChecklists objectAtIndex:row];
        currentFouceChecklistContentIndex = 0;
        
        [checkListsDropDownMenu closeAllComponentsAnimated:YES];
        [checkListsDropDownMenu reloadAllComponents];
        
        [ChecklistsContentsTableView reloadData];
        if (currentCheckList.checklists.count > 0) {
            [ChecklistsContentsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition: UITableViewScrollPositionMiddle];
            [ChecklistsContentsTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
        }
    }else{
        currentSelectedType = [typeArray objectAtIndex:row];
        [rCVDropDownToEdit closeAllComponentsAnimated:YES];
        [rCVDropDownToEdit reloadAllComponents];
        [otherCVDropDownToEdit closeAllComponentsAnimated:YES];
        [otherCVDropDownToEdit reloadAllComponents];
    }
    
    //shave current history
    NSMutableDictionary *currentCheckContentHistory = [[checklistsHistories objectAtIndex:currentFouceCategoryIndex] mutableCopy];
    [currentCheckContentHistory setObject:@(currentFouceChecklistContentIndex) forKey:@"content"];
    [currentCheckContentHistory setObject:@(currentFouceGroupIndex) forKey:@"group"];
    [currentCheckContentHistory setObject:@(currentFouceChecklistIndex) forKey:@"checklist"];
    [checklistsHistories removeObjectAtIndex:currentFouceCategoryIndex];
    [checklistsHistories insertObject:currentCheckContentHistory atIndex:currentFouceCategoryIndex];
    
    
    [self saveCurrentStatus];
}
@end
