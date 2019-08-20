//
//  NSBubbleBanner.h
//  FlightDesk
//
//  Created by stepanekdavid on 8/23/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBubbleBanner : UIView{
    __weak IBOutlet UILabel *lblLargeText;
    __weak IBOutlet UILabel *lblMediumText;
    __weak IBOutlet UILabel *lblSmallText;
    __weak IBOutlet UIView *coverViewOfTexts;

}
+ (id)customView;
-(void)initWithString:(NSString*)bannerText withColor:(UIColor *)bgColor;
- (void)setViewFrame:(CGRect)frame;
@end
