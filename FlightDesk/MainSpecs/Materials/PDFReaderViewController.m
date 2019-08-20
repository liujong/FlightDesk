//
//  PDFReaderViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/30/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "PDFReaderViewController.h"

@interface PDFReaderViewController ()<UIGestureRecognizerDelegate>{
    UIView *containViewOfSharing;
    UIButton *sharingBTN;
    
    UIView *containViewOfPrint;
    UIButton *printBTN;
}

@end

@implementation PDFReaderViewController
@synthesize pathOfCurrentPDF;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setTintColor:[UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f]];
    [self performSelector:@selector(refreshFrame) withObject:nil afterDelay:1.0f];
    
    containViewOfSharing = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-60, 70, 50, 50)];
    containViewOfSharing.autoresizesSubviews = NO;
    containViewOfSharing.contentMode = UIViewContentModeRedraw;
    containViewOfSharing.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    containViewOfSharing.layer.shadowRadius = 25.0f;
    containViewOfSharing.layer.shadowOpacity = 1.0f;
    containViewOfSharing.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    containViewOfSharing.layer.shadowPath = [UIBezierPath bezierPathWithRect:containViewOfSharing.bounds].CGPath;
    containViewOfSharing.layer.cornerRadius = 25.0f;
    containViewOfSharing.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    
    sharingBTN = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
    [sharingBTN addTarget:self action:@selector(onSharing) forControlEvents:UIControlEventTouchUpInside];
    [sharingBTN setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    [sharingBTN setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [containViewOfSharing addSubview:sharingBTN];
    
    containViewOfPrint = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-60, 140, 50, 50)];
    containViewOfPrint.autoresizesSubviews = NO;
    containViewOfPrint.contentMode = UIViewContentModeRedraw;
    containViewOfPrint.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    containViewOfPrint.layer.shadowRadius = 25.0f;
    containViewOfPrint.layer.shadowOpacity = 1.0f;
    containViewOfPrint.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    containViewOfPrint.layer.shadowPath = [UIBezierPath bezierPathWithRect:containViewOfPrint.bounds].CGPath;
    containViewOfPrint.layer.cornerRadius = 25.0f;
    containViewOfPrint.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    
    printBTN = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
    [printBTN addTarget:self action:@selector(onPrinting) forControlEvents:UIControlEventTouchUpInside];
    [printBTN setImage:[UIImage imageNamed:@"print"] forState:UIControlStateNormal];
    [printBTN setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [containViewOfPrint addSubview:printBTN];
    [self.view addSubview:containViewOfSharing];
    [self.view addSubview:containViewOfPrint];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    //[super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];

}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated{
    //[super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"PDFReaderViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

}
- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
}
- (void)refreshFrame{
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void)
     {
         CGRect rectFrame = UIScreen.mainScreen.bounds;
         rectFrame.size.height = rectFrame.size.height - 50.0f;
         [self.view setFrame:rectFrame];
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
}
- (void)deviceOrientationDidChange{
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn
                     animations:^(void)
     {
         CGRect rectFrame = UIScreen.mainScreen.bounds;
         rectFrame.size.height = rectFrame.size.height - 50.0f;
         [self.view setFrame:rectFrame];
         [self.view layoutIfNeeded];
     }
                     completion:^(BOOL finished)
     {
     }
     ];
    
    
}
-(void)onSharing{
    
    NSString *textToShare = self.textDisplayViewController.text;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:pathOfCurrentPDF, nil] applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeOpenInIBooks ];
    
    activityVC.excludedActivityTypes = excludeActivities;
                                 
    activityVC.popoverPresentationController.sourceView = self.view;
    activityVC.popoverPresentationController.sourceRect = containViewOfSharing.frame;
    UIPopoverController* _popover = [[UIPopoverController alloc] initWithContentViewController:activityVC];
    _popover.delegate = self;
    [self presentViewController:activityVC
                       animated:YES
                     completion:nil];
}
- (void)onPrinting{
    UIPrintInteractionController *pc = [UIPrintInteractionController
                                        sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.orientation = UIPrintInfoOrientationPortrait;
    printInfo.jobName =@"Report";
    
    pc.printInfo = printInfo;
    pc.showsPageRange = YES;
    pc.printingItem = pathOfCurrentPDF;
    
    
    UIPrintInteractionCompletionHandler completionHandler =
    ^(UIPrintInteractionController *printController, BOOL completed,
      NSError *error) {
        if(!completed && error){
            NSLog(@"Print failed - domain: %@ error code %ld", error.domain,
                  (long)error.code);
        }
    };
    
    
    [pc presentFromRect:containViewOfPrint.frame inView:self.view animated:YES completionHandler:completionHandler];
}
@end
