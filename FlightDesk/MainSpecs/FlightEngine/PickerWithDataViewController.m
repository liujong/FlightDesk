//
//  PickerWithDataViewController.m
//  FlightDesk
//
//  Created by stepanekdavid on 6/18/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import "PickerWithDataViewController.h"

@interface PickerWithDataViewController ()<UIPickerViewDelegate, UIPickerViewDataSource>{

    
    
    NSMutableArray *arrAirCraftCategories;
    NSMutableArray *arrAirCraftClass;
    NSMutableArray *arrShortAirCraftClass;
    NSMutableArray *arrEndorsements;
    
    
    
    NSString *currentTextOfSending;
    
}

@end

@implementation PickerWithDataViewController
@synthesize pickerType, cellIndexForEndorsement, arrLookUpCategories, strToSend, pickerItems;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.autoresizesSubviews = YES;
    self.view.userInteractionEnabled = NO;
    self.view.contentMode = UIViewContentModeRedraw;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
    self.view.hidden = YES; self.view.alpha = 0.0f; // Start hidden
    currentTextOfSending = @"";
    
    
//    pickerDialog.autoresizesSubviews = NO;
//    pickerDialog.contentMode = UIViewContentModeRedraw;
//    pickerDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//    
//    pickerDialog.layer.shadowRadius = 3.0f;
//    pickerDialog.layer.shadowOpacity = 1.0f;
//    pickerDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
//    pickerDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:pickerDialog.bounds].CGPath;
    pickerDialog.layer.cornerRadius = 5.0f;
    
    currentPicker.delegate = self;
    currentPicker.dataSource = self;
    
    pickerItems = [[NSMutableArray alloc] init];
    arrAirCraftCategories = [[NSMutableArray alloc] init];
    arrShortAirCraftClass = [[NSMutableArray alloc] init];
    arrAirCraftClass = [[NSMutableArray alloc] init];
    arrEndorsements = [[NSMutableArray alloc] init];
    arrLookUpCategories = [[NSMutableArray alloc] init];
    
    [arrAirCraftCategories addObject:@"Normal"];
    [arrAirCraftCategories addObject:@"Utility"];
    [arrAirCraftCategories addObject:@"Transport"];
    [arrAirCraftCategories addObject:@"Acrobatic"];
    [arrAirCraftCategories addObject:@"Limited"];
    
    [arrAirCraftClass addObject:@"Airplane"];
    [arrShortAirCraftClass addObject:@"Airplane"];
    [arrAirCraftClass addObject:@"Rotorcraft"];
    [arrShortAirCraftClass addObject:@"Rotorcraft"];
    [arrAirCraftClass addObject:@"Glider"];
    [arrShortAirCraftClass addObject:@"Glider"];
    [arrAirCraftClass addObject:@"Lighter-than-Air"];
    [arrShortAirCraftClass addObject:@"Lighter-than-Air"];
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"PREREQUISITES FOR THE PRACTICAL TEST ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Prerequisites for practical test: § 61.39(a)(6)(i) and (ii).", @"title", @" I certify that (First name, MI, Last name) has received and logged training time within 2 calendar-months preceding the month of application in preparation for the practical test and he/she is prepared for the required practical test for the issuance of (applicable) certificate.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Review of deficiencies identified on airman knowledge test: § 61.39(a)(6)(iii) as required.", @"title", @" I certify that (First name, MI, Last name) has demonstrated satisfactory knowledge of the subject areas in which he/she was deficient on the (applicable) airman knowledge test.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"STUDENT PILOT ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Presolo aeronautical knowledge: § 61.87(b).", @"title", @" I certify that (First name, MI, Last name) has satisfactorily completed the presolo knowledge exam of § 61.87(b) for the (make and model aircraft).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Presolo flight training: § 61.87(c).", @"title", @" I certify that (First name, MI, Last name) has received the required presolo training in a (make and model aircraft). I have determined he/she has demonstrated the proficiency of § 61.87(d) and is proficient to make solo flights in that make and model aircraft. ", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Presolo flight training at night: § 61.87(c) and 61.87(o).", @"title", @" I certify that (First name, MI, Last name) has received the required presolo training in a (make and model aircraft). I have determined he/she has demonstrated the proficiency of § 61.87(o) and is proficient to make solo flights at night in that make and model aircraft.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight (first 90-day period): § 61.87(n).", @"title", @" I certify that (First name, MI, Last name) has received the required training to qualify for solo flying. I have determined he/she meets the applicable requirements of § 61.87(n) and is proficient to make solo flights in (make and model).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight (each additional 90-day period): § 61.87(p).", @"title", @" I certify that (First name, MI, Last name) has received the required training to qualify for solo flying. I have determined he/she meets the applicable requirements of § 61.87(p) and is proficient to make solo flights in (make and model).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo takeoffs and landings at another airport within 25 nautical miles (NM):\n§ 61.93(b)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.93(b)(1). I have determined that he/she is proficient to practice solo takeoffs and landings at (airport name). The takeoffs and landings at (airport name) are subject to the following conditions: (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo cross-country flight: § 61.93(c)(1) and 61.93(c)(2).", @"title", @" I certify that (First name, MI, Last name) has received the required solo cross-country training. I find he/she has met the applicable requirements of § 61.93, and is proficient to make solo cross-country flights in a (make and model aircraft), (aircraft category).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo cross-country flight: § 61.93(c)(3).", @"title", @" I have reviewed the cross-country planning of (First name, MI, Last name). I find the planning and preparation to be correct to make the solo flight from (origination airport) to (origination airport) via (route of flight) with landings at (name the airports) in a (make and model aircraft) on (date). (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Repeated solo cross-country flights not more than 50 NM from the point of departure:\n§ 61.93(b)(2).", @"title", @" I certify that (First name, MI, Last name) has received the required training in both directions between and at both (airport names). I have determined that he/she is proficient of § 61.93(b)(2) to conduct repeated solo cross-country flights over that route, subject to the following conditions: (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight in Class B airspace: § 61.95(a).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.95(a). I have determined he/she is proficient to conduct solo flights in (name of Class B) airspace. (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight to, from, or at an airport located in Class B airspace: § 61.95(a) and 14 CFR part 91, § 91.131(b)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.95(a)(1). I have determined that he/she is proficient to conduct solo flight operations at (name of airport). (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Endorsement of U.S. citizenship recommended by the Transportation Security Administration (TSA): Title 49 of the Code of Federal Regulations (49 CFR) § 1552.3(h).", @"title", @" I certify that (First name, MI, Last name) has presented me a [insert type of document presented, such as a U.S. birth certificate or U.S. passport, and the relevant control or sequential number on the document, if any] establishing that [he or she] is a U.S. citizen or national in accordance with 49 CFR § 1552.3(h).", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"ADDITIONAL STUDENT PILOT ENDORSEMENTS FOR STUDENTS SEEKING SPORT OR RECREATIONAL PILOT CERTIFICATES", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight in Class B, C, and D airspace: § 61.94(a).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.94(a). I have determined he/she is proficient to conduct solo flights in (name of Class B, C, or D) airspace and authorized to operate to, from through and at __________ airport. (List any applicable conditions or limitations.)", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Solo flight to, from, or at an airport located in Class B, C, or D airspace or on an airport having an operational control tower: §§ 61.94(a) and 91.131(b)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.94(a)(1). I have determined that he/she is proficient to conduct solo flight operations at (name of airport located in Class B, C, or D airspace or on an airport having an operational control tower). (List any applicable conditions or limitations.)", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"SPORT PILOT ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical knowledge test: § 61.35(a)(1) and 61.309.", @"title", @" I certify that (First name, MI, Last name) has received the required aeronautical knowledge training of § 61.309. I have determined that he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Taking flight proficiency check for different category or class of aircraft: § 61.309 and 61.311.", @"title", @" I certify that (First name, MI, Last name) has received the required training required in accordance with §§ 61.309 and 61.311 and have determined that he/she is prepared for the (name of) proficiency check.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable", @"Passing flight proficiency check for different category or class of aircraft: §§ 61.309 and 61.311.", @"title", @" I certify that (First name, MI, Last name) has met the requirements of §§ 61.309 and 61.311 and I have determined him/her proficient to act as PIC of (category and class) of light-sport aircraft.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"selectable", @"Taking sport pilot practical test: §§ 61.309, 61.311, and 61.313.", @"title", @" I certify that (First name, MI, Last name) has received the training required in accordance with §§ 61.309 and 61.311 and met the aeronautical experience requirements of § 61.313. I have determined that he/she is prepared for the (type of) practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"selectable", @"Passing a sport pilot practical test: §§ 61.309, 61.311, and 61.313.", @"title", @" I certify that (First name, MI, Last name) has met the requirements of §§ 61.309, 61.311, and 61.313, and I have determined him/her proficient to act as PIC of (category and class of) Light-Sport Aircraft.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"selectable", @"Class B, C, or D airspace, at an airport located in Class B, C, or D airspace, or to, from, through, or on an airport having an operational control tower: § 61.325.", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.325. I have determined he/she is proficient to conduct operations in Class B, C, or D airspace, at an airport located in Class B, C, or D airspace, or to, from, through, or on an airport having an operational control tower.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"selectable", @"Light-sport aircraft that has a maximum speed in level flight with maximum continuous power (VH) less than or equal to 87 Knots Calibrated Airspeed (KCAS): § 61.327.", @"title", @" I certify that (First name, MI, Last name) has received the required training required in accordance with § 61.327(a) in a (make and model aircraft). I have determined him/her proficient to act as PIC of a light-sport aircraft that has a VH less than or equal to 87 KCAS.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1),@"selectable", @"Light-sport aircraft that has a VH greater than 87 KCAS: § 61.327.", @"title", @" I certify that (First name, MI, Last name) has received the required training required in accordance with § 61.327(b) in a (make and model aircraft). I have determined him/her proficient to act as PIC of a light-sport aircraft that has a VH greater than 87 KCAS.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"RECREATIONAL PILOT ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical knowledge test: §§ 61.35(a)(1), 61.96(b)(3), and 61.97(b).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.97(b). I have determined that he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight proficiency/practical test: §§ 61.96(b)(5), 61.98(a) and (b), and 61.99.", @"title", @" I certify that (First name, MI, Last name) has received the required training of §§ 61.98(b)and 61.99. I have determined that he/she is prepared for the (name of) practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Recreational pilot to operate within 50 NM of the airport where training was received: § 61.101(b).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.101(b). I have determined he/she is competent to operate at the (name of airport).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Recreational pilot to act as pilot in command (PIC) on a flight that exceeds 50 NM of the departure airport: § 61.101(c).", @"title", @" I certify that (First name, MI, Last name) has received the required cross-country training of § 61.101(c). I have determined that he/she is proficient in cross-country flying of part 61 subpart E.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Recreational pilot with less than 400 flight hours and not logged PIC time within the preceding 180 days: § 61.101(g).", @"title", @" I certify that (First name, MI, Last name) has received the required 180-day recurrent training of § 61.101(g) in a (make and model aircraft). I have determined him/her proficient to act as PIC of that aircraft.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Recreational pilot to conduct solo flights for the purpose of obtaining an additional certificate or rating while under the supervision of an authorized flight instructor: § 61.101(j).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.87 in a (make and model aircraft). I have determined he/she is prepared to conduct a solo flight on (date) under the following conditions: (List all conditions which require endorsement, e.g., flight which requires communication with air traffic control, flight in an aircraft for which the pilot does not hold a category/class rating, etc.).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Class B, C, or D airspace, at an airport located in Class B, C, or D airspace, or to, from, through, or on an airport having an operational control tower: § 61.101(d).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.101(d). I have determined he/she is proficient to conduct operations in Class B, C, or D airspace, at an airport located in Class B, C, or D airspace, or to, from, through, or on an airport having an operational control tower.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"PRIVATE PILOT ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical knowledge test: §§ 61.35(a)(1), 61.103(d), and 61.105.", @"title", @" I certify that (First name, MI, Last name) has received the required training in accordance with § 61.105. I have determined he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight proficiency/practical test: §§ 61.103(f), 61.107(b), and 61.109.", @"title", @" I certify that (First name, MI, Last name) has received the required training in accordance with §§ 61.107 and 61.109. I have determined he/she is prepared for the (name of) practical test.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"COMMERCIAL PILOT ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical knowledge test: §§ 61.35(a)(1), 61.123(c), and 61.125.", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.125. I have determined that he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight proficiency/practical test: §§ 61.123(e), 61.127, and 61.129.", @"title", @" I certify that (First name, MI, Last name) has received the required training of §§ 61.127 and 61.129. I have determined he/she is prepared for the (name of) practical test.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"AIRLINE TRANSPORT PILOT (ATP) ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Restricted privileges ATP Certificate: Airplane multiengine land rating, § 61.160.", @"title", @"The [insert institution’s name] certifies that the recipient of this degree has successfully completed all of the aviation coursework requirements of § 61.160[(b), (c), or (d)] and therefore meets the academic eligibility requirements of § 61.160[(b), (c), or (d)].", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"ATP Certification Training Program (CTP): § 61.153(e).", @"title", @"The applicant named above has successfully completed the Airline Transport Pilot Certification Training Program as required by § 61.156, and therefore has met the prerequisite required by § 61.35(a)(2) for the Airline Transport Pilot Multiengine Airplane Knowledge Test.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"INSTRUMENT RATING ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical knowledge test: §§ 61.35(a)(1), 61.65(a) and 61.65(b).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.65(b). I have determined that he/she is prepared for the Instrument—(airplane, helicopter, or powered-lift) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight proficiency/practical test: § 61.65(a)(6).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.65(c) and 61.65(d). I have determined he/she is prepared for the Instrument—(airplane, helicopter, or powered-lift) practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Prerequisites for instrument practical tests: § 61.39(a)", @"title", @" I certify that (First name, MI, Last name) has received and logged the required flight time/training of § 61.39(a) in preparation for the practical test within 2 calendar-months preceding the date of the test and has satisfactory knowledge of the subject areas in which he/she was shown to be deficient by the FAA airman knowledge test report. I have determined he/she is prepared for the Instrument—(airplane, helicopter, or powered-lift) practical test.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"FLIGHT INSTRUCTOR (OTHER THAN FLIGHT INSTRUCTORS WITH A SPORT PILOT RATING) ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Fundamentals of instructing knowledge test: § 61.183(d).", @"title", @" I certify that (First name, MI, Last name) has received the required fundamentals of instruction training of § 61.185(a)(1). I have determined that he/she is prepared for the Fundamentals of Instructing knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight instructor aeronautical knowledge test: § 61.183(f).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.185(a)(2) or (3) (as appropriate to the flight instructor rating sought). I have determined that he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight instructor ground and flight proficiency/practical test: § 61.183(g).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.187(b). I have determined he/she is prepared for the CFI—(aircraft category and class) practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight instructor certificate with instrument—(category/class) rating/practical test: §§ 61.183(g), 61.187(a) and 61.187(b)(7).", @"title", @" I certify that (First name, MI, Last name) has received the required CFII training of § 61.187(b)(7). I have determined he/she is prepared for the CFII(airplane, helicopter, or powered-lift) practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Spin training: § 61.183(i)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.183(i). I have determined that he/she is competent in instructional skills for training stall awareness, spin entry, spins, and spin recovery procedures.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"FLIGHT INSTRUCTOR WITH A SPORT PILOT RATING ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Fundamentals of instructing knowledge test: § 61.405(a)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training in accordance with § 61.405(a)(1). I have determined that he/she is prepared for the Fundamentals of Instruction Knowledge Test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Sport pilot flight instructor aeronautical knowledge test: §§ 61.35(a)(1) and 61.405(a).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.405(a)(2). I have determined that he/she is prepared for the (name the knowledge test).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight instructor flight proficiency check to provide training if a different category or class of aircraft(additional category/class): §§ 61.409 and 61.419.", @"title", @" I certify that (First name, MI, Last name) has received the required training in accordance with §§ 61.409 and 61.419 and have determined he/she is prepared for a proficiency check for the flight instructor with a sport pilot rating in a (aircraft category and class).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Passing the flight instructor flight proficiency check to provide training in a different category or class of aircraft(additional category/class): §§ 61.409 and 61.419.", @"title", @" I certify that (First name, MI, Last name) has met the requirements in accordance with §§ 61.409 and 61.419. I have determined that he/she is proficient and authorized for the additional (aircraft category and class) flight instructor privilege.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight instructor practical test: §§ 61.409 and 61.411.", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.409 and met the aeronautical experience requirements of § 61.411. I have determined he/she is prepared for the flight instructor with a sport pilot rating practical test in a (aircraft category and class).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Passing the flight instructor practical test: §§ 61.409 and 61.411.", @"title", @" I certify that (First name, MI, Last name) has met the requirements in accordance with §§ 61.409 and 61.411. I have determined that he/she is proficient and authorized for the (aircraft category and class) flight instructor privilege.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Spin training: § 61.405(b)(1)(ii).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.405(b)(1)(ii). I have determined that he/she is competent and possesses instructional proficiency in stall awareness, spin entry, spins, and spin recovery procedures.", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"GROUND INSTRUCTOR ENDORSEMENT", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Ground instructor who does not meet the recent experience requirements: § 61.217(b).", @"title", @" I certify that (First name, MI, Last name) has demonstrated satisfactory proficiency on the appropriate ground instructor knowledge and training subjects of § 61.213(a)(3) and 61.213(a)(4).", @"text", nil]];
    
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"SPECIAL FEDERAL AVIATION REGULATION (SFAR) 73 ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R22/R44 awareness training: SFAR 73, section 2(a)(1) or (2).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) has received the Awareness Training required by SFAR 73, section 2(a)(3)(i-iv).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R22 solo endorsement: SFAR 73, section 2(b)(3).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) meets the experience requirements of SFAR 73, section 2(b)(3) and has been given training specified by SFAR 73, section 2(b)(3)(i-iv). He/She has been found proficient to solo the R22 helicopter.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R22 PIC endorsement: SFAR 73, section 2(b)(1)(ii).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) has been given training specified by SFAR 73, section 2(b)(1)(ii)(A-D) for Robinson R22 helicopters and is proficient to act as pilot in command. An annual flight review must be completed by [INSERT DATE 12 CALENDAR-MONTHS AFTER DATE OF THIS ENDORSEMENT] unless the requirements of SFAR 73, section 2(b)(1)(i) are met.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R22 flight instructor endorsement: SFAR 73, section 2(b)(5)(iv).", @"title", @" I certify that (First name, MI, Last name) holder of CFI Certificate No. __________, meets the experience requirements and has completed the flight training specified by SFAR 73, section 2(b)(5)(i-ii) and (iii)(A-D), and has demonstrated an ability to provide instruction on the general subject areas of SFAR 73, section 2(a)(3) and the flight training identified in SFAR 73, section 2(b)(5)(iii) in a Robinson R22 helicopter.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight review in an R22 helicopter: SFAR 73, section 2(c)(1) and (3).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) has satisfactorily completed the Flight Review required by 14 CFR part 61, § 61.56 and SFAR 73, section 2(c)(1) and (3), on [INSERT DATE OF FLIGHT REVIEW].", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R44 solo endorsement: SFAR 73, section 2(b)(4).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) meets the experience requirements of SFAR 73, section 2(b)(4) and has been given training specified by SFAR 73, section 2(b)(4)(i-iv). He/She has been found proficient to solo the R44 helicopter.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R44 PIC endorsement: SFAR 73, section 2(b)(2)(ii).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) has been given training specified by SFAR 73, section 2(b)(2)(ii)(A-D) for Robinson R44 helicopters and is proficient to act as pilot in command. An annual flight review must be completed by [INSERT DATE 12 CALENDAR-MONTHS AFTER DATE OF THIS ENDORSEMENT] unless the requirements of SFAR 73, section 2(b)(2)(i) are met.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"R44 flight instructor endorsement: SFAR 73, section 2(b)(5)(iv).", @"title", @" I certify that (First name, MI, Last name) holder of CFI Certificate No. __________, meets the experience requirements and has completed the flight training specified by SFAR 73, section 2(b)(5)(i-ii) and (iii)(A-D), and has demonstrated an ability to provide instruction on the general subject areas of SFAR 73, section 2(a)(3) and the flight training identified in SFAR 73, section 2(b)(5)(iii) in a Robinson R44 helicopter.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Flight review in an R44 helicopter: SFAR 73, section 2(c)(2) and (3).", @"title", @" I certify that (First name, MI, Last name, Pilot Certificate No. ___________) has satisfactorily completed the Flight Review required by 14 CFR § 61.56 and SFAR 73, section 2(c)(2) and (3), on [INSERT DATE OF FLIGHT REVIEW].", @"text", nil]];
    
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(0), @"selectable",@"ADDITIONAL ENDORSEMENTS", @"title", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Completion of a flight review: § 61.56(a) and 61.56(c).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has satisfactorily completed a flight review of § 61.56(a) on (date).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Completion of any phase of an FAA-sponsored Pilot Proficiency Program (WINGS): § 61.56(e).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has satisfactorily completed Level: (Basic/Advanced/Master, as appropriate), Phase No. ___ of a WINGS program on (date).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Completion of an instrument proficiency check: § 61.57(d).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has satisfactorily completed the instrument proficiency check of § 61.57(d) in a (list make and model of aircraft) on (date).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"To act as PIC in a complex airplane: § 61.31(e).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training of § 61.31(e) in a (make and model of complex airplane). I have determined that he/she is proficient in the operation and systems of a complex airplane.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"To act as PIC in a high performance airplane: § 61.31(f).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training of § 61.31(f) in a (make and model of high performance airplane). I have determined that he/she is proficient in the operation and systems of a high performance airplane.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"To act as PIC in a pressurized aircraft capable of high altitude operations: § 61.31(g).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training of § 61.31(g) in a (make and model of pressurized aircraft). I have determined that he/she is proficient in the operation and systems of a pressurized aircraft.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"To act as PIC in a tailwheel airplane: § 61.31(i).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training of § 61.31(i) in a (make and model of tailwheel airplane). I have determined that he/she is proficient in the operation of a tailwheel airplane.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"To act as PIC of an aircraft in solo operations when the pilot does not hold an appropriate category/class rating: § 61.31(d)(2).", @"title", @" I certify that (First name, MI, Last name) has received the training as required by § 61.31(d)(2) to serve as a PIC in a (specific category and class of aircraft). I have determined that he/she is prepared to serve as PIC in that (make and model) aircraft. Limitations: (optional).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Retesting after failure of a knowledge or practical test: § 61.49.", @"title", @" I certify that (First name, MI, Last name) has received the additional (flight and/or ground, as appropriate) training as required by § 61.49. I have determined that he/she is prepared for the (name of) knowledge/practical test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Additional aircraft category or class rating (other than ATP): § 61.63(b) or 61.63(c).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training for an additional (name the aircraft category/class rating). I have determined that he/she is prepared for the (name of) practical test for the addition of a (name of) (specific aircraft category/class/type) type rating.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Type rating only, already holds the appropriate category or class rating (other than ATP): § 61.63(d)(2) and 61.63(d)(3).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.63(d)(2) and 61.63(d)(3) for an addition of a (name of) type rating.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Type rating concurrently with an additional category or class rating (other than ATP): § 61.63(d)(2) and 61.63(d)(3).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.63(d)(2) and 61.63(d)(3) for an addition of a (name of) (specific category/class/type) type rating. I have determined that he/she is prepared for the (name of) practical test for the addition of a (name of) (specific aircraft category/class/type) type rating.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Type rating only, already holds the appropriate category or class rating (at the ATP level): § 61.157(b)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.157(b)(1) for an addition of a (name of) type rating.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Type rating concurrently with an additional category or class rating (at the ATP level): § 61.157(b)(1).", @"title", @" I certify that (First name, MI, Last name) has received the required training of § 61.157(b)(1) for an addition of a (name of the specific category/class/type) type rating.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Launch procedures for operating a glider: § 61.31(j).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), has received the required training in a (list the glider make and model) for (list the launch procedure). I have determined that he/she is proficient in (list the launch procedure).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Review of a home study curriculum: § 61.35(a)(1).", @"title", @" I certify I have reviewed the home study curriculum of (First name, MI, Last name). I have determined he/she is prepared for the (name of) knowledge test.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Experimental aircraft onlyadditional aircraft category or class rating (other than ATP): § 61.63(h).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), as required by § 61.63(h) is proficient to act as PIC in a (category, class, make, and model) of experimental aircraft and has logged at least 5 hours flight time logged between September 1, 2004, and August 31, 2005, while acting as PIC in (name the aircraft category/class rating and make and model) that has been issued an experimental certificate.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Experimental aircraft onlyadditional aircraft category or class rating ATP: § 61.165(f).", @"title", @" I certify that (First name, MI, Last name), (grade of pilot certificate), (certificate number), as required by § 61.165(f) is proficient to act as PIC in a (category, class, make, and model) of experimental aircraft and has logged at least 5 hours flight time logged between September 1, 2004, and August 31, 2005, while acting as PIC in (name the aircraft category/class rating and make and model) that has been issued an experimental certificate.", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Aeronautical experience creditultralight vehicles: § 61.52.", @"title", @" I certify, I have reviewed the records of (First name, MI, Last name), as required by § 61.52(c). I have determined he/she may use (number of hours) aeronautical experience obtained in an ultralight vehicle to meet the requirements for (certificate/rating/privilege).", @"text", nil]];
    [arrEndorsements addObject:[NSDictionary dictionaryWithObjectsAndKeys:@(1), @"selectable",@"Endorsement required to provide training for night vision goggle (NVG) operations: § 61.195(k)(7).", @"title", @" I certify that (First name, MI, Last name) holder of CFI Certificate No. __________, meets the Night Vision Goggle Instructor requirements of § 61.195(k) and is authorized to perform the night vision goggle pilot-in-command qualification and recent flight experience requirements under §§ 61.31(k) and 61.57(f) and (g). This endorsement does not provide the authority to endorse another flight instructor as a night vision goggle instructor.", @"text", nil]];
                                
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
             pickerDialogCons.constant += -520.0f;
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
    [pickerItems removeAllObjects];
    if (pickerType == 1) {
        [pickerItems addObjectsFromArray:arrAirCraftCategories];
        lblPickerTitle.text = @"Pick Aircraft Category";
        pickerDialogWidthCons.constant = 300.0f;
        cancelBtnLeftCons.constant = 10.0f;
        doneBtnRightCons.constant = 10.0f;
        strToSend = [arrAirCraftCategories objectAtIndex:0];
    }else if (pickerType == 2){
        [pickerItems addObjectsFromArray:arrAirCraftClass];
        lblPickerTitle.text = @"Pick Aircraft Class";
        pickerDialogWidthCons.constant = 300.0f;
        cancelBtnLeftCons.constant = 10.0f;
        doneBtnRightCons.constant = 10.0f;
        strToSend = [arrAirCraftClass objectAtIndex:0];
    }else if (pickerType == 3){
        [pickerItems addObjectsFromArray:arrEndorsements];
        lblPickerTitle.text = @"Pick Endorsements";
        pickerDialogWidthCons.constant = 650.0f;
        cancelBtnLeftCons.constant = 70.0f;
        doneBtnRightCons.constant = 70.0f;
        strToSend = [[pickerItems objectAtIndex:1] objectForKey:@"title"];
        currentTextOfSending =  [[pickerItems objectAtIndex:1] objectForKey:@"text"];
    }else if (pickerType == 4) {
        [pickerItems addObjectsFromArray:arrLookUpCategories];
        lblPickerTitle.text = @"Pick Look Up Category";
        pickerDialogWidthCons.constant = 300.0f;
        cancelBtnLeftCons.constant = 10.0f;
        doneBtnRightCons.constant = 10.0f;
        strToSend = [arrLookUpCategories objectAtIndex:0];
    }
    [currentPicker reloadAllComponents];
    
    if (self.view.hidden == YES) // Hidden
    {
        self.view.hidden = NO; // Show hidden views
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 1.0f; // Fade in
             pickerDialogCons.constant += -420.0f;
             [self.view layoutIfNeeded];
             
             
         }
                         completion:^(BOOL finished)
         {
             self.view.userInteractionEnabled = YES;
             pickerDialog.autoresizesSubviews = NO;
             pickerDialog.contentMode = UIViewContentModeRedraw;
             pickerDialog.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
             
             pickerDialog.layer.shadowRadius = 3.0f;
             pickerDialog.layer.shadowOpacity = 1.0f;
             pickerDialog.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
             pickerDialog.layer.shadowPath = [UIBezierPath bezierPathWithRect:pickerDialog.bounds].CGPath;
             pickerDialog.layer.cornerRadius = 5.0f;
             
             if (pickerType == 3){
                 [currentPicker selectRow:1 inComponent:0 animated:YES];
             }
         }
         ];
    }
}
- (IBAction)onCancel:(id)sender {
    if (self.view.hidden == NO) // Visible
    {
        self.view.userInteractionEnabled = NO;
        
        [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.view.alpha = 0.0f; // Fade out
             pickerDialogCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate didCancelPickerView:self];
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
             pickerDialogCons.constant += -520.0f;
             [self.view layoutIfNeeded];
         }
                         completion:^(BOOL finished)
         {
             self.view.hidden = YES;
             [self.delegate returnValueFromPickerView:self withSelectedString:strToSend withType:pickerType  withText:currentTextOfSending withIndex:cellIndexForEndorsement];
         }
         ];
    }
}

// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [pickerItems count];
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (pickerType == 1) {
        strToSend = [pickerItems objectAtIndex:row];
    }else if (pickerType == 2){
        strToSend = [arrShortAirCraftClass objectAtIndex:row];
    } else if (pickerType == 3) {
        if ([[[pickerItems objectAtIndex:row] objectForKey:@"selectable"] boolValue]) {
            
            strToSend = [[pickerItems objectAtIndex:row] objectForKey:@"title"];
            currentTextOfSending =  [[pickerItems objectAtIndex:row] objectForKey:@"text"];
        }else{
            [currentPicker selectRow:row+1 inComponent:component animated:YES];
        }
    }else if (pickerType == 4){
        strToSend = [arrLookUpCategories objectAtIndex:row];
    }else {
        FDLogDebug(@"You selected nothing!");
    }
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *tView = (UILabel *)view;
    if (!tView) {
        tView = [[UILabel alloc] init];
        if (pickerType == 3) {
            tView.font = [UIFont fontWithName:@"Helvetica" size:12];
        }else{
            tView.font = [UIFont fontWithName:@"Helvetica" size:17];
        }
    }
    
    if (pickerType == 3) {
        if (![[[pickerItems objectAtIndex:row] objectForKey:@"selectable"] boolValue]) {
            tView.backgroundColor = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
        }else{
            tView.backgroundColor = [UIColor whiteColor];
        }
        tView.text = [[pickerItems objectAtIndex:row] objectForKey:@"title"];
    } else {
        tView.text = [pickerItems objectAtIndex:row];
    }
//    if (pickerType == 4){
//        tView.text = [arrLookUpCategories objectAtIndex:row];
//    }
    tView.textAlignment = NSTextAlignmentCenter;
    return tView;
}

@end
