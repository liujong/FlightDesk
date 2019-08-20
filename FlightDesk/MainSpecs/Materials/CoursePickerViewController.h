//
//  CoursePickerViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 2/8/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CoursePickerDelegate <NSObject>

@required

-(void)selectedCourse:(NSString *)courseName;

@end

@interface CoursePickerViewController : UITableViewController

- (id)initWithStyle:(UITableViewStyle)style andCourses:(NSArray*)courseArray;

@property (nonatomic, weak) id<CoursePickerDelegate> delegate;

@end
