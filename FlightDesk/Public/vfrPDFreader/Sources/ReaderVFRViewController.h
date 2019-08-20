//
//  ReaderVFRViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/30/17.
//  Copyright © 2017 spider. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "SecureViewController.h"

#import "ReaderDocument.h"

@class ReaderVFRViewController;

@protocol ReaderVFRViewControllerDelegate <NSObject>

@optional // Delegate protocols

- (void)dismissReaderVFRViewController:(ReaderVFRViewController *)viewController;

@end

@interface ReaderVFRViewController : SecureViewController

@property (nonatomic, weak, readwrite) id <ReaderVFRViewControllerDelegate> delegate;

- (instancetype)initWithReaderDocument:(ReaderDocument *)object;

@end
