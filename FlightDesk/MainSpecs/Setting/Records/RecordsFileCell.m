//
//  RecordsFileCell.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "RecordsFileCell.h"

@implementation RecordsFileCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.recordsImageView.layer.masksToBounds = YES;
    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePressGesture:)];
    //pressGesture.minimumPressDuration = 0.8; //pressGesture.numberOfTouchesRequired = 1; pressGesture.delegate = self;
    [self addGestureRecognizer:pressGesture];
}
- (void)handlePressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) // Handle the press
    {
        [self.delegate pressedLongTouchToRename:self];
    }
}
@end
