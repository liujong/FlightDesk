//
//  CheckListContentCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@class CheckListContentCell;
@protocol CheckListContentCellDelegate
@optional;
- (void)didCheckedCheckListItem:(CheckListContentCell *)_cell withStatus:(BOOL)isChecked;
@end

@interface CheckListContentCell : SWTableViewCell
+ (CheckListContentCell *)sharedCell;
@property (nonatomic, weak, readwrite) id <CheckListContentCellDelegate> delegateToUpdate;
@property (weak, nonatomic) IBOutlet UIButton *btnCheckListItem;
@property (weak, nonatomic) IBOutlet UILabel *checkListContentLBL;
@property (weak, nonatomic) IBOutlet UILabel *lblBridge;
@property (weak, nonatomic) IBOutlet UILabel *lblCheckListContentValue;
- (IBAction)onCheck:(id)sender;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentLblConstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentTailLblConstraints;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paddingLeftConstraints;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnCheckHeightCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnCheckWidthCons;

@end
