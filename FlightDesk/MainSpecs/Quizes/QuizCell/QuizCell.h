//
//  QuizCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@interface QuizCell : SWTableViewCell
+ (QuizCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *quizTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblQuizStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblQuizTaken;
@property (weak, nonatomic) IBOutlet UILabel *lblQuizScore;

@end
