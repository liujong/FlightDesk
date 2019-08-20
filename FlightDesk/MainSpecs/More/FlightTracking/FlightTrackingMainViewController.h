//
//  FlightTrackingMainViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/29/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DAScratchPadView.h"

@interface FlightTrackingMainViewController : UIViewController
{
    IBOutlet UIView *navView;
    __weak IBOutlet UIScrollView *padBGScrView;
    __weak IBOutlet UISegmentedControl *segmentedDrawPad;
    __weak IBOutlet UIButton *btnPen;
    __weak IBOutlet UIButton *btnTrash;
    __weak IBOutlet UIButton *btnEraser;
    __weak IBOutlet UIButton *btnMenu;
    
    DAScratchPadView *scratchPad;
    
    IBOutlet UIView *colorsView;
    __weak IBOutlet UISlider *penThicknessSlider;
    IBOutlet UISlider *eraserThicknessSlider;
    __weak IBOutlet UIButton *btnPadStypeChanve;
    __weak IBOutlet UIButton *btnFullScreen;
    __weak IBOutlet UIView *containerView;
}
- (IBAction)onBack:(id)sender;

- (IBAction)onChangePad:(id)sender;
- (IBAction)onSelectPanColor:(id)sender;
- (IBAction)onTrash:(id)sender;
- (IBAction)onEraser:(id)sender;
- (IBAction)onMenu:(id)sender;
- (IBAction)onColorSelected:(id)sender;
- (IBAction)onChangeThickness:(id)sender;
- (IBAction)onChangeEraserThicknessSlider:(id)sender;
- (IBAction)onChangePadStyle:(id)sender;
- (IBAction)onFullScreen:(id)sender;

@end
