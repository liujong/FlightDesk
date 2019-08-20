//
//  LiveChatViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIBubbleTableViewDataSource.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
@interface LiveChatViewController : UIViewController<UIBubbleTableViewDataSource>
{
    __weak IBOutlet UIBubbleTableView *bubbleTableView;
    __weak IBOutlet UITextView *txtMessage;
    
    __weak IBOutlet NSLayoutConstraint *keyboardHegith;
    
    NSMutableArray *bubbleData;
    IBOutlet UIView *navView;
    __weak IBOutlet UILabel *navTitle;
    
    __weak IBOutlet UIButton *btnSettings;
    
    __weak IBOutlet UIView *banerViewForUsers;
    __weak IBOutlet UIView *banerViewToCreateForAdmin;
    __weak IBOutlet NSLayoutConstraint *bubbleTblTopCons;
    __weak IBOutlet NSLayoutConstraint *keyboardConsForBanerView;
    
    __weak IBOutlet UIButton *btnBanerImage;
    __weak IBOutlet UITextField *txtLargeForBanner;
    __weak IBOutlet UITextField *txtMediumForBanner;
    __weak IBOutlet UITextField *txtSmallForBanner;
    
    IBOutlet UIView *topbannerTextView;
    __weak IBOutlet UILabel *topLblLarge;
    __weak IBOutlet UILabel *topLblMedium;
    __weak IBOutlet UILabel *topLblsmall;
    IBOutlet UIImageView *topBannerImage;
    __weak IBOutlet UIView *coverViewOfTextBanner;

    __weak IBOutlet UIView *sendingViewForUsers;

    __weak IBOutlet UIButton *btnClearGeneral;
    
}
- (IBAction)onClearGeneral:(id)sender;

- (IBAction)onChangeBgColor:(id)sender;
- (IBAction)onMessageSend:(id)sender;

- (IBAction)onCamera:(id)sender;
- (IBAction)onPhotoVideoLibrary:(id)sender;
- (IBAction)onShareFiles:(id)sender;

- (IBAction)onSetting:(id)sender;
- (IBAction)onDashBoard:(id)sender;

- (IBAction)onSetBannerImage:(id)sender;
- (IBAction)onSendGeneralBannerByAdmin:(id)sender;
@property (nonatomic, strong) NSString *abbreviationName;
@property (nonatomic, strong) NSString *friendName;
@property (nonatomic, strong) NSString *friendID;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) NSNumber *boardID;
@property (nonatomic, strong) NSNumber *badgeCountOfUser;
@property (nonatomic, strong) NSNumber *isActive;

@property BOOL isGeneralBanner;
@property BOOL isGeneralRoom;

@property (nonatomic, retain) MPMoviePlayerViewController *playerVC;

- (void)reloadBannerView;
- (void)clearBannerWithPush;
- (void)clearGeneralMessages;
@end
