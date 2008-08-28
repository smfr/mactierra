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
@class MTSoupSettingsPanelController;

@interface MTWorldController : NSObject
{
    IBOutlet NSDocument*    document;

    IBOutlet MTSoupView*    mSoupView;
    IBOutlet NSTableView*   mInventoryTableView;

    IBOutlet MTInventoryController*  mInventoryController;
    IBOutlet MTSoupSettingsPanelController*  mSoupSettingsPanelController;

    IBOutlet NSTextView*    mCreatureSoupView;
    
    MacTierra::World*       mWorld;

    MTCreature*             selectedCreature;
    
    BOOL                    running;
    NSTimer*                mRunTimer;      // hacky
    
    u_int64_t               mLastInstructions;
    CFAbsoluteTime          mLastInstTime;

    double                  instructionsPerSecond;
}

@property (readonly) NSDocument* document;
@property (readonly) MTSoupView* soupView;

@property (retain) MTCreature* selectedCreature;

@property (assign) BOOL running;

@property (readonly) MacTierra::World* world;

@property (assign) double instructionsPerSecond;
@property (readonly) double fullness;
@property (readonly) u_int64_t totalInstructions;
@property (readonly) NSInteger numberOfCreatures;

@property (readonly) NSString* playPauseButtonTitle;

- (void)createSoup:(u_int32_t)inSize;
- (void)seedWithAncestor;

- (IBAction)showSettings:(id)sender;

- (IBAction)toggleRunning:(id)sender;
- (IBAction)step:(id)sender;

- (IBAction)exportInventory:(id)sender;


- (void)documentClosing;

// save and restore
- (NSData*)worldData;
- (void)setWorldWithData:(NSData*)inData;

- (NSData*)worldXMLData;
- (void)setWorldWithXMLData:(NSData*)inData;


- (BOOL)writeBinaryDataToFile:(NSURL*)inFileURL;
- (BOOL)readWorldFromBinaryFile:(NSURL*)inFileURL;

- (BOOL)writeXMLDataToFile:(NSURL*)inFileURL;
- (BOOL)readWorldFromXMLFile:(NSURL*)inFileURL;




@end
