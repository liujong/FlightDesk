//
//  AddQuestionViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/5/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Question+CoreDataClass.h"

@class AddQuestionViewController;
@protocol AddQuestionViewControllerDelegate

@optional;
- (void)didCancelAddQuestionView:(AddQuestionViewController *)questionView;
- (void)didDoneAddQuestionView:(AddQuestionViewController *)questionView questionInfo:(NSMutableDictionary *)_questionInfo;
- (void)didDoneAddQuestionView:(AddQuestionViewController *)questionView question:(Question *)_question;
@end

@interface AddQuestionViewController : UIViewController
{
    __weak IBOutlet UIView *AddQuestionDialogView;
    __weak IBOutlet UITextField *txtQuestion;
    __weak IBOutlet UITextField *txtAnswerA;
    __weak IBOutlet UITextField *txtAnswerB;
    __weak IBOutlet UITextField *txtAnswerC;
    __weak IBOutlet UITextField *txtExpRef;
    __weak IBOutlet UITextField *txtExpCode;
    
    __weak IBOutlet UITextView *txtViewExpOfCorrectAnswer;
    __weak IBOutlet UIButton *btnAddFigure;
    
    
    __weak IBOutlet NSLayoutConstraint *AddQuestionViewPositionCons;
    
    
    __weak IBOutlet UIButton *correctAnsBtn1;
    __weak IBOutlet UIButton *correctAnsBtn2;
    __weak IBOutlet UIButton *correctAnsBtn3;
    
    __weak IBOutlet UIImageView *figureImageView;
    
    __weak IBOutlet UIImageView *titleBarImageView;
}

- (IBAction)onAddFigure:(id)sender;
- (IBAction)onDone:(id)sender;
- (IBAction)onCancel:(id)sender;

@property (nonatomic, weak, readwrite) id <AddQuestionViewControllerDelegate> delegate;
@property NSInteger currentIndex;
@property (nonatomic, strong) NSMutableDictionary *selectedQuestionInfo;
@property (nonatomic, strong) Question *selectedQuestion;
@property NSInteger currentQuizId;

- (void)animateHide;
- (void)animateShow;
- (IBAction)onMarkCorrectAnswer:(UIButton *)sender;

@end
