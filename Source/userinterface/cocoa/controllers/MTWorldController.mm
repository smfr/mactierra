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
#import "MTTimeUtils.h"

#import "MT_Cellmap.h"
#import "MT_Inventory.h"
#import "MT_InventoryListener.h"
#import "MT_SoupConfiguration.h"
#import "MT_World.h"
#import "MT_WorldArchiver.h"

#import "MTCreature.h"
#import "MT_DataCollection.h"
#import "MT_DataCollectors.h"

#import "MTGraphController.h"
#import "MTGenebankController.h"
#import "MTGenotypeImageView.h"
#import "MTInventoryController.h"
#import "MTWorldDataCollection.h"
#import "MTWorldSettings.h"

using namespace MacTierra;

@interface MTWorldController ( )

@property (nonatomic, weak) IBOutlet NSTableView* inventoryTableView;
@property (nonatomic, weak) IBOutlet MTInventoryController* inventoryController;
@property (nonatomic, weak) IBOutlet MTGraphController* graphController;
@property (nonatomic, weak) IBOutlet NSTextView* creatureSoupView;
@property (nonatomic, weak) IBOutlet NSObjectController* selectedCreatureController;
@property (nonatomic, weak) IBOutlet MTGenotypeImageView* debugGenotypeImageView;
@property (nonatomic, weak) IBOutlet MTGenotypeImageView* inspectGenotypeImageView;
@property (nonatomic, weak) IBOutlet NSPanel* settingsPanel;

@property (retain) NSTimer* updateTimer;

- (void)startUpdateTimer;
- (void)stopUpdateTimer;
- (void)setRunning:(BOOL)inRunning;
- (void)setWorld:(World*)inWorld dataCollectors:(WorldDataCollectors*)inDataCollectors;

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

@property (nonatomic, assign) MTWorldController* worldController;
@property (nonatomic, retain) NSLock* worldLock;
@property (retain) NSRunLoop* threadRunLoop;
@property (nonatomic, retain) NSTimer* runWorldTimer;
@property (assign) BOOL running;
@property (assign) BOOL terminated;

- (id)initWithWorldController:(MTWorldController*)inController;

- (void)run;
- (void)pause;

- (void)lockWorld;
- (void)unlockWorld;

- (void)wakeUp;

@end

#pragma mark -

@implementation MTWorldController

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"playPauseButtonTitle"])
        return [NSSet setWithObjects:@"worldRunning", nil];

    return [NSSet set];
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
    _selectedCreature = nil;
    [_soupView setWorld:NULL];

    delete mWorldData;
}

