//
//  LegViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "LegViewController.h"
#import "CalcLeg+CoreDataClass.h"
#import "CustomCell.h"
#import "FlightDesk-Swift.h"
#import "CalcLeg+CoreDataClass.h"

#define ENTITY_CALCLEG @"CalcLeg"

#define ACCEPTABLE_CHARECTERS @"0123456789."
#define ACCEPTABLE_TIMECHARECTERS @"0123456789:"
@interface LegViewController ()<UITextFieldDelegate>
{
    BOOL isShownKeyboard;
    NSInteger currentSelectedRow;
}

@end
typedef enum : NSUInteger {
    LEG1 = 10,
    LEG2,
    LEG3,
    LEG4,
    FUELLOAD
    
    
} CalculationsMeasurement;
@implementation LegViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Initialization code
    self.title = @"LEG";
    self.arrayFiles=[[NSMutableArray alloc] init];
    currentSelectedRow = -1;
    isShownKeyboard = NO;
    
    //    self.containerView.layer.borderColor = [UIColor grayColor].CGColor;
    //    self.containerView.layer.borderWidth = 1.0;
    
    for (UIView *aView in self.containerView.subviews) {
        
        // for (UIView *aView in subView.subviews) {
        if ([aView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)aView;
            if ([[NSUserDefaults standardUserDefaults ] boolForKey:@"SavedText"]==YES) {
                textField.text=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"LEG%ld",(long)textField.tag+10000]];
            }
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
            
            textField.keyboardType = UIKeyboardTypeNumberPad;
            if (textField.tag == 1020) {
                textField.keyboardType = UIKeyboardTypeDefault;
            }
            textField.delegate = self;
            //                textField.placeholder = @"0.00";
        }
        
        if ([aView isKindOfClass:[UIButton class]]) {
            // Adding rounded corner to button
            UIButton *button = (UIButton *)aView;
            
            button.layer.cornerRadius = 10;
            button.layer.borderWidth = 1;
            button.layer.borderColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f].CGColor;
            [button setTitleColor:[UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
            //                button.layer.borderColor = [UIColor colorWithRed:0/255.0 green:222/255.0 blue:255/255.0 alpha:1.0].CGColor;
            //                [button setTitleColor:[UIColor colorWithRed:0/255.0 green:222/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
        }
    }
    // }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearText) name:@"ClearText" object:nil];
    self.saveFlightBtn.layer.cornerRadius = 5.0;
    self.saveFlightBtn.layer.borderWidth = 1.0;
    self.saveFlightBtn.layer.borderColor = self.saveFlightBtn.titleLabel.textColor.CGColor;
    
    
    self.saveTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];

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
    
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self getSavedFiles];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"LegViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveText:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)keyboardWasShown:(NSNotification*)aNotification {
    if (!isShownKeyboard)
    {
        isShownKeyboard = YES;
        if (self.view.frame.size.height < self.view.frame.size.width) {
            [scrView setContentSize:CGSizeMake(0, scrView.frame.size.height)];
        }
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    if (isShownKeyboard)
    {
        [self.view endEditing:YES];
        isShownKeyboard = NO;
        [scrView setContentSize:CGSizeMake(0, 0)];
    }
}
-(void)clearText:(NSNotification *) notification {
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subView;
            textField.text=@"";
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"LEG%ld",(long)textField.tag+10000]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
-(void)saveText:(NSNotification *) notification {
    
    for (UIView *subView in self.containerView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)subView;
            [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:[NSString stringWithFormat:@"LEG%ld",(long)textField.tag+10000]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SavedText"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
///-------------------------------------------------
#pragma mark - ActionMethods
///-------------------------------------------------
-(BOOL)exist
{
    NSManagedObjectContext *managedObjectContext=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_CALCLEG inManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setFetchLimit:1];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@", self.nameTxtField.text]];
    
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

- (IBAction)saveAction:(id)sender {
    if ([self.nameTxtField.text length]>0) {
        if (![self exist]) {
            
            NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            NSEntityDescription *descriptor=[NSEntityDescription entityForName:ENTITY_CALCLEG inManagedObjectContext:context];
            CalcLeg *calcLeg=[[CalcLeg alloc] initWithEntity:descriptor insertIntoManagedObjectContext:context];
            calcLeg.name=self.nameTxtField.text;
            
            calcLeg.leg1Dist=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:101]).text doubleValue]];
            calcLeg.leg1GS=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:102]).text doubleValue]];
            calcLeg.leg1Time=((UITextField *)[self.view viewWithTag:103]).text ;
            calcLeg.leg1DistRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:104]).text doubleValue]];
            calcLeg.leg1GalUsed=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:105]).text doubleValue]];
            calcLeg.leg1GalRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:106]).text doubleValue]];
            
            calcLeg.leg2Dist=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:111]).text doubleValue]];
            calcLeg.leg2GS=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:112]).text doubleValue]];
            calcLeg.leg2Time=((UITextField *)[self.view viewWithTag:113]).text ;
            calcLeg.leg2DistRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:114]).text doubleValue]];
            calcLeg.leg2GalUsed=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:115]).text doubleValue]];
            calcLeg.leg2GalRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:116]).text doubleValue]];
            
            calcLeg.leg3Dist=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:121]).text doubleValue]];
            calcLeg.leg3GS=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:122]).text doubleValue]];
            calcLeg.leg3Time=((UITextField *)[self.view viewWithTag:123]).text ;
            calcLeg.leg3DistRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:124]).text doubleValue]];
            calcLeg.leg3GalUsed=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:125]).text doubleValue]];
            calcLeg.leg3GalRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:126]).text doubleValue]];
            
            calcLeg.leg4Dist=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:131]).text doubleValue]];
            calcLeg.leg4GS=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:132]).text doubleValue]];
            calcLeg.leg4Time=((UITextField *)[self.view viewWithTag:133]).text ;
            calcLeg.leg4DistRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:134]).text doubleValue]];
            calcLeg.leg4GalUsed=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:135]).text doubleValue]];
            calcLeg.leg4GalRem=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:136]).text doubleValue]];
            
            calcLeg.fuelLoad=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:141]).text doubleValue]];
            calcLeg.galHr=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:142]).text doubleValue]];
            calcLeg.totalDist=[NSNumber numberWithDouble:[((UITextField *)[self.view viewWithTag:143]).text doubleValue]];
            
            NSError *error;
            [context save:&error];
            if (!error) {
                [self.arrayFiles addObject:calcLeg];
                self.nameTxtField.text=@"";
            }
            currentSelectedRow = self.arrayFiles.count - 1;
            [self.saveTableView reloadData];
        }else {
            [self displayAlertWithMessage:@"File name already exist."];
        }
    }
}
- (IBAction)clearAction:(id)sender {
    [self clearText:nil];
    currentSelectedRow = -1;
    [self.saveTableView reloadData];
}

