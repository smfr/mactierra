//
//  MTWorldController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldController.h"

#import <fstream>

#import <RandomLib/RandomSeed.hpp>

#include <boost/archive/xml_oarchive.hpp>
#include <boost/serialization/serialization.hpp>

#import "MTSoupView.h"

#import "MT_Cellmap.h"
#import "MT_Inventory.h"
#import "MT_InventoryListener.h"
#import "MT_SoupConfiguration.h"
#import "MT_World.h"

#import "MTCreature.h"
#import "MT_DataCollection.h"
#import "MT_DataCollectors.h"

#import "MTGraphController.h"
#import "MTGenebankController.h"
#import "MTInventoryController.h"
#import "MTWorldDataCollection.h"
#import "MTWorldSettings.h"

using namespace MacTierra;

@interface MTWorldController(Private)

- (void)startUpdateTimer;
- (void)stopUpdateTimer;
- (void)setRunning:(BOOL)inRunning;
- (void)setWorld:(World*)inWorld;

- (void)updateSoup;
- (void)updateGenotypes;
- (void)updateDebugPanel;
- (void)updateDisplay;

- (void)terminateWorldThread;
- (void)createWorldThread;
- (void)runWorld;
- (void)pauseWorld;
- (void)iterate:(NSUInteger)inNumCycles;

@end

#pragma mark -

@interface MTWorldThread : NSThread
{
    MTWorldController*  mWorldController;       // not retained
    NSCondition*        runningCondition;
    BOOL                running;
}

- (id)initWithWorldController:(MTWorldController*)inController;

@property (retain) NSCondition* runningCondition;
@property (assign) BOOL running;

- (void)run;
- (void)pause;

- (void)lock;
- (void)unlock;

@end

#pragma mark -

@implementation MTWorldController

@synthesize document;
@synthesize worldRunning;
@synthesize instructionsPerSecond;
@synthesize selectedCreature;

@synthesize worldSettings;
@synthesize creatingNewSoup;
@synthesize worldThread;

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObject:@"worldRunning"]
                                triggerChangeNotificationsForDependentKey:@"playPauseButtonTitle"];
}

- (id)init
{
    if ((self = [super init]))
    {
        mWorldData = new WorldData();
    }
    return self;
}

- (void)dealloc
{
    self.selectedCreature = nil;
    [mSoupView setWorld:NULL];
    [mSoupView release];
    
    delete mWorldData;

    [super dealloc];
}

- (void)awakeFromNib
{
    [mSoupView retain];
}

- (MTSoupView*)soupView
{
    return mSoupView;
}

- (void)setWorld:(World*)inWorld
{
    if (inWorld != mWorldData->world())
    {
        [self terminateWorldThread];
        
        [mSoupView setWorld:nil];
        [mInventoryController setInventory:nil];

        mWorldData->setWorld(inWorld);
        [mSoupView setWorld:mWorldData->world()];
        
        if (mWorldData->world())
            [self createWorldThread];
        
        [mInventoryController setInventory:mWorldData->world() ? mWorldData->world()->inventory() : NULL];

        [mGraphController worldChanged];
        [self updateGenotypes];
        [self updateDisplay];
    }
}

- (void)seedWithAncestor
{
    mWorldData->seedWithAncestor();
}

- (IBAction)toggleRunning:(id)sender
{
    [self setRunning:!worldRunning];
}

- (IBAction)step:(id)sender
{
    if (self.selectedCreature)
    {
        mWorldData->stepCreature(selectedCreature.creature);
        [self updateSoup];
        [self updateDebugPanel];
        [document updateChangeCount:NSChangeDone];
    }
}

