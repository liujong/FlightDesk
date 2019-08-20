//
//  FirstViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "FirstViewController.h"
#import "MainCell.h"
#import "SecondViewController.h"
#import "AppDelegate.h"
#import "JSON.h"
#import "SQLiteDatabase.h"
#import "PersistentCoreDataStack.h"
#import "CalculatorViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIView_DragDrop/UIView+DragDrop.h>

@interface FirstViewController ()<UIViewDragDropDelegate, UIGestureRecognizerDelegate, NSURLSessionDownloadDelegate>{
    NSInteger int_count;
    
    BOOL isInstructor;
    
    NSTimer *countDownTimer;
    int currHour;
    int currMinute;
    int currSeconds;
    NSManagedObjectContext *context;
    NSMutableArray *arrayQuizToUpdate;
}

@end

@implementation FirstViewController
@synthesize txtViewQuestion,tblViewQuestions;
@synthesize imgViewA,imgViewB,imgViewC;
@synthesize btnA,btnB,btnC;
@synthesize btnFigure;
@synthesize txtViewA,txtViewB,txtViewC;
@synthesize viewexit,viewfigure,viewfinish;
@synthesize lblQuestionShow,lblTimer,lblTimeShow,imgViewfigure;

@synthesize currentQuiz, quizDes;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    //init array
    arrayQuizToUpdate = [[NSMutableArray alloc] init];
    for (Question *questionToAdd in currentQuiz.questions) {
        NSMutableDictionary *questionDetails = [[NSMutableDictionary alloc] init];
        [questionDetails setObject:questionToAdd.answerA forKey:@"answerA"];
        [questionDetails setObject:questionToAdd.answerB forKey:@"answerB"];
        [questionDetails setObject:questionToAdd.answerC forKey:@"answerC"];
        [questionDetails setObject:questionToAdd.explanationcode forKey:@"explanationcode"];
        [questionDetails setObject:questionToAdd.explanationReference forKey:@"explanationReference"];
        [questionDetails setObject:questionToAdd.explanationofcorrectAnswer forKey:@"explanationofcorrectAnswer"];
        [questionDetails setObject:questionToAdd.figureurl forKey:@"figureurl"];
        [questionDetails setObject:questionToAdd.gaveAnswer forKey:@"gaveAnswer"];
        [questionDetails setObject:questionToAdd.marked forKey:@"marked"];
        [questionDetails setObject:questionToAdd.ordering forKey:@"ordering"];
        [questionDetails setObject:questionToAdd.question forKey:@"question"];
        [questionDetails setObject:questionToAdd.questionId forKey:@"questionId"];
        [questionDetails setObject:questionToAdd.correctAnswer forKey:@"correctAnswer"];
        
        [arrayQuizToUpdate addObject:questionDetails];
    }
    
    
    lblQuizName.text = [NSString stringWithFormat:@"Quiz %ld", [currentQuiz.quizNumber integerValue]];
    //View Init
    finishViewDialog.autoresizesSubviews = NO;
    finishViewDialog.contentMode = UIViewContentModeRedraw;
    finishViewDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    finishViewDialog.layer.shadowRadius = 3.0f;
    finishViewDialog.layer.shadowOpacity = 1.0f;
    finishViewDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    finishViewDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:finishViewDialog.bounds].CGPath;
    finishViewDialog.layer.cornerRadius = 5.0f;
    
    exitViewDialog.autoresizesSubviews = NO;
    exitViewDialog.contentMode = UIViewContentModeRedraw;
    exitViewDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    exitViewDialog.layer.shadowRadius = 3.0f;
    exitViewDialog.layer.shadowOpacity = 1.0f;
    exitViewDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    exitViewDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:exitViewDialog.bounds].CGPath;
    exitViewDialog.layer.cornerRadius = 5.0f;
    
    btnNoOnFinishView.layer.cornerRadius = 5.0f;
    btnYesOnFinishView.layer.cornerRadius = 5.0f;
    btnYesOnExitView.layer.cornerRadius = 5.0f;
    btnNoOnExitView.layer.cornerRadius = 5.0f;
    btnExitOnBottom.layer.cornerRadius = 5.0f;
    btnUnmarkOnBottom.layer.cornerRadius = 5.0f;
    btnMarkOnBottom.layer.cornerRadius = 5.0f;
    btnPreviousOnBottom.layer.cornerRadius = 5.0f;
    btnNextOnBottom.layer.cornerRadius = 5.0f;
    btnCalculatorOnBottom.layer.cornerRadius = 5.0f;
    btnFinishOnBottom.layer.cornerRadius = 5.0f;
    btnA.layer.cornerRadius = 5.0f;
    btnB.layer.cornerRadius = 5.0f;
    btnC.layer.cornerRadius = 5.0f;
    btnFigure.layer.cornerRadius = 5.0f;
    int_count = 0;
    
    //make a view draggable
    [figureDragDropView makeDraggable];
    [figureDragDropView setDelegate:self];
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        isInstructor = YES;
        btnFinishOnBottom.enabled = NO;
        btnMarkOnBottom.enabled = NO;
        btnUnmarkOnBottom.enabled = NO;
        lblTimer.text = currentQuiz.timeLimit;
        explanationView.hidden = NO;
        imgA.hidden = NO;
        imgB.hidden = NO;
        imgC.hidden = NO;
    }else{
        isInstructor = NO;
        btnFinishOnBottom.enabled = YES;
        btnMarkOnBottom.enabled = YES;
        btnUnmarkOnBottom.enabled = YES;
        NSString *timeLimitStr = currentQuiz.timeLimit;
        NSArray *parseTime = [timeLimitStr componentsSeparatedByString:@":"];
        if (parseTime.count >1) {
            currHour = [parseTime[0] intValue];
            currMinute = [parseTime[1] intValue];
            currSeconds = 0;
            countDownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
        }
        explanationView.hidden = YES;
        imgA.hidden = YES;
        imgB.hidden = YES;
        imgC.hidden = YES;
    }
    lblQuizDes.text = quizDes;
    [self reloadCountsForStatusOfQuestions];
    
    [self questionReport:int_count];
    
    UIPinchGestureRecognizer *twoFingerPinch = [[UIPinchGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(twoFingerPinch:)];
    [figureDragDropView addGestureRecognizer:twoFingerPinch];
    
    
    [AppDelegate sharedDelegate].currentQuizId = currentQuiz.quizId;
    [AppDelegate sharedDelegate].isTestingScreen = YES;
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self setNavigationColorWithGradiant];
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen].bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:233.0f/255.0f green:244.0f/255.0f blue:0.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:24.0f/255.0f green:140.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer
{
    //    NSLog(@"Pinch scale: %f", recognizer.scale);
    //if (recognizer.scale >1.0f && recognizer.scale < 2.5f) {
        CGAffineTransform transform = CGAffineTransformMakeScale(recognizer.scale, recognizer.scale);
        figureDragDropView.transform = transform;
    //}
}
-(void)timerFired
{
    if (currHour == 0 && currMinute == 0 && currSeconds == 0) {
        [countDownTimer invalidate];
    }else{
        if (currSeconds == 0 && currMinute != 0) {
            currMinute -= 1;
            currSeconds = 60;
        }
        
        if(currMinute == 0 && currHour != 0){
            currHour -= 1;
            currMinute = 59;
            currSeconds = 60;
        }
        
        if (currSeconds > 0){
            currSeconds -= 1;
        }
        if(currSeconds>-1){
            NSString *h, *m, *s = @"";
            if (currSeconds < 10) {
                s = [NSString stringWithFormat:@"0%d", currSeconds];
            }else{
                s = [NSString stringWithFormat:@"%d", currSeconds];
            }
            if (currMinute < 10) {
                m = [NSString stringWithFormat:@"0%d", currMinute];
            }else{
                m = [NSString stringWithFormat:@"%d", currMinute];
            }
            if (currHour < 10) {
                h = [NSString stringWithFormat:@"0%d", currHour];
            }else{
                h = [NSString stringWithFormat:@"%d", currHour];
            }
            
            [lblTimer setText:[NSString stringWithFormat:@"%@ : %@ : %@",h, m, s]];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar addSubview:navView];
    txtViewQuestion.layer.borderWidth = 2.0;
    txtViewQuestion.layer.borderColor = [UIColor colorWithRed:96.0/255 green:73.0/255 blue:59.0/255 alpha:1.0].CGColor;
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSingleTap:)];
    [viewfigure addGestureRecognizer:singleFingerTap];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"FirstViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    [navView removeFromSuperview];
    
}
- (void)showAlert:(NSString *)title message:(NSString *)msg{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title
                                                                  message:msg
                                                           preferredStyle:UIAlertControllerStyleAlert];    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        //NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    // CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    viewexit.hidden = YES;
    viewfigure.hidden = YES;
    viewfinish.hidden = YES;
    CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
    figureDragDropView.transform = transform;
    //Do stuff here...
}

