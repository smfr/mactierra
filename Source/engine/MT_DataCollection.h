/*
 *  MT_DataCollection.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_DataCollection_h
#define MT_DataCollection_h

#include <vector>
#include <string.h>

#include "MT_Engine.h"

namespace MacTierra {

class World;

// generic data logging class
class DataLogger
{
public:
    enum ECollectionType {
        kCollectionAdHoc,           // "manually driven" data collectors, like histogram collectors
        kCollectionPeriodic,
        kCollectionSlicerCycle
    };
    
    DataLogger()
    : mLastCollectionInstructions(0)
    , mLastCollectionCycles(0)
    {
    }
    virtual ~DataLogger() {}

    // override to do special processing before/after data collection
    virtual void collect(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const World* inWorld);
    
    u_int64_t       lastCollectionInstructions() const  { return mLastCollectionInstructions; }
    u_int64_t       lastCollectionCycles() const        { return mLastCollectionCycles; }

protected:

    // subclasses should override to collect their type of data
    virtual void    collectData(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const World* inWorld) = 0;

    friend class DataCollector;
    
    void            setCollector(DataCollector* inCollector)
    {
        mOwningCollector = inCollector;
        collectorChanged();
    }
    DataCollector*  collector() const { return mOwningCollector; }

    virtual void    collectorChanged() {}

protected:
    
    DataCollector*  mOwningCollector;
    u_int64_t       mLastCollectionInstructions;
    u_int64_t       mLastCollectionCycles;
};



// logger for "events" (like creature birth and death)
class EventLogger : public DataLogger
{
public:



};


// The DataCollector runs all of the installed loggers at the given collection interval.
class DataCollector
{
public:

    DataCollector();
    ~DataCollector();

    void            collectPeriodicData(u_int64_t inInstructionCount, u_int64_t inCycleCount, const World* inWorld);
    void            collectCyclicalData(u_int64_t inInstructionCount, u_int64_t inCycleCount, const World* inWorld);
    
    // For periodic loggers (which collect every N instructions)
    void            addPeriodicLogger(DataLogger* inLogger);
    bool            removePeriodicLogger(DataLogger* inLogger);

    u_int64_t       nextCollectionInstructions() const { return mNextCollectionInstructions; }
    void            setNextCollectionInstructions(u_int64_t inInst) { mNextCollectionInstructions = inInst; }
    
    u_int64_t       collectionInterval() const { return mCollectionInterval; }
    void            setCollectionInterval(u_int64_t inInterval, u_int64_t inCurrentInstructionCount);


    // For cyclical loggers (which collect every N cycles of the slicer queue)
    void            addCyclicalLogger(DataLogger* inLogger);
    bool            removeCyclicalLogger(DataLogger* inLogger);

    u_int32_t       collectionCycles() const { return mCollectionCycles; }
    void            setCollectionCycles(u_int64_t inCycles, u_int64_t inCurrentCycleCount);

    u_int64_t       nextCollectionCycle() const { return mNextCollectionCycle; }
    void            setNextCollectionCycle(u_int64_t inCycleCount) { mNextCollectionCycle = inCycleCount; }
    
protected:
    
    void            computeNextCollectionTime(u_int64_t inInstructionCount);
    void            computeNextCollectionCycles(u_int64_t inCurrentCycleCount);

protected:

    typedef std::vector<DataLogger*> DataLoggerList;

    u_int64_t       mCollectionInterval;
    u_int64_t       mNextCollectionInstructions;
    DataLoggerList  mPeriodicLoggers;

    u_int64_t       mCollectionCycles;
    u_int64_t       mNextCollectionCycle;
    DataLoggerList  mCyclicalLoggers;
};


} // namespace MacTierra

#endif // MT_DataCollection_h
