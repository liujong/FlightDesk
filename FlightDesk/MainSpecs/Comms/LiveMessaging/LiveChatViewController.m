//
//  LiveChatViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "LiveChatViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"
#import "UIImage+Resize.h"
#import "UIImage+animatedGIF.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AFNetworking/UIButton+AFNetworking.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "ReaderDocument.h"
#import <FastPdfKit/FastPdfKit.h>
#import "PDFReaderViewController.h"
#import "DashboardView.h"
#import "SettingViewController.h"
#import "JSAnimatedView.h"
#import "UIView+Badge.h"

#import "BannerImageCropViewController.h"

#import <RGBColorSlider/RGBColorSlider.h>
#import <RGBColorSlider/RGBColorSliderDelegate.h>

#import <ImageIO/ImageIO.h>
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+GIF.h>


#import <MessageUI/MessageUI.h>

@import Firebase;
@interface LiveChatViewController ()<UITextViewDelegate,UINavigationControllerDelegate,  UIImagePickerControllerDelegate, UIDocumentPickerDelegate, NSBubbleDataDelegate, TOSplitViewControllerDelegate, BubbleTableViewDelegate, UITextFieldDelegate, RGBColorSliderDataOutlet, BannerImageCropViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL keyboardShown;
    
    UIView *vwPhoto;
    UIImageView *imvPhoto;
    
    UIView *vwCoverOfWebView;
    UIWebView *webView;
    
    MBProgressHUD *downloadProgressHUD;
    
    NSInteger fileTypeValue;
    
    NSManagedObjectContext *context;
    
    
    DashboardView *dashboardView;
    
    FIRDatabaseReference *rootR;
    FIRDatabaseReference *rootRForBanner;
    
    NSMutableArray *arrayAvailDeviceTokenForAdmin;
    
    UIRefreshControl *refreshControl;
    
    BOOL isShownBottomOnChatBoard;
    BOOL isOpenFirstTime;
    
    BOOL isToGetBannerImage;
    NSString *currentSetBannerImageUrl;
    
    RGBColorSliderDelegate *delegateOfREGColorSilder;
    NSInteger redValue;
    NSInteger greenValue;
    NSInteger blueValue;
    
    BOOL isGifImage;
    UIImage *gifImage;
    
    JSAnimatedView *jsAnimatedView;
    
    NSNumber *currentUserID;
    
}
@end

@implementation LiveChatViewController

@synthesize abbreviationName, friendName, friendID, deviceToken, badgeCountOfUser, isActive;
@synthesize playerVC;
@synthesize boardID;
@synthesize isGeneralBanner, isGeneralRoom;
- (void)viewDidLoad {
    [super viewDidLoad];
    isShownBottomOnChatBoard = YES;
    isOpenFirstTime = YES;
    isToGetBannerImage = NO;
    currentSetBannerImageUrl = @"";
    redValue = 255;
    greenValue = 255;
    blueValue = 255;
    
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        currentUserID = @999999;
    }else{
        currentUserID = [NSNumber numberWithInteger:[[AppDelegate sharedDelegate].userId integerValue]];
    }
    
    navTitle.text = friendName;
    bubbleData = [[NSMutableArray alloc] init];
    arrayAvailDeviceTokenForAdmin = [[NSMutableArray alloc] init];
    bubbleTableView.bubbleDataSource = self;
    bubbleTableView.snapInterval = 120;
    bubbleTableView.showAvatars = YES;
    bubbleTableView.bubbleTblDelegate = self;
    fileTypeValue = 0;
    context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    
    //show selected image
    vwPhoto = [[UIView alloc] initWithFrame:[AppDelegate sharedDelegate].window.frame];
    vwPhoto.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    CGRect frameOfPhoto = vwPhoto.frame;
    frameOfPhoto.origin.y = frameOfPhoto.origin.y + 64.0f;
    frameOfPhoto.size.height = frameOfPhoto.size.height - 128.0f;
    imvPhoto = [[UIImageView alloc] initWithFrame:frameOfPhoto];
    [vwPhoto addSubview:imvPhoto];
    [imvPhoto setBackgroundColor:[UIColor clearColor]];
    imvPhoto.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton *btDone = [UIButton buttonWithType:UIButtonTypeCustom];
    [btDone setTitle:@"Done" forState:UIControlStateNormal];
    [btDone.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [btDone setFrame:CGRectMake(frameOfPhoto.origin.x - 80.0f, 30, 50, 30)];
    [btDone addTarget:self action:@selector(btPhotoDoneClick) forControlEvents:UIControlEventTouchUpInside];
    [vwPhoto addSubview:btDone];
    UITapGestureRecognizer *tapGestureToPreViewImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(btPhotoDoneClick)];
    [vwPhoto addGestureRecognizer:tapGestureToPreViewImage];
    
    
    //show selected files
    vwCoverOfWebView = [[UIView alloc] initWithFrame:[AppDelegate sharedDelegate].window.frame];
    vwCoverOfWebView.backgroundColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.7f];
    CGRect frameOfWebView = vwCoverOfWebView.frame;
    frameOfWebView.origin.x = frameOfWebView.origin.x + 40.0f;
    frameOfWebView.origin.y = frameOfPhoto.origin.y + 64.0f;
    frameOfWebView.size.height = frameOfPhoto.size.height - 128.0f;
    frameOfWebView.size.width = frameOfPhoto.size.width - 80.0f;
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
    
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [bubbleTableView addGestureRecognizer:tapGesture];
    
    isGifImage = NO;
    gifImage = [[UIImage alloc] init];
    if (isGeneralBanner) {
        banerViewToCreateForAdmin.hidden = NO;
        banerViewForUsers.hidden = YES;
        bubbleTblTopCons.constant = 0;
        keyboardHegith.constant = 275.0f;
        btnBanerImage.layer.masksToBounds = YES;
    }else{
        banerViewToCreateForAdmin.hidden = YES;
        banerViewForUsers.hidden = NO;
        bubbleTblTopCons.constant = 100;
        refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
        [bubbleTableView addSubview:refreshControl];
    }
    
    if (isGeneralRoom && ![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        sendingViewForUsers.hidden = YES;
    }
    if (![[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
        btnClearGeneral.hidden = YES;
    }
}
- (void)handleRefresh:(id)sender{
    isShownBottomOnChatBoard = NO;
    if (bubbleData.count > 0) {
        NSBubbleData *lastData = [bubbleData objectAtIndex:0];
        [self getChatHistoryFromServer:[lastData.ordering integerValue]];
    }else{
        [self getChatHistoryFromServer:-1];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    btnSettings.badge.badgeValue = [[AppDelegate sharedDelegate] getBadgeCountForExpiredAircraft:nil];
    btnSettings.badge.badgeColor = [UIColor redColor];
    [self setNavigationColorWithGradiant];
    [AppDelegate sharedDelegate].isShownChatBoard = YES;
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    
    if (friendID != nil && [boardID integerValue] != 999999 && [boardID integerValue] != 99999) {
        [bubbleData removeAllObjects];
        [self checkBoardIdFromLocal];
    }else if ([boardID integerValue] == 999999){
        [bubbleData removeAllObjects];
        friendID = @"0";
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        [self getAllDeviceTokenFromServer];//to send push notification
        [self checkBoardIdFromLocalForAdmin];
    }else if ([boardID integerValue] == 99999){
        [bubbleData removeAllObjects];
        friendID = @"0";
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        [self getAllDeviceTokenFromServer];//to send push notification
        //[self checkBoardIdFromLocalForAdmin];
        [self syncChattingView];
    }
    
    [self getGeneralBannerFromServer];
    
    [self addAndOrientationWithbannerView];
    
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"LiveChatViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)setNavigationColorWithGradiant{
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor magentaColor].CGColor,
                              (__bridge id)[UIColor colorWithRed:190.0f/255.0f green:0.0f blue:1.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
    [AppDelegate sharedDelegate].isShownChatBoard = NO;
    
    if ([friendID integerValue] == 999999) {
        [self cancelRequestSupportToFlightDesk];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadBannerView{
    [self addAndOrientationWithbannerView];
}
- (void)clearBannerWithPush{
    [AppDelegate sharedDelegate].bannerDetails = nil;
    [topbannerTextView removeFromSuperview];
    [topBannerImage removeFromSuperview];
    [jsAnimatedView removeFromSuperview];
}
- (void)clearGeneralMessages{
    if (!isGeneralRoom) {
        return;
    }
    //clear messages on local
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boardID == 999999"];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
    } else {
        for (ChatHistory *chatHistoryToDelete in objects) {
            [context deleteObject:chatHistoryToDelete];
        }
    }
    [context save:&error];
    
    [bubbleData removeAllObjects];
    [bubbleTableView reloadData];
}
- (void)getAllDeviceTokenFromServer{
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.label.text = @"Activating Comms Messaging…";
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"get_all_devices", @"action", currentUserID, @"user_id", nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [arrayAvailDeviceTokenForAdmin removeAllObjects];
                    for (NSDictionary *oneUser in [queryResults objectForKey:@"devices"]) {
                        [arrayAvailDeviceTokenForAdmin addObject:oneUser];
                    }
                });
                
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Incorrect verification code, Please try again" :@"Failed!"] ;
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
    [uploadLessonRecordsTask resume];
}
- (void)checkBoardIdFromLocal{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatBoard" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSNumber *targetUserID = [NSNumber numberWithInteger:[friendID integerValue]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userID == %@ AND targetUserID == %@) OR (targetUserID == %@ AND userID == %@)", currentUserID, targetUserID, currentUserID, targetUserID];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
        //sync with server
        [self getBoardInfomation];
    } else {
        
        if ([friendID integerValue] == 999999) {
            [self requestToGetSupportToFlightDesk];
        }
        ChatBoard *chatBoard = objects[0];
        boardID = chatBoard.boardID;
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        [self loadChattingHistoryFromLocal];
        [self syncMessagesToUnReadFromServer];
    }
}
- (void)syncMessagesToUnReadFromServer{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSNumber *targetUserID = [NSNumber numberWithInteger:[friendID integerValue]];
    
    NSString *queryStr = @"";
    if ([boardID integerValue] != 999999) {
        queryStr  = [NSString stringWithFormat:@"(userID == %@ AND target_userID == %@) OR (target_userID == %@ AND userID == %@)", currentUserID, targetUserID, currentUserID, targetUserID];
    }else{
        queryStr = @"boardID = 999999";
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:queryStr];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    
    NSInteger maxOrdering = 0;
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
    } else {
        maxOrdering = objects.count;
    }
    
    
    NSMutableArray *missOrderings = [[NSMutableArray alloc] init];
    if ([boardID integerValue] != 999999) {
        for (int i = 1; i < maxOrdering; i ++) {
            predicate = [NSPredicate predicateWithFormat:@"(userID == %@ AND target_userID == %@) OR (target_userID == %@ AND userID == %@) AND ordering = %@", currentUserID, targetUserID, currentUserID, targetUserID, [NSNumber numberWithInteger:i]];
            [request setPredicate:predicate];
            NSArray *objectsOrdering = [context executeFetchRequest:request error:&error];
            if (objectsOrdering == nil) {
                FDLogError(@"Unable to retrieve Board!");
            } else if (objectsOrdering.count == 0) {
                FDLogDebug(@"No valid Board found!");
                [missOrderings addObject:@(i)];
            } else {
            }
        }
    }
    
    
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.label.text = @"Activating Comms Messaging…";
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"syncMessageHistories", @"action", currentUserID, @"user_id",friendID, @"targetID",  @(maxOrdering), @"maxOrdering", missOrderings, @"missingOrdering", boardID, @"board_id", nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    // grab the current user's ID
                    NSString *userIDKey = @"userId";
                    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
                    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
                    if (userID == nil) {
                        FDLogError(@"Unable parse aircraft update without being logged in!");
                        return;
                    }
                    NSError *error;
                    NSNumber *epoch_microseconds;
                    id value = [queryResults objectForKey:@"last_update"];
                    if ([value isKindOfClass:[NSNumber class]]) {
                        epoch_microseconds = value;
                    } else {
                        FDLogError(@"Skipped aircraft update with invalid last_update time!");
                        return;
                    }
                    
                    value = [queryResults objectForKey:@"history"];
                    if ([value isKindOfClass:[NSArray class]] == NO) {
                        FDLogError(@"Encountered unexpected ChatHistories element which was not an array!");
                        return;
                    }
                    NSArray *ChatHistoriesArray = value;
                    for (id chatHistorisElement in ChatHistoriesArray) {
                        if ([chatHistorisElement isKindOfClass:[NSDictionary class]] == NO) {
                            FDLogError(@"Encountered unexpected Chathisotry element which was not a dictionary!");
                            continue;
                        }
                        NSDictionary *chatHistorisFields = chatHistorisElement;
                        // TODO: add lastSync datetime
                        NSNumber *historyID = [chatHistorisFields objectForKey:@"historyID"];
                        NSNumber *board_ID = [chatHistorisFields objectForKey:@"boardID"];
                        NSString *type = [chatHistorisFields objectForKey:@"type"];
                        NSString *fileURL = [chatHistorisFields objectForKey:@"fileURL"];
                        NSNumber *isRead = [chatHistorisFields objectForKey:@"isRead"];
                        NSString *message = [chatHistorisFields objectForKey:@"message"];
                        NSNumber *messageID = [chatHistorisFields objectForKey:@"messageID"];
                        NSString *sentTime = [chatHistorisFields objectForKey:@"sentTime"];
                        NSNumber *targetUserID = [chatHistorisFields objectForKey:@"target_user_id"];
                        NSString *targetName = [chatHistorisFields objectForKey:@"target_name"];
                        NSString *thumbImageSize = [chatHistorisFields objectForKey:@"thumbImageSize"];
                        NSString *thumbURL = [chatHistorisFields objectForKey:@"thumbURL"];
                        NSNumber *fromUserID = [chatHistorisFields objectForKey:@"userID"];
                        NSNumber *ordering = [chatHistorisFields objectForKey:@"ordering"];
                        
                        // check to see if existing version of this group needs to be updated
                        NSFetchRequest *request = [[NSFetchRequest alloc] init];
                        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
                        [request setEntity:entityDescription];
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"history_id == %@", historyID];
                        [request setPredicate:predicate];
                        NSArray *fetchedChatHistoris = [context executeFetchRequest:request error:&error];
                        ChatHistory *chatHistory = nil;
                        if (fetchedChatHistoris == nil) {
                            FDLogError(@"Skipped aircraft update since there was an error checking for existing ChatHistory!");
                        } else if (fetchedChatHistoris.count == 0) {
                            
                            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:context];
                            chatHistory.history_id = historyID;
                            chatHistory.boardID = board_ID;
                            chatHistory.fileUrl = fileURL;
                            chatHistory.isRead = isRead;
                            chatHistory.messageID = messageID;
                            chatHistory.message = message;
                            chatHistory.ordering = ordering;
                            chatHistory.sentTime = sentTime;
                            chatHistory.target_userID = targetUserID;
                            chatHistory.targetName = targetName;
                            chatHistory.thumbImageSize = thumbImageSize;
                            chatHistory.thumbUrl = thumbURL;
                            chatHistory.type = type;
                            chatHistory.userID = fromUserID;
                            chatHistory.lastUpdate = epoch_microseconds;
                        } else if (fetchedChatHistoris.count == 1) {
                            // check if the group has been updated
                            chatHistory = [fetchedChatHistoris objectAtIndex:0];
                            chatHistory.history_id = historyID;
                            chatHistory.boardID = board_ID;
                            chatHistory.fileUrl = fileURL;
                            chatHistory.isRead = isRead;
                            chatHistory.messageID = messageID;
                            chatHistory.message = message;
                            chatHistory.ordering = ordering;
                            chatHistory.sentTime = sentTime;
                            chatHistory.target_userID = targetUserID;
                            chatHistory.targetName = targetName;
                            chatHistory.thumbImageSize = thumbImageSize;
                            chatHistory.thumbUrl = thumbURL;
                            chatHistory.type = type;
                            chatHistory.userID = fromUserID;
                            chatHistory.lastUpdate = epoch_microseconds;
                        } else if (fetchedChatHistoris.count > 1) {
                            
                            for (ChatHistory *chathistoryToDelete in fetchedChatHistoris) {
                                [context deleteObject:chathistoryToDelete];
                            }
                            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:context];
                            chatHistory.history_id = historyID;
                            chatHistory.boardID = board_ID;
                            chatHistory.fileUrl = fileURL;
                            chatHistory.isRead = isRead;
                            chatHistory.messageID = messageID;
                            chatHistory.message = message;
                            chatHistory.ordering = ordering;
                            chatHistory.sentTime = sentTime;
                            chatHistory.target_userID = targetUserID;
                            chatHistory.targetName = targetName;
                            chatHistory.thumbImageSize = thumbImageSize;
                            chatHistory.thumbUrl = thumbURL;
                            chatHistory.type = type;
                            chatHistory.userID = fromUserID;
                            chatHistory.lastUpdate = epoch_microseconds;
                        }
                        if (chatHistory != nil) {
                            chatHistory.lastSync = epoch_microseconds;
                            [context save:&error];
                        }
                    }
                    if ([boardID integerValue] != 999999) {
                        [self loadChattingHistoryFromLocal];
                    }else{
                        [self loadGeneralMessagesFromLocal];
                    }
                });
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }else{
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
}
- (void)checkBoardIdFromLocalForAdmin{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boardID == %@", boardID];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
        [self getChatHistoryFromServer:-1];
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
        [self getChatHistoryFromServer:-1];
    } else {
        ChatBoard *chatBoard = objects[0];
        boardID = chatBoard.boardID;
        
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        [self loadGeneralMessagesFromLocal];
        [self syncMessagesToUnReadFromServer];
    }
    
    [self syncChattingView];
}
- (void)loadGeneralMessagesFromLocal{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boardID == %@", boardID];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
    } else {
        ChatBoard *chatBoard = objects[0];
        boardID = chatBoard.boardID;
        
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        NSMutableArray *tempMessages = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedMessaged = [tempMessages sortedArrayUsingDescriptors:sortDescriptors];
        
        [bubbleData removeAllObjects];
        for (ChatHistory *oneMessage in sortedMessaged) {
            NSString *dateString = oneMessage.sentTime;
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSDate *utcdate = [formatter dateFromString:dateString];
            
            [formatter setTimeZone:[NSTimeZone localTimeZone]];
            NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
            
            if ([oneMessage.type isEqualToString:@"text"]) {
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeMine];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.avatar_name = @"ME";
                    sayBubble.delegate = self;
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeSomeoneElse];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    if (oneMessage.targetName != nil && ![oneMessage.targetName isEqualToString:@""]) {
                        receiveBubble.avatar_name = oneMessage.targetName;
                    }else{
                        receiveBubble.avatar_name =  abbreviationName;
                    }
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"image"]) {
                NSString *imageUrl = oneMessage.thumbUrl;
                NSString *imageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:NO isGIF:NO];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:imageSize  withBanner:NO isGIF:NO];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    if (oneMessage.targetName != nil && ![oneMessage.targetName isEqualToString:@""]) {
                        receiveBubble.avatar_name = oneMessage.targetName;
                    }else{
                        receiveBubble.avatar_name =  abbreviationName;
                    }
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"video"]) {
                NSString *videoUrl = oneMessage.fileUrl;
                NSString *thumbUrl = oneMessage.thumbUrl;
                NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    
                    NSBubbleData *sayBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    if (oneMessage.targetName != nil && ![oneMessage.targetName isEqualToString:@""]) {
                        receiveBubble.avatar_name = oneMessage.targetName;
                    }else{
                        receiveBubble.avatar_name =  abbreviationName;
                    }
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"pdf"]) {
                NSString *pdfUrl = oneMessage.fileUrl;
                NSString *thumbUrl = oneMessage.thumbUrl;
                NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    if (oneMessage.targetName != nil && ![oneMessage.targetName isEqualToString:@""]) {
                        receiveBubble.avatar_name = oneMessage.targetName;
                    }else{
                        receiveBubble.avatar_name =  abbreviationName;
                    }
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"doc"] || [oneMessage.type isEqualToString:@"ppt"]) {
                NSString *docUrl = oneMessage.fileUrl;
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeMine];
                    sayBubble.messageID = oneMessage.messageID;
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeSomeoneElse];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    if (oneMessage.targetName != nil && ![oneMessage.targetName isEqualToString:@""]) {
                        receiveBubble.avatar_name = oneMessage.targetName;
                    }else{
                        receiveBubble.avatar_name =  abbreviationName;
                    }
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }
            if ([oneMessage.isRead integerValue] == 0) {
                oneMessage.isRead = @(1);
                oneMessage.lastUpdate = @(0);
                NSError *error;
                [context save:&error];
            }
        }
        
        
        [bubbleTableView reloadData];
        [self scrollToBottom:YES];
    }
}
- (void)loadChattingHistoryFromLocal{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSNumber *targetUserID = [NSNumber numberWithInteger:[friendID integerValue]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userID == %@ AND target_userID == %@) OR (target_userID == %@ AND userID == %@)", currentUserID, targetUserID, currentUserID, targetUserID];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
    } else {
        [bubbleData removeAllObjects];
        NSMutableArray *tempMessages = [NSMutableArray arrayWithArray:objects];
        // root groups have sub-groups & no lessons and sub-groups have lessons and no sub-groups
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"messageID" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedMessaged = [tempMessages sortedArrayUsingDescriptors:sortDescriptors];
        
        ChatHistory *chatHisToGetBoardID = sortedMessaged[0];
        boardID = chatHisToGetBoardID.boardID;
        [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
        for (ChatHistory *oneMessage in sortedMessaged) {
            NSString *dateString = oneMessage.sentTime;
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSDate *utcdate = [formatter dateFromString:dateString];
            
            [formatter setTimeZone:[NSTimeZone localTimeZone]];
            NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
            
            
            if ([oneMessage.type isEqualToString:@"text"]) {
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeMine];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.avatar_name = @"ME";
                    sayBubble.delegate = self;
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeSomeoneElse];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    receiveBubble.avatar_name =  abbreviationName;
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"image"]) {
                NSString *imageUrl = oneMessage.thumbUrl;
                NSString *imageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:NO isGIF:NO];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:imageSize withBanner:NO isGIF:NO];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    receiveBubble.avatar_name =  abbreviationName;
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"video"]) {
                NSString *videoUrl = oneMessage.fileUrl;
                NSString *thumbUrl = oneMessage.thumbUrl;
                NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    
                    NSBubbleData *sayBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    receiveBubble.avatar_name =  abbreviationName;
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"pdf"]) {
                NSString *pdfUrl = oneMessage.fileUrl;
                NSString *thumbUrl = oneMessage.thumbUrl;
                NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
                NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.messageID = oneMessage.messageID;
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    receiveBubble.avatar_name =  abbreviationName;
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }else if ([oneMessage.type isEqualToString:@"doc"] || [oneMessage.type isEqualToString:@"ppt"]) {
                NSString *docUrl = oneMessage.fileUrl;
                if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
                    NSBubbleData *sayBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeMine];
                    sayBubble.messageID = oneMessage.messageID;
                    //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                    sayBubble.delegate = self;
                    sayBubble.avatar_name = @"ME";
                    [bubbleData addObject:sayBubble];
                }else{
                    NSBubbleData *receiveBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeSomeoneElse];
                    receiveBubble.messageID = oneMessage.messageID;
                    receiveBubble.avatar_url = nil;
                    receiveBubble.delegate = self;
                    receiveBubble.avatar_name =  abbreviationName;
                    receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                    [bubbleData addObject:receiveBubble];
                }
            }
            
            if ([oneMessage.isRead integerValue] == 0) {
                oneMessage.isRead = @1;
                oneMessage.lastUpdate = @0;
                NSError *error;
                [context save:&error];
            }
        }
        [bubbleTableView reloadData];
        [self scrollToBottom:YES];
    }
    
    [self syncChattingView];
}

