//
//  RecordsViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecureViewController.h"

@interface RecordsViewController : SecureViewController{
    UIButton *addButton;
}



//- (void)startUpdateCheck;
- (BOOL)populateLessons;
- (void)reloadData;
- (void)endRefresh;
@end
