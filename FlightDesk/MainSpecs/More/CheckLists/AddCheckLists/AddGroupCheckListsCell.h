//
//  AddGroupCheckListsCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AddGroupCheckListsCell;
@protocol AddGroupCheckListsCellDelegate
@optional;
- (void)didAddedItemFromGroupCheckCell:(AddGroupCheckListsCell *)_cell withType:(NSString *)_type;
- (void)updateContentFromGroupCheckCell:(AddGroupCheckListsCell *)_cell withContent:(NSString *)_content;
@end

@interface AddGroupCheckListsCell : UITableViewCell<UITextFieldDelegate>
+ (AddGroupCheckListsCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblGroupCheckLists;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paddingLeftContriants;
@property (weak, nonatomic) IBOutlet UITextField *groupChecklistTxtField;

@property (weak, nonatomic) IBOutlet UIButton *btnAdd;
- (IBAction)onAddItem:(id)sender;


@property (nonatomic, weak, readwrite) id <AddGroupCheckListsCellDelegate> delegate;

@end
