//
//  NSCharacterSetAdditions.m
//  MacTierra
//
//  Created by Simon Fraser on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSCharacterSetAdditions.h"


@implementation NSCharacterSet(MTCharacterSetAdditions)

+ (NSCharacterSet*)hexCharacterSet
{
    static NSCharacterSet* sHexSet = nil;
    if (!sHexSet)
        sHexSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] retain];

    return sHexSet;
}

@end
