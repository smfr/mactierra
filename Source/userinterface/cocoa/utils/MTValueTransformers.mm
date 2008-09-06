//
//  MTValueTransformers.mm
//  MacTierra
//
//  Created by Simon Fraser on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTValueTransformers.h"


@implementation MTUnsignedIntValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

// number to string
- (id)transformedValue:(id)inValue
{
    if (!inValue) return nil;
    
    unsigned long val = 0;
    if ([inValue respondsToSelector:@selector(unsignedLongValue)])
    {
        val = [inValue unsignedLongValue];
    }
    else
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -unsignedLongValue.", [inValue class]];
    }
    
    return [NSString stringWithFormat:@"%lu", val];
}


// string to number
- (id)reverseTransformedValue:(id)inValue
{
    if (!inValue) return nil;
    
    unsigned long val = 0;
    if ([inValue respondsToSelector:@selector(UTF8String)])
    {
        val = strtoul([inValue UTF8String], NULL, 10);
    }
    else
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Value (%@) does not respond to -UTF8String.", [inValue class]];
    }
    return [NSNumber numberWithUnsignedLong:val];
}



@end
