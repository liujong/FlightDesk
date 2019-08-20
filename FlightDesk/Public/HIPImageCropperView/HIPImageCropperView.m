//
//  HIPImageCropperView.m
//  HIPImageCropper
//
//  Created by Taylan Pince on 2013-05-27.
//  Copyright (c) 2013 Hipo. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "HIPImageCropperView.h"

@interface HIPImageCropperView () {
    UIView *borderView;
}

@property (nonatomic, readwrite, strong) UIScrollView *scrollView;
@property (nonatomic, readwrite, strong) UIView *overlayView;
@property (nonatomic, strong) UIActivityIndicatorView *loadIndicator;
@property (nonatomic, assign) CGFloat cropSizeRatio;
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) HIPImageCropperViewPosition maskPosition;

- (void)updateOverlay;

- (CGRect)localCropFrame;

- (void)didTriggerDoubleTapGesture:(UITapGestureRecognizer *)tapRecognizer;

@end


@implementation HIPImageCropperView

- (id)initWithFrame:(CGRect)frame
       cropAreaSize:(CGSize)cropSize
           position:(HIPImageCropperViewPosition)position
      borderVisible:(BOOL)borderVisible {
    
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.clipsToBounds = YES;
    
    [self setBackgroundColor:[UIColor blackColor]];
    
    CGFloat defaultInset = 0.0;
    
    CGSize maxSize = CGSizeMake(self.bounds.size.width - (defaultInset * 2),
                                self.bounds.size.height - (defaultInset * 2));
    
    _borderVisible = borderVisible;
    _maskPosition = position;
    _targetSize = cropSize;
    _cropSizeRatio = 1.0;
    
    if (cropSize.width >= cropSize.height) {
        if (cropSize.width > maxSize.width) {
            _cropSizeRatio = cropSize.width / maxSize.width;
        }
    } else {
        if (cropSize.height > maxSize.height) {
            _cropSizeRatio = cropSize.height / maxSize.height;
        }
    }
    
    cropSize = CGSizeMake(cropSize.width / _cropSizeRatio,
                          cropSize.height / _cropSizeRatio);
    
    CGFloat scrollViewVerticalPosition = 0.0;
    
    scrollViewVerticalPosition = (frame.size.height - cropSize.height) / 2;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:
                       CGRectMake((self.bounds.size.width - cropSize.width) / 2,
                                  scrollViewVerticalPosition, cropSize.width, cropSize.height)];
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.scrollView setDelegate:self];
    [self.scrollView setBounces:YES];
    [self.scrollView setBouncesZoom:YES];
    [self.scrollView setAlwaysBounceVertical:YES];
    [self.scrollView setAlwaysBounceHorizontal:YES];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView.layer setMasksToBounds:NO];
    [self.scrollView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc]
                                                   initWithTarget:self
                                                   action:@selector(didTriggerDoubleTapGesture:)];
    
    [doubleTapRecognizer setNumberOfTapsRequired:2];
    [doubleTapRecognizer setNumberOfTouchesRequired:1];
    
    [self.scrollView addGestureRecognizer:doubleTapRecognizer];
    
    [self addSubview:self.scrollView];
    
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:cropSize.width]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:cropSize.height]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.scrollView.bounds];
    
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.scrollView addSubview:self.imageView];
    
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.overlayView setUserInteractionEnabled:NO];
    [self.overlayView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
    
    [self addSubview:self.overlayView];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    if (_borderVisible) {
        borderView = [[UIView alloc] initWithFrame:
                      self.scrollView.frame];
        
        borderView.translatesAutoresizingMaskIntoConstraints = NO;
        [borderView.layer setBorderColor:[[[UIColor whiteColor] colorWithAlphaComponent:0.5] CGColor]];
        [borderView.layer setBorderWidth:1.0];
        [borderView setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:borderView];
        
        [borderView addConstraint:[NSLayoutConstraint constraintWithItem:borderView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:_targetSize.width]];
        [borderView addConstraint:[NSLayoutConstraint constraintWithItem:borderView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:_targetSize.height]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:borderView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:borderView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    }
    
    [self updateOverlay];
    
    self.loadIndicator = [[UIActivityIndicatorView alloc]
                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.loadIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.loadIndicator setHidesWhenStopped:YES];
    [self.loadIndicator setCenter:self.scrollView.center];
    
    
    [self addSubview:self.loadIndicator];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.loadIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.loadIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    //    [self updateOverlay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateOverlay];
}

- (void)startLoadingAnimated:(BOOL)animated {
    [self.loadIndicator startAnimating];
    
    [UIView animateWithDuration:(animated) ? 0.2 : 0.0
                     animations:^{
                         [self.imageView setAlpha:0.0];
                         [self.loadIndicator setAlpha:1.0];
                     }];
}

- (void)setOriginalImage:(UIImage *)originalImage {
    [self setOriginalImage:originalImage withCropFrame:CGRectZero];
}

- (void)setOriginalImage:(UIImage *)originalImage
           withCropFrame:(CGRect)cropFrame {
    
    [self.loadIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CGImageRef imageRef = CGImageCreateCopy([originalImage CGImage]);
        UIImageOrientation imageOrientation = [originalImage imageOrientation];
        
        if (!imageRef) {
            return;
        }
        
        size_t bytesPerRow = 0;
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
        
        switch (imageOrientation) {
            case UIImageOrientationRightMirrored:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationLeft:
                width = CGImageGetHeight(imageRef);
                height = CGImageGetWidth(imageRef);
                break;
            default:
                break;
        }
        
        CGSize imageSize = CGSizeMake(width, height);
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     bitmapInfo);
        
        CGColorSpaceRelease(colorSpace);
        
        if (!context) {
            CGImageRelease(imageRef);
            
            return;
        }
        
        switch (imageOrientation) {
            case UIImageOrientationRightMirrored:
            case UIImageOrientationRight:
                CGContextTranslateCTM(context, imageSize.width / 2, imageSize.height / 2);
                CGContextRotateCTM(context, -M_PI_2);
                CGContextTranslateCTM(context, -imageSize.height / 2, -imageSize.width / 2);
                break;
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationLeft:
                CGContextTranslateCTM(context, imageSize.width / 2, imageSize.height / 2);
                CGContextRotateCTM(context, M_PI_2);
                CGContextTranslateCTM(context, -imageSize.height / 2, -imageSize.width / 2);
                break;
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                CGContextTranslateCTM(context, imageSize.width / 2, imageSize.height / 2);
                CGContextRotateCTM(context, M_PI);
                CGContextTranslateCTM(context, -imageSize.width / 2, -imageSize.height / 2);
                break;
            default:
                break;
        }
        
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        CGContextDrawImage(context, CGRectMake(0.0, 0.0, CGImageGetWidth(imageRef),
                                               CGImageGetHeight(imageRef)), imageRef);
        
        CGImageRef contextImage = CGBitmapContextCreateImage(context);
        
        CGContextRelease(context);
        
        if (contextImage != NULL) {
            _originalImage = [UIImage imageWithCGImage:contextImage
                                                 scale:[originalImage scale]
                                           orientation:UIImageOrientationUp];
            
            CGImageRelease(contextImage);
        }
        
        CGImageRelease(imageRef);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGSize convertedImageSize = CGSizeMake(_originalImage.size.width / _cropSizeRatio,
                                                   _originalImage.size.height / _cropSizeRatio);
            
            [self.imageView setAlpha:0.0];
            [self.imageView setImage:_originalImage];
            
            CGSize sampleImageSize = CGSizeMake(fmaxf(convertedImageSize.width, self.scrollView.frame.size.width),
                                                fmaxf(convertedImageSize.height, self.scrollView.frame.size.height));
            
            [self.scrollView setMinimumZoomScale:1.0];
            [self.scrollView setMaximumZoomScale:1.0];
            [self.scrollView setZoomScale:1.0 animated:NO];
            [self.imageView setFrame:CGRectMake(0.0, 0.0, convertedImageSize.width,
                                                convertedImageSize.height)];
            
            CGFloat zoomScale = 1.0;
            
            if (convertedImageSize.width < convertedImageSize.height) {
                zoomScale = (self.scrollView.frame.size.width / convertedImageSize.width);
            } else {
                zoomScale = (self.scrollView.frame.size.height / convertedImageSize.height);
            }
            zoomScale = fmaxf(self.scrollView.frame.size.width / convertedImageSize.width, self.scrollView.frame.size.height / convertedImageSize.height);
            
            [self.scrollView setContentSize:sampleImageSize];
            
            if (zoomScale < 1.0) {
                [self.scrollView setMinimumZoomScale:zoomScale];
                [self.scrollView setMaximumZoomScale:1.0];
                [self.scrollView setZoomScale:zoomScale animated:NO];
            } else {
                [self.scrollView setMinimumZoomScale:zoomScale];
                [self.scrollView setMaximumZoomScale:zoomScale];
                [self.scrollView setZoomScale:zoomScale animated:NO];
            }
            
            [self.scrollView setContentInset:UIEdgeInsetsZero];
            [self.scrollView setContentOffset:
             CGPointMake((self.imageView.frame.size.width - self.scrollView.frame.size.width) / 2,
                         (self.imageView.frame.size.height - self.scrollView.frame.size.height) / 2)];
            
            if (cropFrame.size.width > 0.0 && cropFrame.size.height > 0.0) {
                CGFloat scale = [[UIScreen mainScreen] scale];
                CGFloat newZoomScale = (_targetSize.width * scale) / cropFrame.size.width;
                
                [self.scrollView setZoomScale:newZoomScale animated:NO];
                
                CGFloat heightAdjustment = (_targetSize.height / _cropSizeRatio) - self.scrollView.contentSize.height;
                CGFloat offsetY = cropFrame.origin.y + (heightAdjustment * _cropSizeRatio * scale);
                
                [self.scrollView setContentOffset:CGPointMake(cropFrame.origin.x / scale / _cropSizeRatio,
                                                              (offsetY / scale / _cropSizeRatio) - heightAdjustment)];
            }
            
            [self.scrollView setNeedsLayout];
            
            [UIView animateWithDuration:0.3
                             animations:^{
                                 [self.loadIndicator setAlpha:0.0];
                                 [self.imageView setAlpha:1.0];
                             } completion:^(BOOL finished) {
                                 [self.loadIndicator stopAnimating];
                                 
                                 [_delegate imageCropperViewDidFinishLoadingImage:self];
                             }];
        });
    });
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *t = [super hitTest:point withEvent:event];
    if (t)
        return self.scrollView;
    return nil;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)setBorderVisible:(BOOL)borderVisible {
    _borderVisible = borderVisible;
    
    [self updateOverlay];
}

