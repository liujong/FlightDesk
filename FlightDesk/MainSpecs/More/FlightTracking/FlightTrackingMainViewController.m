//
//  FlightTrackingMainViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 9/29/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "FlightTrackingMainViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ActivityViewCustomActivity.h"


#define RGBA(r,g,b,a) [UIColor colorWithRed:(r/255.0f) green: (g/255.0f) blue:(b/255.0f) alpha: a]
#define COLOR_BORDER RGBA(85, 85, 85, 1)
#define COLOR_CONTENT RGBA(191, 191, 191, 1)

#define COLOR_SELECTED RGBA(38, 161, 255, 1)

#define COLOR_BRASH_RED     RGBA(255, 0, 0, 1)
#define COLOR_BRASH_SKY     RGBA(0, 255, 255, 1)
#define COLOR_BRASH_GREEN   RGBA(0, 255, 0, 1)
#define COLOR_BRASH_PINK    RGBA(255, 0, 255, 1)
#define COLOR_BRASH_BLUE    RGBA(0, 0, 255, 1)
#define COLOR_BRASH_YELLO   RGBA(255, 255, 0, 1)

#define COLOR_BRASH_SELECTED   RGBA(0, 195, 255, 1)

#define FONT_LABEL [UIFont fontWithName:@"Helvetica" size:17];
#define FONT_CONTENT [UIFont fontWithName:@"Helvetica" size:23];

#define FONT_LABEL_SMALL [UIFont fontWithName:@"Helvetica" size:13];
#define FONT_CONTENT_SMALL [UIFont fontWithName:@"Helvetica" size:15];
#define FONT_LABEL_FLIGHT_PLAN_SMALL [UIFont fontWithName:@"Helvetica" size:12];

#define FONT_LABEL_FLIGHT_PLAN [UIFont fontWithName:@"Helvetica" size:12];

@interface FlightTrackingMainViewController ()<UIPopoverControllerDelegate, UITextFieldDelegate>
{
    UIPopoverController *colorPickerPopover;
    UIPopoverController *eraserPickerPopover;
    NSInteger selectedColorIndex;
    NSInteger selectedPage;
    NSArray *imageNamesForPages;
    
    CGPoint lastTouch;
    CGPoint currentTouch;
    
    BOOL isStandard;
    
    UITextField *txtFieldToEnter;
    CGFloat currentTapPointY;

}

@end

