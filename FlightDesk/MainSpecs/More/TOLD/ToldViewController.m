//
//  ToldViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ToldViewController.h"
#import "TOLD+CoreDataClass.h"


#define ACCEPTABLE_CHARECTERS @"-0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"-0123456789:"
@interface ToldViewController ()<UITextFieldDelegate>
{
    NSMutableArray *arrayFiles;
    NSInteger currentSelectedRow;
}
@end
typedef enum : NSUInteger {
    FIRSTROW = 10,
    SECONDROW,
    THIRDROW,
    FOURTHROW,
    FIFTHROW,
    SIXTHROW,
    SEVENTHROW,
    EIGHTHROW,
    NINETHROW,
    TENTHROW,
    ELEVENTHROW,
    TWELVETHROW,
    THIRTEENTHROW,
    FOURTEENTHROW,
    FIFTEENTHROW,
    SIXTEENTHROW,
    SEVENTEENTHROW
    
} PerformanceMeasurement;
@implementation ToldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"T.O.L.D";
    isShownKeyboard = NO;
    arrayFiles = [[NSMutableArray alloc] init];
    currentSelectedRow = -1;
    // Initialization code
    self.btnClearAll.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    // you probably want to center it
    self.btnClearAll.titleLabel.textAlignment = NSTextAlignmentCenter; // if you want to
    [self.btnClearAll setTitle: @"CLEAR ALL" forState: UIControlStateNormal];
    
    //    self.containerView.layer.borderColor = [UIColor grayColor].CGColor;
    //    self.containerView.layer.borderWidth = 1.0;
    
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subView;
            if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"SavedText"]==YES) {
                textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TOLD%ld",(long)textField.tag+10000]];
            }
            if ([textField isUserInteractionEnabled]) {
                textField.layer.cornerRadius=5.0;
                textField.layer.borderWidth=1.0;
                textField.borderStyle=UITextBorderStyleNone;
                textField.textColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
                textField.layer.borderColor=[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                //[textField setValue:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forKeyPath:@"_placeholderLabel.textColor"];
                NSAttributedString *attrForTextField = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] }];
                textField.attributedPlaceholder = attrForTextField;
                textField.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
                textField.layer.borderWidth = 1.0f;
                textField.layer.cornerRadius = 5.0f;
            }else
                textField.textColor=[UIColor blackColor];
            
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.delegate = self;
            //                textField.placeholder = @"0.00";
        }
        
        if ([subView isKindOfClass:[UIButton class]]) {
            // Adding rounded corner to button
            UIButton *button = (UIButton *)subView;
            
            button.layer.cornerRadius = 10;
            button.layer.borderWidth = 1;
            button.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
            [button setTitleColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionClearAll:) name:@"ClearText" object:nil];
    if (self.view.frame.size.width > self.view.frame.size.height) {
        [scrView setContentSize:CGSizeMake(0, self.view.frame.size.width)];
    }else{
        [scrView setContentSize:CGSizeMake(0, self.view.frame.size.height)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearText:) name:@"ClearText" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveText:) name:@"SaveText" object:nil];
}
-(void)clearText:(NSNotification *) notification {
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subView;
                textField.text=@"";
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"TOLD%ld",(long)textField.tag+1000]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
-(void)saveText:(NSNotification *) notification {
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subView;
            
            [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"TOLD%ld",(long)textField.tag+1000]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SavedText"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self getSavedFiles];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"ToldViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveText:nil];
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!isShownKeyboard)
    {
        isShownKeyboard = YES;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            [scrView setContentSize:CGSizeMake(0, self.view.frame.size.width + 400.0f)];
        }else{
            [scrView setContentSize:CGSizeMake(0, self.view.frame.size.height + 400.0f)];
        }
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (isShownKeyboard)
    {
        [self.view endEditing:YES];
        isShownKeyboard = NO;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            [scrView setContentSize:CGSizeMake(0, self.view.frame.size.width + 400.0f)];
        }else{
            [scrView setContentSize:CGSizeMake(0, self.view.frame.size.height + 400.0f)];
        }
        
    }
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
        [scrView setContentSize:CGSizeMake(0, self.view.frame.size.width + 400.0f)];
    }else{
        [scrView setContentSize:CGSizeMake(0, self.view.frame.size.height + 400.0f)];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///-------------------------------------------------
#pragma mark - ActionMethods
///-------------------------------------------------

- (IBAction)actionClearAll:(id)sender {
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
    self.lastTextFieldTag=textField.tag;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField.tag!=1020) {
        NSString *acceptableCharacter=ACCEPTABLE_CHARECTERS;
        
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:acceptableCharacter] invertedSet];
        
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        
        NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
        if (([string isEqualToString:@"."] || [string isEqualToString:@"-"])  && range.length<1) {
            if ([string isEqualToString:@"."] && [textField.text containsString:@"."]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }else if ([string isEqualToString:@"-"] && [textField.text containsString:@"-"]) {
                finalString=[finalString substringToIndex:[finalString length] - 1];
            }
        }
        
        double newValue=[finalString doubleValue];
        
        [self valueChangedInConversionTableForMeasurement:(textField.tag/10) forUnit:(textField.tag % 10) withNewValue:newValue];
        textField.text = finalString;
        
        return NO;
        
    }
    return YES;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UITextField *nextTextField = [[UITextField alloc] init];
    if (textField.tag == 105) {
        nextTextField = [self.view viewWithTag:111];
    }else if (textField.tag == 111) {
        nextTextField = [self.view viewWithTag:112];
    }else if (textField.tag == 112) {
        nextTextField = [self.view viewWithTag:113];
    }else if (textField.tag == 113) {
        nextTextField = [self.view viewWithTag:114];
    }else if (textField.tag == 114) {
        nextTextField = [self.view viewWithTag:115];
    }else if (textField.tag == 115) {
        nextTextField = [self.view viewWithTag:121];
    }else if (textField.tag == 121) {
        nextTextField = [self.view viewWithTag:122];
    }else if (textField.tag == 122) {
        nextTextField = [self.view viewWithTag:123];
    }else if (textField.tag == 123) {
        nextTextField = [self.view viewWithTag:124];
    }else if (textField.tag == 124) {
        nextTextField = [self.view viewWithTag:131];
    }else if (textField.tag == 131) {
        nextTextField = [self.view viewWithTag:132];
    }else if (textField.tag == 132) {
        nextTextField = [self.view viewWithTag:133];
    }else if (textField.tag == 133) {
        nextTextField = [self.view viewWithTag:134];
    }else if (textField.tag == 134) {
        nextTextField = [self.view viewWithTag:141];
    }else if (textField.tag == 141) {
        nextTextField = [self.view viewWithTag:146];
    }else if (textField.tag == 146) {
        nextTextField = [self.view viewWithTag:151];
    }else if (textField.tag == 151) {
        nextTextField = [self.view viewWithTag:161];
    }else if (textField.tag == 161) {
        nextTextField = [self.view viewWithTag:171];
    }else if (textField.tag == 171) {
        nextTextField = [self.view viewWithTag:181];
    }else if (textField.tag == 181) {
        nextTextField = [self.view viewWithTag:191];
    }else if (textField.tag == 191) {
        nextTextField = [self.view viewWithTag:201];
    }else if (textField.tag == 201) {
        nextTextField = [self.view viewWithTag:211];
    }else if (textField.tag == 201) {
        nextTextField = [self.view viewWithTag:211];
    }else if (textField.tag == 211) {
        nextTextField = [self.view viewWithTag:221];
    }else if (textField.tag == 221) {
        nextTextField = [self.view viewWithTag:231];
    }else if (textField.tag == 231) {
        nextTextField = [self.view viewWithTag:241];
    }else if (textField.tag == 241) {
        nextTextField = [self.view viewWithTag:251];
    }else if (textField.tag == 251) {
        nextTextField = [self.view viewWithTag:261];
    }else if (textField.tag == 261) {
        [textField resignFirstResponder];
    }
    
    [nextTextField becomeFirstResponder];
    return YES;
}

