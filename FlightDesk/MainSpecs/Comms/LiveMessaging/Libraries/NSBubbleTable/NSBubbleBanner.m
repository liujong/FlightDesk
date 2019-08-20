//
//  NSBubbleBanner.m
//  FlightDesk
//
//  Created by stepanekdavid on 8/23/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "NSBubbleBanner.h"

@implementation NSBubbleBanner
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
+ (id)customView{
    NSBubbleBanner *customView = [[[NSBundle mainBundle] loadNibNamed:@"NSBubbleBanner" owner:nil options:nil] lastObject];
    
    // make sure customView is not nil or the wrong class!
    if ([customView isKindOfClass:[NSBubbleBanner class]])
        return customView;
    else
        return nil;
}
-(void)initWithString:(NSString*)bannerText withColor:(UIColor *)bgColor{
    NSArray *parseBannerTextArray = [bannerText componentsSeparatedByString:@"#!#!#"];
    NSString *largeTxt = @"";
    NSString *mediumTxt = @"";
    NSString *smallTxt = @"";
    if (parseBannerTextArray.count == 3) {
        largeTxt = parseBannerTextArray[0];
        mediumTxt = parseBannerTextArray[1];
        smallTxt = parseBannerTextArray[2];
    }else if (parseBannerTextArray.count == 2) {
        largeTxt = parseBannerTextArray[0];
        mediumTxt = parseBannerTextArray[1];
    }else if (parseBannerTextArray.count == 1) {
        largeTxt = parseBannerTextArray[0];
    }
    lblLargeText.text = largeTxt;
    lblMediumText.text = mediumTxt;
    lblSmallText.text = smallTxt;
    [coverViewOfTexts setBackgroundColor:bgColor];
}
- (void)setViewFrame:(CGRect)frame{
}
@end