@implementation FlightTrackingMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    txtFieldToEnter = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 10, 50)];
    txtFieldToEnter.delegate = self;
    txtFieldToEnter.layer.borderWidth = 1.0f;
    txtFieldToEnter.layer.borderColor = [UIColor blueColor].CGColor;
    
    imageNamesForPages = [[NSArray alloc] initWithObjects:@"page1_tracking.png",@"page2_tracking.png", @"wx_tracking.png", @"craft_tracking.png", @"pirep_tracking.png",@"flightplan_tracking.png", nil];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont fontWithName:@"Helvetica-Bold" size:14], NSFontAttributeName,
                                [UIColor whiteColor], NSForegroundColorAttributeName,
                                nil];
    [segmentedDrawPad setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    [segmentedDrawPad setTitleTextAttributes:highlightedAttributes forState:UIControlStateSelected];
    
    UIImage *btnPenImage = [[UIImage imageNamed:@"pen_pad"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnPen setImage:btnPenImage forState:UIControlStateNormal];
    btnPen.tintColor = COLOR_BRASH_RED;
    
    UIImage *btnTrashImage = [[UIImage imageNamed:@"delete_doc"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnTrash setImage:btnTrashImage forState:UIControlStateNormal];
    btnTrash.tintColor = [UIColor whiteColor];
    
    UIImage *btnEraserImage = [[UIImage imageNamed:@"eraser"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btnEraser setImage:btnEraserImage forState:UIControlStateNormal];
    btnEraser.tintColor = [UIColor whiteColor];
    
    scratchPad  = [[DAScratchPadView alloc] initWithFrame:CGRectMake(0, 0, padBGScrView.frame.size.width, padBGScrView.frame.size.height)];
    [scratchPad clearToColor:[UIColor clearColor]];
    [scratchPad setBackgroundColor:[UIColor clearColor]];
    scratchPad.drawColor = COLOR_BRASH_RED;
    scratchPad.drawWidth = 3.0f;
    scratchPad.toolType = DAScratchPadToolTypePaint;
    scratchPad.drawOpacity = 1.0f;
    [padBGScrView addSubview:scratchPad];
    
    [penThicknessSlider setValue:3.0f];
    
    selectedColorIndex = 0;
    selectedPage = 0;
    isStandard = NO;
    
    //load from local
    selectedPage = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedPageIndexForTracking"] integerValue];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    UIImage *imageToLoad = [UIImage imageWithContentsOfFile:[basePath stringByAppendingPathComponent:imageNamesForPages[selectedPage]]];
    [scratchPad setSketch:imageToLoad];
    
    [segmentedDrawPad setSelectedSegmentIndex:selectedPage];
    
    selectedColorIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedColorIndexForTracking"] integerValue];
    penThicknessSlider.value = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedColorThicknessForTracking"] floatValue];
    eraserThicknessSlider.value = [[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedEraserThicknessForTracking"] floatValue];
    [self onSelectPanColor:nil];
    scratchPad.drawWidth = penThicknessSlider.value;
    scratchPad.eraserDrawWidth = eraserThicknessSlider.value;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToEnter:)];
    [scratchPad addGestureRecognizer:longPress];
}
- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (self.view.frame.size.width > self.view.frame.size.height ) {
        if (segmentedDrawPad.selectedSegmentIndex == 5) {
            [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
        }else{
            [padBGScrView setFrame:CGRectMake(self.view.frame.size.width/2 - containerView.frame.size.height * containerView.frame.size.height / (2 * containerView.frame.size.width), 0, containerView.frame.size.height * containerView.frame.size.height / containerView.frame.size.width, containerView.frame.size.height)];
        }
    }else{
        [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
    }
    [scratchPad setFrame:CGRectMake(0, 0, padBGScrView.frame.size.width, padBGScrView.frame.size.height)];
    
    [self reloadCurrentPadWithSegment];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self deviceOrientationDidChange];
    [navView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, navView.frame.size.height)];
    [self.navigationController.navigationBar addSubview:navView];
    if (btnFullScreen.selected){
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }else{
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"FlightTrackingMainViewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [navView removeFromSuperview];
    //save pre-scratch on local
    [self saveImageToLocalWithImage:scratchPad.getSketch withName:imageNamesForPages[selectedPage]];
    [[NSUserDefaults standardUserDefaults] setInteger:selectedPage forKey:@"SavedPageIndexForTracking"];
    [[NSUserDefaults standardUserDefaults] setInteger:selectedColorIndex forKey:@"SavedColorIndexForTracking"];
    [[NSUserDefaults standardUserDefaults] setFloat:penThicknessSlider.value forKey:@"SavedColorThicknessForTracking"];
    [[NSUserDefaults standardUserDefaults] setFloat:eraserThicknessSlider.value forKey:@"SavedEraserThicknessForTracking"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (btnFullScreen.selected){
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}
- (void)viewDidAppear:(BOOL)animated{
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
}
- (void)deviceOrientationDidChange{
    [navView setFrame:CGRectMake(0, 0, self.view.frame.size.width, navView.frame.size.height)];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:20.0f/255.0f green:20.0f/255.0f blue:20.0f/255.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:20.0f/255.0f green:20.0f/255.0f blue:20.0f/255.0f alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
    
    if (self.view.frame.size.width > self.view.frame.size.height ) {
        if (segmentedDrawPad.selectedSegmentIndex == 5) {
            [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
        }else{
            [padBGScrView setFrame:CGRectMake(self.view.frame.size.width/2 - containerView.frame.size.height * containerView.frame.size.height / (2 * containerView.frame.size.width), 0, containerView.frame.size.height * containerView.frame.size.height / containerView.frame.size.width, containerView.frame.size.height)];
        }
    }else{
        [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
    }
    [scratchPad setFrame:CGRectMake(0, 0, padBGScrView.frame.size.width, padBGScrView.frame.size.height)];
    [self reloadCurrentPadWithSegment];
}
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if ((padBGScrView.frame.size.height-currentTapPointY)<300) {
        [padBGScrView setContentSize:CGSizeMake(0, padBGScrView.frame.size.height + 300.0f)];
        [padBGScrView setContentOffset:CGPointMake(0, 300) animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [padBGScrView setContentSize:CGSizeMake(0, 0)];
    [self mergeTextWithScratc];
}
#pragma mark LongPressGesture
- (void)longPressToEnter:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"%@",NSStringFromCGPoint([[sender valueForKey:@"_startPointScreen"] CGPointValue]));
        CGPoint pointWithLongPress = [[sender valueForKey:@"_startPointScreen"] CGPointValue];
        CGRect txtRect = txtFieldToEnter.frame;
        
        txtRect.origin.x = pointWithLongPress.x;
        if (btnFullScreen.selected){
            txtRect.origin.y = pointWithLongPress.y - 20.0f;
        }else{
            txtRect.origin.y = pointWithLongPress.y - 64.0f - 20.0f;
        }
        
        currentTapPointY = txtRect.origin.y;
        txtFieldToEnter.frame = txtRect;
        switch (selectedColorIndex) {
            case 0:
                txtFieldToEnter.textColor = COLOR_BRASH_RED;
                break;
            case 1:
                txtFieldToEnter.textColor = COLOR_BRASH_SKY;
                break;
            case 2:
                txtFieldToEnter.textColor = COLOR_BRASH_GREEN;
                break;
            case 3:
                txtFieldToEnter.textColor = COLOR_BRASH_PINK;
                break;
            case 4:
                txtFieldToEnter.textColor = COLOR_BRASH_BLUE;
                break;
            case 5:
                txtFieldToEnter.textColor = COLOR_BRASH_YELLO;
                break;
            case 6:
                txtFieldToEnter.textColor = [UIColor whiteColor];
                break;
                
            default:
                break;
        }
        txtFieldToEnter.font = [UIFont fontWithName:@"Helvetica-Bold" size:penThicknessSlider.value + 20];
        [padBGScrView addSubview:txtFieldToEnter];
        [txtFieldToEnter becomeFirstResponder];
    }
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    CGSize frameSize = CGSizeMake(padBGScrView.frame.size.width, 50);
    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:penThicknessSlider.value + 20];

    CGRect idealFrame = [text boundingRectWithSize:frameSize
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:@{ NSFontAttributeName:font }
                                           context:nil];
    CGRect txtRect = txtFieldToEnter.frame;
    txtRect.size.width = idealFrame.size.width;
    txtRect.size.height = idealFrame.size.height;
    txtFieldToEnter.frame = txtRect;
    txtFieldToEnter.text = text;
    return NO;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == txtFieldToEnter) {
        [self mergeTextWithScratc];
    }
    return YES;
}
- (void)mergeTextWithScratc{
    [txtFieldToEnter removeFromSuperview];
    [self.view endEditing:YES];
    CGPoint currentTextPoint = CGPointMake(txtFieldToEnter.frame.origin.x, txtFieldToEnter.frame.origin.y);
    UIImage *tmpImage =[self  drawFront:scratchPad.getSketch text:txtFieldToEnter.text atPoint:currentTextPoint];
    [scratchPad setSketch:tmpImage];
    txtFieldToEnter.text = @"";
    txtFieldToEnter.frame = CGRectMake(0, 0, 10, 50);
}
-(UIImage*)drawFront:(UIImage*)image text:(NSString*)text atPoint:(CGPoint)point
{
    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:penThicknessSlider.value + 20];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, (point.y - 5), image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    
    NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange range = NSMakeRange(0, [attString length]);
    
    [attString addAttribute:NSFontAttributeName value:font range:range];
    [attString addAttribute:NSForegroundColorAttributeName value:txtFieldToEnter.textColor range:range];
    
//    NSShadow* shadow = [[NSShadow alloc] init];
//    shadow.shadowColor = [UIColor darkGrayColor];
//    shadow.shadowOffset = CGSizeMake(1.0f, 1.5f);
//    [attString addAttribute:NSShadowAttributeName value:shadow range:range];
    
    [attString drawInRect:CGRectIntegral(rect)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (void)reloadCurrentPadWithSegment{
    if (isStandard) {
        padBGScrView.backgroundColor = [UIColor whiteColor];
    }else{
        padBGScrView.backgroundColor = [UIColor blackColor];
    }
    
    for (UIView *subView in padBGScrView.subviews) {
        if ([subView isKindOfClass:[DAScratchPadView class]]) {
            break;
        }
        [subView removeFromSuperview];
    }
    switch (segmentedDrawPad.selectedSegmentIndex) {
        case 0://page 1
        {
            break;
        }
        case 1://page 2
        {
            [padBGScrView insertSubview:[self getNOTES] belowSubview:scratchPad];
            break;
        }
        case 2://WX
        {
            [padBGScrView insertSubview:[self getWXView] belowSubview:scratchPad];
            break;
        }
        case 3://CRAFT
        {
            [padBGScrView insertSubview:[self getCraftView] belowSubview:scratchPad];
            break;
        }
        case 4://PIREP
        {
            [padBGScrView insertSubview:[self getPirepView] belowSubview:scratchPad];
            break;
        }
        case 5://FLIGHT PLAN
        {
            [padBGScrView insertSubview:[self getFlightPlanView] belowSubview:scratchPad];
            break;
        }
        default:
            break;
    }
}
- (IBAction)onBack:(id)sender {
    [self saveImageToLocalWithImage:scratchPad.getSketch withName:imageNamesForPages[selectedPage]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onChangePad:(id)sender {
    if (self.view.frame.size.width > self.view.frame.size.height ) {
        if (segmentedDrawPad.selectedSegmentIndex == 5) {
            [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
        }else{
            [padBGScrView setFrame:CGRectMake(self.view.frame.size.width/2 - containerView.frame.size.height * containerView.frame.size.height / (2 * containerView.frame.size.width), 0, containerView.frame.size.height * containerView.frame.size.height / containerView.frame.size.width, containerView.frame.size.height)];
        }
    }else{
        [padBGScrView setFrame:CGRectMake(0, 0, containerView.frame.size.width, containerView.frame.size.height)];
    }
    [scratchPad setFrame:CGRectMake(0, 0, padBGScrView.frame.size.width, padBGScrView.frame.size.height)];
    [self reloadCurrentPadWithSegment];
    
    //save pre-scratch on local
    [self saveImageToLocalWithImage:scratchPad.getSketch withName:imageNamesForPages[selectedPage]];
    
    selectedPage = segmentedDrawPad.selectedSegmentIndex;
    
    //load next-scratch from local
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    UIImage *imageToLoad = [UIImage imageWithContentsOfFile:[basePath stringByAppendingPathComponent:imageNamesForPages[selectedPage]]];
    [scratchPad setSketch:imageToLoad];
}

- (IBAction)onSelectPanColor:(id)sender {
    scratchPad.toolType = DAScratchPadToolTypePaint;
    btnPen.tintColor = [UIColor whiteColor];
    btnTrash.tintColor = [UIColor whiteColor];
    btnEraser.tintColor = [UIColor whiteColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    UIView *viewToChangeColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 300)];
    [viewToChangeColor addSubview:colorsView];
    
    for (UIView *currentSubView in colorsView.subviews) {
        if ([currentSubView isKindOfClass:[UIButton class]]) {
            UIButton *currentButton = (UIButton *)currentSubView;
            if (currentButton.tag ==300 + selectedColorIndex) {
                currentButton.layer.borderWidth = 5.0f;
                currentButton.layer.borderColor = COLOR_SELECTED.CGColor;
            }else{
                currentButton.layer.borderWidth = 0.0f;
                currentButton.layer.borderColor = [UIColor clearColor].CGColor;
            }
        }
    }
    switch (selectedColorIndex) {
        case 0:
            scratchPad.drawColor = COLOR_BRASH_RED;
            btnPen.tintColor = COLOR_BRASH_RED;
            txtFieldToEnter.textColor = COLOR_BRASH_RED;
            break;
        case 1:
            scratchPad.drawColor = COLOR_BRASH_SKY;
            btnPen.tintColor = COLOR_BRASH_SKY;
            txtFieldToEnter.textColor = COLOR_BRASH_SKY;
            break;
        case 2:
            scratchPad.drawColor = COLOR_BRASH_GREEN;
            btnPen.tintColor = COLOR_BRASH_GREEN;
            txtFieldToEnter.textColor = COLOR_BRASH_GREEN;
            break;
        case 3:
            scratchPad.drawColor = COLOR_BRASH_PINK;
            btnPen.tintColor = COLOR_BRASH_PINK;
            txtFieldToEnter.textColor = COLOR_BRASH_PINK;
            break;
        case 4:
            scratchPad.drawColor = COLOR_BRASH_BLUE;
            btnPen.tintColor = COLOR_BRASH_BLUE;
            txtFieldToEnter.textColor = COLOR_BRASH_BLUE;
            break;
        case 5:
            scratchPad.drawColor = COLOR_BRASH_YELLO;
            btnPen.tintColor = COLOR_BRASH_YELLO;
            txtFieldToEnter.textColor = COLOR_BRASH_YELLO;
            break;
        case 6:
            scratchPad.drawColor = [UIColor whiteColor];
            btnPen.tintColor = [UIColor whiteColor];
            txtFieldToEnter.textColor = [UIColor whiteColor];
            break;
            
        default:
            break;
    }
    
    vc.view = viewToChangeColor;
    colorPickerPopover= [[UIPopoverController alloc] initWithContentViewController:vc];
    [colorPickerPopover setPopoverContentSize:CGSizeMake(130,300) animated:NO];
    [colorPickerPopover presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (IBAction)onTrash:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Clear scratchPad" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        scratchPad.toolType = DAScratchPadToolTypePaint;
        [scratchPad clearToColor:[UIColor clearColor]];
        //save pre-scratch on local
        [self saveImageToLocalWithImage:scratchPad.getSketch withName:imageNamesForPages[selectedPage]];
    }];
    
    [alert addAction:actionCancel];
    alert.view.tintColor = [UIColor redColor];
    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
    popPresenter.sourceView = btnTrash;
    popPresenter.sourceRect = btnTrash.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)onEraser:(id)sender {
    btnPen.tintColor = [UIColor whiteColor];
    btnTrash.tintColor = [UIColor whiteColor];
    btnEraser.tintColor = COLOR_SELECTED;
    scratchPad.toolType = DAScratchPadToolTypeEraser;
    scratchPad.drawColor = [UIColor clearColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    UIView *viewToChangeColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
    [viewToChangeColor addSubview:eraserThicknessSlider];
    
    vc.view = viewToChangeColor;
    eraserPickerPopover= [[UIPopoverController alloc] initWithContentViewController:vc];
    [eraserPickerPopover setPopoverContentSize:CGSizeMake(120,30) animated:NO];
    [eraserPickerPopover presentPopoverFromRect:[sender bounds] inView:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (IBAction)onMenu:(id)sender {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    UIAlertAction* actionSave = [UIAlertAction actionWithTitle:@"SAVE" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [self saveImageToLocalWithImage:scratchPad.getSketch withName:imageNamesForPages[selectedPage]];
        [self saveCurrentScratchInPhotoAlbum];
//
//    }];
//
//    [alert addAction:actionSave];
//    alert.view.tintColor = COLOR_BRASH_SELECTED;
//    UIPopoverPresentationController *popPresenter = [alert  popoverPresentationController];
//    popPresenter.sourceView = btnMenu;
//    popPresenter.sourceRect = btnMenu.bounds;
//    [self presentViewController:alert animated:YES completion:nil];
    
    
}

- (NSString *)getCompletedImageWithPage{
    CGRect cvRect = padBGScrView.frame;
    if (cvRect.size.width > cvRect.size.height) {
        cvRect.size.height = cvRect.size.width * cvRect.size.width/cvRect.size.height;
    }
    
    UIView *pageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    pageView.backgroundColor = [UIColor blackColor];
    switch (segmentedDrawPad.selectedSegmentIndex) {
        case 0://page 1
        {
            break;
        }
        case 1://page 2
        {
            pageView = [self getNOTES];
            break;
        }
        case 2://WX
        {
            pageView = [self getWXView];
            break;
        }
        case 3://CRAFT
        {
            pageView = [self getCraftView];
            break;
        }
        case 4://PIREP
        {
            pageView = [self getPirepView];
            break;
        }
        case 5://FLIGHT PLAN
        {
            pageView = [self getFlightPlanView];
            break;
        }
        default:
            break;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    UIImage *imageToLoad = [UIImage imageWithContentsOfFile:[basePath stringByAppendingPathComponent:imageNamesForPages[selectedPage]]];
    [imageView setBackgroundColor:[UIColor clearColor]];
    imageView.image =imageToLoad;
    [pageView addSubview:imageView];
    
    UIGraphicsBeginImageContext(pageView.frame.size);
    [[pageView layer] renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [self saveImageToLocalWithImage:screenshot withName:[NSString stringWithFormat:@"screenshot_%.f.png", [[NSDate date] timeIntervalSince1970] * 1000000]];
}

- (IBAction)onColorSelected:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *currentBtn = (UIButton *)sender;
        selectedColorIndex = currentBtn.tag - 300;
    }
    
    for (UIView *currentSubView in colorsView.subviews) {
        if ([currentSubView isKindOfClass:[UIButton class]]) {
            UIButton *currentButton = (UIButton *)currentSubView;
            if (currentButton.tag ==300 + selectedColorIndex) {
                currentButton.layer.borderWidth = 5.0f;
                currentButton.layer.borderColor = COLOR_SELECTED.CGColor;
            }else{
                currentButton.layer.borderWidth = 0.0f;
                currentButton.layer.borderColor = [UIColor clearColor].CGColor;
            }
        }
    }
    switch (selectedColorIndex) {
        case 0:
            scratchPad.drawColor = COLOR_BRASH_RED;
            btnPen.tintColor = COLOR_BRASH_RED;
            txtFieldToEnter.textColor = COLOR_BRASH_RED;
            break;
        case 1:
            scratchPad.drawColor = COLOR_BRASH_SKY;
            btnPen.tintColor = COLOR_BRASH_SKY;
            txtFieldToEnter.textColor = COLOR_BRASH_SKY;
            break;
        case 2:
            scratchPad.drawColor = COLOR_BRASH_GREEN;
            btnPen.tintColor = COLOR_BRASH_GREEN;
            txtFieldToEnter.textColor = COLOR_BRASH_GREEN;
            break;
        case 3:
            scratchPad.drawColor = COLOR_BRASH_PINK;
            btnPen.tintColor = COLOR_BRASH_PINK;
            txtFieldToEnter.textColor = COLOR_BRASH_PINK;
            break;
        case 4:
            scratchPad.drawColor = COLOR_BRASH_BLUE;
            btnPen.tintColor = COLOR_BRASH_BLUE;
            txtFieldToEnter.textColor = COLOR_BRASH_BLUE;
            break;
        case 5:
            scratchPad.drawColor = COLOR_BRASH_YELLO;
            btnPen.tintColor = COLOR_BRASH_YELLO;
            txtFieldToEnter.textColor = COLOR_BRASH_YELLO;
            break;
        case 6:
            scratchPad.drawColor = [UIColor whiteColor];
            btnPen.tintColor = [UIColor whiteColor];
            txtFieldToEnter.textColor = [UIColor whiteColor];
            break;
            
        default:
            break;
    }
    [colorPickerPopover dismissPopoverAnimated:YES];
}

- (IBAction)onChangeThickness:(id)sender {
    scratchPad.drawWidth = penThicknessSlider.value;
    txtFieldToEnter.font = [UIFont fontWithName:@"Helvetica-Bold" size:penThicknessSlider.value + 20];
}

- (IBAction)onChangeEraserThicknessSlider:(id)sender {
    scratchPad.eraserDrawWidth = eraserThicknessSlider.value;
}

- (IBAction)onChangePadStyle:(id)sender {
    btnPadStypeChanve.selected = !btnPadStypeChanve.selected;
    isStandard = btnPadStypeChanve.selected;
    [self reloadCurrentPadWithSegment];
}

- (IBAction)onFullScreen:(id)sender {
    btnFullScreen.selected = !btnFullScreen.selected;
    if (btnFullScreen.selected){
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }else{
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    [scratchPad setFrame:CGRectMake(0, 0, padBGScrView.frame.size.width, padBGScrView.frame.size.height)];
    [self reloadCurrentPadWithSegment];
}
- (void)saveCurrentScratchInPhotoAlbum{
    NSString *currentPDFPath = [self getCompletedImageWithPage];
    [AppDelegate sharedDelegate].filePathToImportMyDocs = [NSURL URLWithString:[[NSString stringWithFormat:@"file://%@", currentPDFPath] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    ActivityViewCustomActivity *aVCA = [[ActivityViewCustomActivity alloc]init];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:[AppDelegate sharedDelegate].filePathToImportMyDocs, nil] applicationActivities:[NSArray arrayWithObject:aVCA]];
    
    NSArray *excludeActivities = @[UIActivityTypeOpenInIBooks ];
    
    activityVC.excludedActivityTypes = excludeActivities;
    activityVC.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        NSLog(@"ActivityType: %@", activityType);
        NSLog(@"Completed: %i", completed);
    };
    activityVC.popoverPresentationController.sourceView = self.view;
    activityVC.popoverPresentationController.sourceRect = btnMenu.frame;
    UIPopoverController* _popover = [[UIPopoverController alloc] initWithContentViewController:activityVC];
    _popover.delegate = self;
    [self presentViewController:activityVC
                       animated:YES
                     completion:nil];
}
- (NSString *)saveImageToLocalWithImage:(UIImage *)image withName:(NSString *)name{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSData * binaryImageData = UIImagePNGRepresentation(image);
    
    [binaryImageData writeToFile:[basePath stringByAppendingPathComponent:name] atomically:YES];
    return [basePath stringByAppendingPathComponent:name];
}
- (UIView *)getNOTES{
    CGRect cvRect = padBGScrView.frame;
    UIFont *changedLabelFont = FONT_LABEL;
    if (self.view.frame.size.width > self.view.frame.size.height) {
        changedLabelFont = FONT_LABEL_SMALL;
    }
    if (cvRect.size.width > cvRect.size.height) {
        cvRect.size.height = cvRect.size.width * cvRect.size.width/cvRect.size.height;
    }
    UIView *backgroundCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    backgroundCV.tag = 5001;
    [backgroundCV setBackgroundColor:[UIColor blackColor]];
    UIColor *lblColor = [UIColor whiteColor];
    if (isStandard) {
        lblColor = [UIColor blackColor];
        [backgroundCV setBackgroundColor:[UIColor whiteColor]];
    }
    
    CGFloat positionY = 80;
    
    UIView *nameCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 2/3 + 1, positionY + 1)];
    nameCV.backgroundColor = [UIColor clearColor];
    nameCV.layer.borderColor =  COLOR_BORDER.CGColor;
    nameCV.layer.borderWidth = 1.0f;
    
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width*2/3, 30.0f)];
    nameLbl.textAlignment = NSTextAlignmentCenter;
    nameLbl.text = @"NAME";
    
    nameLbl.font = changedLabelFont;
    nameLbl.textColor = lblColor;
    
    [nameCV addSubview:nameLbl];
    [backgroundCV addSubview:nameCV];
    
    UIView *dateCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/3, 0, cvRect.size.width/3, positionY + 1)];
    dateCV.backgroundColor = [UIColor clearColor];
    dateCV.layer.borderColor =  COLOR_BORDER.CGColor;
    dateCV.layer.borderWidth = 1.0f;
    
    UILabel *dateLBL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3, 30.0f)];
    dateLBL.textAlignment = NSTextAlignmentCenter;
    dateLBL.text = @"DATE";
    dateLBL.font = changedLabelFont;
    dateLBL.textColor = lblColor;
    
    [dateCV addSubview:dateLBL];
    [backgroundCV addSubview:dateCV];
    
    UIView *sessionCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY, cvRect.size.width, positionY + 1)];
    sessionCV.backgroundColor = [UIColor clearColor];
    sessionCV.layer.borderColor =  COLOR_BORDER.CGColor;
    sessionCV.layer.borderWidth = 1.0f;
    
    UILabel *sessionLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 150, positionY)];
    sessionLbl.textAlignment = NSTextAlignmentLeft;
    sessionLbl.text = @"SESSION:";
    sessionLbl.font = changedLabelFont;
    sessionLbl.textColor = lblColor;
    
    [sessionCV addSubview:sessionLbl];
    [backgroundCV addSubview:sessionCV];
    
    positionY = (cvRect.size.height - 2 * positionY) / 3;
    
    UIView *planTaskCV = [[UIView alloc] initWithFrame:CGRectMake(0, 160, cvRect.size.width, positionY + 1)];
    planTaskCV.backgroundColor = [UIColor clearColor];
    planTaskCV.layer.borderColor =  COLOR_BORDER.CGColor;
    planTaskCV.layer.borderWidth = 1.0f;
    
    UILabel *planTaskLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 150, 30.0f)];
    planTaskLbl.textAlignment = NSTextAlignmentLeft;
    planTaskLbl.text = @"PLAN/TASKS:";
    planTaskLbl.font = changedLabelFont;
    planTaskLbl.textColor = lblColor;
    
    UILabel *hobbsTachLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width-150, 0, 150, 30.0f)];
    hobbsTachLbl.textAlignment = NSTextAlignmentCenter;
    hobbsTachLbl.text = @"HOBBS/TACH:";
    hobbsTachLbl.font = changedLabelFont;
    hobbsTachLbl.textColor = lblColor;
    
    UILabel *hobbsTachLineFirst = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width-150, 30, 150, 30.0f)];
    hobbsTachLineFirst.textAlignment = NSTextAlignmentCenter;
    hobbsTachLineFirst.text = @"|";
    hobbsTachLineFirst.font = changedLabelFont;
    hobbsTachLineFirst.textColor = lblColor;
    
    UILabel *hobbsTachLineSecond = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width-150, 60, 150, 30.0f)];
    hobbsTachLineSecond.textAlignment = NSTextAlignmentCenter;
    hobbsTachLineSecond.text = @"|";
    hobbsTachLineSecond.font = changedLabelFont;
    hobbsTachLineSecond.textColor = lblColor;
    
    [planTaskCV addSubview:planTaskLbl];
    [planTaskCV addSubview:hobbsTachLbl];
    [planTaskCV addSubview:hobbsTachLineFirst];
    [planTaskCV addSubview:hobbsTachLineSecond];
    [backgroundCV addSubview:planTaskCV];
    
    
    UIView *errorCV = [[UIView alloc] initWithFrame:CGRectMake(0, 160 + positionY, cvRect.size.width, positionY + 1)];
    errorCV.backgroundColor = [UIColor clearColor];
    errorCV.layer.borderColor =  COLOR_BORDER.CGColor;
    errorCV.layer.borderWidth = 1.0f;
    
    UILabel *errorlbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 150, 30.0f)];
    errorlbl.textAlignment = NSTextAlignmentLeft;
    errorlbl.text = @"ERRORS:";
    errorlbl.font = changedLabelFont;
    errorlbl.textColor = lblColor;
    
    [errorCV addSubview:errorlbl];
    [backgroundCV addSubview:errorCV];
    
    UIView *feedbackAssignmentCV = [[UIView alloc] initWithFrame:CGRectMake(0, 160 + positionY * 2, cvRect.size.width, positionY + 1)];
    feedbackAssignmentCV.backgroundColor = [UIColor clearColor];
    feedbackAssignmentCV.layer.borderColor =  COLOR_BORDER.CGColor;
    feedbackAssignmentCV.layer.borderWidth = 1.0f;
    
    UILabel *feedbackAssignmentLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 250, 30.0f)];
    feedbackAssignmentLbl.textAlignment = NSTextAlignmentLeft;
    feedbackAssignmentLbl.text = @"FEEDBACK/ASSIGNMENT(S):";
    feedbackAssignmentLbl.font = changedLabelFont;
    feedbackAssignmentLbl.textColor = lblColor;
    
    [feedbackAssignmentCV addSubview:feedbackAssignmentLbl];
    [backgroundCV addSubview:feedbackAssignmentCV];
    
    return backgroundCV;
}
- (UIView *)getWXView{
    CGRect cvRect = padBGScrView.frame;
    UIFont *changedLabelFont = FONT_LABEL;
    UIFont *changedContentFont = FONT_CONTENT;
    if (self.view.frame.size.width > self.view.frame.size.height) {
        changedLabelFont = FONT_LABEL_SMALL;
        changedContentFont = FONT_CONTENT_SMALL;
    }
    if (cvRect.size.width > cvRect.size.height) {
        cvRect.size.height = cvRect.size.width * cvRect.size.width/cvRect.size.height;
    }
    UIView *backgroundCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    backgroundCV.tag = 5001;
    [backgroundCV setBackgroundColor:[UIColor blackColor]];
    UIColor *lblColor = [UIColor whiteColor];
    if (isStandard) {
        lblColor = [UIColor blackColor];
        [backgroundCV setBackgroundColor:[UIColor whiteColor]];
    }
    
    CGFloat positionY = cvRect.size.height / 8;
    
    UIView *airportCV = [[UIView alloc] initWithFrame:CGRectMake(-1, 0, cvRect.size.width/3 + 1, positionY + 1)];
    airportCV.backgroundColor = [UIColor clearColor];
    airportCV.layer.borderColor =  COLOR_BORDER.CGColor;
    airportCV.layer.borderWidth = 1.0f;
    
    UILabel *airportLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3, 30.0f)];
    airportLbl.textAlignment = NSTextAlignmentCenter;
    airportLbl.text = @"AIRPORT";
    airportLbl.font = changedLabelFont;
    airportLbl.textColor = lblColor;
    
    [airportCV addSubview:airportLbl];
    [backgroundCV addSubview:airportCV];
    
    UIView *informationCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/3, 0, cvRect.size.width/3 + 1, positionY + 1)];
    informationCV.backgroundColor = [UIColor clearColor];
    informationCV.layer.borderColor =  COLOR_BORDER.CGColor;
    informationCV.layer.borderWidth = 1.0f;
    
    UILabel *informationLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3, 30.0f)];
    informationLbl.textAlignment = NSTextAlignmentCenter;
    informationLbl.text = @"INFORMATION";
    informationLbl.font = changedLabelFont;
    informationLbl.textColor = lblColor;
    
    [informationCV addSubview:informationLbl];
    [backgroundCV addSubview:informationCV];
    
    UIView *timeCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/3, 0, cvRect.size.width/3 + 2, positionY + 1)];
    timeCV.backgroundColor = [UIColor clearColor];
    timeCV.layer.borderColor =  COLOR_BORDER.CGColor;
    timeCV.layer.borderWidth = 1.0f;
    
    UILabel *timeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3, 30.0f)];
    timeLbl.textAlignment = NSTextAlignmentCenter;
    timeLbl.text = @"TIME";
    timeLbl.font = changedLabelFont;
    timeLbl.textColor = lblColor;
    
    [timeCV addSubview:timeLbl];
    [backgroundCV addSubview:timeCV];
    
    UIView *windCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY, cvRect.size.width * 2/3 + 2, positionY + 1)];
    windCV.backgroundColor = [UIColor clearColor];
    windCV.layer.borderColor =  COLOR_BORDER.CGColor;
    windCV.layer.borderWidth = 1.0f;
    
    UILabel *windLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width*2/3, 30.0f)];
    windLbl.textAlignment = NSTextAlignmentCenter;
    windLbl.text = @"WIND";
    windLbl.font = changedLabelFont;
    windLbl.textColor = lblColor;
    
    UILabel *windContentFirst = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/6, (positionY-50)/2, cvRect.size.width/6, 50.0f)];
    windContentFirst.textAlignment = NSTextAlignmentCenter;
    windContentFirst.text = @"@";
    windContentFirst.font = changedContentFont;
    windContentFirst.textColor = COLOR_CONTENT;
    
    UILabel *windContentSecond = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/3, (positionY-50)/2, cvRect.size.width/3, 50.0f)];
    windContentSecond.textAlignment = NSTextAlignmentCenter;
    windContentSecond.text = @"G";
    windContentSecond.font = changedContentFont;
    windContentSecond.textColor = COLOR_CONTENT;
    
    [windCV addSubview:windLbl];
    [windCV addSubview:windContentFirst];
    [windCV addSubview:windContentSecond];
    [backgroundCV addSubview:windCV];
    
    UIView *visiblilityCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/3, positionY, cvRect.size.width/3 + 2, positionY + 1)];
    visiblilityCV.backgroundColor = [UIColor clearColor];
    visiblilityCV.layer.borderColor =  COLOR_BORDER.CGColor;
    visiblilityCV.layer.borderWidth = 1.0f;
    
    UILabel *visibilityLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3-70, 30.0f)];
    visibilityLbl.textAlignment = NSTextAlignmentCenter;
    visibilityLbl.text = @"VISIBILITY";
    visibilityLbl.font = changedLabelFont;
    visibilityLbl.textColor = lblColor;
    float heightOfvisibilityItem = (positionY - 35)/4;
    float widthOfvisibilityItem = 70;
    
    UILabel *brhzLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/3-widthOfvisibilityItem, 20, widthOfvisibilityItem, (positionY - 30)/4)];
    brhzLbl.textAlignment = NSTextAlignmentCenter;
    brhzLbl.text = @"BR HZ";
    brhzLbl.font = changedLabelFont;
    brhzLbl.textColor = lblColor;
    
    UILabel *rafgLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/3-widthOfvisibilityItem, 20 + heightOfvisibilityItem, widthOfvisibilityItem, (positionY - 30)/4)];
    rafgLbl.textAlignment = NSTextAlignmentCenter;
    rafgLbl.text = @"RA FG";
    rafgLbl.font = changedLabelFont;
    rafgLbl.textColor = lblColor;
    
    UILabel *snsqLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/3-widthOfvisibilityItem, 20 + heightOfvisibilityItem * 2, widthOfvisibilityItem, (positionY - 30)/4)];
    snsqLbl.textAlignment = NSTextAlignmentCenter;
    snsqLbl.text = @"SN SQ";
    snsqLbl.font = changedLabelFont;
    snsqLbl.textColor = lblColor;
    
    UILabel *tsvaLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/3-widthOfvisibilityItem, 20 + heightOfvisibilityItem * 3, widthOfvisibilityItem, (positionY - 30)/4)];
    tsvaLbl.textAlignment = NSTextAlignmentCenter;
    tsvaLbl.text = @"TS VA";
    tsvaLbl.font = changedLabelFont;
    tsvaLbl.textColor = lblColor;
    
    [visiblilityCV addSubview:visibilityLbl];
    [visiblilityCV addSubview:brhzLbl];
    [visiblilityCV addSubview:rafgLbl];
    [visiblilityCV addSubview:snsqLbl];
    [visiblilityCV addSubview:tsvaLbl];
    [backgroundCV addSubview:visiblilityCV];
    
    UIView *skyConditionsFirstCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 2, cvRect.size.width+2, positionY + 1)];
    skyConditionsFirstCV.backgroundColor = [UIColor clearColor];
    skyConditionsFirstCV.layer.borderColor =  COLOR_BORDER.CGColor;
    skyConditionsFirstCV.layer.borderWidth = 1.0f;
    
    UILabel *skyConditionsLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, 30.0f)];
    skyConditionsLbl.textAlignment = NSTextAlignmentCenter;
    skyConditionsLbl.text = @"SKY CONDITIONS";
    skyConditionsLbl.font = changedLabelFont;
    skyConditionsLbl.textColor = lblColor;
    
    float widthConditionItem = cvRect.size.width/10 - 3;
    
    UILabel *skyClrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2, (positionY-50)/2, widthConditionItem, 50.0f)];
    skyClrLbl.textAlignment = NSTextAlignmentCenter;
    skyClrLbl.text = @"CLR";
    skyClrLbl.font = changedContentFont;
    skyClrLbl.textColor = COLOR_CONTENT;
    
    UILabel *skyFEWLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem, (positionY-50)/2, widthConditionItem, 50.0f)];
    skyFEWLbl.textAlignment = NSTextAlignmentCenter;
    skyFEWLbl.text = @"FEW";
    skyFEWLbl.font = changedContentFont;
    skyFEWLbl.textColor = COLOR_CONTENT;
    
    UILabel *skySCTLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 2, (positionY-50)/2, widthConditionItem, 50.0f)];
    skySCTLbl.textAlignment = NSTextAlignmentCenter;
    skySCTLbl.text = @"SCT";
    skySCTLbl.font = changedContentFont;
    skySCTLbl.textColor = COLOR_CONTENT;
    
    UILabel *skyBKNLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 3, (positionY-50)/2, widthConditionItem, 50.0f)];
    skyBKNLbl.textAlignment = NSTextAlignmentCenter;
    skyBKNLbl.text = @"BKN";
    skyBKNLbl.font = changedContentFont;
    skyBKNLbl.textColor = COLOR_CONTENT;
    
    UILabel *skyOVCLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 4, (positionY-50)/2, widthConditionItem, 50.0f)];
    skyOVCLbl.textAlignment = NSTextAlignmentCenter;
    skyOVCLbl.text = @"OVC";
    skyOVCLbl.font = changedContentFont;
    skyOVCLbl.textColor = COLOR_CONTENT;
    
    [skyConditionsFirstCV addSubview:skyConditionsLbl];
    [skyConditionsFirstCV addSubview:skyClrLbl];
    [skyConditionsFirstCV addSubview:skyFEWLbl];
    [skyConditionsFirstCV addSubview:skySCTLbl];
    [skyConditionsFirstCV addSubview:skyBKNLbl];
    [skyConditionsFirstCV addSubview:skyOVCLbl];
    [backgroundCV addSubview:skyConditionsFirstCV];
    
    UIView *skyConditionsSecondCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 3, cvRect.size.width+2, positionY + 1)];
    skyConditionsSecondCV.backgroundColor = [UIColor clearColor];
    skyConditionsSecondCV.layer.borderColor =  COLOR_BORDER.CGColor;
    skyConditionsSecondCV.layer.borderWidth = 1.0f;
    
    UILabel *sky2ClrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky2ClrLbl.textAlignment = NSTextAlignmentCenter;
    sky2ClrLbl.text = @"CLR";
    sky2ClrLbl.font = changedContentFont;
    sky2ClrLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky2FEWLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky2FEWLbl.textAlignment = NSTextAlignmentCenter;
    sky2FEWLbl.text = @"FEW";
    sky2FEWLbl.font = changedContentFont;
    sky2FEWLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky2SCTLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 2, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky2SCTLbl.textAlignment = NSTextAlignmentCenter;
    sky2SCTLbl.text = @"SCT";
    sky2SCTLbl.font = changedContentFont;
    sky2SCTLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky2BKNLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 3, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky2BKNLbl.textAlignment = NSTextAlignmentCenter;
    sky2BKNLbl.text = @"BKN";
    sky2BKNLbl.font = changedContentFont;
    sky2BKNLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky2OVCLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 4, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky2OVCLbl.textAlignment = NSTextAlignmentCenter;
    sky2OVCLbl.text = @"OVC";
    sky2OVCLbl.font = changedContentFont;
    sky2OVCLbl.textColor = COLOR_CONTENT;
    
    [skyConditionsSecondCV addSubview:sky2ClrLbl];
    [skyConditionsSecondCV addSubview:sky2FEWLbl];
    [skyConditionsSecondCV addSubview:sky2SCTLbl];
    [skyConditionsSecondCV addSubview:sky2BKNLbl];
    [skyConditionsSecondCV addSubview:sky2OVCLbl];
    [backgroundCV addSubview:skyConditionsSecondCV];
    
    UIView *skyConditionsThirdCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 4, cvRect.size.width+2, positionY + 1)];
    skyConditionsThirdCV.backgroundColor = [UIColor clearColor];
    skyConditionsThirdCV.layer.borderColor =  COLOR_BORDER.CGColor;
    skyConditionsThirdCV.layer.borderWidth = 1.0f;
    
    UILabel *sky3ClrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky3ClrLbl.textAlignment = NSTextAlignmentCenter;
    sky3ClrLbl.text = @"CLR";
    sky3ClrLbl.font = changedContentFont;
    sky3ClrLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky3FEWLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky3FEWLbl.textAlignment = NSTextAlignmentCenter;
    sky3FEWLbl.text = @"FEW";
    sky3FEWLbl.font = changedContentFont;
    sky3FEWLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky3SCTLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 2, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky3SCTLbl.textAlignment = NSTextAlignmentCenter;
    sky3SCTLbl.text = @"SCT";
    sky3SCTLbl.font = changedContentFont;
    sky3SCTLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky3BKNLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 3, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky3BKNLbl.textAlignment = NSTextAlignmentCenter;
    sky3BKNLbl.text = @"BKN";
    sky3BKNLbl.font = changedContentFont;
    sky3BKNLbl.textColor = COLOR_CONTENT;
    
    UILabel *sky3OVCLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/2 + widthConditionItem * 4, (positionY-50)/2, widthConditionItem, 50.0f)];
    sky3OVCLbl.textAlignment = NSTextAlignmentCenter;
    sky3OVCLbl.text = @"OVC";
    sky3OVCLbl.font = changedContentFont;
    sky3OVCLbl.textColor = COLOR_CONTENT;
    
    [skyConditionsThirdCV addSubview:sky3ClrLbl];
    [skyConditionsThirdCV addSubview:sky3FEWLbl];
    [skyConditionsThirdCV addSubview:sky3SCTLbl];
    [skyConditionsThirdCV addSubview:sky3BKNLbl];
    [skyConditionsThirdCV addSubview:sky3OVCLbl];
    [backgroundCV addSubview:skyConditionsThirdCV];
    
    UIView *tempCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 5, cvRect.size.width/4+1, positionY + 1)];
    tempCV.backgroundColor = [UIColor clearColor];
    tempCV.layer.borderColor =  COLOR_BORDER.CGColor;
    tempCV.layer.borderWidth = 1.0f;
    
    UILabel *tempLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/4, 30.0f)];
    tempLbl.textAlignment = NSTextAlignmentCenter;
    tempLbl.text = @"TEMP";
    tempLbl.font = changedLabelFont;
    tempLbl.textColor = lblColor;
    
    [tempCV addSubview:tempLbl];
    [backgroundCV addSubview:tempCV];
    
    UIView *dewpointCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/4, positionY * 5, cvRect.size.width/4+1, positionY + 1)];
    dewpointCV.backgroundColor = [UIColor clearColor];
    dewpointCV.layer.borderColor =  COLOR_BORDER.CGColor;
    dewpointCV.layer.borderWidth = 1.0f;
    
    UILabel *dewpointLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/4, 30.0f)];
    dewpointLbl.textAlignment = NSTextAlignmentCenter;
    dewpointLbl.text = @"DEWPOINT";
    dewpointLbl.font = changedLabelFont;
    dewpointLbl.textColor = lblColor;
    
    [dewpointCV addSubview:dewpointLbl];
    [backgroundCV addSubview:dewpointCV];
    
    UIView *altimeterCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/2, positionY * 5, cvRect.size.width/2+2, positionY + 1)];
    altimeterCV.backgroundColor = [UIColor clearColor];
    altimeterCV.layer.borderColor =  COLOR_BORDER.CGColor;
    altimeterCV.layer.borderWidth = 1.0f;
    
    UILabel *altimeterLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/2, 30.0f)];
    altimeterLbl.textAlignment = NSTextAlignmentCenter;
    altimeterLbl.text = @"ALTEIMTER";
    altimeterLbl.font = changedLabelFont;
    altimeterLbl.textColor = lblColor;
    
    [altimeterCV addSubview:altimeterLbl];
    [backgroundCV addSubview:altimeterCV];
    
    UIView *runwayCV = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 6, cvRect.size.width/3+1, positionY*2 + 2)];
    runwayCV.backgroundColor = [UIColor clearColor];
    runwayCV.layer.borderColor =  COLOR_BORDER.CGColor;
    runwayCV.layer.borderWidth = 1.0f;
    
    UILabel *runwayLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/3, 30.0f)];
    runwayLbl.textAlignment = NSTextAlignmentCenter;
    runwayLbl.text = @"RUNWAY";
    runwayLbl.font = changedLabelFont;
    runwayLbl.textColor = lblColor;
    
    [runwayCV addSubview:runwayLbl];
    [backgroundCV addSubview:runwayCV];
    
    UIView *remarksCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/3, positionY * 6, cvRect.size.width *2/3+2, positionY*2 + 2)];
    remarksCV.backgroundColor = [UIColor clearColor];
    remarksCV.layer.borderColor =  COLOR_BORDER.CGColor;
    remarksCV.layer.borderWidth = 1.0f;
    
    UILabel *remarksLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width *2/3, 30.0f)];
    remarksLbl.textAlignment = NSTextAlignmentCenter;
    remarksLbl.text = @"REMARKS";
    remarksLbl.font = changedLabelFont;
    remarksLbl.textColor = lblColor;
    
    [remarksCV addSubview:remarksLbl];
    [backgroundCV addSubview:remarksCV];

    return backgroundCV;
}
- (UIView *)getCraftView{
    CGRect cvRect = padBGScrView.frame;
    if (cvRect.size.width > cvRect.size.height) {
        cvRect.size.height = cvRect.size.width * cvRect.size.width/cvRect.size.height;
    }
    UIView *backgroundCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    backgroundCV.tag = 5001;
    [backgroundCV setBackgroundColor:[UIColor blackColor]];
    UIColor *lblColor = [UIColor whiteColor];
    if (isStandard) {
        lblColor = [UIColor blackColor];
        [backgroundCV setBackgroundColor:[UIColor whiteColor]];
    }
    
    CGFloat positionY = cvRect.size.height / 5;
    
    UIView *line0 = [[UIView alloc] initWithFrame:CGRectMake(-1, 0, cvRect.size.width+2, 1)];
    line0.backgroundColor = COLOR_BORDER;
    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY, cvRect.size.width+2, 1)];
    line1.backgroundColor = COLOR_BORDER;
    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 2, cvRect.size.width+2, 1)];
    line2.backgroundColor = COLOR_BORDER;
    UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 3, cvRect.size.width+2, 1)];
    line3.backgroundColor = COLOR_BORDER;
    UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(-1, positionY * 4, cvRect.size.width+2, 1)];
    line4.backgroundColor = COLOR_BORDER;
    
    [backgroundCV addSubview:line0];
    [backgroundCV addSubview:line1];
    [backgroundCV addSubview:line2];
    [backgroundCV addSubview:line3];
    [backgroundCV addSubview:line4];
    
    UILabel *firstOfCraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, positionY)];
    firstOfCraftLbl.textAlignment = NSTextAlignmentCenter;
    firstOfCraftLbl.text = @"C";
    firstOfCraftLbl.font =  [UIFont fontWithName:@"Helvetica" size:60];;
    firstOfCraftLbl.textColor = COLOR_CONTENT;
    
    UILabel *secondOfCraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY, 100, positionY)];
    secondOfCraftLbl.textAlignment = NSTextAlignmentCenter;
    secondOfCraftLbl.text = @"R";
    secondOfCraftLbl.font =  [UIFont fontWithName:@"Helvetica" size:60];;
    secondOfCraftLbl.textColor = COLOR_CONTENT;
    
    UILabel *thirdOfCraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY * 2, 100, positionY)];
    thirdOfCraftLbl.textAlignment = NSTextAlignmentCenter;
    thirdOfCraftLbl.text = @"A";
    thirdOfCraftLbl.font =  [UIFont fontWithName:@"Helvetica" size:60];;
    thirdOfCraftLbl.textColor = COLOR_CONTENT;
    
    UILabel *forthOfCraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY * 3, 100, positionY)];
    forthOfCraftLbl.textAlignment = NSTextAlignmentCenter;
    forthOfCraftLbl.text = @"F";
    forthOfCraftLbl.font =  [UIFont fontWithName:@"Helvetica" size:60];;
    forthOfCraftLbl.textColor = COLOR_CONTENT;
    
    UILabel *fifthOfCraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY * 4, 100, positionY)];
    fifthOfCraftLbl.textAlignment = NSTextAlignmentCenter;
    fifthOfCraftLbl.text = @"T";
    fifthOfCraftLbl.font =  [UIFont fontWithName:@"Helvetica" size:60];;
    fifthOfCraftLbl.textColor = COLOR_CONTENT;
    
    [backgroundCV addSubview:firstOfCraftLbl];
    [backgroundCV addSubview:secondOfCraftLbl];
    [backgroundCV addSubview:thirdOfCraftLbl];
    [backgroundCV addSubview:forthOfCraftLbl];
    [backgroundCV addSubview:fifthOfCraftLbl];
    
    return backgroundCV;
}
- (UIView *)getPirepView{
    CGRect cvRect = padBGScrView.frame;
    UIFont *changedLabelFont = FONT_LABEL;
    if (self.view.frame.size.width > self.view.frame.size.height) {
        changedLabelFont = FONT_LABEL_SMALL;
    }
    if (cvRect.size.width > cvRect.size.height) {
        cvRect.size.height = cvRect.size.width * cvRect.size.width/cvRect.size.height;
    }
    UIView *backgroundCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    backgroundCV.tag = 5001;
    [backgroundCV setBackgroundColor:[UIColor blackColor]];
    UIColor *lblColor = [UIColor whiteColor];
    if (isStandard) {
        lblColor = [UIColor blackColor];
        [backgroundCV setBackgroundColor:[UIColor whiteColor]];
    }
    CGFloat positionY = cvRect.size.height / 12;
    NSArray *lblArray = [[NSArray alloc] initWithObjects:@"PIREP TYPE",@"LOCATION (/OV)",@"TIME (/TM)",@"ALTITUDE / FLIGHT LEVEL (/FL)", @"AIRCRAFT TYPE (/TP)", @"SKY COVER (/SK)", @"VISIBILITY AND WEATHER (/WX)", @"TEMPERATURE (CELSIUS) (/TA)", @"WIND (/WV)", @"TURBULENCE (/TB)", @"ICING (/IC)", @"REMARKS (/RM)", nil];
    for (int i = 0; i < 12 ; i ++) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, positionY * i, cvRect.size.width, 1)];
        line.backgroundColor = COLOR_BORDER;
        
        UILabel *contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(40.0f, positionY * i, cvRect.size.width-80.0f, 40.0f)];
        contentLbl.textAlignment = NSTextAlignmentLeft;
        contentLbl.text = lblArray[i];
        contentLbl.font = changedLabelFont;
        contentLbl.textColor = lblColor;
        
        [backgroundCV addSubview:line];
        [backgroundCV addSubview:contentLbl];
    }
    
    UILabel *routineLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width-40.0f, positionY)];
    routineLbl.textAlignment = NSTextAlignmentRight;
    routineLbl.text = @"ROUTINE (UA)   URGEN";
    routineLbl.font = changedLabelFont;
    routineLbl.textColor = lblColor;
    
    [backgroundCV addSubview:routineLbl];
    return backgroundCV;
}
- (UIView *)getFlightPlanView{
    CGRect cvRect = padBGScrView.frame;
    UIView *backgroundCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width, cvRect.size.height)];
    
    backgroundCV.tag = 5001;
    [backgroundCV setBackgroundColor:[UIColor blackColor]];
    UIColor *lblColor = [UIColor whiteColor];
    if (isStandard) {
        lblColor = [UIColor blackColor];
        [backgroundCV setBackgroundColor:[UIColor whiteColor]];
    }
    CGFloat positionY = (cvRect.size.height - 80) / 7;
    
    UIView *flightPlanTitleCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 2.5/9 + 1, positionY + 1)];
    flightPlanTitleCV.backgroundColor = [UIColor clearColor];
    flightPlanTitleCV.layer.borderColor =  COLOR_BORDER.CGColor;
    flightPlanTitleCV.layer.borderWidth = 1.0f;
    
    UILabel *flightPlanTitleExp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 2.5/9, 50.0f)];
    flightPlanTitleExp.textAlignment = NSTextAlignmentCenter;
    flightPlanTitleExp.text = @"U.S DEPARTMENT OF TRANSPORTATION FEDERAL AVIATION ADMINISTRATION";
    flightPlanTitleExp.numberOfLines = 0;
    flightPlanTitleExp.font = FONT_LABEL_FLIGHT_PLAN;
    flightPlanTitleExp.textColor = lblColor;
    
    UILabel *flightPlanTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, cvRect.size.width * 2.5/9, positionY - 50.0f)];
    flightPlanTitle.textAlignment = NSTextAlignmentCenter;
    flightPlanTitle.text = @"FLIGHT PLAN";
    flightPlanTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:25];
    flightPlanTitle.textColor = lblColor;
    
    [flightPlanTitleCV addSubview:flightPlanTitleExp];
    [flightPlanTitleCV addSubview:flightPlanTitle];
    [backgroundCV addSubview:flightPlanTitleCV];
    
    UIView *faaUseOnlyCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width * 2.5/9, 0, cvRect.size.width * 4/9 + 1, positionY + 1)];
    faaUseOnlyCV.backgroundColor = [UIColor grayColor];
    faaUseOnlyCV.layer.borderColor =  COLOR_BORDER.CGColor;
    faaUseOnlyCV.layer.borderWidth = 1.0f;
    
    UILabel *faaUserOnlyLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 4/27, positionY/2)];
    faaUserOnlyLbl.textAlignment = NSTextAlignmentCenter;
    faaUserOnlyLbl.text = @"(FAA USE ONLY)";
    faaUserOnlyLbl.numberOfLines = 0;
    faaUserOnlyLbl.font = [UIFont fontWithName:@"Helvetica" size:12];
    faaUserOnlyLbl.textColor = lblColor;
    
    UILabel *plitoBriefingCheck = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width * 4/27-10, (positionY/2-20)/2, 20, 20)];
    plitoBriefingCheck.layer.borderColor =lblColor.CGColor;
    plitoBriefingCheck.layer.borderWidth = 1.0f;
    
    UILabel *plitoBriefingLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width * 4/27, 0, cvRect.size.width * 4/27, positionY/2)];
    plitoBriefingLbl.textAlignment = NSTextAlignmentRight;
    plitoBriefingLbl.text = @"PILOT BRIEFING";
    plitoBriefingLbl.font = [UIFont fontWithName:@"Helvetica" size:12];
    plitoBriefingLbl.textColor = lblColor;
    
    UILabel *vnrCheck = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width * 8/27+20, (positionY/2-20)/2, 20, 20)];
    vnrCheck.layer.borderColor =lblColor.CGColor;
    vnrCheck.layer.borderWidth = 1.0f;
    
    
    UILabel *vnrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width * 8/27, 0, cvRect.size.width * 4/27, positionY/2)];
    vnrLbl.textAlignment = NSTextAlignmentCenter;
    vnrLbl.text = @"VNR";
    vnrLbl.font = [UIFont fontWithName:@"Helvetica" size:12];
    vnrLbl.textColor = lblColor;
    
    UILabel *stopoverCheck = [[UILabel alloc] initWithFrame:CGRectMake((cvRect.size.width * 4/9-120)/2, positionY/2 +(positionY/2-20)/2, 20, 20)];
    stopoverCheck.layer.borderColor =lblColor.CGColor;
    stopoverCheck.layer.borderWidth = 1.0f;
    
    
    UILabel *stopoverLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY/2, cvRect.size.width * 4/9, positionY/2)];
    stopoverLbl.textAlignment = NSTextAlignmentCenter;
    stopoverLbl.text = @"STOPOVER";
    stopoverLbl.font = [UIFont fontWithName:@"Helvetica" size:12];
    stopoverLbl.textColor = lblColor;
    
    
    [faaUseOnlyCV addSubview:plitoBriefingCheck];
    [faaUseOnlyCV addSubview:vnrCheck];
    [faaUseOnlyCV addSubview:stopoverCheck];
    
    [faaUseOnlyCV addSubview:faaUserOnlyLbl];
    [faaUseOnlyCV addSubview:plitoBriefingLbl];
    [faaUseOnlyCV addSubview:vnrLbl];
    [faaUseOnlyCV addSubview:stopoverLbl];
    [backgroundCV addSubview:faaUseOnlyCV];
    
    UIView *timeStartedCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width * 6.5/9, 0, cvRect.size.width * 1.5/9 + 1, positionY + 1)];
    timeStartedCV.backgroundColor = [UIColor grayColor];
    timeStartedCV.layer.borderColor =  COLOR_BORDER.CGColor;
    timeStartedCV.layer.borderWidth = 1.0f;
    
    UILabel *timeStartedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 1.5/9, 30)];
    timeStartedLbl.textAlignment = NSTextAlignmentCenter;
    timeStartedLbl.text = @"TIME STARTED";
    timeStartedLbl.numberOfLines = 0;
    timeStartedLbl.font = FONT_LABEL_FLIGHT_PLAN;
    timeStartedLbl.textColor = lblColor;
    
    [timeStartedCV addSubview:timeStartedLbl];
    [backgroundCV addSubview:timeStartedCV];
    
    UIView *specialistInitialsCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*8/9, 0, cvRect.size.width/9, positionY + 1)];
    specialistInitialsCV.backgroundColor = [UIColor grayColor];
    specialistInitialsCV.layer.borderColor =  COLOR_BORDER.CGColor;
    specialistInitialsCV.layer.borderWidth = 1.0f;
    
    UILabel *specialistInitialsLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/9, 40)];
    specialistInitialsLbl.textAlignment = NSTextAlignmentCenter;
    specialistInitialsLbl.text = @"SPECIALIST INITALS";
    specialistInitialsLbl.numberOfLines = 0;
    specialistInitialsLbl.font = FONT_LABEL_FLIGHT_PLAN;
    specialistInitialsLbl.textColor = lblColor;
    
    [specialistInitialsCV addSubview:specialistInitialsLbl];
    [backgroundCV addSubview:specialistInitialsCV];
    
    UIView *typeCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY, cvRect.size.width/12+1, positionY + 1)];
    typeCV.backgroundColor = [UIColor clearColor];
    typeCV.layer.borderColor =  COLOR_BORDER.CGColor;
    typeCV.layer.borderWidth = 1.0f;
    
    UILabel *typeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/12, positionY/4)];
    typeLbl.textAlignment = NSTextAlignmentCenter;
    typeLbl.text = @"1.TYPE";
    typeLbl.font = FONT_LABEL_FLIGHT_PLAN;
    typeLbl.textColor = lblColor;
    
    UILabel *typeLine0 = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY/4, cvRect.size.width/12, 1)];
    typeLine0.backgroundColor = COLOR_BORDER;
    UILabel *typeLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY/2, cvRect.size.width/12, 1)];
    typeLine1.backgroundColor = COLOR_BORDER;
    UILabel *typeLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, positionY *3/4, cvRect.size.width/12, 1)];
    typeLine2.backgroundColor = COLOR_BORDER;
    UILabel *typeLineV0 = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/36, positionY/4, 1, positionY *3/4)];
    typeLineV0.backgroundColor = COLOR_BORDER;
    
    UILabel *vfrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/36, positionY/4, cvRect.size.width/18, positionY/4)];
    vfrLbl.textAlignment = NSTextAlignmentCenter;
    vfrLbl.text = @"VFR";
    vfrLbl.font = FONT_LABEL_FLIGHT_PLAN;
    vfrLbl.textColor = lblColor;
    
    UILabel *ifrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/36, positionY/2, cvRect.size.width/18, positionY/4)];
    ifrLbl.textAlignment = NSTextAlignmentCenter;
    ifrLbl.text = @"IFR";
    ifrLbl.font = FONT_LABEL_FLIGHT_PLAN;
    ifrLbl.textColor = lblColor;
    
    UILabel *dvfrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/36, positionY*3/4, cvRect.size.width/18, positionY/4)];
    dvfrLbl.textAlignment = NSTextAlignmentCenter;
    dvfrLbl.text = @"DVFR";
    dvfrLbl.font = FONT_LABEL_FLIGHT_PLAN;
    dvfrLbl.textColor = lblColor;
    
    [typeCV addSubview:typeLbl];
    [typeCV addSubview:typeLine0];
    [typeCV addSubview:typeLine1];
    [typeCV addSubview:typeLine2];
    [typeCV addSubview:typeLineV0];
    [typeCV addSubview:vfrLbl];
    [typeCV addSubview:ifrLbl];
    [typeCV addSubview:dvfrLbl];
    [backgroundCV addSubview:typeCV];
    
    UIView *aircraftIdentificationCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/12, positionY, cvRect.size.width * 5/36+1, positionY + 1)];
    aircraftIdentificationCV.backgroundColor = [UIColor clearColor];
    aircraftIdentificationCV.layer.borderColor =  COLOR_BORDER.CGColor;
    aircraftIdentificationCV.layer.borderWidth = 1.0f;
    
    UILabel *aircraftIdentificationLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width * 5/36, 40.0f)];
    aircraftIdentificationLbl.textAlignment = NSTextAlignmentCenter;
    aircraftIdentificationLbl.text = @"2.AIRCRAFT\n  IDENTIFICATION";
    aircraftIdentificationLbl.numberOfLines = 0;
    aircraftIdentificationLbl.font = FONT_LABEL_FLIGHT_PLAN;
    aircraftIdentificationLbl.textColor = lblColor;
    
    [aircraftIdentificationCV addSubview:aircraftIdentificationLbl];
    [backgroundCV addSubview:aircraftIdentificationCV];
    
    UIView *aircraftTypeCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width *2/9, positionY, cvRect.size.width *1.5/9+1, positionY + 1)];
    aircraftTypeCV.backgroundColor = [UIColor clearColor];
    aircraftTypeCV.layer.borderColor =  COLOR_BORDER.CGColor;
    aircraftTypeCV.layer.borderWidth = 1.0f;
    
    UILabel *aircraftTypeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width *1.5/9, 40.0f)];
    aircraftTypeLbl.textAlignment = NSTextAlignmentCenter;
    aircraftTypeLbl.text = @"3.AIRCRAFT TYPE/\n  SPECIAL EQUIPMENT";
    aircraftTypeLbl.numberOfLines = 0;
    aircraftTypeLbl.font = FONT_LABEL_FLIGHT_PLAN;
    aircraftTypeLbl.textColor = lblColor;
    
    [aircraftTypeCV addSubview:aircraftTypeLbl];
    [backgroundCV addSubview:aircraftTypeCV];
    
    UIView *trueAirspeedCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width *3.5/9, positionY, cvRect.size.width/9+1, positionY + 1)];
    trueAirspeedCV.backgroundColor = [UIColor clearColor];
    trueAirspeedCV.layer.borderColor =  COLOR_BORDER.CGColor;
    trueAirspeedCV.layer.borderWidth = 1.0f;
    
    UILabel *trueAirspeedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/9, 40.0f)];
    trueAirspeedLbl.textAlignment = NSTextAlignmentCenter;
    trueAirspeedLbl.text = @"4.TRUE\n  AIRSPEED";
    trueAirspeedLbl.numberOfLines = 0;
    trueAirspeedLbl.font = FONT_LABEL_FLIGHT_PLAN;
    trueAirspeedLbl.textColor = lblColor;
    
    [trueAirspeedCV addSubview:trueAirspeedLbl];
    [backgroundCV addSubview:trueAirspeedCV];
    
    UIView *departurePointCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width *4.5/9, positionY, cvRect.size.width * 1.5/9+1, positionY + 1)];
    departurePointCV.backgroundColor = [UIColor clearColor];
    departurePointCV.layer.borderColor =  COLOR_BORDER.CGColor;
    departurePointCV.layer.borderWidth = 1.0f;
    
    UILabel *departurePointLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width*1.5/9, 20.0f)];
    departurePointLbl.textAlignment = NSTextAlignmentCenter;
    departurePointLbl.text = @"5.DEPARTURE POINT";
    departurePointLbl.numberOfLines = 0;
    departurePointLbl.font = FONT_LABEL_FLIGHT_PLAN;
    departurePointLbl.textColor = lblColor;
    
    [departurePointCV addSubview:departurePointLbl];
    [backgroundCV addSubview:departurePointCV];
    
    
    UIView *departureTimeCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width *6/9, positionY, cvRect.size.width * 2/9+1, positionY + 1)];
    departureTimeCV.backgroundColor = [UIColor clearColor];
    departureTimeCV.layer.borderColor =  COLOR_BORDER.CGColor;
    departureTimeCV.layer.borderWidth = 1.0f;
    
    UILabel *departureTimeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width*2/9, 30.0f)];
    departureTimeLbl.textAlignment = NSTextAlignmentCenter;
    departureTimeLbl.text = @"6.DEPARTURE TIME";
    departureTimeLbl.numberOfLines = 0;
    departureTimeLbl.font = FONT_LABEL_FLIGHT_PLAN;
    departureTimeLbl.textColor = lblColor;
    
    UILabel *departureTimeLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, cvRect.size.width*2/9, 1.0f)];
    departureTimeLine.backgroundColor = COLOR_BORDER;
    UILabel *departureTimeVLine = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/9, 30, 1, positionY-30)];
    departureTimeVLine.backgroundColor = COLOR_BORDER;
    
    UILabel *porposedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, cvRect.size.width/9, 30.0f)];
    porposedLbl.textAlignment = NSTextAlignmentCenter;
    porposedLbl.text = @"PROPOSED(Z)";
    porposedLbl.numberOfLines = 0;
    porposedLbl.font = FONT_LABEL_FLIGHT_PLAN;
    porposedLbl.textColor = lblColor;
    
    UILabel *actualZLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/9, 30, cvRect.size.width/9, 30.0f)];
    actualZLbl.textAlignment = NSTextAlignmentCenter;
    actualZLbl.text = @"ACTUAL(Z)";
    actualZLbl.numberOfLines = 0;
    actualZLbl.font = FONT_LABEL_FLIGHT_PLAN;
    actualZLbl.textColor = lblColor;
    
    [departureTimeCV addSubview:departureTimeLbl];
    [departureTimeCV addSubview:departureTimeLine];
    [departureTimeCV addSubview:departureTimeVLine];
    [departureTimeCV addSubview:porposedLbl];
    [departureTimeCV addSubview:actualZLbl];
    [backgroundCV addSubview:departureTimeCV];
    
    UIView *cruisingAltitudeCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width *8/9, positionY, cvRect.size.width /9, positionY + 1)];
    cruisingAltitudeCV.backgroundColor = [UIColor clearColor];
    cruisingAltitudeCV.layer.borderColor =  COLOR_BORDER.CGColor;
    cruisingAltitudeCV.layer.borderWidth = 1.0f;
    
    UILabel *cruisingAltitudeLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/9, 40.0f)];
    cruisingAltitudeLbl.textAlignment = NSTextAlignmentCenter;
    cruisingAltitudeLbl.text = @"7.CRUISING\n  ALTITUDE";
    cruisingAltitudeLbl.numberOfLines = 0;
    cruisingAltitudeLbl.font = FONT_LABEL_FLIGHT_PLAN;
    cruisingAltitudeLbl.textColor = lblColor;
    
    [cruisingAltitudeCV addSubview:cruisingAltitudeLbl];
    [backgroundCV addSubview:cruisingAltitudeCV];
    
    UIView *routeOfFlightCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY*2, cvRect.size.width, positionY * 1.5 + 1)];
    routeOfFlightCV.backgroundColor = [UIColor clearColor];
    routeOfFlightCV.layer.borderColor =  COLOR_BORDER.CGColor;
    routeOfFlightCV.layer.borderWidth = 1.0f;
    
    UILabel *routeOfFlightLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width-10, 30.0f)];
    routeOfFlightLbl.textAlignment = NSTextAlignmentLeft;
    routeOfFlightLbl.text = @"8.ROUTE OF FLIGHT";
    routeOfFlightLbl.numberOfLines = 0;
    routeOfFlightLbl.font = FONT_LABEL_FLIGHT_PLAN;
    routeOfFlightLbl.textColor = lblColor;
    
    [routeOfFlightCV addSubview:routeOfFlightLbl];
    [backgroundCV addSubview:routeOfFlightCV];
    
    UIView *destinationCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY*3.5, cvRect.size.width/5 + 1, positionY*1.25 + 1)];
    destinationCV.backgroundColor = [UIColor clearColor];
    destinationCV.layer.borderColor =  COLOR_BORDER.CGColor;
    destinationCV.layer.borderWidth = 1.0f;
    
    UILabel *destinationLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width/5-10, 40.0f)];
    destinationLbl.textAlignment = NSTextAlignmentLeft;
    destinationLbl.text = @"9. DESTINATION (Name of airport and city)";
    destinationLbl.numberOfLines = 0;
    destinationLbl.font = FONT_LABEL_FLIGHT_PLAN;
    destinationLbl.textColor = lblColor;
    
    [destinationCV addSubview:destinationLbl];
    [backgroundCV addSubview:destinationCV];
    
    UIView *estTimeEnrouteCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/5, positionY*3.5, cvRect.size.width/5 + 1, positionY*1.25 + 1)];
    estTimeEnrouteCV.backgroundColor = [UIColor clearColor];
    estTimeEnrouteCV.layer.borderColor =  COLOR_BORDER.CGColor;
    estTimeEnrouteCV.layer.borderWidth = 1.0f;
    
    UILabel *estTimeEnrouteLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/5, 30.0f)];
    estTimeEnrouteLbl.textAlignment = NSTextAlignmentCenter;
    estTimeEnrouteLbl.text = @"10.EST. TIME ENROUTE";
    estTimeEnrouteLbl.numberOfLines = 0;
    estTimeEnrouteLbl.font = FONT_LABEL_FLIGHT_PLAN;
    estTimeEnrouteLbl.textColor = lblColor;
    
    UILabel *estTimeEnrouteLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, cvRect.size.width/5, 1.0f)];
    estTimeEnrouteLine.backgroundColor = COLOR_BORDER;
    UILabel *estTimeEnrouteVLine = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/10, 30, 1, positionY*1.25-30)];
    estTimeEnrouteVLine.backgroundColor = COLOR_BORDER;
    
    UILabel *hoursLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, cvRect.size.width/10, 30.0f)];
    hoursLbl.textAlignment = NSTextAlignmentCenter;
    hoursLbl.text = @"HOURS";
    hoursLbl.numberOfLines = 0;
    hoursLbl.font = FONT_LABEL_FLIGHT_PLAN;
    hoursLbl.textColor = lblColor;
    
    UILabel *minutesLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/10, 30, cvRect.size.width/10, 30.0f)];
    minutesLbl.textAlignment = NSTextAlignmentCenter;
    minutesLbl.text = @"MINUTES";
    minutesLbl.numberOfLines = 0;
    minutesLbl.font = FONT_LABEL_FLIGHT_PLAN;
    minutesLbl.textColor = lblColor;
    
    [estTimeEnrouteCV addSubview:estTimeEnrouteLbl];
    [estTimeEnrouteCV addSubview:estTimeEnrouteLine];
    [estTimeEnrouteCV addSubview:estTimeEnrouteVLine];
    [estTimeEnrouteCV addSubview:hoursLbl];
    [estTimeEnrouteCV addSubview:minutesLbl];
    [backgroundCV addSubview:estTimeEnrouteCV];
    
    UIView *remarksCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/5, positionY*3.5, cvRect.size.width*3/5, positionY*1.25 + 1)];
    remarksCV.backgroundColor = [UIColor clearColor];
    remarksCV.layer.borderColor =  COLOR_BORDER.CGColor;
    remarksCV.layer.borderWidth = 1.0f;
    
    UILabel *remarksLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width*3/5, 30.0f)];
    remarksLbl.textAlignment = NSTextAlignmentLeft;
    remarksLbl.text = @"11.REMARKS";
    remarksLbl.numberOfLines = 0;
    remarksLbl.font = FONT_LABEL_FLIGHT_PLAN;
    remarksLbl.textColor = lblColor;
    
    [remarksCV addSubview:remarksLbl];
    [backgroundCV addSubview:remarksCV];
    
    UIView *fuelOnBoardCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY*4.75, cvRect.size.width/5-50 + 1, positionY*1.25 + 1)];
    fuelOnBoardCV.backgroundColor = [UIColor clearColor];
    fuelOnBoardCV.layer.borderColor =  COLOR_BORDER.CGColor;
    fuelOnBoardCV.layer.borderWidth = 1.0f;
    
    UILabel *fuelOnBoardLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cvRect.size.width/5-50, 30.0f)];
    fuelOnBoardLbl.textAlignment = NSTextAlignmentCenter;
    fuelOnBoardLbl.text = @"10.EST. TIME ENROUTE";
    fuelOnBoardLbl.numberOfLines = 0;
    fuelOnBoardLbl.font = FONT_LABEL_FLIGHT_PLAN;
    fuelOnBoardLbl.textColor = lblColor;
    
    UILabel *fuelOnBoardLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, cvRect.size.width/5-50, 1.0f)];
    fuelOnBoardLine.backgroundColor = COLOR_BORDER;
    UILabel *fuelOnBoardVLine = [[UILabel alloc] initWithFrame:CGRectMake((cvRect.size.width/5-50)/2, 30, 1, positionY*1.25-30)];
    fuelOnBoardVLine.backgroundColor = COLOR_BORDER;
    
    UILabel *fuelOnBoardhoursLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, (cvRect.size.width/5-50)/2, 30.0f)];
    fuelOnBoardhoursLbl.textAlignment = NSTextAlignmentCenter;
    fuelOnBoardhoursLbl.text = @"HOURS";
    fuelOnBoardhoursLbl.numberOfLines = 0;
    fuelOnBoardhoursLbl.font = FONT_LABEL_FLIGHT_PLAN;
    fuelOnBoardhoursLbl.textColor = lblColor;
    
    UILabel *fuelOnBoardminutesLbl = [[UILabel alloc] initWithFrame:CGRectMake((cvRect.size.width/5-50)/2, 30, (cvRect.size.width/5-50)/2, 30.0f)];
    fuelOnBoardminutesLbl.textAlignment = NSTextAlignmentCenter;
    fuelOnBoardminutesLbl.text = @"MINUTES";
    fuelOnBoardminutesLbl.numberOfLines = 0;
    fuelOnBoardminutesLbl.font = FONT_LABEL_FLIGHT_PLAN;
    fuelOnBoardminutesLbl.textColor = lblColor;
    
    [fuelOnBoardCV addSubview:fuelOnBoardLbl];
    [fuelOnBoardCV addSubview:fuelOnBoardLine];
    [fuelOnBoardCV addSubview:fuelOnBoardVLine];
    [fuelOnBoardCV addSubview:fuelOnBoardhoursLbl];
    [fuelOnBoardCV addSubview:fuelOnBoardminutesLbl];
    [backgroundCV addSubview:fuelOnBoardCV];
    
    
    UIView *alternateAirportCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/5-50, positionY*4.75, cvRect.size.width/5+51, positionY*1.25 + 1)];
    alternateAirportCV.backgroundColor = [UIColor clearColor];
    alternateAirportCV.layer.borderColor =  COLOR_BORDER.CGColor;
    alternateAirportCV.layer.borderWidth = 1.0f;
    
    UILabel *alternateAirportLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width/5+40, 30.0f)];
    alternateAirportLbl.textAlignment = NSTextAlignmentLeft;
    alternateAirportLbl.text = @"13.ALTERNATE AIRPORT(S)";
    alternateAirportLbl.numberOfLines = 0;
    alternateAirportLbl.font = FONT_LABEL_FLIGHT_PLAN;
    alternateAirportLbl.textColor = lblColor;
    
    [alternateAirportCV addSubview:alternateAirportLbl];
    [backgroundCV addSubview:alternateAirportCV];
    
    
    UIView *pilotsNATCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/5, positionY*4.75, cvRect.size.width*3/5-cvRect.size.width/9+1, positionY*1.25/2 + 1)];
    pilotsNATCV.backgroundColor = [UIColor clearColor];
    pilotsNATCV.layer.borderColor =  COLOR_BORDER.CGColor;
    pilotsNATCV.layer.borderWidth = 1.0f;
    
    UILabel *pilotsNATLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width*3/5-cvRect.size.width/9-10, 30.0f)];
    pilotsNATLbl.textAlignment = NSTextAlignmentLeft;
    pilotsNATLbl.text = @"14.PILOTS NAME, ADDRESS & TELEPHONE NUMBER &AIRCRAFT HOME BASE";
    pilotsNATLbl.numberOfLines = 0;
    pilotsNATLbl.font = FONT_LABEL_FLIGHT_PLAN;
    pilotsNATLbl.textColor = lblColor;
    
    [pilotsNATCV addSubview:pilotsNATLbl];
    [backgroundCV addSubview:pilotsNATCV];
    
    
    UIView *distinationConCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width*2/5, positionY*4.75 + positionY*1.25/2, cvRect.size.width*3/5-cvRect.size.width/9+1, positionY*1.25/2 + 1)];
    distinationConCV.backgroundColor = [UIColor clearColor];
    distinationConCV.layer.borderColor =  COLOR_BORDER.CGColor;
    distinationConCV.layer.borderWidth = 1.0f;
    
    UILabel *distinationConLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width*3/5-cvRect.size.width/9-10, 30.0f)];
    distinationConLbl.textAlignment = NSTextAlignmentLeft;
    distinationConLbl.text = @"17.DESTINATION CONTACT/TELEPHONE(OPTIONAL)";
    distinationConLbl.numberOfLines = 0;
    distinationConLbl.font = FONT_LABEL_FLIGHT_PLAN;
    distinationConLbl.textColor = lblColor;
    
    [distinationConCV addSubview:distinationConLbl];
    [backgroundCV addSubview:distinationConCV];
    
    UIView *numberAboardCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width-cvRect.size.width/9, positionY*4.75, cvRect.size.width/9, positionY*1.25 + 1)];
    numberAboardCV.backgroundColor = [UIColor clearColor];
    numberAboardCV.layer.borderColor =  COLOR_BORDER.CGColor;
    numberAboardCV.layer.borderWidth = 1.0f;
    
    UILabel *numberAboardLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width/9-10, 40.0f)];
    numberAboardLbl.textAlignment = NSTextAlignmentLeft;
    numberAboardLbl.text = @"15.NUMBER ABOARD";
    numberAboardLbl.numberOfLines = 0;
    numberAboardLbl.font = FONT_LABEL_FLIGHT_PLAN;
    numberAboardLbl.textColor = lblColor;
    
    [numberAboardCV addSubview:numberAboardLbl];
    [backgroundCV addSubview:numberAboardCV];
    
    
    UIView *colorOfAircraftCV = [[UIView alloc] initWithFrame:CGRectMake(0, positionY*6, cvRect.size.width/4+1, positionY)];
    colorOfAircraftCV.backgroundColor = [UIColor clearColor];
    colorOfAircraftCV.layer.borderColor =  COLOR_BORDER.CGColor;
    colorOfAircraftCV.layer.borderWidth = 1.0f;
    
    UILabel *colorOfAircraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, cvRect.size.width/4-10, 30.0f)];
    colorOfAircraftLbl.textAlignment = NSTextAlignmentLeft;
    colorOfAircraftLbl.text = @"16.COLOR OF AIRCRAFT";
    colorOfAircraftLbl.numberOfLines = 0;
    colorOfAircraftLbl.font = FONT_LABEL_FLIGHT_PLAN;
    colorOfAircraftLbl.textColor = lblColor;
    
    [colorOfAircraftCV addSubview:colorOfAircraftLbl];
    [backgroundCV addSubview:colorOfAircraftCV];
    
    
    UIView *civilAircraftCV = [[UIView alloc] initWithFrame:CGRectMake(cvRect.size.width/4, positionY*6, cvRect.size.width*3/4, positionY)];
    civilAircraftCV.backgroundColor = [UIColor clearColor];
    civilAircraftCV.layer.borderColor =  COLOR_BORDER.CGColor;
    civilAircraftCV.layer.borderWidth = 1.0f;
    
    UILabel *civilAircraftLbl = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, cvRect.size.width*3/4-10, positionY-10)];
    civilAircraftLbl.textAlignment = NSTextAlignmentLeft;
    civilAircraftLbl.text = @"CIVIL AIRCRAFT PILOTS. FAR Part 91 requires you file an IFR flight plan to operate under instrument flight rules in controlled airspace. Failure to file could result in al civil penalty not to exceed $1,000 for each violation (Section 901 of the Federal Aviation Act of 1958, as amended). Filing of a VFR flight plan is recommeded as a good operating practice. See also Part 99 for requirements concerning DVFR flight plans.";
    civilAircraftLbl.numberOfLines = 0;
    civilAircraftLbl.font = FONT_LABEL_FLIGHT_PLAN;
    civilAircraftLbl.textColor = lblColor;
    
    [civilAircraftCV addSubview:civilAircraftLbl];
    [backgroundCV addSubview:civilAircraftCV];
    
    UILabel *faaformLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, cvRect.size.height-80, cvRect.size.width/5, 80)];
    faaformLbl.numberOfLines = 0;
    faaformLbl.font = FONT_LABEL_FLIGHT_PLAN;
    faaformLbl.textColor = lblColor;
    faaformLbl.text = @"FAA Form 7233-1 (8-82)\nElectronic Version (Adobe)";
    
    
    UILabel *closeVfrLbl = [[UILabel alloc] initWithFrame:CGRectMake(cvRect.size.width/5, cvRect.size.height-80, cvRect.size.width*4/5-40, 80)];
    closeVfrLbl.numberOfLines = 0;
    closeVfrLbl.textAlignment = NSTextAlignmentRight;
    if (cvRect.size.width > cvRect.size.height) {
        closeVfrLbl.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
    }else{
        closeVfrLbl.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    }
    closeVfrLbl.textColor = lblColor;
    closeVfrLbl.text = @"CLOSE VFR FLIGHT PLAN WITH  _________________  FSS ON ARRIVAL";
    
    [backgroundCV addSubview:faaformLbl];
    [backgroundCV addSubview:closeVfrLbl];
    return backgroundCV;
}
@end
