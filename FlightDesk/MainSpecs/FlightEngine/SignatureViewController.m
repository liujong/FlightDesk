//
//  SignatureViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SignatureViewController.h"

@interface SignatureViewController ()

@end

@implementation SignatureViewController
@synthesize currentCellIndex;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    signatureDialog.autoresizesSubviews = NO;
    signatureDialog.contentMode = UIViewContentModeRedraw;
    signatureDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    signatureDialog.layer.shadowRadius = 3.0f;
    signatureDialog.layer.shadowOpacity = 1.0f;
    signatureDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    signatureDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:signatureDialog.bounds].CGPath;
    signatureDialog.layer.cornerRadius = 5.0f;
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
             signatureDialogCons.constant += -520.0f;
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
    
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             signatureDialogCons.constant += -420.0f;
             [self.view layoutIfNeeded];
             
             
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
             signatureDialogCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelSignView:self];
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
             signatureDialogCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate returnValueFromSignView:self signatureImage:[signatureView signatureImage] withIndex:currentCellIndex];
         }
         ];
    }
}

- (IBAction)onDelete:(id)sender {
    [signatureView clear];
    signatureView.image = nil;
    [signatureView setBackgroundColor:[UIColor clearColor]];
}
@end
