//
//  LogbookRecordView.h
//  FlightDesk
//
//  Created by Gregory Bayard on 4/11/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TPKeyboardAvoidingScrollView.h"
#import "DateViewController.h"
#import "EndorsementCell.h"

@protocol EndorsementViewDelegate <NSObject>

@required // Delegate protocols

- (void)showEndorsement;
- (void)showEndorsementDateView:(NSInteger)type withIndex:(NSInteger)index;
- (void)showEndorsementSignatureView:(NSInteger)index;
- (void)showPickerViewToSelectItem:(NSInteger)type withIndex:(NSInteger)index;

@end

@class LogEntry;

@interface LogbookRecordView : TPKeyboardAvoidingScrollView <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, DateViewControllerDelegate, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, EndorsementCellDelegate>

- (id)initWithFrame:(CGRect)frame andLogEntry:(LogEntry*)logEntry andRecordLesson:(LessonRecord *)lessonRecord andLesson:(Lesson *)lessonOfLog andInstructorID:(NSNumber*)instructorID andUserID:(NSNumber*)userID CFInumber:(NSString *)cfiNum fromLesson:(BOOL)isFromLesson withTotalEngry:(BOOL)isTotal;
- (void)save;
- (LogEntry*)getCurrentEntry;

@property (nonatomic, weak) id<EndorsementViewDelegate> endorsementViewDelegate;

- (void)setDateFromDatePicker:(NSString *)_dateStr type:(NSInteger)_type withIndex:(NSInteger)index;
- (void)setSignature:(UIImage *)signImage withIndex:(NSInteger)index;
- (void)setCurrentItemFromPicker:(NSString *)componentStr withType:(NSInteger)_type withText:(NSString *)_text withIndex:(NSInteger)index;
- (void)ableToShowOtherView;
@end
