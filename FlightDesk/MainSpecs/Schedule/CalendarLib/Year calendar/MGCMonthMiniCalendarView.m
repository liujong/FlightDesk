//
//  MGCMonthMiniCalendarView.m
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2015 Julien Martin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "MGCMonthMiniCalendarView.h"
#import "NSCalendar+MGCAdditions.h"
#import "Constant.h"


static const CGFloat kMonthMargin = 5;
static const CGFloat kDefaultDayFontSize = 13;
static const CGFloat kDefaultHeaderFontSize = 16;
static const CGFloat kMonthMarginiPhone = 5;
static const CGFloat kDefaultDayFontSizeiPhone = 7;
static const CGFloat kDefaultHeaderFontSizeiPhone = 8;


@interface MGCMonthMiniCalendarView ()

@property (nonatomic) NSDateFormatter *dateFormatter;	// date formatter used to format month names
@property (nonatomic, readonly) NSArray *dayLabels;		// strings for the week days symbols (M, T, W...)
@property (nonatomic) NSManagedObjectContext *context;
@end


@implementation MGCMonthMiniCalendarView

@synthesize dayLabels = _dayLabels;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _calendar = [NSCalendar currentCalendar];
        _date = [NSDate date];
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"MMMM yyyy";
        if (isiPad) {
            //NSLog(@"---------------- iPAD ------------------");
            _daysFont = [UIFont systemFontOfSize:kDefaultDayFontSize];
        }
        else{
            //NSLog(@"---------------- iPhone ------------------");
            _daysFont = [UIFont systemFontOfSize:kDefaultDayFontSizeiPhone];
        }
        
        _highlightColor = [UIColor blackColor];
        _showsDayHeader = YES;
        _showsMonthHeader = YES;
        
        _context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
        self.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tap = [UITapGestureRecognizer new];
        [tap addTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)handleTap:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        CGPoint pt = [gesture locationInView:gesture.view];
        // calc sizes
        CGSize daySize = [@"00" sizeWithAttributes:@{ NSFontAttributeName:self.daysFont }];
        CGFloat dayCellSize = MAX(daySize.width, daySize.height);
        CGFloat space = dayCellSize / 2.;
        
        CGRect rect = self.frame;
        rect = CGRectInset(rect, kMonthMargin, kMonthMargin);
        
        // draw month header
        if (self.showsMonthHeader)
        {
            CGRect headerRect = [self.headerText boundingRectWithSize:rect.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
            rect.origin.y += headerRect.size.height + space;
            rect.size.height -= headerRect.size.height + space;
        }
        
        CGFloat x = rect.origin.x, y = rect.origin.y;
        CGFloat spaceX = (rect.size.width - dayCellSize * self.dayLabels.count)/7;
        
        // draw days header
        if (self.showsDayHeader)
        {
            NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
            para.alignment = NSTextAlignmentCenter;
            para.lineBreakMode = NSLineBreakByCharWrapping;
            
            y += dayCellSize;
            
            UIBezierPath *line = [UIBezierPath bezierPathWithRect:CGRectMake(rect.origin.x, y + 2., rect.size.width, .1)];
            [line fill];
            
            y += space;
            if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                rect.size.height -= dayCellSize;
            }
        }
        CGFloat spaceY = (rect.size.height - dayCellSize * 6)/7;
        // draw day cells
        NSDate *firstDayInMonth = [self.calendar mgc_startOfMonthForDate:self.date];
        NSUInteger days = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayInMonth].length;
        NSUInteger firstCol = [self firstDayColumn];
        if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
            x = rect.origin.x + firstCol * (dayCellSize + spaceX);
        }else{
            x = rect.origin.x + firstCol * (dayCellSize + space);
        }
        for (NSUInteger i = 1, col = firstCol; i <= days; i++, col++)
        {
            if (col == self.dayLabels.count)
            {
                col = 0;
                x = rect.origin.x;
                if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                    y += dayCellSize + spaceY;
                }else{
                    y += dayCellSize + space;
                }
            }
            CGRect cellRect = CGRectMake(x, y, dayCellSize, dayCellSize);
            CGRect boxRect = CGRectInset(cellRect, -space / 2 + 1, -space / 2 + 1);
            if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                boxRect = CGRectInset(cellRect, -spaceX / 2 + 1, -space / 2 + 1);
            }
            if (CGRectContainsPoint(boxRect, pt)) {
                NSDate *selectedDate = [firstDayInMonth dateByAddingTimeInterval:60*60*24*(i-1)];
                if ([self.delegate respondsToSelector:@selector(selectedDateFromYearView:)]){
                    [self.delegate selectedDateFromYearView:selectedDate];
                }
                
            }
            if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                x += cellRect.size.width + spaceX;
            }else{
                x += cellRect.size.width + space;
            }
            
        }
    }
}
#pragma mark - Properties

