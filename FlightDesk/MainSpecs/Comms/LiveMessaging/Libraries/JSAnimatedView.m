//
//  JSAnimatedView.m
//  FlightDesk
//
//  Created by stepanekdavid on 8/29/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "JSAnimatedView.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>
#import <DFImageManager/DFImageManagerKit+GIF.h>

@interface JSAnimatedView ()

@property (nonatomic, readonly) UIProgressView *progressView;
@property (nonatomic) NSProgress *currentProgress;

@end
@implementation JSAnimatedView
- (void)dealloc {
    self.currentProgress = nil;
}
- (id)initWithFrameWithAnimatedImage:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[DFAnimatedImageView alloc] initWithFrame:frame];
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, frame.size.height-3, frame.size.width, 5)];
        
        [self addSubview:_imageView];
        [self addSubview:_progressView];
    }
    return self;
}
- (void)prepareForReuse {
    self.progressView.progress = 0;
    self.progressView.alpha = 1;
    self.currentProgress = nil;
    [self.imageView prepareForReuse];
}

- (void)setImageWithURL:(NSURL *)imageURL {
    [self setImageWithRequest:[DFImageRequest requestWithResource:imageURL]];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [_imageView setImageWithRequest:request];
    self.currentProgress = _imageView.imageTask.progress;
    if (_imageView.imageTask.state == DFImageTaskStateCompleted) {
        self.progressView.alpha = 0;
    }
}

- (void)setCurrentProgress:(NSProgress *)currentProgress {
    if (_currentProgress != currentProgress) {
        [_currentProgress removeObserver:self forKeyPath:@"fractionCompleted" context:nil];
        _currentProgress = currentProgress;
        [self.progressView setProgress:currentProgress.fractionCompleted];
        [currentProgress addObserver:self forKeyPath:@"fractionCompleted" options:kNilOptions context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _currentProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:_currentProgress.fractionCompleted animated:YES];
            if (_currentProgress.fractionCompleted == 1) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.progressView.alpha = 0;
                }];
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
@end
