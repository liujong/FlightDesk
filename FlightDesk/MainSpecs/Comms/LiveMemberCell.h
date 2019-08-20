//
//  LiveMemberCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LiveMemberCell : UITableViewCell
+ (LiveMemberCell *)sharedCell;

@property (weak, nonatomic) IBOutlet UIImageView *userProfileImg;
@property (weak, nonatomic) IBOutlet UILabel *lblUserNamePreix;
@property (weak, nonatomic) IBOutlet UILabel *lblUserName;
@property (weak, nonatomic) IBOutlet UILabel *redBOfOneUser;
@property (weak, nonatomic) IBOutlet UILabel *lblUsersType;

- (void)setBorder;
- (void)parseUserName:(NSString *)userName;
- (void)setColorOnline:(NSNumber*)isActive;
@end
