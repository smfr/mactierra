//
//  MTInstructionsValueTransformer.m
//  MacTierra
//
//  Created by Simon Fraser on 8/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTInstructionsValueTransformer.h"


@implementation MTInstructionsValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    double doubleVal = [value doubleValue];
    
    
}

@end