- (void)setScrollViewTopOffset:(CGFloat)scrollViewTopOffset {
    CGRect scrollViewFrame = _scrollView.frame;
    
    scrollViewFrame.origin.y += scrollViewTopOffset;
    
    [_scrollView setFrame:scrollViewFrame];
    
    [self.loadIndicator setCenter:self.scrollView.center];
    
    [self updateOverlay];
}

- (void)updateOverlay {
    //    for (UIView *subview in [self.overlayView subviews]) {
    //        [subview removeFromSuperview];
    //    }
    //
    //
    
    CAShapeLayer *maskWithHole = [CAShapeLayer layer];
    
    CGRect biggerRect = self.overlayView.bounds;
    CGRect smallerRect = self.scrollView.frame;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPath];
    
    //    maskPath = [UIBezierPath bezierPathWithRoundedRect:<#(CGRect)#> byRoundingCorners:<#(UIRectCorner)#> cornerRadii:<#(CGSize)#>]
    
    [maskPath moveToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMaxY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(biggerRect), CGRectGetMinY(biggerRect))];
    [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(biggerRect), CGRectGetMinY(biggerRect))];
    
    if (_isOval)
        [maskPath appendPath:[UIBezierPath bezierPathWithOvalInRect:smallerRect]];
    else {
        [maskPath moveToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMinY(smallerRect))];
        [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMaxY(smallerRect))];
        [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(smallerRect), CGRectGetMaxY(smallerRect))];
        [maskPath addLineToPoint:CGPointMake(CGRectGetMaxX(smallerRect), CGRectGetMinY(smallerRect))];
        [maskPath addLineToPoint:CGPointMake(CGRectGetMinX(smallerRect), CGRectGetMinY(smallerRect))];
    }
    
    [maskWithHole setFrame:self.bounds];
    [maskWithHole setPath:[maskPath CGPath]];
    [maskWithHole setFillRule:kCAFillRuleEvenOdd];
    
    [self.overlayView.layer setMask:maskWithHole];
}

