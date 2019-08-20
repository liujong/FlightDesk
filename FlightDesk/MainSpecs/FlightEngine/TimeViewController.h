//
//  TimeViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TimeViewController;
@protocol TimeViewControllerDelegate

@optional;
- (void)didCancelTimeView:(TimeViewController *)timeView;
- (void)returnValueFromTimeView:(TimeViewController *)timeView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index;
@end

@interface TimeViewController : UIViewController{
    
    __weak IBOutlet UIView *timeView;
    __weak IBOutlet UIDatePicker *timePicker;
    __weak IBOutlet NSLayoutConstraint *timeViewCons;
    __weak IBOutlet UILabel *lblTitlePicker;
}
- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;

@property (nonatomic, weak, readwrite) id <TimeViewControllerDelegate> delegate;
- (void)animateHide;
- (void)animateShow;

@property NSInteger type;
@property NSString *pickerTitle;
@property NSInteger indexForEndorsementCell;

@end
