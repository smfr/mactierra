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
#import "MT_World.h"

#import "MTCreature.h"
#import "MTInventoryController.h"
#import "MTWorldSettings.h"

using namespace MacTierra;


@interface MTWorldController(Private)

- (void)startRunTimer;
- (void)stopRunTimer;
- (void)setWorld:(World*)inWorld;

- (void)updateSoup;
- (void)updateGenotypes;
- (void)updateDebugPanel;

@end

#pragma mark -

@implementation MTWorldController

@synthesize document;
@synthesize running;
@synthesize instructionsPerSecond;
@synthesize selectedCreature;

@synthesize worldSettings;
@synthesize creatingNewSoup;

+ (void)initialize
{
    [self setKeys:[NSArray arrayWithObject:@"running"]
                                triggerChangeNotificationsForDependentKey:@"playPauseButtonTitle"];
}

- (id)init
{
    if ((self = [super init]))
    {
    }
    return self;
}

- (void)dealloc
{
    self.selectedCreature = nil;
    
    [mSoupView setWorld:NULL];
    [mSoupView release];
    
    delete mWorld;
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
    if (inWorld != mWorld)
    {
        [mSoupView setWorld:nil];
        delete mWorld;
        [mInventoryController setInventory:nil];
        
        mWorld = inWorld;
        [mSoupView setWorld:mWorld];
        
        [mInventoryController setInventory:mWorld ? mWorld->inventory() : NULL];

        [self updateGenotypes];
    }
}

- (void)seedWithAncestor
{
    // seed the soup
    if (mWorld)
        mWorld->insertCreature(mWorld->soupSize() / 4, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
}

- (IBAction)toggleRunning:(id)sender
{
    if (running)
    {
        [self stopRunTimer];
        self.running = NO;
        // hack to update genotypes on pause
        [self updateGenotypes];
        [self updateDebugPanel];
    }
    else
    {
        [self startRunTimer];
        self.running = YES;
    }
}

- (IBAction)step:(id)sender
{
    if (self.selectedCreature)
    {
        mWorld->stepCreature(selectedCreature.creature);
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
    if (mWorld && returnCode == NSOKButton)
    {
        NSString* filePath = [sheet filename];
        
        std::ofstream outFileStream([filePath fileSystemRepresentation]);
        mWorld->inventory()->writeToStream(outFileStream);
    }
}

- (NSString*)playPauseButtonTitle
{
    return running ? NSLocalizedString(@"RunningButtonTitle", @"Pause") : NSLocalizedString(@"PausedButtonTitle", @"Continue");
}

- (MacTierra::World*)world
{
    return mWorld;
}

- (double)fullness
{
    return mWorld ? mWorld->cellMap()->fullness() : 0.0;
}

- (u_int64_t)totalInstructions
{
    return mWorld ? mWorld->timeSlicer().instructionsExecuted() : 0;
}

- (NSInteger)numberOfCreatures
{
    return mWorld ? mWorld->cellMap()->numCreatures() : 0;
}

- (void)documentClosing
{
    // have to break ref cycles
    [self stopRunTimer];
    
    [self setWorld:NULL];
    self.selectedCreature = nil;
}

#pragma mark -

- (void)startRunTimer
{
    mRunTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(runTimerFired:)
                                                userInfo:nil
                                                 repeats:YES] retain];       // retain cycle

    mLastInstTime = CFAbsoluteTimeGetCurrent();
    mLastInstructions = mWorld->timeSlicer().instructionsExecuted();
}

- (void)stopRunTimer
{
    [mRunTimer invalidate];
    [mRunTimer release];
    mRunTimer = nil;
}

- (void)runTimerFired:(NSTimer*)inTimer
{
    [self willChangeValueForKey:@"fullness"];
    [self willChangeValueForKey:@"totalInstructions"];
    [self willChangeValueForKey:@"numberOfCreatures"];
    
    const u_int32_t kCycleCount = 100000;
    if (mWorld)
        mWorld->iterate(kCycleCount);

    u_int64_t curInstructions = mWorld->timeSlicer().instructionsExecuted();
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

    self.instructionsPerSecond = (double)(curInstructions - mLastInstructions) / (currentTime - mLastInstTime);
    
    mLastInstTime = currentTime;
    mLastInstructions = curInstructions;
    
    [self updateSoup];

    [self didChangeValueForKey:@"fullness"];
    [self didChangeValueForKey:@"totalInstructions"];
    [self didChangeValueForKey:@"numberOfCreatures"];
    
    // hack to avoid slowing things down too much
    if ([mInventoryTableView window])
        [self updateGenotypes];

    [document updateChangeCount:NSChangeDone];
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
    NSAssert(mWorld, @"Should have world already");

    self.creatingNewSoup = NO;

    self.worldSettings = [[[MTWorldSettings alloc] initWithSettings:mWorld->settings()] autorelease];
    self.worldSettings.soupSize = mWorld->soupSize();
    
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
    if (returnCode == NSOKButton)
    {
        const MacTierra::Settings* theSettings = worldSettings.settings;
        BOOST_ASSERT(theSettings);

        if (self.creatingNewSoup)
        {
            BOOST_ASSERT(!mWorld);
            
            MacTierra::World* newWorld = new World();
            newWorld->RNG().Reseed(self.worldSettings.randomSeed);
            newWorld->setSettings(*worldSettings.settings);
            
            newWorld->initializeSoup(worldSettings.soupSize);
            [self setWorld:newWorld];
            
            if (worldSettings.seedWithAncestor)
                [self seedWithAncestor];
        }
        else
        {
            mWorld->setSettings(*theSettings);
        }
    }
    [sheet orderOut:nil];
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

- (NSData*)worldData
{
    if (!mWorld)
        return nil;

//    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    std::ostringstream stringStream;
    World::worldToStream(mWorld, stringStream, World::kBinary);

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
    if (!mWorld)
        return nil;

    std::ostringstream stringStream;
    World::worldToStream(mWorld, stringStream, World::kXML);

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
    World::worldToStream(mWorld, fileStream, World::kBinary);
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
    World::worldToStream(mWorld, fileStream, World::kXML);
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
