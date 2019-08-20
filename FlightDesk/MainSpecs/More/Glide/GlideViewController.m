//
//  GlideViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "GlideViewController.h"
#import "CalcGlide+CoreDataClass.h"


#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"
@interface GlideViewController ()<UITextFieldDelegate>
{
    NSMutableArray *arrayFiles;
    NSInteger currentSelectedRow;
}
@end
typedef enum : NSUInteger {
    DISTANCE = 10,
    ETA,
    FUELBURN,
    FUELNM,
    ISA,
    PA,
    DA,
    TAS,
    CLOUDBASES,
    FREEZINGLEVEL,
    GLIDING
    
} CalculationsMeasurement;
@implementation GlideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"GLIDE";
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
                    textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"GLI%ld",(long)textField.tag+10000]];
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
    [tracker set:kGAIScreenName value:@"GlideviewController"];
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
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"GLI%ld",(long)textField.tag+10000]];
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
                
                [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"GLI%ld",(long)textField.tag+10000]];
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

- (IBAction)clearGliding:(id)sender {
    ((UITextField *)[self.view viewWithTag:201]).text = @"";
    ((UITextField *)[self.view viewWithTag:202]).text = @"";
    ((UITextField *)[self.view viewWithTag:203]).text = @"";
    ((UITextField *)[self.view viewWithTag:204]).text = @"";
    ((UITextField *)[self.view viewWithTag:205]).text = @"";
    ((UITextField *)[self.view viewWithTag:206]).text = @"";
    
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
    if (textField.tag==122) {
        newValue=[self getdecimalTimeFromString:finalString];
    }else if (textField.tag==201) {
        newValue=[[finalString stringByReplacingOccurrencesOfString:@":" withString:@"."] doubleValue];
    }
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
        case DISTANCE:
            [self calculateTimeDistanceOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case ETA:
            [self calculateETAOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case FUELBURN:
            [self calculateFuelBurnOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case FUELNM:
            [self calculateFuelNMOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case ISA:
            [self calculateISAOnChangeInUnit:unitId toNewValue:newValue];
            //No Functionality has been defined
            break;
            
        case PA:
            [self calculatePAOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case DA:
            //No Functionality has been defined
            [self calculateDensityAltitudeOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case TAS:
            [self calculateTASOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case CLOUDBASES:
            [self calculateCloudBasesOnChangeInUnit:unitId toNewValue:newValue];
            break;
            
        case FREEZINGLEVEL:
            [self calculateFreezingLevelOnChangeInUnit:unitId toNewValue:newValue];
            
            break;
            
        case GLIDING:
            [self calculateGlidingOnChangeInUnit:unitId toNewValue:newValue value:secondValue];
            break;
            
        default:
            break;
    }
}

- (void)calculateISAOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    UITextField *altTextField = [self.view viewWithTag:141];
    UITextField *baroTextField = [self.view viewWithTag:142];
    UITextField *tempTextField = [self.view viewWithTag:143];
    UITextField *diffCTextField = [self.view viewWithTag:144];
    UITextField *diffFeetTextField = [self.view viewWithTag:145];
    
    double altValue=0.0,baroValue=0.0,tempValue=0.0,diffC=0.0,diffFeet=0.0;
    switch (unitId) {
        case 1:
            altValue=newValue;
            baroValue=[baroTextField.text doubleValue];
            tempValue=[tempTextField.text doubleValue];
            diffC=(tempValue-(15-((2*altValue)/1000)));
            diffFeet=((29.92-baroValue)*1000)+altValue;
            break;
        case 2:
            altValue=[altTextField.text doubleValue];
            baroValue=newValue;
            tempValue=[tempTextField.text doubleValue];
            diffC=(tempValue-(15-((2*altValue)/1000)));
            diffFeet=((29.92-baroValue)*1000)+altValue;
            break;
        case 3:
            altValue=[altTextField.text doubleValue];
            baroValue=[baroTextField.text doubleValue];
            tempValue=newValue;
            diffC=(tempValue-(15-((2*altValue)/1000)));
            diffFeet=((29.92-baroValue)*1000)+altValue;
            break;
        case 4:
            
            break;
        default:
            break;
    }
    altTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:altValue uptoDecimal:2]];
    baroTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:baroValue uptoDecimal:2]];
    tempTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:tempValue uptoDecimal:2]];
    diffCTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:diffC uptoDecimal:2]];
    diffFeetTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:diffFeet uptoDecimal:2]];
}

