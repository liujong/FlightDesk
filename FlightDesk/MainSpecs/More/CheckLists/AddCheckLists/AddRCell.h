//
//  AddRCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddRCell;
@protocol AddRCellDelegate
@optional;
- (void)didAddedItemFromRCell:(AddRCell *)_cell withType:(NSString*)_type;
- (void)updatedContentFromRCell:(AddRCell *)_cell withContent:(NSString *)_content;
@end

@interface AddRCell : UITableViewCell<UITextFieldDelegate>
+ (AddRCell *)sharedCell;

@property (weak, nonatomic) IBOutlet UILabel *lblR;
@property (weak, nonatomic) IBOutlet UITextField *tailContentTxtField;
@property (weak, nonatomic) IBOutlet UITextField *preContentTxtField;

@property (weak, nonatomic) IBOutlet UIButton *btnAdd;
- (IBAction)onAddItem:(id)sender;

@property (nonatomic, weak, readwrite) id <AddRCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paddingLeftLBLConstraints;



@end
