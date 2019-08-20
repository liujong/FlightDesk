//
//  ZSSRichTextEditorViewController.h
//  ZSSRichTextEditor
//
//  Created by Nicholas Hubbard on 11/30/13.
//  Copyright (c) 2013 Zed Said Studio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HRColorPickerViewController.h"
#import "ZSSFontsViewController.h"

/**
 *  The types of toolbar items that can be added flightdeskapp.com
 */
static NSString * const ZSSRichTextEditorToolbarBold = @"com.flightdeskapp.toolbaritem.bold";
static NSString * const ZSSRichTextEditorToolbarItalic = @"com.flightdeskapp.toolbaritem.italic";
static NSString * const ZSSRichTextEditorToolbarSubscript = @"com.flightdeskapp.toolbaritem.subscript";
static NSString * const ZSSRichTextEditorToolbarSuperscript = @"com.flightdeskapp.toolbaritem.superscript";
static NSString * const ZSSRichTextEditorToolbarStrikeThrough = @"com.flightdeskapp.toolbaritem.strikeThrough";
static NSString * const ZSSRichTextEditorToolbarUnderline = @"com.flightdeskapp.toolbaritem.underline";
static NSString * const ZSSRichTextEditorToolbarRemoveFormat = @"com.flightdeskapp.toolbaritem.removeFormat";
static NSString * const ZSSRichTextEditorToolbarJustifyLeft = @"com.flightdeskapp.toolbaritem.justifyLeft";
static NSString * const ZSSRichTextEditorToolbarJustifyCenter = @"com.flightdeskapp.toolbaritem.justifyCenter";
static NSString * const ZSSRichTextEditorToolbarJustifyRight = @"com.flightdeskapp.toolbaritem.justifyRight";
static NSString * const ZSSRichTextEditorToolbarJustifyFull = @"com.flightdeskapp.toolbaritem.justifyFull";
static NSString * const ZSSRichTextEditorToolbarH1 = @"com.flightdeskapp.toolbaritem.h1";
static NSString * const ZSSRichTextEditorToolbarH2 = @"com.flightdeskapp.toolbaritem.h2";
static NSString * const ZSSRichTextEditorToolbarH3 = @"com.flightdeskapp.toolbaritem.h3";
static NSString * const ZSSRichTextEditorToolbarH4 = @"com.flightdeskapp.toolbaritem.h4";
static NSString * const ZSSRichTextEditorToolbarH5 = @"com.flightdeskapp.toolbaritem.h5";
static NSString * const ZSSRichTextEditorToolbarH6 = @"com.flightdeskapp.toolbaritem.h6";
static NSString * const ZSSRichTextEditorToolbarTextColor = @"com.flightdeskapp.toolbaritem.textColor";
static NSString * const ZSSRichTextEditorToolbarBackgroundColor = @"com.flightdeskapp.toolbaritem.backgroundColor";
static NSString * const ZSSRichTextEditorToolbarUnorderedList = @"com.flightdeskapp.toolbaritem.unorderedList";
static NSString * const ZSSRichTextEditorToolbarOrderedList = @"com.flightdeskapp.toolbaritem.orderedList";
static NSString * const ZSSRichTextEditorToolbarHorizontalRule = @"com.flightdeskapp.toolbaritem.horizontalRule";
static NSString * const ZSSRichTextEditorToolbarIndent = @"com.flightdeskapp.toolbaritem.indent";
static NSString * const ZSSRichTextEditorToolbarOutdent = @"com.flightdeskapp.toolbaritem.outdent";
static NSString * const ZSSRichTextEditorToolbarInsertImage = @"com.flightdeskapp.toolbaritem.insertImage";
static NSString * const ZSSRichTextEditorToolbarInsertImageFromDevice = @"com.flightdeskapp.toolbaritem.insertImageFromDevice";
static NSString * const ZSSRichTextEditorToolbarInsertLink = @"com.flightdeskapp.toolbaritem.insertLink";
static NSString * const ZSSRichTextEditorToolbarRemoveLink = @"com.flightdeskapp.toolbaritem.removeLink";
static NSString * const ZSSRichTextEditorToolbarQuickLink = @"com.flightdeskapp.toolbaritem.quickLink";
static NSString * const ZSSRichTextEditorToolbarUndo = @"com.flightdeskapp.toolbaritem.undo";
static NSString * const ZSSRichTextEditorToolbarRedo = @"com.flightdeskapp.toolbaritem.redo";
static NSString * const ZSSRichTextEditorToolbarViewSource = @"com.flightdeskapp.toolbaritem.viewSource";
static NSString * const ZSSRichTextEditorToolbarParagraph = @"com.flightdeskapp.toolbaritem.paragraph";
static NSString * const ZSSRichTextEditorToolbarAll = @"com.flightdeskapp.toolbaritem.all";
static NSString * const ZSSRichTextEditorToolbarNone = @"com.flightdeskapp.toolbaritem.none";
static NSString * const ZSSRichTextEditorToolbarFonts = @"com.flightdeskapp.toolbaritem.fonts";