- (void)calculateDensityAltitudeOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue
{
    UITextField *altTextField = [self.view viewWithTag:161];
    UITextField *tempTextField = [self.view viewWithTag:162];
    UITextField *baroTextField = [self.view viewWithTag:163];
    UITextField *dewTextField = [self.view viewWithTag:164];
    UITextField *daTextField = [self.view viewWithTag:165];
    
    double dA=0.00, alt=0.00, baro=00.00, temp=0.00, dew=0.00;
    switch (unitId) {
        case 1:
            
            baro=[baroTextField.text doubleValue];
            alt=newValue;
            temp=[tempTextField.text doubleValue];
            dew=[dewTextField.text doubleValue];
            dA=alt+(120*(temp-(15-((2*alt)/1000))));
            
            break;
            
        case 2:
            
            baro=[baroTextField.text doubleValue];
            alt=[altTextField.text doubleValue];
            temp=newValue;
            dew=[dewTextField.text doubleValue];
            
            dA=alt+(120*(temp-(15-((2*alt)/1000))));
            
            
            break;
            
        case 3:
            
            
            
            break;
            
        case 4:
            
            
            
            break;
            
        case 5:
            
            break;
            
            
        default:
            break;
    }
    
    daTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:dA uptoDecimal:2]];
    altTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:alt uptoDecimal:2]];
    baroTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:baro uptoDecimal:2]];
    tempTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:temp uptoDecimal:2]];
}

- (void)calculateTimeDistanceOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    double timeInMinutes = 0.00;
    double speedAsKTS = 0.00;
    double smValue=0.00;
    double nmValue=0.00;
    
    UITextField *minutesTextField = [self.view viewWithTag:101];
    UITextField *ktsTextField = [self.view viewWithTag:102];
    UITextField *nmTextField = [self.view viewWithTag:103];
    UITextField *smTextField = [self.view viewWithTag:104];
    
    switch (unitId) {
        case 1://Time
            timeInMinutes = newValue;
            if (self.lastTextFieldTag==nmTextField.tag) {
                nmValue=[nmTextField.text doubleValue];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                smValue = nmValue * 1.1508;
            }else if (self.lastTextFieldTag==smTextField.tag) {
                smValue=[smTextField.text doubleValue];
                nmValue=smValue/1.1508;
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
            }else {
                speedAsKTS = [ktsTextField.text doubleValue];
                nmValue = timeInMinutes * (speedAsKTS );
                smValue = nmValue * 1.1508;
            }
            break;
            
        case 2://KTS - Knots per hour
            speedAsKTS = newValue;
            
            if (self.lastTextFieldTag==nmTextField.tag) {
                nmValue=[nmTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
                smValue = nmValue * 1.1508;
            }else if(self.lastTextFieldTag==smTextField.tag) {
                smValue=[smTextField.text doubleValue];
                nmValue=smValue/1.1508;
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
            }else {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                nmValue = timeInMinutes * (speedAsKTS );
                smValue = nmValue * 1.1508;
                
            }
            break;
            
        case 3://NM- Nautical Miles
            nmValue=newValue;
            smValue = nmValue * 1.1508;
            
            if ((self.lastTextFieldTag==smTextField.tag && self.previousTextFieldTag==ktsTextField.tag) || ( self.lastTextFieldTag==ktsTextField.tag)) {
                speedAsKTS=[ktsTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
            }else if ((self.lastTextFieldTag==smTextField.tag && self.previousTextFieldTag==minutesTextField.tag) || ( self.lastTextFieldTag==minutesTextField.tag)) {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
            }
            break;
            
        case 4://SM - Statute Miles
            smValue=newValue;
            nmValue=smValue/1.1508;
            if ((self.lastTextFieldTag==nmTextField.tag && self.previousTextFieldTag==ktsTextField.tag) || ( self.lastTextFieldTag==ktsTextField.tag)) {
                speedAsKTS=[ktsTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
            }else if ((self.lastTextFieldTag==nmTextField.tag && self.previousTextFieldTag==minutesTextField.tag) || (self.lastTextFieldTag==minutesTextField.tag)) {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
            }
            
            break;
            
        default:
            break;
    }
    
    
    
    minutesTextField.text=[self convertDecimalTimeTostring:timeInMinutes];
    ktsTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:speedAsKTS uptoDecimal:2]];
    nmTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:nmValue uptoDecimal:2]];
    smTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:smValue uptoDecimal:2]];
}

