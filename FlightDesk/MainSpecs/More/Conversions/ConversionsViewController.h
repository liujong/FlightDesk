//
//  ConversionsViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/10/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface ConversionsViewController : UIViewController
{
    NSDictionary * dictTimeZone;
    __weak IBOutlet UIScrollView *scrView;
    BOOL isShownKeyboard;
}
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property(nonatomic)NSInteger lastTextFieldTag;


- (IBAction)clearTemperature:(id)sender;
- (IBAction)clearDistance:(id)sender;
- (IBAction)clearWeights:(id)sender;
- (IBAction)clearFluids:(id)sender;
- (IBAction)clearSpeed:(id)sender;
- (IBAction)clearFuel:(id)sender;
- (IBAction)clearTime:(id)sender;
- (IBAction)clearTimeZone:(id)sender;
- (IBAction)clearAdmosPressure:(id)sender;

- (IBAction)actionLocal:(id)sender;
- (IBAction)actionZuhu:(id)sender;
- (IBAction)actionCustom:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
- (IBAction)onSave:(id)sender;
- (IBAction)onClearAll:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *SavedRecordTableView;



@end
