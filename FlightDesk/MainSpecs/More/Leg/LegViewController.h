//
//  LegViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/12/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
@interface LegViewController : UIViewController
{
    __weak IBOutlet UIScrollView *scrView;
    
}
@property(strong,nonatomic)IBOutlet UITableView *saveTableView;

@property (nonatomic, weak) id <KeyboardDelegate> keyboardDelegate;
@property (strong, nonatomic) IBOutlet UITextField *nameTxtField;
@property (weak,nonatomic)IBOutlet UIButton *saveFlightBtn;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong)NSMutableArray *arrayFiles;

- (IBAction)saveAction:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)onClearAll:(id)sender;

@end
