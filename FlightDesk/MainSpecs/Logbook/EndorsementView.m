//
//  EndorsementView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 11/20/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#import "EndorsementView.h"

@implementation EndorsementView
{
    //LogEntry *currentLogEntry;
    NSNumber *currentInstructorID;
    NSNumber *currentUserID;
    
    // Primary fields
    UIPickerView *endorsementTitlePicker;
    UITextField *endorsementTitle;
    UITextField *endorsementText;
    NSMutableArray *endorsementArray;
    NSMutableArray *endorsementTextArray;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        BOOL editable = YES;
        /*if (currentLogEntry != nil && currentLogEntry.logLessonRecord != nil && currentLogEntry.logLessonRecord.instructorID != nil && [currentLogEntry.logLessonRecord.instructorID intValue] != [userID intValue]) {
            editable = NO;
        } else if (currentInstructorID != nil && [currentInstructorID intValue] != [userID intValue]) {
            editable = NO;
        }*/
        
        UIColor *logBookBGColor = [[UIColor alloc] initWithRed:190.0/255.0 green:230.0/255.0 blue:210.0/255.0 alpha:0.5];
        self.backgroundColor = logBookBGColor;
        UIColor *userFieldColor = [UIColor colorWithRed:0.02 green:0.47 blue:1 alpha:1];
        
        int y = 25;
        int endorsementFieldWidth = self.bounds.size.width - 50;
        int fixedColumWidths = 80 + 60 + 60 + 60 + 70 + 70 + 70 + 70 + 70;
        
        int x = 25;
        
        // Title
        endorsementTitlePicker = [[UIPickerView alloc] init];
        endorsementTitlePicker.dataSource = self;
        endorsementTitlePicker.delegate = self;
        endorsementTitlePicker.showsSelectionIndicator = YES;
        
        endorsementTitle = [[UITextField alloc] initWithFrame:CGRectMake(x, y, endorsementFieldWidth, 25)];
        endorsementTitle.font = [UIFont fontWithName:@"Helvetica" size:16];
        endorsementTitle.textAlignment = NSTextAlignmentCenter;
        endorsementTitle.textColor = userFieldColor;
        endorsementTitle.layer.borderColor = [UIColor blackColor].CGColor;
        endorsementTitle.layer.borderWidth = 1.0;
        /*if (currentLogEntry != nil && currentLogEntry.aircraftCategory != nil) {
            aircraftCategory.text = currentLogEntry.aircraftCategory;
        } else {
            aircraftCategory.text = [aircraftCategoryArray objectAtIndex:0];
        }*/
        endorsementTitle.inputView = endorsementTitlePicker;
        if (editable == NO) {
            endorsementTitle.enabled = NO;
            endorsementTitle.textColor = [UIColor blackColor];
        }
        [self addSubview:endorsementTitle];
        y += 40;

        // Text
        endorsementText = [[UITextField alloc] initWithFrame:CGRectMake(x, y, endorsementFieldWidth, 200)];
        endorsementText.font = [UIFont fontWithName:@"Helvetica" size:14];
        endorsementText.textAlignment = NSTextAlignmentCenter;
        endorsementText.textColor = userFieldColor;
        endorsementText.layer.borderColor = [UIColor blackColor].CGColor;
        endorsementText.layer.borderWidth = 1.0;
        endorsementText.text = @"";
        if (editable == NO) {
            endorsementText.enabled = NO;
            endorsementText.textColor = [UIColor blackColor];
        }
        [self addSubview:endorsementText];
        
        endorsementArray = [[NSMutableArray alloc] init];
        [endorsementArray addObject:@"Initial Solo"];
        [endorsementArray addObject:@"Private Pilot Knowledge Test"];
        [endorsementArray addObject:@"Solo Cross-Country"];
        
        endorsementTextArray = [[NSMutableArray alloc] init];
        [endorsementTextArray addObject:@"I certify that _ has satisfactorily completed a pre-solo written examination as required by 14 CFR 61.87(b), has received the flight instruction required by 14 CFR 61.87(c), has demonstrated proficiency in the applicable maneuvers therein and is competent to make safe solo flights in a _"];
        [endorsementTextArray addObject:@"I certify that _ has received the required training of 14 CFR 61.105 and is prepared for the Private Pilot - Airplane Knowledge Test."];
        [endorsementTextArray addObject:@"I certify that _ has satisfactorily completed ..."];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [endorsementArray count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [endorsementArray objectAtIndex:row];
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    endorsementTitle.text = [endorsementArray objectAtIndex:row];
    endorsementText.text = [endorsementTextArray objectAtIndex:row];
}

@end