- (void)calculateETAOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue{
    UITextField *ktsTextField = [self.view viewWithTag:111];
    UITextField *nmTextField = [self.view viewWithTag:112];
    UITextField *smTextField = [self.view viewWithTag:113];
    UITextField *minutesTextField = [self.view viewWithTag:114];
    
    double timeInMinutes = 0.00;
    double speedAsKTS = 0.00;
    double smValue=0.00;
    double nmValue=0.00;
    
    switch (unitId) {
        case 1://KTS(Knots per hour)
            speedAsKTS = newValue;
            
            if (self.lastTextFieldTag==nmTextField.tag) {
                nmValue=[nmTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
                smValue = nmValue * 1.1508;
            }else if(self.lastTextFieldTag==smTextField.tag) {
                smValue=[smTextField.text doubleValue];
                nmValue=smValue/1.1508;
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
            }else {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                nmValue = timeInMinutes * (speedAsKTS );
                smValue = nmValue * 1.1508;
                
            }
            break;
            
        case 2://NM - Nutical Miles
            nmValue=newValue;
            smValue = nmValue * 1.1508;
            
            if ((self.lastTextFieldTag==smTextField.tag && self.previousTextFieldTag==ktsTextField.tag) || ( self.lastTextFieldTag==ktsTextField.tag)) {
                speedAsKTS=[ktsTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
            }else if ((self.lastTextFieldTag==smTextField.tag && self.previousTextFieldTag==minutesTextField.tag) || (self.lastTextFieldTag==minutesTextField.tag)) {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
            }
            break;
            
        case 3://SM - Statute Miles
            smValue=newValue;
            nmValue=smValue/1.1508;
            if ((self.lastTextFieldTag==nmTextField.tag && self.previousTextFieldTag==ktsTextField.tag) || ( self.lastTextFieldTag==ktsTextField.tag)) {
                speedAsKTS=[ktsTextField.text doubleValue];
                if (speedAsKTS>0.0) {
                    timeInMinutes=nmValue/speedAsKTS;
                }
                
            }else if ((self.lastTextFieldTag==nmTextField.tag && self.previousTextFieldTag==minutesTextField.tag) || (self.lastTextFieldTag==minutesTextField.tag)) {
                timeInMinutes = [self getdecimalTimeFromString:minutesTextField.text];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
            }
            break;
            
        case 4://ETA
            timeInMinutes = newValue;
            if (self.lastTextFieldTag==nmTextField.tag) {
                nmValue=[nmTextField.text doubleValue];
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
                smValue = nmValue * 1.1508;
            }else if (self.lastTextFieldTag==smTextField.tag) {
                smValue=[smTextField.text doubleValue];
                nmValue=smValue/1.1508;
                if (timeInMinutes>0.0) {
                    speedAsKTS=nmValue/timeInMinutes;
                }
                
                
            }else {
                speedAsKTS = [ktsTextField.text doubleValue];
                nmValue = timeInMinutes * (speedAsKTS );
                smValue = nmValue * 1.1508;
            }
            break;
            
            
        default:
            break;
    }
    
    minutesTextField.text=[self convertDecimalTimeTostring:timeInMinutes];
    ktsTextField.text=[NSString stringWithFormat:@"%.02f", [self getRoundedForValue:speedAsKTS uptoDecimal:2]];
    nmTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:nmValue uptoDecimal:2]];
    smTextField.text = [NSString stringWithFormat:@"%.02f", [self getRoundedForValue:smValue uptoDecimal:2]];
}

-(void)calculateFuelBurnOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *timeDecimalTextField = [self.view viewWithTag:121];
    UITextField *timeTextField = [self.view viewWithTag:122];
    UITextField *fuelBurnTextField = [self.view viewWithTag:123];
    UITextField *fuelUsedTextField = [self.view viewWithTag:124];
    double timeDecimal = 0.00;
    double fuelBurn=0.00;
    double fuelUsed=0.00;
    NSString *timeString=nil;
    switch (unitId) {
        case 1:  //Decimal Time
            if (self.lastTextFieldTag==fuelBurnTextField.tag || self.lastTextFieldTag==timeTextField.tag) {
                timeString=[self convertDecimalTimeTostring:newValue];
                fuelBurn=[fuelBurnTextField.text doubleValue];
                timeDecimal=newValue;
                fuelUsed=timeDecimal*fuelBurn;
                
            }else {
                timeString=[self convertDecimalTimeTostring:newValue];
                fuelUsed=[fuelUsedTextField.text doubleValue];
                timeDecimal=newValue;
                fuelBurn=fuelUsed/timeDecimal;
            }
            break;
        case 2: // Time
            if (self.lastTextFieldTag==fuelBurnTextField.tag || self.lastTextFieldTag==timeDecimalTextField.tag) {
                timeString=[self convertDecimalTimeTostring:newValue];
                fuelBurn=[fuelBurnTextField.text doubleValue];
                timeDecimal=newValue;
                fuelUsed=timeDecimal*fuelBurn;
            }
            else {
                timeString=[self convertDecimalTimeTostring:newValue];
                fuelUsed=[fuelUsedTextField.text doubleValue];
                timeDecimal=newValue;
                fuelBurn=fuelUsed/timeDecimal;
                
            }
            break;
        case 3: // FuelBurn
            if (self.lastTextFieldTag==fuelUsedTextField.tag ) {
                
                fuelBurn=newValue;
                fuelUsed=[fuelUsedTextField.text doubleValue];
                timeDecimal=fuelUsed/fuelBurn;
                timeString=[self convertDecimalTimeTostring:timeDecimal];
            }else {
                timeString=timeTextField.text;
                
                timeDecimal=[timeDecimalTextField.text doubleValue];
                fuelUsed=timeDecimal*newValue;
                
            }
            break;
        case 4: // FuelUsed
            if (self.lastTextFieldTag==fuelBurnTextField.tag ) {
                fuelUsed=newValue;
                fuelBurn=[fuelBurnTextField.text doubleValue];
                timeDecimal=fuelUsed/fuelBurn;
                timeString=[self convertDecimalTimeTostring:timeDecimal];
            }else {
                timeString=timeTextField.text;
                
                timeDecimal=[timeDecimalTextField.text doubleValue];
                fuelUsed=newValue;
                fuelBurn=newValue/timeDecimal;
                
            }
            break;
        default:
            break;
    }
    
    timeDecimalTextField.text=[NSString stringWithFormat:@"%.2f",[self getRoundedForValue:timeDecimal uptoDecimal:2]];
    timeTextField.text=timeString;
    fuelBurnTextField.text=[NSString stringWithFormat:@"%.2f",[self getRoundedForValue:fuelBurn uptoDecimal:2]];
    fuelUsedTextField.text=[NSString stringWithFormat:@"%.2f",[self getRoundedForValue:fuelUsed uptoDecimal:2]];
    
}

