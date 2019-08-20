//
//  UserManageCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/9/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@interface UserManageCell : SWTableViewCell

+ (UserManageCell *)sharedCell;

@property (weak, nonatomic) IBOutlet UILabel *lblContentUser;


@end