- (IBAction)onClearAll:(id)sender {
    currentSelectedRow = -1;
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:@"CalcLeg" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [self.arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        for (CalcLeg *calcLegToDelete in fetchedData) {
            [context deleteObject:calcLegToDelete];
        }
    }
    [self.saveTableView reloadData];
}
-(void)displayDetails:(CalcLeg*)calcLeg {
    ((UITextField *)[self.view viewWithTag:101]).text=[calcLeg.leg1Dist doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg1Dist doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:102]).text=[calcLeg.leg1GS doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg1GS doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:103]).text=[calcLeg.leg1Time length]>0?calcLeg.leg1Time:@"";
    ((UITextField *)[self.view viewWithTag:104]).text=[calcLeg.leg1DistRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg1DistRem doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:105]).text =[calcLeg.leg1GalUsed doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg1GalUsed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:106]).text=[calcLeg.leg1GalRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg1GalRem doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:111]).text=[calcLeg.leg2Dist doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg2Dist doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:112]).text=[calcLeg.leg2GS doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg2GS doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:113]).text=[calcLeg.leg2Time length]>0?calcLeg.leg2Time:@"";
    ((UITextField *)[self.view viewWithTag:114]).text=[calcLeg.leg2DistRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg2DistRem doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:115]).text =[calcLeg.leg2GalUsed doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg2GalUsed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:116]).text=[calcLeg.leg2GalRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg2GalRem doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:121]).text=[calcLeg.leg3Dist doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg3Dist doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:122]).text=[calcLeg.leg3GS doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg3GS doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:123]).text=[calcLeg.leg3Time length]>0?calcLeg.leg3Time:@"";
    ((UITextField *)[self.view viewWithTag:124]).text=[calcLeg.leg3DistRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg3DistRem doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:125]).text =[calcLeg.leg3GalUsed doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg3GalUsed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:126]).text=[calcLeg.leg3GalRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg3GalRem doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:131]).text=[calcLeg.leg4Dist doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg4Dist doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:132]).text=[calcLeg.leg4GS doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg4GS doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:133]).text=[calcLeg.leg4Time length]>0?calcLeg.leg4Time:@"";
    ((UITextField *)[self.view viewWithTag:134]).text=[calcLeg.leg4DistRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg4DistRem doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:135]).text =[calcLeg.leg4GalUsed doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg4GalUsed doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:136]).text=[calcLeg.leg4GalRem doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.leg4GalRem doubleValue]]:@"";
    
    ((UITextField *)[self.view viewWithTag:141]).text=[calcLeg.fuelLoad doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.fuelLoad doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:142]).text=[calcLeg.galHr doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.galHr doubleValue]]:@"";
    ((UITextField *)[self.view viewWithTag:143]).text=[calcLeg.totalDist doubleValue]>0.0?[NSString stringWithFormat:@"%.01f", [calcLeg.totalDist doubleValue]]:@"";
}

