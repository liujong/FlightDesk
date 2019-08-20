//
//  WindViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface WindViewController : UIViewController
{
    BOOL checkTime;
}
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property(nonatomic) NSInteger previousTextFieldTag;
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property(nonatomic)NSInteger lastTextFieldTag;
- (IBAction)onWindClear:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
- (IBAction)onSAve:(id)sender;
- (IBAction)onClearAll:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *SavedRecordTableView;



@end
