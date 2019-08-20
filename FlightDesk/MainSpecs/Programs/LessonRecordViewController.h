//
//  LessonRecordViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 4/6/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Lesson;

@interface LessonRecordViewController : UIViewController

- (id)initWithLesson:(Lesson*)lesson;

@property (nonatomic, retain) NSString *lessonNavTitle;

@end