@class ZSSBarButtonItem;

/**
 *  The viewController used with ZSSRichTextEditor
 */
@interface ZSSRichTextEditor : UIViewController <UIWebViewDelegate, HRColorPickerViewControllerDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,ZSSFontsViewControllerDelegate>


/**
 *  The base URL to use for the webView
 */
@property (nonatomic, strong) NSURL *baseURL;

/**
 *  If the HTML should be formatted to be pretty
 */
@property (nonatomic) BOOL formatHTML;

/**
 *  If the keyboard should be shown when the editor loads
 */
@property (nonatomic) BOOL shouldShowKeyboard;

/**
 * If the toolbar should always be shown or not
 */
@property (nonatomic) BOOL alwaysShowToolbar;

/**
 * If the sub class recieves text did change events or not
 */
@property (nonatomic) BOOL receiveEditorDidChangeEvents;

/**
 *  The placeholder text to use if there is no editor content
 */
@property (nonatomic, strong) NSString *placeholder;

/**
 *  Toolbar items to include
 */
@property (nonatomic, strong) NSArray *enabledToolbarItems;

/**
 *  Color to tint the toolbar items
 */
@property (nonatomic, strong) UIColor *toolbarItemTintColor;

/**
 *  Color to tint selected items
 */
@property (nonatomic, strong) UIColor *toolbarItemSelectedTintColor;

//Permission for Admin
@property BOOL isAbleToEdit;

/**
 *  Sets the HTML for the entire editor
 *
 *  @param html  HTML string to set for the editor
 *
 */
- (void)setHTML:(NSString *)html;

/**
 *  Returns the HTML from the Rich Text Editor
 *
 */
- (NSString *)getHTML;

/**
 *  Returns the plain text from the Rich Text Editor
 *
 */
- (NSString *)getText;

/**
 *  Inserts HTML at the caret position
 *
 *  @param html  HTML string to insert
 *
 */
- (void)insertHTML:(NSString *)html;

/**
 *  Manually focuses on the text editor
 */
- (void)focusTextEditor;

/**
 *  Manually dismisses on the text editor
 */
- (void)blurTextEditor;

/**
 *  Shows the insert image dialog with optinal inputs
 *
 *  @param url The URL for the image
 *  @param alt The alt for the image
 */
- (void)showInsertImageDialogWithLink:(NSString *)url alt:(NSString *)alt;

/**
 *  Inserts an image
 *
 *  @param url The URL for the image
 *  @param alt The alt attribute for the image
 */
- (void)insertImage:(NSString *)url alt:(NSString *)alt;

/**
 *  Shows the insert link dialog with optional inputs
 *
 *  @param url   The URL for the link
 *  @param title The tile for the link
 */
- (void)showInsertLinkDialogWithLink:(NSString *)url title:(NSString *)title;

/**
 *  Inserts a link
 *
 *  @param url The URL for the link
 *  @param title The title for the link
 */
- (void)insertLink:(NSString *)url title:(NSString *)title;

/**
 *  Gets called when the insert URL picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertURLAlternatePicker;

/**
 *  Gets called when the insert Image picker button is tapped in an alertView
 *
 *  @warning The default implementation of this method is blank and does nothing
 */
- (void)showInsertImageAlternatePicker;

/**
 *  Dismisses the current AlertView
 */
- (void)dismissAlertView;

/**
 *  Add a custom UIBarButtonItem by using a UIButton
 */
- (void)addCustomToolbarItemWithButton:(UIButton*)button;

/**
 *  Add a custom ZSSBarButtonItem
 */
- (void)addCustomToolbarItem:(ZSSBarButtonItem *)item;

/**
 *  Scroll event callback with position
 */
- (void)editorDidScrollWithPosition:(NSInteger)position;

/**
 *  Text change callback with text and html
 */
- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html;

/**
 *  Hashtag callback with word
 */
- (void)hashtagRecognizedWithWord:(NSString *)word;

/**
 *  Mention callback with word
 */
- (void)mentionRecognizedWithWord:(NSString *)word;

/**
 *  Set custom css
 */
- (void)setCSS:(NSString *)css;

@end
