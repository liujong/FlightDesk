//
//  QuizesViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecureViewController.h"

@interface QuizesViewController : SecureViewController{
    UIButton *addButton;
}

@property (strong, nonatomic) NSArray *items;

- (BOOL)populateQuizes;
- (void)reloadData;

@end
