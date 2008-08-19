//
//  MTInstructionCountFormatter.m
//  MacTierra
//
//  Created by Simon Fraser on 8/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTInstructionCountFormatter.h"


@implementation MTInstructionCountFormatter

- (NSString *)stringForObjectValue:(id)inObject
{
    NSString* result = @"";
    
    if ([inObject isKindOfClass:[NSNumber self]])
    {
        double val = [inObject doubleValue];
        
        return [NSString stringWithFormat:@"%.fK", val / 1024.0];
    }
    else
    {
        [NSException exceptionWithName:NSInvalidArgumentException 
						reason:@"MTInstructionCountFormatter got non-NSNumber value"
						userInfo:nil];
    }
    return result;
}

@end