-(void)getSavedFiles {
    NSManagedObjectContext *context=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    NSEntityDescription *descriptor=[NSEntityDescription entityForName:ENTITY_CALCLEG inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init] ;
    //    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES]]];
    [request setEntity:descriptor];
    
    NSError *error;
    NSArray *fetchedData = [context executeFetchRequest:request error:&error];
    [self.arrayFiles removeAllObjects];
    if ([fetchedData count]>0) {
        [self.arrayFiles addObjectsFromArray:[fetchedData mutableCopy]];
    }
    [self.saveTableView reloadData];
}



#pragma mark Table View Delegate Method
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.arrayFiles count];    //count number of row from counting array hear cataGorry is An Array
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier];
    }
    
    CalcLeg *calcLeg=[self.arrayFiles objectAtIndex:indexPath.row];
    UITextField *saveTxt = [[UITextField alloc]init];
    saveTxt.borderStyle=UITextBorderStyleRoundedRect;
    saveTxt.frame = CGRectMake(0.0, 0.0, self.saveTableView.bounds.size.width, 30.0);
    saveTxt.textAlignment = NSTextAlignmentCenter;
    saveTxt.userInteractionEnabled = NO;
    saveTxt.text = calcLeg.name;
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
    CalcLeg *calcLeg=[self.arrayFiles objectAtIndex:indexPath.row];
    [self displayDetails:calcLeg];
    [self.saveTableView reloadData];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        CalcLeg *calcLeg=[self.arrayFiles objectAtIndex:indexPath.row];
        [self deleteFile:calcLeg];
    }
}
-(void)deleteFile:(CalcLeg*)calcLeg {
    NSManagedObjectContext *moc=[AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    [moc deleteObject:calcLeg];
    NSError *error;
    [moc save:&error];
    if (!error) {
        [self.arrayFiles removeObject:calcLeg];
        [self.saveTableView reloadData];
    }
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

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.nameTxtField) {
        [scrView setContentOffset:CGPointMake(0, 30.0f) animated:YES];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField.tag!=1020) {
        NSString *acceptableCharacter=ACCEPTABLE_CHARECTERS;
        if (textField.tag==103 || textField.tag==113 || textField.tag==123 || textField.tag==123) {
            acceptableCharacter=ACCEPTABLE_TIMECHARECTERS;
        }
        
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:acceptableCharacter] invertedSet];
        
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        
        NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:[string isEqualToString:filtered]?string:@""];
        
        if ([textField.text containsString:@"."] && [string isEqualToString:@"."] && range.length<1) {
            finalString=[finalString substringToIndex:[finalString length] - 1];
        }
        double newValue=[finalString doubleValue];
        
        [self valueChangedInConversionTableForMeasurement:(textField.tag/10) forUnit:(textField.tag % 10) withNewValue:newValue];
        textField.text = finalString;
        
        return NO;
        
    }
    return YES;
}

