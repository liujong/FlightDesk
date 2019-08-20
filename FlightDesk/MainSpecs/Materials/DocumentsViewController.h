//
//  DocumentsViewController.h
//  FlightDesk
//
//  Created by Gregory Bayard on 1/25/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecureViewController.h"
#import <FastPdfKit/FastPdfKit.h>

@class MFDocumentManager;

@interface DocumentsViewController : SecureViewController

- (void)populateDocuments;
- (void)uploadFileToRedirect:(NSURL *)pdfUrl withRedirectPad:(BOOL)isRedirect;
@end
