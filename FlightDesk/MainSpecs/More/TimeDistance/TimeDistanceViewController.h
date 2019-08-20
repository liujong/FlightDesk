//
//  TimeDistanceViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/11/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface TimeDistanceViewController : UIViewController
{
    BOOL checkTime;
}
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property(nonatomic) NSInteger previousTextFieldTag;
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property(nonatomic)NSInteger lastTextFieldTag;
- (IBAction)clearDistance:(id)sender;
- (IBAction)clearETA:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
- (IBAction)onSave:(id)sender;
- (IBAction)onClearAll:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *SavedRecordTableView;



@end
