//
//  FreezingLevelViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "FreezingLevelViewController.h"
#import "CalcFreezingLevel+CoreDataClass.h"


#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"
@interface FreezingLevelViewController ()<UITextFieldDelegate>
{
    NSMutableArray *arrayFiles;
    NSInteger currentSelectedRow;
}

@end
typedef enum : NSUInteger {
    FREEZINGLEVEL = 19
    
} CalculationsMeasurement;
@implementation FreezingLevelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"FREEZING LEVEL";
    arrayFiles = [[NSMutableArray alloc] init];
    currentSelectedRow = -1;
    for (UIView *subView in self.containerView.subviews) {
        if (subView.subviews.count == 0){
            continue;
        }
        
        for (UIView *aView in subView.subviews) {
            if ([aView isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)aView;
                if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"SavedText"]==YES) {
                    textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"FL%ld",(long)textField.tag+10000]];
                }
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.delegate = self;
                textField.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                //[textField setValue:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forKeyPath:@"_placeholderLabel.textColor"];
                NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] }];
                textField.attributedPlaceholder = attrForTextField;
                textField.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                textField.layer.borderWidth = 1.0f;
                textField.layer.cornerRadius = 5.0f;
            }
            
            if ([aView isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)aView;
                button.layer.cornerRadius = 10;
                button.layer.borderWidth = 1;
                button.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                [button setTitleColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearText:) name:@"ClearText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveText:) name:@"SaveText" object:nil];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
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
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveText:nil];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getSavedFiles];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"FreezingLevelViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)clearText:(NSNotification *) notification {
    for (UIView *subView in self.containerView.subviews) {
        if (subView.subviews.count == 0){
            continue;
        }
        
        for (UIView *aView in subView.subviews) {
            if ([aView isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)aView;
                textField.text=@"";
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"FL%ld",(long)textField.tag+10000]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
}
-(void)saveText:(NSNotification *) notification {
    
    for (UIView *subView in self.containerView.subviews) {
        if (subView.subviews.count == 0){
            continue;
        }
        
        for (UITextField *textField in subView.subviews) {
            if ([textField isKindOfClass:[UITextField class]]) {
                
                [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"FL%ld",(long)textField.tag+10000]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SavedText"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
///-------------------------------------------------
#pragma mark - ActionMethods
///-------------------------------------------------
- (IBAction)clearFreezingLevel:(id)sender {
    ((UITextField *)[self.view viewWithTag:191]).text = @"";
    ((UITextField *)[self.view viewWithTag:192]).text = @"";
    [self clearText:nil];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}

///-------------------------------------------------
#pragma mark - KeyBoard Done Handler
///-------------------------------------------------
- (void)doneWithNumberPad{
    [self.view endEditing:YES];
}

///-------------------------------------------------
#pragma mark - UITextFieldDelegate Methods
///-------------------------------------------------
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if ([self.keyboardDelegate respondsToSelector:@selector(keyboardWillPresentForTextField:)]) {
        [self.keyboardDelegate keyboardWillPresentForTextField:textField];
    }
    
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.previousTextFieldTag=self.lastTextFieldTag;
    self.lastTextFieldTag=textField.tag;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.nameTextField) {
        return YES;
    }
    NSString *acceptableCharacter=ACCEPTABLE_CHARECTERS;
    if (textField.tag==122 || textField.tag==201 || textField.tag==101 || textField.tag==114) {
        acceptableCharacter=ACCEPTABLE_TIMECHARECTERS;
    }else if (textField.tag==143 || textField.tag==144 || textField.tag==162 || textField.tag==164 || textField.tag==181 || textField.tag==182 || textField.tag==191) {
        acceptableCharacter=ACCEPTABLE_TEMPCHARACTERS;
    }
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:acceptableCharacter] invertedSet];
    
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
    if ([acceptableCharacter isEqual:ACCEPTABLE_TEMPCHARACTERS]) {
        if (([string isEqualToString:@"."] || [string isEqualToString:@"-"] ) && range.length<1 ) {
            if ([string isEqualToString:@"."] && [textField.text containsString:@"."]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }else if ([string isEqualToString:@"-"] && [textField.text containsString:@"-"]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }
        }
    }
    if ([string isEqualToString:@"."] && range.length<1 && [textField.text containsString:@"."]) {
        finalString=[finalString substringToIndex:[finalString length]-1];
    }
    if ((textField.tag==142 || textField.tag==152 || textField.tag==163 )  ) {
        
        if ([finalString length]==2 && ![textField.text containsString:@"."] && ![string isEqualToString:@"."] && range.length<1) {
            finalString=[NSString stringWithFormat:@"%@.",finalString];
            
        }else if([finalString length]>5) {
            finalString =[finalString substringToIndex:5];
        }
    }else if (textField.tag==122 || textField.tag == 206 || textField.tag==101 || textField.tag==114) {
        if (([finalString length]==2|| [finalString length]==5)  && range.length<1) {
            if (![string isEqualToString:@":"]) {
                finalString=[NSString stringWithFormat:@"%@:",finalString];
                
            }
            
        }else if ([string isEqualToString:@":"] && range.length<1 ) {
            NSString *lastCharacter=[finalString substringFromIndex:[finalString length] - 1];
            if ([lastCharacter isEqualToString:string]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }
        }
        else if([finalString length]>8) {
            finalString =[finalString substringToIndex:8];
        }
    }
    
    
    double newValue=[finalString doubleValue];
    [self valueChangedInConversionTableForMeasurement:(textField.tag/10) forUnit:(textField.tag % 10) withNewValue:newValue Value:finalString];
    textField.text = finalString;
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

///-------------------------------------------------
#pragma mark - Measurement Calculations
///-------------------------------------------------

- (void)valueChangedInConversionTableForMeasurement:(CalculationsMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue Value:(NSString*)secondValue{
    switch (measurement) {
        case FREEZINGLEVEL:
            [self calculateFreezingLevelOnChangeInUnit:unitId toNewValue:newValue];
            
            break;
        default:
            break;
    }
}


-(void)calculateFreezingLevelOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *ftTextField = [self.view viewWithTag:192];
    UITextField *tempTextField = [self.view viewWithTag:191];
    double freezingTempratue = 0.00;
    double Tempratue = 0.00;
    switch (unitId) {
        case 1:
            freezingTempratue = (newValue/2)*1000;
            ftTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:freezingTempratue uptoDecimal:2]];
            break;
        case 2:
            Tempratue = (newValue*2)/1000;
            tempTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:Tempratue uptoDecimal:2]];
            break;
    }
}


