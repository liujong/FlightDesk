//
//  QuestionCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@interface QuestionCell : SWTableViewCell
+ (QuestionCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *questionDes;
@property (nonatomic, strong) NSDictionary *currentDist;
- (void)setDist:(NSDictionary *)dist;
@end
