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
    
    if (!mPopSizeLogger)
    {
        mPopSizeLogger = new PopulationSizeLogger();
        mPopSizeLogger->setMaxDataCount(kMaxDataPoints);
    }
    inWorld->dataCollector()->addPeriodicLogger(mPopSizeLogger);

    if (!mMeanSizeLogger)
    {
        mMeanSizeLogger = new MeanCreatureSizeLogger();
        mMeanSizeLogger->setMaxDataCount(kMaxDataPoints);
    }
    inWorld->dataCollector()->addPeriodicLogger(mMeanSizeLogger);

    if (!mFitnessFrequencyLogger)
    {
        mFitnessFrequencyLogger = new MaxFitnessDataLogger();
        mFitnessFrequencyLogger->setMaxDataCount(kMaxDataPoints);
    }
    inWorld->dataCollector()->addPeriodicLogger(mFitnessFrequencyLogger);
    
    if (!mGenotypeFrequencyLogger)
    {
        mGenotypeFrequencyLogger = new GenotypeFrequencyDataLogger();
        mGenotypeFrequencyLogger->setMaxBuckets(15);
    }
    
    if (!mSizeFrequencyLogger)
    {
        mSizeFrequencyLogger = new SizeHistogramDataLogger();
        mSizeFrequencyLogger->setMaxBuckets(15);
    }
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

void
WorldDataCollectors::registerTypes(boost::archive::polymorphic_oarchive& inArchive)
{
    inArchive.register_type(static_cast<PopulationSizeLogger *>(NULL));
    inArchive.register_type(static_cast<MeanCreatureSizeLogger *>(NULL));
    inArchive.register_type(static_cast<MaxFitnessDataLogger *>(NULL));
    inArchive.register_type(static_cast<GenotypeFrequencyDataLogger *>(NULL));
    inArchive.register_type(static_cast<SizeHistogramDataLogger *>(NULL));
}

void
WorldDataCollectors::registerTypes(boost::archive::polymorphic_iarchive& inArchive)
{
    inArchive.register_type(static_cast<PopulationSizeLogger *>(NULL));
    inArchive.register_type(static_cast<MeanCreatureSizeLogger *>(NULL));
    inArchive.register_type(static_cast<MaxFitnessDataLogger *>(NULL));
    inArchive.register_type(static_cast<GenotypeFrequencyDataLogger *>(NULL));
    inArchive.register_type(static_cast<SizeHistogramDataLogger *>(NULL));
}

void
WorldDataCollectors::loadAddition(const std::string& inAdditionType, boost::archive::polymorphic_iarchive& inArchive)
{
    inArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("population_size_logger", mPopSizeLogger);
    inArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("mean_size_logger", mMeanSizeLogger);
    inArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("max_fitness_logger", mFitnessFrequencyLogger);

    inArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype_frequency_logger", mGenotypeFrequencyLogger);
    inArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("size_frequency_logger", mSizeFrequencyLogger);
}

void
WorldDataCollectors::saveAddition(const std::string& inAdditionType, boost::archive::polymorphic_oarchive& inArchive)
{
    inArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("population_size_logger", mPopSizeLogger);
    inArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("mean_size_logger", mMeanSizeLogger);
    inArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("max_fitness_logger", mFitnessFrequencyLogger);

    inArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("genotype_frequency_logger", mGenotypeFrequencyLogger);
    inArchive << MT_BOOST_MEMBER_SERIALIZATION_NVP("size_frequency_logger", mSizeFrequencyLogger);
}

#pragma mark -

WorldData::~WorldData()
{
    delete mGenebankListener;

    setWorld(NULL, NULL);
}

void
WorldData::setWorld(MacTierra::World* inWorld, WorldDataCollectors* inDataCollectors)
{
    if (inWorld != mWorld)
    {
        mDataCollectors = 0;
        
        delete mWorld;
        mWorld = inWorld;
        
        if (mWorld)
        {
            if (inDataCollectors)
                mDataCollectors = inDataCollectors;
            else
                mDataCollectors = new WorldDataCollectors();

            mDataCollectors->setWorld(mWorld);
            
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
