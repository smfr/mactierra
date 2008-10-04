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

#include "MT_DataCollectors.h"
#include "MT_World.h"

class GenebankInventoryListener;

// Container for C++ world-related data, particularly for data collection
class WorldDataCollectors
{
public:
    WorldDataCollectors(MacTierra::World* inWorld)
    : mPopSizeLogger(NULL)
    , mMeanSizeLogger(NULL)
    , mFitnessFrequencyLogger(NULL)
    , mGenotypeFrequencyLogger(NULL)
    , mSizeFrequencyLogger(NULL)
    {
        setupDataCollectors(inWorld);
    }
    
    ~WorldDataCollectors()
    {
        clearDataCollectors();
    }
    
    PopulationSizeLogger*    populationSizeLogger() const    { return mPopSizeLogger; }
    MeanCreatureSizeLogger*  meanCreatureSizeLogger() const  { return mMeanSizeLogger; }
    MaxFitnessDataLogger*    maxFitnessDataLogger() const    { return mFitnessFrequencyLogger; }

    GenotypeFrequencyDataLogger* genotypeFrequencyDataLogger() const { return mGenotypeFrequencyLogger; }
    SizeHistogramDataLogger*     sizeHistogramDataLogger() const     { return mSizeFrequencyLogger; }

protected:

    void setupDataCollectors(MacTierra::World* inWorld);
    void clearDataCollectors();

protected:
    PopulationSizeLogger*        mPopSizeLogger;
    MeanCreatureSizeLogger*      mMeanSizeLogger;
    MaxFitnessDataLogger*        mFitnessFrequencyLogger;

    GenotypeFrequencyDataLogger* mGenotypeFrequencyLogger;
    SizeHistogramDataLogger*     mSizeFrequencyLogger;
    
    GenebankInventoryListener*              mGenebankListener;
};


class WorldData
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
    
    void setWorld(MacTierra::World* inWorld);
    MacTierra::World* world() { return mWorld; }

    u_int64_t instructionsExecuted() const { return mWorld->timeSlicer().instructionsExecuted(); }

    WorldDataCollectors*        dataCollectors() const { return mDataCollectors; }

protected:
    MacTierra::World*           mWorld;
    WorldDataCollectors*        mDataCollectors;
    GenebankInventoryListener*  mGenebankListener;
};

#endif // MTWorldDataCollection_h