-(void)calculateFuelNMOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    
    UITextField *nmTextField = [self.view viewWithTag:131];
    
    UITextField *timeTextField = [self.view viewWithTag:132];
    
    UITextField *hrTextField = [self.view viewWithTag:133];
    
    UITextField *nmGALTextField = [self.view viewWithTag:134];
    
    UITextField *galNMTextField = [self.view viewWithTag:135];
    
    double nmValue = 0.00,galValue= 0.00, nmGalValue= 0.00, timeVale= 0.00, fuelHr= 0.00;
    
    switch (unitId) {
            
        case 1:
            
            timeVale=[timeTextField.text doubleValue];
            
            fuelHr=[hrTextField.text doubleValue];
            
            nmValue=newValue;
            
            fuelHr=[hrTextField.text doubleValue];
            
            
            
            if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==timeTextField.tag ) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==timeTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                fuelHr=(nmValue*timeVale)/nmGalValue;
                
                galValue=(timeVale/newValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==timeTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==timeTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                fuelHr=(galValue*nmValue)/timeVale;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                timeVale=(nmGalValue*fuelHr)/nmValue;
                
                
                
                galValue=(timeVale/nmValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                timeVale=(galValue/fuelHr)*nmValue;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }
            
            else {
                
                if (fuelHr>0.0) {
                    
                    nmGalValue=(nmValue*timeVale)/fuelHr;
                    
                }
                
                galValue=(timeVale/nmValue)*fuelHr;
                
                
                
            }
            
            
            
            break;
            
        case 2:
            
            timeVale=newValue;
            
            nmValue=[nmTextField.text doubleValue];
            
            fuelHr=[hrTextField.text doubleValue];
            
            if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                
                
                fuelHr=(timeVale*nmValue)/nmGalValue;
                
                galValue=(nmValue/newValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                fuelHr=(galValue*nmValue)/timeVale;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                nmValue=(nmGalValue*fuelHr)/timeVale;
                
                galValue=(timeVale/newValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                nmValue=(timeVale*fuelHr)/galValue;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }
            
            else {
                
                if (fuelHr>0.0) {
                    
                    nmGalValue=(nmValue*timeVale)/fuelHr;
                    
                }
                
                galValue=(timeVale/nmValue)*fuelHr;
                
                
                
            }
            
            break;
            
        case 3:
            
            fuelHr=newValue;
            
            nmValue=[nmTextField.text doubleValue];
            
            timeVale=[timeTextField.text doubleValue];
            
            nmGalValue=(timeVale*nmValue)/newValue;
            
            galValue=(timeVale/nmValue)*newValue;
            
            
            
            if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                timeVale=(nmGalValue*fuelHr)/nmValue;
                
                galValue=(nmValue/newValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                timeVale=(galValue/fuelHr)*nmValue;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==nmGALTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==nmGALTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                nmGalValue=[nmGALTextField.text doubleValue];
                
                nmValue=(nmGalValue*fuelHr)/timeVale;
                
                galValue=(timeVale/newValue)*fuelHr;
                
            }else if ((self.lastTextFieldTag==galNMTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==galNMTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                galValue=[galNMTextField.text doubleValue];
                
                nmValue=(timeVale*fuelHr)/galValue;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }
            
            
            
            else {
                
                if (fuelHr>0.0) {
                    
                    nmGalValue=(nmValue*timeVale)/fuelHr;
                    
                }
                
                galValue=(timeVale/nmValue)*fuelHr;
                
                
                
            }
            
            break;
            
        case 4:
            
            nmGalValue=newValue;
            
            timeVale=[timeTextField.text doubleValue];
            
            nmValue=[nmTextField.text doubleValue];
            
            fuelHr=[hrTextField.text doubleValue];
            
            galValue=[galNMTextField.text doubleValue];
            
            if ((self.lastTextFieldTag==timeTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==timeTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                fuelHr=(timeVale*nmValue)/nmGalValue;
                
                galValue=(timeVale/nmValue)*fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==hrTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==hrTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                
                
                timeVale=(fuelHr*nmGalValue)/nmValue;
                
                galValue=(timeVale/nmValue)*fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==timeTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==timeTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                nmValue=(fuelHr*nmGalValue)/timeVale;
                
                galValue=(timeVale/newValue)*fuelHr;
                
            }
            
            break;
            
        case 5:
            
            nmGalValue=[nmGALTextField.text doubleValue];
            
            timeVale=[timeTextField.text doubleValue];
            
            nmValue=[nmTextField.text doubleValue];
            
            fuelHr=[hrTextField.text doubleValue];
            
            galValue=newValue;
            
            
            
            if ((self.lastTextFieldTag==timeTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==timeTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                
                
                
                
                fuelHr=(galValue*nmValue)/timeVale;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==hrTextField.tag && self.previousTextFieldTag==nmTextField.tag) || (self.previousTextFieldTag==hrTextField.tag && self.lastTextFieldTag==nmTextField.tag)) {
                
                
                
                timeVale=(galValue/fuelHr)*nmValue;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
                
                
            }else if ((self.lastTextFieldTag==timeTextField.tag && self.previousTextFieldTag==hrTextField.tag) || (self.previousTextFieldTag==timeTextField.tag && self.lastTextFieldTag==hrTextField.tag)) {
                
                nmValue=(timeVale/galValue)*fuelHr;
                
                nmGalValue=(nmValue*timeVale)/fuelHr;
                
            }
            
            
            
        default:
            
            break;
            
    }
    
    nmTextField.text=[NSString stringWithFormat:@"%.02f",nmValue];
    
    timeTextField.text=[NSString stringWithFormat:@"%.02f",timeVale];
    
    hrTextField.text=[NSString stringWithFormat:@"%.02f",fuelHr];
    
    nmGALTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:nmGalValue uptoDecimal:2]];
    
    galNMTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:galValue uptoDecimal:2]];
    
}

