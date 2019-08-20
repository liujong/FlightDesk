//
//  NavLogViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/4/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavLogViewController : UIViewController
{
    BOOL showKeyboard;
    __weak IBOutlet UIScrollView *scrView;
    __weak IBOutlet UITableView *NavLogTableView;
    __weak IBOutlet UITableView *preNavLogTableView;

    __weak IBOutlet UIView *navLogCoverView;
    __weak IBOutlet UIScrollView *navLogSrollingView;
    __weak IBOutlet UIView *preNavLogCoverView;
    __weak IBOutlet UIView *totalCoverView;
    
    //Top function

    __weak IBOutlet UICollectionView *SavedFilesCollectionView;
    __weak IBOutlet UITextView *txtViewNotes;
    __weak IBOutlet UITextField *txtNovlogName;
    __weak IBOutlet UITextField *txtAirCraft;
    __weak IBOutlet UITextField *txtDate;
    __weak IBOutlet UIButton *btnClear;
    __weak IBOutlet UIButton *btnDel;
    
    //Header of NavLog
    __weak IBOutlet UITextField *txtHeaderCasTas;
    __weak IBOutlet UITextField *txtHeaderDistRem;
    __weak IBOutlet UITextField *txtHeaderTimeOff;
    __weak IBOutlet UITextField *txtHeaderFuel;
    __weak IBOutlet UITextField *txtHeaderGPH;
    
    //total
    __weak IBOutlet UITextField *txtDistTotal;
    __weak IBOutlet UITextField *txtTimeOffTotal;
    __weak IBOutlet UITextField *txtGPHTotal;
    
    __weak IBOutlet UIView *coverViewToAddRo;
    __weak IBOutlet UIButton *btnAddNewWayPoint;
    
    //navigation bar
    IBOutlet UIView *navView;
    __weak IBOutlet UIButton *btnShare;
    __weak IBOutlet UIButton *btnPrint;
    
}
- (IBAction)onAddWayPoint:(id)sender;
- (IBAction)onGetDateNavLog:(id)sender;
- (IBAction)onGetTimeOff:(id)sender;
- (IBAction)onSave:(id)sender;
- (IBAction)onClearNavLog:(id)sender;
- (IBAction)onDelNavLog:(id)sender;


//navigation bar
- (IBAction)onBack:(id)sender;
- (IBAction)onShare:(id)sender;
- (IBAction)onPrint:(id)sender;

- (void)reloadNavLogs;

@end
