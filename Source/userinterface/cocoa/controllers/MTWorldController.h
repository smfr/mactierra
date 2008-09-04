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
    class PopulationSizeLogger;
    class MeanCreatureSizeLogger;
};

@class MTCreature;
@class MTGraphController;
@class MTInventoryController;
@class MTSoupView;
@class MTWorldThread;
@class MTWorldSettings;

@interface MTWorldController : NSObject
{
    IBOutlet NSDocument*    document;

    IBOutlet MTSoupView*    mSoupView;
    IBOutlet NSTableView*   mInventoryTableView;

    IBOutlet MTInventoryController*  mInventoryController;
    IBOutlet MTGraphController*      mGraphController;
    
    IBOutlet NSTextView*    mCreatureSoupView;
    
    // settings panel
    IBOutlet NSPanel*       mSettingsPanel;

    MTWorldSettings*        worldSettings;
    BOOL                    creatingNewSoup;
    
    MacTierra::World*       mWorld;

    // temp
    MacTierra::PopulationSizeLogger* mPopSizeLogger;
    MacTierra::MeanCreatureSizeLogger* mMeanSizeLogger;
    
    // threading-related
    MTWorldThread*          worldThread;
    NSLock*                 worldLock;
    
    MTCreature*             selectedCreature;
    
    BOOL                    worldRunning;
    NSTimer*                mUpdateTimer;
    
    u_int64_t               mLastInstructions;
    NSInteger               mLastNumCreatures;
    CFAbsoluteTime          mLastInstTime;
    double                  mLastFullness;

    double                  instructionsPerSecond;
}

@property (readonly) NSDocument* document;
@property (readonly) MTSoupView* soupView;

@property (retain) MTCreature* selectedCreature;

// threading
@property (retain) MTWorldThread* worldThread;
@property (retain) NSLock* worldLock;

@property (assign) BOOL worldRunning;

// for settings panel
@property (retain) MTWorldSettings* worldSettings;
@property (assign) BOOL creatingNewSoup;

//@property (readonly) MacTierra::World* world;
// temp. Move to graph controller?
@property (readonly) MacTierra::PopulationSizeLogger* popSizeLogger;
@property (readonly) MacTierra::MeanCreatureSizeLogger* meanSizeLogger;


@property (assign) double instructionsPerSecond;
@property (readonly) double fullness;
@property (readonly) u_int64_t totalInstructions;
@property (readonly) NSInteger numberOfCreatures;

@property (readonly) NSString* playPauseButtonTitle;

- (void)seedWithAncestor;

- (IBAction)editSoupSettings:(id)sender;
- (IBAction)newEmptySoup:(id)sender;
- (IBAction)newSoupShowingSettings:(id)sender;

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


// for settings panel
- (IBAction)zeroMutationRates:(id)sender;
- (IBAction)initializeRandomSeed:(id)sender;

- (IBAction)okSettingsPanel:(id)sender;
- (IBAction)cancelSettingsPanel:(id)sender;

// threading
- (void)lockWorld;
- (void)unlockWorld;

@end
