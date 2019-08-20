//
//  WelcomeViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    loginYPositionCons.constant = -340.0f;
    btnSetUp.layer.cornerRadius = 5.0f;
    btnSignin.layer.cornerRadius = 5.0f;
    self.view.alpha = 0.0f; // Fade out
    
    imgThanksgivingDay.autoresizesSubviews = NO;
    imgThanksgivingDay.contentMode = UIViewContentModeRedraw;
    imgThanksgivingDay.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    imgThanksgivingDay.layer.masksToBounds = YES;
    imgThanksgivingDay.layer.shadowRadius = 3.0f;
    imgThanksgivingDay.layer.shadowOpacity = 1.0f;
    imgThanksgivingDay.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    imgThanksgivingDay.layer.shadowPath = [UIBezierPath bezierPathWithRect:imgThanksgivingDay.bounds].CGPath;
    imgThanksgivingDay.layer.cornerRadius = 20.0f;
    UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThanksGivingTap:)];
    [thanksgivedayCV addGestureRecognizer:tapToClose];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)handleThanksGivingTap:(UIGestureRecognizer *)gestureRecognizer {
    thanksgivedayCV.hidden = YES;
}
- (void)showAnimation{
    [UIView animateWithDuration:0.5
                          delay: 0.0
                        options: UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.view.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         [self showLoginRegisterView];
                     }];
}

- (void)showLoginRegisterView{
    [UIView animateWithDuration:0.5
                          delay: 0.0
                        options: UIViewAnimationOptionTransitionNone
                     animations:^{
                         loginYPositionCons.constant += 398.0f;
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

- (void)hideLoginRegisterView{
    [UIView animateWithDuration:0.5f delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         loginYPositionCons.constant += -398.0f;
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished){
                         
                     }];
}

- (IBAction)onSetupProfile:(id)sender {
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         loginYPositionCons.constant += -348.0f;
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished){
                         [self.delegate didRegisterPilotProfile:self];
                     }];
}
- (IBAction)onSignin:(id)sender {
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionCurveLinear
                     animations:^(void)
     {
         loginYPositionCons.constant += -348.0f;
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished){
                         [self.delegate didSignInPilotAccount:self];
                     }];
}
@end
