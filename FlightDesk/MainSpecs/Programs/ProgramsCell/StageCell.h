//
//  StageCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@interface StageCell : SWTableViewCell
+ (StageCell *)sharedCell;

@property (weak, nonatomic) IBOutlet UIImageView *exImage;
@property (weak, nonatomic) IBOutlet UILabel *stageTitle;
@property (weak, nonatomic) IBOutlet UILabel *corseStatusLbl;

@end
