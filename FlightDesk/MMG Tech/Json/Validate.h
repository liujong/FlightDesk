//
//  Validate.h
//  ValidationCode
//
//  Amit Triforce consultancy on 21/01/12.
//  Copyright 2012 Triforce consultancy . All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Validate : NSObject {
    
}

+(BOOL) isEmpty:(NSString *) candidate;
+(BOOL) isValidEmailAddress:(NSString *) candidate;
+(BOOL) isAlphabetsOnly:(NSString *) candidate;
+(BOOL) isNumbersOnly:(NSString *) candidate;
+(BOOL) isAlphaNumeric:(NSString *) candidate;
+(BOOL) lenghtVaidation:(NSString *) candidate withMinSize:(NSInteger)minSize andMaxSize:(NSInteger)maxSize;
+(BOOL) isValidURL:(NSString *) candidate;
+(BOOL) isValidPhoneNumber:(NSString *) candidate;
+(BOOL) isValidCard:(NSString *) candidate;
+(BOOL) isNotSpecialCharacter:(NSString *) password;
+(BOOL) string:(NSString *)text matches:(NSString *)pattern;
+(BOOL) isValidPattern:(NSString *) candidate;
+(BOOL) isForSpecial:(NSString *) password ;
@end
