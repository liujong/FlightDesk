//
//  DAScratchPadView.h
//  Drawjella
//
//  Created by jellastar on 11/30/15.
//  Copyright © 2015 jellastar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@protocol DAScratchPadViewDelegate
@optional;
- (void)didTapFirst;
@end

typedef enum {
    DAScratchPadToolTypePaint = 0,
    DAScratchPadToolTypeAirBrush,
    DAScratchPadToolTypeEraser
} DAScratchPadToolType;

@interface DAScratchPadView : UIControl

@property (assign) DAScratchPadToolType toolType;
@property (strong,nonatomic) UIColor* drawColor;
@property (assign) CGFloat drawWidth;
@property (assign) CGFloat eraserDrawWidth;
@property (assign) CGFloat drawOpacity;
@property (assign) CGFloat airBrushFlow;

@property (nonatomic, weak, readwrite) id <DAScratchPadViewDelegate> scratchDelegate;
- (void) clearToColor:(UIColor*)color;

- (UIImage*) getSketch;
- (void) setSketch:(UIImage*)sketch;

@end