- (void)getBoardInfomation{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Activating Comms Messaging…";
    NSError *error;
    NSNumber *friend_id = [NSNumber numberWithInteger:[friendID integerValue]];
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"update_chatboard", @"action", currentUserID, @"one_user_id", friend_id, @"other_user_id", nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSNumber *boardIdFromServer = [queryResults objectForKey:@"board_id"];
                    boardID = boardIdFromServer;
                    [AppDelegate sharedDelegate].currentBoardID = [boardID integerValue];
                    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatBoard" inManagedObjectContext:context];
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    [request setEntity:entityDesc];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boardID == %@", boardIdFromServer];
                    [request setPredicate:predicate];
                    NSError *error;
                    NSArray *objects = [context executeFetchRequest:request error:&error];
                    
                    ChatBoard *chatBoard = nil;
                    if (objects == nil) {
                        FDLogError(@"Unable to retrieve Board!");
                    } else if (objects.count == 0) {
                        chatBoard = [NSEntityDescription insertNewObjectForEntityForName:@"ChatBoard" inManagedObjectContext:context];
                        chatBoard.boardID = boardIdFromServer;
                        chatBoard.userID = currentUserID;
                        chatBoard.targetUserID = [NSNumber numberWithInteger:[friendID integerValue]];
                    }
                    if (chatBoard != nil) {
                        NSError *error;
                        [context save:&error];
                    }
                    [self  syncChattingView];
                    [self getChatHistoryFromServer:-1];
                    if ([friendID integerValue] == 999999) {
                        [self requestToGetSupportToFlightDesk];
                    }
                });
            }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }else{
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading queries";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadLessonRecordsTask resume];
}
- (void)getGeneralBannerFromServer{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"get_generalBanner", @"action", currentUserID, @"user_id", nil];
    NSData *getChatHistoryJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *getChatHistoryRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [getChatHistoryRequest setHTTPMethod:@"POST"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [getChatHistoryRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)getChatHistoryJSON.length] forHTTPHeaderField:@"Content-Length"];
    [getChatHistoryRequest setHTTPBody:getChatHistoryJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getChatHistoriesTask = [session dataTaskWithRequest:getChatHistoryRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
        // handle the documents update
        if (data != nil) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self handleGeneralBannersUpdate:data];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while getting chathistories";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [getChatHistoriesTask resume];
}
- (void)handleGeneralBannersUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse banners update without being logged in!");
        return;
    }
    NSError *error;
    // parse the query results
    NSDictionary *chatHistoriesResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for banners data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [chatHistoriesResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped banners update with invalid last_update time!");
        return;
    }
    
    value = [chatHistoriesResults objectForKey:@"banners"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected banners element which was not an array!");
        return;
    }
    NSArray *ChatHistoriesArray = value;
    
    if (isGeneralBanner) {
        [self parsebannersArrayForAdminRoom:ChatHistoriesArray AsUserID:userID];
        
        [bubbleTableView reloadData];
        [self scrollToBottom:YES];
        isShownBottomOnChatBoard = YES;
    }else{
        NSInteger ordering = 0;
        NSDictionary *latestBannerDetails;
        for (NSDictionary *dictBannerDetails in ChatHistoriesArray) {
            if (ordering < [[dictBannerDetails objectForKey:@"ordering"] integerValue]) {
                latestBannerDetails = [dictBannerDetails copy];
            }
        }
        
        if (latestBannerDetails != nil) {
            [[AppDelegate sharedDelegate].bannerDetails setObject:[latestBannerDetails objectForKey:@"type"] forKey:@"type"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[latestBannerDetails objectForKey:@"fileURL"] forKey:@"bgColor"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[latestBannerDetails objectForKey:@"message"] forKey:@"message"];
            [[AppDelegate sharedDelegate].bannerDetails setObject:[latestBannerDetails objectForKey:@"thumbURL"] forKey:@"thumbURL"];
            
            NSString *type = [latestBannerDetails objectForKey:@"type"];
            NSString *fileURL = [latestBannerDetails objectForKey:@"fileURL"];
            NSString *message = [latestBannerDetails objectForKey:@"message"];
            NSString *thumbURL = [latestBannerDetails objectForKey:@"thumbURL"];
            
            [topbannerTextView removeFromSuperview];
            [topBannerImage removeFromSuperview];
            [jsAnimatedView removeFromSuperview];
            
            if ([type isEqualToString:@"bannerForText"]) {
                NSArray *parseBannerTextArray = [message componentsSeparatedByString:@"#!#!#"];
                NSString *largeTxt = @"";
                NSString *mediumTxt = @"";
                NSString *smallTxt = @"";
                if (parseBannerTextArray.count == 3) {
                    largeTxt = parseBannerTextArray[0];
                    mediumTxt = parseBannerTextArray[1];
                    smallTxt = parseBannerTextArray[2];
                }else if (parseBannerTextArray.count == 2) {
                    largeTxt = parseBannerTextArray[0];
                    mediumTxt = parseBannerTextArray[1];
                }else if (parseBannerTextArray.count == 1) {
                    largeTxt = parseBannerTextArray[0];
                }
                topLblLarge.text = largeTxt;
                topLblMedium.text = mediumTxt;
                topLblsmall.text = smallTxt;
                
                NSArray *parseBannercolorArray = [fileURL componentsSeparatedByString:@":"];
                float redColor = [parseBannercolorArray[0] floatValue];
                float greenColor = [parseBannercolorArray[1] floatValue];
                float blueColor = [parseBannercolorArray[2] floatValue];
                [topbannerTextView setFrame:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
                topbannerTextView.backgroundColor = [UIColor colorWithRed:redColor/255.0f green:greenColor/255.0f blue:blueColor/255.0f alpha:1.0f];
                [banerViewForUsers addSubview:topbannerTextView];
            }else if ([type isEqualToString:@"bannerForImage"]) {
                [topBannerImage setImageWithURL:[NSURL URLWithString:thumbURL]];
                [topBannerImage setFrame:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
                [banerViewForUsers addSubview:topBannerImage];
            }else if ([type isEqualToString:@"bannerForGif"]) {
                jsAnimatedView = [[JSAnimatedView alloc] initWithFrameWithAnimatedImage:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
                [jsAnimatedView prepareForReuse];
                [jsAnimatedView setImageWithURL:[NSURL URLWithString:[thumbURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                
                [banerViewForUsers addSubview:jsAnimatedView];
            }
        }
    }
}
- (void)parsebannersArrayForAdminRoom:(NSArray *)array AsUserID:(NSNumber *)userID
{
    for (id chatHistorisElement in array) {
        if ([chatHistorisElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected banners element which was not a dictionary!");
            continue;
        }
        NSDictionary *chatHistorisFields = chatHistorisElement;
        // TODO: add lastSync datetime
        NSString *type = [chatHistorisFields objectForKey:@"type"];
        NSString *fileURL = [chatHistorisFields objectForKey:@"fileURL"];
        NSString *message = [chatHistorisFields objectForKey:@"message"];
        NSNumber *messageID = [chatHistorisFields objectForKey:@"messageID"];
        NSString *sentTime = [chatHistorisFields objectForKey:@"sentTime"];
        NSString *thumbImageSize = [chatHistorisFields objectForKey:@"thumbImageSize"];
        NSString *thumbURL = [chatHistorisFields objectForKey:@"thumbURL"];
        NSNumber *ordering = [chatHistorisFields objectForKey:@"ordering"];
        
        NSString *dateString = sentTime;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
        NSDate *utcdate = [formatter dateFromString:dateString];
        
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
        
        
        if ([type isEqualToString:@"bannerForText"]) {
            if (isGeneralBanner) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithBannerText:message withBGColor:fileURL date:dateFromString type:BubbleTypeMine];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.isGeneralBanner = isGeneralBanner;
                sayBubble.avatar_name = @"ME";
                sayBubble.delegate = self;
                [bubbleData addObject:sayBubble];
            }
        }else if ([type isEqualToString:@"bannerForImage"]) {
            NSString *imageUrl = thumbURL;
            NSString *imageSizeToParse = thumbImageSize;
            NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
            CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
            CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
            CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
            if (isGeneralBanner) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:YES isGIF:NO];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.isGeneralBanner = isGeneralBanner;
                sayBubble.avatar_name = @"ME";
                [bubbleData addObject:sayBubble];
            }
        }else if ([type isEqualToString:@"bannerForGif"]) {
            NSString *imageUrl = thumbURL;
            NSString *imageSizeToParse = thumbImageSize;
            NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
            CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
            CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
            CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
            if (isGeneralBanner) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:YES isGIF:YES];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.isGeneralBanner = isGeneralBanner;
                sayBubble.avatar_name = @"ME";
                [bubbleData addObject:sayBubble];
            }
        }
    }
}
- (void)getChatHistoryFromServer:(NSInteger)startIndex{
    NSError *error;
    NSNumber *friend_id = [NSNumber numberWithInteger:[friendID integerValue]];
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"get_chathistory", @"action", currentUserID, @"user_id", friend_id, @"target_user_id",@(startIndex), @"start_index", nil];
    NSData *getChatHistoryJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *getChatHistoryRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [getChatHistoryRequest setHTTPMethod:@"POST"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [getChatHistoryRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)getChatHistoryJSON.length] forHTTPHeaderField:@"Content-Length"];
    [getChatHistoryRequest setHTTPBody:getChatHistoryJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *getChatHistoriesTask = [session dataTaskWithRequest:getChatHistoryRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [refreshControl endRefreshing];
        });
        // handle the documents update
        if (data != nil) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self handleChatHistoriesUpdate:data];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while getting chathistories";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [getChatHistoriesTask resume];
}
- (void)handleChatHistoriesUpdate:(NSData *)results{
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse aircraft update without being logged in!");
        return;
    }
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
        userID = @999999;
    }
    NSError *error;
    // parse the query results
    NSDictionary *chatHistoriesResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        FDLogError(@"Unable to parse JSON for ChatHistory data: %@", error);
        return;
    }
    
    NSNumber *epoch_microseconds;
    id value = [chatHistoriesResults objectForKey:@"last_update"];
    if ([value isKindOfClass:[NSNumber class]]) {
        epoch_microseconds = value;
    } else {
        FDLogError(@"Skipped aircraft update with invalid last_update time!");
        return;
    }
    
    value = [chatHistoriesResults objectForKey:@"history"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected ChatHistories element which was not an array!");
        return;
    }
    NSArray *ChatHistoriesArray = value;
    BOOL requireRepopulate = NO;
    //if ([boardID integerValue] != 999999) {
        if ([self parseChatHistorisArray:ChatHistoriesArray IntoContext:context WithSync:epoch_microseconds AsUserID:userID] == YES) {
            requireRepopulate = YES;
        }
    //}else{
        //[self parseChatHistorisArrayForAdminRoom:ChatHistoriesArray AsUserID:userID];
    //}
    
    if ([context hasChanges]) {
        [context save:&error];
    }
    
    [bubbleTableView reloadData];
    if (isShownBottomOnChatBoard) {
        [self scrollToBottom:YES];
    }
    isShownBottomOnChatBoard = YES;
}
- (BOOL)parseChatHistorisArray:(NSArray *)array IntoContext:(NSManagedObjectContext *)contextChatHistory WithSync:(NSNumber *)epochMicros AsUserID:(NSNumber *)userID
{
    BOOL requireRepopulate = NO;
    NSError *error;
    
    for (id chatHistorisElement in array) {
        if ([chatHistorisElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected Chathisotry element which was not a dictionary!");
            continue;
        }
        NSDictionary *chatHistorisFields = chatHistorisElement;
        // TODO: add lastSync datetime
        NSNumber *historyID = [chatHistorisFields objectForKey:@"historyID"];
        NSNumber *board_ID = [chatHistorisFields objectForKey:@"boardID"];
        NSString *type = [chatHistorisFields objectForKey:@"type"];
        NSString *fileURL = [chatHistorisFields objectForKey:@"fileURL"];
        NSNumber *isRead = [chatHistorisFields objectForKey:@"isRead"];
        NSString *message = [chatHistorisFields objectForKey:@"message"];
        NSNumber *messageID = [chatHistorisFields objectForKey:@"messageID"];
        NSString *sentTime = [chatHistorisFields objectForKey:@"sentTime"];
        NSNumber *targetUserID = [chatHistorisFields objectForKey:@"target_user_id"];
        NSString *targetName = [chatHistorisFields objectForKey:@"target_name"];
        NSString *thumbImageSize = [chatHistorisFields objectForKey:@"thumbImageSize"];
        NSString *thumbURL = [chatHistorisFields objectForKey:@"thumbURL"];
        NSNumber *fromUserID = [chatHistorisFields objectForKey:@"userID"];
        NSNumber *ordering = [chatHistorisFields objectForKey:@"ordering"];
        
        // check to see if existing version of this group needs to be updated
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:contextChatHistory];
        [request setEntity:entityDescription];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"history_id == %@", historyID];
        [request setPredicate:predicate];
        NSArray *fetchedChatHistoris = [contextChatHistory executeFetchRequest:request error:&error];
        ChatHistory *chatHistory = nil;
        if (fetchedChatHistoris == nil) {
            FDLogError(@"Skipped aircraft update since there was an error checking for existing ChatHistory!");
        } else if (fetchedChatHistoris.count == 0) {
            
            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:contextChatHistory];
            chatHistory.history_id = historyID;
            chatHistory.boardID = board_ID;
            chatHistory.fileUrl = fileURL;
            chatHistory.isRead = isRead;
            chatHistory.messageID = messageID;
            chatHistory.message = message;
            chatHistory.ordering = ordering;
            chatHistory.sentTime = sentTime;
            chatHistory.target_userID = targetUserID;
            chatHistory.targetName = targetName;
            chatHistory.thumbImageSize = thumbImageSize;
            chatHistory.thumbUrl = thumbURL;
            chatHistory.type = type;
            chatHistory.userID = fromUserID;
            chatHistory.lastUpdate = epochMicros;
            
            requireRepopulate = YES;
        } else if (fetchedChatHistoris.count == 1) {
            // check if the group has been updated
            chatHistory = [fetchedChatHistoris objectAtIndex:0];
            chatHistory.history_id = historyID;
            chatHistory.boardID = board_ID;
            chatHistory.fileUrl = fileURL;
            chatHistory.isRead = isRead;
            chatHistory.messageID = messageID;
            chatHistory.message = message;
            chatHistory.ordering = ordering;
            chatHistory.sentTime = sentTime;
            chatHistory.target_userID = targetUserID;
            chatHistory.targetName = targetName;
            chatHistory.thumbImageSize = thumbImageSize;
            chatHistory.thumbUrl = thumbURL;
            chatHistory.type = type;
            chatHistory.userID = fromUserID;
            chatHistory.lastUpdate = epochMicros;
        } else if (fetchedChatHistoris.count > 1) {
            
            for (ChatHistory *chathistoryToDelete in fetchedChatHistoris) {
                [context deleteObject:chathistoryToDelete];
            }
            chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:contextChatHistory];
            chatHistory.history_id = historyID;
            chatHistory.boardID = board_ID;
            chatHistory.fileUrl = fileURL;
            chatHistory.isRead = isRead;
            chatHistory.messageID = messageID;
            chatHistory.message = message;
            chatHistory.ordering = ordering;
            chatHistory.sentTime = sentTime;
            chatHistory.target_userID = targetUserID;
            chatHistory.targetName = targetName;
            chatHistory.thumbImageSize = thumbImageSize;
            chatHistory.thumbUrl = thumbURL;
            chatHistory.type = type;
            chatHistory.userID = fromUserID;
            chatHistory.lastUpdate = epochMicros;
            
            requireRepopulate = YES;
        }
        if (chatHistory != nil) {
            chatHistory.lastSync = epochMicros;
            [self addCurrentChatHistoryOnBubbleData:chatHistory];
            [contextChatHistory save:&error];
        }
    }
