//
//  UIBubbleTableViewCell.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <QuartzCore/QuartzCore.h>
#import "UIBubbleTableViewCell.h"
#import "NSBubbleData.h"
#import "UIImageView+AFNetworking.h"

@interface UIBubbleTableViewCell ()

@property (nonatomic, retain) UIView *customView;
@property (nonatomic, retain) UIImageView *bubbleImage;
@property (nonatomic, retain) UIImageView *avatarImage;
@property (nonatomic, retain) UILabel *avatarName;

- (void) setupInternalData;

@end

@implementation UIBubbleTableViewCell

@synthesize data = _data;
@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;
@synthesize showAvatar = _showAvatar;
@synthesize avatarImage = _avatarImage;
@synthesize avatarName = _avatarName;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
	[self setupInternalData];
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    self.data = nil;
    self.customView = nil;
    self.bubbleImage = nil;
    self.avatarImage = nil;
    self.avatarName = nil;
    [super dealloc];
}
#endif

- (void)setDataInternal:(NSBubbleData *)value
{
	self.data = value;
	[self setupInternalData];
}

- (void) setupInternalData
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (!self.bubbleImage )
    {
#if !__has_feature(objc_arc)
        self.bubbleImage = [[[UIImageView alloc] init] autorelease];
#else
        self.bubbleImage = [[UIImageView alloc] init];        
#endif
        [self addSubview:self.bubbleImage];
    }
    
    NSBubbleType type = self.data.type;
    
    CGFloat width = self.data.view.frame.size.width;
    CGFloat height = self.data.view.frame.size.height;
    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - self.data.insets.left - self.data.insets.right;
    CGFloat y = 0;
    
    // Adjusting the x coordinate for avatar
    if (self.showAvatar)
    {
        [self.avatarImage removeFromSuperview];
        [self.avatarName removeFromSuperview];
        self.avatarName = [[UILabel alloc] init];
#if !__has_feature(objc_arc)
        self.avatarImage = [[UIImageView alloc] initWithImage:nil];
        if (self.data.avatar_url) {
            [self.avatarImage setImageWithURL:[NSURL URLWithString:APPDELEGATE.profileUrl]];
        }
#else
        self.avatarImage = [[UIImageView alloc] initWithImage:nil];
        if (self.data.avatar_url) {
            //[self.avatarImage setImageWithURL:[NSURL URLWithString:APPDELEGATE.profileUrl]];
        }
        //
#endif
        if (type == BubbleTypeSomeoneElse)
        {            
            self.avatarImage.layer.cornerRadius = 35/2;
            self.avatarImage.layer.masksToBounds = YES;
            self.avatarImage.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
            self.avatarImage.layer.borderWidth = 1.0;
            
            CGFloat avatarX = 10 ;
            CGFloat avatarY = self.frame.size.height - 35;
            
            self.avatarImage.frame = CGRectMake(avatarX, avatarY, 35, 35);
            self.avatarImage.backgroundColor = [UIColor grayColor];
            self.avatarName.frame = CGRectMake(avatarX, avatarY, 35, 35);
            self.avatarName.backgroundColor = [UIColor clearColor];
            self.avatarName.textColor = [UIColor whiteColor];
            self.avatarName.text = self.data.avatar_name;
            self.avatarName.textAlignment = NSTextAlignmentCenter;
            self.avatarName.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
            [self addSubview:self.avatarImage];
            if ([self.data.friendID integerValue] == 999999) {
                [self.avatarImage setImage:[UIImage imageNamed:@"support.png"]];
            }else{
                [self addSubview:self.avatarName];
            }
            
            CGFloat delta = self.frame.size.height - (self.data.insets.top + self.data.insets.bottom + self.data.view.frame.size.height);
            if (delta > 0) y = delta;
            
            if (type == BubbleTypeSomeoneElse) x += 47;
        }else if(type == BubbleTypeMine){
            
            if (self.data.isGeneralBanner) {
                x -= 0;
            }else{
                
                self.avatarImage.layer.cornerRadius = 35/2;
                self.avatarImage.layer.masksToBounds = YES;
                self.avatarImage.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
                self.avatarImage.layer.borderWidth = 1.0;
                
                CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - 52;
                CGFloat avatarY = self.frame.size.height - 35;
                
                self.avatarImage.frame = CGRectMake(avatarX, avatarY, 35, 35);
                self.avatarImage.backgroundColor = [UIColor colorWithRed:16.0f/255.0f green:114.0f/255.0f blue:189.0f/255.0f alpha:1.0];
                
                self.avatarName.frame = CGRectMake(avatarX, avatarY, 35, 35);
                self.avatarName.backgroundColor = [UIColor clearColor];
                self.avatarName.textColor = [UIColor whiteColor];
                self.avatarName.text = self.data.avatar_name;
                self.avatarName.textAlignment = NSTextAlignmentCenter;
                self.avatarName.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
                [self addSubview:self.avatarImage];
                if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"support"]) {
                    [self.avatarImage setImage:[UIImage imageNamed:@"support.png"]];
                }else{
                    [self addSubview:self.avatarName];
                }
                
                CGFloat delta = self.frame.size.height - (self.data.insets.top + self.data.insets.bottom + self.data.view.frame.size.height);
                if (delta > 0) y = delta;
                x -= 54;
            }
        }
    }

    [self.customView removeFromSuperview];
    if (self.data != nil) {
        if (self.data.isGeneralBanner) {
            for (UIView * i in self.data.view.subviews) {
                if ([i isKindOfClass:[UILabel class]]) {
                    UILabel *lblToResize = (UILabel *)i;
                    CGRect rectOfLbl = lblToResize.frame;
                    rectOfLbl.size.width = self.frame.size.width;
                    [lblToResize setFrame:rectOfLbl];
                }
            }
        }
    }
    self.customView = self.data.view;
    if (self.data.isGeneralBanner) {
        self.customView.frame = CGRectMake(10, y + self.data.insets.top, self.frame.size.width-20, height);
        
    }else{
        self.customView.frame = CGRectMake(x + self.data.insets.left, y + self.data.insets.top, width, height);
    }
    [self.contentView addSubview:self.customView];

    if (self.data != nil) {
        if (self.data.isGeneralBanner) {
            
        }else{
            if (type == BubbleTypeSomeoneElse)
            {
                self.bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];
                
            }
            else {
                self.bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
            }
        }
    }

    self.bubbleImage.frame = CGRectMake(x, y, width + self.data.insets.left + self.data.insets.right, height + self.data.insets.top + self.data.insets.bottom);
}

@end
