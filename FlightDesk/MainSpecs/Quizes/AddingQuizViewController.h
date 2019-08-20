//
//  AddingQuizViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/5/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MKDropdownMenu/MKDropdownMenu.h>
#import "Student+CoreDataClass.h"
#import "LessonGroup+CoreDataClass.h"
#import "Lesson+CoreDataClass.h"

@interface AddingQuizViewController : UIViewController
{
    __weak IBOutlet UIScrollView *scrView;
    
    __weak IBOutlet UITextField *txtQuizname;
    __weak IBOutlet UITextField *txtQuizNumber;
    __weak IBOutlet UITextField *txtTimeLimit;
    __weak IBOutlet UITextField *txtPassingScore;
    
    __weak IBOutlet UITableView *QuestionTableView;
    __weak IBOutlet UIButton *addQuestionBtn;
    
    __weak IBOutlet MKDropdownMenu *corseDropmenu;
    
    
    IBOutlet UIView *navView;
    
}
- (IBAction)onAddQuestion:(id)sender;
- (IBAction)onSetTimeLimit:(id)sender;

@property (nonatomic, retain) Student *currentStudent;
@property (nonatomic, retain) Quiz *currentQuiz;
@property BOOL isEditOldQuiz;

- (IBAction)onBackQuizPrograms:(id)sender;
- (IBAction)onSave:(id)sender;

@end
