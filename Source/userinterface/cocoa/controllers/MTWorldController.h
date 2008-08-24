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

@class MTCreature;
@class MTInventoryController;
@class MTSoupView;

@interface MTWorldController : NSObject
{
    IBOutlet NSDocument*    document;

    IBOutlet MTSoupView*    mSoupView;
    IBOutlet NSTableView*   mInventoryTableView;

    MacTierra::World*       mWorld;
    
    MTInventoryController*  inventoryController;

    MTCreature*             selectedCreature;
    
    BOOL                    running;
    NSTimer*                mRunTimer;      // hacky
    
    u_int64_t               mLastInstructions;
    CFAbsoluteTime          mLastInstTime;

    double                  instructionsPerSecond;
}

@property (readonly) MTSoupView* soupView;

@property (retain) MTInventoryController* inventoryController;

@property (retain) MTCreature* selectedCreature;

@property (assign) BOOL running;

@property (assign) double instructionsPerSecond;
@property (readonly) double fullness;
@property (readonly) u_int64_t totalInstructions;
@property (readonly) NSInteger numberOfCreatures;

@property (readonly) NSString* playPauseButtonTitle;


- (void)createSoup:(u_int32_t)inSize;
- (void)seedWithAncestor;

- (IBAction)toggleRunning:(id)sender;

- (void)documentClosing;

// save and restore
- (NSData*)worldData;
- (void)setWorldWithData:(NSData*)inData;

- (NSData*)worldXMLData;
- (void)setWorldWithXMLData:(NSData*)inData;

@end
