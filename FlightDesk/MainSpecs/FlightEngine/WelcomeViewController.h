//
//  WelcomeViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WelcomeViewController;
@protocol WelcomeViewControllerDelegate

@optional;
- (void)didRegisterPilotProfile:(WelcomeViewController *)welView;
- (void)didSignInPilotAccount:(WelcomeViewController *)welView;
@end
@interface WelcomeViewController : UIViewController
{
    __weak IBOutlet UIView *loginRegisterView;
    __weak IBOutlet UIButton *btnSetUp;
    __weak IBOutlet UIButton *btnSignin;
    
    __weak IBOutlet NSLayoutConstraint *loginYPositionCons;
    
    __weak IBOutlet UIView *thanksgivedayCV;
    __weak IBOutlet UIImageView *imgThanksgivingDay;
    
    
}
@property (nonatomic, weak, readwrite) id <WelcomeViewControllerDelegate> delegate;
- (IBAction)onSetupProfile:(id)sender;
- (IBAction)onSignin:(id)sender;

- (void)showAnimation;

@end
