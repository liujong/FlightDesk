//
//  EndorsementViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 11/20/16.
//  Copyright © 2016 NOVA.GregoryBayard. All rights reserved.
//

#import "Logging.h"
#import "EndorsementViewController.h"
#import "EndorsementView.h"

@interface EndorsementViewController ()

@end

@implementation EndorsementViewController
{
    EndorsementView *endorsementView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = [NSString stringWithFormat:@"%@", @"Endorsement"];
    
    // grab the current user's ID
    NSString *userIDKey = @"userId";
    NSString *currentUserId = [[NSUserDefaults standardUserDefaults] objectForKey:userIDKey];
    NSNumber *userID = [NSNumber numberWithInteger: [currentUserId integerValue]];
    if (userID == nil) {
        FDLogError(@"Unable parse lessons update without being logged in!");
    }
    // determine if this entry is editable by the current user
    BOOL editable = YES;
    /*if (currentLogEntry.logLessonRecord != nil && [userID intValue] == [currentLogEntry.logLessonRecord.userID intValue]) {
     editable = NO;
     }*/
    
    endorsementView = [[EndorsementView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:endorsementView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
