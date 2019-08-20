//
//  ConversionsViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/10/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ConversionsViewController.h"
#import "CalcConversions+CoreDataClass.h"

#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"
@interface ConversionsViewController ()<UIPopoverControllerDelegate,UIPickerViewDelegate,UIPickerViewDataSource, UITextFieldDelegate>
{
    int isValue;
    NSMutableArray *arrayFiles;
    NSInteger currentSelectedRow;
}

@end
typedef enum : NSUInteger {
    TEMPs = 10,
    DISTANCE,
    WEIGHTS,
    FLUIDS,
    SPEED,
    FUEL,
    TIME,
    TIMEZONE,
    ADMOSPRESSURE
} ConversionMeasurement;

@implementation ConversionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CONVERSIONS";
    arrayFiles = [[NSMutableArray alloc] init];
    currentSelectedRow = -1;
    isShownKeyboard = NO;
    isValue = 0;
    for (UIView *subView in self.containerView.subviews) {
        if (subView.subviews.count == 0){
            continue;
        }
        for (UIView *aView in subView.subviews) {
            if ([aView isKindOfClass:[UITextField class]]) {
                UITextField *textField = (UITextField *)aView;
                if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"SavedText"]==YES) {
                    textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"CON%ld",(long)textField.tag+1000]];
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
                //                textField.placeholder = @"0.00";
            }
            if ([aView isKindOfClass:[UIButton class]]) {
                // Adding rounded corner to button
                UIButton *button = (UIButton *)aView;
                if (button.tag!=1000 && button.tag!=1001 && button.tag!=1002) {
                    button.layer.cornerRadius = 10;
                    button.layer.borderWidth = 1;
                }
                button.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                [button setTitleColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
                //                button.layer.borderColor = [UIColor colorWithRed:0/255.0 green:222/255.0 blue:255/255.0 alpha:1.0].CGColor;
                //                [button setTitleColor:[UIColor colorWithRed:0/255.0 green:222/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearText:) name:@"ClearText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveText:) name:@"SaveText" object:nil];
    
    if (self.view.frame.size.width > self.view.frame.size.height) {
        [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 400.0f)];
    }else{
        [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 150.0f)];
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"ConversionViewcontroller"];
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
    
    
    if (self.view.frame.size.width > self.view.frame.size.height) {
        [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 400.0f)];
    }else{
        [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 150.0f)];
    }
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!isShownKeyboard)
    {
        isShownKeyboard = YES;
        [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 300.0f)];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (isShownKeyboard)
    {
        [self.view endEditing:YES];
        isShownKeyboard = NO;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 400.0f)];
        }else{
            [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height + 150.0f)];
        }
        
    }
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
                
                [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"CON%ld",(long)textField.tag+1000]];
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

