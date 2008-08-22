//
//  MTWorldController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldController.h"

#import "MTSoupView.h"

#import "MT_Ancestor.h"
#import "MT_Cellmap.h"
#import "MT_World.h"

#import "MTCreature.h"
#import "MTInventoryController.h"

using namespace MacTierra;


@interface MTWorldController(Private)

- (void)startRunTimer;
- (void)stopRunTimer;

@end

#pragma mark -

@implementation MTWorldController

@synthesize running;
@synthesize instructionsPerSecond;
@synthesize inventoryController;
@synthesize selectedCreature;

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
    self.inventoryController = nil;
    
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

- (void)createSoup:(u_int32_t)inSize
{
    NSAssert(!mWorld, @"Should not have world yet");
    
    mWorld = new World();

    mWorld->setFlawRate(8.34E-4);
    mWorld->setCosmicRate(7.634E-9);
    mWorld->setCopyErrorRate(1.0E-3);
    mWorld->setSliceSizeVariance(2);
    mWorld->setSizeSelection(0.9);

    mWorld->initializeSoup(inSize);
    
    [mSoupView setWorld:mWorld];
    
    self.inventoryController = [[[MTInventoryController alloc] initWithInventory:mWorld->inventory()] autorelease];
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
    }
    else
    {
        [self startRunTimer];
        self.running = YES;
    }
}

- (NSString*)playPauseButtonTitle
{
    return running ? NSLocalizedString(@"RunningButtonTitle", @"Pause") : NSLocalizedString(@"PausedButtonTitle", @"Continue");
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
    
    [mSoupView setNeedsDisplay:YES];

    [self didChangeValueForKey:@"fullness"];
    [self didChangeValueForKey:@"totalInstructions"];
    [self didChangeValueForKey:@"numberOfCreatures"];
    
    // hack to avoid slowing things down too much
    if ([mInventoryTableView window])
        [inventoryController updateGenotypesArray];
}

@end
