//
//  JSAnimatedView.h
//  FlightDesk
//
//  Created by stepanekdavid on 8/29/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DFAnimatedImageView;
@class DFImageRequest;
@interface JSAnimatedView : UIView

@property (nonatomic, readonly) DFAnimatedImageView *imageView;

- (id)initWithFrameWithAnimatedImage:(CGRect)frame;

- (void)prepareForReuse;
- (void)setImageWithURL:(NSURL *)imageURL;
- (void)setImageWithRequest:(DFImageRequest *)request;
@end