- (IBAction)clearTemperature:(id)sender {
    ((UITextField *)[self.view viewWithTag:101]).text = @"";
    ((UITextField *)[self.view viewWithTag:102]).text = @"";
    ((UITextField *)[self.view viewWithTag:103]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",101+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",102+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",103+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}

- (IBAction)clearDistance:(id)sender {
    ((UITextField *)[self.view viewWithTag:111]).text = @"";
    ((UITextField *)[self.view viewWithTag:112]).text = @"";
    ((UITextField *)[self.view viewWithTag:113]).text = @"";
    ((UITextField *)[self.view viewWithTag:114]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",111+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",112+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",113+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",114+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}

- (IBAction)clearWeights:(id)sender {
    ((UITextField *)[self.view viewWithTag:121]).text = @"";
    ((UITextField *)[self.view viewWithTag:122]).text = @"";
    ((UITextField *)[self.view viewWithTag:123]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",121+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",122+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",123+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}

- (IBAction)clearFluids:(id)sender {
    ((UITextField *)[self.view viewWithTag:131]).text = @"";
    ((UITextField *)[self.view viewWithTag:132]).text = @"";
    ((UITextField *)[self.view viewWithTag:133]).text = @"";
    ((UITextField *)[self.view viewWithTag:134]).text = @"";
    ((UITextField *)[self.view viewWithTag:135]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",131+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",132+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",133+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",134+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",135+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}

- (IBAction)clearSpeed:(id)sender {
    ((UITextField *)[self.view viewWithTag:141]).text = @"";
    ((UITextField *)[self.view viewWithTag:142]).text = @"";
    ((UITextField *)[self.view viewWithTag:143]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",141+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",142+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",143+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}
- (IBAction)clearFuel:(id)sender {
    ((UITextField *)[self.view viewWithTag:151]).text = @"";
    ((UITextField *)[self.view viewWithTag:152]).text = @"";
    ((UITextField *)[self.view viewWithTag:153]).text = @"";
    ((UITextField *)[self.view viewWithTag:154]).text = @"";
    ((UITextField *)[self.view viewWithTag:155]).text = @"";
    ((UITextField *)[self.view viewWithTag:156]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",151+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",152+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",153+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",154+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",155+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",156+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}
- (IBAction)clearTime:(id)sender {
    ((UITextField *)[self.view viewWithTag:161]).text = @"";
    ((UITextField *)[self.view viewWithTag:162]).text = @"";
    ((UITextField *)[self.view viewWithTag:163]).text = @"";
    ((UITextField *)[self.view viewWithTag:164]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",161+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",162+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",163+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",164+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}
- (IBAction)clearTimeZone:(id)sender {
    ((UITextField *)[self.view viewWithTag:171]).text = @"";
    ((UITextField *)[self.view viewWithTag:172]).text = @"";
    ((UITextField *)[self.view viewWithTag:173]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",171+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",172+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",173+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    currentSelectedRow = -1;
    [self.SavedRecordTableView reloadData];
}
- (IBAction)clearAdmosPressure:(id)sender {
    ((UITextField *)[self.view viewWithTag:181]).text = @"";
    ((UITextField *)[self.view viewWithTag:182]).text = @"";
    ((UITextField *)[self.view viewWithTag:183]).text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",181+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",182+1000]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"CON%d",183+1000]];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    self.lastTextFieldTag=textField.tag;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *acceptableCharacter=ACCEPTABLE_CHARECTERS;
    if (textField.tag==161 || textField.tag==162 || textField.tag==163 || textField.tag==171 || textField.tag==172 || textField.tag==173) {
        acceptableCharacter=ACCEPTABLE_TIMECHARECTERS;
    }else if (textField.tag==101 || textField.tag==102 || textField.tag==103) {
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
    else if (textField.tag==181 ) {
        if ([finalString length]==2 && ![finalString containsString:@"."] && range.length<1) {
            finalString=[NSString stringWithFormat:@"%@.",finalString];
            
        }else if ([string isEqualToString:@"."] && range.length<1 ) {
            NSString *lastCharacter=[finalString substringFromIndex:[finalString length] - 1];
            if ([lastCharacter isEqualToString:string]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }
        }
        else if([finalString length]>5) {
            finalString =[finalString substringToIndex:5];
        }
        
    }else if (textField.tag==161 || textField.tag==162 ||textField.tag==163 || textField.tag==171 || textField.tag==172 || textField.tag==173) {
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
    
    if (textField.tag==161 || textField.tag==162 ||textField.tag==163 || textField.tag==171 || textField.tag==172 || textField.tag==173)
    {
        //            if((isValue == 1) || (isValue == 3))
        //            {
        //                finalString = [finalString stringByAppendingString:@":"];
        //                NSLog(@"%@",finalString);
        //                [textField setText:finalString];
        //                isValue ++;
        //                return NO;
        //            }
        newValue=[self getdecimalTimeFromString:finalString];
    }
    [self valueChangedInConversionTableForMeasurement:(textField.tag/10) forUnit:(textField.tag % 10) withNewValue:newValue];
    textField.text = finalString;
    isValue ++;
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

///-------------------------------------------------
#pragma mark - Measurement Calculations
///-------------------------------------------------

- (void)valueChangedInConversionTableForMeasurement:(ConversionMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue{
    switch (measurement) {
        case TEMPs:
            [self calculateTemperatureConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case DISTANCE:
            [self calculateDistanceConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case WEIGHTS:
            [self calculateWightsConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case FLUIDS:
            [self calculateFluidsConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case SPEED:
            [self calculateSpeedConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
        case FUEL:
            [self calculateFuelConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
        case TIME:
            [self calculateTimeConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
        case TIMEZONE:
            [self calculateTimeZoneConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
        case ADMOSPRESSURE:
            [self calculateAdmosPressureConversionsOnChangeInUnit:unitId toNewValue:newValue];
            break;
        default:
            break;
    }
}

- (void)calculateTemperatureConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double celsiusVaue = 0.00;
    
    switch (unitId) {
        case 1:// Celsius
            celsiusVaue = newValue;
            break;
            
        case 2:// Fahrenheit// celsius = (fahrenheit - 32.0) * (5.0 / 9.0)
            celsiusVaue = (newValue - 32.0) * (5.0 / 9.0);
            break;
            
        case 3:// kelvin// celsius = kelvin - 273.15
            celsiusVaue = newValue - 273.15;
            break;
            
        default:
            break;
    }
    
    double fahrenheitValue = celsiusVaue * (9.0/5.0) + 32.0;
    double kelvinValue = celsiusVaue + 273.15;
    
    UITextField *celsiusTextField = [self.view viewWithTag:101];
    UITextField *fahrenheitTextField = [self.view viewWithTag:102];
    UITextField *kelvinTextField = [self.view viewWithTag:103];
    
    celsiusTextField.text = [NSString stringWithFormat:@"%.02f", roundf(celsiusVaue)];
    fahrenheitTextField.text = [NSString stringWithFormat:@"%.02f", roundf(fahrenheitValue)];
    kelvinTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:kelvinValue uptoDecimal:2]];
}

- (void)calculateDistanceConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double milesValue = 0.00;
    
    switch (unitId) {
        case 1:// Miles(SM)
            milesValue = newValue;
            break;
            
        case 2:// Feet(FT)// mile = feet / 5280.0
            milesValue = newValue / 5280.0;
            break;
            
        case 3:// Nutical Miles(NM)// mile = nautical_miles * 1.15078
            milesValue = newValue * 1.15078;
            break;
            
        case 4:// Kilometers(KM)// mile = kilometers * 0.62137
            milesValue = newValue * 0.62137;
            break;
            
        default:
            break;
    }
    
    double feetValue = milesValue * 5280.0;                 // feet = mile * 5280.0;
    double nauticalMilesValue = milesValue / 1.15078;       // nautical_mile = mile / 1.15078
    double kilometersValue = milesValue / 0.62137;          // kilometers = mile / 0.62137
    
    UITextField *milesTextField = [self.view viewWithTag:111];
    UITextField *feetTextField = [self.view viewWithTag:112];
    UITextField *nauticalMilesTextField = [self.view viewWithTag:113];
    UITextField *kilometersTextField = [self.view viewWithTag:114];
    
    //milesTextField.text = [NSString stringWithFormat:@"%.02f", roundf(milesValue)];
    //feetTextField.text = [NSString stringWithFormat:@"%.02f", roundf(feetValue)];
    milesTextField.text = [NSString stringWithFormat:@"%.02f",milesValue];
    feetTextField.text = [NSString stringWithFormat:@"%.02f",feetValue];
    nauticalMilesTextField.text = [NSString stringWithFormat:@"%.5f", [self getRoundedForValue:nauticalMilesValue uptoDecimal:5]];
    kilometersTextField.text = [NSString stringWithFormat:@"%.5f", [self getRoundedForValue:kilometersValue uptoDecimal:5]];
}

- (void)calculateWightsConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double poundsValue = 0.00;
    
    switch (unitId) {
        case 1:// Pounds(LB)
            poundsValue = newValue;
            break;
            
        case 2:// Kilos(KL)// pound(lb) = kg * 2.2046
            poundsValue = newValue * 2.2046;
            break;
            
        case 3:// Tons(T)// pound(lb) = ton * 2000
            poundsValue = newValue * 2000;
            break;
            
        default:
            break;
    }
    
    
    double kilosValue = poundsValue / 2.2046;   // kilo = pound(lb) / 2.2046
    double tonsValue = poundsValue / 2000;      // ton = pound(lb) / 2000
    
    UITextField *poundsTextField = [self.view viewWithTag:121];
    UITextField *kilosTextField = [self.view viewWithTag:122];
    UITextField *tonsTextField = [self.view viewWithTag:123];
    
    poundsTextField.text = [NSString stringWithFormat:@"%.02f", roundf(poundsValue)];
    kilosTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:kilosValue uptoDecimal:2]];
    tonsTextField.text = [NSString stringWithFormat:@"%.4f", [self getRoundedForValue:tonsValue uptoDecimal:4]];
}

- (void)calculateFluidsConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double gallonsValue = 0.00;
    
    switch (unitId) {
        case 1:// Gallons(GL)
            gallonsValue = newValue;
            break;
            
        case 2:// Ounces(OZ)// gallon = ounces / 128
            gallonsValue = newValue / 128.0;
            break;
            
        case 3:// Quarts(QT)// gallon = quarts / 4
            gallonsValue = newValue / 4.0;
            break;
            
        case 4:// Pints(PT)// gallon = pint / 8
            gallonsValue = newValue / 8.0;
            break;
            
        case 5:// Litters(LT)// gallon = litter * 0.26417
            gallonsValue = newValue * 0.26417;
            break;
            
        default:
            break;
    }
    
    
    double ouncesValue = gallonsValue * 128;        // ounce = gallon * 128
    double quartsValue = gallonsValue * 4.0;        // quart = gallon * 4
    double pintsValue = gallonsValue * 8.0;         // pint = gallon * 8
    double littersValue = gallonsValue / 0.26417;   // litter = gallon / 0.26417
    
    UITextField *gallonsTextField = [self.view viewWithTag:131];
    UITextField *ouncesTextField = [self.view viewWithTag:132];
    UITextField *quartsTextField = [self.view viewWithTag:133];
    UITextField *pintsTextField = [self.view viewWithTag:134];
    UITextField *littersTextField = [self.view viewWithTag:135];
    
    gallonsTextField.text = [NSString stringWithFormat:@"%.02f", roundf(gallonsValue)];
    ouncesTextField.text = [NSString stringWithFormat:@"%.02f", roundf(ouncesValue)];
    quartsTextField.text = [NSString stringWithFormat:@"%.02f", roundf(quartsValue)];
    pintsTextField.text = [NSString stringWithFormat:@"%.02f", roundf(pintsValue)];
    littersTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:littersValue uptoDecimal:2]];
}

- (void)calculateSpeedConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double knotsValue = 0.00;
    
    switch (unitId) {
        case 1://Knots(KTS)
            knotsValue = newValue;
            break;
            
        case 2://MPH// knot = mph * 0.86897624190816
            knotsValue = newValue * 0.86897624190816;
            break;
            
        case 3://KPH// knot = kph / 1.85200
            knotsValue = newValue / 1.85200;
            break;
            
        default:
            break;
    }
    
    double mphValue = knotsValue / 0.86897624190816;    // mph = knot / 0.86897624190816
    double kphValue = knotsValue * 1.85200;             // kph = knot / 1.85200
    
    UITextField *knotsTextField = [self.view viewWithTag:141];
    UITextField *mphTextField = [self.view viewWithTag:142];
    UITextField *kphTextField = [self.view viewWithTag:143];
    
    knotsTextField.text = [NSString stringWithFormat:@"%.02f", roundf(knotsValue)];
    mphTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:mphValue uptoDecimal:2]];
    kphTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:kphValue uptoDecimal:2]];
}

- (void)calculateFuelConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    
    UITextField *poundTextField = [self.view viewWithTag:151];
    UITextField *AvVGASTextField = [self.view viewWithTag:152];
    UITextField *jetTextField = [self.view viewWithTag:153];
    UITextField *tksTextField = [self.view viewWithTag:154];
    UITextField *oilTextField = [self.view viewWithTag:155];
    UITextField *waterTextField = [self.view viewWithTag:156];
    double poundValue = 0.00;
    switch (unitId) {
        case 1:
            poundValue=newValue;
            break;
        case 2:
            poundValue=newValue*6;
            break;
        case 3:
            poundValue=newValue*6.7;
            break;
        case 4:
            poundValue=newValue*9.12;
            break;
        case 5:
            poundValue=newValue*7.5;
            break;
        case 6:
            poundValue=newValue*8.36;
            break;
            
            
        default:
            break;
    }
    poundTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue uptoDecimal:2]];
    AvVGASTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue/6 uptoDecimal:2]];
    jetTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue/6.7 uptoDecimal:2]];
    tksTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue/9.12 uptoDecimal:2]];
    oilTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue/7.5 uptoDecimal:2]];
    waterTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:poundValue/8.36 uptoDecimal:2]];
}