///-------------------------------------------------
#pragma mark - Measurement Calculations
///-------------------------------------------------

- (void)valueChangedInConversionTableForMeasurement:(PerformanceMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue{
    switch (measurement) {
        case FIRSTROW:
            [self compareValueInUnit:unitId toNewValue:newValue];
            break;
            
        case SECONDROW:
            [self calculateTakeOfTotalRunwayByTempInUnit:unitId toNewValue:newValue];
            break;
            
        case THIRDROW:
            [self calculateTakeOfTotalRunwayInUnit:unitId toNewValue:newValue];
            break;
            
        case FOURTHROW:
            [self calculateLandingTotalRunwayInUnit:unitId toNewValue:newValue];
            break;
            
        case FIFTHROW:
            [self calculateTopRowValueInUnit:unitId toNewValue:newValue row:FIFTHROW];
            //No Functionality has been defined
            break;
            
        case SIXTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:SIXTHROW];
            break;
            
        case SEVENTHROW:
            //No Functionality has been defined
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:SEVENTHROW];
            break;
            
        case EIGHTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:EIGHTHROW];
            break;
            
        case NINETHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:NINETHROW];
            break;
        case TENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:TENTHROW];
            break;
            
        case ELEVENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:ELEVENTHROW];
            break;
            
        case TWELVETHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:TWELVETHROW];
            break;
            
        case THIRTEENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:THIRTEENTHROW];
            break;
            
        case FOURTEENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:FOURTEENTHROW];
            break;
            
        case FIFTEENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:FIFTEENTHROW];
            break;
            
        case SIXTEENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:SIXTEENTHROW];
            break;
            
        case SEVENTEENTHROW:
            [self calculateFifthRowValueInUnit:unitId toNewValue:newValue row:SEVENTEENTHROW];
            break;
            
        default:
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

-(double)getdecimalTimeFromString:(NSString*)time {
    NSArray *seperateString;
    double hours;
    double minutes;
    double second;
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

- (double)getRoundedForValue:(double)value uptoDecimal:(int)decimalPlaces{
    int divisor = pow(10, decimalPlaces);
    NSLog(@"%.02f",roundf(value * divisor) / divisor);
    return roundf(value * divisor) / divisor;
}





-(void)compareValueInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *departureRunwayTextField = [self.view viewWithTag:105];
    switch (unitId) {
        case 5:
            departureRunwayTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:newValue uptoDecimal:2]];
            [self displayeTotal:0 newValue:0];
            break;
    }
}