//    NSFetchRequest *expiredGroupRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
//    [expiredGroupRequest setEntity:entityDescription];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastSync < %@", epochMicros];
//    [expiredGroupRequest setPredicate:predicate];
//    NSArray *expiredChatHistories = [context executeFetchRequest:expiredGroupRequest error:&error];
//    if (expiredChatHistories != nil && expiredChatHistories.count > 0) {
//        for (ChatHistory *chathistoryToDelete in expiredChatHistories) {
//            [context deleteObject:chathistoryToDelete];
//        }
//        requireRepopulate = YES;
//    }
    return requireRepopulate;
}
- (void)addCurrentChatHistoryOnBubbleData:(ChatHistory *)oneMessage{
    NSString *dateString = oneMessage.sentTime;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    NSDate *utcdate = [formatter dateFromString:dateString];
    
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
    
    
    if ([oneMessage.type isEqualToString:@"text"]) {
        if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
            NSBubbleData *sayBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeMine];
            sayBubble.messageID = oneMessage.messageID;
            sayBubble.ordering = oneMessage.ordering;
            sayBubble.delegate = self;
            sayBubble.avatar_name = @"ME";
            [bubbleData insertObject:sayBubble atIndex:0];
        }else{
            NSBubbleData *receiveBubble = [NSBubbleData dataWithText:oneMessage.message date:dateFromString type:BubbleTypeSomeoneElse];
            receiveBubble.messageID = oneMessage.messageID;
            receiveBubble.avatar_url = nil;
            receiveBubble.delegate = self;
            receiveBubble.avatar_name =  abbreviationName;
            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
            receiveBubble.ordering = oneMessage.ordering;
            [bubbleData insertObject:receiveBubble atIndex:0];
        }
    }else if ([oneMessage.type isEqualToString:@"image"]) {
        NSString *imageUrl = oneMessage.thumbUrl;
        NSString *imageSizeToParse = oneMessage.thumbImageSize;
        NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
        if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
            NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:NO isGIF:NO];
            sayBubble.messageID = oneMessage.messageID;
            sayBubble.delegate = self;
            sayBubble.ordering = oneMessage.ordering;
            //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
            sayBubble.avatar_name = @"ME";
            [bubbleData insertObject:sayBubble atIndex:0];
        }else{
            NSBubbleData *receiveBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:imageSize withBanner:NO isGIF:NO];
            receiveBubble.messageID = oneMessage.messageID;
            receiveBubble.avatar_url = nil;
            receiveBubble.delegate = self;
            receiveBubble.ordering = oneMessage.ordering;
            receiveBubble.avatar_name =  abbreviationName;
            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
            [bubbleData insertObject:receiveBubble atIndex:0];
        }
    }else if ([oneMessage.type isEqualToString:@"video"]) {
        NSString *videoUrl = oneMessage.fileUrl;
        NSString *thumbUrl = oneMessage.thumbUrl;
        NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
        NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
        CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
        if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
            
            NSBubbleData *sayBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
            //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
            sayBubble.messageID = oneMessage.messageID;
            sayBubble.delegate = self;
            sayBubble.ordering = oneMessage.ordering;
            sayBubble.avatar_name = @"ME";
            [bubbleData insertObject:sayBubble atIndex:0];
        }else{
            NSBubbleData *receiveBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
            receiveBubble.messageID = oneMessage.messageID;
            receiveBubble.avatar_url = nil;
            receiveBubble.delegate = self;
            receiveBubble.avatar_name =  abbreviationName;
            receiveBubble.ordering = oneMessage.ordering;
            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
            [bubbleData insertObject:receiveBubble atIndex:0];
        }
    }else if ([oneMessage.type isEqualToString:@"pdf"]) {
        NSString *pdfUrl = oneMessage.fileUrl;
        NSString *thumbUrl = oneMessage.thumbUrl;
        NSString *thumbImageSizeToParse = oneMessage.thumbImageSize;
        NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
        CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
        if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
            NSBubbleData *sayBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
            //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
            sayBubble.messageID = oneMessage.messageID;
            sayBubble.delegate = self;
            sayBubble.ordering = oneMessage.ordering;
            sayBubble.avatar_name = @"ME";
            [bubbleData insertObject:sayBubble atIndex:0];
        }else{
            NSBubbleData *receiveBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
            receiveBubble.messageID = oneMessage.messageID;
            receiveBubble.avatar_url = nil;
            receiveBubble.delegate = self;
            receiveBubble.avatar_name =  abbreviationName;
            receiveBubble.ordering = oneMessage.ordering;
            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
            [bubbleData insertObject:receiveBubble atIndex:0];
        }
    }else if ([oneMessage.type isEqualToString:@"doc"] || [oneMessage.type isEqualToString:@"ppt"]) {
        NSString *docUrl = oneMessage.fileUrl;
        if ([currentUserID integerValue] == [oneMessage.userID integerValue]) {
            NSBubbleData *sayBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeMine];
            sayBubble.messageID = oneMessage.messageID;
            //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
            sayBubble.delegate = self;
            sayBubble.ordering = oneMessage.ordering;
            sayBubble.avatar_name = @"ME";
            [bubbleData insertObject:sayBubble atIndex:0];
        }else{
            NSBubbleData *receiveBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeSomeoneElse];
            receiveBubble.messageID = oneMessage.messageID;
            receiveBubble.avatar_url = nil;
            receiveBubble.delegate = self;
            receiveBubble.avatar_name =  abbreviationName;
            receiveBubble.ordering = oneMessage.ordering;
            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
            [bubbleData insertObject:receiveBubble atIndex:0];
        }
    }
    
    if ([oneMessage.isRead integerValue] == 0) {
        oneMessage.isRead = @1;
        oneMessage.lastUpdate = @0;
        NSError *error;
        [context save:&error];
    }
}
- (void)parseChatHistorisArrayForAdminRoom:(NSArray *)array AsUserID:(NSNumber *)userID
{
    for (id chatHistorisElement in array) {
        if ([chatHistorisElement isKindOfClass:[NSDictionary class]] == NO) {
            FDLogError(@"Encountered unexpected Chathisotry element which was not a dictionary!");
            continue;
        }
        NSDictionary *chatHistorisFields = chatHistorisElement;
        // TODO: add lastSync datetime
        NSString *type = [chatHistorisFields objectForKey:@"type"];
        NSString *fileURL = [chatHistorisFields objectForKey:@"fileURL"];
        NSString *message = [chatHistorisFields objectForKey:@"message"];
        NSNumber *messageID = [chatHistorisFields objectForKey:@"messageID"];
        NSString *sentTime = [chatHistorisFields objectForKey:@"sentTime"];
        NSString *targetName = [chatHistorisFields objectForKey:@"target_name"];
        NSString *thumbImageSize = [chatHistorisFields objectForKey:@"thumbImageSize"];
        NSString *thumbURL = [chatHistorisFields objectForKey:@"thumbURL"];
        NSNumber *fromUserID = [chatHistorisFields objectForKey:@"userID"];
        NSNumber *ordering = [chatHistorisFields objectForKey:@"ordering"];
        
        NSString *dateString = sentTime;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
        NSDate *utcdate = [formatter dateFromString:dateString];
        
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
        
        
        if ([type isEqualToString:@"text"]) {
            if ([currentUserID integerValue] == [fromUserID integerValue]) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithText:message date:dateFromString type:BubbleTypeMine];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.avatar_name = @"ME";
                [bubbleData insertObject:sayBubble atIndex:0];
            }else{
                NSBubbleData *receiveBubble = [NSBubbleData dataWithText:message date:dateFromString type:BubbleTypeSomeoneElse];
                receiveBubble.messageID = messageID;
                receiveBubble.avatar_url = nil;
                receiveBubble.delegate = self;
                receiveBubble.ordering = ordering;
                if (targetName != nil && ![targetName isEqualToString:@""]) {
                    receiveBubble.avatar_name = targetName;
                }else{
                    receiveBubble.avatar_name =  abbreviationName;
                }
                receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                [bubbleData insertObject:receiveBubble atIndex:0];
            }
        }else if ([type isEqualToString:@"image"]) {
            NSString *imageUrl = thumbURL;
            NSString *imageSizeToParse = thumbImageSize;
            NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
            CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
            CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
            CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
            if ([currentUserID integerValue] == [fromUserID integerValue]) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:NO isGIF:NO];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.avatar_name = @"ME";
                [bubbleData insertObject:sayBubble atIndex:0];
            }else{
                NSBubbleData *receiveBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:imageSize withBanner:NO isGIF:NO];
                receiveBubble.messageID = messageID;
                receiveBubble.avatar_url = nil;
                receiveBubble.delegate = self;
                receiveBubble.ordering = ordering;
                if (targetName != nil && ![targetName isEqualToString:@""]) {
                    receiveBubble.avatar_name = targetName;
                }else{
                    receiveBubble.avatar_name =  abbreviationName;
                }
                receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                [bubbleData insertObject:receiveBubble atIndex:0];
            }
        }else if ([type isEqualToString:@"video"]) {
            NSString *videoUrl = fileURL;
            NSString *thumbUrl = thumbURL;
            NSString *thumbImageSizeToParse = thumbImageSize;
            NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
            CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
            CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
            CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
            if ([currentUserID integerValue] == [fromUserID integerValue]) {
                
                NSBubbleData *sayBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.avatar_name = @"ME";
                [bubbleData insertObject:sayBubble atIndex:0];
            }else{
                NSBubbleData *receiveBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                receiveBubble.messageID = messageID;
                receiveBubble.avatar_url = nil;
                receiveBubble.delegate = self;
                receiveBubble.ordering = ordering;
                if (targetName != nil && ![targetName isEqualToString:@""]) {
                    receiveBubble.avatar_name = targetName;
                }else{
                    receiveBubble.avatar_name =  abbreviationName;
                }
                receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                [bubbleData insertObject:receiveBubble atIndex:0];
            }
        }else if ([type isEqualToString:@"pdf"]) {
            NSString *pdfUrl = fileURL;
            NSString *thumbUrl = thumbURL;
            NSString *thumbImageSizeToParse = thumbImageSize;
            NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
            CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
            CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
            CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
            if ([currentUserID integerValue] == [fromUserID integerValue]) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                sayBubble.messageID = messageID;
                sayBubble.ordering = ordering;
                sayBubble.delegate = self;
                sayBubble.avatar_name = @"ME";
                [bubbleData insertObject:sayBubble atIndex:0];
            }else{
                NSBubbleData *receiveBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                receiveBubble.messageID = messageID;
                receiveBubble.avatar_url = nil;
                receiveBubble.delegate = self;
                receiveBubble.ordering = ordering;
                if (targetName != nil && ![targetName isEqualToString:@""]) {
                    receiveBubble.avatar_name = targetName;
                }else{
                    receiveBubble.avatar_name =  abbreviationName;
                }
                receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                [bubbleData insertObject:receiveBubble atIndex:0];
            }
        }else if ([type isEqualToString:@"doc"] || [type isEqualToString:@"ppt"]) {
            NSString *docUrl = fileURL;
            if ([currentUserID integerValue] == [fromUserID integerValue]) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeMine];
                sayBubble.messageID = messageID;
                //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                sayBubble.delegate = self;
                sayBubble.ordering = ordering;
                sayBubble.avatar_name = @"ME";
                [bubbleData insertObject:sayBubble atIndex:0];
            }else{
                NSBubbleData *receiveBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeSomeoneElse];
                receiveBubble.messageID = messageID;
                receiveBubble.avatar_url = nil;
                receiveBubble.delegate = self;
                receiveBubble.ordering = ordering;
                if (targetName != nil && ![targetName isEqualToString:@""]) {
                    receiveBubble.avatar_name = targetName;
                }else{
                    receiveBubble.avatar_name =  abbreviationName;
                }
                receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                [bubbleData insertObject:receiveBubble atIndex:0];
            }
        }
    }
    
}
- (void)syncChattingView{
    
    if (!isGeneralBanner) {
        rootR =[[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld" ,(long)[boardID integerValue]]];
        
        [[rootR queryOrderedByKey] removeAllObservers];
        [[rootR queryOrderedByKey] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot){
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                NSDictionary *dict = snapshot.value;
                NSNumber *boardIDToCheck = [dict objectForKey:@"boardID"];
                NSNumber *messageIDToCheck = [dict objectForKey:@"message_id"];
                NSNumber *userIDToUpdate = [dict objectForKey:@"from"];
                NSNumber *targetIDToUpdate = [dict objectForKey:@"to"];
                NSNumber *ordering = [dict objectForKey:@"ordering"];
                NSString *messageType = [dict objectForKey:@"type"];
                NSString *dateString = [dict objectForKey:@"sentTime"];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
                NSDate *utcdate = [formatter dateFromString:dateString];
                
                [formatter setTimeZone:[NSTimeZone localTimeZone]];
                NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
                
                NSNumber *isRead = [dict objectForKey:@"isRead"];
                
                NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:entityDesc];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageID == %@", messageIDToCheck];
                [request setPredicate:predicate];
                NSError *error;
                NSArray *objects = [context executeFetchRequest:request error:&error];
                
                ChatHistory *chatHistory = nil;
                if (objects == nil) {
                    FDLogError(@"Unable to retrieve Board!");
                } else if (objects.count == 0) {
                    chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:context];
                    chatHistory.boardID = boardID;
                    chatHistory.messageID = messageIDToCheck;
                    chatHistory.userID = userIDToUpdate;
                    chatHistory.target_userID = targetIDToUpdate;
                    chatHistory.type = messageType;
                    chatHistory.sentTime = dateString;
                    chatHistory.searchKey = snapshot.key;
                    chatHistory.isRead = isRead;
                    chatHistory.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    chatHistory.lastUpdate = @(0);
                    chatHistory.history_id = @(0);
                    chatHistory.ordering = ordering;
                    
                    if ([dict objectForKey:@"fromName"]) {
                        chatHistory.targetName = [dict objectForKey:@"fromName"];
                    }
                    
                    //play sound
                    if ([isRead integerValue] == 0) {
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            [[AppDelegate sharedDelegate] playingAndStopForMessageToSend];
                        }else{
                            [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
                        }
                    }
                    
                    
                    if ([messageType isEqualToString:@"text"]) {
                        chatHistory.message = [dict objectForKey:@"message"];
                        
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithText:[dict objectForKey:@"message"] date:dateFromString type:BubbleTypeMine];
                            sayBubble.messageID = messageIDToCheck;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            sayBubble.delegate = self;
                            [bubbleData addObject:sayBubble];
                            
                            if ([isRead integerValue] == 0) {
                                [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                            }
                        }else{
                            NSBubbleData *receiveBubble = [NSBubbleData dataWithText:[dict objectForKey:@"message"] date:dateFromString type:BubbleTypeSomeoneElse];
                            receiveBubble.messageID = messageIDToCheck;
                            receiveBubble.avatar_url = nil;
                            receiveBubble.delegate = self;
                            receiveBubble.ordering = ordering;
                            if ([dict objectForKey:@"fromName"]) {
                                receiveBubble.avatar_name = [dict objectForKey:@"fromName"];
                            }else{
                                receiveBubble.avatar_name =  abbreviationName;
                            }
                            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                            [bubbleData addObject:receiveBubble];
                        }
                    }else if ([messageType isEqualToString:@"image"]) {
                        NSString *imageUrl = [dict objectForKey:@"imageUrl"];
                        NSString *imageSizeToParse = [dict objectForKey:@"imageSize"];
                        NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
                        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
                        
                        chatHistory.thumbUrl = imageUrl;
                        chatHistory.thumbImageSize = imageSizeToParse;
                        
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            
                            NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:NO isGIF:NO];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                            
                            if ([isRead integerValue] == 0) {
                                [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                            }
                        }else{
                            NSBubbleData *receiveBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:imageSize withBanner:NO isGIF:NO];
                            receiveBubble.avatar_url = nil;
                            receiveBubble.delegate = self;
                            receiveBubble.ordering = ordering;
                            if ([dict objectForKey:@"fromName"]) {
                                receiveBubble.avatar_name = [dict objectForKey:@"fromName"];
                            }else{
                                receiveBubble.avatar_name =  abbreviationName;
                            }
                            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                            [bubbleData addObject:receiveBubble];
                        }
                    }else if ([messageType isEqualToString:@"video"]) {
                        NSString *videoUrl = [dict objectForKey:@"videoUrl"];
                        NSString *thumbUrl = [dict objectForKey:@"thumbUrl"];
                        NSString *thumbImageSizeToParse = [dict objectForKey:@"thumbImageSize"];
                        NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                        CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                        
                        chatHistory.fileUrl = videoUrl;
                        chatHistory.thumbUrl = thumbUrl;
                        chatHistory.thumbImageSize = thumbImageSizeToParse;
                        
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                            
                            if ([isRead integerValue] == 0) {
                                [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                            }
                        }else{
                            NSBubbleData *receiveBubble = [NSBubbleData dataWithVideo:videoUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                            receiveBubble.avatar_url = nil;
                            receiveBubble.delegate = self;
                            receiveBubble.ordering = ordering;
                            if ([dict objectForKey:@"fromName"]) {
                                receiveBubble.avatar_name = [dict objectForKey:@"fromName"];
                            }else{
                                receiveBubble.avatar_name =  abbreviationName;
                            }
                            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                            [bubbleData addObject:receiveBubble];
                        }
                    }else if ([messageType isEqualToString:@"pdf"]) {
                        NSString *pdfUrl = [dict objectForKey:@"pdfUrl"];
                        NSString *thumbUrl = [dict objectForKey:@"thumbUrl"];
                        NSString *thumbImageSizeToParse = [dict objectForKey:@"thumbImageSize"];
                        NSArray *arraySizeToBeParsed = [thumbImageSizeToParse componentsSeparatedByString:@":"];
                        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                        CGSize thumbImageSize = CGSizeMake(imageWidth, imageHeight);
                        
                        chatHistory.fileUrl = pdfUrl;
                        chatHistory.thumbUrl = thumbUrl;
                        chatHistory.thumbImageSize = thumbImageSizeToParse;
                        
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeMine withImageSize:thumbImageSize];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                            
                            if ([isRead integerValue] == 0) {
                                [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                            }
                        }else{
                            NSBubbleData *receiveBubble = [NSBubbleData dataWithPdf:pdfUrl withRemoteUrl:pdfUrl thumb:thumbUrl date:dateFromString type:BubbleTypeSomeoneElse withImageSize:thumbImageSize];
                            receiveBubble.avatar_url = nil;
                            receiveBubble.delegate = self;
                            receiveBubble.ordering = ordering;
                            if ([dict objectForKey:@"fromName"]) {
                                receiveBubble.avatar_name = [dict objectForKey:@"fromName"];
                            }else{
                                receiveBubble.avatar_name =  abbreviationName;
                            }
                            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                            [bubbleData addObject:receiveBubble];
                        }
                    }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
                        NSString *docUrl = [dict objectForKey:@"pdfUrl"];
                        
                        chatHistory.fileUrl = docUrl;
                        
                        if ([currentUserID integerValue] == [[dict objectForKey:@"from"] integerValue]) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeMine];
                            //sayBubble.avatar_url = [NSURL URLWithString:APPDELEGATE.profileUrl];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                            
                            if ([isRead integerValue] == 0) {
                                [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                            }
                        }else{
                            NSBubbleData *receiveBubble = [NSBubbleData dataWithDocs:docUrl withRemoteUrl:docUrl date:dateFromString type:BubbleTypeSomeoneElse];
                            receiveBubble.avatar_url = nil;
                            receiveBubble.delegate = self;
                            receiveBubble.ordering = ordering;
                            if ([dict objectForKey:@"fromName"]) {
                                receiveBubble.avatar_name = [dict objectForKey:@"fromName"];
                            }else{
                                receiveBubble.avatar_name =  abbreviationName;
                            }
                            receiveBubble.friendID = [NSNumber numberWithInteger:[friendID integerValue]];
                            [bubbleData addObject:receiveBubble];
                        }
                        
                    }
                    
                    
                    if ([isRead integerValue] == 0  && [AppDelegate sharedDelegate].isShownChatBoard == YES && [boardIDToCheck integerValue] == [boardID integerValue] && [currentUserID integerValue] != [[dict objectForKey:@"from"] integerValue]) {
                        chatHistory.isRead = @1;
                    }
                    if (chatHistory.message == nil) {
                        chatHistory.message = @"";
                    }
                    if (chatHistory.fileUrl == nil) {
                        chatHistory.fileUrl = @"";
                    }
                    if (chatHistory.thumbImageSize == nil) {
                        chatHistory.thumbImageSize = @"";
                    }
                    if (chatHistory.thumbUrl == nil) {
                        chatHistory.thumbUrl = @"";
                    }
                    
                    [context save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                    [self sendMessageHistoryToServer:chatHistory];
                    
                    //delete current message from firebase
                    [self performSelector:@selector(deleteChatHistoryOnFireBase:) withObject:snapshot.key afterDelay:1.0f];
                    
                    
                    
                    [bubbleTableView reloadData];
                    [self scrollToBottom:YES];
                    
                    
                } else if (objects.count == 1){
                    
                }else{
                }
                [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
            });
        }
                                    withCancelBlock:^(NSError *error){
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                                        });
                                        NSLog(@"%@", error.description);
                                    }];
    }
    
    
    
    
    rootRForBanner =[[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%d" ,99999]];
    
    [[rootRForBanner queryOrderedByKey] removeAllObservers];
    [[rootRForBanner queryOrderedByKey] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            NSDictionary *dict = snapshot.value;
            
            NSNumber *boardIDToCheck = [dict objectForKey:@"boardID"];
            NSNumber *messageIDToCheck = [dict objectForKey:@"message_id"];
            NSNumber *userIDToUpdate = [dict objectForKey:@"from"];
            NSNumber *targetIDToUpdate = [dict objectForKey:@"to"];
            NSNumber *ordering = [dict objectForKey:@"ordering"];
            NSString *messageType = [dict objectForKey:@"type"];
            NSString *dateString = [dict objectForKey:@"sentTime"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSDate *utcdate = [formatter dateFromString:dateString];
            
            [formatter setTimeZone:[NSTimeZone localTimeZone]];
            NSDate *dateFromString = [formatter dateFromString:[formatter stringFromDate:utcdate]];
            NSNumber *isRead = [dict objectForKey:@"isRead"];
            
            if (!isGeneralBanner) {
                [topbannerTextView removeFromSuperview];
                [topBannerImage removeFromSuperview];
                [jsAnimatedView removeFromSuperview];
                
                [[AppDelegate sharedDelegate].bannerDetails setObject:[dict objectForKey:@"type"] forKey:@"type"];
                if ([messageType isEqualToString:@"bannerForText"]) {
                    NSArray *parseBannercolorArray = [[dict objectForKey:@"bannerColor"] componentsSeparatedByString:@":"];
                    float redColor = [parseBannercolorArray[0] floatValue];
                    float greenColor = [parseBannercolorArray[1] floatValue];
                    float blueColor = [parseBannercolorArray[2] floatValue];
                    topbannerTextView.backgroundColor = [UIColor colorWithRed:redColor/255.0f green:greenColor/255.0f blue:blueColor/255.0f alpha:1.0f];
                    
                    [[AppDelegate sharedDelegate].bannerDetails setObject:[dict objectForKey:@"bannerColor"] forKey:@"bgColor"];
                    [[AppDelegate sharedDelegate].bannerDetails setObject:[dict objectForKey:@"message"] forKey:@"message"];
                    NSArray *parseBannerTextArray = [[dict objectForKey:@"message"] componentsSeparatedByString:@"#!#!#"];
                    NSString *largeTxt = @"";
                    NSString *mediumTxt = @"";
                    NSString *smallTxt = @"";
                    
                    if (parseBannerTextArray.count == 3) {
                        largeTxt = parseBannerTextArray[0];
                        mediumTxt = parseBannerTextArray[1];
                        smallTxt = parseBannerTextArray[2];
                    }else if (parseBannerTextArray.count == 2) {
                        largeTxt = parseBannerTextArray[0];
                        mediumTxt = parseBannerTextArray[1];
                    }else if (parseBannerTextArray.count == 1) {
                        largeTxt = parseBannerTextArray[0];
                    }
                    topLblLarge.text = largeTxt;
                    topLblMedium.text = mediumTxt;
                    topLblsmall.text = smallTxt;
                    [banerViewForUsers addSubview:topbannerTextView];
                    
                }else if ([messageType isEqualToString:@"bannerForImage"]) {
                    [[AppDelegate sharedDelegate].bannerDetails setObject:[dict objectForKey:@"imageUrl"] forKey:@"thumbURL"];
                    NSString *imageUrl = [dict objectForKey:@"imageUrl"];
                    [topBannerImage setImageWithURL:[NSURL URLWithString:imageUrl]];
                    [banerViewForUsers addSubview:topBannerImage];
                }else if ([messageType isEqualToString:@"bannerForGif"]) {
                    [[AppDelegate sharedDelegate].bannerDetails setObject:[dict objectForKey:@"imageUrl"] forKey:@"thumbURL"];
                    NSString *imageUrl = [dict objectForKey:@"imageUrl"];
                    jsAnimatedView = [[JSAnimatedView alloc] initWithFrameWithAnimatedImage:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
                    [jsAnimatedView prepareForReuse];
                    [jsAnimatedView setImageWithURL:[NSURL URLWithString:[imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                    
                    [banerViewForUsers addSubview:jsAnimatedView];
                }
            }else{
                
                
                NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:entityDesc];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageID == %@", messageIDToCheck];
                [request setPredicate:predicate];
                NSError *error;
                NSArray *objects = [context executeFetchRequest:request error:&error];
                
                ChatHistory *chatHistory = nil;
                if (objects == nil) {
                    FDLogError(@"Unable to retrieve Board!");
                } else if (objects.count == 0) {
                    chatHistory = [NSEntityDescription insertNewObjectForEntityForName:@"ChatHistory" inManagedObjectContext:context];
                    chatHistory.boardID = boardID;
                    chatHistory.messageID = messageIDToCheck;
                    chatHistory.userID = userIDToUpdate;
                    chatHistory.target_userID = targetIDToUpdate;
                    chatHistory.type = messageType;
                    chatHistory.sentTime = dateString;
                    chatHistory.searchKey = snapshot.key;
                    chatHistory.isRead = isRead;
                    chatHistory.lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    chatHistory.lastUpdate = @(0);
                    chatHistory.history_id = @(0);
                    chatHistory.ordering = ordering;
                    
                    if ([dict objectForKey:@"fromName"]) {
                        chatHistory.targetName = [dict objectForKey:@"fromName"];
                    }
                    
                    //play soundlpo
                    if ([isRead integerValue] == 0) {
                        if ([currentUserID integerValue] == [userIDToUpdate integerValue]) {
                            [[AppDelegate sharedDelegate] playingAndStopForMessageToSend];
                        }else{
                            [[AppDelegate sharedDelegate] playingAndStopForMessageToBeArrived];
                        }
                    }
                    
                    
                    if ([messageType isEqualToString:@"bannerForText"]) {
                        chatHistory.message = [dict objectForKey:@"message"];
                        //use for color
                        chatHistory.fileUrl = [dict objectForKey:@"bannerColor"];
                        if (isGeneralBanner) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithBannerText:[dict objectForKey:@"message"] withBGColor:[dict objectForKey:@"bannerColor"] date:dateFromString type:BubbleTypeMine];
                            sayBubble.messageID = messageIDToCheck;
                            sayBubble.ordering = ordering;
                            sayBubble.avatar_name = @"ME";
                            sayBubble.delegate = self;
                            sayBubble.isGeneralBanner = isGeneralBanner;
                            [bubbleData addObject:sayBubble];
                        }
                        
                        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                            [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                        }
                    }else if ([messageType isEqualToString:@"bannerForImage"]) {
                        NSString *imageUrl = [dict objectForKey:@"imageUrl"];
                        NSString *imageSizeToParse = [dict objectForKey:@"imageSize"];
                        NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
                        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
                        
                        chatHistory.thumbUrl = imageUrl;
                        chatHistory.thumbImageSize = imageSizeToParse;
                        
                        if (isGeneralBanner) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:YES isGIF:NO];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.isGeneralBanner = isGeneralBanner;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                        }
                        
                        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                            [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                        }
                    }else if ([messageType isEqualToString:@"bannerForGif"]) {
                        NSString *imageUrl = [dict objectForKey:@"imageUrl"];
                        NSString *imageSizeToParse = [dict objectForKey:@"imageSize"];
                        NSArray *arraySizeToBeParsed = [imageSizeToParse componentsSeparatedByString:@":"];
                        CGFloat imageWidth = [arraySizeToBeParsed[0] floatValue];
                        CGFloat imageHeight = [arraySizeToBeParsed[1] floatValue];
                        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
                        
                        chatHistory.thumbUrl = imageUrl;
                        chatHistory.thumbImageSize = imageSizeToParse;
                        
                        if (isGeneralBanner) {
                            NSBubbleData *sayBubble = [NSBubbleData dataWithImageUrl:imageUrl date:dateFromString type:BubbleTypeMine withImageSize:imageSize withBanner:YES isGIF:YES];
                            sayBubble.delegate = self;
                            sayBubble.ordering = ordering;
                            sayBubble.isGeneralBanner = isGeneralBanner;
                            sayBubble.avatar_name = @"ME";
                            [bubbleData addObject:sayBubble];
                        }
                        
                        if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                            [self sendPushNotificationToUser:dict withSearchKey:snapshot.key];
                        }
                    }
                    
                    if ([isRead integerValue] == 0  && [AppDelegate sharedDelegate].isShownChatBoard == YES && [boardIDToCheck integerValue] == [boardID integerValue] && [currentUserID integerValue] != [[dict objectForKey:@"from"] integerValue]) {
                        chatHistory.isRead = @1;
                    }
                    if (chatHistory.message == nil) {
                        chatHistory.message = @"";
                    }
                    if (chatHistory.fileUrl == nil) {
                        chatHistory.fileUrl = @"";
                    }
                    if (chatHistory.thumbImageSize == nil) {
                        chatHistory.thumbImageSize = @"";
                    }
                    if (chatHistory.thumbUrl == nil) {
                        chatHistory.thumbUrl = @"";
                    }
                    
                    if ([boardID integerValue] != 999999 || [boardID integerValue] != 99999) {
                        [context save:&error];
                        if (error) {
                            NSLog(@"Error when saving managed object context : %@", error);
                        }
                        
                        [self sendMessageHistoryToServer:chatHistory];
                    }else{
                        [context deleteObject:chatHistory];
                        [self sendMessageHistoryToServerForAdmin:dict];
                    }
                    
                    //delete current message from firebase
                    [self performSelector:@selector(deleteChatHistoryOnFireBase:) withObject:snapshot.key afterDelay:1.0f];
                    
                    
                    
                    [bubbleTableView reloadData];
                    [self scrollToBottom:YES];
                    
                    
                } else if (objects.count == 1){
                    
                }else{
                }
                [[AppDelegate sharedDelegate] getChattingMessageUnreadCount];
            }
            
        });
    }
                                withCancelBlock:^(NSError *error){
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                    });
                                    NSLog(@"%@", error.description);
                                }];
}
- (void)deleteChatHistoryOnFireBase:(id)searchKey{
    
    rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
    FIRDatabaseReference *rootRForResgiter = [rootR child:searchKey];
    [rootRForResgiter removeValue];
}
- (void)sendMessageHistoryToServerForAdmin:(NSDictionary *)dict{
    NSError *error;
    NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
    NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable to save lesson records until logged in!");
        return;
    }
    NSNumber *messageIDToCheck = [dict objectForKey:@"message_id"];
    NSNumber *userIDToUpdate = [dict objectForKey:@"from"];
    NSNumber *targetIDToUpdate = [dict objectForKey:@"to"];
    NSNumber *ordering = [dict objectForKey:@"ordering"];
    NSString *messageType = [dict objectForKey:@"type"];
    NSString *dateString = [dict objectForKey:@"sentTime"];
    NSString *targetName = @"";
    if ([dict objectForKey:@"fromName"]) {
        targetName = [dict objectForKey:@"fromName"];
    }
    
    NSMutableArray *chathistories = [[NSMutableArray alloc] init];
    NSNumber *lastSync = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    
    if ([messageType isEqualToString:@"text"]) {
        
        NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:@0, boardID, messageType, @"", @1, [dict objectForKey:@"message"], messageIDToCheck, dateString, targetIDToUpdate, targetName, @"", @"", userIDToUpdate, lastSync, lastSync, ordering, nil];
        [chathistories addObject:chathistoryArray];
        
    }else if ([messageType isEqualToString:@"image"]) {
        NSString *imageUrl = [dict objectForKey:@"imageUrl"];
        NSString *imageSizeToParse = [dict objectForKey:@"imageSize"];
        
        NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:@0, boardID, messageType, @"", @1, @"", messageIDToCheck, dateString, targetIDToUpdate, targetName, imageSizeToParse, imageUrl, userIDToUpdate, lastSync, lastSync, ordering, nil];
        [chathistories addObject:chathistoryArray];
        
    }else if ([messageType isEqualToString:@"video"]) {
        NSString *videoUrl = [dict objectForKey:@"videoUrl"];
        NSString *thumbUrl = [dict objectForKey:@"thumbUrl"];
        NSString *thumbImageSizeToParse = [dict objectForKey:@"thumbImageSize"];
        
        NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:@0, boardID, messageType, videoUrl, @1, @"", messageIDToCheck, dateString, targetIDToUpdate, targetName, thumbImageSizeToParse, thumbUrl, userIDToUpdate, lastSync, lastSync, ordering, nil];
        [chathistories addObject:chathistoryArray];
    }else if ([messageType isEqualToString:@"pdf"]) {
        NSString *pdfUrl = [dict objectForKey:@"pdfUrl"];
        NSString *thumbUrl = [dict objectForKey:@"thumbUrl"];
        NSString *thumbImageSizeToParse = [dict objectForKey:@"thumbImageSize"];
        
        NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:@0, boardID, messageType, pdfUrl, @1, @"", messageIDToCheck, dateString, targetIDToUpdate, targetName, thumbImageSizeToParse, thumbUrl, userIDToUpdate, lastSync, lastSync, ordering, nil];
        [chathistories addObject:chathistoryArray];
        
    }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
        NSString *docUrl = [dict objectForKey:@"pdfUrl"];
        
        NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:@0, boardID, messageType, docUrl, @1, @"", messageIDToCheck, dateString, targetIDToUpdate, targetName, @"", @"", userIDToUpdate, lastSync, lastSync, ordering, nil];
        [chathistories addObject:chathistoryArray];
        
    }
    
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_chathistory", @"action", userID, @"user_id", chathistories, @"histories", nil];
    NSData *chatHistoriesJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [saveLessonsRequest setHTTPMethod:@"POST"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)chatHistoriesJSON.length] forHTTPHeaderField:@"Content-Length"];
    [saveLessonsRequest setHTTPBody:chatHistoriesJSON];
    //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
    //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *uploadChatHistoryTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            
        } else {
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while uploading lesson records";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [uploadChatHistoryTask resume];
}
- (void)sendMessageHistoryToServer:(ChatHistory *)chathistory{
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastUpdate == 0"];
    [request setPredicate:predicate];
    NSArray *fetchedChatHistories = [context executeFetchRequest:request error:&error];
    if (fetchedChatHistories.count > 0) {
        // make sure we are logged in
        NSString *userIdStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"userId"];
        NSNumber *userID = [NSNumber numberWithInteger:[userIdStr integerValue]];
        if (userID == nil) {
            FDLogError(@"Unable to save lesson records until logged in!");
            return;
        }
        NSMutableArray *chathistories = [[NSMutableArray alloc] init];
        // array of NSManagedObjectIDs for crossing thread boundaries
        NSMutableArray *fetchedChathistoryIDs = [[NSMutableArray alloc] init];
        for (ChatHistory *chathistory in fetchedChatHistories) {
            NSArray *chathistoryArray = [[NSArray alloc] initWithObjects:chathistory.history_id, chathistory.boardID, chathistory.type, chathistory.fileUrl, chathistory.isRead, chathistory.message, chathistory.messageID, chathistory.sentTime, chathistory.target_userID, chathistory.targetName, chathistory.thumbImageSize, chathistory.thumbUrl, chathistory.userID, chathistory.lastSync, chathistory.lastUpdate, chathistory.ordering, nil];
            [chathistories addObject:chathistoryArray];
            [fetchedChathistoryIDs addObject:[chathistory objectID]];
        }
        NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"save_chathistory", @"action", userID, @"user_id", chathistories, @"histories", nil];
        NSData *chatHistoriesJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
        NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
        [saveLessonsRequest setHTTPMethod:@"POST"];
        [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [saveLessonsRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [saveLessonsRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)chatHistoriesJSON.length] forHTTPHeaderField:@"Content-Length"];
        [saveLessonsRequest setHTTPBody:chatHistoriesJSON];
        //NSString *jsonStrData = [[NSString alloc] initWithData:lessonRecordsJSON encoding:NSUTF8StringEncoding];
        //FDLogDebug(@"Uploading the lesson records! JSON '%@'", jsonStrData);
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *uploadChatHistoryTask = [session dataTaskWithRequest:saveLessonsRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
            // handle the documents update
            if (data != nil) {
                [self handleUploadChathistoriesResults:data AndRecordIDs:fetchedChathistoryIDs contextForChatHistory:context];
            } else {
                NSString *errorText;
                if (responseError != nil) {
                    errorText = [responseError localizedDescription];
                } else {
                    errorText = @"An unknown error occurred while uploading lesson records";
                }
                FDLogError(@"%@", errorText);
            }
        }];
        [uploadChatHistoryTask resume];
    } else {
    }
}
- (void)handleUploadChathistoriesResults:(NSData *)results AndRecordIDs:(NSArray *)chathistoryIDs contextForChatHistory:(NSManagedObjectContext *)_contextChathistory{
    NSError *error;
    NSDictionary *chathistoryResults = [NSJSONSerialization JSONObjectWithData:results options:0 error:&error];
    if (error != nil) {
        NSString *jsonStrData = [[NSString alloc] initWithData:results encoding:NSUTF8StringEncoding];
        FDLogError(@"Unable to parse JSON for chathistory data: %@\nText: %@\n\n", error, jsonStrData);
        return;
    }
    id value = [chathistoryResults objectForKey:@"histories"];
    if ([value isKindOfClass:[NSArray class]] == NO) {
        FDLogError(@"Encountered unexpected chathistory results element which was not an array!");
        return;
    }
    NSArray *chathistoryResultsArray = value;
    
    int chatHistoryIndex = 0;
    for (id chatHistoryResultElement in chathistoryResultsArray) {
        if ([chatHistoryResultElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *chatHistoryResultFields = chatHistoryResultElement;
            NSNumber *resultBool = [chatHistoryResultFields objectForKey:@"success"];
            NSNumber *recordID = [chatHistoryResultFields objectForKey:@"record_id"];
            NSNumber *timestamp = [chatHistoryResultFields objectForKey:@"timestamp"];
            if (chatHistoryIndex < [chathistoryIDs count]) {
                NSManagedObjectID *aircraftID = [chathistoryIDs objectAtIndex:chatHistoryIndex];
                ChatHistory *chathistory = [_contextChathistory existingObjectWithID:aircraftID error:&error];
                if ([resultBool boolValue] == YES) {
                    chathistory.lastUpdate = timestamp;
                    // insert/update succeeded, save record id
                    if (chathistory.history_id == nil || [chathistory.history_id integerValue] == 0) {
                        
                        NSNumber *ordering = [chatHistoryResultFields objectForKey:@"ordering"];
                        chathistory.history_id = recordID;
                        chathistory.ordering = ordering;
                    } else if ([chathistory.history_id intValue] != [recordID intValue]) {
                        
                    }
                } else {
                    
                }
            } else {
                
            }
        }
        chatHistoryIndex += 1;
    }
    
    if ([_contextChathistory hasChanges]) {
        [_contextChathistory save:&error];
    }
}

-(void)showAlert:(NSString*)msg :(NSString*)title
{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)handleTap
{
    [self.view endEditing:YES];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[rootR queryOrderedByKey] removeAllObservers];
}

