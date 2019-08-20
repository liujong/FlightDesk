//
//  StutdentCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StutdentCell : UITableViewCell
+ (StutdentCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblStudentName;
@property (weak, nonatomic) IBOutlet UIImageView *imgStudentArrow;
@end
