//
//  GlideViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface GlideViewController : UIViewController
{
    BOOL checkTime;
}
@property(nonatomic) NSInteger previousTextFieldTag;
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property(nonatomic)NSInteger lastTextFieldTag;
- (IBAction)clearGliding:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITableView *SavedRecordTableView;
- (IBAction)onSave:(id)sender;
- (IBAction)onClearAll:(id)sender;


@end