- (UIImage *)processedImage {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGImageRef imageRef = CGImageCreateCopy([self.imageView.image CGImage]);
    
    if (!imageRef) {
        return nil;
    }
    
    size_t bytesPerRow = 0;
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 _targetSize.width * scale,
                                                 _targetSize.height * scale,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        CGImageRelease(imageRef);
        
        return nil;
    }
    
    CGRect targetFrame = [self localCropFrame];
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, targetFrame, imageRef);
    
    CGImageRef contextImage = CGBitmapContextCreateImage(context);
    UIImage *finalImage = nil;
    
    CGContextRelease(context);
    
    if (contextImage != NULL) {
        finalImage = [UIImage imageWithCGImage:contextImage
                                         scale:scale
                                   orientation:UIImageOrientationUp];
        
        CGImageRelease(contextImage);
    }
    
    CGImageRelease(imageRef);
    
    return finalImage;
}

- (CGRect)localCropFrame {
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize originalImageSize = _originalImage.size;
    CGFloat actualHeight = originalImageSize.height * self.scrollView.zoomScale * scale;
    CGFloat actualWidth = originalImageSize.width * self.scrollView.zoomScale * scale;
    CGFloat heightAdjustment = (_targetSize.height / _cropSizeRatio) - self.scrollView.contentSize.height;
    CGFloat offsetX = -(self.scrollView.contentOffset.x * _cropSizeRatio * scale);
    CGFloat offsetY = (self.scrollView.contentOffset.y + heightAdjustment) * _cropSizeRatio * scale;
    CGRect targetFrame = CGRectMake(offsetX, offsetY, actualWidth, actualHeight);
    
    return targetFrame;
}

