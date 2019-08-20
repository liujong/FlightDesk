//
//  WeightAndBalanceViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "WeightBalance+CoreDataClass.h"
#import "TMLineGraph.h"
@interface WeightAndBalanceViewController : UIViewController{
    BOOL isShownKeyboard;
    __weak IBOutlet UIScrollView *scrView;
}
@property CAShapeLayer *shapeLayerGraph,*shapeLayerGraphLine,*shapeLayerRedLine,*shapeLayerGraphUtility;
@property (strong,nonatomic)IBOutlet UIButton *wtClearBackBtn;
@property (strong, nonatomic)TMLineGraph *momentGraph;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property(nonatomic)NSInteger lastTextFieldTag;

@property(strong,nonatomic)IBOutlet UITableView *saveTableView;
@property (weak,nonatomic)IBOutlet UIButton *saveBtn;
@property (strong, nonatomic) IBOutlet UITextField *txtFieldName;
- (IBAction)actionSave:(id)sender;
@property(nonatomic,strong)NSMutableArray *arrayFiles;

- (IBAction)actionClearAll:(id)sender;

- (IBAction)backSaveAll:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *btnClearAll;
@property (strong,nonatomic)WeightBalance * wtTextValue;
@property (assign,nonatomic)BOOL isSaveFileSelected;

- (IBAction)clearBaseEmptyWeight:(id)sender;
- (IBAction)clearFrontPax1:(id)sender;
- (IBAction)clearFrontPax2:(id)sender;
- (IBAction)clearBackPax1:(id)sender;
- (IBAction)clearBackPax2:(id)sender;
- (IBAction)clearCargo1:(id)sender;
- (IBAction)clearCargo2:(id)sender;
- (IBAction)clearEmptyFuel:(id)sender;
- (IBAction)clearMainTanks:(id)sender;
- (IBAction)clearFuelAuxTanks:(id)sender;
- (IBAction)clearGrossRampWeight:(id)sender;
- (IBAction)clearMaxTakeOffWeight:(id)sender;
- (IBAction)clearMaxLandingWeight:(id)sender;
- (IBAction)clearMaxEmptyFuelWeight:(id)sender;
- (IBAction)clearMaxCargo1Weight:(id)sender;
- (IBAction)clearMaxCargo2Weight:(id)sender;
- (IBAction)clearRangeAtMAXGrossWeight:(id)sender;
- (IBAction)clearRangeAtMAXTakeOffWeight:(id)sender;
- (IBAction)clearRangeAtEmptyFuelWeight:(id)sender;
- (IBAction)clearRangeAtBasicEmptyWeight:(id)sender;
- (IBAction)clearRangeAtMAXGrossWeight2:(id)sender;
- (IBAction)clearRangeAtMAXTakeOffWeight2:(id)sender ;
- (IBAction)clearRangeAtEmptyFuelWeight2:(id)sender;
- (IBAction)clearRangeAtBasicEmptyWeight2:(id)sender;
@end