- (void)calculateTimeConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *startTimeTextField = [self.view viewWithTag:161];
    UITextField *endTimeTextField = [self.view viewWithTag:162];
    UITextField *totalTextField = [self.view viewWithTag:163];
    UITextField *decimalTextField = [self.view viewWithTag:164];
    double startTime=0.00,endTime=0.00,decimalTime=0.00,totalTime=0.00;
    
    switch (unitId)
    {
        case 1:
            startTime=newValue;
            endTime=[self getdecimalTimeFromString:endTimeTextField.text];
            if ((startTime == 0 && endTime != 0 && totalTime == 0 && decimalTime == 0) || (startTime != 0 && endTime != 0 && totalTime == 0 && decimalTime == 0))
            {
                decimalTime=endTime-startTime;
                totalTextField.text=[self convertDecimalTimeTostring:decimalTime];
                decimalTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:decimalTime uptoDecimal:2]];
            }
            else if (startTime != 0 && endTime == 0 && totalTime == 0 && decimalTime == 0)
            {
                totalTextField.text=@"";
                decimalTextField.text=@"";
            }
            break;
        case 2:
            startTime=[self getdecimalTimeFromString:startTimeTextField.text];
            endTime=newValue;
            if ((startTime != 0 && endTime == 0 && totalTime == 0) || (startTime != 0 && endTime != 0 && totalTime == 0) || (startTime != 0 && endTime == 0 && totalTime == 0) || (startTime != 0 && endTime != 0 && totalTime == 0))
            {
                decimalTime=endTime-startTime;
                totalTextField.text=[self convertDecimalTimeTostring:decimalTime];
                decimalTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:decimalTime uptoDecimal:2]];
            }
            else if (startTime == 0 && endTime != 0 && totalTime == 0 && decimalTime == 0)
            {
                totalTextField.text=@"";
                decimalTextField.text=@"";
            }
            else
            {
                decimalTime=endTime-startTime;
                totalTextField.text=[self convertDecimalTimeTostring:decimalTime];
                decimalTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:decimalTime uptoDecimal:2]];
            }
            
            break;
        case 3:
            totalTime=newValue;
            endTime=[self getdecimalTimeFromString:endTimeTextField.text];
            startTime=[self getdecimalTimeFromString:startTimeTextField.text];
            
            if ((startTime == 0 && endTime != 0 && totalTime != 0) || (startTime == 0 && endTime != 0 && totalTime == 0) || (startTime == 0 && endTime == 0 && totalTime != 0) || (startTime != 0 && endTime != 0 && totalTime != 0) || (startTime != 0 && endTime != 0 && totalTime == 0))
            {
                endTime = totalTime;
                startTime =  endTime - totalTime;
                endTimeTextField.text = [self convertDecimalTimeTostring:totalTime];
                startTimeTextField.text=[self convertDecimalTimeTostring:startTime];
                decimalTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:decimalTime uptoDecimal:2]];
            }
            else
            {
                endTime = startTime + totalTime;
                endTimeTextField.text=[self convertDecimalTimeTostring:endTime];
                decimalTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:decimalTime uptoDecimal:2]];
            }
            break;
        case 4:
            totalTime=newValue;
            endTime=[self getdecimalTimeFromString:endTimeTextField.text];
            startTime=[self getdecimalTimeFromString:startTimeTextField.text];
            
            if ((startTime == 0 && endTime != 0 && totalTime != 0) || (startTime == 0 && endTime != 0 && totalTime == 0) || (startTime == 0 && endTime == 0 && totalTime != 0) || (startTime != 0 && endTime != 0 && totalTime != 0) || (startTime != 0 && endTime != 0 && totalTime == 0) || (startTime == 0 && endTime == 0 && totalTime != 0) )
            {
                endTime = totalTime;
                startTime =  endTime - totalTime;
                endTimeTextField.text = [self convertDecimalTimeTostring:totalTime];
                startTimeTextField.text=[self convertDecimalTimeTostring:startTime];
                totalTextField.text=[self convertDecimalTimeTostring:totalTime];
            }
            else
            {
                endTime = startTime + totalTime;
                endTimeTextField.text=[self convertDecimalTimeTostring:endTime];
                totalTextField.text=[self convertDecimalTimeTostring:totalTime];
            }
            break;
        default:
            break;
    }
}

