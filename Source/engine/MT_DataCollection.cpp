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

using namespace std;

void
DataLogger::collect(ECollectionType inCollectionType, u_int64_t inInstructionCount, u_int64_t inSlicerCycles, const World* inWorld)
{
    mLastCollectionInstructions = inInstructionCount;
    mLastCollectionCycles = inSlicerCycles;
    collectData(inCollectionType, inInstructionCount, inSlicerCycles, inWorld);
}

#pragma mark -

DataCollector::DataCollector()
: mCollectionInterval(100000)
, mNextCollectionInstructions(0)
, mCollectionCycles(20)
, mNextCollectionCycle(0)
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
DataCollector::collectPeriodicData(u_int64_t inInstructionCount, u_int64_t inCycleCount, const World* inWorld)
{
    DataLoggerList::const_iterator it;
    DataLoggerList::const_iterator end = mPeriodicLoggers.end();
    for (it = mPeriodicLoggers.begin(); it != end; ++it)
    {
        DataLogger* curLogger = *it;
        curLogger->collect(DataLogger::kCollectionPeriodic, inInstructionCount, inCycleCount, inWorld);
    }
    
    computeNextCollectionTime(inInstructionCount);
}

void
DataCollector::collectCyclicalData(u_int64_t inInstructionCount, u_int64_t inCycleCount, const World* inWorld)
{
    DataLoggerList::const_iterator it;
    DataLoggerList::const_iterator end = mCyclicalLoggers.end();
    for (it = mCyclicalLoggers.begin(); it != end; ++it)
    {
        DataLogger* curLogger = *it;
        curLogger->collect(DataLogger::kCollectionSlicerCycle, inInstructionCount, inCycleCount, inWorld);
    }
    
    computeNextCollectionCycles(inCycleCount);
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
DataCollector::removePeriodicLogger(DataLogger* inLogger)
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

void
DataCollector::setCollectionCycles(u_int64_t inCycles, u_int64_t inCurrentCycleCount)
{
    mCollectionCycles = inCycles;
    computeNextCollectionCycles(inCurrentCycleCount);
}

void
DataCollector::computeNextCollectionCycles(u_int64_t inCurrentCycleCount)
{
    mNextCollectionCycle = inCurrentCycleCount + mCollectionCycles;
}

void
DataCollector::addCyclicalLogger(DataLogger* inLogger)
{
    inLogger->setCollector(this);
    mCyclicalLoggers.push_back(inLogger);
}

bool
DataCollector::removeCyclicalLogger(DataLogger* inLogger)
{
    DataLoggerList::iterator findIter = find(mCyclicalLoggers.begin(), mCyclicalLoggers.end(), inLogger);
    if (findIter != mCyclicalLoggers.end())
    {
        inLogger->setCollector(NULL);
        mCyclicalLoggers.erase(findIter);
        return true;
    }
    return false;
}


} // namespace MacTierra
