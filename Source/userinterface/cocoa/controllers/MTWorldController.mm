//
//  MTWorldController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldController.h"

#import <RandomLib/RandomSeed.hpp>
#import <fstream>

#import "MTSoupView.h"

#import "MT_Ancestor.h"
#import "MT_Cellmap.h"
#import "MT_Inventory.h"
#import "MT_InventoryListener.h"
#import "MT_World.h"

#import "MTCreature.h"
#import "MT_DataCollection.h"
#import "MT_DataCollectors.h"

#import "MTGraphController.h"
#import "MTGenebankController.h"
#import "MTInventoryController.h"
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

class GenebankInventoryListener : public MacTierra::InventoryListener
{
public:

    virtual void noteGenotype(const MacTierra::InventoryGenotype* inGenotype)
    {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        
        NSData* genomeData = [NSData dataWithBytes:inGenotype->genome().dataString().data() length:inGenotype->genome().length()];
        
        MTGenebankController* genebankController = [MTGenebankController sharedGenebankController];
        [genebankController performSelectorOnMainThread:@selector(findOrEnterGenome:) withObject:genomeData waitUntilDone:NO];
        
        [pool release];
    }

};


// Container for C++ world-related data
class WorldData
{
public:

    WorldData()
    : mWorld(NULL)
    , mPopSizeLogger(NULL)
    , mMeanSizeLogger(NULL)
    , mGenotypeFrequencyLogger(NULL)
    , mSizeFrequencyLogger(NULL)
    , mGenebankListener(NULL)
    {
    }
    
    ~WorldData()
    {
        delete mWorld;
        delete mPopSizeLogger;
        delete mMeanSizeLogger;
        delete mGenotypeFrequencyLogger;
        delete mSizeFrequencyLogger;
        delete mGenebankListener;
    }
    
    MacTierra::World*       mWorld;

    // temp
    MacTierra::PopulationSizeLogger*        mPopSizeLogger;
    MacTierra::MeanCreatureSizeLogger*      mMeanSizeLogger;
    MacTierra::GenotypeFrequencyDataLogger* mGenotypeFrequencyLogger;
    MacTierra::SizeHistogramDataLogger*     mSizeFrequencyLogger;
    
    GenebankInventoryListener*              mGenebankListener;
};

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
    if (inWorld != mWorldData->mWorld)
    {
        [self terminateWorldThread];
        
        [mSoupView setWorld:nil];
        delete mWorldData->mWorld;
        [mInventoryController setInventory:nil];
        
        mWorldData->mWorld = inWorld;
        [mSoupView setWorld:mWorldData->mWorld];
        
        [self createWorldThread];
        
        [mInventoryController setInventory:mWorldData->mWorld ? mWorldData->mWorld->inventory() : NULL];

        if (mWorldData->mWorld)
        {
            const NSUInteger kMaxDataPoints = 500;
            
            // set up some logging
            mWorldData->mPopSizeLogger = new PopulationSizeLogger();
            mWorldData->mPopSizeLogger->setMaxDataCount(kMaxDataPoints);
            mWorldData->mWorld->dataCollector()->addPeriodicLogger(mWorldData->mPopSizeLogger);

            mWorldData->mMeanSizeLogger = new MeanCreatureSizeLogger();
            mWorldData->mMeanSizeLogger->setMaxDataCount(kMaxDataPoints);
            mWorldData->mWorld->dataCollector()->addPeriodicLogger(mWorldData->mMeanSizeLogger);

            mWorldData->mGenotypeFrequencyLogger = new GenotypeFrequencyDataLogger();
            mWorldData->mGenotypeFrequencyLogger->setMaxBuckets(15);
            
            mWorldData->mSizeFrequencyLogger = new SizeHistogramDataLogger();
            mWorldData->mSizeFrequencyLogger->setMaxBuckets(15);
            
            mWorldData->mGenebankListener = new GenebankInventoryListener();
            mWorldData->mWorld->inventory()->setListenerAliveThreshold(20);
            mWorldData->mWorld->inventory()->registerListener(mWorldData->mGenebankListener);
        }
        
        [mGraphController worldChanged];
        [self updateGenotypes];
        [self updateDisplay];
    }
}