- (void)awakeFromNib
{
    [self.inventoryTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
    [self.inventoryTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    [self.debugGenotypeImageView bind:@"genotype"
                         toObject:self
                      withKeyPath:@"selectedCreature.genotype"
                          options:0];

    [self.inspectGenotypeImageView bind:@"genotype"
                         toObject:self
                      withKeyPath:@"selectedCreature.genotype"
                          options:0];
}

- (void)setWorld:(World*)inWorld dataCollectors:(WorldDataCollectors*)inDataCollectors
{
    if (inWorld != mWorldData->world())
    {
        [self terminateWorldThread];

        [_soupView setWorld:nil];
        [self.inventoryController setInventory:nil];

        mWorldData->setWorld(inWorld, inDataCollectors);
        [_soupView setWorld:mWorldData->world()];

        if (mWorldData->world())
            [self createWorldThread];

        [self.inventoryController setInventory:mWorldData->world() ? mWorldData->world()->inventory() : NULL];

        [self.graphController worldChanged];
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
    [self setRunning:!_worldRunning];
}

- (IBAction)step:(id)sender
{
    if (_selectedCreature)
    {
        mWorldData->stepCreature(_selectedCreature.creature);
        [self updateSoup];
        [self updateDebugPanel];
        [self.document updateChangeCount:NSChangeDone];
    }
}

- (IBAction)exportInventory:(id)sender
{
    NSSavePanel*    savePanel = [NSSavePanel savePanel];

    [savePanel beginSheetForDirectory:nil
                                 file:@"Inventory.txt"
                       modalForWindow:[self.document windowForSheet]
                        modalDelegate:self
                       didEndSelector:@selector(exportInventorySavePanelDidDne:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (void)exportInventorySavePanelDidDne:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (mWorldData->world() && returnCode == NSModalResponseOK)
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
    return _worldRunning ? NSLocalizedString(@"RunningButtonTitle", @"Pause") : NSLocalizedString(@"PausedButtonTitle", @"Continue");
}

- (MacTierra::World*)world
{
    return mWorldData->world();
}

- (const WorldDataCollectors*)dataCollectors
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

- (u_int64_t)slicerCycles
{
    return mLastSlicerCycles;
}

- (NSInteger)numberOfCreatures
{
    return mLastNumCreatures;
}

- (void)documentClosing
{
    [self clearWorld];

    [self.graphController documentClosing];
    [self.debugGenotypeImageView unbind:@"genotype"];
    [self.inspectGenotypeImageView unbind:@"genotype"];
}

- (void)clearWorld
{
    // have to break ref cycles
    [self setRunning:NO];

    [self setWorld:NULL dataCollectors:NULL];
    self.selectedCreature = nil;
}

#pragma mark -

- (void)setRunning:(BOOL)inRunning
{
    if (inRunning == _worldRunning)
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
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:kUpdateInterval
                                                    target:self
                                                  selector:@selector(updateTimerFired:)
                                                  userInfo:nil
                                                   repeats:YES];

    mLastInstTime = CFAbsoluteTimeGetCurrent();
    mLastInstructions = mWorldData->instructionsExecuted();
    mLastSlicerCycles = mWorldData->world()->timeSlicer().cycleCount();
}

- (void)stopUpdateTimer
{
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)updateTimerFired:(NSTimer*)inTimer
{
    [self updateDisplay];
    [self.document updateChangeCount:NSChangeDone];
}

- (void)updateDisplay
{
    if (!mWorldData->world())
        return;

    [self willChangeValueForKey:@"fullness"];
    [self willChangeValueForKey:@"totalInstructions"];
    [self willChangeValueForKey:@"slicerCycles"];
    [self willChangeValueForKey:@"numberOfCreatures"];

    [self lockWorld];
    {
        u_int64_t curInstructions = mWorldData->instructionsExecuted();
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

        self.instructionsPerSecond = (double)(curInstructions - mLastInstructions) / (currentTime - mLastInstTime);

        mLastInstructions = curInstructions;
        mLastSlicerCycles = mWorldData->world()->timeSlicer().cycleCount();
        mLastNumCreatures = mWorldData->world()->cellMap()->numCreatures();
        mLastFullness = mWorldData->world()->cellMap()->fullness();

        [self updateSoup];

        // hack to avoid slowing things down too much
        if ([self.inventoryTableView window])
            [self updateGenotypes];

        [self.graphController updateGraph];

        mLastInstTime = CFAbsoluteTimeGetCurrent();
    }
    [self unlockWorld];

    [self didChangeValueForKey:@"fullness"];
    [self didChangeValueForKey:@"totalInstructions"];
    [self didChangeValueForKey:@"slicerCycles"];
    [self didChangeValueForKey:@"numberOfCreatures"];
}

- (void)updateSoup
{
    // FIXME: This could update the soup image while we have the lock held.
    [self.soupView setNeedsDisplay:YES];
}

- (void)updateGenotypes
{
    [self.inventoryController updateGenotypesArray];
}

- (void)updateDebugPanel
{
    // hack
    MTCreature* oldSelectedCreature = self.selectedCreature;
    self.selectedCreature = nil;
    self.selectedCreature = oldSelectedCreature;

    // FIXME: need to do this on setSelectedCreature too
    if (self.selectedCreature)
        [_creatureSoupView setSelectedRanges:[NSArray arrayWithObject:[NSValue valueWithRange:_selectedCreature.soupSelectionRange]]];
}

#pragma mark -

// Settings panel
- (IBAction)editSoupSettings:(id)sender
{
    NSAssert(mWorldData->world(), @"Should have world already");

    self.creatingNewSoup = NO;

    self.worldSettings = [[MTWorldSettings alloc] initWithSettings:mWorldData->world()->settings()];
    self.worldSettings.soupSize = mWorldData->world()->soupSize();
    self.worldSettings.randomSeed = mWorldData->world()->initialRandomSeed();

    [NSApp beginSheet:self.settingsPanel
       modalForWindow:[self.document windowForSheet]
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

    [self setWorld:newWorld dataCollectors:NULL];
}

- (IBAction)newSoupShowingSettings:(id)sender
{
    self.creatingNewSoup = YES;

    self.worldSettings = [[MTWorldSettings alloc] initWithSettings:MacTierra::Settings::mediumMutationSettings(256 * 1024)];
    self.worldSettings.creatingNewSoup = YES;
    self.worldSettings.soupSizePreset = k256K;
    self.worldSettings.seedWithAncestor = YES;

    [NSApp beginSheet:self.settingsPanel
       modalForWindow:[self.document windowForSheet]
        modalDelegate:self
       didEndSelector:@selector(soupSettingsPanelDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)soupSettingsPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];

    if (returnCode == NSModalResponseOK)
    {
        const MacTierra::Settings* theSettings = self.worldSettings.settings;
        BOOST_ASSERT(theSettings);

        if (self.creatingNewSoup)
        {
            BOOST_ASSERT(!mWorldData->world());

            MacTierra::World* newWorld = new World();
            newWorld->setInitialRandomSeed(_worldSettings.randomSeed);
            newWorld->setSettings(*_worldSettings.settings);

            newWorld->initializeSoup(_worldSettings.soupSize);
            [self setWorld:newWorld dataCollectors:NULL];

            if (_worldSettings.seedWithAncestor)
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
            [self.document performSelector:@selector(close) withObject:nil afterDelay:0];
        }
    }

    self.worldSettings = nil;
}

- (IBAction)zeroMutationRates:(id)sender
{
    _worldSettings.cosmicRate = 0.0;
    _worldSettings.flawRate = 0.0;
    _worldSettings.copyErrorRate = 0.0;
}

- (IBAction)initializeRandomSeed:(id)sender
{
    self.worldSettings.randomSeed = RandomLib::RandomSeed::SeedWord();
}

- (IBAction)okSettingsPanel:(id)sender
{
    [NSApp endSheet:self.settingsPanel returnCode:NSModalResponseOK];
}

- (IBAction)cancelSettingsPanel:(id)sender
{
    [NSApp endSheet:self.settingsPanel returnCode:NSModalResponseCancel];
}

#pragma mark -

- (void)createWorldThread
{
    self.worldThread = [[MTWorldThread alloc] initWithWorldController:self];
    [_worldThread start];
}

- (void)terminateWorldThread
{
    if (!_worldThread)
        return;

    _worldThread.terminated = YES;
    [_worldThread performSelector:@selector(wakeUp) onThread:_worldThread withObject:nil waitUntilDone:NO];

    while (![_worldThread isFinished])
        [NSThread sleepForTimeInterval:0.001];

    self.worldThread = nil;
}

- (void)runWorld
{
    [_worldThread run];
}

- (void)pauseWorld
{
    [_worldThread pause];
}

- (void)iterate:(NSUInteger)inNumCycles
{
    if (mWorldData->world())
        mWorldData->world()->iterate(inNumCycles);
}

- (void)lockWorld
{
    [_worldThread lockWorld];
}

- (void)unlockWorld
{
    [_worldThread unlockWorld];
}

#pragma mark -

static BOOL filePathFromURL(NSURL* inURL, std::string& outPath)
{
    if (![inURL isFileURL])
        return NO;

    outPath = [[inURL path] fileSystemRepresentation];
    return YES;
}

#define MEASURE_LOADING 1

- (BOOL)readWorldFromFile:(NSURL*)inFileURL format:(WorldArchiver::EWorldSerializationFormat)inFileFormat
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

#ifdef MEASURE_LOADING
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
#endif

    RefPtr<WorldDataCollectors> dataCollectorsAddition = WorldDataCollectors::create();

    World* newWorld = NULL;
    {
        std::ifstream fileStream(filePath.c_str());
        WorldImporter importer(fileStream, inFileFormat);

        std::vector<std::string> archivingTypes;
        archivingTypes.push_back("data");
        importer.registerAddition(archivingTypes, dataCollectorsAddition.get());

        newWorld = importer.loadWorld();
    }

#ifdef MEASURE_LOADING
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSLog(@"Reading %@ world took %f milliseconds", (inFileFormat == WorldArchiver::kXML) ? @"XML" : @"binary", (endTime - startTime) * 1000.0);
#endif

    [self setWorld:newWorld dataCollectors:dataCollectorsAddition.get()];

    return YES;
}

- (BOOL)writeWorldToFile:(NSURL*)inFileURL format:(WorldArchiver::EWorldSerializationFormat)inFileFormat
{
    std::string filePath;
    if (!filePathFromURL(inFileURL, filePath))
        return NO;

    std::ofstream fileStream(filePath.c_str());
    [self lockWorld];
    {
        WorldExporter exporter(fileStream, inFileFormat);

        std::vector<std::string> archivingTypes;
        archivingTypes.push_back("data");
        exporter.registerAddition(archivingTypes, mWorldData->dataCollectors());

        exporter.saveWorld(mWorldData->world());
    }
    [self unlockWorld];

    return YES;
}

- (BOOL)readWorldFromBinaryFile:(NSURL*)inFileURL
{
    return [self readWorldFromFile:inFileURL format:WorldArchiver::kBinary];
}

- (BOOL)readWorldFromXMLFile:(NSURL*)inFileURL
{
    return [self readWorldFromFile:inFileURL format:WorldArchiver::kXML];
}

- (BOOL)writeWorldToBinaryFile:(NSURL*)inFileURL
{
    return [self writeWorldToFile:inFileURL format:WorldArchiver::kBinary];
}

- (BOOL)writeWorldToXMLFile:(NSURL*)inFileURL
{
    return [self writeWorldToFile:inFileURL format:WorldArchiver::kXML];
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

- (id)initWithWorldController:(MTWorldController*)inController
{
    if ((self = [super init]))
    {
        [self setName:@"World thread"];
        _worldLock = [[NSLock alloc] init];
        _worldController = inController;
        _running = NO;
        _terminated = NO;
    }
    return self;
}

- (void)installTimer
{
    if (_runWorldTimer)
        return;

    _runWorldTimer = [[NSTimer alloc] initWithFireDate:[NSDate now] interval:0 target:self selector:@selector(runOneWorldCycle) userInfo:nil repeats:YES];
    [_threadRunLoop addTimer:self.runWorldTimer forMode:NSDefaultRunLoopMode];
}

- (void)uninstallTimer
{
    [_runWorldTimer invalidate];
    self.runWorldTimer = nil;
}

- (void)main
{
    self.threadRunLoop = [NSRunLoop currentRunLoop];

    // This adds timer with a distance fire time to keep the thread running (and not immediately busylooping).
    [NSTimer scheduledTimerWithTimeInterval:9999999999 repeats:YES block:^(NSTimer * _Nonnull timer) {
        // nothing
    }];

    while (!_terminated && [_threadRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        // All the work happens on the timer.
    }

    [self uninstallTimer];
}

- (void)runOneWorldCycle
{
    [_worldLock lock];

    constexpr CFTimeInterval maxTimeToRun = 0.02; // 20ms
    CFTimeInterval startTime = approximateTime();
    CFTimeInterval endTime = startTime + maxTimeToRun;

    int numCycles = 0;
    do {
        const NSUInteger kNumCycles = 500000;
        [_worldController iterate:kNumCycles];
        ++numCycles;
    } while (approximateTime() < endTime);

    [_worldLock unlock];
}

- (void)run
{
    self.running = YES;
    [self performSelector:@selector(installTimer) onThread:self withObject:nil waitUntilDone:NO];
}

- (void)pause
{
    self.running = NO;
    [self performSelector:@selector(uninstallTimer) onThread:self withObject:nil waitUntilDone:NO];
}

- (void)lockWorld
{
    [_worldLock lock];
}

- (void)unlockWorld
{
    [_worldLock unlock];
}

- (void)wakeUp
{
}

@end
