//
//  WindViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "WindViewController.h"
#import "CalcWind+CoreDataClass.h"


#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"
@interface WindViewController ()<UITextFieldDelegate>
{
    NSMutableArray *arrayFiles;
    NSInteger currentSelectedRow;
}
@end
typedef enum : NSUInteger {
    WIND = 10
    
} CalculationsMeasurement;
@implementation WindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WIND";
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
                    textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"WIN%ld",(long)textField.tag+10000]];
                }
                
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.delegate = self;
                if (textField.isUserInteractionEnabled) {
                    textField.textColor=[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                    //[textField setValue:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forKeyPath:@"_placeholderLabel.textColor"];
                    NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] }];
                    textField.attributedPlaceholder = attrForTextField;
                    textField.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                    textField.layer.borderWidth = 1.0f;
                    textField.layer.cornerRadius = 5.0f;
                }else
                    textField.textColor=[UIColor blackColor];
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
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"WindViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    [self getSavedFiles];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveText:nil];
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
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"WIN%ld",(long)textField.tag+10000]];
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
                
                [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"WIN%ld",(long)textField.tag+10000]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SavedText"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (IBAction)onWindClear:(id)sender {
    ((UITextField *)[self.view viewWithTag:101]).text = @"";
    ((UITextField *)[self.view viewWithTag:102]).text = @"";
    ((UITextField *)[self.view viewWithTag:103]).text = @"";
    ((UITextField *)[self.view viewWithTag:104]).text = @"";
    ((UITextField *)[self.view viewWithTag:105]).text = @"";
    ((UITextField *)[self.view viewWithTag:106]).text = @"";
    ((UITextField *)[self.view viewWithTag:107]).text = @"";
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
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *acceptableCharacter=ACCEPTABLE_CHARECTERS;
    
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:acceptableCharacter] invertedSet];
    
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
    
    if ([textField.text containsString:@"."] && [string isEqualToString:@"."] && range.length<1) {
        finalString=[finalString substringToIndex:[finalString length] - 1];
    }
    double newValue=[finalString doubleValue];
    
    textField.text = finalString;
    [self valueChangedInConversionTableForMeasurement:10 forUnit:(textField.tag % 10) withNewValue:newValue];
    
    return NO;
}
///-------------------------------------------------
#pragma mark - Measurement Calculations
///-------------------------------------------------

