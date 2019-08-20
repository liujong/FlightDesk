//
//  BannerImageCropViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 8/23/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "BannerImageCropViewController.h"

@interface BannerImageCropViewController ()

@end

@implementation BannerImageCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    _imageCropperView = [[HIPImageCropperView alloc]
                         initWithFrame:self.view.bounds
                         cropAreaSize:CGSizeMake(self.view.bounds.size.width, 120)
                         position:HIPImageCropperViewPositionCenter
                         borderVisible:YES];
    _imageCropperView.isOval = NO;
    _imageCropperView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_imageCropperView];
    
    NSDictionary *viewsDictionary = @{@"cropperView":_imageCropperView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[cropperView]|" options:0 metrics:0 views:viewsDictionary]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_imageCropperView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_imageCropperView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_toolbar attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    
    [_imageCropperView setOriginalImage:_sourceImage];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onCancel:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onChoose:(id)sender {
    
    UIImage *resultImage = [_imageCropperView processedImage];
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectBannerImage: withImageName:)])
        [_delegate didSelectBannerImage:resultImage withImageName:self.imageName];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
