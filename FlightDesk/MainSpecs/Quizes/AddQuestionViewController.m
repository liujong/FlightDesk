//
//  AddQuestionViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/5/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddQuestionViewController.h"
#import "PersistentCoreDataStack.h"
#import "Quiz+CoreDataClass.h"
#import "Question+CoreDataClass.h"
#import "UIImage+Resize.h"
#import "Question+CoreDataClass.h"
#import "Quiz+CoreDataClass.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "PhotoTweaksViewController.h"

@interface AddQuestionViewController ()<UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate, PhotoTweaksViewControllerDelegate>
{
    NSString *rightAnswer;
    NSString *currentFigureImageUrl;
}

@end

@implementation AddQuestionViewController
@synthesize currentIndex;
@synthesize selectedQuestionInfo;
@synthesize selectedQuestion;
@synthesize currentQuizId;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    AddQuestionDialogView.autoresizesSubviews = NO;
    AddQuestionDialogView.contentMode = UIViewContentModeRedraw;
    AddQuestionDialogView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    AddQuestionDialogView.layer.shadowRadius = 3.0f;
    AddQuestionDialogView.layer.shadowOpacity = 1.0f;
    AddQuestionDialogView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    AddQuestionDialogView.layer.shadowPath = [UIBezierPath bezierPathWithRect:AddQuestionDialogView.bounds].CGPath;
    AddQuestionDialogView.layer.cornerRadius = 5.0f;
    
    rightAnswer = @"";
    currentFigureImageUrl = @"";
    
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
    [titleBarImageView setImage:gradientImage];
    
    figureImageView.layer.masksToBounds = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)animateHide{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             AddQuestionViewPositionCons.constant += -300.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}
- (void)animateShow{
    
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             AddQuestionViewPositionCons.constant += -300.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             if (selectedQuestionInfo) {
                 txtQuestion.text = [selectedQuestionInfo objectForKey:@"question"];
                 txtAnswerA.text = [selectedQuestionInfo objectForKey:@"answerA"];
                 txtAnswerB.text = [selectedQuestionInfo objectForKey:@"answerB"];
                 txtAnswerC.text = [selectedQuestionInfo objectForKey:@"answerC"];
                 txtExpRef.text = [selectedQuestionInfo objectForKey:@"explanationReference"];
                 txtExpCode.text = [selectedQuestionInfo objectForKey:@"explanationCode"];
                 txtViewExpOfCorrectAnswer.text = [selectedQuestionInfo objectForKey:@"explanationOfCorrectAnswer"];
                 if ([[selectedQuestionInfo objectForKey:@"markcorrectAnswer"] isEqualToString:@"A"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn1];
                 }else if ([[selectedQuestionInfo objectForKey:@"markcorrectAnswer"] isEqualToString:@"B"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn2];
                 }else if ([[selectedQuestionInfo objectForKey:@"markcorrectAnswer"] isEqualToString:@"C"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn3];
                 }
                 [figureImageView setImageWithURL:[NSURL URLWithString:[selectedQuestionInfo objectForKey:@"figure_url"]]];
             }else if (selectedQuestion){
                 txtQuestion.text = selectedQuestion.question;
                 txtAnswerA.text = selectedQuestion.answerA;
                 txtAnswerB.text = selectedQuestion.answerB;
                 txtAnswerC.text = selectedQuestion.answerC;
                 txtExpRef.text = selectedQuestion.explanationReference;
                 txtExpCode.text = selectedQuestion.explanationcode;
                 txtViewExpOfCorrectAnswer.text = selectedQuestion.explanationofcorrectAnswer;
                 [figureImageView setImageWithURL:[NSURL URLWithString:selectedQuestion.figureurl]];
                 if ([selectedQuestion.correctAnswer isEqualToString:@"A"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn1];
                 }else if ([selectedQuestion.correctAnswer isEqualToString:@"B"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn2];
                 }else if ([selectedQuestion.correctAnswer isEqualToString:@"C"]) {
                     [self onMarkCorrectAnswer:correctAnsBtn3];
                 }
                 currentFigureImageUrl = selectedQuestion.figureurl;
             }
             self.view.userInteractionEnabled = YES;
             [txtQuestion becomeFirstResponder];
         }
        ];
    }
}