- (void)seedWithAncestor
{
    // seed the soup
    if (mWorldData->mWorld)
        mWorldData->mWorld->insertCreature(mWorldData->mWorld->soupSize() / 4, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
}

- (IBAction)toggleRunning:(id)sender
{
    [self setRunning:!worldRunning];
}

- (IBAction)step:(id)sender
{
    if (self.selectedCreature)
    {
        mWorldData->mWorld->stepCreature(selectedCreature.creature);
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
    if (mWorldData->mWorld && returnCode == NSOKButton)
    {
        [self lockWorld];
        NSString* filePath = [sheet filename];
        
        std::ofstream outFileStream([filePath fileSystemRepresentation]);
        mWorldData->mWorld->inventory()->writeToStream(outFileStream);
        [self unlockWorld];
    }
}

- (NSString*)playPauseButtonTitle
{
    return worldRunning ? NSLocalizedString(@"RunningButtonTitle", @"Pause") : NSLocalizedString(@"PausedButtonTitle", @"Continue");
}

- (MacTierra::World*)world
{
    return mWorldData->mWorld;
}

- (MacTierra::PopulationSizeLogger*)popSizeLogger
{
    return mWorldData->mPopSizeLogger;
}

- (MacTierra::MeanCreatureSizeLogger*)meanSizeLogger
{
    return mWorldData->mMeanSizeLogger;
}

- (MacTierra::GenotypeFrequencyDataLogger*)genotypeFrequencyLogger;
{
    return mWorldData->mGenotypeFrequencyLogger;
}

- (MacTierra::SizeHistogramDataLogger*)sizeFrequencyLogger
{
    return mWorldData->mSizeFrequencyLogger;
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
    // have to break ref cycles
    [self setRunning:NO];    
    
    [self setWorld:NULL];
    self.selectedCreature = nil;
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
    mLastInstructions = mWorldData->mWorld->timeSlicer().instructionsExecuted();
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
    if (!mWorldData->mWorld) return;

    [self willChangeValueForKey:@"fullness"];
    [self willChangeValueForKey:@"totalInstructions"];
    [self willChangeValueForKey:@"numberOfCreatures"];
    
    [self lockWorld];
    {
        u_int64_t curInstructions = mWorldData->mWorld->timeSlicer().instructionsExecuted();
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

        self.instructionsPerSecond = (double)(curInstructions - mLastInstructions) / (currentTime - mLastInstTime);
        
        mLastInstTime = currentTime;
        mLastInstructions = curInstructions;
        mLastNumCreatures = mWorldData->mWorld->cellMap()->numCreatures();
        mLastFullness = mWorldData->mWorld->cellMap()->fullness();
        
        [self updateSoup];
        
        // hack to avoid slowing things down too much
        if ([mInventoryTableView window])
            [self updateGenotypes];

        [mGraphController updateGraph];
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
    NSAssert(mWorldData->mWorld, @"Should have world already");

    self.creatingNewSoup = NO;

    self.worldSettings = [[[MTWorldSettings alloc] initWithSettings:mWorldData->mWorld->settings()] autorelease];
    self.worldSettings.soupSize = mWorldData->mWorld->soupSize();
    self.worldSettings.randomSeed = mWorldData->mWorld->initialRandomSeed();
    
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
            BOOST_ASSERT(!mWorldData->mWorld);
            
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
            mWorldData->mWorld->setSettings(*theSettings);
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
    if (mWorldData->mWorld)
        mWorldData->mWorld->iterate(inNumCycles);
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
    if (!mWorldData->mWorld)
        return nil;

//    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    std::ostringstream stringStream;
    [self lockWorld];
        World::worldToStream(mWorldData->mWorld, stringStream, World::kBinary);
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
    if (!mWorldData->mWorld)
        return nil;

    std::ostringstream stringStream;
    [self lockWorld];
        World::worldToStream(mWorldData->mWorld, stringStream, World::kXML);
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
        World::worldToStream(mWorldData->mWorld, fileStream, World::kBinary);
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
        World::worldToStream(mWorldData->mWorld, fileStream, World::kXML);
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