- (void)calculateTimeZoneConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    
    UITextField *localTimeTextField = [self.view viewWithTag:171];
    UITextField *gmtTimeTextField = [self.view viewWithTag:172];
    UITextField *customTimeTextField = [self.view viewWithTag:173];
    NSString *localTime=@"00:00:00",*gmtTime=@"00:00:00",*customTime=@"00:00:00";
    
    switch (unitId) {
        case 1:
            if (newValue>0) {
                localTime=[self convertDecimalTimeTostring:newValue];
                gmtTime=[self getGMTTimeFromLocal:localTime];
                customTime=[self getCustomTimeFromLocal:localTime];
            }
            
            break;
        case 2:
            if (newValue>0) {
                localTime=[self getLocalTimeFromGMT:[self convertDecimalTimeTostring:newValue]];
                gmtTime=[self convertDecimalTimeTostring:newValue];
                customTime=[self getCustomTimeFromLocal:localTime];
            }
            break;
        case 3:
            if (newValue>0) {
                localTime=[self getLocalTimeFromCustom:[self convertDecimalTimeTostring:newValue]];
                gmtTime=[self getGMTTimeFromLocal:localTime];
                customTime=[self convertDecimalTimeTostring:newValue];
            }
            break;
            
        default:
            break;
    }
    localTimeTextField.text=localTime;
    gmtTimeTextField.text=gmtTime;
    customTimeTextField.text=customTime;
}
- (void)calculateAdmosPressureConversionsOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *beroTextField = [self.view viewWithTag:181];
    UITextField *millibarsTextField = [self.view viewWithTag:182];
    UITextField *psiTextField = [self.view viewWithTag:183];
    double mbarValue;
    switch (unitId) {
        case 1:
            mbarValue=newValue*33.8638816;
            break;
        case 2:
            mbarValue=newValue;
            break;
        case 3:
            mbarValue=newValue/68.9475728;
            break;
            
        default:
            break;
    }
    beroTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:mbarValue/33.8638816 uptoDecimal:2]];
    millibarsTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:mbarValue uptoDecimal:2]];
    psiTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:mbarValue/68.9475728 uptoDecimal:2]];
}
- (IBAction)actionLocal:(id)sender {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    UITextField *localTimeTextField = [self.view viewWithTag:171];
    UITextField *gmtTimeTextField = [self.view viewWithTag:172];
    UITextField *customTimeTextField = [self.view viewWithTag:173];
    
    localTimeTextField.text=[dateFormatter stringFromDate:[NSDate date]];
    
    
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    gmtTimeTextField.text=[dateFormatter stringFromDate:[NSDate date]];
    
    UIButton *btn=(UIButton*)[self.containerView viewWithTag:1002];
    NSString *abbreviation=[[[[[btn currentTitle] componentsSeparatedByString:@"("] objectAtIndex:1] componentsSeparatedByString:@")"] objectAtIndex:0];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
    customTimeTextField.text=[dateFormatter stringFromDate:[NSDate date]];
    
    [dateFormatter setDateFormat:@"zzz"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *abbrevation= [[[[[dateFormatter stringFromDate:[NSDate date]] componentsSeparatedByString:@"+"] objectAtIndex:0] componentsSeparatedByString:@"-"] objectAtIndex:0];
    [sender setTitle:[NSString stringWithFormat:@"LOCAL(%@)",abbrevation] forState:UIControlStateNormal];
    
}
- (IBAction)actionZuhu:(id)sender {
    
    
}
- (IBAction)actionCustom:(id)sender {
    dictTimeZone = [NSTimeZone abbreviationDictionary];
    
    
    
    //Create the view controller you want to display.
    UIViewController* popoverContent = [[UIViewController alloc] init]; //ViewController
    
    UIView *popoverView = [[UIView alloc] init];   //view
    popoverView.backgroundColor = [UIColor clearColor];
    
    UIPickerView *objPickerView = [[UIPickerView alloc]init];//Date picker
    objPickerView.delegate = self; // Also, can be done from IB, if you're using
    objPickerView.dataSource = self;// Also, can be done from IB, if you're using
    objPickerView.frame=CGRectMake(0,44,320, 216);
    [popoverView addSubview:objPickerView];
    popoverContent.view = popoverView;
    
    
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
    popoverController.delegate = self;
    
    [popoverController setPopoverContentSize:CGSizeMake(320, 264) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    
    return 1;//Or return whatever as you intend
}
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [dictTimeZone allKeys].count;//Or, return as suitable for you...normally we use array for dynamic
}
- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[NSString stringWithFormat:@"%@(%@)",[[[dictTimeZone valueForKey:[[dictTimeZone allKeys] objectAtIndex:row]] componentsSeparatedByString:@"/"] objectAtIndex:0],[[dictTimeZone allKeys] objectAtIndex:row]] uppercaseString];//[NSString stringWithFormat:@"Choice-%ld",(long)row];//Or, your suitable title; like Choice-a, etc.
}
- (void)pickerView:(UIPickerView *)pV didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    UIButton *btn=(UIButton*)[self.containerView viewWithTag:1002];
    NSString *abbreviation=[[[[[btn currentTitle] componentsSeparatedByString:@"("] objectAtIndex:1] componentsSeparatedByString:@")"] objectAtIndex:0];
    NSString *title=[NSString stringWithFormat:@"%@(%@)",[[[dictTimeZone valueForKey:[[dictTimeZone allKeys] objectAtIndex:row]] componentsSeparatedByString:@"/"] objectAtIndex:0],[[dictTimeZone allKeys] objectAtIndex:row]];
    [btn setTitle:[title uppercaseString] forState:UIControlStateNormal];
    
    UITextField *customTimeTextField = [self.view viewWithTag:173];
    
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
    NSDate *date=[dateFormatter dateFromString:customTimeTextField.text];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:[[dictTimeZone allKeys] objectAtIndex:row]]];
    customTimeTextField.text= [dateFormatter stringFromDate:date];
}
///-------------------------------------------------
#pragma mark - Utility Methods
///-------------------------------------------------

