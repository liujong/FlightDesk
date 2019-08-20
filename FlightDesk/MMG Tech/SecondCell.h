//
//  SecondCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondCell : UITableViewCell
+ (SecondCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblNo;
@property (weak, nonatomic) IBOutlet UIImageView *imageviewAnswer;
@end
