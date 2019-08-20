//
//  ActivityViewCustomActivity.m
//  FlightDesk
//
//  Created by stepanekdavid on 10/29/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "ActivityViewCustomActivity.h"

@implementation ActivityViewCustomActivity

- (NSString *)activityType
{
    return @"Flightdeskapp.MyDocs.App";
}

- (NSString *)activityTitle
{
    return @"Import to My Docs";
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"import_mydoc.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    
    [[AppDelegate sharedDelegate].rootViewControllerForTab setSelectedIndex:1];
    [[AppDelegate sharedDelegate].documents_vc uploadFileToRedirect:[AppDelegate sharedDelegate].filePathToImportMyDocs  withRedirectPad:YES];
    
}

@end