/** Create Method **/
-(void)calculateTakeOfTotalRunwayByTempInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    /** Field Value of TOTAL TAKEOFF RUNWAY **/
    UITextField *lowerColoumTextField = [self.view viewWithTag:121];
    UITextField *lowerLengthTextField = [self.view viewWithTag:122];
    UITextField *heigherColoumTextField = [self.view viewWithTag:123];
    UITextField *heigherLengthTextField = [self.view viewWithTag:124];
    UITextField *takeOffRunwayTextField = [self.view viewWithTag:102];
    
    /** Field Value of TOTAL LANDING RUNWAY **/
    UITextField *lowerColoumLandingTextField = [self.view viewWithTag:131];
    UITextField *lowerLengthLandingTextField = [self.view viewWithTag:132];
    UITextField *heigherColoumLandingTextField = [self.view viewWithTag:133];
    UITextField *heigherLengthLandingTextField = [self.view viewWithTag:134];
    UITextField *takeOffRunwayLandingTextField = [self.view viewWithTag:103];
    
    /** Field Value of LANDING Weight **/
    UITextField *atLandingTextField = [self.view viewWithTag:145];
    /** Field Value of LANDING Weight **/
    UITextField *atThisFlightTextField = [self.view viewWithTag:142];
    /** Field Value of Destination Runway **/
    UITextField *destinationRunwayTextField = [self.view viewWithTag:115];
    float difference;
    switch (unitId) {
        case 1:
            atThisFlightTextField.text = [NSString stringWithFormat:@"%d",(int)newValue];
            [self calculateRowValueInUnit:unitId toNewValue:newValue row:0];
            [self calculateAtThisFlightValueInUnit:0 toNewValue:newValue row:0];
            [self calculateAtLB1ValueInUnit:0 toNewValue:newValue row:0];
            [self calculateAtLB2ValueInUnit:0 toNewValue:newValue row:0];
            break;
        case 2:
            difference = [lowerLengthTextField.text doubleValue] +((([heigherLengthTextField.text doubleValue] - [lowerLengthTextField.text doubleValue])/([heigherColoumTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]))*(newValue - [lowerColoumTextField.text doubleValue]));
            takeOffRunwayTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:difference uptoDecimal:2]];
            break;
        case 3:
            atLandingTextField.text = [NSString stringWithFormat:@"%d",(int)newValue];
            [self calculateRowValueInUnit:unitId toNewValue:newValue row:0];
            [self calculateAtLandingValueInUnit:0 toNewValue:newValue row:0];
            [self calculateAtLB1ValueInUnit:0 toNewValue:newValue row:0];
            [self calculateAtLB2ValueInUnit:0 toNewValue:newValue row:0];
            break;
        case 4:
            difference = [lowerLengthLandingTextField.text doubleValue] +((([heigherLengthLandingTextField.text doubleValue] - [lowerLengthLandingTextField.text doubleValue])/([heigherColoumLandingTextField.text doubleValue] - [lowerColoumLandingTextField.text doubleValue]))*(newValue - [lowerColoumLandingTextField.text doubleValue]));
            takeOffRunwayLandingTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:difference uptoDecimal:2]];
            break;
        case 5:
            destinationRunwayTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:newValue uptoDecimal:2]];
            [self displayeTotal:0 newValue:0];
        default:
            
            break;
    }
    [self displayeTotal:0 newValue:0];
}


-(void)calculateTakeOfTotalRunwayInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *lowerColoumTextField = [self.view viewWithTag:121];
    UITextField *lowerLengthTextField = [self.view viewWithTag:122];
    UITextField *heigherColoumTextField = [self.view viewWithTag:123];
    UITextField *heigherLengthTextField = [self.view viewWithTag:124];
    UITextField *takeOffTempTextField = [self.view viewWithTag:112];
    UITextField *takeOffRunwayTextField = [self.view viewWithTag:102];
    float difference;
    switch (unitId) {
        case 1:
            difference = [lowerLengthTextField.text doubleValue] +((([heigherLengthTextField.text doubleValue] - [lowerLengthTextField.text doubleValue])/([heigherColoumTextField.text doubleValue] - newValue))*([takeOffTempTextField.text doubleValue] - newValue));
            break;
        case 2:
            difference = newValue +((([heigherLengthTextField.text doubleValue] - newValue)/([heigherColoumTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        case 3:
            difference = [lowerLengthTextField.text doubleValue] +((([heigherLengthTextField.text doubleValue] - [lowerLengthTextField.text doubleValue])/(newValue - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        case 4:
            difference = [lowerLengthTextField.text doubleValue] +(((newValue - [lowerLengthTextField.text doubleValue])/([heigherColoumTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        default:
            
            break;
    }
    takeOffRunwayTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:difference uptoDecimal:2]];
    [self displayeTotal:0 newValue:0];
}

-(void)calculateLandingTotalRunwayInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *lowerColoumTextField = [self.view viewWithTag:131];
    UITextField *lowerLengthTextField = [self.view viewWithTag:132];
    UITextField *heigherColoumTextField = [self.view viewWithTag:133];
    UITextField *heigherLengthTextField = [self.view viewWithTag:134];
    UITextField *takeOffTempTextField = [self.view viewWithTag:114];
    UITextField *takeOffRunwayTextField = [self.view viewWithTag:103];
    float difference;
    switch (unitId) {
        case 1:
            difference = [lowerLengthTextField.text doubleValue] +((([heigherLengthTextField.text doubleValue] - [lowerLengthTextField.text doubleValue])/([heigherColoumTextField.text doubleValue] - newValue))*([takeOffTempTextField.text doubleValue] - newValue));
            break;
        case 2:
            difference = newValue +((([heigherLengthTextField.text doubleValue] - newValue)/([heigherColoumTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        case 3:
            difference = [lowerLengthTextField.text doubleValue] +((([heigherLengthTextField.text doubleValue] - [lowerLengthTextField.text doubleValue])/(newValue - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        case 4:
            difference = [lowerLengthTextField.text doubleValue] +(((newValue - [lowerLengthTextField.text doubleValue])/([heigherColoumTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]))*([takeOffTempTextField.text doubleValue] - [lowerColoumTextField.text doubleValue]));
            break;
        default:
            
            break;
    }
    takeOffRunwayTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:difference uptoDecimal:2]];
    [self displayeTotal:0 newValue:0];
}
-(void)calculateTakeOfInterPolationInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    
    
}



#pragma mark Fifth Row Calculation
-(void)calculateRowValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightTextField = [self.view viewWithTag:142];
    UITextField *emptyFuelWeightTextField = [self.view viewWithTag:145];
    UITextField *atLB1TextField = [self.view viewWithTag:143];
    UITextField *atLB2TextField = [self.view viewWithTag:144];
    
    float difference,otherDifference;
    switch (unitId) {
        case 1:
            difference = newValue - ((newValue-[emptyFuelWeightTextField.text doubleValue])/3);
            otherDifference = newValue - ((newValue-[emptyFuelWeightTextField.text doubleValue])/3)*2;
            atLB1TextField.text = [NSString stringWithFormat:@"%d",(int)difference];
            atLB2TextField.text = [NSString stringWithFormat:@"%d",(int)otherDifference];
            //[self calculateReverseValueInUnit:0 toNewValue:newValue row:rowIndex];
            break;
        case 3:
            difference = [grossWeightTextField.text doubleValue] - (([grossWeightTextField.text doubleValue]-newValue)/3);
            otherDifference = [grossWeightTextField.text doubleValue] - (([grossWeightTextField.text doubleValue]-newValue)/3)*2;
            atLB1TextField.text = [NSString stringWithFormat:@"%d",(int)difference];
            atLB2TextField.text = [NSString stringWithFormat:@"%d",(int)otherDifference];
            //[self calculateEmptyFuelWaitValueInUnit:0 toNewValue:newValue row:0];
            break;
    }
}

-(void)calculateTopRowValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    switch (unitId) {
        case 1:
            [self calculateReverseValueInUnit:0 toNewValue:newValue row:rowIndex];
            break;
        case 6:
            [self calculateEmptyFuelWaitValueInUnit:0 toNewValue:newValue row:0];
            break;
    }
}

-(void)calculateFifthRowValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    UITextField *atThisFlightUpTextField = [self.view viewWithTag:142];
    UITextField *atLB1UpTextField = [self.view viewWithTag:143];
    UITextField *atLB2UpTextField = [self.view viewWithTag:144];
    UITextField *atLandingUpTextField = [self.view viewWithTag:145];
    UITextField *emptyFuelWeightUpTextField = [self.view viewWithTag:146];
    
    
    //UITextField *grossWeightTextField = [self.view viewWithTag:91+((rowIndex-9)*10)];
    UITextField *atThisFlightTextField = [self.view viewWithTag:92+((rowIndex-9)*10)];
    UITextField *atLB1TextField = [self.view viewWithTag:93+((rowIndex-9)*10)];
    UITextField *atLB2TextField = [self.view viewWithTag:94+((rowIndex-9)*10)];
    UITextField *atLandingTextField = [self.view viewWithTag:95+((rowIndex-9)*10)];
    UITextField *emptyFuelWeightTextField = [self.view viewWithTag:96+((rowIndex-9)*10)];
    
    
    float differenceAtThisFlight,differenceatLB1,differenceAtLB2,differenceAtLandingTextField,differenceEmptyFuelWeight;
    switch (unitId) {
        case 1:
            
            differenceAtThisFlight = sqrt(([atThisFlightUpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*newValue;
            atThisFlightTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtThisFlight uptoDecimal:2]];
            
            differenceatLB1 = sqrt(([atLB1UpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*newValue;
            atLB1TextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceatLB1 uptoDecimal:2]];
            
            differenceAtLB2 = sqrt(([atLB2UpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*newValue;
            atLB2TextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLB2 uptoDecimal:2]];
            
            differenceAtLandingTextField = sqrt(([atLandingUpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*newValue;
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
            
            differenceEmptyFuelWeight = sqrt(([emptyFuelWeightUpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*newValue;
            emptyFuelWeightTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceEmptyFuelWeight uptoDecimal:2]];
            
            if (rowIndex == NINETHROW) {
                UITextField *landingRequiredTextField = [self.view viewWithTag:104];
                landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
            }
            if (rowIndex == EIGHTHROW) {
                UITextField *TakeOffRequiredTextField = [self.view viewWithTag:101];
                TakeOffRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtThisFlight uptoDecimal:2]];
            }
            break;
    }
    
}



#pragma marl change color when limit exceed
-(void)displayeTotal:(NSInteger)selectedTag newValue:(double)newValue {
    UITextField *takeOffRunwayTextField = [self.view viewWithTag:102];
    UITextField *departureRunwayTextField = [self.view viewWithTag:105];
    if ([takeOffRunwayTextField.text doubleValue] < [departureRunwayTextField.text doubleValue] || ([takeOffRunwayTextField.text doubleValue] == 0 && [departureRunwayTextField.text doubleValue] == 0)) {
        takeOffRunwayTextField.layer.borderColor=[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
        
    }else
    {
        takeOffRunwayTextField.layer.borderColor = [[UIColor redColor] CGColor];
        takeOffRunwayTextField.layer.borderWidth = 1.0f;
        takeOffRunwayTextField.layer.cornerRadius = 5;
    }
    
    UITextField *takeOffLandingTextField = [self.view viewWithTag:103];
    UITextField *departureLandingTextField = [self.view viewWithTag:115];
    if ([takeOffLandingTextField.text doubleValue] < [departureLandingTextField.text doubleValue] || ([takeOffLandingTextField.text doubleValue] == 0 && [departureLandingTextField.text doubleValue] == 0)) {
        takeOffLandingTextField.layer.borderColor=[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
        
    }else
    {
        takeOffLandingTextField.layer.borderColor=[UIColor redColor].CGColor;
        takeOffLandingTextField.layer.borderWidth = 1.0f;
        takeOffLandingTextField.layer.cornerRadius = 5;
    }
}




/***** Reverse Programming ****/
-(void)calculateAtLandingValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+(6+i)*10];
        UITextField *atLandingTextField = [self.view viewWithTag:95+((6+i)*10)];
        
        float differenceAtLandingTextField;
        
        differenceAtLandingTextField = sqrt((newValue/[grossWeightUpTextField.text doubleValue]))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        if (rowIndex == NINETHROW && differenceAtLandingTextField > 0) {
            UITextField *landingRequiredTextField = [self.view viewWithTag:104];
            landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
    }
}
-(void)calculateAtThisFlightValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+(6+i)*10];
        UITextField *atLandingTextField = [self.view viewWithTag:92+((6+i)*10)];
        
        float differenceAtLandingTextField;
        
        differenceAtLandingTextField = sqrt((newValue/[grossWeightUpTextField.text doubleValue]))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        
        if (rowIndex == EIGHTHROW && differenceAtLandingTextField >0) {
            UITextField *landingRequiredTextField = [self.view viewWithTag:101];
            landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
    }
}



-(void)calculateAtLB1ValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    UITextField *atLB1UpTextField = [self.view viewWithTag:143];
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+(6+i)*10];
        UITextField *atLandingTextField = [self.view viewWithTag:93+((6+i)*10)];
        
        float differenceAtLandingTextField;
        
        differenceAtLandingTextField = sqrt(([atLB1UpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        
        if (rowIndex == EIGHTHROW && differenceAtLandingTextField >0) {
            UITextField *landingRequiredTextField = [self.view viewWithTag:101];
            landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
    }
}
-(void)calculateAtLB2ValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    UITextField *atLB2UpTextField = [self.view viewWithTag:144];
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+(6+i)*10];
        UITextField *atLandingTextField = [self.view viewWithTag:94+((6+i)*10)];
        
        float differenceAtLandingTextField;
        
        differenceAtLandingTextField = sqrt(([atLB2UpTextField.text doubleValue]/[grossWeightUpTextField.text doubleValue]))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        
        if (rowIndex == EIGHTHROW && differenceAtLandingTextField >0) {
            UITextField *landingRequiredTextField = [self.view viewWithTag:101];
            landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
    }
}

-(void)calculateEmptyFuelWaitValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *grossWeightUpTextField = [self.view viewWithTag:141];
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+(6+i)*10];
        UITextField *atLandingTextField = [self.view viewWithTag:96+((6+i)*10)];
        
        float differenceAtLandingTextField;
        
        differenceAtLandingTextField = sqrt((newValue/[grossWeightUpTextField.text doubleValue]))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
    }
}

-(void)calculateReverseValueInUnit:(NSInteger)unitId toNewValue:(double)newValue row:(PerformanceMeasurement)rowIndex {
    
    UITextField *atThisFlightUpTextField = [self.view viewWithTag:142];
    UITextField *atLB1UpTextField = [self.view viewWithTag:143];
    UITextField *atLB2UpTextField = [self.view viewWithTag:144];
    UITextField *atLandingUpTextField = [self.view viewWithTag:145];
    UITextField *emptyFuelWeightUpTextField = [self.view viewWithTag:146];
    
    for (int i = 0; i < 12; i++) {
        UITextField *grossWeightTextField = [self.view viewWithTag:91+((6+i)*10)];
        UITextField *atThisFlightTextField = [self.view viewWithTag:92+((6+i)*10)];
        UITextField *atLB1TextField = [self.view viewWithTag:93+((6+i)*10)];
        UITextField *atLB2TextField = [self.view viewWithTag:94+((6+i)*10)];
        UITextField *atLandingTextField = [self.view viewWithTag:95+((6+i)*10)];
        UITextField *emptyFuelWeightTextField = [self.view viewWithTag:96+((6+i)*10)];
        
        
        float differenceAtThisFlight,differenceatLB1,differenceAtLB2,differenceAtLandingTextField,differenceEmptyFuelWeight;
        
        differenceAtThisFlight = sqrt(([atThisFlightUpTextField.text doubleValue]/newValue))*[grossWeightTextField.text doubleValue];
        if (differenceAtThisFlight > 0) {
            atThisFlightTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtThisFlight uptoDecimal:2]];
            
        }
        
        differenceatLB1 = sqrt(([atLB1UpTextField.text doubleValue]/newValue))*[grossWeightTextField.text doubleValue];
        if (differenceatLB1 > 0) {
            atLB1TextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceatLB1 uptoDecimal:2]];
        }
        
        differenceAtLB2 = sqrt(([atLB2UpTextField.text doubleValue]/newValue))*[grossWeightTextField.text doubleValue];
        if (differenceAtLB2 > 0) {
            atLB2TextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLB2 uptoDecimal:2]];
        }
        
        differenceAtLandingTextField = sqrt(([atLandingUpTextField.text doubleValue]/newValue))*[grossWeightTextField.text doubleValue];
        if (differenceAtLandingTextField > 0) {
            atLandingTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        
        
        differenceEmptyFuelWeight = sqrt(([emptyFuelWeightUpTextField.text doubleValue]/newValue))*[grossWeightTextField.text doubleValue];
        if (differenceEmptyFuelWeight > 0) {
            emptyFuelWeightTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceEmptyFuelWeight uptoDecimal:2]];
        }
        
        
        if (rowIndex == 4 && differenceAtLandingTextField > 0) {
            UITextField *landingRequiredTextField = [self.view viewWithTag:104];
            landingRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtLandingTextField uptoDecimal:2]];
        }
        if (rowIndex == 3 && differenceAtThisFlight > 0) {
            UITextField *TakeOffRequiredTextField = [self.view viewWithTag:101];
            TakeOffRequiredTextField.text = [NSString stringWithFormat:@"%.02f",[self getRoundedForValue:differenceAtThisFlight uptoDecimal:2]];
        }
    }
}

