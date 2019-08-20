//
//  DocumentsViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "DocumentsViewController.h"
#import "DocumentsView.h"
#import "CoursePickerViewController.h"
#import "ReaderDocument.h"
#import <FastPdfKit/FastPdfKit.h>
#import "PDFReaderViewController.h"
#import "AddDocumentsViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface DocumentsViewController () <DocumentsViewDelegate, CoursePickerDelegate, AddDocumentsViewControllerDelegate, NSURLSessionTaskDelegate>

@end

@implementation DocumentsViewController
{
    DocumentsView *documentsView;
    CoursePickerViewController *coursePickerController;
    UIPopoverController *coursePickerPopover;
    UIBarButtonItem *updateButton;
    UIBarButtonItem *addButtonItem;
    UIButton *addBtn;
    UIBarButtonItem *selectButtonItem;
    UIButton *selectBtn;
    UIBarButtonItem *foldersButton;
    BOOL isSelectedToDelete;
    
    UIButton *updateBaseButton;
    
    NSString *currentSelectedCourseName;
    
    
    UIView *progressContainView;
    UIProgressView *progressToUploadFile;
    
    //red badge
    UIView *redBadgeView;
    UILabel *redBadgeLbl;
    
    UIView *vwCoverOfWebView;
    UIWebView *webView;
    
    UIView *ivCoverView;
    UIImageView *imageViewOfDoc;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    isSelectedToDelete = NO;
    
    updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(doUpdateButtonTapped:)];
    
    
    UIImage *updateImage = [[UIImage imageNamed:@"inbox_able"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGRect updateImageFrame = CGRectMake(5, 5, updateImage.size.width, updateImage.size.height);
    updateBaseButton = [[UIButton alloc] initWithFrame:updateImageFrame];
    [updateBaseButton setImage:updateImage forState:UIControlStateNormal];
    [updateBaseButton addTarget:self action:@selector(updateButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [updateBaseButton setShowsTouchWhenHighlighted:YES];
    updateBaseButton.tintColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    UIView *containsViewOfUpload = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [containsViewOfUpload addSubview:updateBaseButton];
    
    //red badge
    redBadgeView = [[UIView alloc] initWithFrame:CGRectMake(30, 0, 20, 20)];
    redBadgeView.backgroundColor = [UIColor redColor];
    redBadgeView.layer.cornerRadius = redBadgeView.frame.size.height / 2.0f;
    redBadgeView.layer.masksToBounds = YES;
    redBadgeView.layer.borderWidth = 0.0f;
    
    redBadgeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    redBadgeLbl.textColor = [UIColor whiteColor];
    redBadgeLbl.textAlignment = NSTextAlignmentCenter;
    redBadgeLbl.font = [UIFont systemFontOfSize:13.0f];
    redBadgeLbl.backgroundColor = [UIColor clearColor];
    [redBadgeView addSubview:redBadgeLbl];
    [containsViewOfUpload addSubview:redBadgeView];
    
    updateButton =[[UIBarButtonItem alloc] initWithCustomView:containsViewOfUpload];
    //updateButton.enabled = YES;
    
    addBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 0, 40, 40)];
    [addBtn addTarget:self action:@selector(addDocumentsByInstructor) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
    [addBtn setTitleColor:[UIColor colorWithRed:0.0f/255.0f green:125.0f/255.0 blue:255.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    addBtn.hidden = YES;
    
    UIView *containsViewOfAdd = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [containsViewOfAdd addSubview:addBtn];
    addButtonItem = [[UIBarButtonItem alloc] initWithCustomView:containsViewOfAdd];
    
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:updateButton];
    [rightBarButtonItems addObject:addButtonItem];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    
    foldersButton = [[UIBarButtonItem alloc] initWithTitle:@"Programs" style:UIBarButtonItemStylePlain target:self action:@selector(chooseCourseButtonTapped:)];
    foldersButton.enabled = YES;
    foldersButton.tintColor = [UIColor whiteColor];
    
    selectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 70, 40)];
    [selectBtn addTarget:self action:@selector(selectDocumentsToDelete) forControlEvents:UIControlEventTouchUpInside];
    [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
    [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    selectButtonItem = [[UIBarButtonItem alloc] initWithCustomView:selectBtn];
    
    NSMutableArray *leftBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.leftBarButtonItems];
    [leftBarButtonItems addObject:foldersButton];
    [leftBarButtonItems addObject:selectButtonItem];
    self.navigationItem.leftBarButtonItems = [[NSArray alloc] initWithArray:leftBarButtonItems];
    
    CGRect documentRect = self.view.bounds;
    documentRect.size.height = documentRect.size.height - 50.0f;
    documentsView = [[DocumentsView alloc] initWithFrame:documentRect];
    // TODO: save last folder!!!
    
    documentsView.delegate = self;
    //[self reSetBadge];
    
    [documentsView populateDocumentsWithGroupName:@"My Docs"];
    self.navigationItem.title = @"My Docs";
    [self.view addSubview:documentsView];
    
    currentSelectedCourseName =@"My Docs";
    
    CGRect screenRect = self.view.bounds;
    progressContainView = [[UIView alloc] initWithFrame:screenRect];
    progressContainView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3f];
    progressToUploadFile = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progressToUploadFile setFrame:CGRectMake(200, screenRect.size.height/2, screenRect.size.width-400, 11)];
    [progressContainView addSubview:progressToUploadFile];
    UILabel *lblUploading = [[UILabel alloc] initWithFrame:CGRectMake(200, screenRect.size.height/2-40, screenRect.size.width-400, 30)];
    lblUploading.text = @"Uploading...";
    lblUploading.textColor = [UIColor colorWithRed:0.0f/255.0f green:125.0f/255.0 blue:255.0f/255.0f alpha:1.0f];
    [progressContainView addSubview:lblUploading];
    
    //show selected files
    vwCoverOfWebView = [[UIView alloc] initWithFrame:[AppDelegate sharedDelegate].window.frame];
    vwCoverOfWebView.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    CGRect frameOfWebView = vwCoverOfWebView.frame;
    frameOfWebView.origin.x = frameOfWebView.origin.x + 40.0f;
    frameOfWebView.origin.y = frameOfWebView.origin.y + 64.0f;
    frameOfWebView.size.height = frameOfWebView.size.height - 128.0f;
    frameOfWebView.size.width = frameOfWebView.size.width - 80.0f;
    webView = [[UIWebView alloc] initWithFrame:frameOfWebView];
    webView.layer.shadowRadius = 3.0f;
    webView.layer.shadowOpacity = 1.0f;
    webView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    webView.layer.shadowPath = [UIBezierPath bezierPathWithRect:webView.bounds].CGPath;
    webView.layer.cornerRadius = 5.0f;
    webView.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    [webView  setScalesPageToFit:YES];
    [vwCoverOfWebView addSubview:webView];
    UITapGestureRecognizer *tapGestureToWebView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverOfWebView)];
    [vwCoverOfWebView addGestureRecognizer:tapGestureToWebView];
    
    ivCoverView = [[UIView alloc] initWithFrame:[AppDelegate sharedDelegate].window.frame];
    ivCoverView.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    frameOfWebView = ivCoverView.frame;
    frameOfWebView.origin.x = frameOfWebView.origin.x + 40.0f;
    frameOfWebView.origin.y = frameOfWebView.origin.y + 64.0f;
    frameOfWebView.size.height = frameOfWebView.size.height - 128.0f;
    frameOfWebView.size.width = frameOfWebView.size.width - 80.0f;
    imageViewOfDoc = [[UIImageView alloc] initWithFrame:frameOfWebView];
    imageViewOfDoc.layer.shadowRadius = 3.0f;
    imageViewOfDoc.layer.shadowOpacity = 1.0f;
    imageViewOfDoc.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    imageViewOfDoc.layer.shadowPath = [UIBezierPath bezierPathWithRect:webView.bounds].CGPath;
    imageViewOfDoc.layer.cornerRadius = 5.0f;
    imageViewOfDoc.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    [ivCoverView addSubview:imageViewOfDoc];
    UITapGestureRecognizer *tapGestureToImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideCoverOfImageView)];
    [ivCoverView addGestureRecognizer:tapGestureToImageView];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [self setNavigationColorWithGradiant];
    [self reSetBadge];
    
    [[AppDelegate sharedDelegate] startThreadToSyncData:3];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"DocumentsViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
