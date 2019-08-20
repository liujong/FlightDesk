//
//  DateViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "DateViewController.h"
#import "NTMonthYearPicker.h"

@interface DateViewController ()
{
    NTMonthYearPicker *monthYearPicker;
}
@end

@implementation DateViewController
@synthesize indexForEndorsementCell;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    monthYearCoverView.hidden = YES;
    monthYearPicker = [[NTMonthYearPicker alloc] initWithFrame:CGRectMake( 0, 0, monthYearCoverView.frame.size.width, monthYearCoverView.frame.size.height)];
    [monthYearPicker addTarget:self action:@selector(onDatePicked:) forControlEvents:UIControlEventValueChanged];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSCalendar *cal = [NSCalendar currentCalendar];

    // Set mode to month + year
    // This is optional; default is month + year
    monthYearPicker.datePickerMode = NTMonthYearPickerModeMonthAndYear;

    // Set minimum date to January 2000
    // This is optional; default is no min date
    [comps setDay:1];
    [comps setMonth:1];
    [comps setYear:2000];
    monthYearPicker.minimumDate = [cal dateFromComponents:comps];

    // Set maximum date to next month
    // This is optional; default is no max date
    [comps setDay:31];
    [comps setMonth:12];
    [comps setYear:2999];
    monthYearPicker.maximumDate = [cal dateFromComponents:comps];

    // Set initial date to last month
    // This is optional; default is current month/year
    [comps setDay:0];
    [comps setMonth:-1];
    [comps setYear:0];
    monthYearPicker.date = [cal dateByAddingComponents:comps toDate:[NSDate date] options:0];
    monthYearPicker.datePickerMode = NTMonthYearPickerModeMonthAndYear;
    [monthYearCoverView addSubview:monthYearPicker];
    
    dateView.autoresizesSubviews = NO;
    dateView.contentMode = UIViewContentModeRedraw;
    dateView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    dateView.layer.shadowRadius = 3.0f;
    dateView.layer.shadowOpacity = 1.0f;
    dateView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    dateView.layer.shadowPath = [UIBezierPath bezierPathWithRect:dateView.bounds].CGPath;
    dateView.layer.cornerRadius = 5.0f;
    
}
- (void) pickerView:(UIPickerView *)pickerView didChangeDate:(NSDate *)newDate {
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateHide{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dateViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}
- (void)animateShow{
    
    lblTitlePicker.text = _pickerTitle;
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        if (self.type == 2) {
            datePick.hidden = YES;
            monthYearCoverView.hidden = NO;
        }
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             dateViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
             
             lblTitlePicker.text = _pickerTitle;
             
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
         }
         ];
    }
}
- (void)onDatePicked:(UITapGestureRecognizer *)gestureRecognizer {
    
}
- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dateViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelDateView:self];
         }
         ];
    }
}

- (IBAction)onDone:(id)sender {
    
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dateViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
             [dateFormat setDateFormat:@"MM/dd/yyyy"];
             NSString *theDate = [dateFormat stringFromDate:datePick.date];
             if (self.type == 2){
                 [dateFormat setDateFormat:@"MM/yyyy"];
                 theDate = [dateFormat stringFromDate:monthYearPicker.date];
                 monthYearCoverView.hidden = YES;
                 datePick.hidden = NO;
             }
             [self.delegate returnValueFromDateView:self type:_type strDate:theDate withIndex:indexForEndorsementCell];
         }
         ];
    }
}
@end
