//
//  NSBubbleDocView.m
//  FlightDesk
//
//  Created by stepanekdavid on 7/27/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "NSBubbleDocView.h"
#import "UIImageView+AFNetworking.h"

@implementation NSBubbleDocView

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
    NSBubbleDocView *customView = [[[NSBundle mainBundle] loadNibNamed:@"NSBubbleDocView" owner:nil options:nil] lastObject];
    
    // make sure customView is not nil or the wrong class!
    if ([customView isKindOfClass:[NSBubbleDocView class]])
        return customView;
    else
        return nil;
}
-(void)initWithUrl:(NSString*)url thumb:(NSString*)thumburl withRemoteUrl:(NSString *)remoteUrl
{
    
    imvThumb.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [imvThumb addGestureRecognizer:tapGesture];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [imvThumb addGestureRecognizer:longPress];
    
    docUrl = url;
    remoteDocUrl = remoteUrl;
    [imvThumb setImageWithURL:[NSURL URLWithString:thumburl]];
}

- (void)setImageFrame:(CGRect)frame
{
    imvThumb.frame = frame;
}

-(void)handleTap
{
    [delegate pdfTouched:docUrl];
}

- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan)
        [delegate pdfLongPressed:docUrl withRemoteUrl:remoteDocUrl withView:self];
}
@end