//
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:3];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    CGRect documentRect = self.view.bounds;
    documentRect.size.height = documentRect.size.height - 50.0f;
    [documentsView setFrame:documentRect];
    [self setNavigationColorWithGradiant];
    [self superClassDeviceOrientationDidChange];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [documentsView hiddenKeyboard];
}
- (void)setNavigationColorWithGradiant{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:145.0f/255.0f blue:0 alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:250.0f/255.0f green:83.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//Uploading file to server
- (void)uploadFileToRedirect:(NSURL *)pdfUrl withRedirectPad:(BOOL)isRedirect{
    
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_pdf.php", serverName, webAppDir];
    NSURL *saveURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveRequest = [NSMutableURLRequest requestWithURL:saveURL];
    [saveRequest setHTTPMethod:@"POST"];
    
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Get all the files at ~/Documents/user
    NSError *error;
    NSString *pdfName = [pdfUrl lastPathComponent];
    NSString *pdfNameToUpload = [NSString stringWithFormat:@"pdf_%d.pdf", (int)[[NSDate date] timeIntervalSince1970] * 1000000];
//    NSString *toPath = [documentDirectory stringByAppendingPathComponent:pdfName];
//    NSURL *toUrl = [NSURL URLWithString:[toPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    [fm moveItemAtURL:pdfUrl toURL:toUrl error:&error];
    NSString *fromPdfPath =[pdfUrl path];
    NSString *toPdfPath = [documentDirectory stringByAppendingPathComponent:pdfNameToUpload];
    //if (!isRedirect) {
        [fm copyItemAtPath:fromPdfPath toPath:toPdfPath error:&error];
    //}
    if (error == nil || isRedirect) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:progressContainView];
            [progressToUploadFile setProgress:0.0 animated:YES];
        });
        NSString *finalPath=[documentDirectory stringByAppendingPathComponent:[pdfName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSData *datapdf = [NSData dataWithContentsOfFile:toPdfPath];
        
        //parsing pdf file on local cache.
        //ReaderDocument *readerDocument = [ReaderDocument withDocumentFilePath:finalPath password:nil];
        
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [saveRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
        NSMutableData *postbody = [NSMutableData data];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", pdfNameToUpload ] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[@"Content-Type: application/pdf\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:datapdf]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [saveRequest setHTTPBody:postbody];
        
        NSURLSession *session = [NSURLSession sharedSession];
        session = [NSURLSession sessionWithConfiguration:session.configuration delegate:self delegateQueue:nil];
        NSURLSessionDataTask *uploadQuizRecordsTask = [session dataTaskWithRequest:saveRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            dispatch_async(dispatch_get_main_queue(), ^{
                [progressContainView removeFromSuperview];
                [progressToUploadFile setProgress:0.0f animated:YES];
            });
            if (data != nil) {
                NSError *error;
                NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if ([[results objectForKey:@"success"] boolValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self uploadNewPdfToserver:[results objectForKey:@"pdfurl"] withFileName:pdfName withFilePath:toPdfPath];
                    });
                }else{
                    [fm removeItemAtPath:[documentDirectory stringByAppendingPathComponent:pdfName] error:&error];
                    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:[NSString stringWithFormat:@"%@ Uploading failed.", pdfName] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                        NSLog(@"you pressed Yes, please button");
                    }];
                    [alert addAction:yesButton];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            } else {
                NSError *error;
                [fm removeItemAtPath:[documentDirectory stringByAppendingPathComponent:pdfName] error:&error];
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while logout";
                }
                FDLogError(@"%@", errorText);
                UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:[responseError localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    NSLog(@"you pressed Yes, please button");
                }];
                [alert addAction:yesButton];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
        [uploadQuizRecordsTask resume];
    }else{
        
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:[error localizedDescription]  preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSLog(@"you pressed Yes, please button");
        }];
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)uploadNewPdfToserver:(NSString *)remoteUrl  withFileName:(NSString *)pdfName withFilePath:(NSString *)finalPath{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"upload_own_pdf", @"action", [AppDelegate sharedDelegate].userId, @"user_id", remoteUrl, @"pdf_url", pdfName, @"pdf_name", nil];
    NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)lessonRecordsJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadLessonRecordsTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
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
                
                NSNumber *pdfID = [queryResults objectForKey:@"document_id"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [ReaderDocument withDocumentFilePath:finalPath password:nil];
                    
                    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                    NSError *error;
                    Document *document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:context];
                    document.documentID = pdfID;
                    document.downloaded = @(1);
                    document.lastSync =  [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    document.lastUpdate =  @(0);
                    document.name = pdfName;
                    document.pdfURL = finalPath;
                    document.remoteURL = remoteUrl;
                    document.type = @(1);
                    [context save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                    [documentsView populateDocuments];
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadNewPdfToserver:remoteUrl withFileName:pdfName withFilePath:finalPath];
            });
        }
    }];
    [uploadLessonRecordsTask resume];
}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    float progress = [[NSNumber numberWithInteger:totalBytesSent] floatValue];
    float total = [[NSNumber numberWithInteger: totalBytesExpectedToSend] floatValue];
    NSLog(@"progress/total %f",progress/total);
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressToUploadFile setProgress:progress/total animated:YES];
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics{
    
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (error != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressContainView removeFromSuperview];
            NSString *errorStr = [NSString stringWithFormat:@"Error downloading '%@", [error userInfo]];
            FDLogError(errorStr);
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Document Upload Failed" message:errorStr preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSLog(@"you pressed Yes, please button");
            }];
            [alert addAction:yesButton];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}


