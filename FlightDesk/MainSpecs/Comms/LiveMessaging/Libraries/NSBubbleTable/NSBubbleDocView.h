//
//  NSBubbleDocView.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class NSBubbleDocView;
@protocol NSBubbleDocViewDelegate <NSObject>

- (void)pdfTouched:(NSString*)pdfPath;
- (void)pdfLongPressed:(NSString *)pdfPath withRemoteUrl:(NSString *)remoteUrl withView:(NSBubbleDocView *)pdfView;
@end
@interface NSBubbleDocView : UIView
{
    IBOutlet UIImageView *imvThumb;
    NSString *docUrl;
    NSString *remoteDocUrl;
}
+ (id)customView;
-(void)initWithUrl:(NSString*)url thumb:(NSString*)thumburl withRemoteUrl:(NSString *)remoteUrl;
- (void)setImageFrame:(CGRect)frame;
@property (nonatomic,retain) id<NSBubbleDocViewDelegate> delegate;
@end
