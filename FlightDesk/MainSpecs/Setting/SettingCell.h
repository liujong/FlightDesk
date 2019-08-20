//
//  SettingCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingCell : UITableViewCell
+ (SettingCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UIImageView *itemImg;
@property (weak, nonatomic) IBOutlet UILabel *itemLbl;
@property (weak, nonatomic) IBOutlet UILabel *lblBadge;

@end