-(void)chooseCourseButtonTapped:(id)sender
{
    if (coursePickerController == nil) {
        NSArray *courseNames = [NSArray arrayWithArray:documentsView.getGroupArray];
        coursePickerController = [[CoursePickerViewController alloc] initWithStyle:UITableViewStylePlain andCourses:courseNames];
        coursePickerController.delegate = self;
    }
    
    if (coursePickerPopover == nil) {
        // display the popover of courses
        coursePickerPopover = [[UIPopoverController alloc] initWithContentViewController:coursePickerController];
        [coursePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        // close the popover
        [coursePickerPopover dismissPopoverAnimated:YES];
        coursePickerPopover = nil;
        coursePickerController = nil;
    }
}

-(void)doUpdateButtonTapped:(id)sender
{
    //updateButton.enabled = NO;
    updateBaseButton.tintColor = [UIColor whiteColor];
    [documentsView confirmDocumentUpdate];
}

-(void)updateButtonTapped
{
    //updateButton.enabled = NO;
    updateBaseButton.tintColor = [UIColor whiteColor];
    [documentsView confirmDocumentUpdate];
}

-(void)addDocumentsByInstructor{
    if (isSelectedToDelete) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete the selected document(s)?" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            [documentsView deleteViewsToBeSelected];
            
            isSelectedToDelete = NO;
            [[AppDelegate sharedDelegate] startThreadToSyncData:3];
            foldersButton.enabled = YES;
            [addBtn setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
            [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            }else{
                addBtn.hidden = YES;
            }
            if ([currentSelectedCourseName isEqualToString:@"My Docs"]) {
                addBtn.hidden = YES;
            }
            [documentsView reloadWithSelecting:NO];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
            
        }];
        [alert addAction:cancel];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }else{
        [[AppDelegate sharedDelegate] stopThreadToSyncData:3];
        AddDocumentsViewController *addDocView = [[AddDocumentsViewController alloc] initWithNibName:@"AddDocumentsViewController" bundle:nil];
        [addDocView.view setFrame:self.view.bounds];
        addDocView.delegate = self;
        addDocView.shownDocs = [documentsView getCurrentDocs];
        [self displayContentController:addDocView];
        [addDocView animateShow];
    }
}
- (void) displayContentController: (UIViewController*) content;
{
    [self.view addSubview:content.view];
    [self addChildViewController:content];
    [content didMoveToParentViewController:self];
}
- (void)removeCurrentViewFromSuper:(UIViewController *)viewController{
    [viewController willMoveToParentViewController:nil];  // 1
    [viewController.view removeFromSuperview];            // 2
    [viewController removeFromParentViewController];
}

