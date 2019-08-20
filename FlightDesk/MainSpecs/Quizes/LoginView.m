//
//  LoginView.m
//  FlightDesk
//
//  Created by Gregory Bayard on 2/1/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import "LoginView.h"

@interface LoginView () <UITextFieldDelegate>

@end

@implementation LoginView
{
    UIView *theDialogView;
    
	UIView *theContentView;
    
	UIToolbar *theToolbar;
    
	UILabel *theTitleLabel;
    
    UILabel *theUsernameLabel;
    UILabel *thePasswordLabel;
    
	UITextField *theUsernameField;
    UITextField *thePasswordField;
    
    UIBarButtonItem *theLoginButton;
    UIBarButtonItem *theRegisterButton;
    
	NSInteger visibleCenterY;
	NSInteger hiddenCenterY;
}

#pragma mark Constants

#define TITLE_X 80.0f
#define TITLE_Y 12.0f
#define TITLE_HEIGHT 20.0f

#define TEXT_FIELD_HEIGHT 27.0f

#define STATUS_LABEL_Y 118.0f
#define STATUS_LABEL_HEIGHT 20.0f

#define LABEL_X 16.0f
#define FIELD_X 118.0f

#define USERNAME_Y 65.0f
#define PASSWORD_Y 105.0f

#define TOOLBAR_HEIGHT 44.0f

#define DIALOG_WIDTH_LARGE 448.0f
#define DIALOG_WIDTH_SMALL 304.0f
#define DIALOG_HEIGHT 152.0f

#define TEXT_LENGTH_LIMIT 128

#define DEFAULT_DURATION 0.3