-(BOOL)exist
{
    NSManagedObjectContext *managedObjectContext=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"TOLD" inManagedObjectContext:managedObjectContext];
    
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
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"TOLD" inManagedObjectContext:context];
            TOLD *toldElement=[[TOLD alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            toldElement.name=self.nameTextField.text;
            
            toldElement.takeOffVRReq = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:101]).text doubleValue]];
            toldElement.takeOffRunwayReq = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:102]).text doubleValue]];
            toldElement.landingRunwayReq = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:103]).text doubleValue]];
            toldElement.landingVrefReq = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:104]).text doubleValue]];
            toldElement.departureUsableLength = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:105]).text doubleValue]];
            toldElement.takeOffWeight = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:111]).text doubleValue]];
            toldElement.takeOffTemp = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:112]).text doubleValue]];
            toldElement.lendingWeight = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:113]).text doubleValue]];
            toldElement.landingTemp = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:114]).text doubleValue]];
            toldElement.destinationUsableLength = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:115]).text doubleValue]];
            
            toldElement.coloumLowerTakeOFF = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:121]).text doubleValue]];
            toldElement.lengthLowerTakeOFF = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:122]).text doubleValue]];
            toldElement.coloumHigherTakeOFF = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:123]).text doubleValue]];
            toldElement.lengthHigherTakeOFF = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:124]).text doubleValue]];
            toldElement.coloumLandingLower = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:131]).text doubleValue]];
            toldElement.lengthLandingLower = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:132]).text doubleValue]];
            toldElement.coloumLandingHigher = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:133]).text doubleValue]];
            toldElement.lengthLandingLower = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:134]).text doubleValue]];
            
            toldElement.grossWeight = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:141]).text doubleValue]];
            toldElement.atThisFlight = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:142]).text doubleValue]];
            toldElement.aTLB1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:143]).text doubleValue]];
            toldElement.atLB2 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:144]).text doubleValue]];
            toldElement.atLanding = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:145]).text doubleValue]];
            toldElement.emptyFuelWeight = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:146]).text doubleValue]];
            
            toldElement.grossWeightVso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:151]).text doubleValue]];
            toldElement.atThisFlightVso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:152]).text doubleValue]];
            toldElement.atLB1Vso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:153]).text doubleValue]];
            toldElement.atLB2Vso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:154]).text doubleValue]];
            toldElement.atLandingVso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:155]).text doubleValue]];
            toldElement.emptyFuelWeightVso = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:156]).text doubleValue]];
            
            toldElement.grossWeightVs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:161]).text doubleValue]];
            toldElement.atThisFlightVs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:162]).text doubleValue]];
            toldElement.atLB1Vs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:163]).text doubleValue]];
            toldElement.atLB2Vs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:164]).text doubleValue]];
            toldElement.atLandingVs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:165]).text doubleValue]];
            toldElement.emptyFuelWeightVs1 = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:166]).text doubleValue]];
            
            toldElement.grossWeightVr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:171]).text doubleValue]];
            toldElement.atThisFlightVr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:172]).text doubleValue]];
            toldElement.atLB1Vr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:173]).text doubleValue]];
            toldElement.atLB2Vr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:174]).text doubleValue]];
            toldElement.atLandingVr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:175]).text doubleValue]];
            toldElement.emptyFuelWeightVr = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:176]).text doubleValue]];
            
            toldElement.grossWeightVx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:181]).text doubleValue]];
            toldElement.atThisFlightVx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:182]).text doubleValue]];
            toldElement.atLB1Vx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:183]).text doubleValue]];
            toldElement.atLB2Vx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:184]).text doubleValue]];
            toldElement.atLandingVx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:185]).text doubleValue]];
            toldElement.emptyFuelWeightVx = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:186]).text doubleValue]];
            
            toldElement.grossWeightVy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:191]).text doubleValue]];
            toldElement.atThisFlightVy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:192]).text doubleValue]];
            toldElement.atLB1Vy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:193]).text doubleValue]];
            toldElement.atLB2Vy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:194]).text doubleValue]];
            toldElement.atLandingVy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:195]).text doubleValue]];
            toldElement.emptyFuelWeightVy = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:196]).text doubleValue]];
            
            toldElement.grossWeightVg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:201]).text doubleValue]];
            toldElement.atThisFlightVg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:202]).text doubleValue]];
            toldElement.atLB1Vg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:203]).text doubleValue]];
            toldElement.atLB2Vg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:204]).text doubleValue]];
            toldElement.atLandingVg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:205]).text doubleValue]];
            toldElement.emptyFuelWeightVg = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:206]).text doubleValue]];
            
            toldElement.grossWeightVlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:211]).text doubleValue]];
            toldElement.atThisFlightVlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:212]).text doubleValue]];
            toldElement.atLB1Vlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:213]).text doubleValue]];
            toldElement.atLB2Vlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:214]).text doubleValue]];
            toldElement.atLandingVlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:215]).text doubleValue]];
            toldElement.emptyFuelWeightVlo = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:216]).text doubleValue]];
            
            toldElement.grossWeightVle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:221]).text doubleValue]];
            toldElement.atThisFlightVle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:222]).text doubleValue]];
            toldElement.atLB1Vle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:223]).text doubleValue]];
            toldElement.atLB2Vle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:224]).text doubleValue]];
            toldElement.atLandingVle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:225]).text doubleValue]];
            toldElement.emptyFuelWeightVle = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:226]).text doubleValue]];
            
            toldElement.grossWeightVfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:231]).text doubleValue]];
            toldElement.atThisFlightVfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:232]).text doubleValue]];
            toldElement.atLB1Vfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:233]).text doubleValue]];
            toldElement.atLB2Vfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:234]).text doubleValue]];
            toldElement.atLandingVfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:235]).text doubleValue]];
            toldElement.emptyFuelWeightVfe = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:236]).text doubleValue]];
            
            toldElement.grossWeightVa = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:241]).text doubleValue]];
            toldElement.atThisFlightVa = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:242]).text doubleValue]];
            toldElement.atLB1Va = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:243]).text doubleValue]];
            toldElement.atLB2Va = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:244]).text doubleValue]];
            toldElement.atLandingVa = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:245]).text doubleValue]];
            toldElement.emptyFuelWeightVa = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:246]).text doubleValue]];
            
            toldElement.grossWeightVno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:251]).text doubleValue]];
            toldElement.atThisFlightVno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:252]).text doubleValue]];
            toldElement.atLB1Vno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:253]).text doubleValue]];
            toldElement.atLB2Vno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:254]).text doubleValue]];
            toldElement.atLandingVno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:255]).text doubleValue]];
            toldElement.emptyFuelWeightVno = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:256]).text doubleValue]];
            
            toldElement.grossWeightVne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:261]).text doubleValue]];
            toldElement.atThisFlightVne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:262]).text doubleValue]];
            toldElement.atLB1Vne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:263]).text doubleValue]];
            toldElement.atLB2Vne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:264]).text doubleValue]];
            toldElement.atLandingVne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:265]).text doubleValue]];
            toldElement.emptyFuelWeightVne = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:266]).text doubleValue]];
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [arrayFiles addObject:toldElement];
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
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"TOLD" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (TOLD *toldElementToDelete in fetchedData) {
            [context deleteObject:toldElementToDelete];
        }
    }
    [self.SavedRecordTableView reloadData];
}
- (void)getSavedFiles{
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"TOLD" inManagedObjectContext:context];
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
    static NSString *MyIdentifier = @"TOLDItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier];
    }
    
    TOLD *toldElement=[arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.SavedRecordTableView.bounds.size.width, 28.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = toldElement.name;
    
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
    TOLD *toldElement=[arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:toldElement];
    [self.SavedRecordTableView reloadData];
}
-(void)displayDetails:(TOLD*)toldElement {
    ((UITextField *)[self.view viewWithTag:101]).text=[toldElement.takeOffVRReq doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.takeOffVRReq doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:102]).text=[toldElement.takeOffRunwayReq doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.takeOffRunwayReq doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:103]).text=[toldElement.landingRunwayReq doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.landingRunwayReq doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:104]).text=[toldElement.landingVrefReq doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.landingVrefReq doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:105]).text=[toldElement.departureUsableLength doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.departureUsableLength doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:111]).text=[toldElement.takeOffWeight doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.takeOffWeight doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:112]).text=[toldElement.takeOffTemp doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.takeOffTemp doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:113]).text=[toldElement.lendingWeight doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.lendingWeight doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:114]).text=[toldElement.landingTemp doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.landingTemp doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:115]).text=[toldElement.destinationUsableLength doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.destinationUsableLength doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:121]).text=[toldElement.coloumLowerTakeOFF doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.coloumLowerTakeOFF doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:122]).text=[toldElement.lengthLowerTakeOFF doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.lengthLowerTakeOFF doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:123]).text=[toldElement.coloumHigherTakeOFF doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.coloumHigherTakeOFF doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:124]).text=[toldElement.lengthHigherTakeOFF doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.lengthHigherTakeOFF doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:131]).text=[toldElement.coloumLandingLower doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.coloumLandingLower doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:132]).text=[toldElement.lengthLandingLower doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.lengthLandingLower doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:133]).text=[toldElement.coloumLandingHigher doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.coloumLandingHigher doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:134]).text=[toldElement.lengthLandingLower doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.lengthLandingLower doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:141]).text=[toldElement.grossWeight doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeight doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:142]).text=[toldElement.atThisFlight doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlight doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:143]).text=[toldElement.aTLB1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.aTLB1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:144]).text=[toldElement.atLB2 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:145]).text=[toldElement.atLanding doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLanding doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:146]).text=[toldElement.emptyFuelWeight doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeight doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:151]).text=[toldElement.grossWeightVso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVso doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:152]).text=[toldElement.atThisFlightVso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVso doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:153]).text=[toldElement.atLB1Vso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vso doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:154]).text=[toldElement.atLB2Vso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vso doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:155]).text=[toldElement.atLandingVso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVso doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:156]).text=[toldElement.emptyFuelWeightVso doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVso doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:161]).text=[toldElement.grossWeightVs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVs1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:162]).text=[toldElement.atThisFlightVs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVs1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:163]).text=[toldElement.atLB1Vs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vs1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:164]).text=[toldElement.atLB2Vs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vs1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:165]).text=[toldElement.atLandingVs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVs1 doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:166]).text=[toldElement.emptyFuelWeightVs1 doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVs1 doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:171]).text=[toldElement.grossWeightVr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:172]).text=[toldElement.atThisFlightVr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:173]).text=[toldElement.atLB1Vr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:174]).text=[toldElement.atLB2Vr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:175]).text=[toldElement.atLandingVr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:176]).text=[toldElement.emptyFuelWeightVr doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVr doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:181]).text=[toldElement.grossWeightVx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVx doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:182]).text=[toldElement.atThisFlightVx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVx doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:183]).text=[toldElement.atLB1Vx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vx doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:184]).text=[toldElement.atLB2Vx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vx doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:185]).text=[toldElement.atLandingVx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVx doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:186]).text=[toldElement.emptyFuelWeightVx doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVx doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:191]).text=[toldElement.grossWeightVy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVy doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:192]).text=[toldElement.atThisFlightVy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVy doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:193]).text=[toldElement.atLB1Vy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vy doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:194]).text=[toldElement.atLB2Vy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vy doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:195]).text=[toldElement.atLandingVy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVy doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:196]).text=[toldElement.emptyFuelWeightVy doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVy doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:201]).text=[toldElement.grossWeightVg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVg doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:202]).text=[toldElement.atThisFlightVg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVg doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:203]).text=[toldElement.atLB1Vg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vg doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:204]).text=[toldElement.atLB2Vg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vg doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:205]).text=[toldElement.atLandingVg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVg doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:206]).text=[toldElement.emptyFuelWeightVg doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVg doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:211]).text=[toldElement.grossWeightVlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVlo doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:212]).text=[toldElement.atThisFlightVlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVlo doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:213]).text=[toldElement.atLB1Vlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vlo doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:214]).text=[toldElement.atLB2Vlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vlo doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:215]).text=[toldElement.atLandingVlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVlo doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:216]).text=[toldElement.emptyFuelWeightVlo doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVlo doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:221]).text=[toldElement.grossWeightVle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVle doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:222]).text=[toldElement.atThisFlightVle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVle doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:223]).text=[toldElement.atLB1Vle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vle doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:224]).text=[toldElement.atLB2Vle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vle doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:225]).text=[toldElement.atLandingVle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVle doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:226]).text=[toldElement.emptyFuelWeightVle doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVle doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:231]).text=[toldElement.grossWeightVfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVfe doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:232]).text=[toldElement.atThisFlightVfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVfe doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:233]).text=[toldElement.atLB1Vfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vfe doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:234]).text=[toldElement.atLB2Vfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vfe doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:235]).text=[toldElement.atLandingVfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVfe doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:236]).text=[toldElement.emptyFuelWeightVfe doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVfe doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:241]).text=[toldElement.grossWeightVa doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVa doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:242]).text=[toldElement.atThisFlightVa doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVa doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:243]).text=[toldElement.atLB1Va doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Va doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:244]).text=[toldElement.atLB2Va doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Va doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:245]).text=[toldElement.atLandingVa doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVa doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:246]).text=[toldElement.emptyFuelWeightVa doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVa doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:251]).text=[toldElement.grossWeightVno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVno doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:252]).text=[toldElement.atThisFlightVno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVno doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:253]).text=[toldElement.atLB1Vno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vno doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:254]).text=[toldElement.atLB2Vno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vno doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:255]).text=[toldElement.atLandingVno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVno doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:256]).text=[toldElement.emptyFuelWeightVno doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVno doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:261]).text=[toldElement.grossWeightVne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.grossWeightVne doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:262]).text=[toldElement.atThisFlightVne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atThisFlightVne doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:263]).text=[toldElement.atLB1Vne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB1Vne doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:264]).text=[toldElement.atLB2Vne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLB2Vne doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:265]).text=[toldElement.atLandingVne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.atLandingVne doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:266]).text=[toldElement.emptyFuelWeightVne doubleValue]>0.0?[NSString stringWithFormat:@"%f", [toldElement.emptyFuelWeightVne doubleValue]]:@"";
}
@end
