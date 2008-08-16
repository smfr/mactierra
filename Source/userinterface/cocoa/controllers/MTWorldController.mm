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
    [mSoupView setSoup:NULL];

    delete mWorld;
    [super dealloc];
}

- (void)awakeFromNib
{
}

- (void)createSoup:(u_int32_t)inSize
{
    mWorld = new World();
    mWorld->initializeSoup(inSize);

    // seed the soup
    mWorld->insertCreature(1024, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    
    [mSoupView setSoup:mWorld->soup()];
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
    const u_int32_t kCycleCount = 100;
    if (mWorld)
        mWorld->iterate(kCycleCount);

    [mSoupView setNeedsDisplay:YES];
}

@end
