//
//  AddCheckListsViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 9/15/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MKDropdownMenu/MKDropdownMenu.h>

@interface AddCheckListsViewController : UIViewController{

    __weak IBOutlet UIButton *btnImportAceFile;
    
    __weak IBOutlet UITextView *categoryTxtView;
    __weak IBOutlet MKDropdownMenu *categoryDropDown;
    
    __weak IBOutlet UITableView *ItemTableView;
    
    IBOutlet UIView *FootBarToAddItem;
    __weak IBOutlet MKDropdownMenu *TypeDropDown;
    IBOutlet UIView *navView;
}
- (IBAction)onBack:(id)sender;
- (IBAction)onSave:(id)sender;

- (IBAction)onAddItem:(id)sender;
- (IBAction)onParsingAce:(id)sender;

@property BOOL isImporedFromOther;
@property (nonatomic, strong) NSURL *importedUrl;

- (void)parseACEFileFromUrl:(NSURL *)fileUrl;
@end
