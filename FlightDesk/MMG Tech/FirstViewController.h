//
//  FirstViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"

@interface FirstViewController : UIViewController{
    //finish view
    __weak IBOutlet UIView *finishViewDialog;
    __weak IBOutlet UIButton *btnNoOnFinishView;
    __weak IBOutlet UIButton *btnYesOnFinishView;
    
    //exit view
    __weak IBOutlet UIView *exitViewDialog;
    __weak IBOutlet UIButton *btnYesOnExitView;
    __weak IBOutlet UIButton *btnNoOnExitView;
    
    //bottom buttons
    __weak IBOutlet UIButton *btnExitOnBottom;
    __weak IBOutlet UIButton *btnUnmarkOnBottom;
    __weak IBOutlet UIButton *btnMarkOnBottom;
    __weak IBOutlet UIButton *btnPreviousOnBottom;
    __weak IBOutlet UIButton *btnNextOnBottom;
    __weak IBOutlet UIButton *btnCalculatorOnBottom;
    __weak IBOutlet UIButton *btnFinishOnBottom;
    
    IBOutlet UIView *navView;
    __weak IBOutlet UILabel *lblQuizName;
    
    __weak IBOutlet UILabel *lblQuizDes;
    
    //questions status
    __weak IBOutlet UILabel *lblUnansweredCount;
    __weak IBOutlet UILabel *lblAnswerdCount;
    __weak IBOutlet UILabel *lblMarkedCount;
    __weak IBOutlet UILabel *lblMarkedAnsweredCount;
    
    //Explanation for instructor
    __weak IBOutlet UIView *explanationView;
    __weak IBOutlet UILabel *lblExpReference;
    __weak IBOutlet UILabel *lblExpCode;
    __weak IBOutlet UITextView *lblExpForAnswer;
    
    //indicate for instructor
    __weak IBOutlet UIImageView *imgA;
    __weak IBOutlet UIImageView *imgB;
    __weak IBOutlet UIImageView *imgC;
    
    __weak IBOutlet UIView *figureDragDropView;
    
    __weak IBOutlet UILabel *lblViewA;
    __weak IBOutlet UILabel *lblViewB;
    __weak IBOutlet UILabel *lblViewC;
    
}
@property(nonatomic,retain) IBOutlet UITextView *txtViewQuestion;
@property(nonatomic,retain) IBOutlet UITextView *txtViewA;
@property(nonatomic,retain) IBOutlet UITextView *txtViewB;
@property(nonatomic,retain) IBOutlet UITextView *txtViewC;

@property(nonatomic,retain) IBOutlet UITableView *tblViewQuestions;

@property(nonatomic,retain) IBOutlet UIButton *btnA;
@property(nonatomic,retain) IBOutlet UIButton *btnB;
@property(nonatomic,retain) IBOutlet UIButton *btnC;
@property(nonatomic,retain) IBOutlet UIButton *btnFigure;


@property(nonatomic,retain) IBOutlet UIImageView *imgViewA;
@property(nonatomic,retain) IBOutlet UIImageView *imgViewB;
@property(nonatomic,retain) IBOutlet UIImageView *imgViewC;
@property(nonatomic,retain) IBOutlet UIImageView *imgViewfigure;

@property(nonatomic,retain) IBOutlet UIView *viewfigure;
@property(nonatomic,retain) IBOutlet UIView *viewexit;
@property(nonatomic,retain) IBOutlet UIView *viewfinish;

@property(nonatomic,retain)IBOutlet UILabel *lblTimer;
@property(nonatomic,retain)IBOutlet UILabel *lblTimeShow;
@property(nonatomic,retain)IBOutlet UILabel *lblQuestionShow;

- (IBAction)onClickFigure:(UIButton *)sender;
- (IBAction)onClickOption:(UIButton *)sender;

- (IBAction)onClickExitFinish:(UIButton *)sender;
- (IBAction)onClickUnmarkMark:(UIButton *)sender;
- (IBAction)onClickPrevious:(UIButton *)sender;
- (IBAction)onClickNext:(UIButton *)sender;
- (IBAction)okClickCalculator:(id)sender;

- (IBAction)onClickYesNo:(UIButton *)sender;
- (IBAction)onBackProgramQuiz:(id)sender;

@property (nonatomic, retain) NSString *quizDes;
@property (nonatomic, retain) Quiz *currentQuiz;

@end
