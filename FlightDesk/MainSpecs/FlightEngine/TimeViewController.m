//
//  TimeViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "TimeViewController.h"

@interface TimeViewController ()

@end

@implementation TimeViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    timeView.autoresizesSubviews = NO;
    timeView.contentMode = UIViewContentModeRedraw;
    timeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    timeView.layer.shadowRadius = 3.0f;
    timeView.layer.shadowOpacity = 1.0f;
    timeView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    timeView.layer.shadowPath = [UIBezierPath bezierPathWithRect:timeView.bounds].CGPath;
    timeView.layer.cornerRadius = 5.0f;
    
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
             timeViewCons.constant += -520.0f;
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
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             timeViewCons.constant += -520.0f;
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

- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             timeViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelTimeView:self];
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
             timeViewCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
             [dateFormat setDateFormat:@"HH:mm"];
             NSString *theDate = [dateFormat stringFromDate:timePicker.date];
             [self.delegate returnValueFromTimeView:self type:_type strDate:theDate withIndex:0];
         }
         ];
    }
}

@end
