//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "NSBubbleVideoPlayer.h"
#import "NSBubbleDocView.h"
#import "NSBubbleBanner.h"
#import "UIImage+animatedGIF.h"
#import "UIImageView+WebCache.h"
#import "JSAnimatedView.h"
#import <ImageIO/ImageIO.h>
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+GIF.h>
#import "KILabel.h"

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar_url = _avatar_url;
@synthesize avatar_name = _avatar_name;
@synthesize delegate;
@synthesize mediaFilePath = _mediaFilePath;
@synthesize messageID = _messageID;
@synthesize ordering = _ordering;
@synthesize isGeneralBanner = _isGeneralBanner;
@synthesize hadGIF = _hadGIF;
@synthesize bannerTextStr = _bannerTextStr;
@synthesize bannerTextBgColor = _bannerTextBgColor;

@synthesize coverView = _coverView;

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;
    _hadGIF = NO;
    
    self.avatar_url = nil;
    self.avatar_name = @"";
    self.bannerTextStr = @"";
    self.bannerTextBgColor = @"";

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets textInsetsMine = {5, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {5, 15, 11, 10};

+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithText:text date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithText:text date:date type:type];
#endif    
}

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
    UIFont *font = [UIFont systemFontOfSize:15];
    CGSize size = [(text ? text : @"") sizeWithFont:font constrainedToSize:CGSizeMake(300, 9999) lineBreakMode:NSLineBreakByWordWrapping];
    
    KILabel *label = [[KILabel alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = (text ? text : @"");
    label.font = font;
    if (type == BubbleTypeMine) {
        label.textColor = [UIColor blackColor];
    }else if (type == BubbleTypeSomeoneElse){
        label.textColor = [UIColor whiteColor];
    }
    label.backgroundColor = [UIColor clearColor];
    label.systemURLStyle = YES;
    label.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {        
        [self.delegate linkTouched:string];
    };
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(linkUrlHandleTap:)];
    [label addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressPhoto:)];
    [label addGestureRecognizer:longPress];
#if !__has_feature(objc_arc)
    [label autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:label date:date type:type insets:insets];
}
- (void)linkUrlHandleTap:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        // Get the position of the touch in the label
        CGPoint location = [gesture locationInView:(KILabel *)gesture.view];
        KILabel * kiLbl = (KILabel *)gesture.view;
        // Get the link under the location from the label
        NSDictionary *link = [(KILabel *)gesture.view linkAtPoint:location];
        
        if (!link)
        {
            [self.delegate textTouched:kiLbl.text];
        }else{
            [self.delegate linkTouched:link[KILabelLinkKey]];
        }
    }
}
- (void)linkLongPressPhoto:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) { // check if image is loaded
        // Get the position of the touch in the label
        CGPoint location = [recognizer locationInView:(KILabel *)recognizer.view];
        
        // Get the link under the location from the label
        NSDictionary *link = [(KILabel *)recognizer.view linkAtPoint:location];
        
        KILabel * kiLbl = (KILabel *)recognizer.view;
        if (!link)
        {
            [self.delegate textLongTouched:kiLbl.text withView:recognizer.view];
        }else{
            [self.delegate linkLongTouched:link[KILabelLinkKey] withView:recognizer.view];
        }
        
    }
}


#pragma mark - Image bubble

const UIEdgeInsets imageInsetsMine = {11, 13, 16, 22};
const UIEdgeInsets imageInsetsSomeone = {11, 18, 16, 14};
+ (id)dataWithImageUrl:(NSString *)imageUrl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize withBanner:(BOOL)isGeneralBanner isGIF:(BOOL)isGif{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithImageUrl:imageUrl date:date type:type withImageSize:imageSize withBanner:isGeneralBanner isGIF:isGif] autorelease];
#else
    return [[NSBubbleData alloc] initWithImageUrl:imageUrl date:date type:type withImageSize:imageSize withBanner:isGeneralBanner isGIF:isGif];
#endif
}
- (id)initWithImageUrl:(NSString *)imageUrl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize withBanner:(BOOL)isGeneralBanner isGIF:(BOOL)isGif{
    
    
    
    CGSize size = imageSize;
    if (size.width > 220 && !isGeneralBanner)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    strimageurl = imageUrl;
    
    _mediaFilePath = imageUrl;
    
    UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    coverView.layer.cornerRadius = 5.0;
    coverView.layer.masksToBounds = YES;
    coverView.userInteractionEnabled = YES;
    
    if (isGif) {
        JSAnimatedView *jsAnimatedView = [[JSAnimatedView alloc] initWithFrameWithAnimatedImage:CGRectMake(0, 0, size.width, size.height)];
        [jsAnimatedView prepareForReuse];
        [jsAnimatedView setImageWithURL:[NSURL URLWithString:[imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [coverView addSubview:jsAnimatedView];
    }else{
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [imageView sd_setImageWithURL:[NSURL URLWithString:[imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        
        [coverView addSubview:imageView];
#if !__has_feature(objc_arc)
        [imageView autorelease];
#endif
    }
    
    _hadGIF = isGif;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTap)];
    [coverView addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressPhoto:)];
    [coverView addGestureRecognizer:longPress];
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:coverView date:date type:type insets:insets];
}

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithImage:image date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithImage:image date:date type:type];
#endif    
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type
{
    CGSize size = image.size;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    imageView.image = image;
    imageView.layer.cornerRadius = 5.0;
    imageView.layer.masksToBounds = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTap)];
    [imageView addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressPhoto:)];
    [imageView addGestureRecognizer:longPress];
    
