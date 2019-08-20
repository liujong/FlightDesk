//
//  NSBubbleData.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <Foundation/Foundation.h>
#import "NSBubbleVideoPlayer.h"
#import "NSBubbleDocView.h"
@protocol NSBubbleDataDelegate <NSObject>

- (void)videoTouched:(NSString*)videoPath;
- (void)videoLongPressed:(NSString *)videoPath;
- (void)pdfTouched:(NSString*)pdfPath;
- (void)pdfLongPressed:(NSString *)pdfPath withRemoteurl:(NSString *)remoteUrl withView:(NSBubbleDocView *)pdfView;
- (void)imageTouched:(NSString*)imageurl;
- (void)photoLongPressed:(NSString *)photoPath  withView:(UIView *)selectedView withGif:(BOOL)isGif;
- (void)voiceLongPressed:(NSString *)audioPath;

- (void)docLongPressed:(NSString *)docPath withRemoteurl:(NSString *)remoteUrl withView:(UIView *)docView;
- (void)bannerTextLongPress:(NSString *)bannerTextStr withColor:(NSString *)textBgColor withView:(UIView *)bannerTextCoverView;

- (void)linkTouched:(NSString *)link;
- (void)linkLongTouched:(NSString *)link  withView:(UIView*)view;


- (void)textTouched:(NSString *)text;
- (void)textLongTouched:(NSString *)text  withView:(UIView*)view;

@end

typedef enum _NSBubbleType
{
    BubbleTypeMine = 0,
    BubbleTypeSomeoneElse = 1
} NSBubbleType;

@interface NSBubbleData : NSObject<NSBubbleVideoDelegate, NSBubbleDocViewDelegate>
{
    NSString *strimageurl;
}
@property (readonly, nonatomic) NSString *bannerTextStr;
@property (readonly, nonatomic) NSString *bannerTextBgColor;
@property (readonly, nonatomic) NSString *mediaFilePath; // exists for photo, voice, video
@property (readonly, nonatomic, strong) NSDate *date;
@property (readonly, nonatomic) NSBubbleType type;
@property (readonly, nonatomic, strong) UIView *view;
@property (readonly, nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) NSURL *avatar_url;
@property (nonatomic, strong) NSString *avatar_name;
@property (nonatomic, strong) NSNumber *messageID;
@property (nonatomic, strong) NSNumber *ordering;
@property (nonatomic, strong) NSNumber *friendID;
@property BOOL isGeneralBanner;
@property BOOL hadGIF;

@property (nonatomic, strong) UIView *coverView;

@property (nonatomic,retain) id<NSBubbleDataDelegate> delegate;

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type;
+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type;
- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type;
+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type;
// aded by jella
- (id)initWithImageUrl:(NSString *)imageUrl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize withBanner:(BOOL)isGeneralBanner isGIF:(BOOL)isGif;
+ (id)dataWithImageUrl:(NSString *)imageUrl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize withBanner:(BOOL)isGeneralBanner isGIF:(BOOL)isGif;
- (id)initWithVideo:(NSString *)video thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize;
+ (id)dataWithVideo:(NSString *)video thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize;
- (id)initWithPdf:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize;
+ (id)dataWithPdf:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize;
- (id)initWithDocs:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl date:(NSDate *)date type:(NSBubbleType)type;
+ (id)dataWithDocs:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl date:(NSDate *)date type:(NSBubbleType)type;

- (id)initWithBannerText:(NSString *)bannerText withBGColor:(NSString *)bgColor date:(NSDate *)date type:(NSBubbleType)type;
+ (id)dataWithBannerText:(NSString *)bannerText withBGColor:(NSString *)bgColor date:(NSDate *)date type:(NSBubbleType)type;
///
- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets;
+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets;

@end
