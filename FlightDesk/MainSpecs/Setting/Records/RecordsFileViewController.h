//
//  RecordsFileViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>


@class RecordsFileCell;
@class RecordsFile;

@interface UploadFileInfo : NSObject

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLSessionDataTask *uploadTask;
@property (nonatomic, weak) RecordsFileCell *currentCell;
@property (nonatomic, strong) RecordsFile *recordsFile;

- (id)initWithCoreDataRecordsFile:(RecordsFile *)record;
@end

@interface RecordsFileViewController : UIViewController
{
    __weak IBOutlet UITableView *UsersTableView;
    __weak IBOutlet UILabel *lblTableTitle;
    __weak IBOutlet UIView *recordsFileCV;
    __weak IBOutlet UIView *recordsFileDialog;
    __weak IBOutlet UILabel *userNameLbl;
    __weak IBOutlet UIButton *btnAddRecords;
    __weak IBOutlet UIButton *btnDeleteRecords;
    __weak IBOutlet UIButton *btnClose;
    __weak IBOutlet UICollectionView *RecordsCollectionView;
    
    __weak IBOutlet UIView *studentsView;
    __weak IBOutlet UILabel *lblMyName;
    __weak IBOutlet UIView *vwCoverOfWebView;
    __weak IBOutlet UIWebView *webView;
}
- (IBAction)onDeleteRecordsFile:(id)sender;
- (IBAction)onAddRecordsFile:(id)sender;
- (IBAction)onCloseOrCancelEditMode:(id)sender;
- (IBAction)onMyRecords:(id)sender;

- (void)reloadUsersAndFiles;
@property (nonatomic, retain) MPMoviePlayerViewController *playerVC;

@end
