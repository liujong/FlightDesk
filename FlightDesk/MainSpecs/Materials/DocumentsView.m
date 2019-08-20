//
//  DocumentsView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 1/26/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.

// TODO
// fix reloadDocuments so that previous documents are not always lost

#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "Reachability.h"
#import "DocumentsView.h"

#import "ReaderConstants.h"
#import "ReaderThumbRequest.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"
#import "CGPDFDocument.h"
#include "Document+CoreDataClass.h"
#include "LessonGroup+CoreDataClass.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation DocumentInfo

@synthesize document;
@synthesize readerDocument;
@synthesize downloadTask;
@synthesize currentCell;
    @synthesize isAbleDownload;

- (id)initWithCoreDataDocument:(Document *)doc andReaderDocument:(ReaderDocument *)rd
{
    self = [super init];
    if (self) {
        document = doc;
        readerDocument = rd;
        downloadTask = nil;
        currentCell = nil;
        isAbleDownload = YES;
    }
    return self;
}

@end

@interface DocumentsView () <ReaderThumbsViewDelegate, NSURLSessionDownloadDelegate, UIAlertViewDelegate, UITextFieldDelegate>
@end

@implementation DocumentsView
{
    // all DocumentInfo instances indexed by ID
    NSMutableDictionary *loadedDocuments;
    
    // DocumentInfo instances associated with the currently selected group
    NSMutableArray *currentDocuments;
    
    // lock to protect download task count and queue
    NSLock *downloadTasksLock;
    
    // download tasks indexed by task (for look-up from progress and finished delegates)
    NSMutableDictionary *downloadTasks;
    NSMutableDictionary *downloadTasksToCheck;
    
    // number of active download tasks
    int downloadTaskCount;
    
    // queued download tasks
    NSMutableArray *queuedDownloadTasks;
    
    // Thumbs view
    ReaderThumbsView *theThumbsView;

    // Currently selected group name
    NSString *currentGroupName;
    
    // Background session for downloading documents in the background
    NSURLSession *backgroundSession;
    
    BOOL isSelect;
    NSMutableArray *selectedThumbViews;
    
    Document *docToRename;
    NSInteger indexToEdit;
    
    UIView *coverViewForRenameText;
    UITextField *tmptext;
    UIView *renameTxtDialog;
    UIView *tmpCV;
    UITextField *lblRenameView;
    UIImageView *gradiantImageView;
    
    CGPoint currentDocumentViewPoint;
}

#pragma mark Constants

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_UPDATE_INTERVAL (5*60) // 5 minutes
//#define FOREGROUND_UPDATE_INTERVAL 10 // 10 seconds

#define THUMB_WIDTH_LARGE_DEVICE 192
#define THUMB_HEIGHT_LARGE_DEVICE 120 + 30 + 60

#define THUMB_WIDTH_SMALL_DEVICE 160
#define THUMB_HEIGHT_SMALL_DEVICE 104 + 20 + 50

