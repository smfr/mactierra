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
    class MaxFitnessDataLogger;
    class GenotypeFrequencyDataLogger;
    class SizeHistogramDataLogger;
};

@class MTCreature;
@class MTGraphController;
@class MTInventoryController;
@class MTGenotypeImageView;
@class MTSoupView;
@class MTWorldThread;
@class MTWorldSettings;

class WorldData;
class WorldDataCollectors;

@interface MTWorldController : NSObject
{
    WorldData*              mWorldData;
    
    u_int64_t               mLastInstructions;
    u_int64_t               mLastSlicerCycles;
    NSInteger               mLastNumCreatures;
    CFAbsoluteTime          mLastInstTime;
    double                  mLastFullness;
}

@property (nonatomic, weak) IBOutlet NSDocument* document;
@property (nonatomic, weak) IBOutlet MTSoupView* soupView;

@property (nonatomic, retain) MTCreature* selectedCreature;

@property (retain) MTWorldThread* worldThread;

@property (assign) BOOL worldRunning;

// for settings panel
@property (retain) MTWorldSettings* worldSettings;
@property (assign) BOOL creatingNewSoup;

@property (nonatomic, readonly) MacTierra::World* world;
@property (nonatomic, readonly) const WorldDataCollectors* dataCollectors;

@property (nonatomic, assign) double instructionsPerSecond;
@property (nonatomic, readonly) double fullness;
@property (nonatomic, readonly) u_int64_t totalInstructions;
@property (nonatomic, readonly) u_int64_t slicerCycles;
@property (nonatomic, readonly) NSInteger numberOfCreatures;

@property (nonatomic, readonly) NSString* playPauseButtonTitle;

- (void)seedWithAncestor;

- (IBAction)editSoupSettings:(id)sender;
- (IBAction)newEmptySoup:(id)sender;
- (IBAction)newSoupShowingSettings:(id)sender;

- (IBAction)toggleRunning:(id)sender;
- (IBAction)step:(id)sender;

- (IBAction)exportInventory:(id)sender;

- (void)documentClosing;
- (void)clearWorld;

// save and restore
- (BOOL)readWorldFromBinaryFile:(NSURL*)inFileURL;
- (BOOL)readWorldFromXMLFile:(NSURL*)inFileURL;

- (BOOL)writeWorldToBinaryFile:(NSURL*)inFileURL;
- (BOOL)writeWorldToXMLFile:(NSURL*)inFileURL;

- (BOOL)writeSoupConfigurationToXMLFile:(NSURL*)inFileURL;

// for settings panel
- (IBAction)zeroMutationRates:(id)sender;
- (IBAction)initializeRandomSeed:(id)sender;

- (IBAction)okSettingsPanel:(id)sender;
- (IBAction)cancelSettingsPanel:(id)sender;

// threading
- (void)lockWorld;
- (void)unlockWorld;

@end