@synthesize delegate;
@synthesize isGoneFromRegister;
#pragma mark LoginView instance methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.autoresizesSubviews = YES;
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.36f]; // View tint
		self.hidden = YES; self.alpha = 0.0f; // Start hidden a
        
        
		BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
        
		visibleCenterY = (large ? (DIALOG_HEIGHT * 1.25f) : (DIALOG_HEIGHT - (TOOLBAR_HEIGHT / 2.0f)));
        
		CGFloat dialogWidth = (large ? DIALOG_WIDTH_LARGE : DIALOG_WIDTH_SMALL); // Dialog width
        
		CGFloat dialogY = (0.0f - DIALOG_HEIGHT); // Start off screen
		CGFloat dialogX = ((self.bounds.size.width - dialogWidth) / 2.0f);
		CGRect dialogRect = CGRectMake(dialogX, dialogY, dialogWidth, DIALOG_HEIGHT);
        
		theDialogView = [[UIView alloc] initWithFrame:dialogRect];
        hiddenCenterY = theDialogView.center.y;
        
		theDialogView.autoresizesSubviews = NO;
		theDialogView.contentMode = UIViewContentModeRedraw;
		theDialogView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		theDialogView.backgroundColor = [UIColor clearColor];
        
		theDialogView.layer.shadowRadius = 3.0f;
		theDialogView.layer.shadowOpacity = 1.0f;
		theDialogView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
		theDialogView.layer.shadowPath = [UIBezierPath bezierPathWithRect:theDialogView.bounds].CGPath;
        
		theContentView = [[UIView alloc] initWithFrame:theDialogView.bounds];
        
		theContentView.autoresizesSubviews = NO;
		theContentView.contentMode = UIViewContentModeRedraw;
		theContentView.autoresizingMask = UIViewAutoresizingNone;
		theContentView.backgroundColor = [UIColor whiteColor];
        
		CGRect toolbarRect = theContentView.bounds; toolbarRect.size.height = TOOLBAR_HEIGHT;
        
		theToolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
		theToolbar.autoresizingMask = UIViewAutoresizingNone;
		theToolbar.barStyle = UIBarStyleBlack;
		theToolbar.translucent = YES;
        
		UIBarButtonItem *loginButton =	[[UIBarButtonItem alloc]
                                         initWithTitle:NSLocalizedString(@"Login", @"button")
                                         style:UIBarButtonItemStyleDone
                                         target:self action:@selector(loginButtonTapped:)];
        UIBarButtonItem *registerButton =	[[UIBarButtonItem alloc]
                                         initWithTitle:NSLocalizedString(@"Register", @"button")
                                         style:UIBarButtonItemStyleDone
                                         target:self action:@selector(registerButtonTapped:)];
		theLoginButton = loginButton;
        theRegisterButton = registerButton;
        
        loginButton.enabled = NO; // Disable button
        
		UIBarButtonItem *flexiSpace =	[[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                         target:nil action:NULL];
        if (isGoneFromRegister) {
            theToolbar.items = [NSArray arrayWithObjects:flexiSpace, loginButton, nil];
        }else{
            theToolbar.items = [NSArray arrayWithObjects:registerButton, flexiSpace, loginButton, nil];
        }
        
		[theContentView addSubview:theToolbar]; // Add toolbar to view
        
		CGFloat titleWidth = (theToolbar.bounds.size.width - (TITLE_X + TITLE_X));
        
		CGRect titleRect = CGRectMake(TITLE_X, TITLE_Y, titleWidth, TITLE_HEIGHT);
        
		theTitleLabel = [[UILabel alloc] initWithFrame:titleRect];
        
		theTitleLabel.textAlignment = NSTextAlignmentCenter;
		theTitleLabel.backgroundColor = [UIColor clearColor];
		theTitleLabel.font = [UIFont systemFontOfSize:17.0f];
		theTitleLabel.textColor = [UIColor whiteColor];
		theTitleLabel.adjustsFontSizeToFitWidth = YES;
		theTitleLabel.minimumScaleFactor = 0.75f;
        theTitleLabel.text = @"Login Required";
        
		[theContentView addSubview:theTitleLabel]; // Add label to view
        
        CGFloat baseWidth = theContentView.bounds.size.width / 3;
        CGFloat fieldWidth = (2 * baseWidth) - LABEL_X - LABEL_X;
        CGFloat labelWidth = baseWidth - LABEL_X - LABEL_X;
        
        // username entry
        CGRect usernameLabelRect = CGRectMake(LABEL_X, USERNAME_Y, labelWidth, STATUS_LABEL_HEIGHT);
        
		theUsernameLabel = [[UILabel alloc] initWithFrame:usernameLabelRect];
        
		theUsernameLabel.textAlignment = NSTextAlignmentCenter;
		theUsernameLabel.backgroundColor = [UIColor clearColor];
		theUsernameLabel.font = [UIFont systemFontOfSize:16.0f];
		theUsernameLabel.textColor = [UIColor grayColor];
		theUsernameLabel.adjustsFontSizeToFitWidth = YES;
		theUsernameLabel.minimumScaleFactor = 0.75f;
        theUsernameLabel.text = @"Username";
        
		[theContentView addSubview:theUsernameLabel];
        
		CGRect usernameFieldRect = CGRectMake(FIELD_X, USERNAME_Y, fieldWidth, TEXT_FIELD_HEIGHT);
        
		theUsernameField = [[UITextField alloc] initWithFrame:usernameFieldRect];
        
		theUsernameField.returnKeyType = UIReturnKeyDone;
		theUsernameField.enablesReturnKeyAutomatically = YES;
		theUsernameField.autocorrectionType = UITextAutocorrectionTypeNo;
		theUsernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		theUsernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
		theUsernameField.borderStyle = UITextBorderStyleRoundedRect;
		theUsernameField.font = [UIFont systemFontOfSize:17.0f];
		theUsernameField.delegate = self;
        
		[theContentView addSubview:theUsernameField]; // Add text field to view
        
        // password entry
        CGRect passwordLabelRect = CGRectMake(LABEL_X, PASSWORD_Y - 4, labelWidth, STATUS_LABEL_HEIGHT);
        
		thePasswordLabel = [[UILabel alloc] initWithFrame:passwordLabelRect];
        
		thePasswordLabel.textAlignment = NSTextAlignmentCenter;
		thePasswordLabel.backgroundColor = [UIColor clearColor];
		thePasswordLabel.font = [UIFont systemFontOfSize:16.0f];
		thePasswordLabel.textColor = [UIColor grayColor];
		thePasswordLabel.adjustsFontSizeToFitWidth = YES;
		thePasswordLabel.minimumScaleFactor = 0.75f;
        thePasswordLabel.text = @"Password";
        
		[theContentView addSubview:thePasswordLabel];
        
        CGRect passwordFieldRect = CGRectMake(FIELD_X, PASSWORD_Y - 4, fieldWidth, TEXT_FIELD_HEIGHT);
        
		thePasswordField = [[UITextField alloc] initWithFrame:passwordFieldRect];
        
		thePasswordField.returnKeyType = UIReturnKeyDone;
		thePasswordField.enablesReturnKeyAutomatically = YES;
		thePasswordField.autocorrectionType = UITextAutocorrectionTypeNo;
		thePasswordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		thePasswordField.clearButtonMode = UITextFieldViewModeWhileEditing;
		thePasswordField.borderStyle = UITextBorderStyleRoundedRect;
		thePasswordField.font = [UIFont systemFontOfSize:17.0f];
        thePasswordField.secureTextEntry = YES;
		thePasswordField.delegate = self;
        
		[theContentView addSubview:thePasswordField]; // Add text field to view
        
		[theDialogView addSubview:theContentView];
        
		[self addSubview:theDialogView];
	}
    
	return self;
}