#pragma mark Properties

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        loadedDocuments = [[NSMutableDictionary alloc] init];
        downloadTasks = [[NSMutableDictionary alloc] init];
        downloadTasksToCheck = [[NSMutableDictionary alloc] init];
        downloadTasksLock = [[NSLock alloc] init];
        currentDocuments = [[NSMutableArray alloc] init];
        backgroundSession = nil;
        
        indexToEdit = -1;
        isSelect = NO;
        selectedThumbViews = [[NSMutableArray alloc] init];
        
        coverViewForRenameText = [[UIView alloc] initWithFrame:self.frame];
        [coverViewForRenameText setBackgroundColor:[UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:0.5f]];
        renameTxtDialog = [[UIView alloc] initWithFrame:CGRectMake((coverViewForRenameText.frame.size.width-350.0f)/2, coverViewForRenameText.frame.size.height-500.0f, 350.0f, 80.0f)];
        renameTxtDialog.autoresizesSubviews = NO;
        renameTxtDialog.contentMode = UIViewContentModeRedraw;
        renameTxtDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        renameTxtDialog.backgroundColor = [UIColor whiteColor];
        renameTxtDialog.layer.shadowRadius = 3.0f;
        renameTxtDialog.layer.shadowOpacity = 1.0f;
        renameTxtDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        renameTxtDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:renameTxtDialog.bounds].CGPath;
        renameTxtDialog.layer.cornerRadius = 5.0f;
        
        tmpCV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 35)];
        [renameTxtDialog addSubview:tmpCV];
        gradiantImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tmpCV.frame.size.width, tmpCV.frame.size.height)];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = [UIScreen mainScreen] .bounds;
        gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:145.0f/255.0f blue:0 alpha:1.0f].CGColor,
                                  (__bridge id)[UIColor colorWithRed:250.0f/255.0f green:83.0f/255.0f blue:0 alpha:1.0f].CGColor ];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        UIGraphicsBeginImageContext(gradientLayer.bounds.size);
        [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [gradiantImageView setImage:gradientImage];
        [tmpCV addSubview:gradiantImageView];
        
        lblRenameView = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 40)];
        lblRenameView.text = @"Please rename current file in here.";
        lblRenameView.textAlignment = NSTextAlignmentCenter;
        lblRenameView.textColor = [UIColor whiteColor];
        [tmpCV addSubview:lblRenameView];
        
        tmptext = [[UITextField alloc] initWithFrame:CGRectMake(5, 40, renameTxtDialog.frame.size.width-10, 35)];
        tmptext.delegate = self;
        tmptext.textAlignment = NSTextAlignmentCenter;
        tmptext.font = [UIFont systemFontOfSize:13.0f];
        tmptext.textColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
        tmptext.backgroundColor = [UIColor whiteColor];
        tmptext.layer.cornerRadius = 5.0f;
        tmptext.layer.borderColor = [UIColor blackColor].CGColor;
        tmptext.layer.borderWidth = 1.0f;
        [renameTxtDialog addSubview:tmptext];
        
        [coverViewForRenameText addSubview:renameTxtDialog];
        
        UITapGestureRecognizer *tapGestureToPreViewImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCoverViewForRemaing)];
        [coverViewForRenameText addGestureRecognizer:tapGestureToPreViewImage];
        
        // Initialization code
        BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
        
        self.backgroundColor = [UIColor whiteColor];
        
        CGRect viewRect = self.bounds;
        theThumbsView = [[ReaderThumbsView alloc] initWithFrame:viewRect];
        // TODO: do something important with insets?
        theThumbsView.delegate = self;
        [self addSubview:theThumbsView];
        
        NSInteger thumbWidth = (large ? THUMB_WIDTH_LARGE_DEVICE : THUMB_WIDTH_SMALL_DEVICE);
        NSInteger thumbHeight = (large ? THUMB_HEIGHT_LARGE_DEVICE : THUMB_HEIGHT_SMALL_DEVICE);
        
        [theThumbsView setThumbSize:CGSizeMake(thumbWidth, thumbHeight)];
        
        currentDocumentViewPoint = CGPointZero;
    }
    return self;
}
-(void)tapCoverViewForRemaing
{
    [self endEditing:YES];
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Do you want to change current file's name?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        if (docToRename.documentID != nil && tmptext.text.length > 0) {
            [[AppDelegate sharedDelegate] startThreadToSyncData:3];
            [coverViewForRenameText removeFromSuperview];
            docToRename.name = tmptext.text;
            docToRename.lastUpdate = @(0);
            [self endEditing:YES];
            indexToEdit = -1;
            [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
            [context save:&error];
        }
    }];
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        [[AppDelegate sharedDelegate] startThreadToSyncData:3];
        [coverViewForRenameText removeFromSuperview];
        tmptext.text = @"";
        [self endEditing:YES];
        indexToEdit = -1;
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
    }];
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}
- (void)reloadViewsForRenaming{
    [coverViewForRenameText setFrame:self.frame];
    [coverViewForRenameText setBackgroundColor:[UIColor colorWithRed:167.0f/255.0f green:167.0f/255.0f blue:167.0f/255.0f alpha:0.5f]];
    [renameTxtDialog setFrame:CGRectMake((coverViewForRenameText.frame.size.width-350.0f)/2, coverViewForRenameText.frame.size.height-500.0f, 350.0f, 80.0f)];
    [tmpCV setFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 35)];
    [gradiantImageView setFrame:CGRectMake(0, 0, tmpCV.frame.size.width, tmpCV.frame.size.height)];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:1.0f green:145.0f/255.0f blue:0 alpha:1.0f].CGColor,
                              (__bridge id)[UIColor colorWithRed:250.0f/255.0f green:83.0f/255.0f blue:0 alpha:1.0f].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [gradiantImageView setImage:gradientImage];
    [lblRenameView setFrame:CGRectMake(0, 0, renameTxtDialog.frame.size.width, 40)];
    [tmptext setFrame:CGRectMake(5, 40, renameTxtDialog.frame.size.width-10, 35)];
}
- (NSMutableArray *)getCurrentDocs{
    return currentDocuments;
}
- (NSArray*)getGroupArray
{
    NSArray *groupNames;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    // load the groups
    NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
    NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
    [groupRequest setEntity:groupEntityDescription];
    NSSortDescriptor *groupSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [groupRequest setSortDescriptors:@[groupSortDescriptor]];
    
    NSError *error;
    NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
    if (groupArray == nil) {
        FDLogError(@"Unable to retrieve lesson group!");
        NSMutableArray *newGroups = [NSMutableArray arrayWithCapacity:1];
        [newGroups addObject:@"My Docs"];
        groupNames = [NSArray arrayWithArray:newGroups];
    } else if (groupArray.count == 0) {
        FDLogDebug(@"No groups stored!");
        NSMutableArray *newGroups = [NSMutableArray arrayWithCapacity:1];
        [newGroups addObject:@"My Docs"];
        groupNames = [NSArray arrayWithArray:newGroups];
    } else {
        NSMutableArray *newGroups = [NSMutableArray arrayWithCapacity:groupArray.count + 1];
        [newGroups addObject:@"My Docs"];
        for (LessonGroup *group in groupArray) {
            if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"] || [[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
                if (group.parentGroup == nil) {
                    if (![newGroups containsObject:group.name]) {
                        [newGroups addObject:group.name];
                    }
                }
            }else{
                if (group.parentGroup == nil && [group.isShown boolValue] == YES) {
                    if (![newGroups containsObject:group.name]) {
                        [newGroups addObject:group.name];
                    }
                }
            }
        }
        groupNames = [NSArray arrayWithArray:newGroups];
    }
    return groupNames;
}