///-------------------------------------------------
#pragma mark - Measurement Calculations
///-------------------------------------------------

- (void)valueChangedInConversionTableForMeasurement:(CalculationsMeasurement)measurement forUnit:(NSInteger)unitId withNewValue:(double)newValue{
    switch (measurement) {
        case LEG1:
            [self calculateLag1OnChangeInUnit:unitId toNewValue:newValue];
            break;
        case LEG2:
            [self calculateLag2OnChangeInUnit:unitId toNewValue:newValue];
            break;
        case LEG3:
            [self calculateLag3OnChangeInUnit:unitId toNewValue:newValue];
            break;
        case LEG4:
            [self calculateLag4OnChangeInUnit:unitId toNewValue:newValue];
            break;
        case FUELLOAD:
            [self calculateFuelLoadChangeInUnit:unitId toNewValue:newValue];
            break;
            
            
        default:
            break;
    }
}

- (void)calculateLag1OnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *distTextField = [self.view viewWithTag:101];
    UITextField *gsTextField = [self.view viewWithTag:102];
    UITextField *timeTextField = [self.view viewWithTag:103];
    
    UITextField *fuelLoadTextField = [self.view viewWithTag:141];
    UITextField *galHrTextField = [self.view viewWithTag:142];
    UITextField *totalDistTextField = [self.view viewWithTag:143];
    
    double dist=0.00,gs=0.00,time=0.00;
    switch (unitId) {
        case 1:
            dist=newValue;
            gs=[gsTextField.text doubleValue];
            
            break;
        case 2:
            dist=[distTextField.text doubleValue];
            gs=newValue;
            
            break;
            
            
            
        default:
            break;
    }
    if (gs>0.0) {
        time=dist/gs;
    }
    
    distTextField.text=[NSString stringWithFormat:@"%.02f",dist];
    timeTextField.text=time>0.0 ?[self convertDecimalTimeTostring:time]:@"00:00:00";
    gsTextField.text=[NSString stringWithFormat:@"%.01f",gs];
    
    
    
    [self calculateValues:[fuelLoadTextField.text doubleValue] Gal:[galHrTextField.text doubleValue] totalDist:[totalDistTextField.text doubleValue]];
    
}

