//
//  NSViewExtensions.h
//  MacTierra
//
//  Created by Simon Fraser on 1/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSView(MTViewAdditions)

- (NSView*)firstSubview;

- (void)removeAllSubviews;

// subview is sized to fill bounds
- (void)addFullSubview:(NSView*)inSubview replaceExisting:(BOOL)inReplace fill:(BOOL)inFill;

@end
