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
    DataLogger()
    : mLastCollectionTime(0)
    {
    }
    virtual ~DataLogger() {}

    void            collect(u_int64_t inInstructionCount, const World* inWorld)
    {
        mLastCollectionTime = inInstructionCount;
        collectData(inInstructionCount, inWorld);
    }
    
    u_int64_t       lastCollectionTime() const { return mLastCollectionTime; }

protected:

    virtual void    collectData(u_int64_t inInstructionCount, const World* inWorld) = 0;

protected:
    u_int64_t       mLastCollectionTime;
};



// logger for "events" (like creature birth and death)
class EventLogger : public DataLogger
{
public:



};



class DataCollector
{
public:

    DataCollector();
    ~DataCollector();

    void            collectData(u_int64_t inInstructionCount, const World* inWorld);
    
    u_int64_t       nextCollectionInstructions() const { return mNextCollectionInstructions; }

    u_int64_t       collectionInterval() const { return mCollectionInterval; }
    void            setCollectionInterval(u_int64_t inInterval, u_int64_t inCurrentInstructionCount);

    void            addLogger(DataLogger* inLogger);

protected:
    
    void            computeNextCollectionTime(u_int64_t inInstructionCount);

protected:

    u_int64_t       mCollectionInterval;
    u_int64_t       mNextCollectionInstructions;
    
    typedef std::vector<DataLogger*> DataLoggerList;
    DataLoggerList mLoggers;
};


} // namespace MacTierra

#endif // MT_DataCollection_h