////
-(void)calculatePAOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *altTextField = [self.view viewWithTag:151];
    UITextField *beroTextField = [self.view viewWithTag:152];
    UITextField *milibarsTextField = [self.view viewWithTag:153];
    UITextField *paTextField = [self.view viewWithTag:154];
    double paValue=0.00;
    double milibars=0.00;
    double beroValue=0.00;
    double altValue=0.00;
    
    switch (unitId) {
        case 1:
            if (self.lastTextFieldTag==paTextField.tag) {
                altValue=newValue;
                beroValue=29.92-(([paTextField.text doubleValue]-newValue)/1000);
                milibars=beroValue*33.8637526;
                paValue=[paTextField.text doubleValue];
            }else {
                altValue=newValue;
                beroValue=[beroTextField.text doubleValue];
                milibars=beroValue*33.8637526;
                if (beroValue>0.0) {
                    paValue=newValue+(1000*(29.92-beroValue));
                }
                
            }
            break;
        case 2:
            if (self.lastTextFieldTag==paTextField.tag) {
                paValue=[paTextField.text doubleValue];
                beroValue=newValue;
                milibars=beroValue*33.8637526;
                altValue=paValue-(1000*(29.92-beroValue));
                
            }else {
                altValue=[altTextField.text doubleValue];
                paValue=altValue+(1000*(29.92-newValue));
                beroValue=newValue;
                milibars=newValue*33.8637526;
                
            }
            break;
        case 3:
            if (self.lastTextFieldTag==paTextField.tag) {
                milibars=newValue;
                beroValue=beroValue/33.8637526;
                paValue=[paTextField.text doubleValue];
                altValue=paValue-(1000*(29.92-beroValue));
            }else {
                milibars=newValue;
                beroValue=newValue/33.8637526;
                altValue=[altTextField.text doubleValue];
                paValue=[altTextField.text doubleValue]+(1000*(29.92-beroValue));
            }
            break;
            
        case 4:
            if (self.lastTextFieldTag==altTextField.tag) {
                altValue=[altTextField.text doubleValue];
                beroValue=29.92-((newValue-altValue)/1000);
                milibars=beroValue*33.8637526;
                paValue=newValue;
                
                
            }else {
                paValue=newValue;
                beroValue=[beroTextField.text doubleValue];
                milibars=beroValue*33.8637526;
                altValue=paValue-(1000*(29.92-beroValue));
            }
            
            break;
            
            
        default:
            break;
    }
    milibarsTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:milibars uptoDecimal:2]];
    paTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:paValue uptoDecimal:2]];
    altTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:altValue uptoDecimal:2]];
    beroTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:beroValue uptoDecimal:2]];
    
}

