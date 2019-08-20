//
//  StudentProgramCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StudentProgramCell;
@protocol StudentProgramCellDelegate
@optional;
- (void)didChecked:(StudentProgramCell *)_cell selected:(BOOL)_selected;
- (void)didRequestInstructor:(StudentProgramCell *)_cell;
@end
@interface StudentProgramCell : UITableViewCell
+ (StudentProgramCell *)sharedCell;

@property (nonatomic, weak, readwrite) id <StudentProgramCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *lblProgramName;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;
@property (weak, nonatomic) IBOutlet UIButton *btnSelect;
@property (weak, nonatomic) IBOutlet UIView *checkView;
@property (weak, nonatomic) IBOutlet UITextField *txtInstructorName;

- (IBAction)onChangeOrAddInstructor:(id)sender;
- (IBAction)onSelect:(id)sender;
@end