- (IBAction)exportInventory:(id)sender
{
    NSSavePanel*    savePanel = [NSSavePanel savePanel];
    
    [savePanel beginSheetForDirectory:nil
                                 file:@"Inventory.txt"
                       modalForWindow:[document windowForSheet]
                        modalDelegate:self
                       didEndSelector:@selector(exportInventorySavePanelDidDne:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (void)exportInventorySavePanelDidDne:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (mWorldData->world() && returnCode == NSOKButton)
    {
        [self lockWorld];
        NSString* filePath = [sheet filename];
        
        std::ofstream outFileStream([filePath fileSystemRepresentation]);
        mWorldData->writeInventory(outFileStream);
        [self unlockWorld];
    }
}

- (NSString*)playPauseButtonTitle
{
    return worldRunning ? NSLocalizedString(@"RunningButtonTitle", @"Pause") : NSLocalizedString(@"PausedButtonTitle", @"Continue");
}

- (MacTierra::World*)world
{
    return mWorldData->world();
}

- (WorldDataCollectors*)dataCollectors
{
    return mWorldData->dataCollectors();
}

- (double)fullness
{
    return mLastFullness;
}

- (u_int64_t)totalInstructions
{
    return mLastInstructions;
}

- (NSInteger)numberOfCreatures
{
    return mLastNumCreatures;
}

- (void)documentClosing
{
    [self clearWorld];
}

- (void)clearWorld
{
    // have to break ref cycles
    [self setRunning:NO];    

    [self setWorld:NULL];
    self.selectedCreature = nil;
}

#pragma mark -

- (void)setRunning:(BOOL)inRunning
{
    if (inRunning == worldRunning)
        return;

    if (inRunning)
    {
        [self startUpdateTimer];
        [self runWorld];
        self.worldRunning = YES;
    }
    else
    {
        [self stopUpdateTimer];
        [self pauseWorld];
        self.worldRunning = NO;

        // hack to update genotypes on pause
        [self updateGenotypes];
        [self updateDebugPanel];
    }
}

- (void)startUpdateTimer
{
    const NSTimeInterval kUpdateInterval = 0.25;
    mUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:kUpdateInterval
                                                  target:self
                                                selector:@selector(updateTimerFired:)
                                                userInfo:nil
                                                 repeats:YES] retain];       // retain cycle

    mLastInstTime = CFAbsoluteTimeGetCurrent();
    mLastInstructions = mWorldData->instructionsExecuted();
}

- (void)stopUpdateTimer
{
    [mUpdateTimer invalidate];
    [mUpdateTimer release];
    mUpdateTimer = nil;
}

- (void)updateTimerFired:(NSTimer*)inTimer
{
    [self updateDisplay];
    [document updateChangeCount:NSChangeDone];
}

- (void)updateDisplay
{
    if (!mWorldData->world()) return;

    [self willChangeValueForKey:@"fullness"];
    [self willChangeValueForKey:@"totalInstructions"];
    [self willChangeValueForKey:@"numberOfCreatures"];
    
    [self lockWorld];
    {
        u_int64_t curInstructions = mWorldData->instructionsExecuted();
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

        self.instructionsPerSecond = (double)(curInstructions - mLastInstructions) / (currentTime - mLastInstTime);
        
        mLastInstructions = curInstructions;
        mLastNumCreatures = mWorldData->world()->cellMap()->numCreatures();
        mLastFullness = mWorldData->world()->cellMap()->fullness();
        
        [self updateSoup];
        
        // hack to avoid slowing things down too much
        if ([mInventoryTableView window])
            [self updateGenotypes];

        [mGraphController updateGraph];

        mLastInstTime = CFAbsoluteTimeGetCurrent();
    }
    [self unlockWorld];

    [self didChangeValueForKey:@"fullness"];
    [self didChangeValueForKey:@"totalInstructions"];
    [self didChangeValueForKey:@"numberOfCreatures"];
}

- (void)updateSoup
{
    [mSoupView setNeedsDisplay:YES];
}

- (void)updateGenotypes
{
    [mInventoryController updateGenotypesArray];
}

- (void)updateDebugPanel
{
    // hack
    MTCreature* oldSelectedCreature = [self.selectedCreature retain];
    self.selectedCreature = nil;
    self.selectedCreature = oldSelectedCreature;
    [oldSelectedCreature release];
    
    // FIXME: need to do this on setSelectedCreature too
    if (selectedCreature)
        [mCreatureSoupView setSelectedRanges:[NSArray arrayWithObject:[NSValue valueWithRange:selectedCreature.soupSelectionRange]]];
}

#pragma mark -

