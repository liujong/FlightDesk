//
//  LessonRecordView.h
//  FlightDesk
//
//  Created by Gregory Bayard on 4/11/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingScrollView.h"
#import "LogbookRecordView.h"

@class Lesson;

@interface LessonRecordView : TPKeyboardAvoidingScrollView <UITextFieldDelegate, UITextViewDelegate>

- (id)initWithLesson:(Lesson*)lesson;
- (void)save;
- (void)updateLogBookHeight:(CGFloat)_height;

@property (nonatomic, retain) UIColor *userFieldColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, retain) UIColor *placeholderFieldColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, retain) LogbookRecordView *logBookView;

@end