///-------------------------------------------------
#pragma mark - Utility Methods
///-------------------------------------------------
-(void)displayAlertWithMessage:(NSString*)message {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@""
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    
    [alert addAction:ok];
    UIViewController *VC=[[AppDelegate sharedDelegate].window rootViewController];
    [VC presentViewController:alert animated:YES completion:nil];
}

- (double)getRoundedForValue:(double)value uptoDecimal:(int)decimalPlaces{
    int divisor = pow(10, decimalPlaces);
    NSLog(@"%.02f",roundf(value * divisor) / divisor);
    return roundf(value * divisor) / divisor;
}
-(BOOL)exist
{
    NSManagedObjectContext *managedObjectContext=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CalcFreezingLevel" inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setFetchLimit:1];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", self.nameTextField.text]];
    
    NSError *error = nil;
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&error];
    
    if (count)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}
- (IBAction)onSave:(id)sender {
    if ([self.nameTextField.text length]>0) {
        if (![self exist]) {
            
            NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcFreezingLevel" inManagedObjectContext:context];
            CalcFreezingLevel *calcFreezingLevel=[[CalcFreezingLevel alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            calcFreezingLevel.name=self.nameTextField.text;
            
            calcFreezingLevel.temp = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:191]).text doubleValue]];
            calcFreezingLevel.ft = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:192]).text doubleValue]];
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [arrayFiles addObject:calcFreezingLevel];
                self.nameTextField.text=@"";
            }
            currentSelectedRow = arrayFiles.count - 1;
            [self.SavedRecordTableView reloadData];
        }else {
            [self displayAlertWithMessage:@"File name already exist."];
        }
    }
    
}

- (IBAction)onClearAll:(id)sender {
    currentSelectedRow = -1;
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcFreezingLevel" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (CalcFreezingLevel *calcFreezingLevelToDelete in fetchedData) {
            [context deleteObject:calcFreezingLevelToDelete];
        }
    }
    [self.SavedRecordTableView reloadData];
}
- (void)getSavedFiles{
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcFreezingLevel" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        [arrayFiles addObjectsFromArray:[fetchedData mutableCopy]];
    }
    [self.SavedRecordTableView reloadData];
}
#pragma mark Table View Delegate Method
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [arrayFiles count];    //count number of row from counting array hear cataGorry is An Array
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"CalcFreezingLevelItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier];
    }
    
    CalcFreezingLevel *calcFreezingLevel=[arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.SavedRecordTableView.bounds.size.width, 28.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = calcFreezingLevel.name;
    
    saveTxt.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
    saveTxt.layer.borderWidth = 1.0f;
    saveTxt.backgroundColor = [UIColor whiteColor];
    saveTxt.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    saveTxt.layer.cornerRadius = 5.0f;
    if (currentSelectedRow == indexPath.row) {
        saveTxt.backgroundColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
        saveTxt.textColor = [UIColor whiteColor];
    }
    [cell.contentView addSubview:saveTxt];
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    currentSelectedRow = indexPath.row;
    CalcFreezingLevel *calcFreezingLevel=[arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:calcFreezingLevel];
    [self.SavedRecordTableView reloadData];
}
-(void)displayDetails:(CalcFreezingLevel*)calcFreezingLevel {
    ((UITextField *)[self.view viewWithTag:191]).text=[calcFreezingLevel.temp doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcFreezingLevel.temp doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:192]).text=[calcFreezingLevel.ft doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcFreezingLevel.ft doubleValue]]:@"";
    
}
@end
