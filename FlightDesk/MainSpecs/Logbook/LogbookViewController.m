//
//  LogbookViewController.m
//  FlightDesk
//
//  Created by Gregory Bayard on 8/7/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "AppDelegate.h"
#import "PersistentCoreDataStack.h"
#import "LogbookViewController.h"
#import "LogbookRecordViewController.h"
#import "LogEntry+CoreDataClass.h"
#import <SWTableViewCell/SWTableViewCell.h>
#import "EndorsementAllViewController.h"

#define DEFAULT_UITABLEVIEW_CELL_HEIGHT 44.0f
#define REMARKS_HEIGHT 22.0f

// extends UITableViewCell
@interface LogbookCell : SWTableViewCell

// now only showing one label, you can add more yourself
@property (nonatomic, strong) UILabel *logDate;
@property (nonatomic, strong) UILabel *aircraft;
@property (nonatomic, strong) UILabel *ident;
@property (nonatomic, strong) UILabel *route;
@property (nonatomic, strong) UILabel *duration;
@property (nonatomic, strong) UILabel *actualInstrument;
@property (nonatomic, strong) UILabel *hoodInstrument;
@property (nonatomic, strong) UILabel *simInstrument;
@property (nonatomic, strong) UILabel *dayLandings;
@property (nonatomic, strong) UILabel *nightLandings;
@property (nonatomic, strong) UILabel *groundTime;
@property (nonatomic, strong) UILabel *flightTime;
@property (nonatomic, strong) UILabel *xcTime;
@property (nonatomic, strong) UILabel *soloTime;
@property (nonatomic, strong) UILabel *remarks;
@property (nonatomic) int lastColumnX;

@end

@implementation LogbookCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    LogbookCell *cell = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (cell) {
        UIColor *logBookBGColor = [[UIColor alloc] initWithRed:190.0/255.0 green:230.0/255.0 blue:210.0/255.0 alpha:0.5];
        cell.backgroundColor = logBookBGColor;
        
        CGFloat topHalfHeight = DEFAULT_UITABLEVIEW_CELL_HEIGHT;
        CGFloat remarksHeight = REMARKS_HEIGHT;
        
        int x = 0;
        int width = 60;
        cell.logDate = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, self.bounds.size.height)];
        cell.logDate.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.logDate.textAlignment = NSTextAlignmentCenter;
        cell.logDate.numberOfLines = 0;
        cell.logDate.text = @"";
        cell.logDate.layer.borderColor = [UIColor blackColor].CGColor;
        cell.logDate.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.logDate];
        x += width;
        
        cell.aircraft = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.aircraft.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.aircraft.textAlignment = NSTextAlignmentCenter;
        cell.aircraft.numberOfLines = 0;
        cell.aircraft.text = @"";
        cell.aircraft.layer.borderColor = [UIColor blackColor].CGColor;
        cell.aircraft.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.aircraft];
        x += width;
        
        cell.ident = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.ident.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.ident.textAlignment = NSTextAlignmentCenter;
        cell.ident.numberOfLines = 0;
        cell.ident.text = @"";
        cell.ident.layer.borderColor = [UIColor blackColor].CGColor;
        cell.ident.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.ident];
        x += width;
        
        width = 100;
        cell.route = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.route.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.route.textAlignment = NSTextAlignmentCenter;
        cell.route.numberOfLines = 0;
        cell.route.text = @"";
        cell.route.layer.borderColor = [UIColor blackColor].CGColor;
        cell.route.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.route];
        x += width;
        
        width = 50;
        cell.duration = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.duration.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.duration.textAlignment = NSTextAlignmentCenter;
        cell.duration.numberOfLines = 0;
        cell.duration.text = @"";
        cell.duration.layer.borderColor = [UIColor blackColor].CGColor;
        cell.duration.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.duration];
        x += width;
        
        cell.actualInstrument = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.actualInstrument.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.actualInstrument.textAlignment = NSTextAlignmentCenter;
        cell.actualInstrument.numberOfLines = 0;
        cell.actualInstrument.text = @"";
        cell.actualInstrument.layer.borderColor = [UIColor blackColor].CGColor;
        cell.actualInstrument.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.actualInstrument];
        x += width;
        
        cell.hoodInstrument = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.hoodInstrument.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.hoodInstrument.textAlignment = NSTextAlignmentCenter;
        cell.hoodInstrument.numberOfLines = 0;
        cell.hoodInstrument.text = @"";
        cell.hoodInstrument.layer.borderColor = [UIColor blackColor].CGColor;
        cell.hoodInstrument.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.hoodInstrument];
        x += width;
        
        cell.simInstrument = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.simInstrument.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.simInstrument.textAlignment = NSTextAlignmentCenter;
        cell.simInstrument.numberOfLines = 0;
        cell.simInstrument.text = @"";
        cell.simInstrument.layer.borderColor = [UIColor blackColor].CGColor;
        cell.simInstrument.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.simInstrument];
        x += width;
        
        cell.dayLandings = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.dayLandings.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.dayLandings.textAlignment = NSTextAlignmentCenter;
        cell.dayLandings.numberOfLines = 0;
        cell.dayLandings.text = @"";
        cell.dayLandings.layer.borderColor = [UIColor blackColor].CGColor;
        cell.dayLandings.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.dayLandings];
        x += width;
        
        cell.nightLandings = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.nightLandings.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.nightLandings.textAlignment = NSTextAlignmentCenter;
        cell.nightLandings.numberOfLines = 0;
        cell.nightLandings.text = @"";
        cell.nightLandings.layer.borderColor = [UIColor blackColor].CGColor;
        cell.nightLandings.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.nightLandings];
        x += width;
        
        cell.groundTime = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.groundTime.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.groundTime.textAlignment = NSTextAlignmentCenter;
        cell.groundTime.numberOfLines = 0;
        cell.groundTime.text = @"";
        cell.groundTime.layer.borderColor = [UIColor blackColor].CGColor;
        cell.groundTime.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.groundTime];
        x += width;
        
        cell.flightTime = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.flightTime.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.flightTime.textAlignment = NSTextAlignmentCenter;
        cell.flightTime.numberOfLines = 0;
        cell.flightTime.text = @"";
        cell.flightTime.layer.borderColor = [UIColor blackColor].CGColor;
        cell.flightTime.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.flightTime];
        x += width;
        
        cell.xcTime = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.xcTime.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.xcTime.textAlignment = NSTextAlignmentCenter;
        cell.xcTime.numberOfLines = 0;
        cell.xcTime.text = @"";
        cell.xcTime.layer.borderColor = [UIColor blackColor].CGColor;
        cell.xcTime.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.xcTime];
        x += width;
        
        cell.lastColumnX = x;
        cell.soloTime = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, cell.bounds.size.height)];
        cell.soloTime.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.soloTime.textAlignment = NSTextAlignmentCenter;
        cell.soloTime.numberOfLines = 0;
        cell.soloTime.text = @"";
        cell.soloTime.layer.borderColor = [UIColor blackColor].CGColor;
        cell.soloTime.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.soloTime];
        
        cell.remarks = [[UILabel alloc] initWithFrame:CGRectMake(0, topHalfHeight - 1, x + width + 1, remarksHeight)];
        cell.remarks.font = [UIFont fontWithName:@"Helvetica" size:12];
        cell.remarks.textAlignment = NSTextAlignmentLeft;
        cell.remarks.numberOfLines = 0;
        cell.remarks.text = @" Remarks: ";
        cell.remarks.layer.borderColor = [UIColor blackColor].CGColor;
        cell.remarks.layer.borderWidth = 1.0;
        [cell.contentView addSubview:cell.remarks];

    }
    return cell;
}

@end

@interface LogbookViewController () <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate>

@end