- (void)populateDocuments
{
    if (indexToEdit != -1) {
        return;
    }
    //update red_badge
    [self.delegate reSetBadge];
    
    if ([currentGroupName isEqualToString:@"My Docs"]) {
        [currentDocuments removeAllObjects];
        NSError *error;
        BOOL documentsToUpdate = NO;
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
                
                // check if this document is already loaded
                DocumentInfo *documentInfo = [loadedDocuments objectForKey:document.documentID];
                if (documentInfo == nil) {
                    // the document has not yet been loaded
                    FDLogDebug(@"Creating document info for '%@'", document.name);
                    ReaderDocument *readerDocument = nil;
                    if (document.pdfURL != nil) {
                        FDLogDebug(@"Loading local document from '%@'", document.pdfURL);
                        
                        NSURL *pdfLocalUrl = [[NSURL alloc] initWithString:[document.pdfURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentDirectory = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], [pdfLocalUrl lastPathComponent]];
                        readerDocument = [ReaderDocument unarchiveFromFileName:documentDirectory password:nil];
                    }
                    // create the new DocumentInfo instance
                    documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:readerDocument];
                    [loadedDocuments setObject:documentInfo forKey:document.documentID];
                }
                if ([document.downloaded boolValue] == NO && documentInfo.downloadTask == nil) {
                    //FDLogDebug(@"%@ requires update", document.pdfURL);
                    documentsToUpdate = YES;
                }
                
                if ([document.downloaded boolValue] == YES) {
                    //Checking if document exists on local
                    [self updateDownloadedStatusWithDocument:document withContext:context];
                }
                
                [currentDocuments addObject:documentInfo];
            }
            
        }
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
        [self.delegate enableUpdateButton:documentsToUpdate];
    }else{
        // populate the documents using the currently selected group
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        BOOL documentsToUpdate = NO;
        // load the groups
        NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
        NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
        [groupRequest setEntity:groupEntityDescription];
        NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"name == %@", currentGroupName];
        [groupRequest setPredicate:groupPredicate];
        NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
        if (groupArray == nil) {
            FDLogError(@"Unable to retrieve current group %@!", currentGroupName);
            [currentDocuments removeAllObjects];
        } else if (groupArray.count == 0) {
            FDLogDebug(@"No valid group %@ found!", currentGroupName);
            [currentDocuments removeAllObjects];
        } else if (groupArray.count > 1) {
            FDLogError(@"More than one group named %@!", currentGroupName);
            
            [currentDocuments removeAllObjects];
            NSMutableArray *documentArrayToUniqueDo = [[NSMutableArray alloc] init];
            for (LessonGroup *group in groupArray) {
                for (Document *document in group.documents) {
                    BOOL isExist = NO;
                    for (Document *itemDocOfArray in documentArrayToUniqueDo) {
                        if ([itemDocOfArray.documentID integerValue] == [document.documentID integerValue]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [documentArrayToUniqueDo addObject:document];
                    }
                }
            }
            if (documentArrayToUniqueDo == nil) {
                FDLogError(@"Unable to retrieve documents!");
                [currentDocuments removeAllObjects];
            } else if (documentArrayToUniqueDo.count == 0) {
                FDLogDebug(@"No documents for current group %@", currentGroupName);
                [currentDocuments removeAllObjects];
            } else {
                [currentDocuments removeAllObjects];
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                NSArray *sortedDocumentArray = [documentArrayToUniqueDo sortedArrayUsingDescriptors:sortDescriptors];
                FDLogDebug(@"Loaded %ld documents for current group '%@'", (unsigned long)[sortedDocumentArray count], currentGroupName);
                for (Document *document in sortedDocumentArray) {
                    if ([document isFault] && document.documentID == nil) {
                        
                    }else{
                        
                        // check if this document is already loaded
                        DocumentInfo *documentInfo = [loadedDocuments objectForKey:document.documentID];
                        if (documentInfo == nil) {
                            // the document has not yet been loaded
                            FDLogDebug(@"Creating document info for '%@'", document.name);
                            ReaderDocument *readerDocument = nil;
                            if (document.pdfURL != nil) {
                                FDLogDebug(@"Loading local document from '%@'", document.pdfURL);
                                NSURL *pdfLocalUrl = [[NSURL alloc] initWithString:[document.pdfURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                NSString *documentDirectory = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], [pdfLocalUrl lastPathComponent]];
                                readerDocument = [ReaderDocument unarchiveFromFileName:documentDirectory password:nil];
                            }
                            // create the new DocumentInfo instance
                            documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:readerDocument];
                            [loadedDocuments setObject:documentInfo forKey:document.documentID];
                        }else{
                            //                        if ([documentInfo.document isFault]) {
                            //                            documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:documentInfo.readerDocument];
                            //                        }
                        }
                        if ([document.downloaded boolValue] == NO && documentInfo.downloadTask == nil) {
                            //FDLogDebug(@"%@ requires update", document.pdfURL);
                            documentsToUpdate = YES;
                        }
                        
                        if ([document.downloaded boolValue] == YES) {
                            //Checking if document exists on local
                            [self updateDownloadedStatusWithDocument:document withContext:context];
                        }
                        [currentDocuments addObject:documentInfo];
                    }
                }
            }
            
        } else {
            // found one group with the current group name
            LessonGroup *group = [groupArray objectAtIndex:0];
            // get an array of Documents associated with the current group
            NSMutableArray *documentArray = [[NSMutableArray alloc] init];
            for (Document *doc in group.documents) {
                [documentArray addObject:doc];
            }
            if (documentArray == nil) {
                FDLogError(@"Unable to retrieve documents!");
                [currentDocuments removeAllObjects];
            } else if (documentArray.count == 0) {
                FDLogDebug(@"No documents for current group %@", currentGroupName);
                [currentDocuments removeAllObjects];
            } else {
                [currentDocuments removeAllObjects];
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                NSArray *sortedDocumentArray = [documentArray sortedArrayUsingDescriptors:sortDescriptors];
                FDLogDebug(@"Loaded %ld documents for current group '%@'", (unsigned long)[sortedDocumentArray count], currentGroupName);
                for (Document *document in sortedDocumentArray) {
                    if ([document isFault] && document.documentID == nil) {
                        
                    }else{
                        // check if this document is already loaded
                        DocumentInfo *documentInfo = [loadedDocuments objectForKey:document.documentID];
                        if (documentInfo == nil) {
                            // the document has not yet been loaded
                            FDLogDebug(@"Creating document info for '%@'", document.name);
                            ReaderDocument *readerDocument = nil;
                            if (document.pdfURL != nil) {
                                FDLogDebug(@"Loading local document from '%@'", document.pdfURL);
                                NSURL *pdfLocalUrl = [[NSURL alloc] initWithString:[document.pdfURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                NSString *documentDirectory = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], [pdfLocalUrl lastPathComponent]];
                                readerDocument = [ReaderDocument unarchiveFromFileName:documentDirectory password:nil];
                            }
                            // create the new DocumentInfo instance
                            documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:readerDocument];
                            [loadedDocuments setObject:documentInfo forKey:document.documentID];
                        }
                        if ([document.downloaded boolValue] == NO && documentInfo.downloadTask == nil) {
                            //FDLogDebug(@"%@ requires update", document.pdfURL);
                            documentsToUpdate = YES;
                            if ([documentInfo.document isFault]) {
                                ReaderDocument *readerDocument = documentInfo.readerDocument;
                                documentInfo  = nil;
                                documentInfo = [[DocumentInfo alloc] initWithCoreDataDocument:document andReaderDocument:readerDocument];
                                [loadedDocuments setObject:documentInfo forKey:document.documentID];
                            }
                        }
                        
                        if ([document.downloaded boolValue] == YES) {
                            //Checking if document exists on local
                            [self updateDownloadedStatusWithDocument:document withContext:context];
                        }
                        [currentDocuments addObject:documentInfo];
                    }
                    
                }
            }
        }
        [downloadTasksToCheck removeAllObjects];
        for (DocumentInfo *docInfoToCheck in downloadTasks.allValues){
            if (docInfoToCheck.document != nil && ![self isExistCurrentDocument:docInfoToCheck.document]){
                docInfoToCheck.isAbleDownload = NO;
            }
            [downloadTasksToCheck setObject:docInfoToCheck forKey:docInfoToCheck.downloadTask];
        }
        for(int i = 0 ; i < loadedDocuments.allValues.count ; i ++){
            DocumentInfo *docInfoToCheck = [loadedDocuments.allValues objectAtIndex:i];
            NSNumber *documentIDToCheck = [loadedDocuments.allKeys objectAtIndex:i];
            if (docInfoToCheck.document != nil && ![self isExistCurrentDocument:docInfoToCheck.document]){
                [loadedDocuments removeObjectForKey:documentIDToCheck];
            }
        }
        
        // refresh the thumbs view
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
        [self.delegate enableUpdateButton:documentsToUpdate];
    }
}
    - (BOOL)isExistCurrentDocument:(Document *)doc{
        NSError *error;
        NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        // load the groups
        NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
        NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
        [groupRequest setEntity:groupEntityDescription];
        NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"documentID == %@", doc.documentID];
        [groupRequest setPredicate:groupPredicate];
        NSArray *docArray = [context executeFetchRequest:groupRequest error:&error];
        if (docArray != nil && docArray.count > 0) {
            return  YES;
        }else{
            return NO;
        }
    }
