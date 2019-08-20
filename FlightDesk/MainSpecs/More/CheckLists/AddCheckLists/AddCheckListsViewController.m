//
//  AddCheckListsViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddCheckListsViewController.h"

#import "AddRCell.h"
#import "AddGroupCheckListsCell.h"
#import "AddOtherCell.h"

@interface AddCheckListsViewController ()<UITableViewDelegate, UITableViewDataSource, MKDropdownMenuDelegate, MKDropdownMenuDataSource, AddRCellDelegate, AddGroupCheckListsCellDelegate, AddOtherCellDelegate, UIDocumentPickerDelegate>
{
    NSManagedObjectContext *contextRecords;
    
    NSMutableArray *arrayGroups;
    NSString *currentCategory;
    
    NSMutableArray *arrayAvailableCategories;
    NSMutableArray *arrayAvailableTypes;
    NSString *currentSelectedType;
    
    BOOL isShownKeyboard;
    NSMutableArray *tmpGropArray;
}
@end
#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define COLOR_STANDARD_CHECKLIST_BLUE_THEME RGBA(94, 156, 211, 1)
#define COLOR_STANDARD_CHECKLIST_GREEN_THEME RGBA(26, 175, 84, 1)
#define COLOR_STANDARD_CHECKLIST_SKY_THEME RGBA(30, 177, 237, 1)