- (NSArray*)dayLabels
{
    if (_dayLabels == nil)
    {
        NSArray *symbols = self.dateFormatter.veryShortStandaloneWeekdaySymbols;
        
        NSMutableArray *labels = [NSMutableArray array];
        for (int i = 0; i < symbols.count; i++)
        {
            // days array is zero-based, sunday first.
            // translate to get firstWeekday at position 0
            NSUInteger weekday = (i + self.calendar.firstWeekday - 1 + symbols.count) % symbols.count;
            
            [labels addObject:[symbols objectAtIndex:weekday]];
        }
        _dayLabels = labels;
    }
    return _dayLabels;
}

- (void)setCalendar:(NSCalendar*)calendar
{
    _calendar = [calendar copy];
    self.dateFormatter.calendar = calendar;
}

- (NSAttributedString*)headerText
{
    if (_headerText == nil)
    {
        NSString *s = [[self.dateFormatter stringFromDate:self.date]uppercaseString];
        UIFont *font;
        if (isiPad) {
            //NSLog(@"---------------- iPAD ------------------");
            font = [UIFont boldSystemFontOfSize:kDefaultHeaderFontSize];
        }
        else{
            //NSLog(@"---------------- iPhone ------------------");
            font = [UIFont boldSystemFontOfSize:kDefaultHeaderFontSizeiPhone];
        }
        
        
        NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
        para.alignment = NSTextAlignmentCenter;
        return [[NSAttributedString alloc]initWithString:s attributes:@{ NSFontAttributeName: font, NSParagraphStyleAttributeName: para }];
    }
    return _headerText;
}

- (NSUInteger)firstDayColumn
{
	NSDate *firstDayInMonth = [self.calendar mgc_startOfMonthForDate:self.date];
	NSUInteger weekday = [self.calendar components:NSCalendarUnitWeekday fromDate:firstDayInMonth].weekday;
	NSUInteger numDaysInWeek = [self.calendar maximumRangeOfUnit:NSCalendarUnitWeekday].length;
	// zero-based, 0 is the first day of week of current calendar
	weekday = (weekday + numDaysInWeek - self.calendar.firstWeekday) % numDaysInWeek;
	return weekday;
}

#pragma mark - Methods