- (void)deviceOrientationDidChange{
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    [self addAndOrientationWithbannerView];
    [self setNavigationColorWithGradiant];
    if (dashboardView != nil) {
        [dashboardView setFrame:[[UIScreen mainScreen] bounds]];
        CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
        if (currentScreenRect.size.height<currentScreenRect.size.width) {
            [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
        }else{
            [dashboardView setContentSize:CGSizeMake(0,0)];
        }
        [dashboardView reloadViewsWithCurrentScreen];
    }
    [bubbleTableView reloadData];
}
- (void)addAndOrientationWithbannerView{
    if ([AppDelegate sharedDelegate].bannerDetails != nil && [[AppDelegate sharedDelegate].bannerDetails objectForKey:@"type"] != nil && !isGeneralBanner) {
        NSString *type = [[AppDelegate sharedDelegate].bannerDetails objectForKey:@"type"];
        NSString *bgColorStr = [[AppDelegate sharedDelegate].bannerDetails objectForKey:@"bgColor"];
        NSString *message = [[AppDelegate sharedDelegate].bannerDetails objectForKey:@"message"];
        NSString *thumbURL = [[AppDelegate sharedDelegate].bannerDetails objectForKey:@"thumbURL"];
        
        [topbannerTextView removeFromSuperview];
        [topBannerImage removeFromSuperview];
        [jsAnimatedView removeFromSuperview];
        
        if ([type isEqualToString:@"bannerForText"]) {
            NSArray *parseBannerTextArray = [message componentsSeparatedByString:@"#!#!#"];
            NSString *largeTxt = @"";
            NSString *mediumTxt = @"";
            NSString *smallTxt = @"";
            if (parseBannerTextArray.count == 3) {
                largeTxt = parseBannerTextArray[0];
                mediumTxt = parseBannerTextArray[1];
                smallTxt = parseBannerTextArray[2];
            }else if (parseBannerTextArray.count == 2) {
                largeTxt = parseBannerTextArray[0];
                mediumTxt = parseBannerTextArray[1];
            }else if (parseBannerTextArray.count == 1) {
                largeTxt = parseBannerTextArray[0];
            }
            topLblLarge.text = largeTxt;
            topLblMedium.text = mediumTxt;
            topLblsmall.text = smallTxt;
            
            NSArray *parseBannercolorArray = [bgColorStr componentsSeparatedByString:@":"];
            float redColor = [parseBannercolorArray[0] floatValue];
            float greenColor = [parseBannercolorArray[1] floatValue];
            float blueColor = [parseBannercolorArray[2] floatValue];
            topbannerTextView.backgroundColor = [UIColor colorWithRed:redColor/255.0f green:greenColor/255.0f blue:blueColor/255.0f alpha:1.0f];
            
            [topbannerTextView setFrame:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
            [banerViewForUsers addSubview:topbannerTextView];
        }else if ([type isEqualToString:@"bannerForImage"]) {
            [topBannerImage setImageWithURL:[NSURL URLWithString:thumbURL]];
            [topBannerImage setFrame:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
            [banerViewForUsers addSubview:topBannerImage];
        }else if ([type isEqualToString:@"bannerForGif"]) {
           
            jsAnimatedView = [[JSAnimatedView alloc] initWithFrameWithAnimatedImage:CGRectMake(0, 0, self.view.frame.size.width, banerViewForUsers.frame.size.height)];
            [jsAnimatedView prepareForReuse];
            [jsAnimatedView setImageWithURL:[NSURL URLWithString:[thumbURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
            [banerViewForUsers addSubview:jsAnimatedView];
        }
    }
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    
    NSDictionary* userInfo = [aNotification userInfo];
    CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    if(!keyboardShown)
    {
        CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    }
    if (isGeneralBanner) {
        keyboardConsForBanerView.constant = kbSize.height;
        keyboardHegith.constant = kbSize.height + 225.0f;
    }else{
        keyboardHegith.constant = kbSize.height;
    }
    [self.view layoutIfNeeded];
    
    if(!keyboardShown)
        [UIView commitAnimations];
    
    keyboardShown = YES;
    [self scrollToBottom : YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    keyboardShown = NO;
    
    NSDictionary *userInfo = [aNotification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    if (isGeneralBanner) {
        keyboardConsForBanerView.constant = 50.0f;
        keyboardHegith.constant = 275.0f;
    }else{
        keyboardHegith.constant = 50.0f;
    }
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}
//
-(void)scrollToBottom : (BOOL)_animated
{
    CGFloat yoffset = 64;
    if (bubbleTableView.contentSize.height > bubbleTableView.bounds.size.height) {
        yoffset = bubbleTableView.contentSize.height - bubbleTableView.bounds.size.height + 64.0f;
        [bubbleTableView setContentOffset:CGPointMake(0, yoffset) animated:_animated];
    }
    
}

#pragma mark - UIBubbleTableViewDelegate
- (void)scrollViewDidScrollWithBubble:(UIBubbleTableView *)_table ScrView:(UIScrollView *)_scrView
{

}
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
}

- (IBAction)onClearGeneral:(id)sender {
    [self.view endEditing:YES];
    NSString *message = @"";
    if (isGeneralBanner) {
        message = @"Are you sure to clear all banner?";
    }
    if (isGeneralRoom) {
        message = @"Are you sure to clear all Messages?";
    }
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        if (isGeneralBanner) {
            [self clearAllGeneralBanner];
        }
        if (isGeneralRoom) {
            [self clearAllGeneralMessages];
        }
    }];
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
    }];
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearAllGeneralBanner{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Clearing Banners…";
    
    [AppDelegate sharedDelegate].bannerDetails = nil;
    [topbannerTextView removeFromSuperview];
    [topBannerImage removeFromSuperview];
    [jsAnimatedView removeFromSuperview];
    
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"clear_all_generalbanners", @"action", currentUserID, @"user_id", nil];
    NSData *getChatHistoryJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *getChatHistoryRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [getChatHistoryRequest setHTTPMethod:@"POST"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [getChatHistoryRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)getChatHistoryJSON.length] forHTTPHeaderField:@"Content-Length"];
    [getChatHistoryRequest setHTTPBody:getChatHistoryJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *clearGeneralBannerTask = [session dataTaskWithRequest:getChatHistoryRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        // handle the documents update
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                [self showAlert:@"Failed!" :@"FlightDesk"];
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                [self showAlert:@"Cleared successfully" :@"FlightDesk"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [bubbleData removeAllObjects];
                    [bubbleTableView reloadData];
                });
            }else{
                [self showAlert:@"Failed!" :@"FlightDesk"];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self showAlert:@"Failed!" :@"FlightDesk"];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while getting chathistories";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [clearGeneralBannerTask resume];
}

- (void)clearAllGeneralMessages{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Clearing Messages…";
    
    //clear messages on local
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ChatHistory" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"boardID == 999999"];
    [request setPredicate:predicate];
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        FDLogError(@"Unable to retrieve Board!");
    } else if (objects.count == 0) {
        FDLogDebug(@"No valid Board found!");
    } else {
        for (ChatHistory *chatHistoryToDelete in objects) {
            [context deleteObject:chatHistoryToDelete];
        }
    }
    [context save:&error];
    
    //clear messages on server
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"clear_all_generalmessages", @"action", currentUserID, @"user_id", nil];
    NSData *clearGeneralMessagesJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *getChatHistoryRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [getChatHistoryRequest setHTTPMethod:@"POST"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [getChatHistoryRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [getChatHistoryRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)clearGeneralMessagesJSON.length] forHTTPHeaderField:@"Content-Length"];
    [getChatHistoryRequest setHTTPBody:clearGeneralMessagesJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *clearAllGeneralMessageTask = [session dataTaskWithRequest:getChatHistoryRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
        
        // handle the documents update
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            NSError *error;
            // parse the query results
            NSDictionary *queryResults = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                [self showAlert:@"Failed!" :@"FlightDesk"];
                return;
            }
            if ([[queryResults objectForKey:@"success"] boolValue]) {
                [self showAlert:@"Cleared successfully" :@"FlightDesk"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [bubbleData removeAllObjects];
                    [bubbleTableView reloadData];
                });
            }else{
                [self showAlert:@"Failed!" :@"FlightDesk"];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [self showAlert:@"Failed!" :@"FlightDesk"];
            });
            NSString *errorText;
            if (responseError != nil) {
                errorText = [responseError localizedDescription];
            } else {
                errorText = @"An unknown error occurred while getting chathistories";
            }
            FDLogError(@"%@", errorText);
        }
    }];
    [clearAllGeneralMessageTask resume];
}