- (IBAction)onMarkCorrectAnswer:(UIButton *)sender {
    [correctAnsBtn1 setImage:nil forState:UIControlStateNormal];
    [correctAnsBtn2 setImage:nil forState:UIControlStateNormal];
    [correctAnsBtn3 setImage:nil forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:@"right.png"] forState:UIControlStateNormal];
    if (sender.tag == 101) {
        rightAnswer = @"A";
    }else if (sender.tag == 102) {
        rightAnswer = @"B";
    }else if (sender.tag == 103) {
        rightAnswer = @"C";
    }
}
- (IBAction)onAddFigure:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionTakeProfilePhoto = [UIAlertAction actionWithTitle:@"Take Figure Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }];
    UIAlertAction* actionChooseFromLib = [UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionTakeProfilePhoto];
    [alert addAction:actionChooseFromLib];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = btnAddFigure;
    popPresenter.sourceRect = btnAddFigure.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSURL *imagePath = [info objectForKey:UIImagePickerControllerReferenceURL];
    NSString *imageName = [imagePath lastPathComponent];
    
    [btnAddFigure setTitle:[NSString stringWithFormat:@"%@", imageName] forState:UIControlStateNormal];
    if (![UIImageJPEGRepresentation(image, 0.5f) writeToFile:[NSTemporaryDirectory() stringByAppendingString:@"/image.jpg"] atomically:YES]) {
        [self showAlert:@"Failed to save information. Please try again." title:@"Error"];
        return;
    }
    
    PhotoTweaksViewController *photoTweaksViewController = [[PhotoTweaksViewController alloc] initWithImage:image];
    photoTweaksViewController.delegate = self;
    photoTweaksViewController.autoSaveToLibray = NO;
    photoTweaksViewController.maxRotationAngle = M_PI_2;
    [picker pushViewController:photoTweaksViewController animated:YES];
    
}
#pragma mark PhotoTweaksViewController
- (void)photoTweaksController:(PhotoTweaksViewController *)controller didFinishWithCroppedImage:(UIImage *)croppedImage
{
    [self uploadPhoto:croppedImage];
    [controller dismissViewControllerAnimated:YES completion:nil];
    // cropped image
}
- (void)photoTweaksControllerDidCancel:(PhotoTweaksViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
- (void)uploadPhoto:(UIImage *)img{
    NSData *imageData = UIImageJPEGRepresentation(img,0.2);     //change Image to NSData
    
    if (imageData != nil)
    {
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_figureimage.php", serverName, webAppDir];
        
        NSURL *saveURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[AppDelegate sharedDelegate].userId dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        NSDate *currentime = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
        NSString *imagefileName = [dateformatter stringFromDate:currentime];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"flightdesk_%@.jpg\"\r\n", imagefileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:imageData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];
        // now lets make the connection to the web
        NSURLSession *session = [NSURLSession sharedSession];
        session = [NSURLSession sessionWithConfiguration:session.configuration delegate:nil delegateQueue:nil];
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            if (data != nil) {
                NSError *error;
                // parse the query results
                NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error != nil) {
                    NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                    return;
                }
                if ([[queryResults objectForKey:@"success"] boolValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CGFloat scale = figureImageView.frame.size.width / img.size.width;
                        CGRect imageRect = figureImageView.frame;
                        imageRect.size.width = img.size.width * imageRect.size.height / img.size.height;
                        [figureImageView setFrame:imageRect];
                        [figureImageView setImage:img];
                        currentFigureImageUrl = [queryResults objectForKey:@"imageurl"];
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Please try again" title:@"Failed!"] ;
                    });
                }
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading queries";
                }
                FDLogError(@"%@", errorText);
            }
        }];
        [uploadQuizRecordsTask resume];
    }
    
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}
- (IBAction)onDone:(id)sender {
    if (!txtQuestion.text.length)
    {
        [self showAlert:@"Please input Question" title:@"Input Error"];
        return;
    }
    if (!txtAnswerA.text.length)
    {
        [self showAlert:@"Please input First Answer" title:@"Input Error"];
        return;
    }
    if (!txtAnswerB.text.length)
    {
        [self showAlert:@"Please input second Answer" title:@"Input Error"];
        return;
    }
    if (!txtAnswerC.text.length)
    {
        [self showAlert:@"Please input third Answer" title:@"Input Error"];
        return;
    }
    if (!txtExpRef.text.length)
    {
        [self showAlert:@"Please input Explanation Reference" title:@"Input Error"];
        return;
    }
    if (!txtExpCode.text.length)
    {
        [self showAlert:@"Please input Explanation code" title:@"Input Error"];
        return;
    }
    if (!txtViewExpOfCorrectAnswer.text.length)
    {
        [self showAlert:@"Please input Explanation of correct Answer" title:@"Input Error"];
        return;
    }
    
    if ([rightAnswer isEqualToString:@""]) {
        [self showAlert:@"Please mark correct answer" title:@"Input Error"];
        return;
    }
    
//    if ([currentFigureImageUrl isEqualToString:@""]) {
//        [self showAlert:@"Please select Figure image" title:@"Input Error"];
//        return;
//    }
    if(selectedQuestion){
        selectedQuestion.question = txtQuestion.text;
        selectedQuestion.answerA = txtAnswerA.text;
        selectedQuestion.answerB = txtAnswerB.text;
        selectedQuestion.answerC = txtAnswerC.text;
        selectedQuestion.explanationofcorrectAnswer = txtViewExpOfCorrectAnswer.text;
        selectedQuestion.explanationcode = txtExpCode.text;
        selectedQuestion.explanationReference = txtExpRef.text;
        selectedQuestion.figureurl = currentFigureImageUrl;
        selectedQuestion.correctAnswer = rightAnswer;
        if (self.view.hidden == NO) // Visible
        {
            self.view.userInteractionEnabled = NO;
            
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                             animations:^(void)
             {
                 self.view.alpha = 0.0f; // Fade out
                 AddQuestionViewPositionCons.constant += -300.0f;
                 [self.view layoutIfNeeded];
             }
                             completion:^(BOOL finished)
             {
                 self.view.hidden = YES;
                 [self.delegate didDoneAddQuestionView:self question:selectedQuestion];
             }
             ];
        }
    }else {
        NSMutableDictionary *queryInfo = [[NSMutableDictionary alloc] init];
        if (selectedQuestionInfo) {
            [queryInfo setObject:[selectedQuestionInfo objectForKey:@"id"] forKey:@"id"];
        }else{
            [queryInfo setObject:@(currentIndex) forKey:@"id"];
        }
        [queryInfo setObject:txtQuestion.text forKey:@"question"];
        [queryInfo setObject:txtAnswerA.text forKey:@"answerA"];
        [queryInfo setObject:txtAnswerB.text forKey:@"answerB"];
        [queryInfo setObject:txtAnswerC.text forKey:@"answerC"];
        [queryInfo setObject:txtExpRef.text forKey:@"explanationReference"];
        [queryInfo setObject:txtExpCode.text forKey:@"explanationCode"];
        [queryInfo setObject:txtViewExpOfCorrectAnswer.text forKey:@"explanationOfCorrectAnswer"];
        [queryInfo setObject:rightAnswer forKey:@"markcorrectAnswer"];
        [queryInfo setObject:currentFigureImageUrl forKey:@"figure_url"];
        NSInteger timeStap = [[NSDate date] timeIntervalSince1970];
        [queryInfo setObject:@(timeStap) forKey:@"sessionId"];
        
        if (self.view.hidden == NO) // Visible
        {
            self.view.userInteractionEnabled = NO;
            
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                             animations:^(void)
             {
                 self.view.alpha = 0.0f; // Fade out
                 AddQuestionViewPositionCons.constant += -300.0f;
                 [self.view layoutIfNeeded];
             }
                             completion:^(BOOL finished)
             {
                 self.view.hidden = YES;
                 [self.delegate didDoneAddQuestionView:self questionInfo:queryInfo];
             }
             ];
        }
    }
    
}
- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             AddQuestionViewPositionCons.constant += -300.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelAddQuestionView:self];
         }
         ];
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtQuestion) {
        [txtAnswerA becomeFirstResponder];
    }else if (textField == txtAnswerA){
        [txtAnswerB becomeFirstResponder];
    }else if (textField == txtAnswerB){
        [txtAnswerC becomeFirstResponder];
    }else if (textField == txtAnswerC){
        [txtExpRef becomeFirstResponder];
    }else if (textField == txtExpRef){
        [txtExpCode becomeFirstResponder];
    }else if (textField == txtExpCode){
        [txtViewExpOfCorrectAnswer becomeFirstResponder];
    }
    return YES;
}
@end
