//
//  MTWorldController.h
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


namespace MacTierra {
    class World;
};

@class MTSoupView;

@interface MTWorldController : NSObject
{
    IBOutlet MTSoupView*    mSoupView;
    MacTierra::World*       mWorld;
    
    BOOL                    mRunning;
    NSTimer*                mRunTimer;      // hacky
}

- (void)createSoup:(u_int32_t)inSize;

- (IBAction)toggleRunning:(id)sender;

@end
