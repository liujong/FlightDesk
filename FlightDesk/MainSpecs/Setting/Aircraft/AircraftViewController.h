//
//  AircraftViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DateViewController.h"
#import "EndorsementCell.h"
#import <MediaPlayer/MediaPlayer.h>

@class RecordsFileCell;
@class MaintenanceLogs;

@interface UploadMaintenanceLogsInfo : NSObject

@property (nonatomic, strong) NSMutableURLRequest *urlRequest;
@property (nonatomic, strong) NSURLSessionDataTask *uploadTask;
@property (nonatomic, weak) RecordsFileCell *currentCell;
@property (nonatomic, strong) MaintenanceLogs *maintenanceLog;

- (id)initWithCoreDataMaintenanceLogs:(MaintenanceLogs *)maintenanceLog;
@end

@interface AircraftViewController : UIViewController{
    

    __weak IBOutlet UIScrollView *scrView;
    IBOutlet UIButton *btnAddAirCraft;
    __weak IBOutlet UITableView *AirCraftTableView;

    
    //add aircraft
    __weak IBOutlet UIView *addAircraftView;
    __weak IBOutlet UIView *aircraftAddingDialog;
    __weak IBOutlet UITableView *MaintaineTableView;
    __weak IBOutlet UITableView *AvionicsTableView;
    IBOutlet UIButton *btnAddNewMaintenance;
    IBOutlet UIButton *btnAvionics;
    __weak IBOutlet UIScrollView *scrAircraft;
    __weak IBOutlet UILabel *lblAircraftTitle;
    
    //add aircraft item
    __weak IBOutlet UIButton *btnAddAirCraftItem;
    __weak IBOutlet UITableView *AirCraftItemTableView;
    __weak IBOutlet UIView *addAircraftItemView;
    __weak IBOutlet UIView *addAircraftitemDialog;
    __weak IBOutlet UIButton *btnAircraftItemCancel;
    __weak IBOutlet UIButton *btnAircraftItemSave;
    __weak IBOutlet UIScrollView *scrAircraftItem;
    
    __weak IBOutlet UITextField *txtFieldName;
    __weak IBOutlet UITextField *txtValueMaxNum;
    __weak IBOutlet UITextField *txtNotiNumOfDaysPrior;
    __weak IBOutlet UITextField *txtNotiNumberOfDaysAfter;
    __weak IBOutlet UITextField *txtStartDate;
    __weak IBOutlet UITextField *txtEndDate;
    __weak IBOutlet UITextField *txtMultiDateNotifiNumAfter;
    
    __weak IBOutlet UITextField *txt25TachLastDone;
    __weak IBOutlet UITextField *txt25TachNextDue;
    __weak IBOutlet UITextField *txt50TachLastDone;
    __weak IBOutlet UITextField *txt50TachNextDue;
    __weak IBOutlet UITextField *txt100TachLastDone;
    __weak IBOutlet UITextField *txt100TachNextDue;
    __weak IBOutlet UITextField *txt2000TachLastDone;
    __weak IBOutlet UITextField *txt2000TachNextDue;
    
    
    __weak IBOutlet UITextField *txtMultiDateNotiNumPrior;
    __weak IBOutlet UITextField *txtLookupValue1;
    __weak IBOutlet UITextField *txtLookupValue2;
    __weak IBOutlet UITextField *txtLookupValue3;
    __weak IBOutlet UITextField *txtLookupValue4;
    __weak IBOutlet UITextField *txtLookupValue5;
    __weak IBOutlet UITextField *txtLookupValue6;
    __weak IBOutlet UITextField *txtLookupValue7;
    __weak IBOutlet UITextField *txtLookupValue8;
    
    
    __weak IBOutlet UIImageView *imgGroupSymbol;
    
    
    //limited parts
    __weak IBOutlet UIButton *btnLimitedPart;
    __weak IBOutlet UITableView *limitedPartTableView;
    //Squawks parts
    __weak IBOutlet UITableView *SquawksTableView;
    //other item
    IBOutlet UIButton *btnOtherItem;
    __weak IBOutlet UITableView *otherPartTableView;
    
    //Add Item
    __weak IBOutlet UILabel *lblAddItemTitle;
    IBOutlet UIView *AddOtherItemView;
    __weak IBOutlet UIView *AddOtherItemDialog;
    __weak IBOutlet UITextField *txtOtherItem;
    __weak IBOutlet UILabel *lblTitleToAddNewItem;
    
    //value group
    __weak IBOutlet UIButton *optionValue;
    __weak IBOutlet UIButton *btnCheckMNC;
    __weak IBOutlet UIButton *btnCheckAlpha;
    __weak IBOutlet UIButton *btnCheckLettersOnly;
    __weak IBOutlet UIButton *btnCheckLettersCAPS;
    __weak IBOutlet UIButton *btnCheckNumbersOnly;
    __weak IBOutlet UIButton *btnCheckTachBasedNoti;
    __weak IBOutlet UIButton *btnSubTach25;
    __weak IBOutlet UIButton *btnSubTach50;
    __weak IBOutlet UIButton *btnSubTach100;
    __weak IBOutlet UIButton *btnSubTach2000;
    
    //date group
    
