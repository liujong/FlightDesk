//
//  AddAssignmentViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AddAssignmentViewController;
@protocol AddAssignmentViewControllerDelegate

@optional;
- (void)didCancelAddAssignmentView:(AddAssignmentViewController *)assignmentView;
- (void)didDoneAddAssignmentView:(AddAssignmentViewController *)assignmentView assignmentInfo:(NSMutableArray *)_assignmentInfo type:(NSInteger)_type;
@end
@interface AddAssignmentViewController : UIViewController

{
    __weak IBOutlet UIView *assignmentDialogView;
    __weak IBOutlet UITextField *txtAssignmentReference;
    __weak IBOutlet UITextField *txtAssignmentTitle;
    __weak IBOutlet UITextField *txtAssignmentChapters;
    __weak IBOutlet UITableView *AssignmentsTableView;
    __weak IBOutlet UIButton *btnAddOrEdit;

    __weak IBOutlet NSLayoutConstraint *dialogPositionCons;
    __weak IBOutlet UIImageView *titleBarImageView;
}

- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;
- (IBAction)onAddAssignments:(id)sender;

@property (nonatomic, weak, readwrite) id <AddAssignmentViewControllerDelegate> delegate;
@property NSInteger assignmentType;
@property (nonatomic, retain) NSMutableArray *assignmentArray;
- (void)animateHide;
- (void)animateShow;

@end
