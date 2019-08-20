//
//  DocumentsView.h
//  FlightDesk
//
//  Created by Gregory Bayard on 1/26/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderThumbsView.h"

@class DocumentsView;
@class Document;
@class ReaderDocument;
@class DocumentsCell;

@interface DocumentInfo : NSObject

@property (nonatomic, strong, readonly) Document *document;
@property (nonatomic, strong) ReaderDocument *readerDocument;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, weak) DocumentsCell *currentCell;
@property BOOL isAbleDownload;

- (id)initWithCoreDataDocument:(Document *)doc andReaderDocument:(ReaderDocument *)rd;

@end

@protocol DocumentsViewDelegate <NSObject>

@required // Delegate protocols

- (void)documentsView:(DocumentsView *)documentsView didSelectDocument:(DocumentInfo *)document withType:(NSInteger)type;
- (void)documentsView:(DocumentsView *)documentsView didSelectDocumentWithUrl:(NSString *)docUrl;
- (void)enableUpdateButton:(BOOL)_isEnabled;

- (void)reSetBadge;
@end


@interface DocumentsView : UIView

@property (nonatomic, weak, readwrite) id <DocumentsViewDelegate> delegate;

// get an array of course names (to populate course menu)
- (NSArray*)getGroupArray;

// set a new current course name and then re-populate the current documents for the new course name
// (this also starts an update check timer if it wasn't already started)
- (void)populateDocumentsWithGroupName:(NSString *)groupName;

// re-populate the current documents
- (void)populateDocuments;

- (void)confirmDocumentUpdate;

- (void)reloadWithSelecting:(BOOL)isSelectable;
- (void)deleteViewsToBeSelected;


- (void)hiddenKeyboard;

- (NSMutableArray *)getCurrentDocs;

@end

#pragma mark -

//
//	DocumentsCell class interface
//

@interface DocumentsCell : ReaderThumbView

@property (nonatomic, strong, readonly) UIProgressView *progressView;
@property (nonatomic, strong) UIView *maskToSelect;
@property (nonatomic, strong) UIImageView *imgToSelect;

@property (nonatomic, weak) DocumentInfo *currentCellDocumentInfo;

- (CGSize)maximumContentSize;

- (void)showProgressView;

- (void)showText:(NSString *)text;

- (void)setDocumentInfo:(DocumentInfo *)info;

@end
