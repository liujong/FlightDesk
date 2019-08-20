//
//  AdminTrainingViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/25/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdminTrainingViewController : UIViewController{

    __weak IBOutlet UIScrollView *scrView;
    __weak IBOutlet UITableView *ProgramsTableView;
    IBOutlet UIView *addProgramView;
    
    __weak IBOutlet UIView *programSelectView;
    __weak IBOutlet UIView *selectedProgramDialogView;
    __weak IBOutlet UITableView *unUsedProgramsTableView;
    
    
}
- (IBAction)onAddPrograms:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;

@end
