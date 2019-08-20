//
//  AddDocumentsViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/3/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddDocumentsViewController.h"
#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "Reachability.h"
#import "ReaderConstants.h"
#import "ReaderThumbRequest.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"
#import "CGPDFDocument.h"
#include "Document+CoreDataClass.h"
#include "LessonGroup+CoreDataClass.h"

@interface AddDocumentsViewController ()<ReaderThumbsViewDelegate>{
    // Thumbs view
    ReaderThumbsView *theThumbsView;
    
    // DocumentInfo instances associated with the currently selected group
    NSMutableArray *currentDocuments;
    
    NSMutableArray *selectedThumbViews;
}

@end


@implementation AddDocumentsViewController
    
    @synthesize shownDocs;
    
#pragma mark Constants

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_UPDATE_INTERVAL (5*60) // 5 minutes
//#define FOREGROUND_UPDATE_INTERVAL 10 // 10 seconds

#define THUMB_WIDTH_LARGE_DEVICE 192
#define THUMB_HEIGHT_LARGE_DEVICE 120 + 30 + 60

#define THUMB_WIDTH_SMALL_DEVICE 160
#define THUMB_HEIGHT_SMALL_DEVICE 104 + 20 + 50
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES;
    
    self.view.alpha = 0.0f;
    documentDialog.alpha = 0.0f; // Start hidden
    
    documentDialog.autoresizesSubviews = NO;
    documentDialog.contentMode = UIViewContentModeRedraw;
    documentDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
//    documentDialog.layer.shadowRadius = 3.0f;
//    documentDialog.layer.shadowOpacity = 1.0f;
//    documentDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
//    documentDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:documentDialog.bounds].CGPath;
    documentDialog.layer.cornerRadius = 5.0f;
    
    currentDocuments = [[NSMutableArray alloc] init];
    selectedThumbViews = [[NSMutableArray alloc] init];
    
    // Initialization code
    BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    CGRect viewRect = documentContainView.frame;
    viewRect.origin.y = 0;
    theThumbsView = [[ReaderThumbsView alloc] initWithFrame:viewRect];
    // TODO: do something important with insets?
    theThumbsView.delegate = self;
    [documentContainView addSubview:theThumbsView];
    
    NSInteger thumbWidth = (large ? THUMB_WIDTH_LARGE_DEVICE : THUMB_WIDTH_SMALL_DEVICE);
    NSInteger thumbHeight = (large ? THUMB_HEIGHT_LARGE_DEVICE : THUMB_HEIGHT_SMALL_DEVICE);
    
    [theThumbsView setThumbSize:CGSizeMake(thumbWidth, thumbHeight)];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self populateDocuments];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)populateDocuments
{
    [currentDocuments removeAllObjects];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
    NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
    [documentRequest setEntity:documentEntityDescription];
    NSPredicate *documentPredicate = [NSPredicate predicateWithFormat:@"type == 1"];
    [documentRequest setPredicate:documentPredicate];
    NSArray *documentArray = [context executeFetchRequest:documentRequest error:&error];
    if (documentArray == nil) {
        [currentDocuments removeAllObjects];
    } else if (documentArray.count == 0) {
        [currentDocuments removeAllObjects];
    } else if (documentArray.count > 0) {
        [currentDocuments removeAllObjects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedDocumentArray = [documentArray sortedArrayUsingDescriptors:sortDescriptors];
        for (Document *document in sortedDocumentArray) {
            ReaderDocument *readerDocument = nil;
            NSString *fileName = [[NSURL URLWithString:document.remoteURL] lastPathComponent];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentDirectory =[NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], fileName];
            readerDocument = [ReaderDocument withDocumentFilePath:documentDirectory password:nil];
            DocumentInfo *documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:readerDocument];
            BOOL isExist = NO;
            for (DocumentInfo *docInfo in shownDocs) {
                if (docInfo.document != nil && [docInfo.document.documentID integerValue] == [document.documentID integerValue]){
                    isExist = YES;
                }
            }
            if (isExist == NO){
                [currentDocuments addObject:documentInfo];
            }
        }
        
    }
    [theThumbsView reloadThumbsContentOffset:CGPointZero];
}
- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             documentDialog.alpha = 0.0f; // Fade out
             self.view.alpha = 0.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelDocumentView:self];
         }
         ];
    }
}

