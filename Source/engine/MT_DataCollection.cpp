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
    DataLoggerList::const_iterator end = mLoggers.end();
    for (it = mLoggers.begin(); it != end; ++it)
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
DataCollector::addLogger(DataLogger* inLogger)
{
    mLoggers.push_back(inLogger);
}



} // namespace MacTierra