    __weak IBOutlet UIButton *optionDate;
    __weak IBOutlet UIButton *btnCheckSD;
    __weak IBOutlet UIButton *btnCkeckNNDpD;
    __weak IBOutlet UIButton *btnCheckNNDAD;
    __weak IBOutlet UIButton *btnCheckMultiDate;
    __weak IBOutlet UIButton *btnCheckMultiNNDAD;
    __weak IBOutlet UIButton *btnCheckMultiNDPED;
    
    __weak IBOutlet UIButton *btnStartDate;
    
    __weak IBOutlet UIButton *btnEndDate;
    
    //look up group
    
    __weak IBOutlet UIButton *optionLookUp;
    
    //move views
    __weak IBOutlet UIView *mainTenanceView;
    __weak IBOutlet UIView *avionicsView;
    __weak IBOutlet UIView *lifeLimitedPartView;
    __weak IBOutlet UIView *otherItemViews;
    __weak IBOutlet UIView *squawksViews;
    
    //picker buttons
    
    //save button for add aircraft view
    
    __weak IBOutlet UIButton *btnAircraftSave;
    
    
    BOOL showKeyboard;
    __weak IBOutlet UIButton *btnShareCurrentAircraft;
    __weak IBOutlet UIButton *btnImportAircraft;
    
    //Squawks View
    __weak IBOutlet UIView *addSquawkItemView;
    __weak IBOutlet UIView *addSquawkDialog;
    __weak IBOutlet UILabel *lblSquawksTitle;
    __weak IBOutlet UIButton *btnSaveUpdateSquawks;
    __weak IBOutlet UITextView *squawkTxtView;
    
    //Maintenace logs
    __weak IBOutlet UIView *maintenanceLogsView;
    __weak IBOutlet UICollectionView *MaintenanceCollectionView;
    __weak IBOutlet UIButton *btnCloseOfLogs;
    __weak IBOutlet UIButton *btnAddLogs;
    __weak IBOutlet UIButton *btnDeleteLogs;
    __weak IBOutlet UIButton *btnShowHideLogs;
    
    __weak IBOutlet UIView *vwCoverOfWebView;
    __weak IBOutlet UIWebView *webView;
}

- (IBAction)onAddAirCraft:(id)sender;

//add aircraft
- (IBAction)onCancelAirCraftAdding:(id)sender;
- (IBAction)onSaveAirCraftAdding:(id)sender;

- (IBAction)onAddNewMaintenance:(id)sender;
- (IBAction)onAddNewAvionics:(id)sender;
- (IBAction)onAddLimitedPart:(UIButton *)sender;

//add Aircraft Item
- (IBAction)onAddnewAircraftItem:(UIButton *)sender;
- (IBAction)onCancelAddCraftItem:(UIButton *)sender;
- (IBAction)onSaveAddCraftItem:(UIButton *)sender;

//other item
- (IBAction)onAddOtherItem:(UIButton *)sender;
- (IBAction)onCancelAddOther:(UIButton *)sender;
- (IBAction)onAddOther:(UIButton *)sender;

//value group action handle

- (IBAction)onOptionValue:(UIButton *)sender;
- (IBAction)onCheckMNC:(UIButton *)sender;
- (IBAction)onCheckAlpha:(UIButton *)sender;
- (IBAction)onCheckLettersOnly:(UIButton *)sender;
- (IBAction)onCheckLettersCAPS:(UIButton *)sender;
- (IBAction)onCheckNumbersOnly:(UIButton *)sender;
- (IBAction)onCheckTachBasedNoti:(id)sender;
- (IBAction)onCheck25Tach:(UIButton *)sender;
- (IBAction)onCheck50Tach:(id)sender;
- (IBAction)onCheck100Tach:(id)sender;
- (IBAction)onCheck2000Tach:(id)sender;
//date group action handle

- (IBAction)onOptionDate:(UIButton *)sender;
- (IBAction)onCheckSD:(UIButton *)sender;
- (IBAction)onCkeckNNDpD:(UIButton *)sender;
- (IBAction)onCheckNNDAD:(UIButton *)sender;
- (IBAction)onCheckMultiDate:(UIButton *)sender;
- (IBAction)onCheckMultiNNDAD:(UIButton *)sender;
- (IBAction)onCheckMultiNDPED:(UIButton *)sender;

//look up action handle

- (IBAction)onOptionLookUp:(UIButton *)sender;
- (IBAction)onStartDate:(UIButton *)sender;
- (IBAction)onEndDate:(UIButton *)sender;

- (IBAction)onAddSquawks:(UIButton *)sender;



- (IBAction)onImportAircraft:(id)sender;
- (IBAction)onShareCurrentAircraft:(id)sender;

- (IBAction)onAddUpdateSquawk:(id)sender;
- (IBAction)onCancelSquawk:(id)sender;


- (void) displayContentController: (UIViewController*) content;
- (void)popUpDateDialog: (UIButton *) button;
- (void)popUpPickerDialog:(NSInteger)type withIndex:(NSInteger)index;


- (void)reloadData;

@property (nonatomic, weak, readwrite) id <EndorsementCellDelegate> delegate;

//Maintenance Logs
- (IBAction)onShowHideLogs:(UIButton *)sender;
- (IBAction)onCloseLogs:(UIButton *)sender;
- (IBAction)onAddLogs:(UIButton *)sender;
- (IBAction)onDeleteLogs:(UIButton *)sender;
@property (nonatomic, retain) MPMoviePlayerViewController *playerVC;



@end