- (void)calculateLag2OnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *distTextField = [self.view viewWithTag:111];
    UITextField *gsTextField = [self.view viewWithTag:112];
    UITextField *timeTextField = [self.view viewWithTag:113];
    
    UITextField *fuelLoadTextField = [self.view viewWithTag:141];
    UITextField *galHrTextField = [self.view viewWithTag:142];
    UITextField *totalDistTextField = [self.view viewWithTag:143];
    
    double dist=0.00,gs=0.00,time=0.00;
    switch (unitId) {
        case 1:
            dist=newValue;
            gs=[gsTextField.text doubleValue];
            
            break;
        case 2:
            dist=[distTextField.text doubleValue];
            gs=newValue;
            
            break;
            
        default:
            break;
    }
    if (gs>0.0) {
        time=dist/gs;
    }
    
    
    distTextField.text=[NSString stringWithFormat:@"%.02f",dist];
    timeTextField.text=time>0.0 ?[self convertDecimalTimeTostring:time]:@"00:00:00";
    gsTextField.text=[NSString stringWithFormat:@"%.01f",gs];
    
    [self calculateValues:[fuelLoadTextField.text doubleValue] Gal:[galHrTextField.text doubleValue] totalDist:[totalDistTextField.text doubleValue]];
    
    
    
    
    
}
- (void)calculateLag3OnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *distTextField = [self.view viewWithTag:121];
    UITextField *gsTextField = [self.view viewWithTag:122];
    UITextField *timeTextField = [self.view viewWithTag:123];
    
    UITextField *fuelLoadTextField = [self.view viewWithTag:141];
    UITextField *galHrTextField = [self.view viewWithTag:142];
    UITextField *totalDistTextField = [self.view viewWithTag:143];
    
    
    
    double dist=0.00,gs=0.00,time=0.00;
    switch (unitId) {
        case 1:
            dist=newValue;
            gs=[gsTextField.text doubleValue];
            
            break;
        case 2:
            dist=[distTextField.text doubleValue];
            gs=newValue;
            
            break;
            
        default:
            break;
    }
    if (gs>0.0) {
        time=dist/gs;
    }
    
    
    
    distTextField.text=[NSString stringWithFormat:@"%.02f",dist];
    timeTextField.text=time>0.0 ?[self convertDecimalTimeTostring:time]:@"00:00:00";
    gsTextField.text=[NSString stringWithFormat:@"%.01f",gs];
    
    
    
    
    
    [self calculateValues:[fuelLoadTextField.text doubleValue] Gal:[galHrTextField.text doubleValue] totalDist:[totalDistTextField.text doubleValue]];
}
- (void)calculateLag4OnChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *distTextField = [self.view viewWithTag:131];
    UITextField *gsTextField = [self.view viewWithTag:132];
    UITextField *timeTextField = [self.view viewWithTag:133];
    
    UITextField *fuelLoadTextField = [self.view viewWithTag:141];
    UITextField *galHrTextField = [self.view viewWithTag:142];
    UITextField *totalDistTextField = [self.view viewWithTag:143];
    
    
    double dist=0.00,gs=0.00,time=0.00;
    switch (unitId) {
        case 1:
            dist=newValue;
            gs=[gsTextField.text doubleValue];
            
            break;
        case 2:
            dist=[distTextField.text doubleValue];
            gs=newValue;
            
            break;
            
        default:
            break;
    }
    if (gs>0.0) {
        time=dist/gs;
    }
    
    
    distTextField.text=[NSString stringWithFormat:@"%.02f",dist];
    timeTextField.text=time>0.0 ?[self convertDecimalTimeTostring:time]:@"00:00:00";
    gsTextField.text=[NSString stringWithFormat:@"%.01f",gs];
    
    
    [self calculateValues:[fuelLoadTextField.text doubleValue] Gal:[galHrTextField.text doubleValue] totalDist:[totalDistTextField.text doubleValue]];
    
    
}
-(void)calculateFuelLoadChangeInUnit:(NSInteger)unitId toNewValue:(double)newValue {
    UITextField *fuelLoadTextField = [self.view viewWithTag:141];
    UITextField *galHrTextField = [self.view viewWithTag:142];
    UITextField *totalDistTextField = [self.view viewWithTag:143];
    double fuelValue=0.0,galValue=0.0,totalValue=0.0;
    switch (unitId) {
        case 1:
            fuelValue=newValue;
            galValue=[galHrTextField.text doubleValue];
            totalValue=[totalDistTextField.text doubleValue];
            break;
        case 2:
            fuelValue=[fuelLoadTextField.text doubleValue];
            galValue=newValue;
            totalValue=[totalDistTextField.text doubleValue];
            break;
        case 3:
            fuelValue=[fuelLoadTextField.text doubleValue];
            galValue=[galHrTextField.text doubleValue];
            totalValue=newValue;
            break;
            
        default:
            break;
    }
    fuelLoadTextField.text=[NSString stringWithFormat:@"%.01f",fuelValue];
    galHrTextField.text=[NSString stringWithFormat:@"%.01f",galValue ];
    totalDistTextField.text=[NSString stringWithFormat:@"%.01f",totalValue ];
    [self calculateValues:fuelValue Gal:galValue totalDist:totalValue];
    
}

