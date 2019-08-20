//
//  RecordsFileCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 10/16/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RecordsFileCell;
@protocol RecordsFileCellDelegate
@optional;
- (void)pressedLongTouchToRename:(RecordsFileCell *)_cell;
@end
@interface RecordsFileCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *recordsImageView;
@property (weak, nonatomic) IBOutlet UILabel *lblRecordsName;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;
@property (weak, nonatomic) IBOutlet UIView *maskView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *progressMaskView;

@property (nonatomic, weak, readwrite) id <RecordsFileCellDelegate> delegate;
@end