-(NSString*)getGMTTimeFromLocal:(NSString*)time {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *date=[dateFormatter dateFromString:time];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    return [dateFormatter stringFromDate:date];
}
-(NSString*)getLocalTimeFromGMT:(NSString*)time {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSDate *date=[dateFormatter dateFromString:time];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    return [dateFormatter stringFromDate:date];
}
-(NSString*)getLocalTimeFromCustom:(NSString*)time {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    UIButton *btn=(UIButton*)[self.containerView viewWithTag:1002];
    NSString *abbreviation=[[[[[btn currentTitle] componentsSeparatedByString:@"("] objectAtIndex:1] componentsSeparatedByString:@")"] objectAtIndex:0];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
    NSDate *date=[dateFormatter dateFromString:time];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    return [dateFormatter stringFromDate:date];
    
}
-(NSString*)getCustomTimeFromLocal:(NSString*)time {
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *date=[dateFormatter dateFromString:time];
    UIButton *btn=(UIButton*)[self.containerView viewWithTag:1002];
    NSString *abbreviation=[[[[[btn currentTitle] componentsSeparatedByString:@"("] objectAtIndex:1] componentsSeparatedByString:@")"] objectAtIndex:0];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
    
    return [dateFormatter stringFromDate:date];
    
}
-(double)getdecimalTimeFromString:(NSString*)time {
    NSArray *seperateString;
    double hours=0.00;
    double minutes=0.00;
    double second=0.00;
    if ([time containsString:@":"]) {
        seperateString=[time componentsSeparatedByString:@":"];
    }
    if ([seperateString count]==0) {
        hours=[time doubleValue];
    }
    else if ([seperateString count]==1) {
        hours=[seperateString[0] doubleValue];
    }else if ([seperateString count]==2) {
        hours=[seperateString[0] doubleValue];
        minutes=[seperateString[1] doubleValue];
    }else if ([seperateString count]==3) {
        hours=[seperateString[0] doubleValue];
        minutes=[seperateString[1] doubleValue];
        second=[seperateString[2] doubleValue];
    }
    
    minutes=minutes/60;
    
    return hours+minutes+second;
    
}

