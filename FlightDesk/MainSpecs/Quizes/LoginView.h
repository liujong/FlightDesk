//
//  LoginView.h
//  FlightDesk
//
//  Created by Gregory Bayard on 2/1/14.
//  Copyright (c) 2014 NOVA.GregoryBayard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginView;

@protocol LoginViewDelegate <NSObject>

@required // Delegate protocols

- (void)loginButtonTappedInLoginView:(LoginView *)loginView username:(NSString *)username password:(NSString *)password;
- (void)registerButtonTappedInLoginView:(LoginView *)loginView;

@end

@interface LoginView : UIView

@property (nonatomic, weak, readwrite) id <LoginViewDelegate> delegate;
@property BOOL isGoneFromRegister;

- (void)animateHide;
- (void)animateShow;

@end
