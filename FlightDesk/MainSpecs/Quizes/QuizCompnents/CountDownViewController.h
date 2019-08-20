//
//  CountDownViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/7/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CountDownViewController;
@protocol CountDownViewControllerDelegate

@optional;
- (void)didCancelCoundDownView:(CountDownViewController *)countDownView;
- (void)returnValueFromCoundDownView:(CountDownViewController *)countDownView strDate:(NSString *)_strDate;
@end

@interface CountDownViewController : UIViewController{
    __weak IBOutlet UIView *countDownView;
    __weak IBOutlet NSLayoutConstraint *countDownViewCons;
    __weak IBOutlet UIDatePicker *countDownPicker;
}

- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;
@property (nonatomic, weak, readwrite) id <CountDownViewControllerDelegate> delegate;
- (void)animateHide;
- (void)animateShow;
@end
