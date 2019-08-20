//
//  StudentCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@class StudentCell;
@protocol StudentCellDelegate
@optional;
- (void)didRequestStudent:(StudentCell *)_cell;
@end

@interface StudentCell : SWTableViewCell

+ (StudentCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UITextField *txtStudentName;
@property (weak, nonatomic) IBOutlet UIButton *btnAddStudent;

@property (nonatomic, weak, readwrite) id <StudentCellDelegate> delegateWithStudent;
@property (nonatomic, retain) Student *currentStudent;
- (void)setCurrentStudent:(Student *)_student;
- (IBAction)onAddStudentView:(id)sender;


@end
