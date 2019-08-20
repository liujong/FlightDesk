//
//  NSBubbleVideoPlayer.m
//  InstantMessenger
//
//  Created by Wang MeiHua on 3/1/14.
//  Copyright (c) 2014 Wang. All rights reserved.
//

#import "NSBubbleVideoPlayer.h"

#import "UIImageView+AFNetworking.h"

@implementation NSBubbleVideoPlayer

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (id)customView
{
    NSBubbleVideoPlayer *customView = [[[NSBundle mainBundle] loadNibNamed:@"NSBubbleVideoPlayer" owner:nil options:nil] lastObject];
    
    // make sure customView is not nil or the wrong class!
    if ([customView isKindOfClass:[NSBubbleVideoPlayer class]])
        return customView;
    else
        return nil;
}

-(void)initWithUrl:(NSString*)url thumb:(NSString*)thumburl
{

	imvThumb.userInteractionEnabled = YES;
    
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
	[imvThumb addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [imvThumb addGestureRecognizer:longPress];
	
	videoUrl = url;
    [imvThumb setImageWithURL:[NSURL URLWithString:thumburl]];
}

- (void)setImageFrame:(CGRect)frame
{
    imvThumb.frame = frame;
}

-(void)handleTap
{
	[delegate videoTouched:videoUrl];
}

- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan)
        [delegate videoLongPressed:videoUrl];
}
@end
