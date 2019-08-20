#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DFAFImageFetcher.h"
#import "DFImageManagerKit+AFNetworking.h"
#import "DFCachedImageResponse.h"
#import "DFImageCache.h"
#import "NSCache+DFImageManager.h"
#import "DFImageManagerKit.h"
#import "DFURLHTTPResponseValidator.h"
#import "DFURLImageFetcher.h"
#import "DFURLResponseValidating.h"
#import "DFCompositeImageManager.h"
#import "DFImageManager.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageDecoder.h"
#import "DFImageProcessor.h"
#import "UIImage+DFImageUtilities.h"
#import "DFImageCaching.h"
#import "DFImageDecoding.h"
#import "DFImageFetching.h"
#import "DFImageFetchingOperation.h"
#import "DFImageManaging.h"
#import "DFImageProcessing.h"
#import "DFImageManagerDefines.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"
#import "DFAnimatedImage.h"
#import "DFAnimatedImageDecoder.h"
#import "DFAnimatedImageProcessor.h"
#import "DFAnimatedImageView.h"
#import "DFImageManagerKit+GIF.h"
#import "DFCollectionViewPreheatingController.h"
#import "DFImageManagerKit+UI.h"
#import "DFImageRequest+UIKitAdditions.h"
#import "DFImageView.h"
#import "UIImageView+DFImageManager.h"

FOUNDATION_EXPORT double DFImageManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char DFImageManagerVersionString[];

