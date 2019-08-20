//
//  SquawksCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@interface SquawksCell : SWTableViewCell
+ (SquawksCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblSquawks;

@end
