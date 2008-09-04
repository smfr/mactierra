//
//  NSAttributedStringAdditions.h
//  MacTierra
//
//  Created by Simon Fraser on 9/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAttributedString(MTAttributedStringAdditions)

+ (id)attributedString;
+ (id)attributedStringWithString:(NSString*)inString;
+ (id)attributedStringWithString:(NSString*)inString attributes:(NSDictionary*)inAttributes;

@end



@interface NSMutableAttributedString(MTMutableAttributedStringAdditions)

+ (id)attributedString;
+ (id)attributedStringWithString:(NSString*)inString attributes:(NSDictionary*)inAttributes;

- (void)appendFormatWithAttributes:(NSDictionary*)inAttributes format:(NSString*)inFormat, ...;
- (void)appendFormatListWithAttributes:(NSDictionary*)inAttributes format:(NSString*)inFormat vaList:(va_list)inArgList;
- (void)appendString:(NSString*)inString attributes:(NSDictionary*)inAttributes;
- (void)empty;

@end