@implementation LogbookViewController
{
    UIView *logBookColumnHeaderView;
    UIView *logBookFooterView;
    UITableView *logBookTableView;
    NSMutableArray *logBookEntries;
    
    NSManagedObjectContext *context;
    
    //footer
    UILabel *aircraftCountForFooter;
    UILabel *identCountForFooter;
    UILabel *routeCountForFooter;
    UILabel *durationSumForFooter;
    UILabel *actualInstrumentSumLabelForFooter;
    UILabel *hoodInstrumentSumLabelForFooter;
    UILabel *simInstrumentSumLabelForFooter;
    UILabel *dayLandingsSumLabelForFooter;
    UILabel *nightLandingsSumLabelForFooter;
    UILabel *groundSumLabelForFooter;
    UILabel *flightSumLabelForFooter;
    UILabel *xcSumLabelForFooter;
    UILabel *soloSumLabelForFooter;
    UILabel *picSumLabelForFooter;
    UILabel *niteSumLabelForFooter;
    
    int columnHeaderHeight;
    int halfColumnHeaderHeight;
    
    int columnFooterHeight;
    int labelFooterHeight;
    int halfColumnFooterHeight;
    
    UILabel *dateLabel;
    UILabel *aircraftLabel;
    UILabel *identLabel;
    UILabel *routeLabel;
    UILabel *durationLabel;
    UILabel *instrumentLabel;
    UILabel *actualInstrumentLabel;
    UILabel *hoodInstrumentLabel;
    UILabel *simInstrumentLabel;
    UILabel *landingsLabel;
    UILabel *dayLandingsLabel;
    UILabel *nightLandingsLabel;
    UILabel *experienceLabel;
    UILabel *groundLabel;
    UILabel *flightLabel;
    UILabel *xcLabel;
    UILabel *soloLabel;
    UILabel *totalLabel;
    UILabel *aircraftLabelForFooter;
    UILabel *identLabelForFooter;
    UILabel *routeLabelForFooter;
    UILabel *durationLabelForFooter;
    UILabel *instrumentLabelForFooter;
    UILabel *actualInstrumentLabelForFooter;
    UILabel *hoodInstrumentLabelForFooter;
    UILabel *simInstrumentLabelForFooter;
    UILabel *landingsLabelForFooter;
    UILabel *dayLandingsLabelForFooter;
    UILabel *nightLandingsLabelForFooter;
    UILabel *experienceLabelForFooter;
    UILabel *groundLabelForFooter;
    UILabel *flightLabelForFooter;
    UILabel *xcLabelForFooter;
    UILabel *soloLabelForFooter;
    UILabel *picLabelForFooter;
    UILabel *niteLabelForFooter;
    UIButton *tapTotalLog;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Logbook";
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    // add the "Add Logbook Entry" button
    
    
    context = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    
    logBookEntries = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLogbookEntry)];
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.rightBarButtonItems];
    [rightBarButtonItems addObject:addButton];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithArray:rightBarButtonItems];
    
    UIButton *endrosementBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
    [endrosementBtn addTarget:self action:@selector(selectEndorsementsToShow) forControlEvents:UIControlEventTouchUpInside];
    [endrosementBtn setTitle:@"Endorsements" forState:UIControlStateNormal];
    [endrosementBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIBarButtonItem *selectButtonItem = [[UIBarButtonItem alloc] initWithCustomView:endrosementBtn];
    
    NSMutableArray *leftBarButtonItems = [[NSMutableArray alloc] initWithArray:self.navigationItem.leftBarButtonItems];
    [leftBarButtonItems addObject:selectButtonItem];
    self.navigationItem.leftBarButtonItems = [[NSArray alloc] initWithArray:leftBarButtonItems];
    
    // display logbook header
    columnHeaderHeight = 80;
    halfColumnHeaderHeight = 40;
    
    int statusBarHeight = 0;
    if ([UIApplication sharedApplication].statusBarHidden == NO) {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    int navigationBarHeight = 0;
    if (self.navigationController.navigationBarHidden == NO) {
        navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    }
    
    UIColor *logBookBGColor = [[UIColor alloc] initWithRed:190.0/255.0 green:230.0/255.0 blue:210.0/255.0 alpha:0.5];
    
    // make a new bounds for the UIView with the column headers
    CGRect columnHeaderRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, columnHeaderHeight);
    logBookColumnHeaderView = [[UIView alloc] initWithFrame:columnHeaderRect];
    logBookColumnHeaderView.backgroundColor = logBookBGColor;
    
    // make logbook header
    int x = 0;
    int width = 60;
    dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    dateLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    dateLabel.textAlignment = NSTextAlignmentCenter;
    dateLabel.numberOfLines = 0;
    dateLabel.text = @"DATE";
    dateLabel.layer.borderColor = [UIColor blackColor].CGColor;
    dateLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:dateLabel];
    x += width;
    
    aircraftLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    aircraftLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    aircraftLabel.textAlignment = NSTextAlignmentCenter;
    aircraftLabel.numberOfLines = 0;
    aircraftLabel.text = @"AIRCRAFT";
    aircraftLabel.layer.borderColor = [UIColor blackColor].CGColor;
    aircraftLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:aircraftLabel];
    x += width;
    
    identLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    identLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:9];
    identLabel.textAlignment = NSTextAlignmentCenter;
    identLabel.numberOfLines = 0;
    identLabel.text = @"Registration";
    identLabel.layer.borderColor = [UIColor blackColor].CGColor;
    identLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:identLabel];
    x += width;
    
    width = 100;
    routeLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    routeLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    routeLabel.textAlignment = NSTextAlignmentCenter;
    routeLabel.numberOfLines = 0;
    routeLabel.text = @"ROUTE";
    routeLabel.layer.borderColor = [UIColor blackColor].CGColor;
    routeLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:routeLabel];
    x += width;
    
    width = 50;
    durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    durationLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    durationLabel.textAlignment = NSTextAlignmentCenter;
    durationLabel.numberOfLines = 0;
    durationLabel.text = @"DUR";
    durationLabel.layer.borderColor = [UIColor blackColor].CGColor;
    durationLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:durationLabel];
    x += width;
    
    width = 150;
    instrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    instrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    instrumentLabel.textAlignment = NSTextAlignmentCenter;
    instrumentLabel.numberOfLines = 0;
    instrumentLabel.text = @"INSTRUMENT";
    instrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
    instrumentLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:instrumentLabel];
    
    width = 50;
    actualInstrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    actualInstrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    actualInstrumentLabel.textAlignment = NSTextAlignmentCenter;
    actualInstrumentLabel.numberOfLines = 0;
    actualInstrumentLabel.text = @"ACTUAL";
    actualInstrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
    actualInstrumentLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:actualInstrumentLabel];
    x += width;
    
    hoodInstrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    hoodInstrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    hoodInstrumentLabel.textAlignment = NSTextAlignmentCenter;
    hoodInstrumentLabel.numberOfLines = 0;
    hoodInstrumentLabel.text = @"HOOD";
    hoodInstrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
    hoodInstrumentLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:hoodInstrumentLabel];
    x += width;
    
    simInstrumentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    simInstrumentLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    simInstrumentLabel.textAlignment = NSTextAlignmentCenter;
    simInstrumentLabel.numberOfLines = 0;
    simInstrumentLabel.text = @"SIM";
    simInstrumentLabel.layer.borderColor = [UIColor blackColor].CGColor;
    simInstrumentLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:simInstrumentLabel];
    x += width;
    
    width = 100;
    landingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    landingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    landingsLabel.textAlignment = NSTextAlignmentCenter;
    landingsLabel.numberOfLines = 0;
    landingsLabel.text = @"LANDINGS";
    landingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
    landingsLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:landingsLabel];
    
    width = 50;
    dayLandingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    dayLandingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    dayLandingsLabel.textAlignment = NSTextAlignmentCenter;
    dayLandingsLabel.numberOfLines = 0;
    dayLandingsLabel.text = @"DAY";
    dayLandingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
    dayLandingsLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:dayLandingsLabel];
    x += width;
    
    nightLandingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    nightLandingsLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    nightLandingsLabel.textAlignment = NSTextAlignmentCenter;
    nightLandingsLabel.numberOfLines = 0;
    nightLandingsLabel.text = @"NIGHT";
    nightLandingsLabel.layer.borderColor = [UIColor blackColor].CGColor;
    nightLandingsLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:nightLandingsLabel];
    x += width;
    
    width = self.view.bounds.size.width - x - 1;
    experienceLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    experienceLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    experienceLabel.textAlignment = NSTextAlignmentCenter;
    experienceLabel.numberOfLines = 0;
    experienceLabel.text = @"EXPERIENCE";
    experienceLabel.layer.borderColor = [UIColor blackColor].CGColor;
    experienceLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:experienceLabel];
    
    width = 50;
    groundLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    groundLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    groundLabel.textAlignment = NSTextAlignmentCenter;
    groundLabel.numberOfLines = 0;
    groundLabel.text = @"GNDTRN";
    groundLabel.layer.borderColor = [UIColor blackColor].CGColor;
    groundLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:groundLabel];
    x += width;
    
    flightLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    flightLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    flightLabel.textAlignment = NSTextAlignmentCenter;
    flightLabel.numberOfLines = 0;
    flightLabel.text = @"FLTTRN";
    flightLabel.layer.borderColor = [UIColor blackColor].CGColor;
    flightLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:flightLabel];
    x += width;
    
    xcLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    xcLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    xcLabel.textAlignment = NSTextAlignmentCenter;
    xcLabel.numberOfLines = 0;
    xcLabel.text = @"X-C";
    xcLabel.layer.borderColor = [UIColor blackColor].CGColor;
    xcLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:xcLabel];
    x += width;
    
    width = self.view.bounds.size.width - x - 1;
    soloLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    soloLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    soloLabel.textAlignment = NSTextAlignmentCenter;
    soloLabel.numberOfLines = 0;
    soloLabel.text = @"SOLO";
    soloLabel.layer.borderColor = [UIColor blackColor].CGColor;
    soloLabel.layer.borderWidth = 1.0;
    [logBookColumnHeaderView addSubview:soloLabel];
    x += width;
    
    // add logbook header view
    [self.view addSubview:logBookColumnHeaderView];
    
    columnFooterHeight = 130;
    labelFooterHeight = 80;
    halfColumnFooterHeight = 40;
    // make a new bounds for the UIView with the column headers
    CGRect columnFooterRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height - columnFooterHeight-114, self.view.bounds.size.width, columnFooterHeight);
    logBookFooterView = [[UIView alloc] initWithFrame:columnFooterRect];
    logBookFooterView.backgroundColor = logBookBGColor;
    UIColor *totalLogBGColor = [[UIColor alloc] initWithRed:190.0/255.0 green:230.0/255.0 blue:210.0/255.0 alpha:0.5];
    // make logbook Footer
    int xOfFooter = 0;
    int widthOfFooter = 70;
    totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, columnFooterHeight + 1)];
    totalLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    totalLabel.textAlignment = NSTextAlignmentCenter;
    totalLabel.numberOfLines = 0;
    totalLabel.text = @"TOTALS";
    totalLabel.layer.borderColor = [UIColor blackColor].CGColor;
    totalLabel.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:totalLabel];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 60;
    aircraftLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    aircraftLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    aircraftLabelForFooter.textAlignment = NSTextAlignmentCenter;
    aircraftLabelForFooter.numberOfLines = 0;
    aircraftLabelForFooter.text = @"AIRCRAFT";
    aircraftLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    aircraftLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:aircraftLabelForFooter];
    
    aircraftCountForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    aircraftCountForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    aircraftCountForFooter.textAlignment = NSTextAlignmentCenter;
    aircraftCountForFooter.numberOfLines = 0;
    aircraftCountForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    aircraftCountForFooter.layer.borderWidth = 1.0;
    aircraftCountForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:aircraftCountForFooter];
    xOfFooter += widthOfFooter;
    
    identLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    identLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:9];
    identLabelForFooter.textAlignment = NSTextAlignmentCenter;
    identLabelForFooter.numberOfLines = 0;
    identLabelForFooter.text = @"Registration";
    identLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    identLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:identLabelForFooter];
    
    identCountForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    identCountForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    identCountForFooter.textAlignment = NSTextAlignmentCenter;
    identCountForFooter.numberOfLines = 0;
    identCountForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    identCountForFooter.layer.borderWidth = 1.0;
    identCountForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:identCountForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 60;
    routeLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    routeLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    routeLabelForFooter.textAlignment = NSTextAlignmentCenter;
    routeLabelForFooter.numberOfLines = 0;
    routeLabelForFooter.text = @"ROUTE";
    routeLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    routeLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:routeLabelForFooter];
    
    routeCountForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    routeCountForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    routeCountForFooter.textAlignment = NSTextAlignmentCenter;
    routeCountForFooter.numberOfLines = 0;
    routeCountForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    routeCountForFooter.layer.borderWidth = 1.0;
    routeCountForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:routeCountForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 50;
    durationLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    durationLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    durationLabelForFooter.textAlignment = NSTextAlignmentCenter;
    durationLabelForFooter.numberOfLines = 0;
    durationLabelForFooter.text = @"DUR";
    durationLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    durationLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:durationLabelForFooter];
    
    durationSumForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    durationSumForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    durationSumForFooter.textAlignment = NSTextAlignmentCenter;
    durationSumForFooter.numberOfLines = 0;
    durationSumForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    durationSumForFooter.layer.borderWidth = 1.0;
    durationSumForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:durationSumForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 135;
    instrumentLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    instrumentLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    instrumentLabelForFooter.textAlignment = NSTextAlignmentCenter;
    instrumentLabelForFooter.numberOfLines = 0;
    instrumentLabelForFooter.text = @"INSTRUMENT";
    instrumentLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    instrumentLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:instrumentLabelForFooter];
    
    widthOfFooter = 45;
    actualInstrumentLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    actualInstrumentLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    actualInstrumentLabelForFooter.textAlignment = NSTextAlignmentCenter;
    actualInstrumentLabelForFooter.numberOfLines = 0;
    actualInstrumentLabelForFooter.text = @"ACTUAL";
    actualInstrumentLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    actualInstrumentLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:actualInstrumentLabelForFooter];
    
    actualInstrumentSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    actualInstrumentSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    actualInstrumentSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    actualInstrumentSumLabelForFooter.numberOfLines = 0;
    actualInstrumentSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    actualInstrumentSumLabelForFooter.layer.borderWidth = 1.0;
    actualInstrumentSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:actualInstrumentSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    hoodInstrumentLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    hoodInstrumentLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    hoodInstrumentLabelForFooter.textAlignment = NSTextAlignmentCenter;
    hoodInstrumentLabelForFooter.numberOfLines = 0;
    hoodInstrumentLabelForFooter.text = @"HOOD";
    hoodInstrumentLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    hoodInstrumentLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:hoodInstrumentLabelForFooter];
    
    hoodInstrumentSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    hoodInstrumentSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    hoodInstrumentSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    hoodInstrumentSumLabelForFooter.numberOfLines = 0;
    hoodInstrumentSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    hoodInstrumentSumLabelForFooter.layer.borderWidth = 1.0;
    hoodInstrumentSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:hoodInstrumentSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    simInstrumentLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    simInstrumentLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    simInstrumentLabelForFooter.textAlignment = NSTextAlignmentCenter;
    simInstrumentLabelForFooter.numberOfLines = 0;
    simInstrumentLabelForFooter.text = @"SIM";
    simInstrumentLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    simInstrumentLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:simInstrumentLabelForFooter];
    
    simInstrumentSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    simInstrumentSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    simInstrumentSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    simInstrumentSumLabelForFooter.numberOfLines = 0;
    simInstrumentSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    simInstrumentSumLabelForFooter.layer.borderWidth = 1.0;
    simInstrumentSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:simInstrumentSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 80;
    landingsLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    landingsLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    landingsLabelForFooter.textAlignment = NSTextAlignmentCenter;
    landingsLabelForFooter.numberOfLines = 0;
    landingsLabelForFooter.text = @"LANDINGS";
    landingsLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    landingsLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:landingsLabelForFooter];
    
    widthOfFooter = 40;
    dayLandingsLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    dayLandingsLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    dayLandingsLabelForFooter.textAlignment = NSTextAlignmentCenter;
    dayLandingsLabelForFooter.numberOfLines = 0;
    dayLandingsLabelForFooter.text = @"DAY";
    dayLandingsLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    dayLandingsLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:dayLandingsLabelForFooter];
    
    dayLandingsSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    dayLandingsSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    dayLandingsSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    dayLandingsSumLabelForFooter.numberOfLines = 0;
    dayLandingsSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    dayLandingsSumLabelForFooter.layer.borderWidth = 1.0;
    dayLandingsSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:dayLandingsSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    nightLandingsLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    nightLandingsLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    nightLandingsLabelForFooter.textAlignment = NSTextAlignmentCenter;
    nightLandingsLabelForFooter.numberOfLines = 0;
    nightLandingsLabelForFooter.text = @"NIGHT";
    nightLandingsLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    nightLandingsLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:nightLandingsLabelForFooter];
    
    nightLandingsSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    nightLandingsSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    nightLandingsSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    nightLandingsSumLabelForFooter.numberOfLines = 0;
    nightLandingsSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    nightLandingsSumLabelForFooter.layer.borderWidth = 1.0;
    nightLandingsSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:nightLandingsSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = self.view.bounds.size.width - xOfFooter - 1;
    experienceLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    experienceLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    experienceLabelForFooter.textAlignment = NSTextAlignmentCenter;
    experienceLabelForFooter.numberOfLines = 0;
    experienceLabelForFooter.text = @"EXPERIENCE";
    experienceLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    experienceLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:experienceLabelForFooter];

    widthOfFooter = 45;
    groundLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    groundLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    groundLabelForFooter.textAlignment = NSTextAlignmentCenter;
    groundLabelForFooter.numberOfLines = 0;
    groundLabelForFooter.text = @"GNDTRN";
    groundLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    groundLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:groundLabelForFooter];
    
    groundSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    groundSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    groundSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    groundSumLabelForFooter.numberOfLines = 0;
    groundSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    groundSumLabelForFooter.layer.borderWidth = 1.0;
    groundSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:groundSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    flightLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    flightLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    flightLabelForFooter.textAlignment = NSTextAlignmentCenter;
    flightLabelForFooter.numberOfLines = 0;
    flightLabelForFooter.text = @"FLTTRN";
    flightLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    flightLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:flightLabelForFooter];
    
    flightSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    flightSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    flightSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    flightSumLabelForFooter.numberOfLines = 0;
    flightSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    flightSumLabelForFooter.layer.borderWidth = 1.0;
    flightSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:flightSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    xcLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    xcLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    xcLabelForFooter.textAlignment = NSTextAlignmentCenter;
    xcLabelForFooter.numberOfLines = 0;
    xcLabelForFooter.text = @"X-C";
    xcLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    xcLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:xcLabelForFooter];
    
    xcSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xcSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    xcSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    xcSumLabelForFooter.numberOfLines = 0;
    xcSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    xcSumLabelForFooter.layer.borderWidth = 1.0;
    xcSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:xcSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    soloLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    soloLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    soloLabelForFooter.textAlignment = NSTextAlignmentCenter;
    soloLabelForFooter.numberOfLines = 0;
    soloLabelForFooter.text = @"SOLO";
    soloLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    soloLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:soloLabelForFooter];
    
    soloSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    soloSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    soloSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    soloSumLabelForFooter.numberOfLines = 0;
    soloSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    soloSumLabelForFooter.layer.borderWidth = 1.0;
    soloSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:soloSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 40;
    picLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    picLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    picLabelForFooter.textAlignment = NSTextAlignmentCenter;
    picLabelForFooter.numberOfLines = 0;
    picLabelForFooter.text = @"PIC";
    picLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    picLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:picLabelForFooter];
    
    picSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    picSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    picSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    picSumLabelForFooter.numberOfLines = 0;
    picSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    picSumLabelForFooter.layer.borderWidth = 1.0;
    picSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:picSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = self.view.bounds.size.width - xOfFooter - 1;
    niteLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    niteLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:10];
    niteLabelForFooter.textAlignment = NSTextAlignmentCenter;
    niteLabelForFooter.numberOfLines = 0;
    niteLabelForFooter.text = @"NITE";
    niteLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    niteLabelForFooter.layer.borderWidth = 1.0;
    [logBookFooterView addSubview:niteLabelForFooter];
    
    niteSumLabelForFooter = [[UILabel alloc] initWithFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    niteSumLabelForFooter.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    niteSumLabelForFooter.textAlignment = NSTextAlignmentCenter;
    niteSumLabelForFooter.numberOfLines = 0;
    niteSumLabelForFooter.layer.borderColor = [UIColor blackColor].CGColor;
    niteSumLabelForFooter.layer.borderWidth = 1.0;
    niteSumLabelForFooter.backgroundColor = totalLogBGColor;
    [logBookFooterView addSubview:niteSumLabelForFooter];
    xOfFooter += widthOfFooter;
    
    CGRect columnFooterRectOfButton = CGRectMake(0, 0, self.view.bounds.size.width, columnFooterHeight);
    tapTotalLog = [[UIButton alloc] initWithFrame:columnFooterRectOfButton];
    [tapTotalLog addTarget:self action:@selector(onTapTatalSection) forControlEvents:UIControlEventTouchUpInside];
    [tapTotalLog setBackgroundColor:[UIColor clearColor]];
    [logBookFooterView addSubview:tapTotalLog];
    
    
    // add logbook footer view
    [self.view addSubview:logBookFooterView];
    
    // make a new bounds for the UITableView which leaves room for the column headers
    CGRect tableViewRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y  + columnHeaderHeight, self.view.bounds.size.width, self.view.bounds.size.height - columnHeaderHeight - columnFooterHeight-114);
    logBookTableView = [[UITableView alloc] initWithFrame:tableViewRect style:UITableViewStylePlain];
    logBookTableView.delegate = self;
    logBookTableView.dataSource = self;
    logBookTableView.backgroundColor = logBookBGColor;
    [self.view addSubview:logBookTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"view will appear!");
    [self setNavigationColorWithGradiant];
    [self populateLogBooks];
    [[AppDelegate sharedDelegate] startThreadToSyncData:2];
    
    id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"LogBookviewController"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[AppDelegate sharedDelegate] stopThreadToSyncData:2];
}
- (BOOL)populateLogBooks{
    
    BOOL requireRepopulate = NO;
    // grab logbook entries
    NSManagedObjectContext *contextLog = [AppDelegate sharedDelegate].persistentCoreDataStack.managedObjectContext;
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:contextLog];
    NSError *error;
    // load the remaining lesson groups
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSArray *objects = [contextLog executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"Unable to retrieve lessons!");
        [logBookEntries removeAllObjects];
    } else if (objects.count == 0) {
        NSLog(@"No valid lesson groups found!");
        [logBookEntries removeAllObjects];
    } else {
        [logBookEntries removeAllObjects];
        NSLog(@"%lu lesson groups found", (unsigned long)[objects count]);
        NSMutableArray *tempLogbookEntries = [NSMutableArray arrayWithArray:objects];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"logDate" ascending:NO];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sortedLogbookEntries = [tempLogbookEntries sortedArrayUsingDescriptors:sortDescriptors];
        for (LogEntry *logentry in sortedLogbookEntries) {
            [logBookEntries addObject:logentry];
        }
        requireRepopulate = YES;
    }
    
    [logBookTableView reloadData];
    [self reCalculatorTotalOfLogs];
    return requireRepopulate;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)reCalculatorTotalOfLogs{
    
    NSInteger countOfAircraft = 0;
    NSInteger countOfIdent = 0;
    NSInteger countOfRoute = 0;
    NSDecimalNumber *sumDuration = [NSDecimalNumber zero];
    NSDecimalNumber *sumActualIns = [NSDecimalNumber zero];
    NSDecimalNumber *sumHoodIns = [NSDecimalNumber zero];
    NSDecimalNumber *sumSimIns = [NSDecimalNumber zero];
    NSInteger sumDayLanding = 0;
    NSInteger sumNightLanding = 0;
    NSDecimalNumber *sumGround = [NSDecimalNumber zero];
    NSDecimalNumber *sumFlight = [NSDecimalNumber zero];
    NSDecimalNumber *sumXc = [NSDecimalNumber zero];
    NSDecimalNumber *sumSolo = [NSDecimalNumber zero];
    NSDecimalNumber *sumPic = [NSDecimalNumber zero];
    NSDecimalNumber *sumNite = [NSDecimalNumber zero];
    
    
    NSMutableArray *arrAirCraftModel = [[NSMutableArray alloc] init];
    NSMutableArray *arraircraftRegistration = [[NSMutableArray alloc] init];
    NSMutableArray *arrFlightRoute = [[NSMutableArray alloc] init];
    
    for (LogEntry *logEntry in logBookEntries) {
        if (logEntry.aircraftModel != nil){
            NSString *aircraftModelToRemovedWhiteSpace = [logEntry.aircraftModel stringByReplacingOccurrencesOfString:@" " withString:@""];
            if(![aircraftModelToRemovedWhiteSpace isEqualToString:@""] && ![arrAirCraftModel containsObject:aircraftModelToRemovedWhiteSpace]) {
                [arrAirCraftModel addObject:aircraftModelToRemovedWhiteSpace];
                countOfAircraft = countOfAircraft + 1;
            }
        }
        if (logEntry.aircraftRegistration != nil){
            NSString *aircraftRecToRemovedWhiteSpace = [logEntry.aircraftRegistration stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (![aircraftRecToRemovedWhiteSpace isEqualToString:@""] && ![arraircraftRegistration containsObject:aircraftRecToRemovedWhiteSpace]) {
                [arraircraftRegistration addObject:aircraftRecToRemovedWhiteSpace];
                countOfIdent = countOfIdent + 1;
            }
        }
        if (logEntry.flightRoute != nil && ![logEntry.flightRoute isEqualToString:@""] && ![arrFlightRoute containsObject:logEntry.flightRoute]) {
            [arrFlightRoute addObject:logEntry.flightRoute];
            countOfRoute = countOfRoute + 1;
        }
        // flight duration
        if ([[NSDecimalNumber notANumber] isEqualToValue:logEntry.totalFlightTime] == NO) {
             sumDuration = [sumDuration decimalNumberByAdding:logEntry.totalFlightTime];
        }
        // actual instrument time
        if (logEntry.instrumentActual != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentActual] == NO) {
            sumActualIns = [sumActualIns decimalNumberByAdding:logEntry.instrumentActual];
        }
        // hood instrument time
        if (logEntry.instrumentHood != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentHood] == NO) {
            sumHoodIns = [sumHoodIns decimalNumberByAdding:logEntry.instrumentHood];
        }
        // sim instrument time
        if (logEntry.instrumentSim != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentSim] == NO) {
            sumSimIns = [sumSimIns decimalNumberByAdding:logEntry.instrumentSim];
        }
        // day landings
        if (logEntry.landingsDay != nil) {
            sumDayLanding = sumDayLanding + [logEntry.landingsDay integerValue];
        }
        // night landings
        if (logEntry.landingsNight != nil) {
            sumNightLanding = sumNightLanding + [logEntry.landingsNight integerValue];
        }
        // ground time
        if (logEntry.groundTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.groundTime] == NO) {
            sumGround = [sumGround decimalNumberByAdding:logEntry.groundTime];
        }
        // flight time
        if (logEntry.totalFlightTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.totalFlightTime] == NO) {
            sumFlight = [sumFlight decimalNumberByAdding:logEntry.totalFlightTime];
        }
        // X-C time
        if (logEntry.xcDualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcDualReceived] == NO) {
            sumXc = [sumXc decimalNumberByAdding:logEntry.xcDualReceived];
        }
        // solo time
        if (logEntry.soloTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.soloTime] == NO) {
            sumSolo = [sumSolo decimalNumberByAdding:logEntry.soloTime];
        }
        //pic time
        if (logEntry.picTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.picTime] == NO) {
            sumPic = [sumPic decimalNumberByAdding:logEntry.picTime];
        }
        //nite time
        if (logEntry.nightTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.nightTime] == NO) {
            sumNite = [sumNite decimalNumberByAdding:logEntry.nightTime];
        }
    }
    aircraftCountForFooter.text = [NSString stringWithFormat:@"%ld", (long)countOfAircraft];
    identCountForFooter.text = [NSString stringWithFormat:@"%ld", (long)countOfIdent];
    routeCountForFooter.text = [NSString stringWithFormat:@"%ld", (long)countOfRoute];
    durationSumForFooter.text = [sumDuration stringValue];
    actualInstrumentSumLabelForFooter.text = [sumActualIns stringValue];
    hoodInstrumentSumLabelForFooter.text = [sumHoodIns stringValue];
    simInstrumentSumLabelForFooter.text = [sumSimIns stringValue];
    dayLandingsSumLabelForFooter.text = [NSString stringWithFormat:@"%ld", (long)sumDayLanding];
    nightLandingsSumLabelForFooter.text = [NSString stringWithFormat:@"%ld", (long)sumNightLanding];
    groundSumLabelForFooter.text = [sumGround stringValue];
    flightSumLabelForFooter.text = [sumFlight stringValue];
    xcSumLabelForFooter.text = [sumXc stringValue];
    soloSumLabelForFooter.text = [sumSolo stringValue];
    picSumLabelForFooter.text = [sumPic stringValue];
    niteSumLabelForFooter.text = [sumNite stringValue];
}
- (void)onTapTatalSection{
    NSInteger countaircraftCategory = 0;
    NSInteger countaircraftClass = 0;
    NSInteger countaircraftModel = 0;
    NSInteger countaircraftRegistration = 0;
    NSNumber *sumapproachesCount = [NSNumber numberWithInteger:0];
    NSInteger countapproachesType = 0;
    NSDecimalNumber *sumcomplex = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGiven = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenCFI = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenCommercial = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenGlider = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenInstrument = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenOther = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenRecreational = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualGivenSport = [NSDecimalNumber zero];
    NSDecimalNumber *sumdualReceived = [NSDecimalNumber zero];
    NSInteger countflightRoute = 0;
    NSDecimalNumber *sumglider = [NSDecimalNumber zero];
    NSDecimalNumber *sumgroundTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumhelicopter = [NSDecimalNumber zero];
    NSDecimalNumber *sumhighPerf = [NSDecimalNumber zero];
    NSDecimalNumber *sumhobbsIn = [NSDecimalNumber zero];
    NSDecimalNumber *sumhobbsOut = [NSDecimalNumber zero];
    NSNumber *sumholds = [NSNumber numberWithInteger:0];
    NSDecimalNumber *suminstrumentActual = [NSDecimalNumber zero];
    NSDecimalNumber *suminstrumentHood = [NSDecimalNumber zero];
    NSDecimalNumber *suminstrumentSim = [NSDecimalNumber zero];
    NSDecimalNumber *sumjet = [NSDecimalNumber zero];
    NSNumber *sumlandingsDay = [NSNumber numberWithInteger:0];
    NSNumber *sumlandingsNight = [NSNumber numberWithInteger:0];
    NSDecimalNumber *sumnightDualReceived = [NSDecimalNumber zero];
    NSDecimalNumber *sumnightTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumpicTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumrecreational = [NSDecimalNumber zero];
    NSDecimalNumber *sumsicTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumsoloTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumsport = [NSDecimalNumber zero];
    NSDecimalNumber *sumtaildragger =[NSDecimalNumber zero];
    NSDecimalNumber *sumtotalFlightTime = [NSDecimalNumber zero];
    NSInteger counttracking = 0;
    NSDecimalNumber *sumturboprop = [NSDecimalNumber zero];
    NSDecimalNumber *sumultraLight = [NSDecimalNumber zero];
    NSDecimalNumber *sumxc = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcDualGiven = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcDualReceived = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcNightDualReceived = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcNightTime = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcPIC = [NSDecimalNumber zero];
    NSDecimalNumber *sumxcSolo = [NSDecimalNumber zero];
    
    NSMutableArray *arraircraftCategory = [[NSMutableArray alloc] init];
    NSMutableArray *arraircraftClass = [[NSMutableArray alloc] init];
    NSMutableArray *arrAirCraftModel = [[NSMutableArray alloc] init];
    NSMutableArray *arraircraftRegistration = [[NSMutableArray alloc] init];
    NSMutableArray *arrflightRoute = [[NSMutableArray alloc] init];
    NSMutableArray *arrapproachesType = [[NSMutableArray alloc] init];
    
    for (LogEntry *logEntry in logBookEntries) {
        if (logEntry.aircraftCategory != nil && ![logEntry.aircraftCategory isEqualToString:@""] && ![arraircraftCategory containsObject:logEntry.aircraftCategory]) {
            [arraircraftCategory addObject:logEntry.aircraftCategory];
            countaircraftCategory = countaircraftCategory + 1;
        }
        if (logEntry.aircraftClass != nil && ![logEntry.aircraftClass isEqualToString:@""] && ![arraircraftClass containsObject:logEntry.aircraftClass]) {
            [arraircraftClass addObject:logEntry.aircraftClass];
            countaircraftClass = countaircraftClass + 1;
        }
        if (logEntry.aircraftModel != nil){
            NSString *aircraftModelToRemovedWhiteSpace = [logEntry.aircraftModel stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (![aircraftModelToRemovedWhiteSpace isEqualToString:@""] && ![arrAirCraftModel containsObject:aircraftModelToRemovedWhiteSpace]) {
                [arrAirCraftModel addObject:aircraftModelToRemovedWhiteSpace];
                countaircraftModel = countaircraftModel + 1;
            }
        }
        if (logEntry.aircraftRegistration != nil){
            NSString *aircraftRecToRemovedWhiteSpace = [logEntry.aircraftRegistration stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (![aircraftRecToRemovedWhiteSpace isEqualToString:@""] && ![arraircraftRegistration containsObject:aircraftRecToRemovedWhiteSpace]) {
                [arraircraftRegistration addObject:aircraftRecToRemovedWhiteSpace];
                countaircraftRegistration = countaircraftRegistration + 1;
            }
        }
        if (logEntry.approachesCount != nil) {
            sumapproachesCount = [NSNumber numberWithInteger:([sumapproachesCount integerValue] + [logEntry.approachesCount integerValue])];
        }
        if (logEntry.approachesType != nil && ![logEntry.approachesType isEqualToString:@""] && ![arrapproachesType containsObject:logEntry.approachesType]) {
            [arrapproachesType addObject:logEntry.approachesType];
            countapproachesType = countapproachesType + 1;
        }
        if (logEntry.complex && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.complex] == NO) {
            sumcomplex = [sumcomplex decimalNumberByAdding:logEntry.complex];
        }
        if (logEntry.dualGiven && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGiven] == NO) {
            sumdualGiven = [sumdualGiven decimalNumberByAdding:logEntry.dualGiven];
        }
        if (logEntry.dualGivenCFI && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenCFI] == NO) {
            sumdualGivenCFI = [sumdualGivenCFI decimalNumberByAdding:logEntry.dualGivenCFI];
        }
        if (logEntry.dualGivenCommercial && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenCommercial] == NO) {
            sumdualGivenCommercial = [sumdualGivenCommercial decimalNumberByAdding:logEntry.dualGivenCommercial];
        }
        if (logEntry.dualGivenGlider && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenGlider] == NO) {
            sumdualGivenGlider = [sumdualGivenGlider decimalNumberByAdding:logEntry.dualGivenGlider];
        }
        if (logEntry.dualGivenInstrument && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenInstrument] == NO) {
            sumdualGivenInstrument = [sumdualGivenInstrument decimalNumberByAdding:logEntry.dualGivenInstrument];
        }
        if (logEntry.dualGivenOther && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenOther] == NO) {
            sumdualGivenOther = [sumdualGivenOther decimalNumberByAdding:logEntry.dualGivenOther];
        }
        if (logEntry.dualGivenRecreational && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenRecreational] == NO) {
            sumdualGivenRecreational = [sumdualGivenRecreational decimalNumberByAdding:logEntry.dualGivenRecreational];
        }
        if (logEntry.dualGivenSport && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualGivenSport] == NO) {
            sumdualGivenSport = [sumdualGivenSport decimalNumberByAdding:logEntry.dualGivenSport];
        }
        if (logEntry.dualReceived && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.dualReceived] == NO) {
            sumdualReceived = [sumdualReceived decimalNumberByAdding:logEntry.dualReceived];
        }
        if (logEntry.flightRoute != nil && ![logEntry.flightRoute isEqualToString:@""] && ![arrflightRoute containsObject:logEntry.flightRoute]) {
            [arrflightRoute addObject:logEntry.flightRoute];
            countflightRoute = countflightRoute + 1;
        }
        if (logEntry.glider != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.glider] == NO) {
            sumglider =  [sumglider decimalNumberByAdding:logEntry.glider];
        }
        if (logEntry.groundTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.groundTime] == NO) {
            sumgroundTime = [sumgroundTime decimalNumberByAdding:logEntry.groundTime];
        }
        if (logEntry.helicopter != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.helicopter] == NO) {
            sumhelicopter = [sumhelicopter decimalNumberByAdding:logEntry.helicopter];
        }
        if (logEntry.highPerf != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.highPerf] == NO) {
            sumhighPerf = [sumhighPerf decimalNumberByAdding:logEntry.highPerf];
        }
        if (logEntry.hobbsIn && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.hobbsIn] == NO) {
            sumhobbsIn = [sumhobbsIn decimalNumberByAdding:logEntry.hobbsIn];
        }
        if (logEntry.hobbsOut && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.hobbsOut] == NO) {
            sumhobbsOut = [sumhobbsOut decimalNumberByAdding:logEntry.hobbsOut];
        }
        if (logEntry.holds != nil) {
            sumholds = [NSNumber numberWithInteger:([sumholds integerValue] + [logEntry.holds integerValue])];
        }
        if (logEntry.instrumentActual && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentActual] == NO) {
            suminstrumentActual = [suminstrumentActual decimalNumberByAdding:logEntry.instrumentActual];
        }
        if (logEntry.instrumentHood && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentHood] == NO) {
            suminstrumentHood = [suminstrumentHood decimalNumberByAdding:logEntry.instrumentHood];
        }
        if (logEntry.instrumentSim && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.instrumentSim] == NO) {
            suminstrumentSim = [suminstrumentSim decimalNumberByAdding:logEntry.instrumentSim];
        }
        if (logEntry.jet != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.jet] == NO) {
            sumjet = [sumjet decimalNumberByAdding:logEntry.jet];
        }
        if (logEntry.landingsDay != nil) {
            sumlandingsDay = [NSNumber numberWithInteger:([sumlandingsDay integerValue] + [logEntry.landingsDay integerValue])];
        }
        if (logEntry.landingsNight != nil) {
            sumlandingsNight = [NSNumber numberWithInteger:([sumlandingsNight integerValue] + [logEntry.landingsNight integerValue])];
        }
        if (logEntry.nightDualReceived && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.nightDualReceived] == NO) {
            sumnightDualReceived = [sumnightDualReceived decimalNumberByAdding:logEntry.nightDualReceived];
        }
        if (logEntry.nightTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.nightTime] == NO) {
            sumnightTime = [sumnightTime decimalNumberByAdding:logEntry.nightTime];
        }
        if (logEntry.picTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.picTime] == NO) {
            sumpicTime = [sumpicTime decimalNumberByAdding:logEntry.picTime];
        }
        if (logEntry.recreational != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.recreational] == NO) {
            sumrecreational = [sumrecreational decimalNumberByAdding:logEntry.recreational];
        }
        if (logEntry.sicTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.sicTime] == NO) {
            sumsicTime = [sumsicTime decimalNumberByAdding:logEntry.sicTime];
        }
        if (logEntry.soloTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.soloTime] == NO) {
            sumsoloTime = [sumsoloTime decimalNumberByAdding:logEntry.soloTime];
        }
        if (logEntry.sport != nil&& [[NSDecimalNumber notANumber] isEqualToValue:logEntry.sport] == NO) {
            sumsport = [sumsport decimalNumberByAdding:logEntry.sport];
        }
        if (logEntry.taildragger != nil&& [[NSDecimalNumber notANumber] isEqualToValue:logEntry.sport] == NO) {
            sumtaildragger = [sumtaildragger decimalNumberByAdding:logEntry.taildragger];
        }
        if (logEntry.totalFlightTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.totalFlightTime] == NO) {
            sumtotalFlightTime = [sumtotalFlightTime decimalNumberByAdding:logEntry.totalFlightTime];
        }
        if (logEntry.tracking != nil && ![logEntry.tracking isEqualToString:@""]) {
            counttracking = counttracking + 1;
        }
        if (logEntry.turboprop != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.turboprop] == NO) {
            sumturboprop = [sumturboprop decimalNumberByAdding:logEntry.turboprop];
        }
        if (logEntry.ultraLight != nil && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.ultraLight] == NO) {
            sumultraLight = [sumultraLight decimalNumberByAdding:logEntry.ultraLight];
        }
        if (logEntry.xc && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xc] == NO) {
            sumxc = [sumxc decimalNumberByAdding:logEntry.xc];
        }
        if (logEntry.xcDualGiven && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcDualGiven] == NO) {
            sumxcDualGiven = [sumxcDualGiven decimalNumberByAdding:logEntry.xcDualGiven];
        }
        if (logEntry.xcDualReceived && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcDualReceived] == NO) {
            sumxcDualReceived = [sumxcDualReceived decimalNumberByAdding:logEntry.xcDualReceived];
        }
        if (logEntry.totalFlightTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.totalFlightTime] == NO) {
            sumxcNightDualReceived = [sumxcNightDualReceived decimalNumberByAdding:logEntry.totalFlightTime];
        }
        if (logEntry.xcNightTime && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcNightTime] == NO) {
            sumxcNightTime = [sumxcNightTime decimalNumberByAdding:logEntry.xcNightTime];
        }
        if (logEntry.xcPIC && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcPIC] == NO) {
            sumxcPIC = [sumxcPIC decimalNumberByAdding:logEntry.xcPIC];
        }
        if (logEntry.xcSolo && [[NSDecimalNumber notANumber] isEqualToValue:logEntry.xcSolo] == NO) {
            sumxcSolo = [sumxcSolo decimalNumberByAdding:logEntry.xcSolo];
        }
    }
    
    LogEntry *entry = [NSEntityDescription insertNewObjectForEntityForName:@"LogEntry" inManagedObjectContext:context];
    
    entry.aircraftCategory = [NSString stringWithFormat:@"%ld", (long)countaircraftCategory];
    entry.aircraftClass = [NSString stringWithFormat:@"%ld", (long)countaircraftModel];
    entry.aircraftModel = [NSString stringWithFormat:@"%ld", (long)countaircraftModel];
    entry.aircraftRegistration = [NSString stringWithFormat:@"%ld", (long)countaircraftRegistration];
    entry.approachesCount = sumapproachesCount;
    entry.approachesType = [NSString stringWithFormat:@"%ld", (long)countapproachesType];
    entry.complex = sumcomplex;
    entry.creationDateTime = [NSDate date];
    entry.dualGiven = sumdualGiven;
    entry.dualGivenCFI = sumdualGivenCFI;
    entry.dualGivenCommercial = sumdualGivenCommercial;
    entry.dualGivenGlider = sumdualGivenGlider;
    entry.dualGivenInstrument = sumdualGivenInstrument;
    entry.dualGivenOther = sumdualGivenOther;
    entry.dualGivenRecreational = sumdualGivenRecreational;
    entry.dualGivenSport = sumdualGivenSport;
    entry.dualReceived = sumdualReceived;
    entry.flightRoute = [NSString stringWithFormat:@"%ld", (long)countflightRoute];
    entry.glider = sumglider;
    entry.groundTime = sumgroundTime;
    entry.helicopter = sumhelicopter;
    entry.highPerf = sumhighPerf;
    entry.hobbsIn = sumhobbsIn;
    entry.hobbsOut = sumhobbsOut;
    entry.holds = sumholds;
    entry.instrumentActual = suminstrumentActual;
    entry.instrumentHood = suminstrumentHood;
    entry.instrumentSim = suminstrumentSim;
    entry.jet = sumjet;
    entry.landingsDay = sumlandingsDay;
    entry.landingsNight = sumlandingsNight;
    entry.lastSync=[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    entry.lastUpdate=[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970] * 1000000];
    entry.logDate = [NSDate date];
    entry.nightDualReceived = sumnightDualReceived;
    entry.nightTime = sumnightTime;
    entry.picTime = sumpicTime;
    entry.recreational = sumrecreational;
    entry.sicTime = sumsicTime;
    entry.soloTime = sumsoloTime;
    entry.sport = sumsport;
    entry.taildragger = sumtaildragger;
    entry.totalFlightTime = sumtotalFlightTime;
    entry.tracking = [NSString stringWithFormat:@"%ld", (long)counttracking];
    entry.turboprop = sumturboprop;
    entry.ultraLight = sumultraLight;
    entry.xc = sumxc;
    entry.xcDualGiven = sumxcDualGiven;
    entry.xcDualReceived = sumxcDualReceived;
    entry.xcNightDualReceived = sumxcNightDualReceived;
    entry.xcNightTime = sumxcNightTime;
    entry.xcPIC = sumxcPIC;
    entry.xcSolo = sumxcSolo;
    
    
    
    LogbookRecordViewController *logbookRecordViewController = [[LogbookRecordViewController alloc] initWithLogEntry:entry];
    logbookRecordViewController.isTotal = YES;
    [self.navigationController pushViewController:logbookRecordViewController animated:YES];
}
-(void)addLogbookEntry
{
    FDLogDebug(@"add logbook entry!");
    LogbookRecordViewController *logbookRecordViewController = [[LogbookRecordViewController alloc] initWithLogEntry:nil];
    logbookRecordViewController.isOpenFromLogBook = YES;
    [self.navigationController pushViewController:logbookRecordViewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // get the number of logbook entries
    return [logBookEntries count];
}

// the cell will be returned to the tableView
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"LogbookCell";
    
    // grab a logbook cell
    LogbookCell *cell = (LogbookCell *)[theTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[LogbookCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    
    // compute the last column width
    int width = logBookTableView.frame.size.width - cell.lastColumnX - 1;
    cell.soloTime.frame = CGRectMake(cell.lastColumnX, 0, width + 1, cell.soloTime.frame.size.height);
    // compute the remarks width
    width = logBookTableView.frame.size.width - 1;
    cell.remarks.frame = CGRectMake(cell.remarks.frame.origin.x, cell.remarks.frame.origin.y, width + 1, cell.remarks.frame.size.height);
    // grab the logbook entry object
    LogEntry *entry = [logBookEntries objectAtIndex:indexPath.row];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yy"];
    cell.logDate.text = [formatter stringFromDate:entry.logDate];
    cell.aircraft.text = entry.aircraftModel;
    cell.ident.text = entry.aircraftRegistration;
    cell.route.text = entry.flightRoute;
    // flight duration
    if ([[NSDecimalNumber notANumber] isEqualToValue:entry.totalFlightTime] == NO) {
        cell.duration.text = [entry.totalFlightTime stringValue];
    } else {
        cell.duration.text = @"";
    }
    // actual instrument time
    if (entry.instrumentActual != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.instrumentActual] == NO) {
        cell.actualInstrument.text = [entry.instrumentActual stringValue];
    } else {
        cell.actualInstrument.text = @"";
    }
    // hood instrument time
    if (entry.instrumentHood != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.instrumentHood] == NO) {
        cell.hoodInstrument.text = [entry.instrumentHood stringValue];
    } else {
        cell.hoodInstrument.text = @"";
    }
    // sim instrument time
    if (entry.instrumentSim != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.instrumentSim] == NO) {
        cell.simInstrument.text = [entry.instrumentSim stringValue];
    } else {
        cell.simInstrument.text = @"";
    }
    // day landings
    if (entry.landingsDay != nil) {
        cell.dayLandings.text = [entry.landingsDay stringValue];
    } else {
        cell.dayLandings.text = @"";
    }
    // night landings
    if (entry.landingsNight != nil) {
        cell.nightLandings.text = [entry.landingsNight stringValue];
    } else {
        cell.nightLandings.text = @"";
    }
    // ground time
    if (entry.groundTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.groundTime] == NO) {
        cell.groundTime.text = [entry.groundTime stringValue];
    } else {
        cell.groundTime.text = @"";
    }
    // flight time
    if (entry.totalFlightTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.totalFlightTime] == NO) {
        cell.flightTime.text = [entry.totalFlightTime stringValue];
    } else {
        cell.flightTime.text = @"";
    }
    // X-C time
    if (entry.xcDualReceived != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.xcDualReceived] == NO) {
        cell.xcTime.text = [entry.xcDualReceived stringValue];
    } else {
        cell.xcTime.text = @"";
    }
    // solo time
    if (entry.soloTime != nil && [[NSDecimalNumber notANumber] isEqualToValue:entry.soloTime] == NO) {
        cell.soloTime.text = [entry.soloTime stringValue];
    } else {
        cell.soloTime.text = @"";
    }
    // remarks
    if ([[AppDelegate sharedDelegate].userLevel.lowercaseString isEqualToString:@"instructor"]) {
        
        if (entry.studentUserID != nil) {
            
            NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:context];
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:entityDesc];
            // only grab root lesson groups (where there is no parent)
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", entry.studentUserID];
            [request setPredicate:predicate];
            NSError *error;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (objects == nil) {
                FDLogError(@"Unable to retrieve Student!");
                 cell.remarks.text = [NSString stringWithFormat:@" Remarks: %@", entry.remarks ];
            } else if (objects.count == 0) {
                FDLogDebug(@"No valid Student!");
                cell.remarks.text = [NSString stringWithFormat:@" Remarks: %@", entry.remarks ];
            } else {
                Student *std = objects[0];
                if (entry.remarks != nil) {
                    cell.remarks.text = [NSString stringWithFormat:@" Remarks: %@ %@ %@",std.firstName, std.lastName,  entry.remarks ];
                } else {
                    cell.remarks.text = @"";
                }
            }
        }
    }else{
        if (entry.remarks != nil) {
            cell.remarks.text = [NSString stringWithFormat:@" Remarks: %@", entry.remarks ];
        } else {
            cell.remarks.text = @"";
        }
    }
    
    if ([entry.userID integerValue] == [[AppDelegate sharedDelegate].userId integerValue]){
        cell.delegate = self;
        //    cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
    }
    

    
    return cell;
}

