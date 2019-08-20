//
//  GeneralViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "GeneralViewController.h"
#import "ZSSRichTextEditor.h"
#import "FaqsCell.h"

@interface GeneralViewController ()<HVTableViewDataSource, HVTableViewDelegate, MKDropdownMenuDelegate, MKDropdownMenuDataSource, SWTableViewCellDelegate>
{
    GeneralFlightDesk *generalFlightDesk;
    NSInteger currentType;
    
    NSMutableArray *faqsArray;
    NSMutableArray *categoryArray;
    NSString *selectedCategory;
    BOOL isAddFaqs;
    
    Faqs *faqsToEdit;
}
@end

@implementation GeneralViewController
@synthesize richTextEditorVC;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    faqsArray = [[NSMutableArray alloc] init];
    categoryArray = [[NSMutableArray alloc] init];
    textEditorCV.hidden = YES;
    currentType = 0;
    isAddFaqs = NO;
    //txtEditorDialog.autoresizesSubviews = NO;
    //txtEditorDialog.contentMode = UIViewContentModeRedraw;
    //txtEditorDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    txtEditorDialog.layer.masksToBounds = YES;
    txtEditorDialog.layer.shadowRadius = 20.0f;
    txtEditorDialog.layer.shadowOpacity = 1.0f;
    txtEditorDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    txtEditorDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:txtEditorDialog.bounds].CGPath;
    txtEditorDialog.layer.cornerRadius = 20.0f;
    if ([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height) {
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, mainView.frame.size.height)];
    }else{
        [scrView setContentSize:CGSizeMake(0, 0)];
    }
    
    CGRect editorRect = txtEditorDialog.frame;
    editorRect.size.height = [UIScreen mainScreen].bounds.size.height - 260;
    [txtEditorDialog setFrame:editorRect];
    
    
    FaqsTableView.HVTableViewDelegate = self;
    FaqsTableView.HVTableViewDataSource = self;
    
    selectedCategory = @"";
    categoryDropDownMenu.dataSource = self;
    categoryDropDownMenu.delegate = self;
    categoryDropDownMenu.componentTextAlignment =  NSTextAlignmentLeft;
    
    [btnSave setTitle:@"Save" forState:UIControlStateNormal];
    faqsCoverView.hidden = YES;
    faqsAddView.hidden = YES;
    
    
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        btnSave.hidden = NO;
    }else{
        btnSave.hidden = YES;
    }
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"GeneralViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self.navigationController.navigationBar setHidden:YES];
    [[AppDelegate sharedDelegate] startThreadToSyncData:8];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[AppDelegate sharedDelegate] stopThreadToSyncData:8];
}
- (void)deviceOrientationDidChange{
    CGRect editorRect = txtEditorDialog.frame;
    editorRect.size.height = [UIScreen mainScreen].bounds.size.height - 260;
    [txtEditorDialog setFrame:editorRect];
    editorRect.origin.x = 5;
    editorRect.origin.y = 42;
    editorRect.size.height = editorRect.size.height - 42;
    editorRect.size.width = editorRect.size.width - 10;
    richTextEditorVC.view.frame = editorRect;
    if ([UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height) {
        [scrView setContentSize:CGSizeMake(scrView.frame.size.width, mainView.frame.size.height)];
    }else{
        [scrView setContentSize:CGSizeMake(0, 0)];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onGettingStart:(id)sender {
    lblTextEditorTitle.text = @"Getting Started";
    currentType = 1;
    [self addTextEditor:1];
}

- (IBAction)onFAQs:(id)sender {
    lblTextEditorTitle.text = @"FAQs";
    currentType = 2;
    [self addTextEditor:2];
}

- (IBAction)onTermsOfUse:(id)sender {
    lblTextEditorTitle.text = @"Terms of Use";
    currentType = 3;
    [self addTextEditor:3];
}

- (IBAction)onPrivacy:(id)sender {
    lblTextEditorTitle.text = @"Privacy";
    currentType = 4;
    [self addTextEditor:4];
}

- (IBAction)onCopyrightsAndTradeMarks:(id)sender {
    lblTextEditorTitle.text = @"Copyrights & Trade Marks";
    currentType = 5;
    [self addTextEditor:5];
}
- (void)getCategories{
    
    [categoryArray removeAllObjects];
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Faqs" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
    } else if (objects.count == 0) {
    } else {
        for (Faqs *faqs in objects) {
            if (![categoryArray containsObject:faqs.category]) {
                [categoryArray addObject:faqs.category];
            }
        }
    }
    if (categoryArray.count > 0) {
        if (![selectedCategory isEqualToString:@""]) {
            if (![categoryArray containsObject:selectedCategory]) {
                selectedCategory = categoryArray[0];
            }
        }else{
            selectedCategory = categoryArray[0];
        }
    }else{
        selectedCategory = @"";
    }
    if (isAddFaqs) {
        [categoryArray addObject:@"- Add Category -"];
        if (categoryArray.count == 1) {
            categoryDropDownMenu.hidden = YES;
        }
    }
    [categoryDropDownMenu reloadAllComponents];
    if (!isAddFaqs) {
        if (![selectedCategory isEqualToString:@""]) {
            [self getFaqs:selectedCategory];
        }else{
            [faqsArray removeAllObjects];
            [FaqsTableView reloadData];
        }
    }
}
- (void)addTextEditor:(NSInteger)type{
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    
    if (type == 2) {
        faqsCoverView.hidden = NO;
        [btnSave setTitle:@"Add" forState:UIControlStateNormal];
        [self getCategories];
    }else{
        [btnSave setTitle:@"Save" forState:UIControlStateNormal];
        [[AppDelegate sharedDelegate] stopThreadToSyncData:8];
        faqsCoverView.hidden = YES;
        NSString *html = @"";
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"GeneralFlightDesk" inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
        } else if (objects.count == 0) {
        } else {
            generalFlightDesk = objects[0];
            switch (type) {
                case 1:
                    html = generalFlightDesk.gettingStart;
                    break;
                case 2:
                    
                    break;
                case 3:
                    html = generalFlightDesk.termsOfUse;
                    break;
                case 4:
                    html = generalFlightDesk.privacy;
                    break;
                case 5:
                    html = generalFlightDesk.copyrightAndTradeMarks;
                    break;
                    
                default:
                    break;
            }
        }
        
        richTextEditorVC = [[ZSSRichTextEditor alloc] init];
        //Set Custom CSS
        NSString *customCSS = @"";
        [richTextEditorVC setCSS:customCSS];
        
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            richTextEditorVC.isAbleToEdit = YES;
        }else{
            richTextEditorVC.isAbleToEdit = NO;
        }
        richTextEditorVC.alwaysShowToolbar = YES;
        richTextEditorVC.receiveEditorDidChangeEvents = NO;
        richTextEditorVC.baseURL = [NSURL URLWithString:@"http://flightdeskapp.com/"];
        richTextEditorVC.shouldShowKeyboard = YES;
        [richTextEditorVC setPlaceholder:@"Please enter content"];
        [richTextEditorVC setHTML:[html stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        CGRect editorRect = txtEditorDialog.frame;
        editorRect.size.height = [UIScreen mainScreen].bounds.size.height - 260;
        editorRect.origin.x = 5;
        editorRect.origin.y = 42;
        editorRect.size.height = editorRect.size.height - 42;
        editorRect.size.width = editorRect.size.width - 10;
        [self addChildViewController:richTextEditorVC];
        richTextEditorVC.view.frame = editorRect;
        [txtEditorDialog addSubview:richTextEditorVC.view];
        [richTextEditorVC didMoveToParentViewController:self];
    }
    
    textEditorCV.hidden = NO;
    txtEditorDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:    UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        txtEditorDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        
    }];
}

