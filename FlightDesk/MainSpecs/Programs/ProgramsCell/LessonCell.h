//
//  LessonCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>
@interface LessonCell : SWTableViewCell

+ (LessonCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lessonTitle;
@property (weak, nonatomic) IBOutlet UILabel *lessonStatus;
@property (weak, nonatomic) IBOutlet UIImageView *imgStatus;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *positionLeftLessonNameCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *postionLessonTitleWidth;

@end