#pragma mark AddDocumentViewControllerDelegate
- (void)didCancelDocumentView:(AddDocumentsViewController *)documentView{
    [self removeCurrentViewFromSuper:documentView];
    [[AppDelegate sharedDelegate] startThreadToSyncData:3];
}
- (void)didDoneDocumentView:(AddDocumentsViewController *)documentView withSelecteddoc:(NSMutableArray *)docInfoArray{
    
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    for (Document *documentToAdd in docInfoArray) {
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
            NSError *error;
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentGroup == NULL"];
            [request setPredicate:predicate];
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects == nil) {
                FDLogError(@"Unable to retrieve students!");
            } else if (objects.count == 0) {
                FDLogDebug(@"No valid students found!");
            } else {
                for (LessonGroup *lessonGroup in objects) {
                    if ([lessonGroup.name.lowercaseString isEqualToString:currentSelectedCourseName.lowercaseString]) {
                        Document *documentNew = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:context];
                        documentNew.documentID = documentToAdd.documentID;
                        documentNew.name = documentToAdd.name;
                        documentNew.remoteURL = documentToAdd.remoteURL;
                        documentNew.pdfURL = documentToAdd.pdfURL;
                        documentNew.lastSync = documentToAdd.lastSync;
                        documentNew.lastUpdate = @(0);
                        documentNew.type = @(2);
                        documentNew.downloaded = documentToAdd.downloaded;
                        documentNew.studentID = @(0);
                        documentNew.groupID = lessonGroup.groupID;
                        
                        [lessonGroup addDocumentsObject:documentNew];
                    }
                }
            }
        }else{
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects == nil) {
                FDLogError(@"Unable to retrieve students!");
            } else if (objects.count == 0) {
                FDLogDebug(@"No valid students found!");
            } else {
                FDLogDebug(@"%lu students found", (unsigned long)[objects count]);
                for (Student *student in objects) {
                    for (LessonGroup *lessonGroup in student.subGroups) {
                        if ([lessonGroup.name isEqualToString:currentSelectedCourseName]) {
                            Document *documentNew = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:context];
                            documentNew.documentID = documentToAdd.documentID;
                            documentNew.name = documentToAdd.name;
                            documentNew.remoteURL = documentToAdd.remoteURL;
                            documentNew.pdfURL = documentToAdd.pdfURL;
                            documentNew.lastSync = documentToAdd.lastSync;
                            documentNew.lastUpdate = @(0);
                            documentNew.type = @(2);
                            documentNew.downloaded = documentToAdd.downloaded;
                            documentNew.studentID = student.userID;
                            documentNew.groupID = lessonGroup.groupID;
                            
                            [lessonGroup addDocumentsObject:documentNew];
                        }
                    }
                    
                }
            }
        }
    }
    [context save:&error];
    [self populateDocuments];
    [self removeCurrentViewFromSuper:documentView];
    
    [[AppDelegate sharedDelegate] startThreadToSyncData:3];
}