- (IBAction)onChangeBgColor:(id)sender {
    UIViewController *vc = [[UIViewController alloc] init];
    UIView *viewToChangeColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    
    delegateOfREGColorSilder = [[RGBColorSliderDelegate alloc] init];
    delegateOfREGColorSilder.delegate = self;
    
    RGBColorSlider *redSlider = [[RGBColorSlider alloc] initWithFrame:CGRectMake(20, 20, 280, 44) sliderColor:RGBColorTypeRed trackHeight:6 delegate:delegateOfREGColorSilder];
    RGBColorSlider *greenSlider = [[RGBColorSlider alloc] initWithFrame:CGRectMake(20, 84, 280, 44) sliderColor:RGBColorTypeGreen trackHeight:6 delegate:delegateOfREGColorSilder];
    RGBColorSlider *blueSlider = [[RGBColorSlider alloc] initWithFrame:CGRectMake(20, 148, 280, 44) sliderColor:RGBColorTypeBlue trackHeight:6 delegate:delegateOfREGColorSilder];
    [redSlider setValue:1.0f];
    [greenSlider setValue:1.0f];
    [blueSlider setValue:1.0f];
    [viewToChangeColor addSubview:redSlider];
    [viewToChangeColor addSubview:greenSlider];
    [viewToChangeColor addSubview:blueSlider];
    
    vc.view = viewToChangeColor;
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:vc];
    [popoverController setPopoverContentSize:CGSizeMake(320,200) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}




