//
//  CheckListContentLabelCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/17/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <SWTableViewCell/SWTableViewCell.h>
@interface CheckListContentLabelCell : SWTableViewCell
+ (CheckListContentLabelCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblContent;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *paddingLeftLblConstraints;

@end