// Settings panel
- (IBAction)editSoupSettings:(id)sender
{
    NSAssert(mWorldData->world(), @"Should have world already");

    self.creatingNewSoup = NO;

    self.worldSettings = [[[MTWorldSettings alloc] initWithSettings:mWorldData->world()->settings()] autorelease];
    self.worldSettings.soupSize = mWorldData->world()->soupSize();
    self.worldSettings.randomSeed = mWorldData->world()->initialRandomSeed();
    
    [NSApp beginSheet:mSettingsPanel
       modalForWindow:[document windowForSheet]
        modalDelegate:self
       didEndSelector:@selector(soupSettingsPanelDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)newEmptySoup:(id)sender
{
    const u_int32_t kEmptySoupSize = 256 * 1024;
    MacTierra::World* newWorld = new World();
    newWorld->setSettings(MacTierra::Settings::zeroMutationSettings());
    newWorld->initializeSoup(kEmptySoupSize);
    [self setWorld:newWorld];
}

- (IBAction)newSoupShowingSettings:(id)sender
{
    self.creatingNewSoup = YES;

    self.worldSettings = [[[MTWorldSettings alloc] initWithSettings:MacTierra::Settings::mediumMutationSettings(256 * 1024)] autorelease];
    self.worldSettings.creatingNewSoup = YES;
    self.worldSettings.soupSizePreset = k256K;
    self.worldSettings.seedWithAncestor = YES;

    [NSApp beginSheet:mSettingsPanel
       modalForWindow:[document windowForSheet]
        modalDelegate:self
       didEndSelector:@selector(soupSettingsPanelDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)soupSettingsPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
    
    if (returnCode == NSOKButton)
    {
        const MacTierra::Settings* theSettings = worldSettings.settings;
        BOOST_ASSERT(theSettings);

        if (self.creatingNewSoup)
        {
            BOOST_ASSERT(!mWorldData->world());
            
            MacTierra::World* newWorld = new World();
            newWorld->setInitialRandomSeed(self.worldSettings.randomSeed);
            newWorld->setSettings(*worldSettings.settings);
            
            newWorld->initializeSoup(worldSettings.soupSize);
            [self setWorld:newWorld];
            
            if (worldSettings.seedWithAncestor)
                [self seedWithAncestor];
        }
        else
        {
            mWorldData->world()->setSettings(*theSettings);
        }
    }
    else
    {
        if (self.creatingNewSoup)
        {
            [document performSelector:@selector(close) withObject:nil afterDelay:0];
        }
    }
    
    self.worldSettings = nil;
}

- (IBAction)zeroMutationRates:(id)sender
{
    worldSettings.cosmicRate = 0.0;
    worldSettings.flawRate = 0.0;
    worldSettings.copyErrorRate = 0.0;
}

- (IBAction)initializeRandomSeed:(id)sender
{
    self.worldSettings.randomSeed = RandomLib::RandomSeed::SeedWord();
}

- (IBAction)okSettingsPanel:(id)sender
{
    [NSApp endSheet:mSettingsPanel returnCode:NSOKButton];
}

- (IBAction)cancelSettingsPanel:(id)sender
{
    [NSApp endSheet:mSettingsPanel returnCode:NSCancelButton];
}

#pragma mark -

- (void)createWorldThread
{
    self.worldThread = [[MTWorldThread alloc] initWithWorldController:self];
    [worldThread start];
}

- (void)terminateWorldThread
{
    if (worldThread)
    {
        [worldThread run];
        [worldThread cancel];
        while (![worldThread isFinished])
            [NSThread sleepForTimeInterval:0.001];
        self.worldThread = nil;
    }
}

- (void)runWorld
{
    [worldThread run];
}

- (void)pauseWorld
{
    [worldThread pause];
}

- (void)iterate:(NSUInteger)inNumCycles
{
    if (mWorldData->world())
        mWorldData->world()->iterate(inNumCycles);
}

- (void)lockWorld
{
    [worldThread lock];
}

- (void)unlockWorld
{
    [worldThread unlock];
}

#pragma mark -

- (NSData*)worldData
{
    if (!mWorldData->world())
        return nil;

//    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    std::ostringstream stringStream;
    [self lockWorld];
        World::worldToStream(mWorldData->world(), stringStream, World::kBinary);
    [self unlockWorld];

//    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
//    NSLog(@"Serializaing world took %f milliseconds", (endTime - startTime) * 1000.0);

    return [NSData dataWithBytes:stringStream.str().data() length:stringStream.str().length()];
}

- (void)setWorldWithData:(NSData*)inData
{
    std::string worldString((const char*)[inData bytes], [inData length]);
    std::istringstream stringStream(worldString);

    World* newWorld = World::worldFromStream(stringStream, World::kBinary);

    [self setWorld:newWorld];
}

- (NSData*)worldXMLData
{
    if (!mWorldData->world())
        return nil;

    std::ostringstream stringStream;
    [self lockWorld];
        World::worldToStream(mWorldData->world(), stringStream, World::kXML);
    [self unlockWorld];

    return [NSData dataWithBytes:stringStream.str().data() length:stringStream.str().length()];
}

- (void)setWorldWithXMLData:(NSData*)inData
{
    std::string worldString((const char*)[inData bytes], [inData length]);

    std::istringstream stringStream(worldString);
    World* newWorld = World::worldFromStream(stringStream, World::kXML);

    [self setWorld:newWorld];
}

#pragma mark -

static BOOL filePathFromURL(NSURL* inURL, std::string& outPath)
{
    if (![inURL isFileURL])
        return NO;

    outPath = [[inURL path] fileSystemRepresentation];
    return YES;
}

- (BOOL)writeBinaryDataToFile:(NSURL*)inFileURL
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ofstream fileStream(filePath.c_str());

    [self lockWorld];
        World::worldToStream(mWorldData->world(), fileStream, World::kBinary);
    [self unlockWorld];

    return YES;
}

- (BOOL)readWorldFromBinaryFile:(NSURL*)inFileURL
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ifstream fileStream(filePath.c_str());
    World* newWorld = World::worldFromStream(fileStream, World::kBinary);
    [self setWorld:newWorld];

    return YES;
}

- (BOOL)writeXMLDataToFile:(NSURL*)inFileURL
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ofstream fileStream(filePath.c_str());
    [self lockWorld];
        World::worldToStream(mWorldData->world(), fileStream, World::kXML);
    [self unlockWorld];

    return YES;
}

