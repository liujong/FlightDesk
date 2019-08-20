//
//  QuizCourseCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/6/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuizCourseCell : UITableViewCell

+ (QuizCourseCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UIImageView *expandableImageView;
@property (weak, nonatomic) IBOutlet UILabel *corseTitle;
@property (weak, nonatomic) IBOutlet UILabel *quizCountLbl;


@end
