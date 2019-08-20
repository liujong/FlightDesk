//
//  SecondViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/28/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"

@interface SecondViewController : UIViewController{
    __weak IBOutlet UITableView *tblView_answer;
    __weak IBOutlet UIButton *btnFigure;
    __weak IBOutlet UIButton *btnA;
    __weak IBOutlet UIButton *btnB;
    __weak IBOutlet UIButton *btnC;
    __weak IBOutlet UIImageView *imageA;
    __weak IBOutlet UIImageView *imageB;
    __weak IBOutlet UIImageView *imageC;
    __weak IBOutlet UITextView *txtViewA;
    __weak IBOutlet UITextView *txtViewB;
    __weak IBOutlet UITextView *txtViewC;
    
    __weak IBOutlet UILabel *lblViewA;
    __weak IBOutlet UILabel *lblViewB;
    __weak IBOutlet UILabel *lblViewC;
    
    __weak IBOutlet UILabel *lbQuestionShow;
    __weak IBOutlet UITextView *txtViewQuestion;
    __weak IBOutlet UITextView *txtViewAnswer;
    
    IBOutlet UIView *navView;
    __weak IBOutlet UIButton *btnRetake;
    
    __weak IBOutlet UIButton *btnPrevious;
    __weak IBOutlet UIButton *btnNext;
    
    __weak IBOutlet UILabel *lblScore;
    __weak IBOutlet UILabel *lblExplanationReference;
    __weak IBOutlet UILabel *lblExplanationCode;
    
    __weak IBOutlet UIView *figureView;
    __weak IBOutlet UIImageView *figureImageView;
    __weak IBOutlet UILabel *lblQuizDes;
    __weak IBOutlet UIView *figureDragDropView;
}

- (IBAction)onClickPrevious:(id)sender;
- (IBAction)onclickNext:(id)sender;
- (IBAction)onBackBtn:(id)sender;
- (IBAction)onRetakeBtn:(id)sender;
- (IBAction)onFigure:(id)sender;

@property (nonatomic, retain) Quiz *currentQuiz;
@property (nonatomic, retain) NSString *quizDes;
@end