- (void)updateColor:(UIColor *)color
{
    coverViewOfTextBanner.backgroundColor = color;
    redValue = [delegateOfREGColorSilder getRedColorComponent]*255;
    greenValue = [delegateOfREGColorSilder getGreenColorComponent]*255;
    blueValue = [delegateOfREGColorSilder getBlueColorComponent]*255;
    
    NSLog(@"R : %ld G : %ld B : %ld", (long)redValue, (long)greenValue, (long)blueValue);
}
- (IBAction)onMessageSend:(id)sender {
    if (!txtMessage.text.length)
    {
        return;
    }
    NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
    [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
    [chatInfoForPost setValue:[NSNumber numberWithInteger:[currentUserID integerValue]] forKey:@"from"];
    [chatInfoForPost setValue:@"text" forKey:@"type"];
    [chatInfoForPost setValue:txtMessage.text forKey:@"message"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    NSString *stringDate = [formatter stringFromDate:[NSDate date]];
    [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
    
    [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
    [chatInfoForPost setValue:@0 forKey:@"isRead"];
    [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
    [chatInfoForPost setValue:boardID forKey:@"boardID"];
    [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
    
    rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
    FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
    [rootRForResgiter setValue:chatInfoForPost];
    [self getBadgeCountOfUserFromServer];
    txtMessage.text = @"";
    
}
- (void)updateBadgeCountOfUserFromServer{
    if ([friendID integerValue] <= 0)
    {
        return;
    }
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"updateBadgeCountWithNewMessage", @"action", [NSNumber numberWithInteger:[friendID integerValue]], @"user_id", nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
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
        }
    }];
    [uploadLessonRecordsTask resume];
}

- (void)getBadgeCountOfUserFromServer{
    if ([friendID integerValue] <= 0)
    {
        return;
    }
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"getBadgeCount", @"action", [NSNumber numberWithInteger:[friendID integerValue]], @"user_id", nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    badgeCountOfUser = [queryResults objectForKey:@"all_badgecount"];
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
        }
    }];
    [uploadLessonRecordsTask resume];
}
- (NSString *)getDeviceTokenOfUserFromLocal{
    NSError *error;
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"student"]) {
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"instructorID == %@", friendID];
        [request setPredicate:predicate];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve LessonGroups!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid LessonGroup found!");
        } else {
            LessonGroup *lessongroup = objects[0];
            return lessongroup.instructorDeviceToken;
        }
    }else if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]){
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
        // load the remaining lesson groups
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", friendID];
        [request setPredicate:predicate];
        NSArray *objects = [context executeFetchRequest:request error:&error];
        if (objects == nil) {
            FDLogError(@"Unable to retrieve students!");
        } else if (objects.count == 0) {
            FDLogDebug(@"No valid students found!");
        } else {
            Student *student = objects[0];
            return student.deviceToken;
        }
    }
    
    return @"";
}
- (void)sendPushNotificationToUser:(NSDictionary *)pushDict withSearchKey:(NSString *)searchKey{
    if ([friendID integerValue] == 999999) {
        [[AppDelegate sharedDelegate] getDeviceTokenOfSupport];
    }
    if ([boardID integerValue] == 999999) {
        if (arrayAvailDeviceTokenForAdmin.count > 0) {
            NSMutableDictionary *dicToSendPush = [[NSMutableDictionary alloc] init];
            [dicToSendPush setObject:searchKey forKey:@"seachKey"];
            [dicToSendPush setObject:[pushDict objectForKey:@"message_id"] forKey:@"message_id"];
            [dicToSendPush setObject:[pushDict objectForKey:@"sentTime"] forKey:@"lastupdate"];
            [dicToSendPush setObject:currentUserID forKey:@"sent_user_id"];
            
            if ([pushDict objectForKey:@"fromName"]) {
                [dicToSendPush setObject:[pushDict objectForKey:@"fromName"] forKey:@"fromName"];
            }
            
            NSString *messageType = [pushDict objectForKey:@"type"];
            if ([messageType isEqualToString:@"text"]) {
                
                [dicToSendPush setObject:@"text" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"message"] forKey:@"message"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName, [pushDict objectForKey:@"message"]] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"image"]) {
                
                [dicToSendPush setObject:@"image" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent image to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"video"]) {
                
                [dicToSendPush setObject:@"video" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"videoUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbImageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent video to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"pdf"]) {
                
                [dicToSendPush setObject:@"pdf" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"pdfUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbImageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent pdf to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
                
                [dicToSendPush setObject:@"doc" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"pdfUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent file to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }
            
            [dicToSendPush setObject:@"chat" forKey:@"pushType"];
            [dicToSendPush setObject:@"" forKey:@"title"];
            [dicToSendPush setObject:@"default" forKey:@"sound"];
            [dicToSendPush setObject:boardID forKey:@"boardID"];
            
            for (NSDictionary *oneUser in arrayAvailDeviceTokenForAdmin) {
                NSString *deviceTokenFrom = [oneUser objectForKey:@"device_token"];
                NSError *error;
                NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:deviceTokenFrom, @"to", dicToSendPush, @"notification", nil];
                NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
                NSString *apiURLString = @"https://fcm.googleapis.com/fcm/send";
                NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
                NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
                [saveLessonsRequest setHTTPMethod:@"POST"];
                [saveLessonsRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [saveLessonsRequest setValue:@"key=AAAALU8yQXs:APA91bGpmsPOYmhm7IyldmsgDSAedCMjxvEOEYN_0zzSecQn67ZUWTdZ_3PlUY-CPlfqPkFzvZHmlzh2XeguVbrxLo7h7OOtQdodWipTdhvv44-AMVpKxz1EKFP0aTW0WTD52TSEcX9e" forHTTPHeaderField:@"Authorization"];
                [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
                
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
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //NSLog(@"success");
                            });
                            
                        }else{
                            //FDLogError(@"failed to update deivce token");
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
                [uploadLessonRecordsTask resume];
            }
            
        }

    }else if ([boardID integerValue] == 99999) {
        if (arrayAvailDeviceTokenForAdmin.count > 0) {
            NSMutableDictionary *dicToSendPush = [[NSMutableDictionary alloc] init];
            [dicToSendPush setObject:searchKey forKey:@"seachKey"];
            [dicToSendPush setObject:[pushDict objectForKey:@"message_id"] forKey:@"message_id"];
            [dicToSendPush setObject:[pushDict objectForKey:@"sentTime"] forKey:@"lastupdate"];
            [dicToSendPush setObject:currentUserID forKey:@"sent_user_id"];
            
            if ([pushDict objectForKey:@"fromName"]) {
                [dicToSendPush setObject:[pushDict objectForKey:@"fromName"] forKey:@"fromName"];
            }
            
            NSString *messageType = [pushDict objectForKey:@"type"];
            if ([messageType isEqualToString:@"bannerForText"]) {
                
                [dicToSendPush setObject:@"text" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"message"] forKey:@"message"];
                [dicToSendPush setObject:[pushDict objectForKey:@"bannerColor"] forKey:@"bannerColor"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent banner text to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"bannerForImage"]) {
                
                [dicToSendPush setObject:@"image" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent banner image to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"bannerForGif"]) {
                
                [dicToSendPush setObject:@"gifbanner" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent banner image to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }
            
            [dicToSendPush setObject:@"banner" forKey:@"pushType"];
            [dicToSendPush setObject:@"" forKey:@"title"];
            [dicToSendPush setObject:@"default" forKey:@"sound"];
            [dicToSendPush setObject:boardID forKey:@"boardID"];
            
            for (NSDictionary *oneUser in arrayAvailDeviceTokenForAdmin) {
                NSString *deviceTokenFrom = [oneUser objectForKey:@"device_token"];
                NSError *error;
                NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:deviceTokenFrom, @"to", dicToSendPush, @"notification", nil];
                NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
                NSString *apiURLString = @"https://fcm.googleapis.com/fcm/send";
                NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
                NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
                [saveLessonsRequest setHTTPMethod:@"POST"];
                [saveLessonsRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [saveLessonsRequest setValue:@"key=AAAALU8yQXs:APA91bGpmsPOYmhm7IyldmsgDSAedCMjxvEOEYN_0zzSecQn67ZUWTdZ_3PlUY-CPlfqPkFzvZHmlzh2XeguVbrxLo7h7OOtQdodWipTdhvv44-AMVpKxz1EKFP0aTW0WTD52TSEcX9e" forHTTPHeaderField:@"Authorization"];
                [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
                
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
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //NSLog(@"success");
                            });
                            
                        }else{
                            //FDLogError(@"failed to update deivce token");
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
                [uploadLessonRecordsTask resume];
            }
            
        }
    }else{
        if (deviceToken!= nil && ![deviceToken isEqualToString:@""] ) {
            NSMutableDictionary *dicToSendPush = [[NSMutableDictionary alloc] init];
            [dicToSendPush setObject:searchKey forKey:@"seachKey"];
            [dicToSendPush setObject:[pushDict objectForKey:@"message_id"] forKey:@"message_id"];
            [dicToSendPush setObject:[pushDict objectForKey:@"sentTime"] forKey:@"lastupdate"];
            [dicToSendPush setObject:currentUserID forKey:@"sent_user_id"];
            
            if ([pushDict objectForKey:@"fromName"]) {
                [dicToSendPush setObject:[pushDict objectForKey:@"fromName"] forKey:@"fromName"];
            }
            
            NSString *messageType = [pushDict objectForKey:@"type"];
            if ([messageType isEqualToString:@"text"]) {
                
                [dicToSendPush setObject:@"text" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"message"] forKey:@"message"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : %@", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName, [pushDict objectForKey:@"message"]] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"image"]) {
                
                [dicToSendPush setObject:@"image" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"imageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent image to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"video"]) {
                
                [dicToSendPush setObject:@"video" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"videoUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbImageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent video to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"pdf"]) {
                
                [dicToSendPush setObject:@"pdf" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"pdfUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbUrl"] forKey:@"thumbUrl"];
                [dicToSendPush setObject:[pushDict objectForKey:@"thumbImageSize"] forKey:@"thumbImageSize"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent pdf to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }else if ([messageType isEqualToString:@"doc"] || [messageType isEqualToString:@"ppt"]) {
                
                [dicToSendPush setObject:@"doc" forKey:@"messageType"];
                [dicToSendPush setObject:[pushDict objectForKey:@"pdfUrl"] forKey:@"fileUrl"];
                [dicToSendPush setObject:[NSString stringWithFormat:@"%@ %@ : sent file to you", [AppDelegate sharedDelegate].clientFirstName, [AppDelegate sharedDelegate].clientLastName] forKey:@"body"];
                
            }
            
            [dicToSendPush setObject:@"chat" forKey:@"pushType"];
            [dicToSendPush setObject:@"" forKey:@"title"];
            [dicToSendPush setObject:@"default" forKey:@"sound"];
            [dicToSendPush setObject:boardID forKey:@"boardID"];
            
            if (badgeCountOfUser == nil) {
                badgeCountOfUser = @1;
            }else{
                NSInteger tmpBadgeCount = [badgeCountOfUser integerValue];
                badgeCountOfUser = [NSNumber numberWithInteger:(tmpBadgeCount + 1)];
            }
            [self updateBadgeCountOfUserFromServer];
            [dicToSendPush setObject:badgeCountOfUser forKey:@"badge"];
            
            NSString *newDeviceToken = [self getDeviceTokenOfUserFromLocal];
            if (newDeviceToken != nil && ![newDeviceToken isEqualToString:@""]) {
                if (![newDeviceToken isEqualToString:deviceToken]) {
                    deviceToken = newDeviceToken;
                }
            }
            
            NSError *error;
            NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:deviceToken, @"to", dicToSendPush, @"notification", nil];
            NSData *lessonRecordsJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
            NSLog(@"Chat DeviceToken:%@", deviceToken);
            NSString *apiURLString = @"https://fcm.googleapis.com/fcm/send";
            NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
            NSMutableURLRequest *saveLessonsRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
            [saveLessonsRequest setHTTPMethod:@"POST"];
            [saveLessonsRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
            [saveLessonsRequest setValue:@"key=AAAALU8yQXs:APA91bGpmsPOYmhm7IyldmsgDSAedCMjxvEOEYN_0zzSecQn67ZUWTdZ_3PlUY-CPlfqPkFzvZHmlzh2XeguVbrxLo7h7OOtQdodWipTdhvv44-AMVpKxz1EKFP0aTW0WTD52TSEcX9e" forHTTPHeaderField:@"Authorization"];
            [saveLessonsRequest setHTTPBody:lessonRecordsJSON];
            
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
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //NSLog(@"success");
                        });
                    }else{
                        //FDLogError(@"failed to update deivce token");
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
            [uploadLessonRecordsTask resume];
        }else{
            
        }

    }
}

- (IBAction)onCamera:(id)sender {
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imgPicker.allowsEditing = YES;
    imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4, (NSString*)kUTTypeImage, (NSString*)kUTTypePNG, (NSString*)kUTTypeJPEG, (NSString*)kUTTypeJPEG2000, nil];
    imgPicker.delegate = self;
    [self presentViewController:imgPicker animated:YES completion:nil];
}

- (IBAction)onPhotoVideoLibrary:(id)sender {
    UIImagePickerController* imagePickerController= [[UIImagePickerController alloc] init];
    imagePickerController.delegate=self;
    imagePickerController.sourceType= UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    // This code ensures only videos are shown to the end user
    imagePickerController.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4, (NSString*)kUTTypeImage, (NSString*)kUTTypePNG, (NSString*)kUTTypeJPEG, (NSString*)kUTTypeJPEG2000];
    
    imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}
#pragma mark UIDocumentPickerDelgate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    NSString *fileName = [url lastPathComponent];
    if (isToGetBannerImage) {
        NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
        NSError* error = nil;
        NSURLResponse* response = nil;
        [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
        NSString* mimeType = [response MIMEType];
        NSArray *parseFileName = [mimeType componentsSeparatedByString:@"/"];
        if (parseFileName.count > 1) {
            NSString *lastString = parseFileName[parseFileName.count-1];
            NSInteger fileType = 0;
            //1: image, 2: video, 3: pdf, 4: doc, txt, 5: ppt
            if ([lastString.lowercaseString isEqualToString:@"png"] || [lastString.lowercaseString isEqualToString:@"jpg"] || [lastString.lowercaseString isEqualToString:@"jpeg"] || [lastString.lowercaseString isEqualToString:@"bmp"]) {
                fileType = 1;
            }else if([lastString.lowercaseString isEqualToString:@"tif"] || [lastString.lowercaseString isEqualToString:@"tiff"]){
                fileType = 2;
            }else if ([lastString.lowercaseString isEqualToString:@"pdf"]){
                fileType = 3;
            }else if ([lastString.lowercaseString isEqualToString:@"gif"]){
                fileType = 4;
            }
            
            switch (fileType) {
                case 1://jpeg, jpg, png, bmp
                {
                    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
                    NSString *imageName = [url lastPathComponent];
                    UIImage *image = [UIImage imageWithData:imageData];
                    BannerImageCropViewController *vc = [[BannerImageCropViewController alloc] initWithNibName:@"BannerImageCropViewController" bundle:nil];
                    vc.sourceImage = image;
                    vc.imageName = imageName;
                    vc.delegate = self;
                    [[AppDelegate sharedDelegate].window.rootViewController presentViewController:vc animated:YES completion:nil];
                    break;
                }
                case 2://TIF, TIFF file
                {
                    NSDataReadingOptions dataReadingOptions = NSDataReadingMappedIfSafe;
                    NSData* data = [[NSData alloc] initWithContentsOfURL:url options:dataReadingOptions error:nil];
                    
                    // Create a CGImageSourceRef that do not cache the decompressed result:
                    NSDictionary* sourcOptions =
                    @{(id)kCGImageSourceShouldCache: (id)kCFBooleanFalse,
                      (id)kCGImageSourceTypeIdentifierHint: (id)@"jellaTIFF"
                      };
                    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data,(CFDictionaryRef)sourcOptions);
                    
                    // Create a thumbnail without caching the decompressed result:
                    NSDictionary* thumbOptions = @{(id)kCGImageSourceShouldCache: (id)kCFBooleanFalse,
                                                   (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue,
                                                   (id)kCGImageSourceCreateThumbnailFromImageIfAbsent:  (id)kCFBooleanTrue,
                                                   (id)kCGImageSourceCreateThumbnailFromImageAlways: (id)kCFBooleanFalse,
                                                   (id)kCGImageSourceThumbnailMaxPixelSize:[NSNumber numberWithInteger:1024]};
                    
                    CGImageRef result = CGImageSourceCreateThumbnailAtIndex(source,0,(CFDictionaryRef)thumbOptions);
                    UIImage *image = [[UIImage alloc] initWithCGImage:result];
                    NSString *imageName = [url lastPathComponent];
                    BannerImageCropViewController *vc = [[BannerImageCropViewController alloc] initWithNibName:@"BannerImageCropViewController" bundle:nil];
                    vc.sourceImage = image;
                    vc.imageName = imageName;
                    vc.delegate = self;
                    [[AppDelegate sharedDelegate].window.rootViewController presentViewController:vc animated:YES completion:nil];
                    break;
                }
                case 3://pdf
                {
                    UIImage *thumbnailImage = [self generateThumbImageWithPdf:url];
                    BannerImageCropViewController *vc = [[BannerImageCropViewController alloc] initWithNibName:@"BannerImageCropViewController" bundle:nil];
                    vc.sourceImage = thumbnailImage;
                    vc.imageName = fileName;
                    vc.delegate = self;
                    [[AppDelegate sharedDelegate].window.rootViewController presentViewController:vc animated:YES completion:nil];
                }
                    break;
                case 4://gif
                {
                    isGifImage = YES;
                    NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
                    UIImage *image = [UIImage animatedImageWithAnimatedGIFData:imageData];
                    gifImage = image;
                    [self uploadPDF:url];
                    break;
                }
                    break;
                default:
                    break;
            }
        }
    }else{
        
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:[NSString stringWithFormat:@"Do you want to send %@", fileName] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:.1];
            NSError* error = nil;
            NSURLResponse* response = nil;
            [NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
            NSString* mimeType = [response MIMEType];
            NSArray *parseFileName = [mimeType componentsSeparatedByString:@"/"];
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
                
                switch (fileTypeValue) {
                    case 1://image
                    {
                        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
                        NSString *imageName = [url lastPathComponent];
                        UIImage *image = [UIImage imageWithData:imageData];
                        [self uploadPhoto:image withImageName:imageName];
                        break;
                    }
                    case 2://video
                        [self uploadVideo:url];
                        break;
                    case 3://pdf
                        [self uploadPDF:url];
                        break;
                    case 4://doc, text
                        [self uploadPDF:url];
                        break;
                    case 5://ppt, pptx
                        [self uploadPDF:url];
                        break;
                    default:
                        break;
                }
            }
        }];
        UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            
        }];
        [alert addAction:yesButton];
        [alert addAction:noButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
- (IBAction)onShareFiles:(id)sender {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                                                                            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:documentPicker];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)onSetting:(id)sender {
    SettingViewController *settingVc = [[SettingViewController alloc] initWithNibName:@"SettingViewController" bundle:nil];
    NSArray *controllers = @[settingVc];
    TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
    splitViewController.delegate = self;
    splitViewController.title = @"Settings";
    splitViewController.isShowFromSetting = YES;
    [[AppDelegate sharedDelegate].commsMain_vc.navigationController pushViewController:splitViewController animated:YES];
}