- (IBAction)onDone:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             documentDialog.alpha = 0.0f; // Fade out
             self.view.alpha = 0.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             if (selectedThumbViews.count > 0) {
                 NSMutableArray *documentArray = [[NSMutableArray alloc] init];
                 for (DocumentInfo *docInfo in selectedThumbViews) {
                     [documentArray addObject:docInfo.document];
                 }
                 [self.delegate didDoneDocumentView:self withSelecteddoc:documentArray];
             }else{
                 [self.delegate didCancelDocumentView:self];
             }
         }
         ];
    }
}

- (void)animateHide{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             documentDialog.alpha = 0.0f; // Fade out
             self.view.alpha = 0.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}
- (void)animateShow{
    
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             documentDialog.alpha = 1.0f; // Fade in
             self.view.alpha = 1.0f;
             [self.view layoutIfNeeded];
             
             
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
         }
         ];
    }
}

#pragma mark ReaderThumbsViewDelegate methods

- (NSUInteger)numberOfThumbsInThumbsView:(ReaderThumbsView *)thumbsView
{
    return (currentDocuments.count);
}

- (id)thumbsView:(ReaderThumbsView *)thumbsView thumbCellWithFrame:(CGRect)frame
{
    return [[DocumentsCell alloc] initWithFrame:frame];
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView updateThumbCell:(DocumentsCell *)thumbCell forIndex:(NSInteger)index
{
    
    // clear thumb cell for reuse
    [thumbCell reuse];
    
    // TODO: update this for document not downloaded!!!****************************************
    DocumentInfo *documentInfoForThumb = [currentDocuments objectAtIndex:index];
    
    if (documentInfoForThumb.document != nil) {
        if (documentInfoForThumb.document.downloaded == NO) {
            // store the progress bar pointer in the document info
            //[thumbCell showProgressView];
        }
    } else {
        FDLogError(@"nil document for document at index %ld", (long)index);
    }
    
    // TODO: combine these
    //[thumbCell showText:[documentForThumb.fileName stringByDeletingPathExtension]];
    [thumbCell showText:documentInfoForThumb.document.name];
    [thumbCell setDocumentInfo:documentInfoForThumb];
    documentInfoForThumb.currentCell = thumbCell;
    
    CGSize size = [thumbCell maximumContentSize];
    
    ReaderDocument *documentForThumb = documentInfoForThumb.readerDocument;
    if (documentForThumb != nil) {
        NSURL *fileURL = documentForThumb.fileURL;
        NSString *guid = documentForThumb.guid;
        NSString *phrase = documentForThumb.password;
        FDLogDebug(@"Loading local document for '%@' from '%@'", documentInfoForThumb.document.name, fileURL);
        
        ReaderThumbRequest *thumbRequest = [ReaderThumbRequest newForView:thumbCell fileURL:fileURL password:phrase guid:guid page:1 size:size];
        
        // Request the thumbnail
        UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:thumbRequest priority:NO];
        
        // Show image from cache
        if ([image isKindOfClass:[UIImage class]]) [thumbCell showImage:image];
    } else {
        if (documentInfoForThumb.downloadTask == nil) {
            [thumbCell.progressView setProgress:0 animated:YES];
            thumbCell.hidden = YES;
        } else {
            [thumbCell showProgressView];
        }
        FDLogDebug(@"No valid local document for '%@'", documentInfoForThumb.document.name);
    }
    
    thumbCell.maskToSelect.hidden = NO;
    
    if ([selectedThumbViews containsObject:documentInfoForThumb]) {
        thumbCell.imgToSelect.hidden = NO;
    }else{
        thumbCell.imgToSelect.hidden = YES;
    }
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView scrollViewDidScroll:(CGPoint)scrOffset{
    
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView refreshThumbCell:(DocumentsCell *)thumbCell forIndex:(NSInteger)index
{
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView scrollViewWillBeginDragging:(BOOL)isActive{
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView didSelectThumbWithIndex:(NSInteger)index
{
    DocumentInfo *documentInfoForThumb = [currentDocuments objectAtIndex:index];
    if ([selectedThumbViews containsObject:documentInfoForThumb]) {
        [selectedThumbViews removeObject:documentInfoForThumb];
    }else{
        [selectedThumbViews addObject:documentInfoForThumb];
    }
    [theThumbsView reloadThumbsContentOffset:CGPointZero];
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView didPressThumbWithIndex:(NSInteger)index
{
}
@end
