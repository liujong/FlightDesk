//
//  FaqsCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/31/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@interface FaqsCell : SWTableViewCell
+ (FaqsCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblQuestion;
@property (weak, nonatomic) IBOutlet UILabel *lblAnswer;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImg;

@end