- (IBAction)onDashBoard:(id)sender {
    // disable naviation bar
    if (self.navigationController != nil) {
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
    // create a new dashboard view
    dashboardView = [[DashboardView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    CGRect currentScreenRect = [[UIScreen mainScreen] bounds];
    if (currentScreenRect.size.height<currentScreenRect.size.width) {
        [dashboardView setContentSize:CGSizeMake(currentScreenRect.size.width, currentScreenRect.size.width * currentScreenRect.size.width/currentScreenRect.size.height)];
    }else{
        [dashboardView setContentSize:CGSizeMake(0,0)];
    }
    // use tap gesture to close view
    UITapGestureRecognizer *tapToClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDashboardTap:)];
    [dashboardView addGestureRecognizer:tapToClose];
    // add the view to the root view controller
    
    [[AppDelegate sharedDelegate].window.rootViewController.view addSubview:dashboardView];
}

- (IBAction)onSetBannerImage:(id)sender {
    isToGetBannerImage = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionTakeProfilePhoto = [UIAlertAction actionWithTitle:@"Take Banner Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }];
    UIAlertAction* actionChooseFromLib = [UIAlertAction actionWithTitle:@"Choose from library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imgPicker.mediaTypes = [NSArray arrayWithObjects:(NSString*)kUTTypeImage, (NSString*)kUTTypePNG, (NSString*)kUTTypeJPEG, (NSString*)kUTTypeJPEG2000, nil];
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }];
    
    UIAlertAction* actionChooseFromDoc = [UIAlertAction actionWithTitle:@"Choose from Document" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                                                                                inMode:UIDocumentPickerModeImport];
        documentPicker.delegate = self;
        
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:documentPicker animated:YES completion:nil];
        
        UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:documentPicker];
        [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
        [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }];
    
    
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionTakeProfilePhoto];
    [alert addAction:actionChooseFromLib];
    [alert addAction:actionChooseFromDoc];
    [alert addAction:actionCancel];
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:alert];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (IBAction)onSendGeneralBannerByAdmin:(id)sender {
    
    rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
    
    BOOL isSentImage = NO;
    if (currentSetBannerImageUrl.length)
    {
        NSMutableDictionary *chatInfoForPostForBannerImage = [[NSMutableDictionary alloc] init];
        [chatInfoForPostForBannerImage setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
        [chatInfoForPostForBannerImage setValue:[NSNumber numberWithInteger:[currentUserID integerValue]] forKey:@"from"];
        if (isGifImage) {
            isGifImage = NO;
            [chatInfoForPostForBannerImage setValue:@"bannerForGif" forKey:@"type"];
        }else{
            [chatInfoForPostForBannerImage setValue:@"bannerForImage" forKey:@"type"];
        }
        [chatInfoForPostForBannerImage setValue:currentSetBannerImageUrl forKey:@"imageUrl"];
        [chatInfoForPostForBannerImage setValue:[NSString stringWithFormat:@"%f:%f", 730.0f, 100.0f] forKey:@"imageSize"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
        NSString *stringDate = [formatter stringFromDate:[NSDate date]];
        [chatInfoForPostForBannerImage setValue:stringDate forKey:@"sentTime"];
        
        [chatInfoForPostForBannerImage setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
        [chatInfoForPostForBannerImage setValue:@1 forKey:@"isRead"];
        [chatInfoForPostForBannerImage setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
        [chatInfoForPostForBannerImage setValue:boardID forKey:@"boardID"];
        [chatInfoForPostForBannerImage setValue:@(bubbleData.count+1) forKey:@"ordering"];
        
        FIRDatabaseReference *rootRForResgiterForBannerImage = [rootR childByAutoId];
        [rootRForResgiterForBannerImage setValue:chatInfoForPostForBannerImage];
        
        [btnBanerImage setBackgroundImage:nil forState:UIControlStateNormal];
        isSentImage = YES;
        currentSetBannerImageUrl = @"";
    }
    
    if (!txtLargeForBanner.text.length)
    {
        return;
    }
    if (!txtMediumForBanner.text.length)
    {
        return;
    }
    if (!txtSmallForBanner.text.length)
    {
        return;
    }
    
    NSMutableDictionary *chatInfoForPostWithBannerText = [[NSMutableDictionary alloc] init];
    [chatInfoForPostWithBannerText setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
    [chatInfoForPostWithBannerText setValue:currentUserID forKey:@"from"];
    [chatInfoForPostWithBannerText setValue:@"bannerForText" forKey:@"type"];
    [chatInfoForPostWithBannerText setValue:[NSString stringWithFormat:@"%@#!#!#%@#!#!#%@", txtLargeForBanner.text, txtMediumForBanner.text, txtSmallForBanner.text] forKey:@"message"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    NSString *stringDate = [formatter stringFromDate:[NSDate date]];
    [chatInfoForPostWithBannerText setValue:stringDate forKey:@"sentTime"];
    [chatInfoForPostWithBannerText setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
    [chatInfoForPostWithBannerText setValue:@1 forKey:@"isRead"];
    [chatInfoForPostWithBannerText setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
    [chatInfoForPostWithBannerText setValue:boardID forKey:@"boardID"];
    [chatInfoForPostWithBannerText setValue:[NSString stringWithFormat:@"%ld:%ld:%ld", (long)redValue, (long)greenValue, (long)blueValue] forKey:@"bannerColor"];
    
    
    
    if (isSentImage) {
        [chatInfoForPostWithBannerText setValue:@(bubbleData.count+2) forKey:@"ordering"];
    }else{
        [chatInfoForPostWithBannerText setValue:@(bubbleData.count+1) forKey:@"ordering"];
    }
        
        FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
        [rootRForResgiter setValue:chatInfoForPostWithBannerText];
        
        
        txtLargeForBanner.text = @"";
        txtMediumForBanner.text = @"";
        txtSmallForBanner.text = @"";
    
}

# pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtLargeForBanner) {
        [txtMediumForBanner becomeFirstResponder];
    }else if (textField == txtMediumForBanner){
        [txtSmallForBanner becomeFirstResponder];
    }else if (textField == txtSmallForBanner){
        [self.view endEditing:YES];
    }
    return YES;
}

-(void)handleDashboardTap:(UIGestureRecognizer *)gestureRecognizer {
    if (dashboardView != nil) {
        dashboardView.hidden = YES;
        [[AppDelegate sharedDelegate].window.rootViewController.view bringSubviewToFront:dashboardView];
        [dashboardView removeFromSuperview];
        dashboardView = nil;
        // enable naviation bar
        if (self.navigationController != nil) {
            self.navigationController.navigationBar.userInteractionEnabled = YES;
        }
    }
}
#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMovie] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeAVIMovie] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeVideo] || [[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeMPEG4]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        NSLog(@"VideoURL = %@", videoURL);
        [picker dismissViewControllerAnimated:YES completion:^(void){
            [self uploadVideo:videoURL];
        }];
    }else{
        
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        NSURL *imagePath = [info objectForKey:UIImagePickerControllerReferenceURL];
        NSString *imageName = [imagePath lastPathComponent];
        if (![UIImageJPEGRepresentation(image, 0.5f) writeToFile:[NSTemporaryDirectory() stringByAppendingString:@"/image.jpg"] atomically:YES]) {
            [self showAlert:@"Failed to save information. Please try again." :@"Error"];
            return;
        }
        
        if (isToGetBannerImage) {
            BannerImageCropViewController *vc = [[BannerImageCropViewController alloc] initWithNibName:@"BannerImageCropViewController" bundle:nil];
            vc.sourceImage = image;
            vc.imageName = imageName;
            vc.delegate = self;
            [picker pushViewController:vc animated:YES];
        }else{
            [picker dismissViewControllerAnimated:YES completion:^(void){
                [self uploadPhoto:image withImageName:imageName];
            }];
        }
    }
    
}

# pragma mark BannerImageCropViewControllerDelegate

- (void)didSelectBannerImage:(UIImage *)image withImageName:(NSString *)imageName{
    [self uploadPhoto:image withImageName:imageName];
}


- (UIImage *)generateThumbImageWithPdf:(NSURL *)url{
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(contextRef);
    CGContextTranslateCTM(contextRef, 0.0, rect.size.height);
    CGContextScaleCTM(contextRef, 1.0, -1.0);
    
    CGContextSetGrayFillColor(contextRef, 1.0, 1.0);
    CGContextFillRect(contextRef, rect);
    
    CGAffineTransform transform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, rect, 0, true);
    CGContextConcatCTM(contextRef, transform);
    CGContextDrawPDFPage(contextRef, page);
    
    UIImage *image= UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(contextRef);
    UIGraphicsEndImageContext();
    CGPDFDocumentRelease(pdf);
    
    return image;
}
- (void)uploadThumbnailImageOfPDF:(NSURL *)pdfUrl withpdfRemoteUrl:(NSString *)remotePdfUrl{
    
    
    [self getBadgeCountOfUserFromServer];
    
    UIImage *thumbnailImage = [self generateThumbImageWithPdf:pdfUrl];
    NSData *imageData = UIImageJPEGRepresentation(thumbnailImage,0.2);     //change Image to NSData
    
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
        [body appendData:[[currentUserID stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        NSDate *currentime = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
        NSString *imagefileName = [dateformatter stringFromDate:currentime];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"flightdesk_t_%@.jpg\"\r\n", imagefileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
                        NSString *currentImageUrl = [queryResults objectForKey:@"imageurl"];
                        NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
                        [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
                        [chatInfoForPost setValue:currentUserID forKey:@"from"];
                        if (fileTypeValue == 3) {
                            [chatInfoForPost setValue:@"pdf" forKey:@"type"];
                        }else if (fileTypeValue == 4){
                            [chatInfoForPost setValue:@"doc" forKey:@"type"];
                        }
                        [chatInfoForPost setValue:remotePdfUrl forKey:@"pdfUrl"];
                        [chatInfoForPost setValue:currentImageUrl forKey:@"thumbUrl"];
                        [chatInfoForPost setValue:[NSString stringWithFormat:@"%f:%f", thumbnailImage.size.width, thumbnailImage.size.height] forKey:@"thumbImageSize"];
                        
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
                        NSString *stringDate = [formatter stringFromDate:[NSDate date]];
                        [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
                        [chatInfoForPost setValue:@0 forKey:@"isRead"];
                        [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
                        [chatInfoForPost setValue:boardID forKey:@"boardID"];
                        [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
                        
                        [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
                        rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
                        FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
                        [rootRForResgiter setValue:chatInfoForPost];
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
    }else{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (fileTypeValue == 4){//doc
            NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
            [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
            [chatInfoForPost setValue:currentUserID forKey:@"from"];
            [chatInfoForPost setValue:@"doc" forKey:@"type"];
            [chatInfoForPost setValue:remotePdfUrl forKey:@"pdfUrl"];
            [chatInfoForPost setValue:@"" forKey:@"thumbUrl"];
            [chatInfoForPost setValue:@"" forKey:@"thumbImageSize"];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSString *stringDate = [formatter stringFromDate:[NSDate date]];
            [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
            [chatInfoForPost setValue:@0 forKey:@"isRead"];
            [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
            [chatInfoForPost setValue:boardID forKey:@"boardID"];
            [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
            
            [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
            rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
            FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
            [rootRForResgiter setValue:chatInfoForPost];
        }else if (fileTypeValue == 5){//ppt, pptx
            NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
            [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
            [chatInfoForPost setValue:currentUserID forKey:@"from"];
            [chatInfoForPost setValue:@"ppt" forKey:@"type"];
            [chatInfoForPost setValue:remotePdfUrl forKey:@"pdfUrl"];
            [chatInfoForPost setValue:@"" forKey:@"thumbUrl"];
            [chatInfoForPost setValue:@"" forKey:@"thumbImageSize"];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSString *stringDate = [formatter stringFromDate:[NSDate date]];
            [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
            [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
            [chatInfoForPost setValue:@0 forKey:@"isRead"];
            [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
            [chatInfoForPost setValue:boardID forKey:@"boardID"];
            [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
            
            rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
            FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
            [rootRForResgiter setValue:chatInfoForPost];
        }
    }
}
- (void)uploadPDF:(NSURL *)pdfUrl{
    
    [self getBadgeCountOfUserFromServer];
    
    NSData *pdfData = [NSData dataWithContentsOfURL:pdfUrl];
    if (pdfData != nil) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"Uploading…";
        
        
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_video.php", serverName, webAppDir];
        
        NSURL *saveURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[currentUserID stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *pdfFileName = [pdfUrl lastPathComponent];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", pdfFileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:pdfData]];
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                    NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                    return;
                }
                if ([[queryResults objectForKey:@"success"] boolValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (isToGetBannerImage) {
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            isToGetBannerImage = NO;
                            currentSetBannerImageUrl = [queryResults objectForKey:@"videoUrl"];
                            [btnBanerImage setBackgroundImage:gifImage forState:UIControlStateNormal];
                        }else{
                            NSString *currentUrl = [queryResults objectForKey:@"videoUrl"];
                            [self uploadThumbnailImageOfPDF:pdfUrl withpdfRemoteUrl:currentUrl];
                        }
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    });
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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

-(UIImage *)generateThumbImage : (NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *_thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return _thumbnail;
}
- (void)uploadThumbnailImageOfVideo:(NSURL *)videoUrl withVideoRemoteUrl:(NSString *)remoteVideoUrl{
    
    [self getBadgeCountOfUserFromServer];
    UIImage *thumbnailImage = [self generateThumbImage:videoUrl];
    NSData *imageData = UIImageJPEGRepresentation(thumbnailImage,0.2);     //change Image to NSData
    
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
        [body appendData:[[currentUserID stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        NSDate *currentime = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
        NSString *imagefileName = [dateformatter stringFromDate:currentime];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"flightdesk_t_%@.jpg\"\r\n", imagefileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
                        NSString *currentImageUrl = [queryResults objectForKey:@"imageurl"];
                        NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
                        [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
                        [chatInfoForPost setValue:currentUserID forKey:@"from"];
                        [chatInfoForPost setValue:@"video" forKey:@"type"];
                        [chatInfoForPost setValue:remoteVideoUrl forKey:@"videoUrl"];
                        [chatInfoForPost setValue:currentImageUrl forKey:@"thumbUrl"];
                        [chatInfoForPost setValue:[NSString stringWithFormat:@"%f:%f", thumbnailImage.size.width, thumbnailImage.size.height] forKey:@"thumbImageSize"];
                        
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
                        NSString *stringDate = [formatter stringFromDate:[NSDate date]];
                        [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
                        [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
                        [chatInfoForPost setValue:@0 forKey:@"isRead"];
                        [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
                        [chatInfoForPost setValue:boardID forKey:@"boardID"];
                        [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
                        
                        rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
                        FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
                        [rootRForResgiter setValue:chatInfoForPost];
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }

}
- (void)uploadVideo:(NSURL *)videoUrl{
    NSData *videoData = [NSData dataWithContentsOfURL:videoUrl];
    if (videoData != nil) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"Video uploading…";
        
        
        NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
        NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
        NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/upload_video.php", serverName, webAppDir];
        
        NSURL *saveURL = [NSURL URLWithString:apiURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:saveURL];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[currentUserID stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *videoFileName = [videoUrl lastPathComponent];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", videoFileName] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:videoData]];
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                    NSString *jsonStrData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    FDLogError(@"Unable to parse JSON for query to delete results data: %@\nText: %@\n\n", error, jsonStrData);
                    return;
                }
                if ([[queryResults objectForKey:@"success"] boolValue]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString *currentImageUrl = [queryResults objectForKey:@"videoUrl"];
                        [self uploadThumbnailImageOfVideo:videoUrl withVideoRemoteUrl:currentImageUrl];
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [ self  showAlert: @"Please try again" :@"Failed!"] ;
                    });
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
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
- (void)uploadPhoto:(UIImage *)img withImageName:(NSString *)imageName{
    
    [self getBadgeCountOfUserFromServer];
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
        [body appendData:[[currentUserID stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        NSDate *currentime = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMddhhmmss"];
        NSString *prefixFileName = [dateformatter stringFromDate:currentime];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@_%@\"\r\n", prefixFileName,imageName] dataUsingEncoding:NSUTF8StringEncoding]];
        
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
                        NSString *currentImageUrl = [queryResults objectForKey:@"imageurl"];
                        if (isToGetBannerImage) {
                            isToGetBannerImage = NO;
                            currentSetBannerImageUrl = currentImageUrl;
                            [btnBanerImage setBackgroundImage:img forState:UIControlStateNormal];
                        }else{
                            NSMutableDictionary *chatInfoForPost = [[NSMutableDictionary alloc] init];
                            [chatInfoForPost setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
                            [chatInfoForPost setValue:currentUserID forKey:@"from"];
                            [chatInfoForPost setValue:@"image" forKey:@"type"];
                            [chatInfoForPost setValue:currentImageUrl forKey:@"imageUrl"];
                            [chatInfoForPost setValue:[NSString stringWithFormat:@"%f:%f", img.size.width, img.size.height] forKey:@"imageSize"];
                            
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
                            NSString *stringDate = [formatter stringFromDate:[NSDate date]];
                            [chatInfoForPost setValue:stringDate forKey:@"sentTime"];
                            [chatInfoForPost setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
                            [chatInfoForPost setValue:@0 forKey:@"isRead"];
                            [chatInfoForPost setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
                            [chatInfoForPost setValue:boardID forKey:@"boardID"];
                            [chatInfoForPost setValue:@(bubbleData.count+1) forKey:@"ordering"];
                            
                            rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
                            FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
                            [rootRForResgiter setValue:chatInfoForPost];
                        }
                        
                    });
                    
                }else if ( ![[queryResults objectForKey:@"success"] boolValue]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ self  showAlert: @"Please try again" :@"Failed!"] ;
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
- (void)hideCoverOfWebView{
    [vwCoverOfWebView removeFromSuperview];
}
-(void)btPhotoDoneClick
{
    [imvPhoto setImage:nil];
    [vwPhoto removeFromSuperview];
}
- (void)viewDocAtLocalPath:(NSString *)docPath {
    NSURL *url = [NSURL fileURLWithPath:docPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView  loadRequest:request];
    [[AppDelegate sharedDelegate].window addSubview:vwCoverOfWebView];
}
- (void)viewPPTAtLocalPath:(NSString *)docPath {
    NSURL *url = [NSURL fileURLWithPath:docPath];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView  loadRequest:request];
    [[AppDelegate sharedDelegate].window addSubview:vwCoverOfWebView];
}
- (void)viewPDFAtLocalPath:(NSString *)docPath {
    NSString *documentDirectory = @"";
    documentDirectory = [NSString stringWithFormat:@"file://%@", docPath];
    NSURL *documentUrl =  [[NSURL alloc] initWithString:[documentDirectory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    MFDocumentManager *aDocManager = [[MFDocumentManager alloc]initWithFileUrl:documentUrl];
    
    ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithDocumentManager:aDocManager];
    readerViewController.pathOfCurrentPDF =documentUrl;
    [readerViewController setDocumentId:[documentUrl lastPathComponent]];
    [readerViewController setDocumentDelegate:readerViewController];
    //    readerViewController.hidesBottomBarWhenPushed = YES;
    [[AppDelegate sharedDelegate].splitViewControllerOfChatting.navigationController pushViewController:readerViewController animated:YES];
}
- (void)playVideoAtLocalPath:(NSString *)videoPath {
    playerVC = [[MPMoviePlayerViewController alloc] init];
    
    playerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    playerVC.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    playerVC.moviePlayer.contentURL = [NSURL fileURLWithPath:videoPath];
    
    [self presentMoviePlayerViewControllerAnimated:playerVC];
}

#pragma mark NSBubbleDataDelegate
- (void)videoTouched:(NSString*)videoPath{
    // Check cache first
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:videoPath];
    
    if (cachedPath) {
        // load from cache
        [self playVideoAtLocalPath:cachedPath];
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:videoPath];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:videoPath]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                [self playVideoAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:videoPath]];
            } else {
                [self showAlert:@"Could not download video, please try again." :@"Error"];
            }
        }];
        
        [downloadTask resume];
    }

}
- (void)videoLongPressed:(NSString *)videoPath{
    
}
- (void)imageTouched:(NSString*)imageurl{
    [imvPhoto setImageWithURL:[NSURL URLWithString:imageurl]];
    [[AppDelegate sharedDelegate].window addSubview:vwPhoto];
}
- (void)photoLongPressed:(NSString *)photoPath withView:(UIView *)selectedView withGif:(BOOL)isGif{
    NSString *alertTitle = @"";
    if (isGeneralBanner) {
        alertTitle = @"Send again?";
    }else{
        alertTitle = @"Import to My Docs";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionImportDocs = [UIAlertAction actionWithTitle:alertTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (isGeneralBanner) {
            NSMutableDictionary *chatInfoForPostForBannerImage = [[NSMutableDictionary alloc] init];
            [chatInfoForPostForBannerImage setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
            [chatInfoForPostForBannerImage setValue:currentUserID forKey:@"from"];
            if (isGif) {
                [chatInfoForPostForBannerImage setValue:@"bannerForGif" forKey:@"type"];
            }else{
                [chatInfoForPostForBannerImage setValue:@"bannerForImage" forKey:@"type"];
            }
            [chatInfoForPostForBannerImage setValue:photoPath forKey:@"imageUrl"];
            [chatInfoForPostForBannerImage setValue:[NSString stringWithFormat:@"%f:%f", 730.0f, 100.0f] forKey:@"imageSize"];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
            NSString *stringDate = [formatter stringFromDate:[NSDate date]];
            [chatInfoForPostForBannerImage setValue:stringDate forKey:@"sentTime"];
            
            [chatInfoForPostForBannerImage setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
            [chatInfoForPostForBannerImage setValue:@1 forKey:@"isRead"];
            [chatInfoForPostForBannerImage setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
            [chatInfoForPostForBannerImage setValue:boardID forKey:@"boardID"];
            [chatInfoForPostForBannerImage setValue:@(bubbleData.count+1) forKey:@"ordering"];
            rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
            FIRDatabaseReference *rootRForResgiterForBannerImage = [rootR childByAutoId];
            [rootRForResgiterForBannerImage setValue:chatInfoForPostForBannerImage];
        }else{
            NSURL *filePath = [NSURL URLWithString:[photoPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [self uploadNewPdfToserver:photoPath withFileName:[filePath lastPathComponent] withFilePath:@"" isImage:YES];
        }
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionImportDocs];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = selectedView;
    popPresenter.sourceRect = selectedView.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)bannerTextLongPress:(NSString *)bannerTextStr withColor:(NSString *)textBgColor withView:(UIView *)bannerTextCoverView{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionImportDocs = [UIAlertAction actionWithTitle:@"Send again?" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        rootR = [[FIRDatabase database] referenceFromURL:[NSString stringWithFormat:@"https://flightdesk-ee2ca.firebaseio.com/chat/%ld", (long)[boardID integerValue]]];
        NSMutableDictionary *chatInfoForPostWithBannerText = [[NSMutableDictionary alloc] init];
        [chatInfoForPostWithBannerText setValue:[NSNumber numberWithInteger:[friendID integerValue]] forKey:@"to"];
        [chatInfoForPostWithBannerText setValue:currentUserID forKey:@"from"];
        [chatInfoForPostWithBannerText setValue:@"bannerForText" forKey:@"type"];
        [chatInfoForPostWithBannerText setValue:bannerTextStr forKey:@"message"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        [formatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
        NSString *stringDate = [formatter stringFromDate:[NSDate date]];
        [chatInfoForPostWithBannerText setValue:stringDate forKey:@"sentTime"];
        [chatInfoForPostWithBannerText setValue:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000] forKey:@"message_id"];
        [chatInfoForPostWithBannerText setValue:@1 forKey:@"isRead"];
        [chatInfoForPostWithBannerText setValue:[NSString stringWithFormat:@"%@%@", [[[AppDelegate sharedDelegate].clientFirstName substringToIndex:1] uppercaseString], [[[AppDelegate sharedDelegate].clientLastName substringToIndex:1] uppercaseString]] forKey:@"fromName"];
        [chatInfoForPostWithBannerText setValue:boardID forKey:@"boardID"];
        [chatInfoForPostWithBannerText setValue:textBgColor forKey:@"bannerColor"];
        [chatInfoForPostWithBannerText setValue:@(bubbleData.count+1) forKey:@"ordering"];
        FIRDatabaseReference *rootRForResgiter = [rootR childByAutoId];
        [rootRForResgiter setValue:chatInfoForPostWithBannerText];
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionImportDocs];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = bannerTextCoverView;
    popPresenter.sourceRect = bannerTextCoverView.bounds;
    [self presentViewController:alert animated:YES completion:nil];
    

}

- (void)voiceLongPressed:(NSString *)audioPath{
    
}
- (void)pdfTouched:(NSString*)pdfPath{
    NSString *fileName = [[NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] lastPathComponent];
    NSArray *parseFileName = [fileName componentsSeparatedByString:@"."];
    NSInteger docType = 0;
    if (parseFileName.count > 1) {
        NSString *lastString = parseFileName[parseFileName.count-1];
        if ([lastString.lowercaseString isEqualToString:@"pdf"]){
            docType = 1;
        }else if ([lastString.lowercaseString isEqualToString:@"txt"] || [lastString.lowercaseString isEqualToString:@"doc"]){
            docType = 2;
        }else if ([lastString.lowercaseString isEqualToString:@"ppt"] || [lastString.lowercaseString isEqualToString:@"pptx"]){
            docType = 3;
        }
    }
    
        
        
    // Check cache first
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:pdfPath];
    
    if (cachedPath) {
        // load from cache
        switch (docType) {
            case 1:
                [self viewPDFAtLocalPath:cachedPath];
                break;
            case 2:
                [self viewDocAtLocalPath:cachedPath];
                break;
            case 3:
                [self viewPPTAtLocalPath:cachedPath];
                break;
                
            default:
                break;
        }
    } else {
        // save to temp directory
        NSURL *url = [NSURL URLWithString:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
        downloadProgressHUD = [MBProgressHUD showHUDAddedTo:[AppDelegate sharedDelegate].window animated:YES];
        downloadProgressHUD.mode = MBProgressHUDModeDeterminate;
        
        NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
            
            NSLog(@"Progress… %f", downloadProgress.fractionCompleted);
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadProgressHUD.progress = downloadProgress.fractionCompleted;
            });
            
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            return [NSURL fileURLWithPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            [downloadProgressHUD hideAnimated:YES];
            if (!error) {
                switch (docType) {
                    case 1:
                        [self viewPDFAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                        break;
                    case 2:
                        [self viewDocAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                        break;
                    case 3:
                        [self viewPPTAtLocalPath:[LocalDBManager getCachedFileNameFromRemotePath:[pdfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                        break;
                        
                    default:
                        break;
                }
            } else {
                [self showAlert:@"Could not download video, please try again." :@"Error"];
            }
        }];
        
        [downloadTask resume];
    }
}
- (void)pdfLongPressed:(NSString *)pdfPath withRemoteurl:(NSString *)remoteUrl withView:(NSBubbleDocView *)pdfView{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionImportDocs = [UIAlertAction actionWithTitle:@"Import to My Docs" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *filePath = [NSURL URLWithString:remoteUrl];
        [self uploadNewPdfToserver:remoteUrl withFileName:[filePath lastPathComponent] withFilePath:@"" isImage:NO];
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionImportDocs];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = pdfView;
    popPresenter.sourceRect = pdfView.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)uploadNewPdfToserver:(NSString *)remoteUrl  withFileName:(NSString *)pdfName withFilePath:(NSString *)finalPath isImage:(BOOL)isImage{
    
    BOOL isExistInLocalCurrentFile = NO;
    
    NSString *cachedPath = [LocalDBManager checkCachedFileExist:remoteUrl];
    
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (cachedPath) {
        isExistInLocalCurrentFile = YES;
        
        // Get all the files at ~/Documents/user
        NSError *error;
        NSString *destinationPath = [documentDirectory stringByAppendingPathComponent:pdfName];
        if([fm fileExistsAtPath:destinationPath])
        {
            [fm removeItemAtPath:destinationPath error:&error];
        }
        
        [fm copyItemAtPath:cachedPath
                    toPath:[documentDirectory stringByAppendingPathComponent:pdfName]
                     error:&error];
        if (error != nil) {
            isExistInLocalCurrentFile = NO;
        }
    }else{
        NSString *destinationPath = [documentDirectory stringByAppendingPathComponent:pdfName];
        if([fm fileExistsAtPath:destinationPath])
        {
            isExistInLocalCurrentFile = YES;
        }
    }
    
        
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"upload_own_pdf", @"action", currentUserID, @"user_id", remoteUrl, @"pdf_url", pdfName, @"pdf_name", nil];
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
                    
                    
                    NSError *error;
                    Document *document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:context];
                    document.documentID = pdfID;
                    document.pdfURL = finalPath;
                    if (isExistInLocalCurrentFile) {
                        document.downloaded = @(1);
                        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentDirectory=[paths objectAtIndex:0];
                        NSString *finalPathWithcurrentFile =[documentDirectory stringByAppendingPathComponent:pdfName];
                        [ReaderDocument withDocumentFilePath:finalPathWithcurrentFile password:nil];
                        document.pdfURL = finalPathWithcurrentFile;
                    }else if (isImage){
                        document.downloaded = @(1);
                    }else{
                        document.downloaded = @(0);
                    }
                    document.lastSync =  [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
                    document.lastUpdate =  @(0);
                    document.name = pdfName;
                    document.remoteURL = remoteUrl;
                    document.type = @(1);
                    [context save:&error];
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                    [[AppDelegate sharedDelegate].documents_vc populateDocuments];
                    [self showAlert:@"Success! File imported to My Docs." :@"FlightDesk"];
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
        }
    }];
    [uploadLessonRecordsTask resume];
}
- (void)docLongPressed:(NSString *)docPath withRemoteurl:(NSString *)remoteUrl withView:(UIView *)docView{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionImportDocs = [UIAlertAction actionWithTitle:@"Import to My Docs" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *filePath = [NSURL URLWithString:[remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [self uploadNewPdfToserver:remoteUrl withFileName:[filePath lastPathComponent] withFilePath:@"" isImage:NO];
    }];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionImportDocs];
    [alert addAction:actionCancel];
    
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = docView;
    popPresenter.sourceRect = docView.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)requestToGetSupportToFlightDesk{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"request_to_support_flightdesk", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
    NSData *usersJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *usersRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [usersRequest setHTTPMethod:@"POST"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [usersRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)usersJSON.length] forHTTPHeaderField:@"Content-Length"];
    [usersRequest setHTTPBody:usersJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *usersTask = [session dataTaskWithRequest:usersRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
                
            }else{
                
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
    [usersTask resume];
}
-(void)cancelRequestSupportToFlightDesk{
    NSError *error;
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:@"cancel_request_to_support_flightdesk", @"action", [AppDelegate sharedDelegate].userId, @"user_id", nil];
    NSData *usersJSON =[NSJSONSerialization dataWithJSONObject:root options:0 error:&error];
    NSString *serverName = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"server_name"];
    NSString *webAppDir = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"web_app_dir"];
    NSString *apiURLString = [[NSString alloc] initWithFormat:@"%@/%@/flight_training_api.php", serverName, webAppDir];
    NSURL *saveLessonsURL = [NSURL URLWithString:apiURLString];
    NSMutableURLRequest *usersRequest = [NSMutableURLRequest requestWithURL:saveLessonsURL];
    [usersRequest setHTTPMethod:@"POST"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [usersRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [usersRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)usersJSON.length] forHTTPHeaderField:@"Content-Length"];
    [usersRequest setHTTPBody:usersJSON];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *usersTask = [session dataTaskWithRequest:usersRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *responseError) {
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                });
                
            }else{
                
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
    [usersTask resume];
}
- (void)textTouched:(NSString *)text{
    
}
- (void)textLongTouched:(NSString *)text  withView:(UIView*)view{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionCopyText = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = text;
    }];
    
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionCopyText];
    [alert addAction:actionCancel];
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:alert];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[view bounds] inView:view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}
- (void)linkLongTouched:(NSString *)link withView:(UIView*)view{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* actionTakeProfilePhoto = [UIAlertAction actionWithTitle:@"Copy link" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [UIPasteboard generalPasteboard].string = link;
    }];
    UIAlertAction* actionChooseFromLib = [UIAlertAction actionWithTitle:@"Mail link" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self mailLink:link];
    }];
    
    UIAlertAction* actionChooseFromDoc = [UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:link];
        BOOL safariCompatible = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
        if (!safariCompatible) {
            NSString *tmplink = [NSString stringWithFormat:@"http://%@", link];
            url = [NSURL URLWithString:tmplink];
            if (![[UIApplication sharedApplication] canOpenURL:url]){
                tmplink = [NSString stringWithFormat:@"https://%@", link];
                url = [NSURL URLWithString:tmplink];
            }
        }
        [self attemptOpenURL:url];
    }];
    
    
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alert addAction:actionTakeProfilePhoto];
    [alert addAction:actionChooseFromLib];
    [alert addAction:actionChooseFromDoc];
    [alert addAction:actionCancel];
    
    UIPopoverController *popoverController= [[UIPopoverController alloc] initWithContentViewController:alert];
    [popoverController setPopoverContentSize:CGSizeMake(320, 400) animated:NO];
    [popoverController presentPopoverFromRect:[view bounds] inView:view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];

}
- (void)linkTouched:(NSString *)link{    
    NSURL *url = [NSURL URLWithString:link];
    BOOL safariCompatible = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
    if (!safariCompatible) {
        NSString *tmplink = [NSString stringWithFormat:@"http://%@", link];
        url = [NSURL URLWithString:tmplink];
        if (![[UIApplication sharedApplication] canOpenURL:url]){
            tmplink = [NSString stringWithFormat:@"https://%@", link];
            url = [NSURL URLWithString:tmplink];
        }
    }
    [self attemptOpenURL:url];
}
#pragma mark - Helper methods

/**
 *  Checks to see if its an URL that we can open in safari. If we can then open it,
 *  otherwise put up an alert to the user.
 *
 *  @param url URL to open in Safari
 */
- (void)attemptOpenURL:(NSURL *)url
{
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                        message:@"The selected link cannot be opened."
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

/**
 *  Create an email containing the specified link. Will put up an alert if we can't send mail.
 *
 *  @param link The link to use as content of the email.
 */
- (void)mailLink:(NSString *)link
{
    if ([MFMailComposeViewController canSendMail])
    {
        // Create a mail controller with a default subject
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:@"Link from my App"];
        
        // Create the body for the mail. We use HTML format because its nice
        NSString *message = [NSString stringWithFormat:@"<!DOCTYPE html><html><a href=\"%@\">%@</a><body></body></html>", link, link];
        [controller setMessageBody:message isHTML:YES];
        
        // Show the mail controller
        [self presentViewController:controller animated:YES completion:NULL];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Problem"
                                                                       message:@"Cannot send mail."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end


