//
//  PilotGroupCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@interface PilotGroupCell : SWTableViewCell

+ (PilotGroupCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UIImageView *exImage;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

@property (weak, nonatomic) IBOutlet UIProgressView *statusProgressView;
@property (weak, nonatomic) IBOutlet UILabel *statusProgressLbl;


@end
