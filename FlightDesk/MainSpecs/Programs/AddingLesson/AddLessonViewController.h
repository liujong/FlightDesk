//
//  AddLessonViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MKDropdownMenu/MKDropdownMenu.h>
#import "Student+CoreDataClass.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"
@interface AddLessonViewController : UIViewController{
    
    BOOL showKeyboard;
    
    __weak IBOutlet UIScrollView *scrView;
    
    __weak IBOutlet UIView *lessionFirstView;
    __weak IBOutlet UITextField *txtNewCourse;
    __weak IBOutlet UITextField *txtStageNumber;
    __weak IBOutlet UITextField *txtLessonTitle;
    __weak IBOutlet UITextField *txtLessonNumber;
    __weak IBOutlet UITextField *txtDualFlight;
    __weak IBOutlet UITextField *txtDualGround;
    __weak IBOutlet UITextField *txtDualInstrument;
    __weak IBOutlet UITextField *txtSoloFlight;
    __weak IBOutlet UITextField *txtLessonGroundSec;
    __weak IBOutlet UITextView *txtViewObjectivesGround;
    __weak IBOutlet MKDropdownMenu *corseDropmenu;
    
    __weak IBOutlet UITableView *groundContentAddingTableView;
    
    __weak IBOutlet UIView *lessonSecondView;
    __weak IBOutlet UITextView *txtViewCompletionObjectives;
    __weak IBOutlet UITextView *txtViewAssignObjectives;
    __weak IBOutlet UITextView *txtViewInstructorNotesGround;
    __weak IBOutlet UITextView *txtViewStudentNotesGround;
    __weak IBOutlet UITextField *txtLessonSectionFlight;
    __weak IBOutlet UITextView *txtViewObjectivesFlight;
    
    __weak IBOutlet UITableView *flightContentAddingTableView;
    
    __weak IBOutlet UIView *lessonThirdView;
    __weak IBOutlet UITextView *txtViewCompletionFlight;
    __weak IBOutlet UITextView *txtViewAssignFlight;
    __weak IBOutlet UITextView *txtViewInstructorNotesFlight;
    __weak IBOutlet UITextView *txtViewStudentNotesFlight;
    
    IBOutlet UIView *contentAddView;
    IBOutlet UIView *contentAddViewForFlight;
    
    __weak IBOutlet UILabel *lblObjectivesPlaceHolderGround;
    __weak IBOutlet UILabel *lblCSPlaceHolderGround;
    __weak IBOutlet UILabel *lblARPlaceHoderGround;
    __weak IBOutlet UILabel *lblINPlaceHoderGround;
    __weak IBOutlet UILabel *lblSNPlaceHoderGround;
    
    __weak IBOutlet UILabel *lblObjectivesPlaceHolderFlight;
    __weak IBOutlet UILabel *lblCSPlaceHolderFlight;
    __weak IBOutlet UILabel *lblARPlaceHolderFlight;
    __weak IBOutlet UILabel *lblINPlaceHolderFlight;
    __weak IBOutlet UILabel *lblSNPlaceHolderFlight;
    
    IBOutlet UIView *navView;
    
    __weak IBOutlet UIButton *btnAssignmentToAddAndEditForGround;
    __weak IBOutlet UIButton *btnAssignmentToAddAndEditForFlight;
    
    __weak IBOutlet UIButton *btnAddContentSectionFlight;
    __weak IBOutlet UIButton *btnAddContentSectionGround;
    
    __weak IBOutlet UIButton *btnCheckAssignTo;
    __weak IBOutlet UILabel *lblAssignToUser;
}
- (IBAction)onAddContentSecForflight:(id)sender;
- (IBAction)onAddContentSec:(UIButton *)sender;
- (IBAction)onAddAssignmentForGround:(id)sender;
- (IBAction)onAddAssignmentForFlight:(id)sender;

@property (nonatomic, retain) Lesson *currentLesson;
@property BOOL isEditOldLesson;
- (IBAction)onBack:(id)sender;
- (IBAction)onSave:(id)sender;
- (IBAction)onCheckAssignTo:(id)sender;

@end
