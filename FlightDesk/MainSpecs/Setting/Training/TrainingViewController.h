//
//  TrainingViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrainingViewController : UIViewController{
    __weak IBOutlet UIScrollView *scrView;
    __weak IBOutlet UITableView *programTableView;
    __weak IBOutlet UILabel *lblProgram;

    IBOutlet UIView *footerViewOfAddProgram;
    
    __weak IBOutlet UIView *studentAddView;
    __weak IBOutlet UIView *studentFindDialog;
    __weak IBOutlet UITextField *txtStudentId;
    
    __weak IBOutlet UILabel *lblProgramName;
    
}
- (IBAction)onAddPrograms:(id)sender;
- (IBAction)onCancelAddView:(id)sender;
- (IBAction)onFindStudent:(id)sender;
- (void)reloadDataWithTraining;
@end