- (CGRect)cropFrame {
    CGRect localCropFrame = [self localCropFrame];
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat heightAdjustment = (_targetSize.height / _cropSizeRatio) - self.scrollView.contentSize.height;
    
    return CGRectMake(-localCropFrame.origin.x, localCropFrame.origin.y - (heightAdjustment * _cropSizeRatio * scale),
                      _targetSize.width / self.scrollView.zoomScale * scale,
                      _targetSize.height / self.scrollView.zoomScale * scale);
}

- (CGFloat)zoomScale {
    return self.scrollView.zoomScale;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //    if (scrollView.zoomScale == scrollView.minimumZoomScale) {
    if (!_isOval) {
        if (scrollView.contentOffset.x < 0) {
            CGRect scrollBounds = scrollView.bounds;
            scrollBounds.origin = CGPointMake(0, scrollView.contentOffset.y);
            scrollView.bounds = scrollBounds;
        }
        if (scrollView.contentOffset.x > scrollView.contentSize.width - CGRectGetWidth(scrollView.bounds)) {
            CGRect scrollBounds = scrollView.bounds;
            scrollBounds.origin = CGPointMake(scrollView.contentSize.width - CGRectGetWidth(scrollView.bounds), scrollView.contentOffset.y);
            scrollView.bounds = scrollBounds;
        }
    }
    //    }
}

#pragma mark - Gesture recognizers

- (void)didTriggerDoubleTapGesture:(UITapGestureRecognizer *)tapRecognizer {
    CGFloat currentZoomScale = self.scrollView.zoomScale;
    CGFloat maxZoomScale = self.scrollView.maximumZoomScale;
    CGFloat minZoomScale = self.scrollView.minimumZoomScale;
    CGFloat zoomRange = maxZoomScale - minZoomScale;
    
    if (zoomRange <= 0.0) {
        return;
    }
    
    CGFloat zoomPosition = (currentZoomScale - minZoomScale) / zoomRange;
    
    if (zoomPosition <= 0.5) {
        [self.scrollView setZoomScale:maxZoomScale animated:YES];
    } else {
        [self.scrollView setZoomScale:minZoomScale animated:YES];
    }
}

@end
