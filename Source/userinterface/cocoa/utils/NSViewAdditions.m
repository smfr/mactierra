//
//  NSViewExtensions.m
//  MacTierra
//
//  Created by Simon Fraser on 1/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSArrayAdditions.h"

#import "NSViewAdditions.h"


@implementation NSView(MTViewAdditions)

- (NSView*)firstSubview
{
    return [[self subviews] firstObject];
}

- (void)removeAllSubviews
{
    while ([[self subviews] count] > 0)
        [[self firstSubview] removeFromSuperview];
}

// subview is sized to fill bounds
- (void)addFullSubview:(NSView*)inSubview replaceExisting:(BOOL)inReplace fill:(BOOL)inFill
{
    [inSubview retain];
    if (inReplace)
        [self removeAllSubviews];
    
    if (inFill)
    {
        [inSubview setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        [inSubview setFrame:[self bounds]];
    }
    
    [self addSubview:inSubview];
    [inSubview release];
}


@end