-(void)calculateTASOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    //TAS=IAS+(IASx0.02x(ALT ÷ 1000))
    UITextField *asTextField = [self.view viewWithTag:171];
    UITextField *altTextField = [self.view viewWithTag:172];
    UITextField *tasTextField = [self.view viewWithTag:173];
    double tas=0.00,asValue=0.00,altValue=0.00;
    switch (unitId) {
        case 1:
            if (self.lastTextFieldTag==tasTextField.tag) {
                asValue=newValue;
                tas=[tasTextField.text doubleValue];
                altValue=((tas-newValue)/(newValue*0.02))*1000;
            }else {
                asValue=newValue;
                altValue=[altTextField.text doubleValue];
                tas=newValue+(newValue*0.02*([altTextField.text doubleValue]/1000));
            }
            break;
        case 2:
            if (self.lastTextFieldTag==tasTextField.tag) {
                tas=[tasTextField.text doubleValue];
                asValue=tas/(1+(0.02*(newValue/1000)));
                altValue=newValue;
                
            }else {
                asValue=[asTextField.text doubleValue];
                altValue=newValue;
                tas=[asTextField.text doubleValue]+([asTextField.text doubleValue]*0.02*(newValue/1000));
            }
            break;
        case 3:
            if (self.lastTextFieldTag==asTextField.tag) {
                asValue=[asTextField.text doubleValue];
                tas=newValue;
                altValue=((tas-newValue)/(newValue*0.02))*1000;
            }else {
                tas=newValue;
                altValue=[altTextField.text doubleValue];
                asValue=tas/(1+(0.02*(altValue/1000)));
                
            }
            
        default:
            break;
    }
    tasTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:tas uptoDecimal:2]];
    asTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:asValue uptoDecimal:2]];
    altTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:altValue uptoDecimal:2]];
    
}

-(void)calculateCloudBasesOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *tempTextField = [self.view viewWithTag:181];
    UITextField *dewTextField = [self.view viewWithTag:182];
    UITextField *basesTextField = [self.view viewWithTag:183];
    double bases=0.00,tempValue=0.00,dewValue=0.00;
    switch (unitId) {
        case 1:
            if (self.lastTextFieldTag==basesTextField.tag) {
                tempValue=newValue;
                bases=[basesTextField.text doubleValue];
                dewValue=newValue-(bases/400);
            }else {
                tempValue=newValue;
                dewValue=[dewTextField.text doubleValue];
                bases=(newValue-dewValue)*400;
            }
            break;
        case 2:
            if (self.lastTextFieldTag==basesTextField.tag) {
                bases=[basesTextField.text doubleValue];
                dewValue=newValue;
                tempValue=(bases/400)+dewValue;
            }else {
                tempValue=[tempTextField.text doubleValue];
                dewValue=newValue;
                bases=(tempValue-newValue)*400;
            }
            break;
        case 3:
            if (self.lastTextFieldTag==dewTextField.tag) {
                bases=newValue;
                dewValue=[dewTextField.text doubleValue];
                tempValue=(bases/400)+dewValue;
            }else {
                tempValue=[tempTextField.text doubleValue];
                bases=newValue;
                dewValue=newValue-(bases/400);
            }
        default:
            break;
    }
    basesTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:bases uptoDecimal:2]];
    dewTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:dewValue uptoDecimal:2]];
    tempTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:tempValue uptoDecimal:2]];
    
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

