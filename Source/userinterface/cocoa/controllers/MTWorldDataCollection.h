/*
 *  MTWorldDataCollection.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MTWorldDataCollection_h
#define MTWorldDataCollection_h

#include <iosfwd>

#include <boost/serialization/serialization.hpp>

#include <wtf/Noncopyable.h>

#include "MT_DataCollectors.h"
#include "MT_World.h"
#include "MT_WorldArchiver.h"

class GenebankInventoryListener;

// Container for C++ world-related data, particularly for data collection
class WorldDataCollectors : public MacTierra::WorldArchivingAddition
{
public:
    WorldDataCollectors()
    : mPopSizeLogger(NULL)
    , mMeanSizeLogger(NULL)
    , mFitnessFrequencyLogger(NULL)
    , mGenotypeFrequencyLogger(NULL)
    , mSizeFrequencyLogger(NULL)
    {
    }

    ~WorldDataCollectors()
    {
        clearDataCollectors();
    }
    
    void setWorld(MacTierra::World* inWorld)
    {
        setupDataCollectors(inWorld);
    }
    
    PopulationSizeLogger*    populationSizeLogger() const    { return mPopSizeLogger; }
    MeanCreatureSizeLogger*  meanCreatureSizeLogger() const  { return mMeanSizeLogger; }
    MaxFitnessDataLogger*    maxFitnessDataLogger() const    { return mFitnessFrequencyLogger; }

    GenotypeFrequencyDataLogger* genotypeFrequencyDataLogger() const { return mGenotypeFrequencyLogger; }
    SizeHistogramDataLogger*     sizeHistogramDataLogger() const     { return mSizeFrequencyLogger; }


    virtual void registerTypes(boost::archive::polymorphic_oarchive& inArchive);
    virtual void registerTypes(boost::archive::polymorphic_iarchive& inArchive);

    virtual void loadAddition(const std::string& inAdditionType, boost::archive::polymorphic_iarchive& inArchive);
    virtual void saveAddition(const std::string& inAdditionType, boost::archive::polymorphic_oarchive& inArchive);

protected:

    void setupDataCollectors(MacTierra::World* inWorld);
    void clearDataCollectors();

protected:
    PopulationSizeLogger*        mPopSizeLogger;
    MeanCreatureSizeLogger*      mMeanSizeLogger;
    MaxFitnessDataLogger*        mFitnessFrequencyLogger;

    GenotypeFrequencyDataLogger* mGenotypeFrequencyLogger;
    SizeHistogramDataLogger*     mSizeFrequencyLogger;
    
    GenebankInventoryListener*   mGenebankListener;
};

class WorldData : Noncopyable
{
public:

    WorldData()
    : mWorld(NULL)
    , mDataCollectors(NULL)
    , mGenebankListener(NULL)
    {
    }
    
    ~WorldData();
    
    void seedWithAncestor();
    
    void stepCreature(const MacTierra::Creature* inCreature);
    
    void writeInventory(std::ostream& inStream);
    
    void setWorld(MacTierra::World* inWorld, WorldDataCollectors* inDataCollectors);
    MacTierra::World* world() { return mWorld; }

    u_int64_t instructionsExecuted() const { return mWorld->timeSlicer().instructionsExecuted(); }

    WorldDataCollectors*  dataCollectors() const { return mDataCollectors.get(); }

protected:
    MacTierra::World*           mWorld;
    RefPtr<WorldDataCollectors> mDataCollectors;
    GenebankInventoryListener*  mGenebankListener;
};


#endif // MTWorldDataCollection_h