#if !__has_feature(objc_arc)
    [imageView autorelease];
#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:imageView date:date type:type insets:insets];       
}
- (void)longPressPhoto:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) { // check if image is loaded
        [self.delegate photoLongPressed:[NSString stringWithFormat:@"%@", _mediaFilePath] withView:_view  withGif:_hadGIF];
    }
}

-(void)handelTap
{
    [self.delegate imageTouched:strimageurl];
}
+ (id)dataWithVideo:(NSString *)video thumb:(NSString *)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithVideo:video thumb:thumburl date:date type:type withImageSize:imageSize] autorelease];
#else
    return [[NSBubbleData alloc] initWithVideo:video thumb:thumburl date:date type:type withImageSize:imageSize];
#endif
}

- (id)initWithVideo:(NSString *)video thumb:(NSString *)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize
{
    CGSize size = imageSize;
    if (size.width > 220)
    {
        size.height /= (size.width / 220);
        size.width = 220;
    }
    NSBubbleVideoPlayer *videoplayer = [NSBubbleVideoPlayer customView];
    [videoplayer setFrame:CGRectMake(0, 0, size.width, size.height)];
    videoplayer.delegate = self;
    [videoplayer initWithUrl:video thumb:thumburl];
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:videoplayer date:date type:type insets:insets];
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithView:view date:date type:type insets:insets] autorelease];
#else
    return [[NSBubbleData alloc] initWithView:view date:date type:type insets:insets];
#endif    
}

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets  
{
    self = [super init];
    if (self)
    {
#if !__has_feature(objc_arc)
        _view = [view retain];
        _date = [date retain];
#else
        _view = view;
        _date = date;
#endif
        _type = type;
        _insets = insets;
    }
    return self;
}

#pragma mark NSBubblevideoPlayerDelgate

- (void)videoTouched:(NSString*)videoPath{
    [self.delegate videoTouched:videoPath];
}
- (void)videoLongPressed:(NSString *)videoPath{
    [self.delegate videoLongPressed:videoPath];
}

- (id)initWithPdf:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize{
    
    CGSize size = imageSize;
    if (size.width > 180)
    {
        size.height /= (size.width / 180);
        size.width = 180;
    }
    NSBubbleDocView *docView = [NSBubbleDocView customView];
    [docView setFrame:CGRectMake(0, 0, size.width, size.height)];
    docView.delegate = self;
    [docView initWithUrl:docUrl thumb:thumburl withRemoteUrl:remoteUrl];
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:docView date:date type:type insets:insets];
}
+ (id)dataWithPdf:(NSString *)docUrl  withRemoteUrl:(NSString *)remoteUrl thumb:(NSString*)thumburl date:(NSDate *)date type:(NSBubbleType)type withImageSize:(CGSize)imageSize{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithPdf:docUrl withRemoteUrl:remoteUrl thumb:thumburl date:date type:type withImageSize:imageSize] autorelease];
#else
    return [[NSBubbleData alloc] initWithPdf:docUrl withRemoteUrl:remoteUrl thumb:thumburl date:date type:type withImageSize:imageSize];
#endif
}
#pragma  mark NSBubbleDocViewDelegate
- (void)pdfTouched:(NSString*)pdfPath{
    [self.delegate pdfTouched:pdfPath];
}
- (void)pdfLongPressed:(NSString *)pdfPath withRemoteUrl:(NSString *)remoteUrl withView:(NSBubbleDocView *)pdfView{
    [self.delegate pdfLongPressed:pdfPath withRemoteurl:remoteUrl withView:pdfView];
}
- (id)initWithDocs:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl date:(NSDate *)date type:(NSBubbleType)type{
    strimageurl = remoteUrl;
    _mediaFilePath = remoteUrl;
    
    NSURL *url = [NSURL fileURLWithPath:docUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    _coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 80)];
