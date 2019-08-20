//
//  SecondViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 5/28/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "SecondViewController.h"
#import "SecondCell.h"
#import "FirstViewController.h"
#import "QuizesViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIView_DragDrop/UIView+DragDrop.h>

@interface SecondViewController ()<UITableViewDelegate, UITableViewDataSource, UIViewDragDropDelegate, NSURLSessionDownloadDelegate>{
    int int_count;
}

@end

@implementation SecondViewController
@synthesize currentQuiz, quizDes;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.navigationItem setHidesBackButton:YES animated:YES];
    self.navigationItem.title = [NSString stringWithFormat:@"Quiz %ld", [currentQuiz.quizNumber integerValue]];
    int_count = 0;
    [self questionReport_second:int_count];
    
    
    txtViewQuestion.layer.borderWidth = 2.0;
    txtViewQuestion.layer.borderColor = [UIColor colorWithRed:96.0/255 green:73.0/255 blue:59.0/255 alpha:1.0].CGColor;
    
    txtViewAnswer.layer.borderWidth = 1.0;
    txtViewAnswer.layer.borderColor = [UIColor colorWithRed:96.0/255 green:73.0/255 blue:59.0/255 alpha:1.0].CGColor;
    
    if ([currentQuiz.gotScore integerValue] < 70) {
        [lblScore setTextColor:[UIColor redColor]];
    }else if ([currentQuiz.gotScore integerValue] < 80) {
        [lblScore setTextColor:[UIColor colorWithRed:1.0f green:183.0f/255.0f blue:50.0f/255.0f alpha:1.0f]];
    }else if ([currentQuiz.gotScore integerValue] < 90) {
        [lblScore setTextColor:[UIColor blueColor]];
    }else if ([currentQuiz.gotScore integerValue] <= 100) {
        [lblScore setTextColor:[UIColor colorWithRed:0.0f green:180.0f/255.0f blue:0.0f alpha:1.0f]];
    }
    
    lblScore.text = [NSString stringWithFormat:@"%@", currentQuiz.gotScore];
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        btnRetake.hidden = YES;
    }else{
        btnRetake.hidden = NO;
    }
    
    figureImageView.layer.shadowRadius = 3.0f;
    figureImageView.layer.shadowOpacity = 1.0f;
    figureImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    figureImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:figureImageView.bounds].CGPath;
    figureImageView.layer.cornerRadius = 5.0f;
    
    figureView.hidden = YES;
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleSingleTap:)];
    [figureView addGestureRecognizer:singleFingerTap];
    
    lblQuizDes.text = quizDes;
    
    //make a view draggable
    [figureDragDropView makeDraggable];
    [figureDragDropView setDelegate:self];
    UIPinchGestureRecognizer *twoFingerPinch = [[UIPinchGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(twoFingerPinch:)];
    [figureDragDropView addGestureRecognizer:twoFingerPinch];
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
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
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
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar addSubview:navView];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"SecondViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
}