-(NSString*)convertDecimalTimeTostring:(double)hours {
    
    //    2.88 hours can be broken down to 2 hours plus 0.88 hours - 2 hours
    
    //    0.88 hours * 60 minutes/hour = 52.8 minutes - 52 minutes
    
    //    0.8 minutes * 60 seconds/minute = 48 seconds - 48 seconds
    
    //    02:52:48
    
    float minutes;
    
    int hour=0,minute=0,second;
    
    hour=floor(hours);
    
    minutes=(hours-hour)*60;
    
    minute=floor(minutes);
    
    second=(minutes-minute)*60;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hour,minute,second];
    
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
    
    return roundf(value * divisor) / divisor;
}
-(BOOL)exist
{
    NSManagedObjectContext *managedObjectContext=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"CalcConversions" inManagedObjectContext:managedObjectContext];
    
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
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcConversions" inManagedObjectContext:context];
            CalcConversions *calcConversions=[[CalcConversions alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            calcConversions.name=self.nameTextField.text;
            
            calcConversions.tempCelcius = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:101]).text doubleValue]];
            calcConversions.tempfarnate = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:102]).text doubleValue]];
            calcConversions.tempKelbin = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:103]).text doubleValue]];
            
            calcConversions.distanceMiles = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:111]).text doubleValue]];
            calcConversions.distanceFeet = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:112]).text doubleValue]];
            calcConversions.distanceKilometer = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:114]).text doubleValue]];
            
            calcConversions.weightPound = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:121]).text doubleValue]];
            calcConversions.weightKilos = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:122]).text doubleValue]];
            calcConversions.weightTons = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:123]).text doubleValue]];
            
            calcConversions.fluidGallons = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:131]).text doubleValue]];
            calcConversions.fluidOunces = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:132]).text doubleValue]];
            calcConversions.fluidQuarts = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:133]).text doubleValue]];
            calcConversions.fluidPints = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:134]).text doubleValue]];
            calcConversions.fluidLiters = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:135]).text doubleValue]];
            
            calcConversions.speedKts = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:141]).text doubleValue]];
            calcConversions.speedMph = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:142]).text doubleValue]];
            calcConversions.speedKph = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:143]).text doubleValue]];
            
            calcConversions.fuelPounds = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:151]).text doubleValue]];
            calcConversions.fuelAvGas = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:152]).text doubleValue]];
            calcConversions.fuelJetA = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:153]).text doubleValue]];
            calcConversions.fuelTks = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:154]).text doubleValue]];
            calcConversions.fuelOil = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:155]).text doubleValue]];
            calcConversions.fuelWater = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:156]).text doubleValue]];
            
            calcConversions.timeStart = ((UITextField *)[self.view viewWithTag:161]).text;
            calcConversions.timeEnd = ((UITextField *)[self.view viewWithTag:162]).text;
            calcConversions.timeTotal = ((UITextField *)[self.view viewWithTag:163]).text;
            calcConversions.timeDecimal = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:164]).text doubleValue]];
            
            calcConversions.timeZoneLocal = ((UITextField *)[self.view viewWithTag:171]).text;
            calcConversions.timeZoneZULU = ((UITextField *)[self.view viewWithTag:172]).text;
            calcConversions.timeZoneLocal = ((UITextField *)[self.view viewWithTag:173]).text;
            
            calcConversions.admosBaro = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:181]).text doubleValue]];
            calcConversions.admosMillibars = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:182]).text doubleValue]];
            calcConversions.admosPsi = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:183]).text doubleValue]];
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [arrayFiles addObject:calcConversions];
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
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcConversions" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (CalcConversions *calcConversionsToDelete in fetchedData) {
            [context deleteObject:calcConversionsToDelete];
        }
    }
    [self.SavedRecordTableView reloadData];
}
- (void)getSavedFiles{
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcConversions" inManagedObjectContext:context];
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
    static NSString *MyIdentifier = @"CalcConversionsItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier];
    }
    
    CalcConversions *calcConversions=[arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.SavedRecordTableView.bounds.size.width, 28.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = calcConversions.name;
    
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
    CalcConversions *calcConversions=[arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:calcConversions];
    [self.SavedRecordTableView reloadData];
}
-(void)displayDetails:(CalcConversions*)calcConversions {
    ((UITextField *)[self.view viewWithTag:101]).text=[calcConversions.tempCelcius doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.tempCelcius doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:102]).text=[calcConversions.tempfarnate doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.tempfarnate doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:103]).text=[calcConversions.tempKelbin doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.tempKelbin doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:111]).text=[calcConversions.distanceMiles doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.distanceMiles doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:112]).text=[calcConversions.distanceFeet doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.distanceFeet doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:113]).text=[calcConversions.distanceMiles doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.distanceMiles doubleValue] / 1.15078]:@"";
    ((UITextField *)[self.view viewWithTag:114]).text=[calcConversions.distanceKilometer doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.distanceKilometer doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:121]).text=[calcConversions.weightPound doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.weightPound doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:122]).text=[calcConversions.weightKilos doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.weightKilos doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:123]).text=[calcConversions.weightTons doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.weightTons doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:131]).text=[calcConversions.fluidGallons doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fluidGallons doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:132]).text=[calcConversions.fluidOunces doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fluidOunces doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:133]).text=[calcConversions.fluidQuarts doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fluidQuarts doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:134]).text=[calcConversions.fluidPints doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fluidPints doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:135]).text=[calcConversions.fluidLiters doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fluidLiters doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:141]).text=[calcConversions.speedKts doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.speedKts doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:142]).text=[calcConversions.speedMph doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.speedMph doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:143]).text=[calcConversions.speedKph doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.speedKph doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:151]).text=[calcConversions.fuelPounds doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelPounds doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:152]).text=[calcConversions.fuelAvGas doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelAvGas doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:153]).text=[calcConversions.fuelJetA doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelJetA doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:154]).text=[calcConversions.fuelTks doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelTks doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:155]).text=[calcConversions.fuelOil doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelOil doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:156]).text=[calcConversions.fuelWater doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.fuelWater doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:161]).text=[calcConversions.timeStart length]>0?calcConversions.timeStart:@"";
    ((UITextField *)[self.view viewWithTag:162]).text=[calcConversions.timeEnd length]>0?calcConversions.timeEnd:@"";
    ((UITextField *)[self.view viewWithTag:163]).text=[calcConversions.timeTotal length]>0?calcConversions.timeTotal:@"";
    ((UITextField *)[self.view viewWithTag:164]).text=[calcConversions.timeDecimal doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.timeDecimal doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:171]).text=[calcConversions.timeZoneLocal length]>0?calcConversions.timeZoneLocal:@"";
    ((UITextField *)[self.view viewWithTag:172]).text=[calcConversions.timeZoneZULU length]>0?calcConversions.timeZoneZULU:@"";
    ((UITextField *)[self.view viewWithTag:173]).text=[calcConversions.timeZoneLosAngeles length]>0?calcConversions.timeZoneLosAngeles:@"";
    
    ((UITextField *)[self.view viewWithTag:181]).text=[calcConversions.admosBaro doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.admosBaro doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:182]).text=[calcConversions.admosMillibars doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.admosMillibars doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:183]).text=[calcConversions.admosPsi doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcConversions.admosPsi doubleValue]]:@"";
    
}
@end
