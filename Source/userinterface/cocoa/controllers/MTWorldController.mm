//
//  MTWorldController.mm
//  MacTierra
//
//  Created by Simon Fraser on 8/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MTWorldController.h"

#import "MTSoupView.h"

#import "mt_ancestor.h"
#import "mt_world.h"

using namespace MacTierra;


@interface MTWorldController(Private)

- (void)startRunTimer;
- (void)stopRunTimer;

@end

#pragma mark -

@implementation MTWorldController

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
    if (mRunning)
    {
        [self stopRunTimer];
        mRunning = NO;
    }
    else
    {
        [self startRunTimer];
        mRunning = YES;
    }
}

#pragma mark -

- (void)startRunTimer
{
    mRunTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(runTimerFired:)
                                                userInfo:nil
                                                 repeats:YES] retain];       // retain cycle
}


- (void)stopRunTimer
{
    [mRunTimer invalidate];
    [mRunTimer release];
    mRunTimer = nil;
}

- (void)runTimerFired:(NSTimer*)inTimer
{
    const u_int32_t kCycleCount = 10000;
    if (mWorld)
        mWorld->iterate(kCycleCount);

    [mSoupView setNeedsDisplay:YES];
}

@end
