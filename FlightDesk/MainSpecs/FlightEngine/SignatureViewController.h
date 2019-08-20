//
//  SignatureViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SignatureView/SignatureView.h>

@class SignatureViewController;
@protocol SignatureViewControllerDelegate

@optional;
- (void)didCancelSignView:(SignatureViewController *)signView;
- (void)returnValueFromSignView:(SignatureViewController *)signView signatureImage:(UIImage *)_signImage withIndex:(NSInteger)index;
@end
@interface SignatureViewController : UIViewController
{
    __weak IBOutlet UIView *signatureDialog;
    __weak IBOutlet SignatureView *signatureView;
    __weak IBOutlet NSLayoutConstraint *signatureDialogCons;

}
- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;
- (IBAction)onDelete:(id)sender;


@property NSInteger currentCellIndex;
@property (nonatomic, weak, readwrite) id <SignatureViewControllerDelegate> delegate;
- (void)animateHide;
- (void)animateShow;

@end