-(void)calculateValues:(double)fuelValue Gal:(double)galValue totalDist:(double)distValue {
    
    UITextField *distTextField = [self.view viewWithTag:101];
    UITextField *timeTextField = [self.view viewWithTag:103];
    UITextField *distRemTextField = [self.view viewWithTag:104];
    UITextField *galUsedTextField = [self.view viewWithTag:105];
    UITextField *galRemTextField = [self.view viewWithTag:106];
    
    UITextField *dist2TextField = [self.view viewWithTag:111];
    UITextField *time2TextField = [self.view viewWithTag:113];
    UITextField *dist2RemTextField = [self.view viewWithTag:114];
    UITextField *gal2UsedTextField = [self.view viewWithTag:115];
    UITextField *gal2RemTextField = [self.view viewWithTag:116];
    
    UITextField *dist3TextField = [self.view viewWithTag:121];
    UITextField *time3TextField = [self.view viewWithTag:123];
    UITextField *dist3RemTextField = [self.view viewWithTag:124];
    UITextField *gal3UsedTextField = [self.view viewWithTag:125];
    UITextField *gal3RemTextField = [self.view viewWithTag:126];
    
    UITextField *dist4TextField = [self.view viewWithTag:131];
    UITextField *time4TextField = [self.view viewWithTag:133];
    UITextField *dist4RemTextField = [self.view viewWithTag:134];
    UITextField *gal4UsedTextField = [self.view viewWithTag:135];
    UITextField *gal4RemTextField = [self.view viewWithTag:136];
    
    distRemTextField.text=distValue>0.0?[NSString stringWithFormat:@"%.01f",distValue-[distTextField.text doubleValue]]:@"0.0";
    double time=[self getMinutesFromString:timeTextField.text];
    double galUsed=time>0.0?(galValue/60)*time:0.0;
    galUsedTextField.text=galUsed>0.0?[NSString stringWithFormat:@"%.01f",galUsed ]:@"";
    galRemTextField.text=fuelValue>0.0?[NSString stringWithFormat:@"%.01f",fuelValue-galUsed ]:@"";
    
    dist2RemTextField.text=[distRemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[distRemTextField.text doubleValue]-[dist2TextField.text doubleValue]]:@"";
    time=[self getMinutesFromString:time2TextField.text];
    galUsed=time>0.0?(galValue/60)*time:0.0;
    gal2UsedTextField.text=galUsed>0.0?[NSString stringWithFormat:@"%.01f",galUsed ]:@"";
    gal2RemTextField.text=[galRemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[galRemTextField.text doubleValue]-galUsed ]:@"";
    
    dist3RemTextField.text=[dist2RemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[dist2RemTextField.text doubleValue]-[dist3TextField.text doubleValue]]:@"";
    time=[self getMinutesFromString:time3TextField.text];
    galUsed=time>0.0?(galValue/60)*time:0.0;
    gal3UsedTextField.text=galUsed>0.0?[NSString stringWithFormat:@"%.01f",galUsed ]:@"";
    gal3RemTextField.text=[gal2RemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[gal2RemTextField.text doubleValue]-galUsed ]:@"";
    
    
    dist4RemTextField.text=[dist3RemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[dist3RemTextField.text doubleValue]-[dist4TextField.text doubleValue]]:@"";
    time=[self getMinutesFromString:time4TextField.text];
    galUsed=time>0.0?(galValue/60)*time:0.0;
    gal4UsedTextField.text=galUsed>0.0?[NSString stringWithFormat:@"%.01f",galUsed ]:@"";
    gal4RemTextField.text=[gal3RemTextField.text doubleValue]>0.0?[NSString stringWithFormat:@"%.01f",[gal3RemTextField.text doubleValue]-galUsed ]:@"";
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
-(double)getMinutesFromString:(NSString*)time {
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
    
    // minutes=minutes/60;
    
    return (hours*60)+minutes+(second/60);
    
}

-(double)getMinutesFromDecimal:(double)hours {
    float minutes;
    
    int hour=0,minute=0,second;
    
    hour=floor(hours);
    
    minutes=(hours-hour)*60;
    
    minute=floor(minutes);
    
    second=(minutes-minute)*60;
    NSLog(@"minutes:-%f",(hour*60.0)+minute);
    return (hour*60.0)+minute+(second/60);
    
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
@end
