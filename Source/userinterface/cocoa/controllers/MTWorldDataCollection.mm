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

WorldData::~WorldData()
{
    delete mWorld;
    clearDataCollectors();
}

void
WorldData::setWorld(MacTierra::World* inWorld)
{
    if (inWorld != mWorld)
    {
        clearDataCollectors();
        delete mWorld;
        
        mWorld = inWorld;
        
        if (mWorld)
            setupDataCollectors();
    }
}

void
WorldData::setupDataCollectors()
{
    const NSUInteger kMaxDataPoints = 500;
    
    // set up some logging
    mPopSizeLogger = new PopulationSizeLogger();
    mPopSizeLogger->setMaxDataCount(kMaxDataPoints);
    mWorld->dataCollector()->addPeriodicLogger(mPopSizeLogger);

    mMeanSizeLogger = new MeanCreatureSizeLogger();
    mMeanSizeLogger->setMaxDataCount(kMaxDataPoints);
    mWorld->dataCollector()->addPeriodicLogger(mMeanSizeLogger);

    mFitnessFrequencyLogger = new MaxFitnessDataLogger();
    mFitnessFrequencyLogger->setMaxDataCount(kMaxDataPoints);
    mWorld->dataCollector()->addPeriodicLogger(mFitnessFrequencyLogger);
    
    mGenotypeFrequencyLogger = new GenotypeFrequencyDataLogger();
    mGenotypeFrequencyLogger->setMaxBuckets(15);
    
    mSizeFrequencyLogger = new SizeHistogramDataLogger();
    mSizeFrequencyLogger->setMaxBuckets(15);
    
    mGenebankListener = new GenebankInventoryListener();
    mWorld->inventory()->setListenerAliveThreshold(20);
    mWorld->inventory()->registerListener(mGenebankListener);
}

void
WorldData::clearDataCollectors()
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

    delete mGenebankListener;
    mGenebankListener = NULL;
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
    mWorld->stepCreature(inCreature);
}

void
WorldData::writeInventory(std::ostream& inStream)
{
    if (mWorld)
        mWorld->inventory()->writeToStream(inStream);
}


