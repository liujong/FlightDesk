//
//  NavLogCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "NavLogCell.h"
#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
#define ACCEPTABLE_TEMPCHARACTERS @"0123456789.-"



typedef enum : NSUInteger {
    KMMU = 10,
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
@implementation NavLogCell
+ (NavLogCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"NavLogCell" owner:nil options:nil];
    NavLogCell *cell = [array objectAtIndex:0];
    return cell;
}
- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark- TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == _courseTextField) {
        [_attitudeTextField becomeFirstResponder];
    }else if (textField == _attitudeTextField) {
        [_windDirTextField becomeFirstResponder];
    }else if (textField == _windDirTextField) {
        [_windVelTextField becomeFirstResponder];
    }else if (textField == _windVelTextField) {
        [_windTempTextField becomeFirstResponder];
    }else if (textField == _windTempTextField) {
        [_casTasValueTextField becomeFirstResponder];
    }else if (textField == _casTasValueTextField) {
        [_tcTextField becomeFirstResponder];
    }else if (textField == _tcTextField) {
        [_varTextField becomeFirstResponder];
    }else if (textField == _varTextField) {
        [_devTextField becomeFirstResponder];
    }else if (textField == _devTextField) {
        [_leg12TextField becomeFirstResponder];
    }else if (textField == _leg12TextField) {
        [_actTextField becomeFirstResponder];
    }else if (textField == _actTextField) {
        [self.delegate returnedToEditCurrentCell:self];
    }
    return  YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.delegate startedToEditCurrentCell:self];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {    
    if (textField == _courseTextField) {
        [self.datadict setValue:_courseTextField.text forKey:@"course"];
    }else if (textField == _attitudeTextField) {
        [self.datadict setValue:[_attitudeTextField.text stringByReplacingOccurrencesOfString:@"," withString:@""] forKey:@"Att"];
    }else if (textField == _windDirTextField) {
        [self.datadict setValue:_windDirTextField.text forKey:@"WindDir"];
    }else if (textField == _windVelTextField) {
        [self.datadict setValue:_windVelTextField.text forKey:@"WindVel"];
    }else if (textField == _windTempTextField) {
        [self.datadict setValue:_windTempTextField.text forKey:@"WindTemp"];
    }else if (textField == _casTasValueTextField) {
        [self.datadict setValue:_casTasValueTextField.text forKey:@"CasTas"];
    }else if (textField == _tcTextField) {
        [self.datadict setValue:_tcTextField.text forKey:@"Tc"];
    }else if (textField == _varTextField) {
        [self.datadict setValue:_varTextField.text forKey:@"Var"];
    }else if (textField == _devTextField) {
        [self.datadict setValue:_devTextField.text forKey:@"Dev"];
    }else if (textField == _leg12TextField) {
        [self.datadict setValue:[NSDecimalNumber decimalNumberWithString:_leg12TextField.text] forKey:@"distLeg"];
    }else if (textField == _actTextField) {
        [self.datadict setValue:_actTextField.text forKey:@"Act"];
    }
    //[self.delegate didUpdateNavLogRecord:self.datadict cell:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (textField == _courseTextField) {
        _courseTextField.text = text;
        [self.datadict setValue:text forKey:@"course"];
        [self.delegate didUpdateNavLogRecord:self.datadict cell:self];
        return NO;
    }
    BOOL valid = NO;
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARECTERS];
    if (textField == _devTextField || textField == _varTextField || textField == _windTempTextField) {
        myCharSet = [NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_TEMPCHARACTERS];
    }
    for (int i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        if ([myCharSet characterIsMember:c]) {
            valid = YES;
        }
    }
    
    if (!valid && range.length != 1){
        return NO;
    }
    if (textField == _devTextField && [text isEqualToString:@"-"]) {
        return YES;
    }
    
    NSCharacterSet *cs = [myCharSet invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
    if ([string isEqualToString:@"."] && range.length<1 && [textField.text containsString:@"."]) {
        finalString=[finalString substringToIndex:[finalString length]-1];
    }
    textField.text = finalString;
    
    if (textField == _attitudeTextField) {
        NSNumberFormatter *frmtr = [[NSNumberFormatter alloc] init];
        [frmtr setGroupingSize:3];
        [frmtr setGroupingSeparator:@","];
        [frmtr setUsesGroupingSeparator:YES];
        NSString *commaString = [frmtr stringFromNumber:[NSNumber numberWithFloat:[[finalString stringByReplacingOccurrencesOfString:@"," withString:@""] floatValue]]];
        textField.text = commaString;
    }
    
    // Formaula for _WAC TEXTField (DEGREES(ASIN(((H12/I12)*SIN(RADIANS(G12-J12))))))
    // formula for _thTextField =SUM(J12:J13)
    // formula for _mhTextField==SUM(K12:K13)
    //formula For _chTextView=IF(SUM(L12)>360;SUM(L12)-360;SUM(L12))
    double newValue=[finalString doubleValue];
    [self valueChangedInConversionTableForMeasurement:(10) forUnit:(textField.tag % 10) withNewValue:newValue Value:finalString];   
    
    return NO;
}
- (double)getRoundedForValue:(double)value uptoDecimal:(int)decimalPlaces{
    int divisor = pow(10, decimalPlaces);
    NSLog(@"%.02f",roundf(value * divisor) / divisor);
    return roundf(value * divisor) / divisor;
}
- (void)calculation
{
    float temp= [_windDirTextField.text floatValue]-[_tcTextField.text floatValue];
    float radian=temp*M_PI/180;
    float digreeInSin=sin(radian);
    float h12I12= [_windVelTextField.text floatValue]/[_casTasValueTextField.text floatValue];
    float finalFloat=asin(h12I12*digreeInSin);
    
    /** WCA Calculation **/
    if (!isnan(finalFloat)) {
        _wcaTextField.text=[NSString stringWithFormat:@"%.01f", [self getRoundedForValue:finalFloat * 180 / M_PI uptoDecimal:1]];
    }else{
        _wcaTextField.text = @"";
    }
    
    /** TH Calculation **/
    float aswer=[_tcTextField.text floatValue]+[_wcaTextField.text floatValue];
    _thFieldField.text=[NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:aswer uptoDecimal:0]];
    
    /** MH Calculation **/
    float mhValue =[_thFieldField.text floatValue]+[_varTextField.text floatValue] + [_devTextField.text floatValue];
    _mhTextField.text=[NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:mhValue uptoDecimal:0]];
    
    /** MH Calculation **/
    if (mhValue >360) {
        float chAns = mhValue - 360;
        int chAnsWithInt = (int)[self getRoundedForValue:chAns uptoDecimal:0];
        if (chAnsWithInt < 10 ) {
            _chAnsTextField.text = [NSString stringWithFormat:@"00%d", abs(chAnsWithInt)];
        }else if (chAnsWithInt > 9 && chAnsWithInt < 100){
            _chAnsTextField.text = [NSString stringWithFormat:@"0%d", abs(chAnsWithInt)];
        }else {
            _chAnsTextField.text = [NSString stringWithFormat:@"%d", abs(chAnsWithInt)];
        }
    }else
    {
        int chAnsWithInt = (int)[self getRoundedForValue:mhValue uptoDecimal:0];
        if (chAnsWithInt < 10 ) {
            _chAnsTextField.text = [NSString stringWithFormat:@"00%d", abs(chAnsWithInt)];
        }else if (chAnsWithInt > 9 && chAnsWithInt < 100){
            _chAnsTextField.text = [NSString stringWithFormat:@"0%d", abs(chAnsWithInt)];
        }else {
            _chAnsTextField.text = [NSString stringWithFormat:@"%d", abs(chAnsWithInt)];
        }
    }
    
    /** Leg Rem. Calculation **/
    if ([_distRem floatValue] > 0 && ![_leg12TextField.text isEqualToString:@""]) {
        _legSumTextField.text = [NSString stringWithFormat:@"%@", [[NSDecimalNumber decimalNumberWithString:_distRem] decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:_leg12TextField.text]]];
    }
    
    //I12*SQRT(1-((H12/I12)*SIN(RADIANS(G12-J12)))^2)-H12*COS(RADIANS(G12-J12))
    /** GS Act. Calculation **/
    
    float cosResult = _windVelTextField.text.floatValue* cos(M_PI*(_windDirTextField.text.floatValue - _tcTextField.text.floatValue)/180);
    float powResult = powf(((_windVelTextField.text.floatValue/_casTasValueTextField.text.floatValue) *sin(M_PI*(_windDirTextField.text.floatValue - _tcTextField.text.floatValue)/180)), 2.0);
    float estOutput = [_casTasValueTextField.text floatValue]*sqrt(1-powResult)-cosResult;
    NSInteger mins = 0;
    if (!isnan(estOutput)) {
        _estTextField.text = [NSString stringWithFormat:@"%d", (int)[self getRoundedForValue:estOutput uptoDecimal:0]];
        
        float timeOff = [_leg12TextField.text floatValue] / estOutput;
        mins = (int)[self getRoundedForValue:timeOff * 60 uptoDecimal:0];
        NSInteger hours = 0;
        if (mins > 60) {
            hours = (mins / 60 ) % 60;
        }
        NSString *timeOffStr = @"";
        if (mins < 10) {
            if (hours < 10) {
                timeOffStr = [NSString stringWithFormat:@"%0ld:0%ld", (long)hours, (long)mins%60];
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
        _timeOffTextField.text = timeOffStr;
    
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSDate *preTimeOff = [dateFormatter dateFromString:_headerTimeOff];
        
        NSTimeInterval secondsInMins = mins * 60;
        NSDate *dateToCalcuated = [preTimeOff dateByAddingTimeInterval:secondsInMins];
        
        NSString *timOffToChanged = [dateFormatter stringFromDate:dateToCalcuated];
        _fuelTextField.text = timOffToChanged;
        
        float fuelLoad = timeOff * [_headerGPH floatValue];
        if (!isnan(fuelLoad)) {
            _gphTextField.text = [NSString stringWithFormat:@"%.01f", [self getRoundedForValue:fuelLoad uptoDecimal:1]];
        }else{
            _gphTextField.text = @"";
        }
        
        float gphRem = [_headerFuelLoad floatValue] - fuelLoad;
        _gphRemTextField.text = [NSString stringWithFormat:@"%.01f", [self getRoundedForValue:gphRem uptoDecimal:1]];
    }else{
        _estTextField.text = @"";
        _timeOffTextField.text = @"";
        _fuelTextField.text = @"";
        _gphTextField.text = @"";
        _gphRemTextField.text = @"";
    }
    
    [self.datadict setValue:_courseTextField.text forKey:@"course"];
    [self.datadict setValue:[_attitudeTextField.text stringByReplacingOccurrencesOfString:@"," withString:@""] forKey:@"Att"];
    [self.datadict setValue:_windDirTextField.text forKey:@"WindDir"];
    [self.datadict setValue:_windVelTextField.text forKey:@"WindVel"];
    [self.datadict setValue:_windTempTextField.text forKey:@"WindTemp"];
    [self.datadict setValue:_casTasValueTextField.text forKey:@"CasTas"];
    [self.datadict setValue:_tcTextField.text forKey:@"Tc"];
    [self.datadict setValue:_wcaTextField.text forKey:@"Wca"];
    [self.datadict setValue:_thFieldField.text forKey:@"Th"];
    [self.datadict setValue:_varTextField.text forKey:@"Var"];
    [self.datadict setValue:_mhTextField.text forKey:@"Mh"];
    [self.datadict setValue:_devTextField.text forKey:@"Dev"];
    [self.datadict setValue:_chAnsTextField.text forKey:@"CHAns"];
    if ([_leg12TextField.text isEqualToString:@""]) {
        [self.datadict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"distLeg"];
    }else{
        [self.datadict setValue:[NSDecimalNumber decimalNumberWithString:_leg12TextField.text] forKey:@"distLeg"];
    }
    if ([_legSumTextField.text isEqualToString:@""]) {
        [self.datadict setValue:[NSDecimalNumber decimalNumberWithString:@"0"] forKey:@"LegSum"];
    }else{
        [self.datadict setValue:[NSDecimalNumber decimalNumberWithString:_legSumTextField.text] forKey:@"LegSum"];
    }
    [self.datadict setValue:_estTextField.text forKey:@"Est"];
    [self.datadict setValue:_actTextField.text forKey:@"Act"];
    [self.datadict setValue:[NSString stringWithFormat:@"%ld", (long)mins] forKey:@"TimeOff"];
    [self.datadict setValue:_fuelTextField.text forKey:@"Fuel"];
    [self.datadict setValue:_gphTextField.text forKey:@"Gph"];
    [self.datadict setValue:_gphRemTextField.text forKey:@"GphRem"];
    [self.datadict setValue:_timeOffATETextField.text forKey:@"TimeOffATE"];
    [self.datadict setValue:_fuelATATextField.text forKey:@"fuelATA"];
    
    [self.delegate didUpdateNavLogRecord:self.datadict cell:self];
}

- (IBAction)onGetTimeOfATE:(id)sender {
    if (_isOpenTimeView) {
        return;
    }
    _isOpenTimeView = YES;
    [self endEditing:YES];
    TimeViewController *timeVc = [[TimeViewController alloc] initWithNibName:@"TimeViewController" bundle:nil];
    [timeVc.view setFrame:[UIScreen mainScreen].bounds];
    timeVc.delegate = self;
    timeVc.type = 1;
    timeVc.pickerTitle = @"TimeOff";
    [self displayContentController:timeVc];
    [timeVc animateShow];
}

- (IBAction)onGetFuelATA:(id)sender {
    if (_isOpenTimeView) {
        return;
    }
    _isOpenTimeView = YES;
    [self endEditing:YES];
    TimeViewController *timeVc = [[TimeViewController alloc] initWithNibName:@"TimeViewController" bundle:nil];
    [timeVc.view setFrame:[UIScreen mainScreen].bounds];
    timeVc.delegate = self;
    timeVc.type = 2;
    timeVc.pickerTitle = @"TimeOff";
    [self displayContentController:timeVc];
    [timeVc animateShow];
}
- (void) displayContentController: (UIViewController*) content;
{
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:content.view];
    [[AppDelegate sharedDelegate].window.rootViewController addChildViewController:content];
    [content didMoveToParentViewController:[AppDelegate sharedDelegate].window.rootViewController];
}
- (void)removeContentcontroller:(UIViewController *)content{
    _isOpenTimeView = NO;
    [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:content.view];
    [content willMoveToParentViewController:nil];  // 1
    [content.view removeFromSuperview];            // 2
    [content removeFromParentViewController];
}
#pragma mark TimeViewControllerDelegate
-(void)returnValueFromTimeView:(TimeViewController *)timeView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index{
    if (_type == 1) {
        _timeOffATETextField.text = _strDate;
        [self.datadict setValue:_timeOffATETextField.text forKey:@"TimeOffATE"];
    }else if (_type == 2){
        _fuelATATextField.text = _strDate;
        [self.datadict setValue:_fuelATATextField.text forKey:@"fuelATA"];
    }
    
    [self.delegate didUpdateNavLogRecord:self.datadict cell:self];
    [self removeContentcontroller:timeView];
}
- (void)didCancelTimeView:(TimeViewController *)timeView{
    [self removeContentcontroller:timeView];
}
- (void)saveNavLogRecord:(NSMutableDictionary *)dict
{
    self.datadict = dict;
    _courseTextField.text = @"";
    if (![[dict objectForKey:@"course"] isEqualToString:@""]) {
        _courseTextField.text = [dict objectForKey:@"course"];
    }
    _attitudeTextField.text = @"";
    if (![[dict objectForKey:@"Att"] isEqualToString:@""]) {
        NSNumberFormatter *frmtr = [[NSNumberFormatter alloc] init];
        [frmtr setGroupingSize:3];
        [frmtr setGroupingSeparator:@","];
        [frmtr setUsesGroupingSeparator:YES];
        NSString *commaString = [frmtr stringFromNumber:[NSNumber numberWithFloat:[[dict objectForKey:@"Att"] floatValue]]];
        _attitudeTextField.text = commaString;
    }
    _windDirTextField.text = @"";
    if (![[dict objectForKey:@"WindDir"] isEqualToString:@""]) {
        _windDirTextField.text = [dict objectForKey:@"WindDir"];
    }
    _windVelTextField.text = @"";
    if (![[dict objectForKey:@"WindVel"] isEqualToString:@""]) {
        _windVelTextField.text = [dict objectForKey:@"WindVel"];
    }
    _windTempTextField.text = @"";
    if (![[dict objectForKey:@"WindTemp"] isEqualToString:@""]) {
        _windTempTextField.text = [dict objectForKey:@"WindTemp"];
    }
    _casTasValueTextField.text = @"";
    if (![[dict objectForKey:@"CasTas"] isEqualToString:@""]) {
        _casTasValueTextField.text = [dict objectForKey:@"CasTas"];
    }
    _tcTextField.text = @"";
    if (![[dict objectForKey:@"Tc"] isEqualToString:@""]) {
        _tcTextField.text = [dict objectForKey:@"Tc"];
    }
    _wcaTextField.text = @"";
    if (![[dict objectForKey:@"Wca"] isEqualToString:@""]) {
        _wcaTextField.text = [dict objectForKey:@"Wca"];
    }
    _thFieldField.text = @"";
    if (![[dict objectForKey:@"Th"] isEqualToString:@""]) {
        _thFieldField.text = [dict objectForKey:@"Th"];
    }
    _varTextField.text = @"";
    if (![[dict objectForKey:@"Var"] isEqualToString:@""]) {
        _varTextField.text = [dict objectForKey:@"Var"];
    }
    _mhTextField.text = @"";
    if (![[dict objectForKey:@"Mh"] isEqualToString:@""]) {
        _mhTextField.text = [dict objectForKey:@"Mh"];
    }
    _devTextField.text = @"";
    if (![[dict objectForKey:@"Dev"] isEqualToString:@""]) {
        _devTextField.text = [dict objectForKey:@"Dev"];
    }
    _chAnsTextField.text = @"";
    if (![[dict objectForKey:@"CHAns"] isEqualToString:@""]) {
        _chAnsTextField.text = [dict objectForKey:@"CHAns"];
    }
    _leg12TextField.text = @"";
    if (![[[dict objectForKey:@"distLeg"] stringValue] isEqualToString:@""] && [[dict objectForKey:@"distLeg"] floatValue] > 0) {
        _leg12TextField.text = [[dict objectForKey:@"distLeg"] stringValue];
    }
    _legSumTextField.text = @"";
    if (![[[dict objectForKey:@"LegSum"] stringValue]  isEqualToString:@""] && [[dict objectForKey:@"LegSum"] floatValue] > 0) {
        _legSumTextField.text = [[dict objectForKey:@"LegSum"] stringValue];
    }
    _estTextField.text = @"";
    if (![[dict objectForKey:@"Est"] isEqualToString:@""]) {
        _estTextField.text = [dict objectForKey:@"Est"];
    }
    _timeOffTextField.text = @"";
    if (![[dict objectForKey:@"TimeOff"] isEqualToString:@""] && [[dict objectForKey:@"TimeOff"] integerValue] > 0) {
        NSInteger secs = [[dict objectForKey:@"TimeOff"] integerValue];
        NSInteger mins = 0;
        if (secs > 60) {
            mins = (secs / 60 ) % 60;
        }
        NSString *timeOffStr = @"";
        if (secs < 10) {
            if (mins < 10) {
                timeOffStr = [NSString stringWithFormat:@"0%ld:0%ld", (long)mins, (long)secs%60];
            }else{
                timeOffStr = [NSString stringWithFormat:@"%ld:0%ld", (long)mins, (long)secs%60];
            }
        }else{
            if (mins < 10) {
                timeOffStr = [NSString stringWithFormat:@"0%ld:%ld", (long)mins, (long)secs%60];
            }else{
                timeOffStr = [NSString stringWithFormat:@"%ld:%ld", (long)mins, (long)secs%60];
            }
        }
        _timeOffTextField.text = timeOffStr;
    }
    _fuelTextField.text = @"";
    if (![[dict objectForKey:@"Fuel"] isEqualToString:@""]) {
        _fuelTextField.text = [dict objectForKey:@"Fuel"];
    }
    _gphTextField.text = @"";
    if (![[dict objectForKey:@"Gph"] isEqualToString:@""]) {
        _gphTextField.text = [dict objectForKey:@"Gph"];
    }
    _gphRemTextField.text = @"";
    if (![[dict objectForKey:@"GphRem"] isEqualToString:@""]) {
        _gphRemTextField.text = [dict objectForKey:@"GphRem"];
    }
    _actTextField.text = @"";
    if (![[dict objectForKey:@"Act"] isEqualToString:@""]) {
        _actTextField.text = [dict objectForKey:@"Act"];
    }
    _timeOffATETextField.text = @"";
    if (![[dict objectForKey:@"TimeOffATE"] isEqualToString:@""]) {
        _timeOffATETextField.text = [dict objectForKey:@"TimeOffATE"];
    }
    _fuelATATextField.text = @"";
    if (![[dict objectForKey:@"fuelATA"] isEqualToString:@""]) {
        _fuelATATextField.text = [dict objectForKey:@"fuelATA"];
    }
}

- (void)valueChangedInConversionTableForMeasurement:(CalculationsMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue Value:(NSString*)secondValue{
    switch (measurement) {
        case KMMU:
            [self calculation];
            break;
            
        case ETA:
            
            break;
            
        case FUELBURN:
            
            break;
            
        case FUELNM:
            
            break;
            
        case ISA:
            
            //No Functionality has been defined
            break;
            
        case PA:
            
            break;
            
        case DA:
            //No Functionality has been defined
            
            break;
            
        case TAS:
            
            break;
            
        case CLOUDBASES:
            
            break;
            
        case FREEZINGLEVEL:
            
            break;
            
        case GLIDING:
            
            break;
            
        default:
            break;
    }
}
@end
