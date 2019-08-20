//
//  ToldViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface ToldViewController : UIViewController{

    __weak IBOutlet UIScrollView *scrView;
    BOOL isShownKeyboard;
}
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property (strong, nonatomic) IBOutlet UIButton *btnClearAll;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property(nonatomic)NSInteger lastTextFieldTag;
- (IBAction)actionClearAll:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
- (IBAction)onSave:(id)sender;
- (IBAction)onClearAll:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *SavedRecordTableView;


@end