-(void)calculateGlidingOnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue value:(NSString*)secondValue {
    
    if (unitId == 3)
        checkTime = YES;
    else if(unitId == 6)
    {
        checkTime = NO;
        // unitId = 5;
    }
    UITextField *ratioTextField = [self.view viewWithTag:201];
    UITextField *altTextField = [self.view viewWithTag:202];
    UITextField *iasTextField = [self.view viewWithTag:203];
    UITextField *nmTextField = [self.view viewWithTag:204];
    UITextField *smTextField = [self.view viewWithTag:205];
    UITextField *timealotTextField = [self.view viewWithTag:206];
    double altValue=0.00;
    double iasValue=0.00;
    double nmValue=0.00;
    double smValue=0.00;
    double timeValue=0.00;
    double ratioValue=0.00;
    
    NSString *ratio = @"1:1";
    NSArray *ratioArray;
    NSInteger horizontalValue,verticalValue;
    
    if (unitId==1) {
        ratio=secondValue;//[[NSString stringWithFormat:@"%.01f",newValue] stringByReplacingOccurrencesOfString:@"." withString:@":"];
    }else if(ratioTextField.text.length > 0)
    {
        ratio=ratioTextField.text;
    }else
    {
        ratio=ratio;
    }
    
    if ([ratio containsString:@":"]) {
        ratioArray=[ratio componentsSeparatedByString:@":"];
    }else if(unitId!=1 && [ratioTextField.text length]>0 && ![ratio containsString:@":"]) {
        [self displayAlertWithMessage:@"Please enter ratio value in correct format eg. 0:0"];
    }
    if ([ratioArray count]==0) {
        horizontalValue=newValue;
        verticalValue=1;
    }else if ([ratioArray count]==1) {
        horizontalValue=newValue;
        verticalValue=1;
    }else {
        horizontalValue=[[ratioArray objectAtIndex:0] integerValue];
        verticalValue=[[ratioArray objectAtIndex:1] integerValue];;
    }
    switch (unitId) {
        case 1:
            //ratio=[[NSString stringWithFormat:@"%.02f",newValue] stringByReplacingOccurrencesOfString:@"." withString:@":"];
            altValue=[altTextField.text length]>0?[altTextField.text doubleValue]:0.00;
            iasValue=[iasTextField.text length]>0?[iasTextField.text doubleValue]:0.00;
            if (horizontalValue > 0 && verticalValue >0) {
                if (self.lastTextFieldTag==timealotTextField.tag) {
                    timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                    if (timeValue>0) {
                        nmValue = (timeValue * iasValue)/60;
                    }
                }else
                {
                    nmValue=(altValue*horizontalValue)/(verticalValue*6076.11);
                    nmValue=nmValue>0.0?nmValue:0.00;
                }
                if (iasValue>0.00) {
                    timeValue=(nmValue/iasValue)*60;
                }
                smValue=nmValue*1.15;
                altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
            }
            
            break;
        case 2:
            ratio=ratioTextField.text;
            altValue=newValue;
            iasValue=[iasTextField.text length]>0?[iasTextField.text doubleValue]:0.00;
            if (self.lastTextFieldTag==timealotTextField.tag) {
                timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                if (timeValue>0) {
                    nmValue = (timeValue * iasValue)/60;
                }
            }else
            {
                nmValue=(altValue*horizontalValue)/(verticalValue*6076.11);
                nmValue=nmValue>0.0?nmValue:0.00;
            }
            if (iasValue>0.00) {
                timeValue=(nmValue/iasValue)*60;
            }
            smValue=nmValue*1.15;
            altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
            break;
        case 3:
            ratio=ratioTextField.text;
            altValue=[altTextField.text length]>0?[altTextField.text doubleValue]:0.00;
            iasValue=newValue;
            if (self.lastTextFieldTag==timealotTextField.tag) {
                timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                if (timeValue>0) {
                    nmValue = (timeValue * iasValue)/60;
                }
            }else
            {
                nmValue=(altValue*horizontalValue)/(verticalValue*6076.11);
                nmValue=nmValue>0.0?nmValue:0.00;
            }
            if (iasValue>0.00) {
                timeValue=(nmValue/iasValue)*60;
            }
            smValue=nmValue*1.15;
            altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
            break;
        case 4:
            nmValue=newValue;
            altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
            smValue=nmValue*1.15;
            if (checkTime == YES) {
                iasValue = [iasTextField.text doubleValue];
                if (iasValue>0) {
                    timeValue=(nmValue*60)/iasValue;
                }
            }else{
                timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                if (timeValue>0) {
                    iasValue=(nmValue*60)/timeValue;
                }
            }
            break;
            
        case 5:
            smValue=newValue;
            nmValue=smValue/1.15;
            if (self.lastTextFieldTag==ratioTextField.tag) {
                altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
                if (checkTime == YES) {
                    iasValue = [iasTextField.text doubleValue];
                    if (iasValue>0) {
                        timeValue=(nmValue*60)/iasValue;
                    }
                }else{
                    timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                    if (timeValue>0) {
                        iasValue=(nmValue*60)/timeValue;
                    }
                }
                
            }else if (self.lastTextFieldTag==altTextField.tag) {
                altValue=[altTextField.text doubleValue];
                if (verticalValue>0) {
                    nmValue=(altValue*horizontalValue)/(verticalValue*6076.11);
                }
                
                
            }
            else if (self.lastTextFieldTag==iasTextField.tag) {
                iasValue = [iasTextField.text doubleValue];
                if (iasValue>0) {
                    timeValue=(nmValue*60)/iasValue;
                }
                if (horizontalValue>0 || verticalValue>0) {
                    altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
                }else {
                    ratioValue=nmValue*6076.11/[altTextField.text doubleValue];
                    ratio=[[NSString stringWithFormat:@"%.02f",ratioValue] stringByReplacingOccurrencesOfString:@"." withString:@":"];
                }
            }
            else {
                if (checkTime == YES) {
                    iasValue = [iasTextField.text doubleValue];
                    if (iasValue>0) {
                        timeValue=(nmValue*60)/iasValue;
                    }
                }else{
                    timeValue=[self getdecimalTimeFromString:timealotTextField.text];
                    if (timeValue>0) {
                        iasValue=(nmValue*60)/timeValue;
                    }
                }
                if (horizontalValue>0 || verticalValue>0) {
                    altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
                }else {
                    ratioValue=nmValue*6076.11/[altTextField.text doubleValue];
                    ratio=[[NSString stringWithFormat:@"%.02f",ratioValue] stringByReplacingOccurrencesOfString:@"." withString:@":"];
                }
            }
            
            break;
            
        case 6:
            
            if (self.lastTextFieldTag==iasTextField.tag) {
                ratio=ratioTextField.text;
                altValue=[altTextField.text length]>0?[altTextField.text doubleValue]:0.00;
                iasValue=[iasTextField.text doubleValue];
                timeValue=[self getdecimalTimeFromString:secondValue];
                if (timeValue>0) {
                    nmValue = (timeValue * iasValue)/60;
                }
            }else
            {
                nmValue=(altValue*horizontalValue)/(verticalValue*6076.11);
                nmValue=nmValue>0.0?nmValue:0.00;
            }
            if (iasValue>0.00) {
                timeValue=(nmValue/iasValue)*60;
            }
            smValue=nmValue*1.15;
            altValue=(nmValue*verticalValue*6076.11)/horizontalValue;
            break;
        default:
            break;
    }
    ratioTextField.text=ratio;
    altTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:altValue uptoDecimal:2]];
    iasTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:iasValue uptoDecimal:2]];
    nmTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:nmValue uptoDecimal:2]];
    smTextField.text=[NSString stringWithFormat:@"%.02f",[self getRoundedForValue:smValue uptoDecimal:2]];
    if (timeValue>0.00) {
        timealotTextField.text=[self convertDecimalTimeTostring:timeValue];
    }else {
        timealotTextField.text=@"00:00:00";
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
    if (time.length == 0) {
        return 0;
    }
    NSArray *seperateString;
    double hours;
    double minutes = 0.0;
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
    
    if (time.length == 4)
        minutes=minutes/6;
    else
        minutes=minutes/60;
    
    second = second/(60*60);
    
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
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcGlide" inManagedObjectContext:context];
            CalcGlide *calcGlide=[[CalcGlide alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            calcGlide.name=self.nameTextField.text;
            
            calcGlide.ratio = ((UITextField *)[self.view viewWithTag:201]).text;
            calcGlide.alt = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:202]).text doubleValue]];
            calcGlide.ias = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:203]).text doubleValue]];
            calcGlide.distNm = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:204]).text doubleValue]];
            calcGlide.distSM = [NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:205]).text doubleValue]];
            calcGlide.timeAloft = ((UITextField *)[self.view viewWithTag:206]).text;
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [arrayFiles addObject:calcGlide];
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
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcGlide" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (CalcGlide *calcGlideToDelete in fetchedData) {
            [context deleteObject:calcGlideToDelete];
        }
    }
    [self.SavedRecordTableView reloadData];

}
- (void)getSavedFiles{
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcGlide" inManagedObjectContext:context];
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
    
    CalcGlide *calcGlide=[arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.SavedRecordTableView.bounds.size.width, 28.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = calcGlide.name;
    
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
    CalcGlide *calcGlide=[arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:calcGlide];
    [self.SavedRecordTableView reloadData];
}
-(void)displayDetails:(CalcGlide*)calcGlide {
    ((UITextField *)[self.view viewWithTag:201]).text=[calcGlide.ratio length]>0?calcGlide.ratio:@"";
    ((UITextField *)[self.view viewWithTag:202]).text=[calcGlide.alt doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcGlide.alt doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:203]).text=[calcGlide.ias doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcGlide.ias doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:204]).text=[calcGlide.distNm doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcGlide.distNm doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:205]).text=[calcGlide.distSM doubleValue]>0.0?[NSString stringWithFormat:@"%.02f", [calcGlide.distSM doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:206]).text=[calcGlide.timeAloft length]>0?calcGlide.timeAloft:@"";
    
}

@end
