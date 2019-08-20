//
//  BannerImageCropViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 8/23/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HIPImageCropperView.h"

@protocol BannerImageCropViewControllerDelegate <NSObject>

- (void)didSelectBannerImage:(UIImage *)image withImageName:(NSString *)imageName;

@end

@interface BannerImageCropViewController : UIViewController
@property (strong, nonatomic) HIPImageCropperView *imageCropperView;
- (IBAction)onCancel:(id)sender;
- (IBAction)onChoose:(id)sender;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) NSString *imageName;
@property (weak, nonatomic) id <BannerImageCropViewControllerDelegate> delegate;
@end
