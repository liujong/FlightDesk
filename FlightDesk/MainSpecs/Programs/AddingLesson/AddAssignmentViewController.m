//
//  AddAssignmentViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "AddAssignmentViewController.h"

@interface AddAssignmentViewController ()<UITableViewDelegate, UITableViewDataSource>{
    NSInteger currentIndex;
    BOOL isCurrentAssignUpdate;
    NSMutableDictionary *currentAssignmentToEdit;
    NSInteger positionToEdit;
}

@end

@implementation AddAssignmentViewController
@synthesize assignmentType;
@synthesize assignmentArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    currentAssignmentToEdit = [[NSMutableDictionary alloc] init];
    isCurrentAssignUpdate = NO;
    positionToEdit = 0;
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    
    assignmentDialogView.autoresizesSubviews = NO;
    assignmentDialogView.contentMode = UIViewContentModeRedraw;
    assignmentDialogView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    assignmentDialogView.layer.shadowRadius = 3.0f;
    assignmentDialogView.layer.shadowOpacity = 1.0f;
    assignmentDialogView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    assignmentDialogView.layer.shadowPath = [UIBezierPath bezierPathWithRect:assignmentDialogView.bounds].CGPath;
    assignmentDialogView.layer.cornerRadius = 5.0f;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor colorWithRed:0 green:140.0f/255.0f blue:1.0f alpha:1.0f].CGColor,
                              (__bridge id)[UIColor blueColor].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [titleBarImageView setImage:gradientImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateHide{
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dialogPositionCons.constant += -400.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
         }
         ];
    }
}
- (void)animateShow{
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             dialogPositionCons.constant += 300.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
             [AssignmentsTableView reloadData];
         }
         ];
    }
}


- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dialogPositionCons.constant += -400.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelAddAssignmentView:self];
         }
         ];
    }
}

- (IBAction)onDone:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             dialogPositionCons.constant += -400.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didDoneAddAssignmentView:self assignmentInfo:assignmentArray type:assignmentType];
         }
         ];
    }
}
- (void)showAlert:(NSString *)msg title:(NSString *)title{
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        NSLog(@"you pressed Yes, please button");
    }];
    [alert addAction:yesButton];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)onAddAssignments:(id)sender {
    if (!txtAssignmentReference.text.length)
    {
        [self showAlert:@"Please input Reference" title:@"Input Error"];
        return;
    }
    if (!txtAssignmentTitle.text.length)
    {
        [self showAlert:@"Please input Assignment Title" title:@"Input Error"];
        return;
    }
    if (!txtAssignmentChapters.text.length)
    {
        [self showAlert:@"Please input Chapters" title:@"Input Error"];
        return;
    }
    if (isCurrentAssignUpdate) {
        NSMutableDictionary *oneAssignmentToUpdate = [[NSMutableDictionary alloc] init];
        [oneAssignmentToUpdate setObject:txtAssignmentReference.text forKey:@"reference"];
        [oneAssignmentToUpdate setObject:txtAssignmentTitle.text forKey:@"title"];
        [oneAssignmentToUpdate setObject:txtAssignmentChapters.text forKey:@"chapters"];
        if ([currentAssignmentToEdit objectForKey:@"id"]) {
            [oneAssignmentToUpdate setObject:[currentAssignmentToEdit objectForKey:@"id"] forKey:@"id"];
        }
        [assignmentArray replaceObjectAtIndex:positionToEdit withObject:oneAssignmentToUpdate];
        isCurrentAssignUpdate = NO;
        [btnAddOrEdit setTitle:@"ADD" forState:UIControlStateNormal];
    }else{
        NSMutableDictionary *oneAssignment = [[NSMutableDictionary alloc] init];
        [oneAssignment setObject:txtAssignmentReference.text forKey:@"reference"];
        [oneAssignment setObject:txtAssignmentTitle.text forKey:@"title"];
        [oneAssignment setObject:txtAssignmentChapters.text forKey:@"chapters"];
        [assignmentArray addObject:oneAssignment];
    }
    [AssignmentsTableView reloadData];
    txtAssignmentChapters.text = @"";
    txtAssignmentTitle.text = @"";
    txtAssignmentReference.text = @"";
    
}
#pragma mark TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [assignmentArray count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *sortTableViewIdentifier = @"AssignmentItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sortTableViewIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:sortTableViewIdentifier];
    }
    NSDictionary *dict = [assignmentArray objectAtIndex:indexPath.row];
    cell.textLabel.text =[NSString stringWithFormat:@"%@ %@ %@", [dict objectForKey:@"reference"], [dict objectForKey:@"title"], [dict objectForKey:@"chapters"]];
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [btnAddOrEdit setTitle:@"Update" forState:UIControlStateNormal];
    NSDictionary *dict = [assignmentArray objectAtIndex:indexPath.row];
    positionToEdit = indexPath.row;
    currentAssignmentToEdit = [dict mutableCopy];
    txtAssignmentTitle.text = [dict objectForKey:@"title"];
    txtAssignmentReference.text = [dict objectForKey:@"reference"];
    txtAssignmentChapters.text = [dict objectForKey:@"chapters"];
    isCurrentAssignUpdate = YES;
}
@end