- (void)valueChangedInConversionTableForMeasurement:(CalculationsMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue{
    switch (measurement) {
        case WIND:
            [self calculateWIndChangeInUnit:unitId toNewValue:newValue];
            break;
        default:
            break;
    }
}
- (void)calculateWIndChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *windDirectioinTextField = [self.view viewWithTag:101];
    UITextField *windSpeedTextField = [self.view viewWithTag:102];
    UITextField *trueAirSpeedTextField = [self.view viewWithTag:103];
    UITextField *courseTextField = [self.view viewWithTag:104];
    
    UITextField *headingTextField = [self.view viewWithTag:105];
    UITextField *groundSpeedTextField = [self.view viewWithTag:106];
    UITextField *wcaTextField = [self.view viewWithTag:107];
    
    if (windDirectioinTextField.text.length != 0 && windSpeedTextField.text.length != 0 && trueAirSpeedTextField.text.length != 0 && courseTextField.text.length != 0) {
        float temp= [windDirectioinTextField.text floatValue]-[courseTextField.text floatValue];
        float radian=temp*M_PI/180;
        float digreeInSin=sin(radian);
        float h12I12= [windSpeedTextField.text floatValue]/[trueAirSpeedTextField.text floatValue];
        float finalFloat=asin(h12I12*digreeInSin);
        if (!isnan(finalFloat)) {
            wcaTextField.text=[NSString stringWithFormat:@"%.03f", [self getRoundedForValue:finalFloat * 180 / M_PI uptoDecimal:3]];
        }
        /** TH Calculation **/
        float aswer=[courseTextField.text floatValue]+[wcaTextField.text floatValue];
        headingTextField.text=[NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:aswer uptoDecimal:0]];
        
        float cosResult = windSpeedTextField.text.floatValue* cos(M_PI*(windDirectioinTextField.text.floatValue - courseTextField.text.floatValue)/180);
        float powResult = powf(((windSpeedTextField.text.floatValue/trueAirSpeedTextField.text.floatValue) *sin(M_PI*(windDirectioinTextField.text.floatValue - courseTextField.text.floatValue)/180)), 2.0);
        float estOutput = [trueAirSpeedTextField.text floatValue]*sqrt(1-powResult)-cosResult;
        if (!isnan(estOutput)) {
            groundSpeedTextField.text = [NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:estOutput uptoDecimal:0]];
        }
    }
}
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CalcWind" inManagedObjectContext:managedObjectContext];
    
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
- (IBAction)onSAve:(id)sender {
    if ([self.nameTextField.text length]>0) {
        if (![self exist]) {
            
            NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcWind" inManagedObjectContext:context];
            CalcWind *calcWind=[[CalcWind alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            calcWind.name=self.nameTextField.text;
            
            calcWind.windDirection = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:101]).text doubleValue]];
            calcWind.windSpeed = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:102]).text doubleValue]];
            calcWind.trueAirSpeed = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:103]).text doubleValue]];
            calcWind.course = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:104]).text doubleValue]];
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [arrayFiles addObject:calcWind];
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
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcWind" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (CalcWind *calcWindToDelete in fetchedData) {
            [context deleteObject:calcWindToDelete];
        }
    }
    [self.SavedRecordTableView reloadData];
}
- (void)getSavedFiles{
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcWind" inManagedObjectContext:context];
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
    static NSString *MyIdentifier = @"CalcWindItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier];
    }
    
    CalcWind *calcWind=[arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.SavedRecordTableView.bounds.size.width, 28.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = calcWind.name;
    
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
    CalcWind *calcWind=[arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:calcWind];
    [self.SavedRecordTableView reloadData];
}
-(void)displayDetails:(CalcWind*)calcWind {
    ((UITextField *)[self.view viewWithTag:101]).text=[calcWind.windDirection doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcWind.windDirection doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:102]).text=[calcWind.windSpeed doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcWind.windSpeed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:103]).text=[calcWind.trueAirSpeed doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcWind.trueAirSpeed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:104]).text=[calcWind.course doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcWind.course doubleValue]]:@"";
    
    UITextField *windDirectioinTextField = [self.view viewWithTag:101];
    UITextField *windSpeedTextField = [self.view viewWithTag:102];
    UITextField *trueAirSpeedTextField = [self.view viewWithTag:103];
    UITextField *courseTextField = [self.view viewWithTag:104];
    
    UITextField *headingTextField = [self.view viewWithTag:105];
    UITextField *groundSpeedTextField = [self.view viewWithTag:106];
    UITextField *wcaTextField = [self.view viewWithTag:107];
    
    if (windDirectioinTextField.text.length != 0 && windSpeedTextField.text.length != 0 && trueAirSpeedTextField.text.length != 0 && courseTextField.text.length != 0) {
        float temp= [windDirectioinTextField.text floatValue]-[courseTextField.text floatValue];
        float radian=temp*M_PI/180;
        float digreeInSin=sin(radian);
        float h12I12= [windSpeedTextField.text floatValue]/[trueAirSpeedTextField.text floatValue];
        float finalFloat=asin(h12I12*digreeInSin);
        if (!isnan(finalFloat)) {
            wcaTextField.text=[NSString stringWithFormat:@"%.03f", [self getRoundedForValue:finalFloat * 180 / M_PI uptoDecimal:3]];
        }
        /** TH Calculation **/
        float aswer=[courseTextField.text floatValue]+[wcaTextField.text floatValue];
        headingTextField.text=[NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:aswer uptoDecimal:0]];
        
        float cosResult = windSpeedTextField.text.floatValue* cos(M_PI*(windDirectioinTextField.text.floatValue - courseTextField.text.floatValue)/180);
        float powResult = powf(((windSpeedTextField.text.floatValue/trueAirSpeedTextField.text.floatValue) *sin(M_PI*(windDirectioinTextField.text.floatValue - courseTextField.text.floatValue)/180)), 2.0);
        float estOutput = [trueAirSpeedTextField.text floatValue]*sqrt(1-powResult)-cosResult;
        if (!isnan(estOutput)) {
            groundSpeedTextField.text = [NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:estOutput uptoDecimal:0]];
        }
    }
}
@end
