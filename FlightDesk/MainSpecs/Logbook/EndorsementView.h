//
//  EndorsementView.h
//  FlightDesk
//
//  Created by Gregory Bayard on 11/20/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingScrollView.h"

@interface EndorsementView : TPKeyboardAvoidingScrollView <UIPickerViewDelegate, UIPickerViewDataSource>

- (id)initWithFrame:(CGRect)frame;

@end