- (BOOL)readWorldFromXMLFile:(NSURL*)inFileURL
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ifstream fileStream(filePath.c_str());
    World* newWorld = World::worldFromStream(fileStream, World::kXML);
    [self setWorld:newWorld];

    return YES;
}

- (BOOL)writeSoupConfigurationToXMLFile:(NSURL*)inFileURL
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ofstream fileStream(filePath.c_str());

    MacTierra:SoupConfiguration soupConfig(mWorldData->world()->soupSize(), mWorldData->world()->initialRandomSeed(), mWorldData->world()->settings());
    
    ::boost::archive::xml_oarchive xmlArchive(fileStream);
    xmlArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("configuration", soupConfig);
    return YES;
}

@end

@implementation MTWorldThread

@synthesize runningCondition;
@synthesize running;

- (id)initWithWorldController:(MTWorldController*)inController
{
    if ((self = [super init]))
    {
        mWorldController = inController;
        [self setName:@"World thread"];
        runningCondition = [[NSCondition alloc] init];
        running = false;
    }
    return self;
}

- (void)dealloc
{
    self.runningCondition = nil;
    [super dealloc];
}

- (void)main
{
    while (1)
    {
        [runningCondition lock];
        while (!running)
            [runningCondition wait];

        if ([self isCancelled])
            break;

        const NSUInteger kNumCycles = 10000;
        [mWorldController iterate:kNumCycles];

        [runningCondition unlock];
    }
}

- (void)run
{
    [runningCondition lock];
    running = YES;
    [runningCondition signal];
    [runningCondition unlock];
}

- (void)pause
{
    [runningCondition lock];
    running = NO;
    [runningCondition signal];
    [runningCondition unlock];
}

- (void)lock
{
    [runningCondition lock];
}

- (void)unlock
{
    [runningCondition unlock];
}

@end
