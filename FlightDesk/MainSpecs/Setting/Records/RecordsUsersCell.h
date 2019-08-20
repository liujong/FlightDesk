//
//  RecordsUsersCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordsUsersCell : UITableViewCell
+ (RecordsUsersCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblUserName;

@end