#pragma mark - UITableViewDelegate
// when user tap the row, what action you want to perform
- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
    FDLogDebug(@"view/edit entry for %ld", (long)indexPath.row);
    LogEntry *entry = [logBookEntries objectAtIndex:indexPath.row];
    NSLog(@"%ld", [entry.entryID integerValue]);
    LogbookRecordViewController *logbookRecordViewController = [[LogbookRecordViewController alloc] initWithLogEntry:entry];
    logbookRecordViewController.isOpenFromLogBook = YES;
    [self.navigationController pushViewController:logbookRecordViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DEFAULT_UITABLEVIEW_CELL_HEIGHT + REMARKS_HEIGHT;
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSLog(@"left is ok");
        }
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0:
        {
            NSIndexPath *indexPath = [logBookTableView indexPathForCell:cell];
            LogEntry *oneLogEntry = [logBookEntries objectAtIndex:indexPath.row];
            NSNumber *entryID = oneLogEntry.entryID;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flight Desk" message:@"Do you want to delete current Log Entry?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                NSError *error = nil;
                if ([entryID integerValue] != 0) {
                    NSError *error;
                    // upload lesson records
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
                    [request setEntity:entityDescription];
                    // all lesson records with lastUpdate == 0 need to be uploaded
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"entryID == %@", entryID];
                    [request setPredicate:predicate];
                    NSArray *fetchedLogEntry = [context executeFetchRequest:request error:&error];
                    // create dictionary for uploading lessons
                    if (fetchedLogEntry.count > 0) {
                        for (LogEntry *logEntryToDelete in fetchedLogEntry) {
                            for (Endorsement *endorsementToDelete in logEntryToDelete.endorsements) {
                                [context deleteObject:endorsementToDelete];
                            }
                            [context deleteObject:logEntryToDelete];
                        }
                    }
                    
                    [logBookEntries removeObject:oneLogEntry];
                    
                    DeleteQuery *deleteQuery = [NSEntityDescription insertNewObjectForEntityForName:@"DeleteQuery" inManagedObjectContext:context];
                    deleteQuery.type = @"logbook_entry";
                    deleteQuery.idToDelete = entryID;
                    
                    if (error) {
                        NSLog(@"Error when saving managed object context : %@", error);
                    }
                }else{
                    NSError *error;
                    // upload lesson records
                    NSFetchRequest *request = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"LogEntry" inManagedObjectContext:context];
                    [request setEntity:entityDescription];
                    // all lesson records with lastUpdate == 0 need to be uploaded
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonId == %@", oneLogEntry.lessonId];
                    [request setPredicate:predicate];
                    NSArray *fetchedLogEntry = [context executeFetchRequest:request error:&error];
                    // create dictionary for uploading lessons
                    if (fetchedLogEntry.count > 0) {
                        for (LogEntry *logEntryToDelete in fetchedLogEntry) {
                            for (Endorsement *endorsementToDelete in logEntryToDelete.endorsements) {
                                [context deleteObject:endorsementToDelete];
                            }
                            [context deleteObject:logEntryToDelete];
                        }
                    }
                    [logBookEntries removeObject:oneLogEntry];
                }
                [context save:&error];
                if (error) {
                    NSLog(@"Error when saving managed object context : %@", error);
                }
                [logBookTableView reloadData];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
                
            }];
            [alert addAction:cancel];
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Delete"];
    
    return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor greenColor] title:@"Edit"];
    
    return leftUtilityButtons;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)deviceOrientationDidChange{
    [self setNavigationColorWithGradiant];
    [self drawView];
    [self superClassDeviceOrientationDidChange];
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)setNavigationColorWithGradiant{
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = [UIScreen mainScreen] .bounds;
    gradientLayer.colors = @[ (__bridge id)[UIColor lightGrayColor].CGColor,
                              (__bridge id)[UIColor darkGrayColor].CGColor ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    UIGraphicsBeginImageContext(gradientLayer.bounds.size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
}
-(void) drawView{
    int statusBarHeight = 0;
    if ([UIApplication sharedApplication].statusBarHidden == NO) {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    int navigationBarHeight = 0;
    if (self.navigationController.navigationBarHidden == NO) {
        navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    }
    
    CGRect columnHeaderRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, columnHeaderHeight);
    [logBookColumnHeaderView setFrame:columnHeaderRect];
    
    // make logbook header
    int x = 0;
    int width = 60;
    [dateLabel setFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    x += width;
    
    [aircraftLabel setFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    x += width;
    
    [identLabel setFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    
    x += width;
    
    width = 100;
    
    [routeLabel setFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    x += width;
    
    width = 50;
    [durationLabel setFrame:CGRectMake(x, 0, width + 1, columnHeaderHeight + 1)];
    x += width;
    
    width = 150;
    [instrumentLabel setFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    
    width = 50;
    [actualInstrumentLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    [hoodInstrumentLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    [simInstrumentLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    width = 100;
    [landingsLabel setFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    
    width = 50;
    [dayLandingsLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    [nightLandingsLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    width = self.view.bounds.size.width - x - 1;
    [experienceLabel setFrame:CGRectMake(x, 0, width + 1, halfColumnHeaderHeight + 1)];
    
    width = 50;
    [groundLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    [flightLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    [xcLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    width = self.view.bounds.size.width - x - 1;
    [soloLabel setFrame:CGRectMake(x, halfColumnHeaderHeight, width + 1, halfColumnHeaderHeight + 1)];
    x += width;
    
    columnFooterHeight = 130;
    labelFooterHeight = 80;
    halfColumnFooterHeight = 40;
    // make a new bounds for the UIView with the column headers
    CGRect columnFooterRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.size.height - columnFooterHeight-50, self.view.bounds.size.width, columnFooterHeight);
    [logBookFooterView setFrame:columnFooterRect];

    // make logbook Footer
    int xOfFooter = 0;
    int widthOfFooter = 70;
    [totalLabel setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, columnFooterHeight + 1)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 60;
    [aircraftLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    
    [aircraftCountForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [identLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    
    [identCountForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 60;
    [routeLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    
    [routeCountForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 50;
    [durationLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, labelFooterHeight + 1)];
    
    [durationSumForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 135;
    [instrumentLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    widthOfFooter = 45;
    [actualInstrumentLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [actualInstrumentSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [hoodInstrumentLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [hoodInstrumentSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [simInstrumentLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [simInstrumentSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 80;
    [landingsLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    widthOfFooter = 40;
    [dayLandingsLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [dayLandingsSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [nightLandingsLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [nightLandingsSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = self.view.bounds.size.width - xOfFooter - 1;
    [experienceLabelForFooter setFrame:CGRectMake(xOfFooter, 0, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    widthOfFooter = 45;
    [groundLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [groundSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [flightLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [flightSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    
    xOfFooter += widthOfFooter;
    
    [xcLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [xcSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    [soloLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [soloSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    
    xOfFooter += widthOfFooter;
    
    widthOfFooter = 40;
    [picLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [picSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    widthOfFooter = self.view.bounds.size.width - xOfFooter - 1;
    [niteLabelForFooter setFrame:CGRectMake(xOfFooter, halfColumnFooterHeight, widthOfFooter + 1, halfColumnFooterHeight + 1)];
    
    [niteSumLabelForFooter setFrame:CGRectMake(xOfFooter, labelFooterHeight, widthOfFooter + 1, 51)];
    xOfFooter += widthOfFooter;
    
    CGRect columnFooterRectOfButton = CGRectMake(0, 0, self.view.bounds.size.width, columnFooterHeight);
    [tapTotalLog setFrame:columnFooterRectOfButton];

    
    CGRect tableViewRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y  + columnHeaderHeight, self.view.bounds.size.width, self.view.bounds.size.height - columnHeaderHeight -columnFooterHeight-50);
    [logBookTableView setFrame:tableViewRect];
    
    [logBookTableView reloadData];
}
- (void)selectEndorsementsToShow{
    EndorsementAllViewController *endorsementVc = [[EndorsementAllViewController alloc] init];
    [self.navigationController pushViewController:endorsementVc animated:YES];
}
@end