#pragma mark UIScrollViewDelegate
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
    return figureImageView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)questionReport_second :(int)question
{
    
    btnA.backgroundColor = [UIColor colorWithRed:252.0/255 green:251.0/255 blue:252.0/255 alpha:1.0];
    btnB.backgroundColor = [UIColor colorWithRed:252.0/255 green:251.0/255 blue:252.0/255 alpha:1.0];
    btnC.backgroundColor = [UIColor colorWithRed:252.0/255 green:251.0/255 blue:252.0/255 alpha:1.0];
    
    lbQuestionShow.text = [NSString stringWithFormat:@"Question %d of %lu",question+1,(unsigned long)[currentQuiz.questions count]];
    txtViewAnswer.text = [NSString stringWithFormat:@"%@",[currentQuiz.questions objectAtIndex:question].explanationofcorrectAnswer];
    txtViewQuestion.text = [NSString stringWithFormat:@"%@",[currentQuiz.questions objectAtIndex:question].question];
    lblExplanationReference.text = [NSString stringWithFormat:@"Ref.: %@", [currentQuiz.questions objectAtIndex:question].explanationReference];
    lblExplanationCode.text = [NSString stringWithFormat:@"%@", [currentQuiz.questions objectAtIndex:question].explanationcode];
    
    lblViewA.text = [[currentQuiz.questions objectAtIndex:question].answerA stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    lblViewB.text = [[currentQuiz.questions objectAtIndex:question].answerB stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    lblViewC.text = [[currentQuiz.questions objectAtIndex:question].answerC stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    if([currentQuiz.questions objectAtIndex:question].figureurl == nil || [[currentQuiz.questions objectAtIndex:question].figureurl isEqualToString:@""])
    {
        btnFigure.enabled = NO;
        [btnFigure setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btnFigure setBackgroundColor:[UIColor lightGrayColor]];
    }
    else{
        btnFigure.enabled = YES;
        [btnFigure setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btnFigure setBackgroundColor:[UIColor colorWithRed:16.0/255.0f green:114.0/255.0f blue:189.0/255.0f alpha:1.0f]];
        
        [figureImageView setImageWithURL:[NSURL URLWithString:[currentQuiz.questions objectAtIndex:question].figureurl]];
        NSURLSession *backgroundSession = [NSURLSession sharedSession];
        backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[currentQuiz.questions objectAtIndex:question].figureurl]];
        NSURLSessionDownloadTask *downloadTask = [backgroundSession downloadTaskWithRequest:request];
        [downloadTask resume];
    }
    imageA.image = [[UIImage alloc]init];
    imageB.image = [[UIImage alloc]init];
    imageC.image = [[UIImage alloc]init];
    Question *questionaaa = [currentQuiz.questions objectAtIndex:question];
    if([[currentQuiz.questions objectAtIndex:question].gaveAnswer isEqualToString:@"A"])
    {
        if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"A"])
            imageA.image = [UIImage imageNamed:@"right"];
        else{
            imageA.image = [UIImage imageNamed:@"wrong"];
        }
        btnA.backgroundColor = [UIColor colorWithRed:121.0/255 green:182.0/255 blue:237.0/255 alpha:1.0];
        
    }
    else if([[currentQuiz.questions objectAtIndex:question].gaveAnswer isEqualToString:@"B"])
    {
        if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"B"])
            imageB.image = [UIImage imageNamed:@"right"];
        else{
            imageB.image = [UIImage imageNamed:@"wrong"];
        }
        btnB.backgroundColor = [UIColor colorWithRed:121.0/255 green:182.0/255 blue:237.0/255 alpha:1.0];
        
    }
    else if([[currentQuiz.questions objectAtIndex:question].gaveAnswer isEqualToString:@"C"])
    {
        if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"C"])
            imageC.image = [UIImage imageNamed:@"right"];
        else{
            imageC.image = [UIImage imageNamed:@"wrong"];
        }
        btnC.backgroundColor = [UIColor colorWithRed:121.0/255 green:182.0/255 blue:237.0/255 alpha:1.0];
    }
    if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"A"])
    {
        imageA.image = [UIImage imageNamed:@"right"];
    }
    else if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"B"])
    {
        imageB.image = [UIImage imageNamed:@"right"];
    }
    else if([[currentQuiz.questions objectAtIndex:question].correctAnswer isEqualToString:@"C"])
    {
        imageC.image = [UIImage imageNamed:@"right"];
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
        figureRect = figureImageView.frame;
        figureRect.size.width = figureDragDropView.frame.size.width;
        figureRect.size.height = figureDragDropView.frame.size.height;
        figureRect.origin.x = 0;
        figureRect.origin.y = 0;
        [figureImageView setFrame:figureRect];
        
        
        figureImageView.autoresizesSubviews = NO;
        figureImageView.contentMode = UIViewContentModeRedraw;
        figureImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        figureImageView.layer.shadowRadius = 3.0f;
        figureImageView.layer.shadowOpacity = 1.0f;
        figureImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        figureImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:figureImageView.bounds].CGPath;
        figureImageView.layer.cornerRadius = 5.0f;
    });
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [currentQuiz.questions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SecondItem";
    SecondCell *cell = (SecondCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [SecondCell sharedCell];
    }
    Question *currentQuestion = [currentQuiz.questions objectAtIndex:indexPath.row];
    
    if([[currentQuiz.questions objectAtIndex:indexPath.row].correctAnswer isEqualToString:[currentQuiz.questions objectAtIndex:indexPath.row].gaveAnswer])
    {
        cell.imageviewAnswer.image = [UIImage imageNamed:@"right"];
    }
    else{
        cell.imageviewAnswer.image = [UIImage imageNamed:@"wrong"];
    }
    cell.lblNo.text = [NSString stringWithFormat:@"Question %ld",indexPath.row+1];
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
    [self questionReport_second:(int)indexPath.row];
    
    [tblView_answer reloadData];
}

- (IBAction)onClickPrevious:(id)sender {
    // NSLog(@"Prev===%d",app.int_count);
    [tblView_answer reloadData];
    if(int_count-1>=0)
    {
        int_count--;
        btnPrevious.enabled = YES;
        [self questionReport_second:int_count];
        
    }
    else{
        [self showAlert:@"No more question remains" :@"Warning"];
        //btnPrevious.enabled = NO;
        
    }
}
-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        //NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)onclickNext:(id)sender {
    //NSLog(@"Next===%d",app.int_count);
    [tblView_answer reloadData];
    if(int_count+1<[currentQuiz.questions count])
    {
        int_count++;
        btnNext.enabled = YES;
        [self questionReport_second:int_count];
        
    }
    else{
        //btnNext.enabled = NO;
        [self showAlert:@"No more question remains" :@"Warning"];
    }
}

- (IBAction)onBackBtn:(id)sender {
    NSArray *viewControllers = [[self navigationController] viewControllers];
    for( int i=0;i<[viewControllers count];i++){
        id obj=[viewControllers objectAtIndex:i];
        if([obj isKindOfClass:[QuizesViewController class]]){
            [[self navigationController] popToViewController:obj animated:YES];
            return;
        }
    }
}

- (IBAction)onRetakeBtn:(id)sender {
    for (Question *question in currentQuiz.questions) {
        question.gaveAnswer = @"";
        question.marked = @(0);
    }
    currentQuiz.gotScore = nil;
    FirstViewController *quizViewController = [[FirstViewController alloc] init];
    quizViewController.currentQuiz = currentQuiz;
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController pushViewController:quizViewController animated:YES];
}

- (IBAction)onFigure:(id)sender {
    figureView.hidden = NO;
    // instantaneously make the image view small (scaled to 1% of its actual size)
    figureImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // animate it to the identity transform (100% scale)
        figureImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        // if you want to do something once the animation finishes, put it here
    }];
}
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    // CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    figureView.hidden = YES;
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
    figureDragDropView.transform = transform;
    //Do stuff here...
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