#define COLOR_G1000_CHECKLIST_SKY_THEME RGBA(160, 255, 255, 1)
#define COLOR_G1000_CHECKLIST_RED_THEME RGBA(255, 126, 84, 1)
#define COLOR_G1000_CHECKLIST_GREEN_THEME RGBA(156, 222, 131, 1)
#define COLOR_G1000_CHECKLIST_ORANGE_THEME RGBA(255, 140, 0, 1)
@implementation AddCheckListsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    self.navigationItem.title = @"Adding Checklists";
    
    isShownKeyboard = NO;
    contextRecords = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    arrayGroups = [[NSMutableArray alloc] init];
    arrayAvailableCategories = [[NSMutableArray alloc] init];
    tmpGropArray = [[NSMutableArray alloc] init];
    
    ItemTableView.translatesAutoresizingMaskIntoConstraints = NO;
    
    arrayAvailableTypes = [[NSMutableArray alloc] initWithObjects:@"Group",@"Checklist", @"Warning", @"Notice", @"Title", @"P", @"C", @"R",  nil];
    currentSelectedType = @"Group";
    
    categoryDropDown.dataSource = self;
    categoryDropDown.delegate = self;
    
    TypeDropDown.delegate = self;
    TypeDropDown.dataSource = self;
    
    if (self.isImporedFromOther) {
        [self parseACEFileFromUrl:self.importedUrl];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
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
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!isShownKeyboard)
    {
        isShownKeyboard = YES;
        
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (isShownKeyboard)
    {
        [self.view endEditing:YES];
        isShownKeyboard = NO;
        
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    CGRect sizeRect = [UIScreen mainScreen].bounds;
    [navView setFrame:CGRectMake(0, 0, sizeRect.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    [self getCategoriesFromLocal];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"AddchecklistsviewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [navView removeFromSuperview];
}
- (void)getCategoriesFromLocal{
    [arrayAvailableCategories removeAllObjects];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentChecklistsID == 0"];
    [request setPredicate:predicate];
    NSArray *objects = [contextRecords executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Checklists!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid checklists found!");
    } else {
        for (Checklists *checklists in objects) {
            if (![arrayAvailableCategories containsObject:checklists.category]) {
                [arrayAvailableCategories addObject:checklists.category];
            }
        }
    }
    [arrayAvailableCategories addObject:@"- New Category -"];
    if (arrayAvailableCategories.count > 0) {
        currentCategory = [arrayAvailableCategories objectAtIndex:0];
        [categoryDropDown closeAllComponentsAnimated:YES];
        [categoryDropDown reloadAllComponents];
    }
}
- (IBAction)onBack:(id)sender {
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Do you want to save the current Checklists?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        [self saveCheckLists];
    }];
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onSave:(id)sender {
    [self saveCheckLists];
}

- (IBAction)onAddItem:(id)sender {
    NSMutableDictionary *oneItem = [[NSMutableDictionary alloc] init];
    [oneItem setObject:@"" forKey:@"content"];
    if ([currentSelectedType isEqualToString:@"Group"]) {
        [oneItem setObject:@"group" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"Checklist"]) {
        [oneItem setObject:@"checklist" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"Warning"]) {
        [oneItem setObject:@"w0" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"Notice"]) {
        [oneItem setObject:@"n0" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"Title"]) {
        [oneItem setObject:@"t0" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"P"]) {
        [oneItem setObject:@"p0" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"C"]) {
        [oneItem setObject:@"c0" forKey:@"type"];
    }else if ([currentSelectedType isEqualToString:@"R"]) {
        [oneItem setObject:@"r0" forKey:@"type"];
    }
    if (tmpGropArray.count == arrayGroups.count) {
        [tmpGropArray addObject:oneItem];
    }
    [arrayGroups addObject:oneItem];
    
    [ItemTableView reloadData];
    [self scrollToBottom:YES];
    
}
-(void)scrollToBottom : (BOOL)_animated
{
    CGFloat yoffset = 64;
    if (ItemTableView.contentSize.height > ItemTableView.bounds.size.height) {
        yoffset = ItemTableView.contentSize.height - ItemTableView.bounds.size.height;
        [ItemTableView setContentOffset:CGPointMake(0, yoffset) animated:_animated];
    }
    
}
#pragma mark UIDocumentPickerDelgate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    NSString *fileName = [url lastPathComponent];
    NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
    NSError* error = nil;
    NSURLResponse* response = nil;
    [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
    NSString* mimeType = [response MIMEType];
    NSArray *parseFileName = [mimeType componentsSeparatedByString:@"/"];
    if (parseFileName.count > 1) {
        NSString *lastString = parseFileName[parseFileName.count-1];
        if ([lastString.lowercaseString isEqualToString:@"octet-stream"]) {
            [self parseACEFileFromUrl:url];
        }
    }
}
- (IBAction)onParsingAce:(id)sender {
    
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
- (void)parseACEFileFromUrl:(NSURL *)fileUrl{
    
    [arrayGroups removeAllObjects];
    [tmpGropArray removeAllObjects];
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"ChklistTurbo" ofType:@"ace"];
    NSData *dataOfACE = [NSData dataWithContentsOfURL:fileUrl];
    NSString *strToParseAceData = [[NSString alloc] initWithData:dataOfACE encoding:NSMacOSRomanStringEncoding];
    strToParseAceData = [strToParseAceData stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    NSMutableArray *arrayToParseWithLine = [[strToParseAceData componentsSeparatedByString:@"\n"] mutableCopy];
    
    NSString *category = @"";
    [arrayToParseWithLine removeObjectAtIndex:0];
    for (NSString *oneToLine in arrayToParseWithLine) {
        if (![oneToLine hasPrefix:@"<0"]) {
            if ([category isEqualToString:@""]) {
                category = [NSString stringWithFormat:@"%@", oneToLine];
            }else{
                category = [NSString stringWithFormat:@"%@\n%@", category, oneToLine];
            }
        }else{
            break;
        }
    }
    
    categoryDropDown.hidden = YES;
    categoryTxtView.text = category;
    
    for (NSString *oneToLine in arrayToParseWithLine) {
        NSMutableDictionary *oneItem = [[NSMutableDictionary alloc] init];
        if ([oneToLine hasPrefix:@"<0"]) {
            [oneItem setObject:[oneToLine substringFromIndex:2] forKey:@"content"];
            [oneItem setObject:@"group" forKey:@"type"];
            [arrayGroups addObject:oneItem];
        }else if ([oneToLine hasPrefix:@"(0"]){
            [oneItem setObject:[oneToLine substringFromIndex:2] forKey:@"content"];
            [oneItem setObject:@"checklist" forKey:@"type"];
            [arrayGroups addObject:oneItem];
        }else{
            if (oneToLine.length > 2) {
                if ( [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:[oneToLine characterAtIndex:0]]) {
                    [oneItem setObject:[oneToLine substringFromIndex:2] forKey:@"content"];
                    [oneItem setObject:[oneToLine substringToIndex:2] forKey:@"type"];
                    [arrayGroups addObject:oneItem];
                }
            }
        }
    }
    
    if (tmpGropArray.count < arrayGroups.count) {
        NSInteger currentCourse = tmpGropArray.count;
        int count = 0;
        for (int i = currentCourse; i < arrayGroups.count; i ++) {
            [tmpGropArray addObject:[arrayGroups objectAtIndex:i]];
            count = count +1;
            if (count == 30) {
                break;
            }
        }
    }
    
    [ItemTableView reloadData];
}
- (CGFloat)getLabelHeight:(UITextView*)txtView
{
    CGSize constraint = CGSizeMake(txtView.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [txtView.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:txtView.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height;
}
- (CGFloat)widthOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return tmpGropArray.count;//arrayGroups.count;
    //return arrayChecklistsContents.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *checklistsContent = [tmpGropArray objectAtIndex:indexPath.row];
    NSString *type = [checklistsContent objectForKey:@"type"];
    if ([type.lowercaseString isEqualToString:@"group"] || [type.lowercaseString isEqualToString:@"checklist"]) {
        return 44.0f;
    }else{
        NSString *preType = @"";
        if (type.length>1) {
           preType = [type substringToIndex:1];
        }
        if ([preType.lowercaseString isEqualToString:@"r"]) {
            return 44.0f;
        }
        UITextView *lblToGetHeight = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ItemTableView.frame.size.width, 50.0f)];
        lblToGetHeight.text = [checklistsContent objectForKey:@"content"];
        if ([lblToGetHeight.text isEqualToString:@""]) {
            return 60.0f;
        }
        return [self getLabelHeight:lblToGetHeight] + 30.0f;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *checklistsContent = [tmpGropArray objectAtIndex:indexPath.row];
    
    NSString *type = [checklistsContent objectForKey:@"type"];
    NSString *content = [checklistsContent objectForKey:@"content"];
    
    NSString *preType = @"";
    NSString *depth = @"";
    if (type.length>1) {
        preType = [type substringToIndex:1];
        depth = [type substringFromIndex:1];
    }
    
    if ([preType.lowercaseString isEqualToString:@"r"]) {
        static NSString *simpleTableIdentifier = @"AddRItem";
        AddRCell *cell = (AddRCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [AddRCell sharedCell];
        }
        cell.delegate = self;
        cell.preContentTxtField.delegate = cell;
        cell.tailContentTxtField.delegate = cell;
        NSArray *parseContentArray = [content componentsSeparatedByString:@"~"];
        if (parseContentArray.count ==1) {
            cell.preContentTxtField.text = parseContentArray[0];
        }else if (parseContentArray.count == 2) {
            cell.preContentTxtField.text = parseContentArray[0];
            cell.tailContentTxtField.text = parseContentArray[1];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lblR.text = type.uppercaseString;
        cell.paddingLeftLBLConstraints.constant = 15.0f * [depth integerValue] + 30.0f;
        
        return cell;
    }else if ([type.lowercaseString isEqualToString:@"group"] || [type.lowercaseString isEqualToString:@"checklist"]){
        static NSString *simpleTableIdentifier = @"AddGroupCheckListsItem";
        AddGroupCheckListsCell *cell = (AddGroupCheckListsCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [AddGroupCheckListsCell sharedCell];
        }
        cell.delegate = self;
        cell.groupChecklistTxtField.delegate = cell;
        cell.groupChecklistTxtField.text = content;
        if ([type.lowercaseString isEqualToString:@"group"]) {
            cell.paddingLeftContriants.constant = 0;
            cell.lblGroupCheckLists.text = @"Group:";
        }else{
            cell.paddingLeftContriants.constant = 15.0f;
            cell.lblGroupCheckLists.text = @"CheckList:";
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }else {
        static NSString *simpleTableIdentifier = @"AddOtherItem";
        AddOtherCell *cell = (AddOtherCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil) {
            cell = [AddOtherCell sharedCell];
        }
        cell.delegate = self;
        cell.contentTxtView.delegate = cell;
        cell.contentTxtView.text = content;
        //cell.contentHeightConstraints.constant = [self getLabelHeight:cell.contentTxtView] + 30.0f;
        cell.paddingLeftContraints.constant= 15.0f * [depth integerValue] + 30.0f;
        
        if ([preType.lowercaseString isEqualToString:@"n"]){
            cell.contentTxtView.textColor = COLOR_G1000_CHECKLIST_ORANGE_THEME;
        }else if ([preType.lowercaseString isEqualToString:@"p"]){
            cell.contentTxtView.textColor = [UIColor grayColor];
        }else if ([preType.lowercaseString isEqualToString:@"t"]){
            cell.contentTxtView.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:16];
        }else if ([preType.lowercaseString isEqualToString:@"w"]){
            cell.contentTxtView.textColor = COLOR_G1000_CHECKLIST_RED_THEME;
        }else{
            cell.contentTxtView.textColor = [UIColor darkGrayColor];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lblOther.text = type.uppercaseString;
        return cell;
    }
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
//- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section{
//    [FootBarToAddItem setFrame:CGRectMake(0, 0, ItemTableView.frame.size.width, 50.0f)];
//    [view addSubview:FootBarToAddItem];
//}
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    return 50.0f;
//}
#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDown) {
        return arrayAvailableCategories.count;
    }else{
        return arrayAvailableTypes.count;
    }
}

#pragma mark - MKDropdownMenuDelegate

//- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
//    if (dropdownMenu == categoryDropDown) {
//        return currentCategory;
//    }else{
//        return currentSelectedType;
//    }
//    
//    return @"";
//}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDown) {
        return [arrayAvailableCategories objectAtIndex:row];
    }else{
        return [arrayAvailableTypes objectAtIndex:row];
    }
}

- (BOOL)dropdownMenu:(MKDropdownMenu *)dropdownMenu shouldUseFullRowWidthForComponent:(NSInteger)component {
    return NO;
}
- (nullable NSAttributedString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu attributedTitleForComponent:(NSInteger)component{
    NSString *strSelected = @"";
    if (dropdownMenu == categoryDropDown) {
        strSelected =  @"";
    }else{
        strSelected =  currentSelectedType;
    }
    NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:strSelected attributes:@{ NSFontAttributeName : [UIFont fontWithName:@"TimesNewRomanPSMT" size:16], NSForegroundColorAttributeName :[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] , NSBackgroundColorAttributeName : [UIColor clearColor]}];
    return attrForTextField;
}
- (CGFloat)dropdownMenu:(MKDropdownMenu *)dropdownMenu rowHeightForComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDown) {
        return 80.0f;
    }
    return 30.0f;
}
- (UIView *)dropdownMenu:(MKDropdownMenu *)dropdownMenu viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UIView *selectedView = view;
    if (selectedView == nil) {
        selectedView = [[UIView alloc] init];
    }
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.font = [UIFont fontWithName:@"TimesNewRomanPSMT" size:16];
    if (dropdownMenu == categoryDropDown) {
        contentLabel.text =  [arrayAvailableCategories objectAtIndex:row];
        [contentLabel setFrame:CGRectMake(10, 0, categoryDropDown.frame.size.width, 80.0f)];
    }else{
        contentLabel.text = [arrayAvailableTypes objectAtIndex:row];;
        [contentLabel setFrame:CGRectMake(10, 0,TypeDropDown.frame.size.width, 30.0f)];
    }
    [contentLabel setBackgroundColor:[UIColor clearColor]];
    contentLabel.numberOfLines = 0;
    
    [selectedView addSubview:contentLabel];
    
    return selectedView;
    
}

- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (dropdownMenu == categoryDropDown) {
        currentCategory = [arrayAvailableCategories objectAtIndex:row];
        
        [categoryDropDown closeAllComponentsAnimated:YES];
        [categoryDropDown reloadAllComponents];
        categoryTxtView.text = currentCategory;
        
        if ([currentCategory isEqualToString:@"- New Category -"]) {
            categoryDropDown.hidden = YES;
            categoryTxtView.text = @"";
            [categoryTxtView becomeFirstResponder];
        }
        
        
    }else{
        currentSelectedType = [arrayAvailableTypes objectAtIndex:row];
        
        [TypeDropDown closeAllComponentsAnimated:YES];
        [TypeDropDown reloadAllComponents];
    }
}

#pragma mrak AddRCellDelegate
- (void)didAddedItemFromRCell:(AddRCell *)_cell withType:(NSString *)_type{
    NSIndexPath *indePath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *oneItem = [[NSMutableDictionary alloc] init];
    [oneItem setObject:@"" forKey:@"content"];
    [oneItem setObject:_type forKey:@"type"];
    [arrayGroups insertObject:oneItem atIndex:indePath.row+1];
    [tmpGropArray insertObject:oneItem atIndex:indePath.row+1];
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:indePath.row + 1 inSection:0]];
    [ItemTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
}
- (void)updatedContentFromRCell:(AddRCell *)_cell withContent:(NSString *)_content{
    NSIndexPath *currentIndexPath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *itemToUpdate = [arrayGroups objectAtIndex:currentIndexPath.row];
    [itemToUpdate setObject:_content forKey:@"content"];
    [arrayGroups replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdate];

    NSMutableDictionary *itemToUpdateTmp = [tmpGropArray objectAtIndex:currentIndexPath.row];
    [itemToUpdateTmp setObject:_content forKey:@"content"];
    [tmpGropArray replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdateTmp];
}
#pragma mrak AddGroupCheckListsCellDelegate
- (void)didAddedItemFromGroupCheckCell:(AddGroupCheckListsCell *)_cell withType:(NSString *)_type{
    NSIndexPath *indePath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *oneItem = [[NSMutableDictionary alloc] init];
    [oneItem setObject:@"" forKey:@"content"];
    [oneItem setObject:_type forKey:@"type"];
    [arrayGroups insertObject:oneItem atIndex:indePath.row+1];
    [tmpGropArray insertObject:oneItem atIndex:indePath.row+1];
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:indePath.row + 1 inSection:0]];
    [ItemTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
}
- (void)updateContentFromGroupCheckCell:(AddGroupCheckListsCell *)_cell withContent:(NSString *)_content{
    NSIndexPath *currentIndexPath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *itemToUpdate = [arrayGroups objectAtIndex:currentIndexPath.row];
    [itemToUpdate setObject:_content forKey:@"content"];
    [arrayGroups replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdate];
    
    NSMutableDictionary *itemToUpdateTmp = [tmpGropArray objectAtIndex:currentIndexPath.row];
    [itemToUpdateTmp setObject:_content forKey:@"content"];
    [tmpGropArray replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdateTmp];
}
#pragma mrak AddRCellDelegate
- (void)didAddedOneItemFromOtherCell:(AddOtherCell *)_cell withType:(NSString *)_type{
    NSIndexPath *indePath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *oneItem = [[NSMutableDictionary alloc] init];
    [oneItem setObject:@"" forKey:@"content"];
    [oneItem setObject:_type forKey:@"type"];
    [arrayGroups insertObject:oneItem atIndex:indePath.row+1];
    [tmpGropArray insertObject:oneItem atIndex:indePath.row+1];
    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:indePath.row + 1 inSection:0]];
    [ItemTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
}
- (void)updateContentFromOtherCell:(AddOtherCell *)_cell withContent:(NSString *)_content{
    NSIndexPath *currentIndexPath = [ItemTableView indexPathForCell:_cell];
    NSMutableDictionary *itemToUpdate = [arrayGroups objectAtIndex:currentIndexPath.row];
    [itemToUpdate setObject:_content forKey:@"content"];
    [arrayGroups replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdate];
    
    NSMutableDictionary *itemToUpdateTmp = [tmpGropArray objectAtIndex:currentIndexPath.row];
    [itemToUpdateTmp setObject:_content forKey:@"content"];
    [tmpGropArray replaceObjectAtIndex:currentIndexPath.row withObject:itemToUpdateTmp];
}

