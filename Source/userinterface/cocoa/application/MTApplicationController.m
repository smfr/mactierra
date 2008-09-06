//
//  MTApplicationController.m
//  MacTierra
//
//  Created by Simon Fraser on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTApplicationController.h"

#import "MTValueTransformers.h"


@implementation MTApplicationController

+ (void)initialize
{
    // register our value transformers
    MTUnsignedIntValueTransformer* unsignedIntVT = [[[MTUnsignedIntValueTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:unsignedIntVT
                                    forName:@"UnsignedIntValueTransformer"];
}

@end