-(void)questionReport :(NSInteger)question
{
    
    btnA.backgroundColor = [UIColor whiteColor];
    btnB.backgroundColor = [UIColor whiteColor];
    btnC.backgroundColor = [UIColor whiteColor];
    [btnA setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    [btnB setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    [btnC setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    
    NSMutableDictionary *currentQuestion = [arrayQuizToUpdate objectAtIndex:question];
    
    if([currentQuestion objectForKey:@"figureurl"] == nil || [[currentQuestion objectForKey:@"figureurl"]  isEqualToString:@""])
    {
        btnFigure.enabled = NO;
        imgViewfigure.image = [[UIImage alloc]init];
        [btnFigure setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnFigure setBackgroundColor:[UIColor lightGrayColor]];
    }
    else{
        btnFigure.enabled = YES;
        [btnFigure setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btnFigure setBackgroundColor:[UIColor colorWithRed:16.0/255.0f green:114.0/255.0f blue:189.0/255.0f alpha:1.0f]];
        
        [imgViewfigure setImageWithURL:[NSURL URLWithString:[currentQuestion objectForKey:@"figureurl"]]];
        NSURLSession *backgroundSession = [NSURLSession sharedSession];
        backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[currentQuestion objectForKey:@"figureurl"]]];
        NSURLSessionDownloadTask *downloadTask = [backgroundSession downloadTaskWithRequest:request];
        [downloadTask resume];
    }
    
    lblTimeShow.text = [NSString stringWithFormat:@"%lu questions/%lu min",(unsigned long)[arrayQuizToUpdate count],[arrayQuizToUpdate count]*4];
    lblQuestionShow.text = [NSString stringWithFormat:@"Question %ld of %lu",question+1,(unsigned long)[arrayQuizToUpdate count]];
    
    txtViewQuestion.text = [NSString stringWithFormat:@"%@",[currentQuestion objectForKey:@"question"]];
    lblViewA.text = [[currentQuestion objectForKey:@"answerA"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    lblViewB.text = [[currentQuestion objectForKey:@"answerB"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    lblViewC.text = [[currentQuestion objectForKey:@"answerC"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//    [currentQuiz.questions objectAtIndex:question].recodeId = currentQuiz.recordId;

    if (isInstructor) {
        lblExpReference.text = [NSString stringWithFormat:@"Ref.: %@", [currentQuestion objectForKey:@"explanationReference"]];
        lblExpCode.text = [NSString stringWithFormat:@"%@", [currentQuestion objectForKey:@"explanationcode"]];
        lblExpForAnswer.text = [NSString stringWithFormat:@"%@",[currentQuestion objectForKey:@"explanationofcorrectAnswer"]];
    }
    imgA.image = [[UIImage alloc]init];
    imgB.image = [[UIImage alloc]init];
    imgC.image = [[UIImage alloc]init];
    if([[currentQuestion objectForKey:@"gaveAnswer"] isEqualToString:@"A"])
    {
        btnA.backgroundColor = [UIColor colorWithRed:16.0/255 green:114.0/255 blue:189.0/255 alpha:1.0];
        [btnA setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else if([[currentQuestion objectForKey:@"gaveAnswer"]  isEqualToString:@"B"])
    {
        btnB.backgroundColor = [UIColor colorWithRed:16.0/255 green:114.0/255 blue:189.0/255 alpha:1.0];
        [btnB setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else if([[currentQuestion objectForKey:@"gaveAnswer"]  isEqualToString:@"C"])
    {
        btnC.backgroundColor = [UIColor colorWithRed:16.0/255 green:114.0/255 blue:189.0/255 alpha:1.0];
        [btnC setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    
    if([[currentQuestion objectForKey:@"correctAnswer"]  isEqualToString:@"A"])
    {
        imgA.image = [UIImage imageNamed:@"right"];
    }
    else if([[currentQuestion objectForKey:@"correctAnswer"] isEqualToString:@"B"])
    {
        imgB.image = [UIImage imageNamed:@"right"];
    }
    else if([[currentQuestion objectForKey:@"correctAnswer"] isEqualToString:@"C"])
    {
        imgC.image = [UIImage imageNamed:@"right"];
    }
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error
{
    if (error != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorStr = [NSString stringWithFormat:@"Error downloading : %@", [error userInfo]];
            FDLogError(errorStr);
        });
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
//    double currentProgress = totalBytesWritten / (double)totalBytesExpectedToWrite;
//    FDLogDebug(@"written: %lld total_written: %lld expected_to_write: %lld progress: %f", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, currentProgress);
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSData *imgData = [NSData dataWithContentsOfFile:[location path]];
    UIImage *image = [UIImage imageWithData:imgData];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect figureRect = figureDragDropView.frame;
        figureRect.size.width = [UIScreen mainScreen].bounds.size.width - 80;
        figureRect.size.height = image.size.height * figureRect.size.width / image.size.width;
        figureRect.origin.x = ([UIScreen mainScreen].bounds.size.width-figureRect.size.width)/2;
        figureRect.origin.y = ([UIScreen mainScreen].bounds.size.height-figureRect.size.height-50)/2;
        [figureDragDropView setFrame:figureRect];
        figureRect = imgViewfigure.frame;
        figureRect.size.width = figureDragDropView.frame.size.width;
        figureRect.size.height = figureDragDropView.frame.size.height;
        figureRect.origin.x = 0;
        figureRect.origin.y = 0;
        [imgViewfigure setFrame:figureRect];
        
        
        imgViewfigure.autoresizesSubviews = NO;
        imgViewfigure.contentMode = UIViewContentModeRedraw;
        imgViewfigure.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        imgViewfigure.layer.shadowRadius = 3.0f;
        imgViewfigure.layer.shadowOpacity = 1.0f;
        imgViewfigure.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        imgViewfigure.layer.shadowPath = [UIBezierPath bezierPathWithRect:imgViewfigure.bounds].CGPath;
        imgViewfigure.layer.cornerRadius = 5.0f;
    });
}
- (IBAction)onClickFigure:(UIButton *)sender {
    viewexit.hidden = YES;
    viewfigure.hidden = NO;
    viewfinish.hidden = YES;
    // instantaneously make the image view small (scaled to 1% of its actual size)
    imgViewfigure.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        imgViewfigure.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];

}

- (IBAction)onClickOption:(UIButton *)sender {
    if (isInstructor) {
        return;
    }
    btnA.backgroundColor = [UIColor whiteColor];
    btnB.backgroundColor = [UIColor whiteColor];
    btnC.backgroundColor = [UIColor whiteColor];
    [btnA setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    [btnB setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    [btnC setTitleColor:[UIColor colorWithRed:140.0f/255.0f green:140.0f/255.0f blue:140.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor colorWithRed:16.0/255 green:114.0/255 blue:189.0/255 alpha:1.0];
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    NSMutableDictionary *currentQuestion = [arrayQuizToUpdate objectAtIndex:int_count];
    
    switch ((int)sender.tag) {
        case 1:
            [currentQuestion setObject:@"A" forKey:@"gaveAnswer"];
            [arrayQuizToUpdate replaceObjectAtIndex:int_count withObject:currentQuestion];
            break;
        case 2:
            [currentQuestion setObject:@"B" forKey:@"gaveAnswer"];
            [arrayQuizToUpdate replaceObjectAtIndex:int_count withObject:currentQuestion];
            break;
        case 3:
            [currentQuestion setObject:@"C" forKey:@"gaveAnswer"];
            [arrayQuizToUpdate replaceObjectAtIndex:int_count withObject:currentQuestion];
            break;
            
        default:
            break;
    }
    
    [tblViewQuestions reloadData];
    [self reloadCountsForStatusOfQuestions];
}

- (IBAction)onClickExitFinish:(UIButton *)sender {
    if(sender.tag==1)
    {
        
        viewexit.hidden = NO;
        viewfigure.hidden = YES;
        viewfinish.hidden = YES;
        
        // instantaneously make the image view small (scaled to 1% of its actual size)
        exitViewDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // animate it to the identity transform (100% scale)
            exitViewDialog.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            // if you want to do something once the animation finishes, put it here
        }];
        
    }
    else if(sender.tag==2)
    {
        viewexit.hidden = YES;
        viewfigure.hidden = YES;
        viewfinish.hidden = NO;
        
        // instantaneously make the image view small (scaled to 1% of its actual size)
        finishViewDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // animate it to the identity transform (100% scale)
            finishViewDialog.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished){
            // if you want to do something once the animation finishes, put it here
        }];
    }

}

- (IBAction)onClickUnmarkMark:(UIButton *)sender {
    NSMutableDictionary *currentQuestion = [arrayQuizToUpdate objectAtIndex:int_count];
    if(sender.tag==1){
        [currentQuestion setObject:@(0) forKey:@"marked"];
        [arrayQuizToUpdate replaceObjectAtIndex:int_count withObject:currentQuestion];
    }
    else if(sender.tag==2){
        [currentQuestion setObject:@(1) forKey:@"marked"];
        [arrayQuizToUpdate replaceObjectAtIndex:int_count withObject:currentQuestion];
    }
    [tblViewQuestions reloadData];
    [self reloadCountsForStatusOfQuestions];
}

- (IBAction)onClickPrevious:(UIButton *)sender {
    //NSLog(@"Prev===%d",app.int_count);
    [tblViewQuestions reloadData];
    [self reloadCountsForStatusOfQuestions];
    if(int_count-1>=0)
    {
        int_count--;
        [self questionReport:int_count];
        
    }
    else{
        [self showAlert:@"Warning" message:@"No more question remains"];
        
    }
}

- (IBAction)onClickNext:(UIButton *)sender {
    //NSLog(@"Next===%d",app.int_count);
    [tblViewQuestions reloadData];
    [self reloadCountsForStatusOfQuestions];
    if(int_count+1<[arrayQuizToUpdate count])
    {
        int_count++;
        [self questionReport:int_count];
    }
    else{
        [self showAlert:@"Warning" message:@"No more question remains"];
    }
}

- (IBAction)okClickCalculator:(id)sender {
    CalculatorViewController *VC=[[CalculatorViewController alloc] init];
    //VC.view.frame=CGRectMake(0,10, 320, 480);
    
    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:VC];
    popoverController.delegate = self;
    
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (IBAction)onClickYesNo:(UIButton *)sender {
    [AppDelegate sharedDelegate].isTestingScreen = NO;
    viewexit.hidden = YES;
    viewfigure.hidden = YES;
    viewfinish.hidden = YES;
    if(sender.tag==3)
    {
        [self calculationTestingResult];
        SecondViewController *sec = [[SecondViewController alloc]init];
        sec.currentQuiz = currentQuiz;
        [self.navigationController pushViewController:sec animated:YES];
    }else if (sender.tag == 1){
        [self returnOrignalTestingStatus];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)onBackProgramQuiz:(id)sender {
    if (isInstructor) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    viewexit.hidden = NO;
    viewfigure.hidden = YES;
    viewfinish.hidden = YES;
    
    // instantaneously make the image view small (scaled to 1% of its actual size)
    exitViewDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        exitViewDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}
- (void)returnOrignalTestingStatus{
    for (Question *question in currentQuiz.questions) {
        question.marked = @(0);
        question.gaveAnswer = @"";
    }
}
- (void)calculationTestingResult{
    
    for (Question *questionToUpdate in currentQuiz.questions) {
        for (NSDictionary *questionDetails in arrayQuizToUpdate) {
            if ([questionToUpdate.questionId integerValue] == [[questionDetails objectForKey:@"questionId"] integerValue]) {
                questionToUpdate.gaveAnswer = [questionDetails objectForKey:@"gaveAnswer"];
                questionToUpdate.marked = [questionDetails objectForKey:@"marked"];
                break;
            }
        }
    }
    
    NSError *error = nil;
    NSInteger correctCount = 0;
    for (Question *question in currentQuiz.questions) {
        if ([question.correctAnswer isEqualToString:question.gaveAnswer]) {
            correctCount = correctCount + 1;
        }
        question.lastUpdate = @(0);
    }
    CGFloat result = (CGFloat)correctCount / (CGFloat)currentQuiz.questions.count;
    currentQuiz.gotScore = [NSNumber numberWithInteger:result * 100.0];
    
    currentQuiz.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    currentQuiz.lastUpdate = @(0);
    
    if (currentQuiz.quizTaken == nil) {
        currentQuiz.quizTaken = @(0);
    }
    currentQuiz.quizTaken = [NSNumber numberWithInteger:[currentQuiz.quizTaken integerValue] + 1];
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [arrayQuizToUpdate count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *simpleTableIdentifier = @"MainItem";
    MainCell *cell = (MainCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [MainCell sharedCell];
    }
    NSDictionary *questionDetails = [arrayQuizToUpdate objectAtIndex:indexPath.row];
    if([questionDetails objectForKey:@"gaveAnswer"] && ![[questionDetails objectForKey:@"gaveAnswer"] isEqualToString:@""])
    {
        if([[questionDetails objectForKey:@"marked"] boolValue])
        {
            cell.lblColor.backgroundColor = [UIColor blueColor];
        }
        else{
            cell.lblColor.backgroundColor = [UIColor greenColor];
        }
        
    }
    else
    {
        if([[questionDetails objectForKey:@"marked"] boolValue])
        {
            cell.lblColor.backgroundColor = [UIColor yellowColor];
        }
        else{
            cell.lblColor.backgroundColor = [UIColor redColor];
        }
        
    }
    
    //cell.lblQuestion.text = [NSString stringWithFormat:@"Question %ld", [[questionDetails objectForKey:@"ordering"] integerValue]];
    cell.lblQuestion.text = [NSString stringWithFormat:@"Question %ld", indexPath.row + 1];
    if (int_count == indexPath.row) {
        [cell setBackgroundColor:[UIColor colorWithRed:212.0f/255.0f green:229.0f/255.0f blue:248.0f/255.0f alpha:1.0f]];
    }else{
        [cell setBackgroundColor:[UIColor clearColor]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //ChatViewController *chat = [[ChatViewController alloc]init];
    //[self.navigationController pushViewController:chat animated:YES];
    int_count = (int)indexPath.row;
    NSLog(@"Index===%ld",(long)int_count);
    [self questionReport:(int)indexPath.row];
    
    [tblViewQuestions reloadData];
    [self reloadCountsForStatusOfQuestions];
    
}

- (void)reloadCountsForStatusOfQuestions{
    NSInteger unAnsweredCount = 0;
    NSInteger answeredcount = 0;
    NSInteger markedCount = 0;
    NSInteger markedAndAnsweredCount = 0;
    for (NSMutableDictionary *questionDetails in arrayQuizToUpdate) {
        if([questionDetails objectForKey:@"gaveAnswer"] && ![[questionDetails objectForKey:@"gaveAnswer"] isEqualToString:@""])
        {
            if([[questionDetails objectForKey:@"marked"] boolValue])
            {
                markedAndAnsweredCount = markedAndAnsweredCount + 1;
            }
            else{
                answeredcount = answeredcount + 1;
            }
            
        }
        else
        {
            if([[questionDetails objectForKey:@"marked"] boolValue])
            {
                markedCount = markedCount + 1;
            }
            else{
                unAnsweredCount = unAnsweredCount + 1;
            }
            
        }
    }
    lblUnansweredCount.text = [NSString stringWithFormat:@"%ld", (long)unAnsweredCount];
    lblAnswerdCount.text = [NSString stringWithFormat:@"%ld", (long)answeredcount];
    lblMarkedCount.text = [NSString stringWithFormat:@"%ld", (long)markedCount];
    lblMarkedAnsweredCount.text = [NSString stringWithFormat:@"%ld", (long)markedAndAnsweredCount];
}
#pragma mark - UIViewDragDropDelegate

- (void) view:(UIView *)view wasDroppedOnDropView:(UIView *)drop
{
    
}

- (BOOL) viewShouldReturnToStartingPosition:(UIView*)view
{
    
    return NO;
}

- (void) draggingDidBeginForView:(UIView*)view
{
    
}

- (void) draggingDidEndWithoutDropForView:(UIView*)view
{
    
}

- (void) view:(UIView *)view didHoverOverDropView:(UIView *)dropView
{
    
}

- (void) view:(UIView *)view didUnhoverOverDropView:(UIView *)dropView
{
    
}
@end