- (void)saveCheckLists{
    if (!categoryTxtView.text.length)
    {
        [self showAlert:@"Please input Category" :@"Input Error"];
        return;
    }
    if (arrayGroups.count == 0) {
        [self showAlert:@"You have to add one item at least" :@"Input Error"];
        return;
    }
    [self.view endEditing:YES];
    
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Checklists" inManagedObjectContext:contextRecords];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category = %@", categoryTxtView.text];
    [request setPredicate:predicate];
    NSArray *fetchedChecklists = [contextRecords executeFetchRequest:request error:&error];
    
    
    if (fetchedChecklists == nil) {
        FDLogError(@"Skipped checklists update since there was an error checking for existing checklists!");
    } else if (fetchedChecklists.count == 0) {
        
        NSString *currentGroups = @"";
        Checklists *currentCheckListEntity = nil;
        
        NSNumber *focusParentChecklistID;
        for (NSDictionary *oneItem in arrayGroups) {
            NSString *itemContent = [oneItem objectForKey:@"content"];
            NSString *itemType = [oneItem objectForKey:@"type"];
            
            NSString *preType = @"";
            NSString *depth = @"";
            if (itemType.length>1) {
                preType = [itemType substringToIndex:1];
                depth = [itemType substringFromIndex:1];
            }
            if ([itemType isEqualToString:@"group"]) {
                Checklists *newChecklistEntityForGroup = [NSEntityDescription insertNewObjectForEntityForName:@"Checklists" inManagedObjectContext:contextRecords];
                newChecklistEntityForGroup.checklistsID = @0;
                newChecklistEntityForGroup.category = categoryTxtView.text;
                newChecklistEntityForGroup.groupChecklist = itemContent;
                newChecklistEntityForGroup.checklist = @"";
                newChecklistEntityForGroup.warning = @"";
                newChecklistEntityForGroup.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                newChecklistEntityForGroup.parentChecklistsID = @0;
                newChecklistEntityForGroup.lastUpdate = @0;
                newChecklistEntityForGroup.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                newChecklistEntityForGroup.checklistsLocalId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                focusParentChecklistID = newChecklistEntityForGroup.checklistsLocalId;
                currentGroups = itemContent;
            }else if ([itemType isEqualToString:@"checklist"]){
                Checklists *newChecklistEntityForChecklist = [NSEntityDescription insertNewObjectForEntityForName:@"Checklists" inManagedObjectContext:contextRecords];
                newChecklistEntityForChecklist.checklistsID = @0;
                newChecklistEntityForChecklist.category = categoryTxtView.text;
                newChecklistEntityForChecklist.groupChecklist = currentGroups;
                newChecklistEntityForChecklist.checklist = itemContent;
                newChecklistEntityForChecklist.warning = @"";
                newChecklistEntityForChecklist.userID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
                newChecklistEntityForChecklist.parentChecklistsID = focusParentChecklistID;
                newChecklistEntityForChecklist.lastUpdate = @0;
                newChecklistEntityForChecklist.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                newChecklistEntityForChecklist.checklistsLocalId = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                
                currentCheckListEntity = newChecklistEntityForChecklist;
            }
            else {
                ChecklistsContent *checklistContent = [NSEntityDescription insertNewObjectForEntityForName:@"ChecklistsContent" inManagedObjectContext:contextRecords];
                checklistContent.checklistContentID = @0;
                checklistContent.isChecked = @0;
                if ([preType isEqualToString:@"r"]) {
                    NSArray *parseContent = [itemContent componentsSeparatedByString:@"~"];
                    if (parseContent.count > 1) {
                        checklistContent.content = parseContent[0];
                        checklistContent.contentTail = parseContent[1];
                    }else{
                        checklistContent.content = itemContent;
                        checklistContent.contentTail = @"";
                    }
                }else{
                    checklistContent.content = itemContent;
                    checklistContent.contentTail = @"";
                }
                checklistContent.checklistID = currentCheckListEntity.checklistsLocalId;
                checklistContent.ordering = @(currentCheckListEntity.checklists.count+1);
                checklistContent.type = itemType;
                
                [currentCheckListEntity addChecklistsObject:checklistContent];
            }
        }
    } else if (fetchedChecklists.count == 1) {
        
    } else if (fetchedChecklists.count > 1) {
        
    }
    
    [contextRecords save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    NSString *message = @"Saved!";
    if (self.isImporedFromOther) {
        message = @"Saved!\nYou can find checklists from 'More->Checklists'";
    }
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
    
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
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    float endScrolling = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (endScrolling >= scrollView.contentSize.height)
    {
        NSLog(@"Scroll End Called");
        if (tmpGropArray.count < arrayGroups.count) {
            if (tmpGropArray.count < arrayGroups.count) {
                NSInteger currentCourse = tmpGropArray.count;
                int count = 0;
                for (int i = currentCourse; i < arrayGroups.count; i ++) {
                    [tmpGropArray addObject:[arrayGroups objectAtIndex:i]];
                    count = count +1;
                    if (count == 30) {
                        break;
                    }
                }
            }
            [ItemTableView reloadData];
            
        }
    }
}
// parsing sample
//    NSInteger currentGroupPosition = -1;
//    NSInteger currentChecklistsPosition = -1;
//    for (NSString *oneToLine in arrayToParseWithLine) {
//        if ([oneToLine hasPrefix:@"<0"]) {
//            currentGroupPosition = currentGroupPosition + 1;
//            currentChecklistsPosition = -1;
//            NSMutableDictionary *oneGroup = [[NSMutableDictionary alloc] init];
//            [oneGroup setObject:[oneToLine substringFromIndex:2] forKey:@"group"];
//            [arrayGroups addObject:oneGroup];
//        }
//        else if ([oneToLine hasPrefix:@"(0"]){
//            currentChecklistsPosition = currentChecklistsPosition + 1;
//            NSMutableDictionary *oneGroupToUpdate = [arrayGroups objectAtIndex:currentGroupPosition];
//            if ([oneGroupToUpdate objectForKey:@"checklists"]) {
//                NSMutableArray *checklistsToUpdate = [oneGroupToUpdate objectForKey:@"checklists"];
//                NSMutableDictionary *newOneCheckLists = [[NSMutableDictionary alloc] init];
//                [newOneCheckLists setObject:[oneToLine substringFromIndex:2] forKey:@"checklist"];
//                [checklistsToUpdate addObject:newOneCheckLists];
//
//                [oneGroupToUpdate setObject:checklistsToUpdate forKey:@"checklists"];
//                [arrayGroups replaceObjectAtIndex:currentGroupPosition withObject:oneGroupToUpdate];
//            }else{
//                NSMutableArray *checklistsToUpdate = [[NSMutableArray alloc] init];
//                NSMutableDictionary *newOneCheckLists = [[NSMutableDictionary alloc] init];
//                [newOneCheckLists setObject:[oneToLine substringFromIndex:2] forKey:@"checklist"];
//                [checklistsToUpdate addObject:newOneCheckLists];
//
//                [oneGroupToUpdate setObject:checklistsToUpdate forKey:@"checklists"];
//                [arrayGroups replaceObjectAtIndex:currentGroupPosition withObject:oneGroupToUpdate];
//            }
//        }
//        else {
//            // check if first character is lower case
//            if (oneToLine.length != 0) {
//                if ( [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:[oneToLine characterAtIndex:0]]) {
//                    NSMutableDictionary *oneGroupToUpdate = [arrayGroups objectAtIndex:currentGroupPosition];
//                    if ([oneGroupToUpdate objectForKey:@"checklists"]) {
//                        NSMutableArray *checklistsToUpdate = [oneGroupToUpdate objectForKey:@"checklists"];
//                        NSMutableDictionary *oneCheckListsToUpdate = [checklistsToUpdate objectAtIndex:currentChecklistsPosition];
//                        if ([oneCheckListsToUpdate objectForKey:@"contents"]) {
//                            NSMutableArray *arrayContentToUpdate = [oneCheckListsToUpdate objectForKey:@"contents"];
//                            NSMutableDictionary *newContent = [[NSMutableDictionary alloc] init];
//
//                            for (int i = 0; i < [oneToLine length]; i++) {
//                                if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[oneToLine characterAtIndex:i]]) {
//                                    [newContent setObject:[oneToLine substringFromIndex:i] forKey:@"content"];
//                                    [newContent setObject:[oneToLine substringToIndex:1] forKey:@"type"];
//                                    [arrayContentToUpdate addObject:newContent];
//                                    break;
//                                }
//                            }
//
//                            [oneCheckListsToUpdate setObject:arrayContentToUpdate forKey:@"contents"];
//                            [checklistsToUpdate replaceObjectAtIndex:currentChecklistsPosition withObject:oneCheckListsToUpdate];
//                            [oneGroupToUpdate setObject:checklistsToUpdate forKey:@"checklists"];
//                            [arrayGroups replaceObjectAtIndex:currentGroupPosition withObject:oneGroupToUpdate];
//                        }else{
//                            NSMutableArray *arrayContentToUpdate = [[NSMutableArray alloc] init];
//                            NSMutableDictionary *newContent = [[NSMutableDictionary alloc] init];
//
//                            for (int i = 0; i < [oneToLine length]; i++) {
//                                if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[oneToLine characterAtIndex:i]]) {
//                                    [newContent setObject:[oneToLine substringFromIndex:i] forKey:@"content"];
//                                    [newContent setObject:[oneToLine substringToIndex:1] forKey:@"type"];
//                                    [arrayContentToUpdate addObject:newContent];
//                                    break;
//                                }
//                            }
//
//                            [oneCheckListsToUpdate setObject:arrayContentToUpdate forKey:@"contents"];
//                            [checklistsToUpdate replaceObjectAtIndex:currentChecklistsPosition withObject:oneCheckListsToUpdate];
//                            [oneGroupToUpdate setObject:checklistsToUpdate forKey:@"checklists"];
//                            [arrayGroups replaceObjectAtIndex:currentGroupPosition withObject:oneGroupToUpdate];
//                        }
//                    }else{
//                        NSMutableArray *checklistsToUpdate = [[NSMutableArray alloc] init];
//                        NSMutableDictionary *oneCheckListsToUpdate = [checklistsToUpdate objectAtIndex:currentChecklistsPosition];
//                        NSMutableArray *arrayContentToUpdate = [[NSMutableArray alloc] init];
//                        NSMutableDictionary *newContent = [[NSMutableDictionary alloc] init];
//
//                        for (int i = 0; i < [oneToLine length]; i++) {
//                            if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[oneToLine characterAtIndex:i]]) {
//                                [newContent setObject:[oneToLine substringFromIndex:i] forKey:@"content"];
//                                [newContent setObject:[oneToLine substringToIndex:1] forKey:@"type"];
//                                [arrayContentToUpdate addObject:newContent];
//                                break;
//                            }
//                        }
//
//                        [oneCheckListsToUpdate setObject:arrayContentToUpdate forKey:@"contents"];
//                        [checklistsToUpdate replaceObjectAtIndex:currentChecklistsPosition withObject:oneCheckListsToUpdate];
//                        [oneGroupToUpdate setObject:checklistsToUpdate forKey:@"checklists"];
//                        [arrayGroups replaceObjectAtIndex:currentGroupPosition withObject:oneGroupToUpdate];
//                    }
//                }
//            }
//
//
//        }
//    }
@end
