//
//  EndorsementAllViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/26/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "EndorsementAllViewController.h"
#import "DateViewController.h"
#import "SignatureViewController.h"
#import "PickerWithDataViewController.h"
#import "EndorsementCell.h"

@interface EndorsementAllViewController ()<UITableViewDelegate, UITableViewDataSource, PickerWithDataViewControllerDelegate, SignatureViewControllerDelegate, DateViewControllerDelegate, EndorsementCellDelegate, UITextFieldDelegate, SWTableViewCellDelegate>
{
    NSMutableArray *allEndorsementsArray;
    NSManagedObjectContext *contextRecords;
    
    BOOL isShownPickerView;
    
    NSString *endorsementName;
    NSString *endorsementText;
    NSString *endorsementDate;
    NSString *endorsementExpDate;
    UIImage *signatureImage;
    
    Endorsement *endorsementToEdit;
    NSNumber *logEntryIDToEdit;
    
    BOOL isShownEndorsementTypeForUserType;
}

@end

@implementation EndorsementAllViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Endorsements";
    isShownPickerView = NO;
    endorsementName = @"";
    endorsementText = @"";
    endorsementDate = @"";
    endorsementExpDate = @"";
    signatureImage = nil;
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    allEndorsementsArray = [[NSMutableArray alloc] init];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        endorsmentsTypeConstraints.constant = 54.0f;
        segmentsTypeOfEndorsement.hidden = NO;
        isShownEndorsementTypeForUserType = YES;
    }else{
        endorsmentsTypeConstraints.constant = 0.0f;
        segmentsTypeOfEndorsement.hidden = YES;
        isShownEndorsementTypeForUserType = NO;
    }
    
    EndorsementTableview.translatesAutoresizingMaskIntoConstraints = NO;
 
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont fontWithName:@"Helvetica-Bold" size:16], NSFontAttributeName,
                                [UIColor blackColor], NSForegroundColorAttributeName,
                                nil];
    [segmentsTypeOfEndorsement setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [segmentsTypeOfEndorsement setTitleTextAttributes:highlightedAttributes forState:UIControlStateSelected];
    
    addButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 40, 40)];
    [addButton addTarget:self action:@selector(addEndorsementOwnSelf) forControlEvents:UIControlEventTouchUpInside];
    [addButton setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    UIView *containsViewOfAdd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [containsViewOfAdd addSubview:addButton];
    UIBarButtonItem *addBtnItem = [[UIBarButtonItem alloc] initWithCustomView:containsViewOfAdd];
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:addBtnItem];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    addButton.hidden = YES;
    addEndorsementCV.hidden = YES;

    addEndorsementCV.userInteractionEnabled = NO;
    addEndorsementDialog.autoresizesSubviews = NO;
    addEndorsementDialog.contentMode = UIViewContentModeRedraw;
    addEndorsementDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    addEndorsementDialog.layer.shadowRadius = 3.0f;
    addEndorsementDialog.layer.shadowOpacity = 1.0f;
    addEndorsementDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    addEndorsementDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:addEndorsementDialog.bounds].CGPath;
    addEndorsementDialog.layer.cornerRadius = 5.0f;
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getAllEndorsements:0];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"EndorsementAllViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        [self onCancel:nil];
    }
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)getAllEndorsements:(NSInteger)type{
    [allEndorsementsArray removeAllObjects];
    NSMutableArray *objectsEndorsements = [[NSMutableArray alloc] init];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
    } else if (objects.count == 0) {
    } else {
        for (LogEntry *oneLogentry in objects) {
            if (isShownEndorsementTypeForUserType) {
                if (type == 0) {
                    if (oneLogentry.lessonId && [oneLogentry.lessonId integerValue] > 0) {
                        for (Endorsement *oneEndor in oneLogentry.endorsements) {
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                            [dict setObject:@1 forKey:@"editable"];
                            [dict setObject:oneEndor forKey:@"endorsement"];
                            [dict setObject:oneLogentry.log_local_id forKey:@"logLocalID"];
                            [dict setObject:@1 forKey:@"type"];
                            [objectsEndorsements addObject:dict];
                        }
                    }
                }else if (type == 1){
                    if (oneLogentry.lessonId == nil || [oneLogentry.lessonId integerValue] == 0) {
                        for (Endorsement *oneEndor in oneLogentry.endorsements) {
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                            [dict setObject:@1 forKey:@"editable"];
                            [dict setObject:oneEndor forKey:@"endorsement"];
                            [dict setObject:oneLogentry.log_local_id forKey:@"logLocalID"];
                            [dict setObject:@1 forKey:@"type"];
                            [objectsEndorsements addObject:dict];
                        }
                    }
                }
            }else{
                //student
                for (Endorsement *oneEndor in oneLogentry.endorsements) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                    if ([oneLogentry.userID integerValue] == [[AppDelegate sharedDelegate].userId integerValue]) {
                        [dict setObject:@1 forKey:@"editable"];
                    }else{
                        [dict setObject:@0 forKey:@"editable"];
                    }
                    [dict setObject:oneEndor forKey:@"endorsement"];
                    [dict setObject:oneLogentry.log_local_id forKey:@"logLocalID"];
                    [dict setObject:@1 forKey:@"type"];
                    [objectsEndorsements addObject:dict];
                }
            }
        }
    }
    if (type == 1) {
        entityDesc = [NSEntityDescription entityForName:@"Endorsement" inManagedObjectContext:contextRecords];
        request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == 2"];
        [request setPredicate:predicate];
        NSArray *endorsementObjects = [contextRecords executeFetchRequest:request error:&error];
        if (endorsementObjects == nil) {
            FDLogError(@"Unable to retrieve Endorsements!");
        } else if (endorsementObjects.count == 0) {
            FDLogDebug(@"No valid Endorsements found!");
        } else {
            for (Endorsement *endorsement in endorsementObjects) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setObject:@1 forKey:@"editable"];
                [dict setObject:endorsement forKey:@"endorsement"];
                [dict setObject:@0 forKey:@"logLocalID"];
                [dict setObject:@2 forKey:@"type"];
                [objectsEndorsements addObject:dict];
            }
        }
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSArray *sortedArray = [objectsEndorsements sortedArrayUsingComparator:^NSComparisonResult(NSMutableDictionary *obj1, NSMutableDictionary *obj2) {
        Endorsement *endorsement1 = [obj1 objectForKey:@"endorsement"];
        Endorsement *endorsement2 = [obj2 objectForKey:@"endorsement"];
        NSDate *d1 = [df dateFromString: endorsement1.endorsementDate];
        NSDate *d2 = [df dateFromString: endorsement2.endorsementDate];
        if ([endorsement1.endorsementDate isEqualToString:@""] && ![endorsement2.endorsementDate isEqualToString:@""]) {
            return NSOrderedDescending;
        }else if (![endorsement1.endorsementDate isEqualToString:@""] && [endorsement2.endorsementDate isEqualToString:@""]) {
            return NSOrderedAscending;
        }else if ([endorsement1.endorsementDate isEqualToString:@""] && [endorsement2.endorsementDate isEqualToString:@""]) {
            return NSOrderedSame;
        }else{
            return [d2 compare: d1];
        }
    }];
    
    allEndorsementsArray = [sortedArray mutableCopy];
    [EndorsementTableview reloadData];
}
#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [allEndorsementsArray count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableDictionary *oneDict = [allEndorsementsArray objectAtIndex:indexPath.row];
    Endorsement *endorsement = [oneDict objectForKey:@"endorsement"];
    if (endorsement && endorsement.name && endorsement.text && ![endorsement.name isEqualToString:@""] && ![endorsement.text isEqualToString:@""]) {
        return [self getHeightFromString:endorsement.name withFont:[UIFont fontWithName:@"Helvetica-Bold" size:15] withWidth:EndorsementTableview.frame.size.width] + [self getHeightFromString:endorsement.text withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14] withWidth:EndorsementTableview.frame.size.width] + 230.0f ;
    }else{
        return 280.0f;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *simpleTableIdentifier = @"EndorsementItem";
    EndorsementCell *cell = (EndorsementCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [EndorsementCell sharedCell];
    }
    cell.endorsementDelegate = self;
    cell.backgroundColor = cell.contentView.backgroundColor;
    NSMutableDictionary *oneDict = [allEndorsementsArray objectAtIndex:indexPath.row];
    Endorsement *endorsement = [oneDict objectForKey:@"endorsement"];
    
    cell.btnAdditionalEndorsement.hidden = YES;
    cell.btnAddEndorsement.hidden = YES;
    cell.btnChangeEndorsement.hidden = YES;
    
    cell.endorsementTxtView.delegate = cell;
    cell.endorsementTxtView.textAlignment = NSTextAlignmentLeft;
    UIFont *text1Font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    NSMutableAttributedString *attributedString1 =
    [[NSMutableAttributedString alloc] initWithString:endorsement.name attributes:@{ NSFontAttributeName : text1Font }];
    NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle1 setLineSpacing:4];
    [attributedString1 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, [attributedString1 length])];
    
    UIFont *text2Font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    NSMutableAttributedString *attributedString2 =
    [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@", endorsement.text] attributes:@{NSFontAttributeName : text2Font }];
    NSMutableParagraphStyle *paragraphStyle2 = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle2 setLineSpacing:4];
    [attributedString2 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle2 range:NSMakeRange(0, [attributedString2 length])];
    [attributedString1 appendAttributedString:attributedString2];
    [cell.endorsementTxtView setAttributedText:attributedString1];
    
    if (endorsement != nil && endorsement.cfiSignature != nil && ![endorsement.cfiSignature isEqualToString:@""]) {
        cell.btnSingature.hidden = NO;
        UIImage * signatureImage = [self decodeBase64ToImage:endorsement.cfiSignature];
        [cell.btnSingature setImage:signatureImage forState:UIControlStateNormal];
        cell.btnSingature.backgroundColor = [UIColor clearColor];
        [cell.btnSingature setTitle:@"" forState:UIControlStateNormal];
    } else {
        [cell.btnSingature setImage:nil forState:UIControlStateNormal];
        cell.btnSingature.layer.cornerRadius = 10.0f;
        cell.btnSingature.hidden = YES;
    }
    
    if (endorsement != nil && endorsement.endorsementDate != nil && ![endorsement.endorsementDate isEqualToString:@""]) {
        cell.btnEndorsementDate.hidden = NO;
        [cell.btnEndorsementDate setTitle:endorsement.endorsementDate forState:UIControlStateNormal];
        [cell.btnEndorsementDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        cell.btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        cell.btnEndorsementDate.backgroundColor = [UIColor clearColor];
    } else {
        cell.btnEndorsementDate.hidden = YES;
        cell.btnEndorsementDate.layer.cornerRadius = 10.0f;
    }
    
    if (endorsement != nil && endorsement.cfiNumber != nil && ![endorsement.cfiNumber isEqualToString:@""] && ![endorsement.cfiNumber isEqualToString:@"Tap to Enter"]) {
        cell.lblCFINumber.text = endorsement.cfiNumber;
    }else{
        cell.lblCFINumber.text = @"";
    }
    
    if (endorsement != nil && endorsement.endorsementExpDate != nil && ![endorsement.endorsementExpDate isEqualToString:@""]) {
        [cell.btnEndorsementExpDate setTitle:endorsement.endorsementExpDate forState:UIControlStateNormal];
        [cell.btnEndorsementExpDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        cell.btnEndorsementExpDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        cell.btnEndorsementExpDate.backgroundColor = [UIColor clearColor];
        cell.btnEndorsementExpDate.hidden = NO;
    } else {
        cell.btnEndorsementExpDate.hidden = YES;
        cell.btnEndorsementExpDate.layer.cornerRadius = 10.0f;
    }
    
    cell.btnCancel.hidden = YES;
    cell.endorsementTxtView.editable = NO;
    cell.btnSingature.enabled = NO;
    cell.btnEndorsementDate.enabled = NO;
    cell.btnEndorsementExpDate.enabled = NO;
    if ([endorsement.isSupersed integerValue] == 1) {
        cell.supersedMaskView.hidden = NO;
        cell.btnSuporsed.hidden = YES;
    }else{
        cell.btnSuporsed.hidden = NO;
        cell.supersedMaskView.hidden = YES;
    }
    if (!isShownEndorsementTypeForUserType) {
        if ([[oneDict objectForKey:@"editable"] boolValue] == YES) {
            cell.delegate = self;
            if ([endorsement.isSupersed integerValue] == 0) {
                cell.leftUtilityButtons = [self leftButtons];
            }else{
                cell.leftUtilityButtons = nil;
            }
            cell.rightUtilityButtons = [self rightButtons];
        }else{
            cell.btnSuporsed.hidden = YES;
        }
    }else{
        if (segmentsTypeOfEndorsement.selectedSegmentIndex == 1){
            cell.delegate = self;
            if ([endorsement.isSupersed integerValue] == 0) {
                cell.leftUtilityButtons = [self leftButtons];
            }else{
                cell.leftUtilityButtons = nil;
            }
            cell.rightUtilityButtons = [self rightButtons];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
            NSIndexPath *indexPath = [EndorsementTableview indexPathForCell:cell];
            NSMutableDictionary *dictOne = [allEndorsementsArray objectAtIndex:indexPath.row];
            id rowElement = [dictOne objectForKey:@"endorsement"];
            if ([rowElement isMemberOfClass:[Endorsement class]]) {
                endorsementToEdit = (Endorsement *)rowElement;
                logEntryIDToEdit = [dictOne objectForKey:@"logLocalID"];
                
                addEndorsementCV.hidden = NO;
                supersedView.hidden = YES;
                
                if (![endorsementToEdit.text isEqualToString:@""] || ![endorsementToEdit.name isEqualToString:@""]) {
                    endorsementName = endorsementToEdit.name;
                    endorsementText = endorsementToEdit.text;
                    btnAddEndorsment.hidden = YES;
                    btnChangeEndorsement.hidden = NO;
                    UIFont *text1Font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
                    NSMutableAttributedString *attributedString1 =
                    [[NSMutableAttributedString alloc] initWithString:endorsementToEdit.name attributes:@{ NSFontAttributeName : text1Font }];
                    NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
                    [paragraphStyle1 setLineSpacing:4];
                    [attributedString1 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, [attributedString1 length])];
                    
                    UIFont *text2Font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
                    NSMutableAttributedString *attributedString2 =
                    [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@", endorsementToEdit.text] attributes:@{NSFontAttributeName : text2Font }];
                    NSMutableParagraphStyle *paragraphStyle2 = [[NSMutableParagraphStyle alloc] init];
                    [paragraphStyle2 setLineSpacing:4];
                    [attributedString2 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle2 range:NSMakeRange(0, [attributedString2 length])];
                    
                    [attributedString1 appendAttributedString:attributedString2];
                    [endorsementTxtView setAttributedText:attributedString1];
                }else{
                    endorsementTxtView.text = @"";
                    btnAddEndorsment.hidden = NO;
                    btnChangeEndorsement.hidden = YES;
                }
                
                if (endorsementToEdit.cfiSignature != nil && ![endorsementToEdit.cfiSignature isEqualToString:@""]) {
                    UIImage * signatureImage = [self decodeBase64ToImage:endorsementToEdit.cfiSignature];
                    [btnEndorsementSign setImage:signatureImage forState:UIControlStateNormal];
                    btnEndorsementSign.backgroundColor = [UIColor clearColor];
                    [btnEndorsementSign setTitle:@"" forState:UIControlStateNormal];
                    
                    signatureImage = signatureImage;
                } else {
                    [btnEndorsementSign setImage:nil forState:UIControlStateNormal];
                    [btnEndorsementSign setTitle:@"Tap to Sign" forState:UIControlStateNormal];
                    [btnEndorsementSign setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
                    btnEndorsementSign.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
                    btnEndorsementSign.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                    btnEndorsementSign.layer.cornerRadius = 10.0f;
                }
                
                if (endorsementToEdit.endorsementDate != nil && ![endorsementToEdit.endorsementDate isEqualToString:@""]) {
                    endorsementDate = endorsementToEdit.endorsementDate;
                    [btnEndorsementDate setTitle:endorsementToEdit.endorsementDate forState:UIControlStateNormal];
                    [btnEndorsementDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
                    btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
                    btnEndorsementDate.backgroundColor = [UIColor clearColor];
                } else {
                    [btnEndorsementDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
                    [btnEndorsementDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
                    btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
                    btnEndorsementDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                    btnEndorsementDate.layer.cornerRadius = 5.0f;
                }
                
                if (endorsementToEdit.cfiNumber != nil && ![endorsementToEdit.cfiNumber isEqualToString:@""]) {
                    cfiNumTxtField.text = endorsementToEdit.cfiNumber;
                    [cfiNumTxtField setTextColor:[UIColor blackColor]];
                    cfiNumTxtField.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
                    cfiNumTxtField.backgroundColor = [UIColor clearColor];
                }else{
                    cfiNumTxtField.text = @"Tap to Enter";
                    [cfiNumTxtField setTextColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f]];
                    cfiNumTxtField.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
                    cfiNumTxtField.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                    cfiNumTxtField.layer.cornerRadius = 5.0f;
                }
                
                if (endorsementToEdit.endorsementExpDate != nil && ![endorsementToEdit.endorsementExpDate isEqualToString:@""]) {
                    endorsementExpDate = endorsementToEdit.endorsementExpDate;
                    [btnExpirationDate setTitle:endorsementToEdit.endorsementExpDate forState:UIControlStateNormal];
                    [btnExpirationDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
                    btnExpirationDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
                    btnExpirationDate.backgroundColor = [UIColor clearColor];
                } else {
                    [btnExpirationDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
                    [btnExpirationDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
                    btnExpirationDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
                    btnExpirationDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
                    btnExpirationDate.layer.cornerRadius = 5.0f;
                }
                
                [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                                 animations:^(void)
                 {
                     dialogBottomPaddingConstraints.constant = (self.view.frame.size.height-295.0f)/2;
                     [addEndorsementCV layoutIfNeeded];
                     
                 }
                                 completion:^(BOOL finished)
                 {
                     
                     addEndorsementCV.userInteractionEnabled = YES;
                 }
                 ];
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
            NSIndexPath *indexPath = [EndorsementTableview indexPathForCell:cell];
            NSMutableDictionary *dictOne = [allEndorsementsArray objectAtIndex:indexPath.row];
            id rowElement = [dictOne objectForKey:@"endorsement"];
            if ([rowElement isMemberOfClass:[Endorsement class]]) {
                Endorsement *endorsement = rowElement;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current Endorsement?" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                    //NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                    
                    [allEndorsementsArray removeObjectAtIndex:indexPath.row];
                    [EndorsementTableview deleteRowsAtIndexPaths:@[indexPath]
                                         withRowAnimation:UITableViewRowAnimationAutomatic];
                    
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    NSError *error = nil;
                    
                    if ([[dictOne objectForKey:@"type"] integerValue] == 1) {
                        NSNumber *logIdToUpdate = [dictOne objectForKey:@"logLocalID"];
                        if (logIdToUpdate != nil) {
                            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:contextRecords];
                            NSError *error;
                            NSFetchRequest *request = [[NSFetchRequest alloc] init];
                            [request setEntity:entityDesc];
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"log_local_id == %@", logIdToUpdate];
                            [request setPredicate:predicate];
                            NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
                            if (objects == nil) {
                            } else if (objects.count == 0) {
                            } else {
                                LogEntry *oneLogentry = objects[0];
                                for (Endorsement *oneEndor in oneLogentry.endorsements) {
                                    if ([oneEndor.endorsement_local_id integerValue] == [endorsement.endorsement_local_id integerValue]) {
                                        [oneLogentry removeEndorsementsObject:oneEndor];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    if (endorsement.endorsementID && [endorsement.endorsementID integerValue] != 0) {
                        DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                        deleteQuery.type = @"logbook_endorsement";
                        deleteQuery.idToDelete = endorsement.endorsementID;
                        [context save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                    }
                    [context deleteObject:endorsement];
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
- (CGFloat)getHeightFromString:(NSString*)strToHeight withFont:(UIFont *)font withWidth:(CGFloat)width{
    CGSize constraint = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size;
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [strToHeight boundingRectWithSize:constraint
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:font}
                                                   context:context].size;
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    return size.height;
}
- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

- (UIImage *)decodeBase64ToImage:(NSString *)strEncodeData {
    NSData *data = [[NSData alloc]initWithBase64EncodedString:strEncodeData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [UIImage imageWithData:data];
}
- (IBAction)onChangeTypeOfEndorsement:(id)sender {
    if (segmentsTypeOfEndorsement.selectedSegmentIndex == 0) {
        addButton.hidden = YES;
    }else if (segmentsTypeOfEndorsement.selectedSegmentIndex == 1){
        addButton.hidden = NO;
    }
    [self getAllEndorsements:segmentsTypeOfEndorsement.selectedSegmentIndex];
}

- (IBAction)onSave:(id)sender {
    [self.view endEditing:YES];
    addEndorsementCV.hidden = YES;
    dialogBottomPaddingConstraints.constant = 50.0f;
    Endorsement *endorsementToInit = nil;
    if (endorsementToEdit == nil) {
        endorsementToInit = [NSEntityDescription insertNewObjectForEntityForName:@"Endorsement" inManagedObjectContext:contextRecords];
        endorsementToInit.endorsementID = @(0);
        endorsementToInit.endorsement_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    }else{
        endorsementToInit = endorsementToEdit;
    }
    endorsementToInit.text = endorsementText;
    endorsementToInit.name = endorsementName;
    endorsementToInit.cfiNumber = cfiNumTxtField.text;
    endorsementToInit.endorsementDate = endorsementDate;
    endorsementToInit.endorsementExpDate = endorsementExpDate;
    if (signatureImage != nil) {
        endorsementToInit.cfiSignature = [self encodeToBase64String:signatureImage];
    }else{
        if (endorsementToEdit == nil) {
            endorsementToInit.cfiSignature = @"";
        }
    }
    endorsementToInit.isSupersed = @(0);
    if (btnSupersed.hidden) {
        endorsementToInit.isSupersed = @(1);
    }
    endorsementToInit.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    endorsementToInit.lastUpdate = @0;
    if (endorsementToEdit == nil) {
        endorsementToInit.type = @2;
    }else{
        if ([endorsementToEdit.type integerValue] == 1) {
            [self saveLogEntryFromEndorsement];
        }else{
            endorsementToInit.type = @2;
        }
    }
    NSError *error;
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    if (!isShownEndorsementTypeForUserType) {
        [self getAllEndorsements:0];
    }else{
        [self getAllEndorsements:1];
    }
    isShownPickerView = NO;
    isShownPickerView = NO;
    endorsementName = @"";
    endorsementText = @"";
    endorsementDate = @"";
    endorsementExpDate = @"";
    signatureImage = nil;
    endorsementToEdit = nil;
    logEntryIDToEdit = nil;
}
- (void)saveLogEntryFromEndorsement{
    if (logEntryIDToEdit != nil) {
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"log_local_id == %@", logEntryIDToEdit];
        [request setPredicate:predicate];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        LogEntry *logEntryToUpdate = nil;
        if (objects == nil) {
        } else if (objects.count == 0) {
        } else {
            logEntryToUpdate = objects[0];
            logEntryToUpdate.lastUpdate = @0;
            [context save:&error];
        }
    }
}
- (IBAction)onCancel:(id)sender {
    [self.view endEditing:YES];
    addEndorsementCV.hidden = YES;
    dialogBottomPaddingConstraints.constant = 50.0f;
    
    endorsementToEdit = nil;
    
    isShownPickerView = NO;
    isShownPickerView = NO;
    endorsementName = @"";
    endorsementText = @"";
    endorsementDate = @"";
    endorsementExpDate = @"";
    signatureImage = nil;
}

- (IBAction)onSelectEndorsement:(id)sender {
    if (!isShownPickerView) {
        isShownPickerView = YES;
        PickerWithDataViewController *pickView = [[PickerWithDataViewController alloc] initWithNibName:@"PickerWithDataViewController" bundle:nil];
        [pickView.view setFrame:self.view.bounds];
        pickView.delegate = self;
        pickView.pickerType = 3;
        pickView.cellIndexForEndorsement = 0;
        [self displayContentController:pickView];
        [pickView animateShow];
    }
}
#pragma mark PickerWithDataViewController
- (void)didCancelPickerView:(PickerWithDataViewController *)pickerView{
    [self removeCurrentViewFromSuper:pickerView];
}
- (void)returnValueFromPickerView:(PickerWithDataViewController *)pickerView withSelectedString:(NSString *)toString withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index{
    [self removeCurrentViewFromSuper:pickerView];
    
    endorsementName = toString;
    endorsementText = _text;
    btnAddEndorsment.hidden = YES;
    btnChangeEndorsement.hidden = NO;
    UIFont *text1Font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    NSMutableAttributedString *attributedString1 =
    [[NSMutableAttributedString alloc] initWithString:toString attributes:@{ NSFontAttributeName : text1Font }];
    NSMutableParagraphStyle *paragraphStyle1 = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle1 setLineSpacing:4];
    [attributedString1 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle1 range:NSMakeRange(0, [attributedString1 length])];
    
    UIFont *text2Font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    NSMutableAttributedString *attributedString2 =
    [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n\n%@", _text] attributes:@{NSFontAttributeName : text2Font }];
    NSMutableParagraphStyle *paragraphStyle2 = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle2 setLineSpacing:4];
    [attributedString2 addAttribute:NSParagraphStyleAttributeName value:paragraphStyle2 range:NSMakeRange(0, [attributedString2 length])];
    
    [attributedString1 appendAttributedString:attributedString2];
    [endorsementTxtView setAttributedText:attributedString1];
}
- (IBAction)onSignEndorsement:(id)sender {
    if (!isShownPickerView) {
        isShownPickerView = YES;
        SignatureViewController *signView = [[SignatureViewController alloc] initWithNibName:@"SignatureViewController" bundle:nil];
        [signView.view setFrame:self.view.bounds];
        signView.delegate = self;
        signView.currentCellIndex = 0;
        [self displayContentController:signView];
        [signView animateShow];
    }
}
#pragma mark SignatureViewControllerDelegate
- (void)returnValueFromSignView:(SignatureViewController *)signView signatureImage:(UIImage *)_signImage withIndex:(NSInteger)index{
    [self removeCurrentViewFromSuper:signView];
    [btnEndorsementSign setImage:_signImage forState:UIControlStateNormal];
    btnEndorsementSign.backgroundColor = [UIColor clearColor];
    [btnEndorsementSign setTitle:@"" forState:UIControlStateNormal];
    
    signatureImage = _signImage;
    
}
- (void)didCancelSignView:(SignatureViewController *)signView{
    [self removeCurrentViewFromSuper:signView];
}
- (IBAction)onDateEndorsement:(id)sender {
    if (!isShownPickerView) {
        isShownPickerView = YES;
        DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
        [dateView.view setFrame:self.view.bounds];
        dateView.delegate = self;
        dateView.type = 1;
            dateView.pickerTitle = @"Date";
        dateView.indexForEndorsementCell = 0;
        [self displayContentController:dateView];
        [dateView animateShow];
    }
}

- (IBAction)onExpirationEndorsementDate:(id)sender {
    if (!isShownPickerView) {
        isShownPickerView = YES;
        DateViewController *dateView = [[DateViewController alloc] initWithNibName:@"DateViewController" bundle:nil];
        [dateView.view setFrame:self.view.bounds];
        dateView.delegate = self;
        dateView.type = 2;
        dateView.pickerTitle = @"Expiration";
        dateView.indexForEndorsementCell = 0;
        [self displayContentController:dateView];
        [dateView animateShow];
        
    }
}
#pragma mrak UITextFieldDelete
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == cfiNumTxtField) {
        if ([cfiNumTxtField.text isEqualToString:@"Tap to Enter"]) {
            cfiNumTxtField.text = @"";
        }
        [cfiNumTxtField setTextColor:[UIColor blackColor]];
        cfiNumTxtField.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        cfiNumTxtField.backgroundColor = [UIColor clearColor];
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField == cfiNumTxtField) {
        if ([cfiNumTxtField.text isEqualToString:@""]) {
            cfiNumTxtField.text = @"Tap to Enter";
            [cfiNumTxtField setTextColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f]];
            cfiNumTxtField.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
            cfiNumTxtField.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
            cfiNumTxtField.layer.cornerRadius = 5.0f;
        }
    }
}

#pragma mark DateViewControllerDelegate
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    if (_type == 1) {
        endorsementDate = _strDate;
        [btnEndorsementDate setTitle:_strDate forState:UIControlStateNormal];
        [btnEndorsementDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        btnEndorsementDate.backgroundColor = [UIColor clearColor];
    }else if (_type == 2){
        endorsementExpDate = _strDate;
        [btnExpirationDate setTitle:_strDate forState:UIControlStateNormal];
        [btnExpirationDate setTitleColor:[UIColor blackColor]  forState:UIControlStateNormal];
        btnExpirationDate.titleLabel.font = [UIFont fontWithName:@"Noteworthy-Bold" size:15];
        btnExpirationDate.backgroundColor = [UIColor clearColor];
    }
    [self removeCurrentViewFromSuper:dateView];
}
- (void)didCancelDateView:(DateViewController *)dateView{
    [self removeCurrentViewFromSuper:dateView];
}
- (IBAction)onSupersed:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Are you sure you want to \"Superseded\" this endorsement? This cannot be undone!" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             supersedView.hidden = NO;
                             btnSupersed.hidden = YES;
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                             {
                             }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}
- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    isShownPickerView = NO;
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}
- (void)addEndorsementOwnSelf{
    addEndorsementCV.hidden = NO;
    supersedView.hidden = YES;
    btnAddEndorsment.hidden = NO;
    btnChangeEndorsement.hidden = YES;
    
    endorsementTxtView.text = @"";
    
    [btnEndorsementSign setImage:nil forState:UIControlStateNormal];
    [btnEndorsementSign setTitle:@"Tap to Sign" forState:UIControlStateNormal];
    [btnEndorsementSign setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
    btnEndorsementSign.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
    btnEndorsementSign.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
    btnEndorsementSign.layer.cornerRadius = 10.0f;
    
    [btnEndorsementDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
    [btnEndorsementDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
    btnEndorsementDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    btnEndorsementDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
    btnEndorsementDate.layer.cornerRadius = 5.0f;
    
    [btnExpirationDate setTitle:@"Tap to Enter" forState:UIControlStateNormal];
    [btnExpirationDate setTitleColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f] forState:UIControlStateNormal];
    btnExpirationDate.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    btnExpirationDate.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
    btnExpirationDate.layer.cornerRadius = 5.0f;
    
    cfiNumTxtField.text = @"Tap to Enter";
    [cfiNumTxtField setTextColor:[UIColor colorWithRed:1.0f green:0 blue:0 alpha:0.5f]];
    cfiNumTxtField.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
    cfiNumTxtField.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.35f];
    cfiNumTxtField.layer.cornerRadius = 5.0f;
    
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         dialogBottomPaddingConstraints.constant = (self.view.frame.size.height-295.0f)/2;
         [addEndorsementCV layoutIfNeeded];
         
     }
                     completion:^(BOOL finished)
     {
         
         addEndorsementCV.userInteractionEnabled = YES;
     }
     ];
}

#pragma mark EndorsementCellDelete
-(void)didSignatureWithCell:(EndorsementCell *)cell{
    
}
-(void)didEndorsementDateWithCell:(EndorsementCell *)cell{
    
}
-(void)didEndorsementExpDateWithCell:(EndorsementCell *)cell{
    
}
-(void)didAdditionalEndorsementWithCell:(EndorsementCell *)cell{
    
}
-(void)didAddEndorsementWithCell:(EndorsementCell *)cell{
    
}
-(void)didSupersedWithCell:(EndorsementCell *)cell withFlag:(BOOL)isFlag{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Are you sure you want to \"Superseded\" this endorsement? This cannot be undone!" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                             NSIndexPath *indexpath = [EndorsementTableview indexPathForCell:cell];
                             NSMutableDictionary *dictOne = [allEndorsementsArray objectAtIndex:indexpath.row];
                             Endorsement *endorsementWithCell  = [dictOne objectForKey:@"endorsement"];
                             if (cell.supersedMaskView.hidden) {
                                 endorsementWithCell.isSupersed = @(1);
                             }else{
                                 endorsementWithCell.isSupersed = @(0);
                             }
                             NSError *error = nil;
                             endorsementWithCell.lastUpdate = @0;
                             [contextRecords save:&error];
                             [EndorsementTableview reloadData];
                         }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                         {
                         }];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)didEndEditingWithTextView:(EndorsementCell *)cell withText:(NSString *)_text{
    
}
-(void)didCancelEndorsementWithCell:(EndorsementCell *)cell{
    
}

@end
