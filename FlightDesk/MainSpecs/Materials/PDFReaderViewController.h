//
//  PDFReaderViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 6/30/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FastPdfKit/FastPdfKit.h>

@interface PDFReaderViewController : ReaderViewController

@property (nonatomic, retain)NSURL *pathOfCurrentPDF;

@end