- (void)updateDownloadedStatusWithDocument:(Document *)document withContext:(NSManagedObjectContext *)contextDoc{
    NSError *error;
    NSString *documentName = [document.remoteURL lastPathComponent];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempPath = [documentPaths objectAtIndex:0];
    // TODO: determine the document file name
    NSString *destinationPath = [tempPath stringByAppendingPathComponent:documentName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    FDLogDebug(@"Checking if '%@' already exists...", destinationPath);
    if([fileManager fileExistsAtPath:destinationPath])
    {
        
    }else{
        document.downloaded = @0;
        [contextDoc save:&error];
    }
}
- (void)populateDocumentsWithGroupName:(NSString *)groupName;
{
    currentGroupName = groupName;
    
    [self populateDocuments];
    
    FDLogDebug(@"Selected group: %@, Document count: %ld", currentGroupName, (unsigned long)[currentDocuments count]);
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
        if ([documentInfoForThumb.document.downloaded boolValue] == NO) {
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
    if (documentForThumb != nil && documentInfoForThumb.document != nil && [documentInfoForThumb.document.downloaded boolValue] == YES) {
        NSURL *fileURL = documentForThumb.fileURL;
        NSString *guid = documentForThumb.guid;
        NSString *phrase = documentForThumb.password;
        FDLogDebug(@"Loading local document for '%@' from '%@'", documentInfoForThumb.document.name, fileURL);
        ReaderThumbRequest *thumbRequest = [ReaderThumbRequest newForView:thumbCell fileURL:fileURL password:phrase guid:guid page:1 size:size];
        
        // Request the thumbnail
        UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:thumbRequest priority:NO];
        
        // Show image from cache
        if ([image isKindOfClass:[UIImage class]]){
            [thumbCell showImage:image];
        }
    } else {
        if (documentInfoForThumb.downloadTask == nil) {
            [thumbCell.progressView setProgress:0 animated:YES];
            thumbCell.hidden = YES;
        } else {
            [thumbCell showProgressView];
        }
        //FDLogDebug(@"No valid local document for '%@'", documentInfoForThumb.document.name);
    }
    
    if (isSelect) {
        thumbCell.maskToSelect.hidden = NO;
        
        if ([selectedThumbViews containsObject:documentInfoForThumb]) {
            thumbCell.imgToSelect.hidden = NO;
        }else{
            thumbCell.imgToSelect.hidden = YES;
        }
    }else{
        thumbCell.maskToSelect.hidden = YES;
    }
    
    Document *docToParse = documentInfoForThumb.document;
    NSString *docName = [[NSURL URLWithString:docToParse.remoteURL] lastPathComponent];
    NSInteger fileTypeValue = 0;
    NSArray *parseFileName = [docName componentsSeparatedByString:@"."];
    if (parseFileName.count > 1) {
        NSString *lastString = parseFileName[parseFileName.count-1];
        //1: image, 2: video, 3: pdf, 4: doc, txt, 5: ppt
        if ([lastString.lowercaseString isEqualToString:@"png"] || [lastString.lowercaseString isEqualToString:@"jpg"] || [lastString.lowercaseString isEqualToString:@"jpeg"]) {
            fileTypeValue = 1;
        }else if([lastString.lowercaseString isEqualToString:@"mov"] || [lastString.lowercaseString isEqualToString:@"avi"] || [lastString.lowercaseString isEqualToString:@"mp4"]){
            fileTypeValue = 2;
        }else if ([lastString.lowercaseString isEqualToString:@"pdf"]){
            fileTypeValue = 3;
        }else if ([lastString.lowercaseString isEqualToString:@"txt"] || [lastString.lowercaseString isEqualToString:@"doc"]){
            fileTypeValue = 4;
        }else if ([lastString.lowercaseString isEqualToString:@"ppt"] || [lastString.lowercaseString isEqualToString:@"pptx"]){
            fileTypeValue = 5;
        }
    }
    
    if (fileTypeValue == 3) {
        
    }else if (fileTypeValue == 1) {
        [thumbCell showImageWithUrl:[NSURL URLWithString:docToParse.remoteURL]];
    }else{
    
    }
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView refreshThumbCell:(DocumentsCell *)thumbCell forIndex:(NSInteger)index
{
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView didSelectThumbWithIndex:(NSInteger)index
{
    DocumentInfo *documentInfoForThumb = [currentDocuments objectAtIndex:index];
    if (isSelect) {
        if ([selectedThumbViews containsObject:documentInfoForThumb]) {
            [selectedThumbViews removeObject:documentInfoForThumb];
        }else{
            [selectedThumbViews addObject:documentInfoForThumb];
        }
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
    }else{
        Document *docToParse = documentInfoForThumb.document;
        NSString *docName = [[NSURL URLWithString:docToParse.remoteURL] lastPathComponent];
        NSInteger fileTypeValue = 0;
        NSArray *parseFileName = [docName componentsSeparatedByString:@"."];
        if (parseFileName.count > 1) {
            NSString *lastString = parseFileName[parseFileName.count-1];
            //1: image, 2: video, 3: pdf, 4: doc, txt, 5: ppt
            if ([lastString.lowercaseString isEqualToString:@"png"] || [lastString.lowercaseString isEqualToString:@"jpg"] || [lastString.lowercaseString isEqualToString:@"jpeg"]) {
                fileTypeValue = 1;
            }else if([lastString.lowercaseString isEqualToString:@"mov"] || [lastString.lowercaseString isEqualToString:@"avi"] || [lastString.lowercaseString isEqualToString:@"mp4"]){
                fileTypeValue = 2;
            }else if ([lastString.lowercaseString isEqualToString:@"pdf"]){
                fileTypeValue = 3;
            }else if ([lastString.lowercaseString isEqualToString:@"txt"] || [lastString.lowercaseString isEqualToString:@"doc"]){
                fileTypeValue = 4;
            }else if ([lastString.lowercaseString isEqualToString:@"ppt"] || [lastString.lowercaseString isEqualToString:@"pptx"]){
                fileTypeValue = 5;
            }
        }
        
        if (fileTypeValue == 3) {            
            ReaderDocument *documentForThumb = documentInfoForThumb.readerDocument;
            
            if (documentForThumb != nil && documentInfoForThumb.document != nil && [documentInfoForThumb.document.downloaded boolValue] == YES) {
                if (documentInfoForThumb.document.type != nil && [documentInfoForThumb.document.type integerValue] == 1) {
                    [self.delegate documentsView:self didSelectDocument:documentInfoForThumb withType:1];
                }else{
                    
                    [self.delegate documentsView:self didSelectDocument:documentInfoForThumb withType:2];
                }
            }
        }else{
            [self.delegate documentsView:self didSelectDocumentWithUrl:docToParse.remoteURL];
        }
    }
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView scrollViewWillBeginDragging:(BOOL)isActive{
    if (isActive && tmptext.text.length > 0) {
        [[AppDelegate sharedDelegate] startThreadToSyncData:3];
        [coverViewForRenameText removeFromSuperview];
        [self endEditing:YES];
        indexToEdit = -1;
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
    }
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView scrollViewDidScroll:(CGPoint)scrOffset{
    currentDocumentViewPoint = scrOffset;
}
- (void)thumbsView:(ReaderThumbsView *)thumbsView touchedCell:(id)thumbCell didPressThumbWithIndex:(NSInteger)index
{
    if ([currentGroupName isEqualToString:@"My Docs"]) {
        [[AppDelegate sharedDelegate] stopThreadToSyncData:3];
        NSLog(@"longpress");
        
        if (indexToEdit != -1) {
            [self endEditing:YES];
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"FlightDesk" message:@"Do you want to change current file's name?" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSError *error;
                NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                if (docToRename.documentID != nil && tmptext.text.length > 0) {
                    [[AppDelegate sharedDelegate] startThreadToSyncData:3];
                    [coverViewForRenameText removeFromSuperview];
                    docToRename.name = tmptext.text;
                    docToRename.lastUpdate = @(0);
                    [self endEditing:YES];
                    indexToEdit = -1;
                    [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
                    [context save:&error];
                }
            }];
            UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                [[AppDelegate sharedDelegate] startThreadToSyncData:3];
                [coverViewForRenameText removeFromSuperview];
                tmptext.text = @"";
                [self endEditing:YES];
                indexToEdit = -1;
                [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
            }];
            [alert addAction:yesButton];
            [alert addAction:noButton];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            indexToEdit = -1;
            DocumentsCell *cell = thumbCell;
            indexToEdit = index;
            docToRename = nil;
            DocumentInfo *documentInfoForThumb = [currentDocuments objectAtIndex:index];
            docToRename = documentInfoForThumb.document;
            //[theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
            
            //[coverViewForRenameText removeFromSuperview];
//            CGRect rectText = cell.frame;
//            rectText.origin.y = rectText.origin.y + rectText.size.height - 29.0f - thumbsView.contentOffset.y;
//            rectText.origin.x = rectText.origin.x + 9.0f;
//            rectText.size.width = rectText.size.width - 18.0f;
//            rectText.size.height = 43.0f;
            //tmptext.frame = rectText;
            tmptext.text = docToRename.name;
            [tmptext becomeFirstResponder];
            
            //CGRect titleRect = CGRectMake(9, rectText.size.height - 29, rectText.size.width - 18, 43);
            //tmptext.frame = titleRect;
            //[cell addSubview:tmptext];
            [self reloadViewsForRenaming];
            [self insertSubview:coverViewForRenameText aboveSubview:theThumbsView];
            
            //renameTxtDialog.transform = CGAffineTransformMakeScale(0.01, 0.01);
            [renameTxtDialog setFrame:CGRectMake(cell.frame.origin.x + cell.frame.size.width/2, cell.frame.origin.y + cell.frame.size.height/2, 350.0f, 80.0f)];
            [UIView animateWithDuration:0.4 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // animate it to the identity transform (100% scale)
                //renameTxtDialog.transform = CGAffineTransformIdentity;
                [renameTxtDialog setFrame:CGRectMake((coverViewForRenameText.frame.size.width-350.0f)/2, coverViewForRenameText.frame.size.height-500.0f, 350.0f, 80.0f)];
            } completion:^(BOOL finished){
                // if you want to do something once the animation finishes, put it here
            }];
        }
        
    }
}

- (void)hiddenKeyboard{
    [[AppDelegate sharedDelegate] startThreadToSyncData:3];
    [coverViewForRenameText removeFromSuperview];
    [self endEditing:YES];
    indexToEdit = -1;
    [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    textField.returnKeyType = UIReturnKeyDone;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    if (docToRename.documentID != nil && textField.text.length > 0) {
        [coverViewForRenameText removeFromSuperview];
        docToRename.name = tmptext.text;
        docToRename.lastUpdate = @(0);
        [self endEditing:YES];
        indexToEdit = -1;
        [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
        [context save:&error];
        [[AppDelegate sharedDelegate] startThreadToSyncData:3];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    if (docToRename.documentID != nil && text.length > 0) {
        docToRename.name = text;
        docToRename.lastUpdate = @(0);
        [context save:&error];
    }
    return YES;
}

- (void)reloadWithSelecting:(BOOL)isSelectable{
    [selectedThumbViews removeAllObjects];
    isSelect = isSelectable;
    [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
}

- (void)deleteViewsToBeSelected{
    NSError *error;
    NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectoryToDelte=[paths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (DocumentInfo *documentInfoToDelete in selectedThumbViews) {
        [currentDocuments removeObject:documentInfoToDelete];
        [loadedDocuments removeObjectForKey:documentInfoToDelete.document.documentID];
        Document *documentToDelete = documentInfoToDelete.document;
        if ([currentGroupName isEqualToString:@"My Docs"]) {
            [fm removeItemAtPath:[documentDirectoryToDelte stringByAppendingPathComponent:[documentToDelete.remoteURL lastPathComponent]] error:&error];
            DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
            deleteQueryForAssignment.type = @"document";
            deleteQueryForAssignment.idToDelete = documentToDelete.documentID;
            
            [context deleteObject:documentToDelete];
            [context save:&error];
            if (error) {
                NSLog(@"Error when saving managed object context : %@", error);
            }
        }else{
            // load the groups
            NSEntityDescription *groupEntityDescription = [NSEntityDescription entityForName:@"LessonGroup" inManagedObjectContext:context];
            NSFetchRequest *groupRequest = [[NSFetchRequest alloc] init];
            [groupRequest setEntity:groupEntityDescription];
            NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"name == %@", currentGroupName];
            [groupRequest setPredicate:groupPredicate];
            NSArray *groupArray = [context executeFetchRequest:groupRequest error:&error];
            if (groupArray == nil) {
                FDLogError(@"Unable to retrieve current group %@!", currentGroupName);
                [currentDocuments removeAllObjects];
            } else if (groupArray.count == 0) {
                FDLogDebug(@"No valid group %@ found!", currentGroupName);
                [currentDocuments removeAllObjects];
            } else if (groupArray.count > 0) {
                for (LessonGroup *lesGroup in groupArray){
                    for (Document *docToDel in lesGroup.documents) {
                        if ([docToDel.documentID integerValue] == [documentToDelete.documentID integerValue]) {
                            if (docToDel.studentID != nil) {
                                DeleteQuery *deleteQueryForAssignment = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                                NSString *typeForDoc = @"documentWithGroup";
                                if (docToDel.studentID != nil) {
                                    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"admin"]) {
                                        typeForDoc = [NSString stringWithFormat:@"%@#.#0", typeForDoc];
                                    }else{
                                        typeForDoc = [NSString stringWithFormat:@"%@#.#%ld", typeForDoc, [docToDel.studentID integerValue]];
                                    }
                                }else{
                                    typeForDoc = [NSString stringWithFormat:@"%@#.#0", typeForDoc];
                                }
                                if (docToDel.groupID != nil) {
                                    typeForDoc = [NSString stringWithFormat:@"%@#.#%ld", typeForDoc, [docToDel.groupID integerValue]];
                                }else{
                                    typeForDoc = [NSString stringWithFormat:@"%@#.#0", typeForDoc];
                                }
                                deleteQueryForAssignment.type =typeForDoc;
                                deleteQueryForAssignment.idToDelete = docToDel.documentID;
                                
                                [lesGroup removeDocumentsObject:docToDel];
                                [context deleteObject:docToDel];
                                [context save:&error];
                                if (error) {
                                    NSLog(@"Error when saving managed object context : %@", error);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    [context save:&error];
    if (error) {
        NSLog(@"Error when saving managed object context : %@", error);
    }
    [self.delegate reSetBadge];
    [selectedThumbViews removeAllObjects];
    [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
}

#pragma mark Document Updates

- (void)confirmDocumentUpdate
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == NotReachable) {
        // you must be connected to the internet to download documents
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must be connected to the internet to download documents." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else if (status == ReachableViaWiFi) {
        // safe to proceed
        [self doDocumentUpdate];
    } else if (status == ReachableViaWWAN) {
        // warn about data usage
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Document Download" message:@"You are not currently connected to the internet via WiFi so network carrier data usage will apply.  It is recommended you download documents on WiFi.  Do you still wish to update your documents now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        // optional - add more buttons:
        [alert addButtonWithTitle:@"YES"];
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self doDocumentUpdate];
    } else {
        [self.delegate enableUpdateButton:YES];
    }
}

- (void)doDocumentUpdate
{
    for (DocumentInfo *documentInfo in currentDocuments) {
        FDLogDebug(@"checking if %@ needs download", documentInfo.document.name);
        if ([documentInfo.document.downloaded boolValue] == NO && documentInfo.downloadTask == nil) {
            //NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            //NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
            //NSURLSession *session = [NSURLSession sharedSession];
            if (backgroundSession == nil) {
                // Session configuration
                //NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.NSUrlSession.FDDocs.app"];
                // Initialize session
                backgroundSession = [NSURLSession sessionWithConfiguration:backgroundSession.configuration delegate:self delegateQueue:nil];
            }
            FDLogDebug(@"Downloading %@", documentInfo.document.remoteURL);
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[documentInfo.document.remoteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            documentInfo.downloadTask = [backgroundSession downloadTaskWithRequest:request];
            [downloadTasksLock lock];
            [downloadTasks setObject:documentInfo forKey:documentInfo.downloadTask];
            [downloadTasksLock unlock];
            // download tasks are always created in the suspended state
            [documentInfo.downloadTask resume];
        }
    }
    
    [theThumbsView reloadThumbsContentOffset:currentDocumentViewPoint];
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error
{
    if (error != nil && error.code != -999) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [downloadTasksLock lock];
            DocumentInfo *taskDocument = [downloadTasks objectForKey:downloadTask];
            [downloadTasks removeObjectForKey:downloadTask];
            [downloadTasksLock unlock];
            taskDocument.downloadTask = nil;
            NSError *error;
            taskDocument.document.downloaded = @NO;
            NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
            [context save:&error];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[taskDocument.document.remoteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            taskDocument.downloadTask = [backgroundSession downloadTaskWithRequest:request];
            [downloadTasksLock lock];
            [downloadTasks setObject:taskDocument forKey:taskDocument.downloadTask];
            [downloadTasksLock unlock];
            // download tasks are always created in the suspended state
            [taskDocument.downloadTask resume];
//            NSString *errorStr = [NSString stringWithFormat:@"Error downloading '%@': %@", taskDocument.document.remoteURL, [error userInfo]];
//            FDLogError(errorStr);
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Document Download Failed" message:errorStr delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//            [alert show];
        });
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    double currentProgress = totalBytesWritten / (double)totalBytesExpectedToWrite;
    FDLogDebug(@"written: %lld total_written: %lld expected_to_write: %lld progress: %f", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, currentProgress);
    dispatch_async(dispatch_get_main_queue(), ^{
        [downloadTasksLock lock];
        DocumentInfo *taskDocument = [downloadTasks objectForKey:downloadTask];
        if (taskDocument.document != nil) {
            DocumentInfo *taskDocumentToCheck = [downloadTasksToCheck objectForKey:downloadTask];
            if (taskDocumentToCheck != nil && taskDocumentToCheck.isAbleDownload == NO){
                if(taskDocument.document.documentID != nil){
                    [loadedDocuments removeObjectForKey:taskDocument.document.documentID];
                }
                [downloadTasks removeObjectForKey:downloadTask];
                [downloadTask cancel];
            }
        }
        [downloadTasksLock unlock];
        if (taskDocument.currentCell != nil) {
            [taskDocument.currentCell.progressView setProgress:currentProgress animated:YES];
        }
        //taskDocument.progressView.progress = currentProgress;
        //[taskDocument.progressView setProgress:currentProgress animated:YES];
    });
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    FDLogDebug(@"Download complete of %@", [location path]);
    [downloadTasksLock lock];
    DocumentInfo *documentInfo = [downloadTasks objectForKey:downloadTask];
    [downloadTasks removeObjectForKey:downloadTask];
    [downloadTasksLock unlock];
    documentInfo.downloadTask = nil;
    if (documentInfo.document != nil) {
        NSError *error;
        NSString *documentName = [documentInfo.document.remoteURL lastPathComponent];
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *tempPath = [documentPaths objectAtIndex:0];
        // TODO: determine the document file name
        NSString *destinationPath = [tempPath stringByAppendingPathComponent:documentName];
        NSString *sourcePath = [location path];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        FDLogDebug(@"Checking if '%@' already exists...", destinationPath);
        if([fileManager fileExistsAtPath:destinationPath])
        {
            // remove the existing file
            FDLogDebug(@"Removing existing file from '%@'...", destinationPath);
            [fileManager removeItemAtPath:destinationPath error:&error];
        }
        FDLogDebug(@"Copying download from temporary file to '%@'...", destinationPath);
        if ([fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error] == NO)
        {
            NSString *errorStr = [NSString stringWithFormat:@"%@", error];
            dispatch_async(dispatch_get_main_queue(), ^{
                //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Document Storage Error" message:errorStr delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                //[alert show];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // reload the documents in the main view
                NSError *error;
                documentInfo.document.pdfURL = destinationPath;
                documentInfo.document.downloaded = @YES;
                FDLogDebug(@"updating storage name=%@,pdf=%@,remote=%@,downloaded=%@", documentInfo.document.name, documentInfo.document.pdfURL, documentInfo.document.remoteURL, documentInfo.document.downloaded);
                NSManagedObjectContext *context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
                
                NSEntityDescription *documentEntityDescription = [NSEntityDescription entityForName:@"Document" inManagedObjectContext:context];
                NSFetchRequest *documentRequest = [[NSFetchRequest alloc] init];
                [documentRequest setEntity:documentEntityDescription];
                NSPredicate *documentPredicate = [NSPredicate predicateWithFormat:@"documentID == %@", documentInfo.document.documentID];
                [documentRequest setPredicate:documentPredicate];
                NSArray *documentArray = [context executeFetchRequest:documentRequest error:&error];
                if (documentArray == nil) {
                } else if (documentArray.count == 0) {
                } else if (documentArray.count > 0) {
                    for (Document *docToUpdate in documentArray) {
                        docToUpdate.downloaded = @YES;
                    }
                }
                
                [context save:&error];
                ReaderDocument *newDocument = [ReaderDocument withDocumentFilePath:destinationPath password:nil];
                //[newDocument saveReaderDocument];
                //[newDocument archiveDocumentProperties];
                // update the document info's reader document
                documentInfo.readerDocument = newDocument;
                // TODO: fix the reloading of documents so that tasks are not lost
                
                
                
                
                [self populateDocuments];
            });
        }
    } else {
        FDLogDebug(@"invalid Document pointer for task %p", downloadTask);
    }
}

@end

#pragma mark -

//
//	DocumentsCell class implementation
//

@implementation DocumentsCell
{
	UIView *backView;
    
	UIView *maskView;
    
	UIView *titleView;
    
	UILabel *titleLabel;
    
	CGSize maximumSize;
    
	CGRect defaultRect;
}

@synthesize progressView;
@synthesize currentCellDocumentInfo;
@synthesize maskToSelect, imgToSelect;
#pragma mark Constants

#define CONTENT_INSET 8.0f

#define TITLE_INSET_SMALL 8.0f
#define TITLE_INSET_LARGE 12.0f

#define CHECK_INSET 4.0f

#pragma mark DocumentsCell instance methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
        currentCellDocumentInfo = nil;
        
		//imageView.contentMode = UIViewContentModeCenter;
        imageView.contentMode = UIViewContentModeLeft;
        
        // adjust this for large and small devices
        CGRect previewRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - 60);
        defaultRect = CGRectInset(previewRect, CONTENT_INSET, CONTENT_INSET);
		//defaultRect = CGRectInset(self.bounds, CONTENT_INSET, CONTENT_INSET);
        
		maximumSize = defaultRect.size; // Maximum thumb content size
        
		CGFloat newWidth = ((defaultRect.size.width / 4.0f) * 3.0f);
        
		CGFloat offsetX = ((defaultRect.size.width - newWidth) / 2.0f);
        
		defaultRect.size.width = newWidth; defaultRect.origin.x += offsetX;
        
        
		//imageView.frame = defaultRect; // Update the image view frame
        imageView.frame = CGRectMake(defaultRect.origin.x, defaultRect.origin.y, 0, 0);
        
		//CGFloat titleInset = (large ? TITLE_INSET_LARGE : TITLE_INSET_SMALL);
		//CGRect titleRect = CGRectInset(defaultRect, titleInset, titleInset);
		//titleRect.size.height /= 2.0f; // Half size title view height
        
        CGRect titleRect = CGRectMake(8, frame.size.height - 30, frame.size.width - 16, 45);
		titleView = [[UIView alloc] initWithFrame:titleRect];
        
		titleView.autoresizesSubviews = NO;
		titleView.userInteractionEnabled = NO;
		titleView.contentMode = UIViewContentModeRedraw;
		titleView.autoresizingMask = UIViewAutoresizingNone;
		//titleView.backgroundColor = [UIColor colorWithWhite:0.92f alpha:0.6f];
        titleView.backgroundColor = [UIColor colorWithWhite:0.92f alpha:1.0f];
		titleView.layer.borderColor = [UIColor colorWithWhite:0.86f alpha:1.0f].CGColor;
		titleView.layer.borderWidth = 1.0f; // Draw border around title view
        
		CGRect labelRect = titleView.bounds;
        
		titleLabel = [[UILabel alloc] initWithFrame:labelRect];
        
		titleLabel.autoresizesSubviews = NO;
		titleLabel.userInteractionEnabled = NO;
		titleLabel.contentMode = UIViewContentModeRedraw;
		titleLabel.autoresizingMask = UIViewAutoresizingNone;
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.font = [UIFont systemFontOfSize:13.0f];
		titleLabel.textColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
		titleLabel.numberOfLines = 0; // Fit in bounds
        
		[titleView addSubview:titleLabel]; // Add label to text view
        
        
		//[self insertSubview:titleView belowSubview:imageView]; // Insert
        [self insertSubview:titleView aboveSubview:imageView];
        
		backView = [[UIView alloc] initWithFrame:defaultRect];
        
		backView.autoresizesSubviews = NO;
		backView.userInteractionEnabled = NO;
		backView.contentMode = UIViewContentModeRedraw;
		backView.autoresizingMask = UIViewAutoresizingNone;
		backView.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
        
#if (READER_SHOW_SHADOWS == TRUE) // Option
        
		backView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
		backView.layer.shadowRadius = 4.0f; backView.layer.shadowOpacity = 1.0f;
		backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;
        
#endif // end of READER_SHOW_SHADOWS Option
        
		[self insertSubview:backView belowSubview:imageView]; // Insert
        
		maskView = [[UIView alloc] initWithFrame:imageView.bounds];
        
		maskView.hidden = YES;
		maskView.autoresizesSubviews = NO;
		maskView.userInteractionEnabled = NO;
		maskView.contentMode = UIViewContentModeRedraw;
		maskView.autoresizingMask = UIViewAutoresizingNone;
		maskView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
        
		[imageView addSubview:maskView]; // Add
        
        // initialize progress bar view
        progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.hidden = YES;
        [progressView setFrame:CGRectMake(10, defaultRect.size.height - 30, defaultRect.size.width - 20, 11)];
        [imageView addSubview:progressView];
        
        maskToSelect = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [maskToSelect setBackgroundColor:[UIColor clearColor]];
        
        imgToSelect = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width-50, frame.size.height-80, 40, 40)];
        [imgToSelect setImage:[UIImage imageNamed:@"select_img.png"]];
        [maskToSelect addSubview:imgToSelect];
        imgToSelect.hidden = YES;
        [self insertSubview:maskToSelect aboveSubview:titleView];
        
	}
    
	return self;
}

- (CGSize)maximumContentSize
{
	return maximumSize;
}
- (void)showImageWithUrl:(NSURL *)url
{
    //titleView.hidden = YES; // Hide title view
    
    NSInteger x = (self.bounds.size.width / 2.0f);
    NSInteger y = (self.bounds.size.height / 2.0f);
    
    CGPoint location = CGPointMake(x, y); // Center point
    
    CGRect viewRect = CGRectZero;
    viewRect.size = CGSizeMake(102.0f, 132.0f); // Position
    
    imageView.bounds = viewRect;
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.frame = viewRect;
    imageView.center = location;
    [imageView setImageWithURL:url];
    
    maskView.frame = imageView.bounds; backView.bounds = viewRect; backView.center = location;
    
#if (READER_SHOW_SHADOWS == TRUE) // Option
    
    backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;
    
#endif // end of READER_SHOW_SHADOWS Option
}
- (void)showImage:(UIImage *)image
{
	//titleView.hidden = YES; // Hide title view
    
	NSInteger x = (self.bounds.size.width / 2.0f);
	NSInteger y = (self.bounds.size.height / 2.0f);
    
	CGPoint location = CGPointMake(x, y); // Center point
    
	CGRect viewRect = CGRectZero; viewRect.size = image.size; // Position
    
	imageView.bounds = viewRect;
    imageView.center = location;
    imageView.image = image;
    
	maskView.frame = imageView.bounds; backView.bounds = viewRect; backView.center = location;
    
#if (READER_SHOW_SHADOWS == TRUE) // Option
    
	backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;
    
#endif // end of READER_SHOW_SHADOWS Option
}

- (void)showProgressView
{
    progressView.hidden = NO;
}

- (void)reuse
{
    //FDLogDebug(@"reusing document tile!");
    
	titleLabel.text = nil; titleView.hidden = NO;
    
    currentCellDocumentInfo.currentCell = nil;
    currentCellDocumentInfo = nil;
    
    progressView.hidden = YES;
    
    CGRect rectToUpdate = defaultRect;
    rectToUpdate.origin.y = defaultRect.origin.y + 20.0f;
	imageView.image = nil; imageView.frame = rectToUpdate;
    

	maskView.hidden = YES; maskView.frame = imageView.bounds; backView.frame = rectToUpdate;
    
#if (READER_SHOW_SHADOWS == TRUE) // Option
    
	backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;
    
#endif // end of READER_SHOW_SHADOWS Option
    
    [super reuse]; // Reuse thumb view
}

- (void)showTouched:(BOOL)touched
{
	maskView.hidden = (touched ? NO : YES);
}

- (void)showText:(NSString *)text
{
	titleLabel.text = text;
}

- (void)setDocumentInfo:(DocumentInfo *)info
{
    currentCellDocumentInfo = info;
}

@end
