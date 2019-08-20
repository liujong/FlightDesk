//
//  GeneralViewController.h
//  FlightDesk
//
//  Created by stepanekdavid on 5/24/17.
//  Copyright © 2017 spider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZSSRichTextEditor.h"
#import <MKDropdownMenu/MKDropdownMenu.h>
#import "HVTableView.h"

@interface GeneralViewController : UIViewController{

    __weak IBOutlet UIView *mainView;
    __weak IBOutlet UIScrollView *scrView;
    
    __weak IBOutlet UIView *textEditorCV;
    __weak IBOutlet UIView *txtEditorDialog;
    
    __weak IBOutlet UILabel *lblTextEditorTitle;
    
    __weak IBOutlet UIButton *btnSave;
    
    __weak IBOutlet MKDropdownMenu *categoryDropDownMenu;
    __weak IBOutlet HVTableView *FaqsTableView;
    __weak IBOutlet UIView *faqsCoverView;
    
    __weak IBOutlet UITextField *txtCategory;
    __weak IBOutlet UIView *faqsAddView;
    __weak IBOutlet UITextField *txtQuestion;
    __weak IBOutlet UITextView *txtAnswer;
    
    
}
- (IBAction)onGettingStart:(id)sender;
- (IBAction)onFAQs:(id)sender;
- (IBAction)onTermsOfUse:(id)sender;
- (IBAction)onPrivacy:(id)sender;
- (IBAction)onCopyrightsAndTradeMarks:(id)sender;

- (IBAction)onCancelTxtEditor:(id)sender;
- (IBAction)onSaveTxtEditor:(id)sender;

- (void)reloadFaqs;

@property (strong, nonatomic) ZSSRichTextEditor *richTextEditorVC;

@end
