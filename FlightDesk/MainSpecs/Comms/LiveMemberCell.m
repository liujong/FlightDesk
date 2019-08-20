//
//  LiveMemberCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "LiveMemberCell.h"

@implementation LiveMemberCell
@synthesize userProfileImg, lblUserNamePreix, redBOfOneUser;
+ (LiveMemberCell *)sharedCell
{
    NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"LiveMemberCell" owner:nil options:nil];
    LiveMemberCell *cell = [array objectAtIndex:0];
    return cell;
}
- (void)setBorder{
    userProfileImg.layer.cornerRadius = userProfileImg.frame.size.height / 2.0f;
    userProfileImg.layer.masksToBounds = YES;
    userProfileImg.layer.borderColor = [UIColor grayColor].CGColor;
    userProfileImg.layer.borderWidth = 1.0f;
    
    
    redBOfOneUser.layer.cornerRadius = redBOfOneUser.frame.size.height / 2.0f;
    redBOfOneUser.layer.masksToBounds = YES;
}
- (void)parseUserName:(NSString *)userName{
    NSMutableArray *parseNameArray = [[NSMutableArray alloc] init];
    NSMutableArray *tmpNameArray = [[userName componentsSeparatedByString:@" "] mutableCopy];
    
    for (NSString *tmpName in tmpNameArray) {
        if (tmpName.length != 0 && tmpName != nil) {
            [parseNameArray addObject:tmpName];
        }
    }
    
    if (parseNameArray.count == 1) {
        NSString *tmpName = parseNameArray[0];
        if (tmpName.length == 1) {
            lblUserNamePreix.text = [parseNameArray[0] uppercaseString];
        }else if (tmpName.length > 1){
            lblUserNamePreix.text = [[parseNameArray[0] substringToIndex:2] uppercaseString];
        }else{
            lblUserNamePreix.text = @"";
        }
    }else if(parseNameArray.count > 1) {
        lblUserNamePreix.text = [NSString stringWithFormat:@"%@%@", [[parseNameArray[0] substringToIndex:1] uppercaseString], [[parseNameArray[1] substringToIndex:1] uppercaseString]];
    }
}

- (void)setColorOnline:(NSNumber*)isActive	{
    if ([isActive intValue] == 1)
        userProfileImg.backgroundColor = [UIColor colorWithRed:0.0f green: 102.0f/255.0f blue:0.0f alpha:1.0f];
    else
        userProfileImg.backgroundColor = [UIColor colorWithRed:192.0f/255.0f green: 192.0f/255.0f blue:192.0f/255.0f alpha:1.0f];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