- (IBAction)onCancelTxtEditor:(id)sender {
    [[AppDelegate sharedDelegate] startThreadToSyncData:8];
    if (isAddFaqs) {
        [btnSave setTitle:@"Add" forState:UIControlStateNormal];
        isAddFaqs = NO;
        categoryDropDownMenu.hidden = NO;
        faqsAddView.hidden = YES;
        txtCategory.text = @"";
        txtQuestion.text = @"";
        txtAnswer.text = @"";
        [self getCategories];
    }else{
        [self.view endEditing:YES];
        textEditorCV.hidden = YES;
        [richTextEditorVC willMoveToParentViewController:nil];  // 1
        [richTextEditorVC.view removeFromSuperview];            // 2
        [richTextEditorVC removeFromParentViewController];
    }
}
- (void)saveCurrentFaqs{
    if (categoryDropDownMenu.hidden == YES && faqsToEdit == nil) {
        if (!txtCategory.text.length)
        {
            [self showAlert:@"Please input Category" :@"Input Error"];
            return;
        }
    }
    if (!txtQuestion.text.length)
    {
        [self showAlert:@"Please input Question" :@"Input Error"];
        return;
    }
    if (!txtAnswer.text.length)
    {
        [self showAlert:@"Please input Answer" :@"Input Error"];
        return;
    }
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    if (faqsToEdit == nil) {
        Faqs *faqs = [NSEntityDescription insertNewObjectForEntityForName:@"Faqs" inManagedObjectContext:context];
        faqs.faqs_id = @0;
        faqs.faqs_local_id = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        if (categoryDropDownMenu.hidden == YES) {
            faqs.category = txtCategory.text;
        }else{
            faqs.category = selectedCategory;
        }
        faqs.question = txtQuestion.text;
        faqs.answer = txtAnswer.text;
        faqs.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        faqs.lastUpdate = @0;
        
    }else{
        faqsToEdit.question = txtQuestion.text;
        faqsToEdit.answer = txtAnswer.text;
        faqsToEdit.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
        faqsToEdit.lastUpdate = @0;
    }
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    categoryDropDownMenu.hidden = NO;
    txtCategory.hidden = NO;
    txtCategory.text = @"";
    txtQuestion.text = @"";
    txtAnswer.text = @"";
    [[AppDelegate sharedDelegate] startThreadToSyncData:8];
    [self.view endEditing:YES];
}
- (IBAction)onSaveTxtEditor:(id)sender {
    if (currentType == 2) {
        if (isAddFaqs) {
            isAddFaqs = NO;
            faqsAddView.hidden = YES;
            [btnSave setTitle:@"Add" forState:UIControlStateNormal];
            [self saveCurrentFaqs];
        }else{
            [[AppDelegate sharedDelegate] stopThreadToSyncData:8];
            isAddFaqs = YES;
            faqsAddView.hidden = NO;
            [btnSave setTitle:@"Save" forState:UIControlStateNormal];
        }
        [self getCategories];
    }else{
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        NSString *updateHtml = [richTextEditorVC getHTML];
        if (generalFlightDesk == nil) {
            generalFlightDesk = [NSEntityDescription insertNewObjectForEntityForName:@"GeneralFlightDesk" inManagedObjectContext:context];
            generalFlightDesk.gettingStart = @"";
            generalFlightDesk.termsOfUse = @"";
            generalFlightDesk.privacy = @"";
            generalFlightDesk.copyrightAndTradeMarks = @"";
        }
        
        switch (currentType) {
            case 1:
                generalFlightDesk.gettingStart = updateHtml;
                break;
            case 2:
                
                break;
            case 3:
                generalFlightDesk.termsOfUse = updateHtml;
                break;
            case 4:
                generalFlightDesk.privacy = updateHtml;
                break;
            case 5:
                generalFlightDesk.copyrightAndTradeMarks = updateHtml;
                break;
                
            default:
                break;
        }
        generalFlightDesk.lastUpdate = @0;
        [context save:&error];
        [self.view endEditing:YES];
        textEditorCV.hidden = YES;
        [richTextEditorVC willMoveToParentViewController:nil];  // 1
        [richTextEditorVC.view removeFromSuperview];            // 2
        [richTextEditorVC removeFromParentViewController];
        richTextEditorVC = nil;
        [[AppDelegate sharedDelegate] startThreadToSyncData:8];
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

#pragma mark HVTableViewDatasource
-(void)tableView:(UITableView *)tableView expandCell:(FaqsCell *)cell withIndexPath:(NSIndexPath *)indexPath{
    [UIView animateWithDuration:.5 animations:^{
        Faqs *faqs = [faqsArray objectAtIndex:indexPath.row];
        cell.lblAnswer.text = faqs.answer;
        cell.arrowImg.transform = CGAffineTransformMakeRotation(0);
    }];
    
}

-(void)tableView:(UITableView *)tableView collapseCell:(FaqsCell *)cell withIndexPath:(NSIndexPath *)indexPath{
    cell.arrowImg.transform = CGAffineTransformMakeRotation(0);
    Faqs *faqs = [faqsArray objectAtIndex:indexPath.row];
    cell.lblAnswer.text = faqs.answer;
    
    [UIView animateWithDuration:.5 animations:^{
        cell.arrowImg.transform = CGAffineTransformMakeRotation(-M_PI+0.00);
    }];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return faqsArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isExpanded
{
    static NSString *simpleTableIdentifier = @"FaqsItem";
    FaqsCell *faqsCell = (FaqsCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (faqsCell == nil) {
        faqsCell = [FaqsCell sharedCell];
    }
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        faqsCell.delegate = self;
        faqsCell.leftUtilityButtons = [self leftButtons];
        faqsCell.rightUtilityButtons = [self rightButtons];
    }
    
//    if (indexPath.row %2 ==1)
//        faqsCell.backgroundColor = [UIColor colorWithRed:.96 green:.96 blue:.96 alpha:1];
//    else
//        faqsCell.backgroundColor = [UIColor whiteColor];
    
    Faqs *faqs = [faqsArray objectAtIndex:indexPath.row];
    
    faqsCell.lblQuestion.text = faqs.question;
    
    if (!isExpanded) {
        faqsCell.lblAnswer.text = faqs.answer;
        faqsCell.arrowImg.transform = CGAffineTransformMakeRotation(M_PI);
    }
    else
    {
        faqsCell.lblAnswer.text = faqs.answer;
        faqsCell.arrowImg.transform = CGAffineTransformMakeRotation(0);
    }
    
    return faqsCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isexpanded
{
    if (isexpanded){
        Faqs *faqs = [faqsArray objectAtIndex:indexPath.row];
        UILabel *lblToGetHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, txtEditorDialog.frame.size.width-20, 50.0f)];
        lblToGetHeight.text = faqs.answer;
        lblToGetHeight.font = [UIFont fontWithName:@"Helvetica" size:13];
        CGFloat cellheight = [self getLabelHeight:lblToGetHeight] + 65.0f;
        if (cellheight > 70.0f) {
            return cellheight;
        }else{
            return 70;
        }
    }    
    return 70;
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
            NSIndexPath *indexPath = [FaqsTableView indexPathForCell:cell];
            faqsToEdit = [faqsArray objectAtIndex:indexPath.row];
            [[AppDelegate sharedDelegate] stopThreadToSyncData:8];
            isAddFaqs = YES;
            faqsAddView.hidden = NO;
            categoryDropDownMenu.hidden = YES;
            txtCategory.hidden = YES;
            txtQuestion.text = faqsToEdit.question;
            txtAnswer.text = faqsToEdit.answer;
            [btnSave setTitle:@"Update" forState:UIControlStateNormal];
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
            
            [[AppDelegate sharedDelegate] stopThreadToSyncData:8];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current Faqs?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                
                NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                NSError *error;
                NSIndexPath *indexPath = [FaqsTableView indexPathForCell:cell];
                Faqs *faqs = [faqsArray objectAtIndex:indexPath.row];
                [faqsArray removeObjectAtIndex:indexPath.row];
                [FaqsTableView deleteRowsAtIndexPaths:@[indexPath]
                                                withRowAnimation:UITableViewRowAnimationAutomatic];
                if ([faqs.faqs_id integerValue] != 0) {
                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                    deleteQuery.type = @"faqs";
                    deleteQuery.idToDelete = faqs.faqs_id;
                    [context save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                }
                
                [[AppDelegate sharedDelegate] startThreadToSyncData:8];
                
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                [[AppDelegate sharedDelegate] startThreadToSyncData:8];
            }];
            
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}
#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDownMenu) {
        return categoryArray.count;
    }
    
    return 0;
}

