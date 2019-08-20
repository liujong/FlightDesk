//
//  AddOtherCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AddOtherCell;
@protocol AddOtherCellDelegate
@optional;
- (void)didAddedOneItemFromOtherCell:(AddOtherCell *)_cell withType:(NSString *)_type;
- (void)updateContentFromOtherCell:(AddOtherCell *)_cell withContent:(NSString *)_content;
@end
@interface AddOtherCell : UITableViewCell<UITextViewDelegate>
+ (AddOtherCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblOther;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paddingLeftContraints;
@property (weak, nonatomic) IBOutlet UITextView *contentTxtView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentHeightConstraints;
@property (weak, nonatomic) IBOutlet UIButton *btnAdd;
- (IBAction)onAddItem:(id)sender;

@property (nonatomic, weak, readwrite) id <AddOtherCellDelegate> delegate;

@end
