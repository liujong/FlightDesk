//
//  MainCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainCell : UITableViewCell
+ (MainCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblColor;
@property (weak, nonatomic) IBOutlet UILabel *lblQuestion;

@end
