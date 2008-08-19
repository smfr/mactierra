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
#import "mt_cellmap.h"
#import "mt_world.h"

using namespace MacTierra;


@interface MTWorldController(Private)

- (void)startRunTimer;
- (void)stopRunTimer;

@end

#pragma mark -

@implementation MTWorldController

@synthesize running;
@synthesize instructionsPerSecond;

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
    [mSoupView setWorld:NULL];

    delete mWorld;
    [super dealloc];
}

- (void)awakeFromNib
{
}

- (MTSoupView*)soupView
{
    return mSoupView;
}

- (void)createSoup:(u_int32_t)inSize
{
    mWorld = new World();

    mWorld->setFlawRate(8.34E-4);
    mWorld->setCosmicRate(7.634E-9);
    mWorld->setCopyErrorRate(1.0E-3);
    mWorld->setSliceSizeVariance(2);

    mWorld->initializeSoup(inSize);

    // seed the soup
    mWorld->insertCreature(inSize / 4, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    
    [mSoupView setWorld:mWorld];
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
}

@end
