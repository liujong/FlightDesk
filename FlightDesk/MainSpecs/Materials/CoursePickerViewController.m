//
//  CoursePickerViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 2/8/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "CoursePickerViewController.h"

@interface CoursePickerViewController ()

@end

@implementation CoursePickerViewController
{
    NSArray *courses;
}

- (id)initWithStyle:(UITableViewStyle)style andCourses:(NSArray*)courseArray
{
    self = [super initWithStyle:style];
    courses = [NSArray arrayWithArray:courseArray];
    if (self) {
        // calculate how tall the view should be
        NSInteger rowsCount = [courses count];
        NSInteger singleRowHeight = [self.tableView.delegate tableView:self.tableView
                                               heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSInteger totalRowsHeight = rowsCount * singleRowHeight;
        
        // calculate how wide the view should be
        CGFloat largestLabelWidth = 0;
        for (NSString *courseName in courses) {
            CGSize labelSize = [courseName sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:20.0f]}];
            if (labelSize.width > largestLabelWidth) {
                largestLabelWidth = labelSize.width;
            }
        }
        
        // add some padding to the width
        CGFloat popoverWidth = largestLabelWidth + 100;
        
        // set the popover container size
        self.preferredContentSize = CGSizeMake(popoverWidth, rowsCount * 44.0f);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"gregdebug courses %lu", (unsigned long)courses.count);
    return [courses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    // Configure the cell...
    cell.textLabel.text = [courses objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (_delegate != nil) {
        NSLog(@"gregdebug calling selectedCourse courses %lu", (unsigned long)courses.count);
        [_delegate selectedCourse:[courses objectAtIndex:indexPath.row]];
    }
}

@end
