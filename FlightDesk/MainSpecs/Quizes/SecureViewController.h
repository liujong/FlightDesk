//
//  SecureViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 2/1/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecureViewController : UIViewController{
    UIButton *settingsButton;
}

-(void)loggedInSuccessfully;
- (void)hideSettingBtn;
- (void)superClassDeviceOrientationDidChange;
@end