- (CGSize)preferredSizeYearWise:(BOOL)yearWise
{
	CGSize daySize = [@"00" sizeWithAttributes:@{ NSFontAttributeName:self.daysFont }];
	CGFloat dayCellSize = MAX(daySize.width, daySize.height);
	CGFloat space = dayCellSize / 2.;
	
	NSUInteger numCols = self.dayLabels.count;
	NSUInteger numRows = self.showsDayHeader ? 1 : 0;
	if (yearWise)
		numRows += [self.calendar maximumRangeOfUnit:NSCalendarUnitWeekOfMonth].length;
	else
		numRows += [self.calendar rangeOfUnit:NSCalendarUnitWeekOfMonth inUnit:NSCalendarUnitMonth forDate:self.date].length;
	
	CGSize viewSize = CGSizeMake(numCols * dayCellSize + (numCols - 1) * space, numRows * dayCellSize + (numRows - 1) * space);
	
    if (self.showsMonthHeader)
    {
        CGRect headerRect = [self.headerText boundingRectWithSize:CGSizeMake(viewSize.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        viewSize.height += headerRect.size.height + space;
    }
    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
        viewSize.height += 2 * kMonthMargin;
        viewSize.width += 2 * kMonthMargin;
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        viewSize.height += 2 * kMonthMarginiPhone;
        viewSize.width += 2 * kMonthMarginiPhone;
    }
    
    return viewSize;
}

- (NSMutableAttributedString*)textForDayAtIndex:(NSUInteger)index cellColor:(UIColor*)cellColor
{
    NSString *s = [NSString stringWithFormat:@"%lu", (unsigned long)index];
    UIColor *color = [UIColor blackColor];
    UIFont *font = self.daysFont;
    
    if ([self.highlightedDays containsIndex:index] || cellColor != nil)
    {
        color = [UIColor colorWithWhite:1 alpha:1];
        //font = [UIFont fontWithDescriptor:[[self.daysFont fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:self.daysFont.pointSize];
    }
    
    NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
    para.alignment = NSTextAlignmentCenter;
    para.lineBreakMode = NSLineBreakByCharWrapping;
    
    return [[NSMutableAttributedString alloc]initWithString:s attributes:@{ NSFontAttributeName: font, NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName: para }];
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size
{
    return [self preferredSizeYearWise:NO];
}

- (void)drawRect:(CGRect)rect
{
	// calc sizes
	CGSize daySize = [@"00" sizeWithAttributes:@{ NSFontAttributeName:self.daysFont }];
	CGFloat dayCellSize = MAX(daySize.width, daySize.height);
	CGFloat space = dayCellSize / 2.;

    if (isiPad) {
        //NSLog(@"---------------- iPAD ------------------");
        rect = CGRectInset(rect, kMonthMargin, kMonthMargin);
    }
    else{
        //NSLog(@"---------------- iPhone ------------------");
        rect = CGRectInset(rect, kMonthMarginiPhone, kMonthMarginiPhone);
    }
	
	// draw month header
	if (self.showsMonthHeader)
	{
		CGRect headerRect = [self.headerText boundingRectWithSize:rect.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
		[self.headerText drawInRect:rect];
		
		rect.origin.y += headerRect.size.height + space;
		rect.size.height -= headerRect.size.height + space;
	}
	
	CGFloat x = rect.origin.x, y = rect.origin.y;
	
    CGFloat spaceX = (rect.size.width - dayCellSize * self.dayLabels.count)/7;
	
	// draw days header
	if (self.showsDayHeader)
	{
		NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
		para.alignment = NSTextAlignmentCenter;
		para.lineBreakMode = NSLineBreakByCharWrapping;
				
		for (int i = 0; i < self.dayLabels.count; i++)
		{
			NSString *s = [self.dayLabels objectAtIndex:i];
			CGRect cellRect = CGRectMake(x, rect.origin.y, dayCellSize, dayCellSize);
			[s drawInRect:cellRect withAttributes:@{ NSFontAttributeName:self.daysFont, NSParagraphStyleAttributeName:para }];
            if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                x += dayCellSize + spaceX;
            }else{
                x += dayCellSize + space;
            }
		}
		
		y += dayCellSize;
		
		UIBezierPath *line = [UIBezierPath bezierPathWithRect:CGRectMake(rect.origin.x, y + 2., rect.size.width, .1)];
		[line fill];
		
		y += space;
        if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
            rect.size.height -= dayCellSize;
        }
	}
	
    CGFloat spaceY = (rect.size.height - dayCellSize * 6)/7;
	
	// draw day cells
	NSDate *firstDayInMonth = [self.calendar mgc_startOfMonthForDate:self.date];
	NSUInteger days = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayInMonth].length;
	NSUInteger firstCol = [self firstDayColumn];
    if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
        x = rect.origin.x + firstCol * (dayCellSize + spaceX);
    }else{
        x = rect.origin.x + firstCol * (dayCellSize + space);
    }
	
	for (NSUInteger i = 1, col = firstCol; i <= days; i++, col++)
	{
		if (col == self.dayLabels.count)
		{
			col = 0;
			x = rect.origin.x;
            if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
                y += dayCellSize + spaceY;
            }else{
                y += dayCellSize + space;
            }
		}
		
		CGRect cellRect = CGRectMake(x, y, dayCellSize, dayCellSize);
		CGRect boxRect = CGRectInset(cellRect, -space / 2 + 1, -space / 2 + 1);
		
        if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
            boxRect = CGRectInset(cellRect, -spaceX / 2 + 1, -space / 2 + 1);
        }
        
		UIColor *bkgColor = nil;
		if ([self.delegate respondsToSelector:@selector(monthMiniCalendarView:backgroundColorForDayAtIndex:)])
			bkgColor = [self.delegate monthMiniCalendarView:self backgroundColorForDayAtIndex:i];
        
		if (bkgColor)
		{
			[bkgColor setFill];
			UIRectFill(boxRect);
		}
		////////
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = i-1;
        NSDate *nextDate = [self.calendar dateByAddingComponents:dayComponent toDate:firstDayInMonth options:0];
        if ([self checkReservationsWithDate:nextDate]) {
            UIBezierPath* pt = [UIBezierPath bezierPathWithOvalInRect:boxRect];
            [[UIColor purpleColor] setFill];
            [pt fill];

            CGRect boxRectBorder = CGRectMake(boxRect.origin.x+2, boxRect.origin.y+2, boxRect.size.width-4, boxRect.size.height-4);
            UIBezierPath* ptborder = [UIBezierPath bezierPathWithOvalInRect:boxRectBorder];
            [[UIColor whiteColor] setFill];
            [ptborder fill];
        }
        if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
            if ([self.calendar mgc_isDate:nextDate sameDayAsDate:self.date]){
                UIBezierPath* pt = [UIBezierPath bezierPathWithOvalInRect:boxRect];
                [[UIColor redColor] setFill];
                [pt fill];

                CGRect boxRectBorder = CGRectMake(boxRect.origin.x+2, boxRect.origin.y+2, boxRect.size.width-4, boxRect.size.height-4);
                UIBezierPath* ptborder = [UIBezierPath bezierPathWithOvalInRect:boxRectBorder];
                [[UIColor whiteColor] setFill];
                [ptborder fill];
            }
        }
        
        
        ////////
		if ([self.highlightedDays containsIndex:i])
		{
            UIBezierPath* p = [UIBezierPath bezierPathWithOvalInRect:boxRect];
            [self.highlightColor setFill];
            [p fill];
		}
		
		NSMutableAttributedString *as = [self textForDayAtIndex:i cellColor:bkgColor];
		[as drawInRect:cellRect];
		
        if ([AppDelegate sharedDelegate].isSelectedDayViewForBooking || [AppDelegate sharedDelegate].isSelectedWeekViewForBooking) {
            x += cellRect.size.width + spaceX;
        }else{
            x += cellRect.size.width + space;
        }
        
	}
}
- (BOOL)checkReservationsWithDate:(NSDate*)fouseDate{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    NSDate *nextDate = [self.calendar dateByAddingComponents:dayComponent toDate:fouseDate options:0];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone :[NSTimeZone timeZoneForSecondsFromGMT: 0]];
    
    NSDate *startDate = [dateFormatter dateFromString:[dateFormatter stringFromDate:fouseDate]];
    NSDate *endDate = [dateFormatter dateFromString:[dateFormatter stringFromDate:nextDate]];
    
    
    
    NSError *error;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ResourcesCalendar" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeIntervalStartDate > %@ AND timeIntervalStartDate <%@", [NSNumber numberWithDouble:[startDate timeIntervalSince1970] * 1000000], [NSNumber numberWithDouble:[endDate timeIntervalSince1970] * 1000000]];
    [request setPredicate:predicate];
    NSArray *fetchedResourcesCalendars = [self.context executeFetchRequest:request error:&error];
    if (fetchedResourcesCalendars.count > 0) {
        return YES;
    }
    return NO;
}
@end
