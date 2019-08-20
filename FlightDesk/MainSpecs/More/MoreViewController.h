//
//  MoreViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 2/8/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecureViewController.h"
#import "Spring.h"

@class SpringButton;
@interface MoreViewController : SecureViewController{

    __weak IBOutlet SpringButton *btnNavLog;
    __weak IBOutlet SpringButton *btnTOLD;
    __weak IBOutlet SpringButton *btnWB;
    __weak IBOutlet SpringButton *btnChecklists;
    __weak IBOutlet SpringButton *btnFlightTracking;
    __weak IBOutlet SpringButton *btnWind;
    __weak IBOutlet SpringButton *btnFuel;
    __weak IBOutlet SpringButton *btnPaDa;
    __weak IBOutlet SpringButton *btnIsa;
    __weak IBOutlet SpringButton *btnConversion;
    __weak IBOutlet SpringButton *btnSpeed;
    __weak IBOutlet SpringButton *btnClouds;
    __weak IBOutlet SpringButton *btnTimeDistance;
    __weak IBOutlet SpringButton *btnLeg;
    __weak IBOutlet SpringButton *btnGuide;
    __weak IBOutlet SpringButton *btnFreezingLevel;
}
- (IBAction)onTools:(UIButton *)sender;
- (IBAction)onCalculation:(UIButton *)sender;

@end
