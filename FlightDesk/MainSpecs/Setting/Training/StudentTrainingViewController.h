//
//  StudentTrainingViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StudentTrainingViewController : UIViewController{
    
    __weak IBOutlet UIScrollView *scrView;
    
    __weak IBOutlet UITableView *ProgramsShowTableView;
    
    __weak IBOutlet UIView *instructorFindDialog;
    __weak IBOutlet UIView *instructorFindView;
    __weak IBOutlet UITextField *txtInsID;
    
}
- (IBAction)onCancel:(id)sender;
- (IBAction)onFind:(id)sender;

- (void)reloadDataWithTraining;
@end
