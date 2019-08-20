//
//  AddDocumentsViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/3/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderThumbsView.h"
#import "DocumentsView.h"

@class AddDocumentsViewController;
@class Document;
@class ReaderDocument;
@class DocumentsCell;

@protocol AddDocumentsViewControllerDelegate

@optional;
- (void)didCancelDocumentView:(AddDocumentsViewController *)documentView;
- (void)didDoneDocumentView:(AddDocumentsViewController *)documentView withSelecteddoc:(NSMutableArray *)docInfoArray;
@end


@interface AddDocumentsViewController : UIViewController{
    __weak IBOutlet UIView *documentDialog;
    __weak IBOutlet UIView *documentContainView;

}


@property (nonatomic, weak, readwrite) id <AddDocumentsViewControllerDelegate> delegate;
- (void)animateHide;
- (void)animateShow;
- (IBAction)onCancel:(id)sender;
- (IBAction)onDone:(id)sender;
    
    @property (nonatomic, strong) NSMutableArray *shownDocs;

@end
