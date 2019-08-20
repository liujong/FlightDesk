//
//  Validate.m
//  ValidationCode
//
//  Amit Triforce consultancy on 21/01/12.
//  Copyright 2012 Triforce consultancy . All rights reserved.
//

#import "Validate.h"

#define kMagicSubtractionNumber 48

@implementation Validate

+(BOOL) isEmpty:(NSString *) candidate {
	BOOL isEmplt = NO;
	candidate = [candidate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	//NSLog(@"%@",candidate);
	if ([candidate isEqual:@""]) {
		isEmplt = YES;
	} else if ([candidate isEqual:nil]) {
		isEmplt = YES;
	} else if ([candidate isEqual:[NSNull null]]) {
		isEmplt = YES;
	} else if ([candidate length] == 0) {
		isEmplt = YES;
	}
	return isEmplt;
}

+(BOOL) isValidEmailAddress:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"; 
		NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
		
		return [emailTest evaluateWithObject:candidate];
	}
	return NO;
}

+(BOOL) isValidPattern:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *emailRegex = @"[A-Z0-9a-z]{8}+\\-[A-Z0-9a-z]{4}+\\-[A-Z0-9a-z]{4}+\\-[A-Z0-9a-z]{4}+\\-[A-Z0-9a-z]{12}"; 
		NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
		
		return [emailTest evaluateWithObject:candidate];
	}
	return NO;
}

+(BOOL) isAlphabetsOnly:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *alphaRegex = @"^\\s*([A-Za-z ]*)\\s*$"; 
		NSPredicate *alphaTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", alphaRegex]; 
		
		return [alphaTest evaluateWithObject:candidate];
	}
	return NO;
}

+(BOOL) isNumbersOnly:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *numberRegex = @"^\\s*([0-9]*)\\s*$"; 
		NSPredicate *numberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", numberRegex]; 
		
		return [numberTest evaluateWithObject:candidate];
	}
	return NO;
}
+(BOOL) isNotSpecialCharacter:(NSString *) password {
    if (![self isEmpty:password]) {
        NSString *scPattern = @"[a-z]";
        NSString *cPattern = @"[A-Z]";
        NSString *sPattern = @"[!%@&._;]";
        NSString *nPattern = @"[0-9]";
        
        if ([self string:password matches:scPattern] &&
            [self string:password matches:cPattern] &&
            [self string:password matches:sPattern] &&
            [self string:password matches:nPattern])
        {
            return  YES;
        }
        else
            return NO;
        
    }
    return NO;
}

+(BOOL) isForSpecial:(NSString *) password {
    if (![self isEmpty:password]) {
        NSString *sPattern = @"['\"]";

        
        if ([self string:password matches:sPattern])
        {
            return  YES;
        }
        else
            return NO;
        
    }
    return NO;
}

+(BOOL) string:(NSString *)text matches:(NSString *)pattern
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    NSLog(@"Arr=%@",matches);
    return matches.count > 0;
}

+(BOOL) isAlphaNumeric:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *alphaNumberRegex = @"^\\s*([A-Z0-9a-z ]*)\\s*$"; 
		NSPredicate *alphaNumberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", alphaNumberRegex]; 
		
		return [alphaNumberTest evaluateWithObject:candidate];
	}
	return NO;
}

+(BOOL) lenghtVaidation:(NSString *) candidate withMinSize:(NSInteger)minSize andMaxSize:(NSInteger)maxSize {
	if (![self isEmpty:candidate]) {
		if ([candidate length] >= minSize && [candidate length] <= maxSize) {
			return YES;
		}
	}
	return NO;
}

+(BOOL) isValidURL:(NSString *) candidate {
	
	if (![self isEmpty:candidate]) {
		NSString *urlRegEx = @"((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?";
		NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx]; 
		return [urlTest evaluateWithObject:candidate];
	}
	
	return NO;
}

+ (BOOL) isValidPhoneNumber:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		NSString *phoneRegex = @"^\\s*([0-9-+ ]*)\\s*$"; 
		NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex]; 
		
		return [phoneTest evaluateWithObject:candidate];
	}
	return NO;
}


+(BOOL) isValidCard:(NSString *) candidate {
	if (![self isEmpty:candidate]) {
		
		int Luhn = 0;
		
		// I'm running through my string backwards
		for (int i=0;i<[candidate length];i++)
        {
            NSUInteger count = [candidate length]-1; // Prevents Bounds Error and makes characterAtIndex easier to read
			int doubled = [[NSNumber numberWithUnsignedChar:[candidate characterAtIndex:count-i]] intValue] - kMagicSubtractionNumber;
            if (i % 2)
            {doubled = doubled*2;}
            
			NSString *double_digit = [NSString stringWithFormat:@"%d",doubled];
			
            if ([[NSString stringWithFormat:@"%d",doubled] length] > 1)
			{   Luhn = Luhn + [[NSNumber numberWithUnsignedChar:[double_digit characterAtIndex:0]] intValue]-kMagicSubtractionNumber;
                Luhn = Luhn + [[NSNumber numberWithUnsignedChar:[double_digit characterAtIndex:1]] intValue]-kMagicSubtractionNumber;}
            else
			{Luhn = Luhn + doubled;}
        }
		
		if (Luhn%10 == 0) // If Luhn/10's Remainder is Equal to Zero, the number is valid
            return true;
		else
			return false;
		
	}
	return NO;
}


@end
