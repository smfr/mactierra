/*
 *  MT_DataLogger.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/29/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_DataCollection.h"

#include "MT_World.h"

namespace MacTierra {

void
DataLogger::collect(u_int64_t inInstructionCount, const World* inWorld)
{
    mLastCollectionTime = inInstructionCount;
    collectData(inInstructionCount, inWorld);
}

#pragma mark -

DataCollector::DataCollector()
: mCollectionInterval(100000)
, mNextCollectionInstructions(0)
{
}

DataCollector::~DataCollector()
{
}

void
DataCollector::setCollectionInterval(u_int64_t inInterval, u_int64_t inCurrentInstructionCount)
{
    mCollectionInterval = inInterval;
    computeNextCollectionTime(inCurrentInstructionCount);
}

void
DataCollector::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
    DataLoggerList::const_iterator it;
    DataLoggerList::const_iterator end = mPeriodicLoggers.end();
    for (it = mPeriodicLoggers.begin(); it != end; ++it)
    {
        DataLogger* curLogger = *it;
        curLogger->collect(inInstructionCount, inWorld);
    }
    
    computeNextCollectionTime(inInstructionCount);
}

void
DataCollector::computeNextCollectionTime(u_int64_t inInstructionCount)
{
    mNextCollectionInstructions = inInstructionCount + mCollectionInterval;
}

void
DataCollector::addPeriodicLogger(DataLogger* inLogger)
{
    inLogger->setCollector(this);
    mPeriodicLoggers.push_back(inLogger);
}

bool
DataCollector::removeLogger(DataLogger* inLogger)
{
    DataLoggerList::iterator findIter = find(mPeriodicLoggers.begin(), mPeriodicLoggers.end(), inLogger);
    if (findIter != mPeriodicLoggers.end())
    {
        inLogger->setCollector(NULL);
        mPeriodicLoggers.erase(findIter);
        return true;
    }
    return false;
}


} // namespace MacTierra
