//
//  MTGraphController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTWorldController;

@interface MTGraphController : NSObject
{
    IBOutlet MTWorldController*  mWorldController;
    IBOutlet NSView*    mGraphContainerView;

    // temp
    NSValue*            mDataValue;
    u_int32_t           mCollectionInterval;
    
    NSArray*            mGraphTypes;
}

@property (readonly) NSArray* availableGraphTypes;

- (void)updateGraph;

@end
