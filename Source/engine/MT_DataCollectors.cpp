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


PopulationSizeLogger::PopulationSizeLogger()
{
}

PopulationSizeLogger::~PopulationSizeLogger()
{
}

void
PopulationSizeLogger::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
    mPopulationSize.push_back(inWorld->numAdultCreatures());
}


} // namespace MacTierra
