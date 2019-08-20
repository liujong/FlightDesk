//
//  MainCheckListsViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecureViewController.h"
#import <MKDropdownMenu/MKDropdownMenu.h>
#import "Spring.h"

#import "WLColView.h"

@class SpringButton;
@class SpringLabel;
@interface MainCheckListsViewController : SecureViewController
{
    UIButton *addButton;
    UIButton *shareButton;
    __weak IBOutlet UIView *sliderCoverView;
    
    __weak IBOutlet MKDropdownMenu *groupsDropDownMenu;
    __weak IBOutlet MKDropdownMenu *checkListsDropDownMenu;
    __weak IBOutlet UITableView *ChecklistsContentsTableView;
    
    __weak IBOutlet UILabel *lblStatus;
    __weak IBOutlet UILabel *lblWaring;
    __weak IBOutlet NSLayoutConstraint *lblWarringConstrainsHeight;
    __weak IBOutlet UIButton *btnNextCheckList;
    __weak IBOutlet UISwitch *styleChecklistSwitch;
    __weak IBOutlet UIView *boardToChangeColor;
    
    __weak IBOutlet UILabel *lblGroup;
    __weak IBOutlet UILabel *lblCheckList;
    __weak IBOutlet UILabel *lblStandard;
    __weak IBOutlet UILabel *lblG100;
    
    __weak IBOutlet UIButton *btnCancelDeleteMode;
    
    __weak IBOutlet SpringButton *btnEmergency;
    __weak IBOutlet SpringButton *btnClear;
    __weak IBOutlet SpringButton *btnClearAll;
    __weak IBOutlet SpringButton *btnExit;
    
    __weak IBOutlet UIView *checklistCVToChangeColor;
    __weak IBOutlet UIView *nextBtnBackGroundView;
    
    //R EditView
    IBOutlet UIView *rCoverViewToEdit;
    __weak IBOutlet MKDropdownMenu *rCVDropDownToEdit;
    __weak IBOutlet UITextField *rCVDeptTxtFieldToEdit;
    __weak IBOutlet UITextField *rCVPreTxtFieldToEdit;
    __weak IBOutlet UITextField *rCVTailTxtViewToEdit;
    
    
    //other EditView
    IBOutlet UIView *otherCoverViewToEdit;
    __weak IBOutlet MKDropdownMenu *otherCVDropDownToEdit;
    __weak IBOutlet UITextField *otherCVDeptTxtFieldToEdit;
    __weak IBOutlet UITextView *otherCVTxtView;
    
    __weak IBOutlet UIView *standardToolView;
    __weak IBOutlet UIView *seperatedLineView;
    
    __weak IBOutlet UIView *styleSwithCV;
    
    __weak IBOutlet NSLayoutConstraint *boardTopPositionCons;
    __weak IBOutlet NSLayoutConstraint *boardBottomPostionCons;
    __weak IBOutlet NSLayoutConstraint *boardLeftPositionCons;
    __weak IBOutlet NSLayoutConstraint *boardrightPositionCons;
    
    __weak IBOutlet UIButton *btnFullScreen;
    
}
- (IBAction)onCancelDeleteMode:(id)sender;
- (IBAction)onChangedStyleChecklists:(id)sender;
- (IBAction)onGotoNextCheckLists:(id)sender;

- (IBAction)onExit:(id)sender;
- (IBAction)onClearAll:(id)sender;
- (IBAction)onClear:(id)sender;
- (IBAction)onEvergency:(id)sender;
- (IBAction)onCheckContent:(id)sender;

- (IBAction)onRCVUpdate:(id)sender;
- (IBAction)onOtherCVUpdate:(id)sender;
- (IBAction)onFullScreenMode:(id)sender;


@end
