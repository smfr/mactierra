/*
 *  MT_DataCollectors.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/30/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_DataCollectors.h"
#include "MT_World.h"

namespace MacTierra {

using namespace std;

// collectData is called on the engine thread
void
PopulationSizeLogger::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
    appendValue(inInstructionCount, inWorld->numAdultCreatures());
}

#pragma mark -

// collectData is called on the engine thread
void
MeanCreatureSizeLogger::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
    appendValue(inInstructionCount, inWorld->meanCreatureSize());
}



} // namespace MacTierra
