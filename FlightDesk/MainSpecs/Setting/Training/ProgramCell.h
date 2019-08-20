//
//  ProgramCell.h
//  FlightDesk
//
//  Created by stepanekdavid on 7/14/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface ProgramCell : UITableViewCell

+ (ProgramCell *)sharedCell;
@property (nonatomic, retain) NSString *currentProgram;


@property (weak, nonatomic) IBOutlet UILabel *lblProgramTitle;

@end
