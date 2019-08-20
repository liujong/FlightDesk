//
//  AircraftCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell/SWTableViewCell.h>

@interface AircraftCell : SWTableViewCell
+ (AircraftCell *)sharedCell;
@property (weak, nonatomic) IBOutlet UILabel *lblReg;
@property (weak, nonatomic) IBOutlet UILabel *lblModel;
@property (weak, nonatomic) IBOutlet UILabel *lblVariant;
@property (weak, nonatomic) IBOutlet UILabel *lblYear;
@property (weak, nonatomic) IBOutlet UILabel *lblCategory;
@property (weak, nonatomic) IBOutlet UILabel *lblClass;
@property (weak, nonatomic) IBOutlet UILabel *lblMTOW;

@end
