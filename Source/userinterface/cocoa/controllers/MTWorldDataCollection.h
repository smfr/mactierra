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
class WorldData
{
public:

    WorldData()
    : mWorld(NULL)
    , mPopSizeLogger(NULL)
    , mMeanSizeLogger(NULL)
    , mFitnessFrequencyLogger(NULL)
    , mGenotypeFrequencyLogger(NULL)
    , mSizeFrequencyLogger(NULL)
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

    MacTierra::PopulationSizeLogger*    populationSizeLogger() const    { return mPopSizeLogger; }
    MacTierra::MeanCreatureSizeLogger*  meanCreatureSizeLogger() const  { return mMeanSizeLogger; }
    MacTierra::MaxFitnessDataLogger*    maxFitnessDataLogger() const    { return mFitnessFrequencyLogger; }

    MacTierra::GenotypeFrequencyDataLogger* genotypeFrequencyDataLogger() const { return mGenotypeFrequencyLogger; }
    MacTierra::SizeHistogramDataLogger*     sizeHistogramDataLogger() const     { return mSizeFrequencyLogger; }

protected:

    void setupDataCollectors();
    void clearDataCollectors();

protected:
    MacTierra::World*       mWorld;

    MacTierra::PopulationSizeLogger*        mPopSizeLogger;
    MacTierra::MeanCreatureSizeLogger*      mMeanSizeLogger;
    MacTierra::MaxFitnessDataLogger*        mFitnessFrequencyLogger;

    MacTierra::GenotypeFrequencyDataLogger* mGenotypeFrequencyLogger;
    MacTierra::SizeHistogramDataLogger*     mSizeFrequencyLogger;
    
    GenebankInventoryListener*              mGenebankListener;
};


#endif // MTWorldDataCollection_h