- (void)selectDocumentsToDelete{
    isSelectedToDelete = !isSelectedToDelete;
    if (isSelectedToDelete) {
        
        [[AppDelegate sharedDelegate] stopThreadToSyncData:3];
        foldersButton.enabled = NO;
        [addBtn setImage:[UIImage imageNamed:@"delete_doc"] forState:UIControlStateNormal];
        [selectBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        if ([currentSelectedCourseName isEqualToString:@"My Docs"]) {
            addBtn.hidden = NO;
        }
        [documentsView reloadWithSelecting:YES];
    }else{
        [[AppDelegate sharedDelegate] startThreadToSyncData:3];
        foldersButton.enabled = YES;
        [addBtn setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
        [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        }else{
            addBtn.hidden = YES;
        }
        if ([currentSelectedCourseName isEqualToString:@"My Docs"]) {
            addBtn.hidden = YES;
        }
        [documentsView reloadWithSelecting:NO];
    }
}

-(void)loggedInSuccessfully
{
    [documentsView populateDocuments];
}

#pragma mark LibraryDocumentsDelegate methods

- (void)documentsView:(DocumentsView *)documentsView didSelectDocument:(DocumentInfo *)document withType:(NSInteger)type
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = @"";
    
    documentDirectory = [NSString stringWithFormat:@"file://%@/%@", [paths objectAtIndex:0], document.readerDocument.fileName];
    NSURL *documentUrl =  [[NSURL alloc] initWithString:[documentDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    MFDocumentManager *aDocManager = [[MFDocumentManager alloc]initWithFileUrl:documentUrl];
    
    ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithDocumentManager:aDocManager];
    readerViewController.pathOfCurrentPDF =documentUrl;
    [readerViewController setDocumentId:document.readerDocument.fileName];
    [readerViewController setDocumentDelegate:readerViewController];
    //    readerViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:readerViewController animated:YES];
}
- (void)documentsView:(DocumentsView *)documentsView didSelectDocumentWithUrl:(NSString *)docUrl
{
    
    NSString *docName = [[NSURL URLWithString:docUrl] lastPathComponent];
    NSInteger fileTypeValue = 0;
    NSArray *parseFileName = [docName componentsSeparatedByString:@"."];
    if (parseFileName.count > 1) {
        NSString *lastString = parseFileName[parseFileName.count-1];
        //1: image, 2: video, 3: pdf, 4: doc, txt, 5: ppt
        if ([lastString.lowercaseString isEqualToString:@"png"] || [lastString.lowercaseString isEqualToString:@"jpg"] || [lastString.lowercaseString isEqualToString:@"jpeg"]) {
            fileTypeValue = 1;
        }else if([lastString.lowercaseString isEqualToString:@"mov"] || [lastString.lowercaseString isEqualToString:@"avi"] || [lastString.lowercaseString isEqualToString:@"mp4"]){
            fileTypeValue = 2;
        }else if ([lastString.lowercaseString isEqualToString:@"pdf"]){
            fileTypeValue = 3;
        }else if ([lastString.lowercaseString isEqualToString:@"txt"] || [lastString.lowercaseString isEqualToString:@"doc"]){
            fileTypeValue = 4;
        }else if ([lastString.lowercaseString isEqualToString:@"ppt"] || [lastString.lowercaseString isEqualToString:@"pptx"]){
            fileTypeValue = 5;
        }
    }
    
    if (fileTypeValue == 3) {
        
    }else if (fileTypeValue == 1) {
        [imageViewOfDoc setImageWithURL:[NSURL URLWithString:docUrl]];
        [[AppDelegate sharedDelegate].window addSubview:ivCoverView];
    }else{
        NSString *fileName = [[NSURL fileURLWithPath:docUrl] lastPathComponent];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = @"";
        
        documentDirectory = [NSString stringWithFormat:@"file://%@/%@", [paths objectAtIndex:0], fileName];
        NSURL *documentUrl =  [[NSURL alloc] initWithString:[documentDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:documentUrl];
        [webView  loadRequest:request];
        [[AppDelegate sharedDelegate].window addSubview:vwCoverOfWebView];
    }
    
}
- (void)hideCoverOfWebView{
    [vwCoverOfWebView removeFromSuperview];
}
- (void)hideCoverOfImageView{
    [ivCoverView removeFromSuperview];
}
- (void)enableUpdateButton:(BOOL)_isEnabled
{
    if (_isEnabled) {
        updateBaseButton.tintColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0f];
    }else{
        updateBaseButton.tintColor = [UIColor whiteColor];
    }
    //updateButton.enabled = YES;
}

- (void)reSetBadge{
    NSInteger countRedBadge = [[AppDelegate sharedDelegate] getDocumentDownloadCount];
    
    if (countRedBadge == 0) {
        redBadgeView.hidden = YES;
    }else{
        redBadgeView.hidden = NO;
        redBadgeLbl.text = [NSString stringWithFormat:@"%ld", (long)countRedBadge];
    }
}
- (void)populateDocuments
{
    [documentsView populateDocuments];
}

#pragma mark - CoursePickerDelegate methods

-(void)selectedCourse:(NSString *)courseName
{
    currentSelectedCourseName = courseName;
    [documentsView populateDocumentsWithGroupName:courseName];
    self.navigationItem.title = courseName;
    
    if ([courseName isEqualToString:@"My Docs"]) {
        selectBtn.hidden = NO;
        if (isSelectedToDelete) {
            [[AppDelegate sharedDelegate] stopThreadToSyncData:3];
            [addBtn setImage:[UIImage imageNamed:@"delete_doc"] forState:UIControlStateNormal];
            [selectBtn setTitle:@"Cancel" forState:UIControlStateNormal];
            addBtn.hidden = NO;
            [documentsView reloadWithSelecting:YES];
        }else{
            [[AppDelegate sharedDelegate] startThreadToSyncData:3];
            [addBtn setImage:[UIImage imageNamed:@"addbtn"] forState:UIControlStateNormal];
            [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
            addBtn.hidden = YES;
            [documentsView reloadWithSelecting:NO];
        }
    }else{
        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
            addBtn.hidden = NO;
            selectBtn.hidden = NO;
        }else{
            addBtn.hidden = YES;
            selectBtn.hidden = YES;
        }
    }
    
    if (coursePickerPopover != nil) {
        [coursePickerPopover dismissPopoverAnimated:YES];
        coursePickerPopover = nil;
        coursePickerController = nil;
    }
}

@end
