/*
 *  MTWorldDataCollection.mm
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MTWorldDataCollection.h"

#include "MT_Ancestor.h"
#include "MT_InventoryListener.h"

#import "MTGenebankController.h"

using namespace MacTierra;


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


#pragma mark -

void
WorldDataCollectors::setupDataCollectors(World* inWorld)
{
    const NSUInteger kMaxDataPoints = 500;
    
    // set up some logging
    mPopSizeLogger = new PopulationSizeLogger();
    mPopSizeLogger->setMaxDataCount(kMaxDataPoints);
    inWorld->dataCollector()->addPeriodicLogger(mPopSizeLogger);

    mMeanSizeLogger = new MeanCreatureSizeLogger();
    mMeanSizeLogger->setMaxDataCount(kMaxDataPoints);
    inWorld->dataCollector()->addPeriodicLogger(mMeanSizeLogger);

    mFitnessFrequencyLogger = new MaxFitnessDataLogger();
    mFitnessFrequencyLogger->setMaxDataCount(kMaxDataPoints);
    inWorld->dataCollector()->addPeriodicLogger(mFitnessFrequencyLogger);
    
    mGenotypeFrequencyLogger = new GenotypeFrequencyDataLogger();
    mGenotypeFrequencyLogger->setMaxBuckets(15);
    
    mSizeFrequencyLogger = new SizeHistogramDataLogger();
    mSizeFrequencyLogger->setMaxBuckets(15);
}

void
WorldDataCollectors::clearDataCollectors()
{
    delete mPopSizeLogger;
    mPopSizeLogger = NULL;
    
    delete mMeanSizeLogger;
    mMeanSizeLogger = NULL;

    delete mFitnessFrequencyLogger;
    mFitnessFrequencyLogger = NULL;

    delete mGenotypeFrequencyLogger;
    mGenotypeFrequencyLogger = NULL;
    
    delete mSizeFrequencyLogger;
    mSizeFrequencyLogger = NULL;
}

#pragma mark -

WorldData::~WorldData()
{
    delete mDataCollectors;
    mDataCollectors = NULL;

    delete mGenebankListener;
    mGenebankListener = NULL;

    setWorld(NULL);
}

void
WorldData::setWorld(MacTierra::World* inWorld)
{
    if (inWorld != mWorld)
    {
        delete mDataCollectors;
        mDataCollectors = NULL;
        
        delete mWorld;
        mWorld = inWorld;
        
        if (mWorld)
        {
            mDataCollectors = new WorldDataCollectors(mWorld);

            mGenebankListener = new GenebankInventoryListener();
            mWorld->inventory()->setListenerAliveThreshold(20);
            mWorld->inventory()->registerListener(mGenebankListener);
        }
    }
}

void
WorldData::seedWithAncestor()
{
    if (mWorld)
        mWorld->insertCreature(mWorld->soupSize() / 4, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
}

void
WorldData::stepCreature(const MacTierra::Creature* inCreature)
{
    if (mWorld)
        mWorld->stepCreature(inCreature);
}

void
WorldData::writeInventory(std::ostream& inStream)
{
    if (mWorld)
        mWorld->inventory()->writeToStream(inStream);
}