#pragma mark - MKDropdownMenuDelegate

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDownMenu) {
        return selectedCategory;
    }
    
    return @"";
}
- (nullable NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForComponent:(NSInteger)component{
    NSAttributedString *attrFortype= [[NSAttributedString alloc] initWithString:selectedCategory attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:17]}];
    return attrFortype;
}
- (nullable NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForSelectedComponent:(NSInteger)componen{
    NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:selectedCategory attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Helvetica" size:17] , NSForegroundColorAttributeName :[UIColor blackColor], NSBackgroundColorAttributeName : [UIColor clearColor] }];
    return attrForTextField;
}
- (BOOL)dropdownMenu:(MKDropdownMenu *)dropdownMenu shouldUseFullRowWidthForComponent:(NSInteger)component {
    return NO;
}
- (CGFloat)dropdownMenu:(MKDropdownMenu *)dropdownMenu rowHeightForComponent:(NSInteger)component {
    return 35.0f;
}
- (UIView *)dropdownMenu:(MKDropdownMenu *)dropdownMenu viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UIView *selectedView = view;
    if (selectedView == nil) {
        selectedView = [[UIView alloc] init];
    }
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont fontWithName:@"Helvetica" size:15];
    contentLabel.text = [categoryArray objectAtIndex:row];
    contentLabel.textAlignment = NSTextAlignmentLeft;
    [contentLabel setFrame:CGRectMake(10, 0, categoryDropDownMenu.frame.size.width-15, 35.0f)];
    [selectedView addSubview:contentLabel];
    return selectedView;
}
- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    selectedCategory = [categoryArray objectAtIndex:row];
    
    if (isAddFaqs) {
        if (row == categoryArray.count - 1) {
            [categoryDropDownMenu closeAllComponentsAnimated:YES];
            categoryDropDownMenu.hidden = YES;
            return;
        }
    }
    [categoryDropDownMenu closeAllComponentsAnimated:YES];
    [categoryDropDownMenu reloadAllComponents];
        
    [self getFaqs:selectedCategory];
}
- (void)getFaqs:(NSString *)category{
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSError *error;
    
    [faqsArray removeAllObjects];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Faqs" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", category];
    [request setPredicate:predicate];
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
    } else if (objects.count == 0) {
    } else {
        NSMutableArray *tempfaqs = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"question" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedfaqs = [tempfaqs sortedArrayUsingDescriptors:sortDescriptors];
        for (Faqs *faqs in sortedfaqs) {
            if (![faqsArray containsObject:faqs]) {
                [faqsArray addObject:faqs];
            }
        }
    }
    
    [FaqsTableView reloadData];
}
- (void)reloadFaqs{
    [self getCategories];
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
@end
