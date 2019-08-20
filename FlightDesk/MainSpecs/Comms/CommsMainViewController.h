//
//  CommsMainViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommsMainViewController : UIViewController{
    
    __weak IBOutlet UISearchBar *userSearchBar;
    __weak IBOutlet UITableView *userTableView;
    __weak IBOutlet UILabel *lblGeneralChatBadgeCount;
    IBOutlet UIView *headerView;
    __weak IBOutlet UIButton *btnGeneralBanersByAdmin;
    __weak IBOutlet UIButton *btnGeneralByAdmin;
    __weak IBOutlet UIView *navViewUsers;
    __weak IBOutlet UIImageView *navImageVoiew;
    __weak IBOutlet UIButton *btnSupport;
}
- (IBAction)onGeneralRoon:(id)sender;
- (IBAction)onGengeralBaners:(id)sender;
- (IBAction)onSupport:(id)sender;

- (void)getUsersWhatRequestSupports;
- (void)reloadTableViewWithPush;
- (void)reloadTableViewWithOnlineStatus:(NSString*)deviceToken onLinevalue:(NSNumber*)index;
@end
