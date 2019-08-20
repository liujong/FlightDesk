//
//  UIBubbleTableView.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import <UIKit/UIKit.h>

#import "UIBubbleTableViewDataSource.h"
#import "UIBubbleTableViewCell.h"

typedef enum _NSBubbleTypingType
{
    NSBubbleTypingTypeNobody = 0,
    NSBubbleTypingTypeMe = 1,
    NSBubbleTypingTypeSomebody = 2
} NSBubbleTypingType;

@class BubbleTableView;
@protocol BubbleTableViewDelegate
@optional;
- (void)scrollViewDidScrollWithBubble:(UIBubbleTableView *)_table ScrView:(UIScrollView *)_scrView;
@end

@interface UIBubbleTableView : UITableView <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

@property (nonatomic, assign) IBOutlet id<UIBubbleTableViewDataSource> bubbleDataSource;
@property (nonatomic) NSTimeInterval snapInterval;
@property (nonatomic) NSBubbleTypingType typingBubble;
@property (nonatomic) BOOL showAvatars;

- (void) scrollBubbleViewToBottomAnimated:(BOOL)animated;

@property (nonatomic, weak, readwrite) id <BubbleTableViewDelegate> bubbleTblDelegate;

@end