//    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 220, 240)];
//    
//    [webView setScalesPageToFit:YES];
//    [webView  loadRequest:request];
//    [coverView addSubview:webView];
    
    UILabel *docNamelbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 220, 80)];
    docNamelbl.autoresizesSubviews = NO;
    docNamelbl.userInteractionEnabled = NO;
    docNamelbl.contentMode = UIViewContentModeRedraw;
    docNamelbl.autoresizingMask = UIViewAutoresizingNone;
    docNamelbl.textAlignment = NSTextAlignmentCenter;
    docNamelbl.font = [UIFont systemFontOfSize:13.0f];
    docNamelbl.textColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
    docNamelbl.backgroundColor = [UIColor clearColor];
    docNamelbl.lineBreakMode = NSLineBreakByCharWrapping;
    docNamelbl.numberOfLines = 0; // Fit in bounds
    docNamelbl.text = [url lastPathComponent];
    [_coverView addSubview:docNamelbl];
    
    _coverView.backgroundColor = [UIColor whiteColor];
    _coverView.layer.cornerRadius = 5.0;
    _coverView.layer.masksToBounds = YES;
    _coverView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTapWithWebView)];
    [_coverView addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressWithWebView:)];
    [_coverView addGestureRecognizer:longPress];
    
#if !__has_feature(objc_arc)
    [coverView autorelease];
#endif
    
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:_coverView date:date type:type insets:insets];
}
+ (id)dataWithDocs:(NSString *)docUrl withRemoteUrl:(NSString *)remoteUrl date:(NSDate *)date type:(NSBubbleType)type{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithDocs:docUrl withRemoteUrl:remoteUrl date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithDocs:docUrl withRemoteUrl:remoteUrl date:date type:type];
#endif
}
- (void)longPressWithWebView:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) { // check if image is loaded
        [self.delegate docLongPressed:_mediaFilePath withRemoteurl:_mediaFilePath withView:_coverView];
    }
}

-(void)handelTapWithWebView
{
    [self.delegate pdfTouched:strimageurl];
}

- (id)initWithBannerText:(NSString *)bannerText withBGColor:(NSString *)bgColor date:(NSDate *)date type:(NSBubbleType)type{
    
    _bannerTextStr = bannerText;
    _bannerTextBgColor = bgColor;
    
    
    NSArray *parseBannercolorArray = [bgColor componentsSeparatedByString:@":"];
    float redColor = [parseBannercolorArray[0] floatValue];
    float greenColor = [parseBannercolorArray[1] floatValue];
    float blueColor = [parseBannercolorArray[2] floatValue];
    
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
    
    UIView *coverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 720, 100)];
    coverView.backgroundColor = [UIColor colorWithRed:redColor/255.0f green:greenColor/255.0f blue:blueColor/255.0f alpha:1.0f];
    coverView.autoresizesSubviews = YES;
    
    UILabel *largeLBL = [[UILabel alloc] initWithFrame:CGRectMake(0, 11, 720, 32)];
    largeLBL.font = [UIFont fontWithName:@"Helvetica" size:19];
    largeLBL.textAlignment = NSTextAlignmentCenter;
    largeLBL.text = largeTxt;
    [coverView addSubview:largeLBL];
    UILabel *mediumLBL = [[UILabel alloc] initWithFrame:CGRectMake(0, 44, 720, 25)];
    mediumLBL.font = [UIFont fontWithName:@"Helvetica" size:15];
    mediumLBL.textAlignment = NSTextAlignmentCenter;
    mediumLBL.text = mediumTxt;
    [coverView addSubview:mediumLBL];
    UILabel *smallLBL = [[UILabel alloc] initWithFrame:CGRectMake(0, 72, 720, 20)];
    smallLBL.font = [UIFont fontWithName:@"Helvetica" size:12];
    smallLBL.textAlignment = NSTextAlignmentCenter;
    smallLBL.text = smallTxt;
    [coverView addSubview:smallLBL];
    coverView.layer.cornerRadius = 5.0;
    coverView.layer.masksToBounds = YES;
    coverView.userInteractionEnabled = YES;
#if !__has_feature(objc_arc)
    [coverView autorelease];
#endif
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressWithBannerText:)];
    [coverView addGestureRecognizer:longPress];
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:coverView date:date type:type insets:insets];
    
//    NSBubbleBanner *bubbleBaner = [NSBubbleBanner customView];
//    [bubbleBaner setViewFrame:CGRectMake(0, 0, 720, 100)];
//    [bubbleBaner initWithString:bannerText withColor:bgColor];
//    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
//    return [self initWithView:bubbleBaner date:date type:type insets:insets];
}
+ (id)dataWithBannerText:(NSString *)bannerText withBGColor:(NSString *)bgColor date:(NSDate *)date type:(NSBubbleType)type{
#if !__has_feature(objc_arc)
    return [[[NSBubbleData alloc] initWithBannerText:bannerText withBGColor:bgColor date:date type:type] autorelease];
#else
    return [[NSBubbleData alloc] initWithBannerText:bannerText withBGColor:bgColor date:date type:type];
#endif
}
- (void)longPressWithBannerText:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) { // check if image is loaded
        [self.delegate bannerTextLongPress:_bannerTextStr withColor:_bannerTextBgColor withView:_view];
    }
}

@end
