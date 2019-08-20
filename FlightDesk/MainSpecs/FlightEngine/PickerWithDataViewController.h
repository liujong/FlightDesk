//
//  PickerWithDataViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PickerWithDataViewController;
@protocol PickerWithDataViewControllerDelegate

@optional;
- (void)didCancelPickerView:(PickerWithDataViewController *)pickerView;
- (void)returnValueFromPickerView:(PickerWithDataViewController *)pickerView withSelectedString:(NSString *)toString withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index;
@end
@interface PickerWithDataViewController : UIViewController
{
    __weak IBOutlet UIView *pickerDialog;
    __weak IBOutlet UILabel *lblPickerTitle;
    __weak IBOutlet UIPickerView *currentPicker;

    __weak IBOutlet NSLayoutConstraint *pickerDialogCons;
    __weak IBOutlet NSLayoutConstraint *pickerDialogWidthCons;
    __weak IBOutlet NSLayoutConstraint *cancelBtnLeftCons;
    __weak IBOutlet NSLayoutConstraint *doneBtnRightCons;
}

- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;

@property (nonatomic, weak, readwrite) id <PickerWithDataViewControllerDelegate> delegate;
@property NSInteger pickerType;
@property NSString *strToSend;
@property NSMutableArray *pickerItems;
@property NSInteger cellIndexForEndorsement;
@property NSMutableArray *arrLookUpCategories;
- (void)animateHide;
- (void)animateShow;
@end
