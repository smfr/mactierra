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
@class MTInventoryController;

@interface MTWorldController : NSObject
{
    IBOutlet MTSoupView*    mSoupView;
    IBOutlet NSTableView*   mInventoryTableView;

    MacTierra::World*       mWorld;
    
    MTInventoryController*  inventoryController;
    
    BOOL                    running;
    NSTimer*                mRunTimer;      // hacky
    
    u_int64_t               mLastInstructions;
    CFAbsoluteTime          mLastInstTime;

    double                  instructionsPerSecond;
}

@property (readonly) MTSoupView* soupView;

@property (retain) MTInventoryController* inventoryController;

@property (assign) BOOL running;

@property (assign) double instructionsPerSecond;
@property (readonly) double fullness;
@property (readonly) u_int64_t totalInstructions;
@property (readonly) NSInteger numberOfCreatures;

@property (readonly) NSString* playPauseButtonTitle;

- (void)createSoup:(u_int32_t)inSize;

- (IBAction)toggleRunning:(id)sender;

- (void)documentClosing;

@end
