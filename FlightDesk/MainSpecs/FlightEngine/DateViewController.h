//
//  DateViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/2/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DateViewController;
@protocol DateViewControllerDelegate

@optional;
- (void)didCancelDateView:(DateViewController *)dateView;
- (void)returnValueFromDateView:(DateViewController *)dateView type:(NSInteger)_type strDate:(NSString *)_strDate withIndex:(NSInteger)index;
@end

@interface DateViewController : UIViewController
{
    
    __weak IBOutlet UIView *dateView;
    __weak IBOutlet UIDatePicker *datePick;
    __weak IBOutlet NSLayoutConstraint *dateViewCons;
    __weak IBOutlet UILabel *lblTitlePicker;
    __weak IBOutlet UIView *monthYearCoverView;
}
- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;

@property (nonatomic, weak, readwrite) id <DateViewControllerDelegate> delegate;
- (void)animateHide;
- (void)animateShow;

@property NSInteger type;
@property NSString *pickerTitle;
@property NSInteger indexForEndorsementCell;

@end