- (void)animateHide
{
	if (self.hidden == NO) // Visible
	{
		self.userInteractionEnabled = NO;
        
		[theUsernameField resignFirstResponder]; // Hide keyboard
        
		[UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.alpha = 0.0f; // Fade out
             
             CGPoint location = theDialogView.center;
             location.y = hiddenCenterY; // Off screen Y
             theDialogView.center = location;
         }
                         completion:^(BOOL finished)
         {
             self.hidden = YES;
         }
         ];
	}
}

- (void)animateShow
{
	if (self.hidden == YES) // Hidden
	{
		self.hidden = NO; // Show hidden views
        
		[UIView animateWithDuration:DEFAULT_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^(void)
         {
             self.alpha = 1.0f; // Fade in
             
             CGPoint location = theDialogView.center;
             location.y = visibleCenterY; // On screen Y
             theDialogView.center = location;
         }
                         completion:^(BOOL finished)
         {
             self.userInteractionEnabled = YES;
         }
         ];
        
		[theUsernameField becomeFirstResponder]; // Show keyboard
	}
}

- (void)tryLogin
{
    NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
	NSString *theUsername = [theUsernameField.text stringByTrimmingCharactersInSet:trimSet];
    NSString *thePassword = [thePasswordField.text stringByTrimmingCharactersInSet:trimSet];
    
	// check the password
    NSLog(@"GREGDEBUG user %@ pass %@", theUsername, thePassword);
    
    if ([delegate respondsToSelector:@selector(loginButtonTappedInLoginView:username:password:)] == YES)
	{
		[delegate loginButtonTappedInLoginView:self username:theUsername password:thePassword];
	}
	else
	{
		NSAssert(NO, @"Delegate must respond to -loginButtonTappedInLoginView:");
	}

}

#pragma mark UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSInteger insertDelta = (string.length - range.length);
    
	NSInteger editedLength = (textField.text.length + insertDelta);
    
	theLoginButton.enabled = ((editedLength > 0) ? YES : NO); // Button state
    
	if (editedLength > TEXT_LENGTH_LIMIT) // Limit input text field to length
	{
		if (string.length == 1) // Check for return as the final character
		{
			NSCharacterSet *newLines = [NSCharacterSet newlineCharacterSet];
            
			NSRange rangeOfCharacterSet = [string rangeOfCharacterFromSet:newLines];
            
			if (rangeOfCharacterSet.location != NSNotFound) return TRUE;
		}
        
		return FALSE;
	}
	else
		return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // TODO: consider trimming characters
    //NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (textField == theUsernameField) {
        //theUsernameField.text = [theUsernameField.text stringByTrimmingCharactersInSet:trimSet];
        [thePasswordField becomeFirstResponder];
        return NO;
    } else if (textField == thePasswordField) {
        //thePasswordField.text = [thePasswordField.text stringByTrimmingCharactersInSet:trimSet];
        [self tryLogin];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	theLoginButton.enabled = NO; // Disable button
    
	return YES;
}

#pragma mark UIBarButtonItem action methods

- (void)loginButtonTapped:(id)sender
{
	[self tryLogin];
}

- (void)registerButtonTapped:(id)sender{
    [self animateHide];
}

@end
