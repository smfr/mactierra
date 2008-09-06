/*
 *  MT_DataCollectors.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/30/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <set>

#include "MT_DataCollectors.h"
#include "MT_Inventory.h"
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

#pragma mark -

struct aliveReverseSort
{
    bool operator()(const InventoryGenotype* s1, const InventoryGenotype* s2) const
    {
        return s1->numberAlive() > s2->numberAlive();
    }
};

void
GenotypeFrequencyDataLogger::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
    Inventory*  inventory = inWorld->inventory();

    typedef std::set<const InventoryGenotype*, aliveReverseSort> alive_set;
    alive_set    commonGenotypeSet;
    
    u_int32_t minAlive = 1;

    // This will be pretty slow for large inventories. Maybe have the inventory move
    // extinct genotypes into a different map?
    Inventory::InventoryMap::const_iterator it, end;
    for (it = inventory->inventoryMap().begin(), end = inventory->inventoryMap().end();
         it != end;
         ++it)
    {
        const InventoryGenotype* curEntry = it->second;
        if (curEntry->numberAlive() == 0)
            continue;

        if (curEntry->numberAlive() >= minAlive)
        {
            commonGenotypeSet.insert(curEntry);
            minAlive = curEntry->numberAlive();
        }
    }

    // now pick the top N
    mData.clear();
    alive_set::const_iterator aliveIt = commonGenotypeSet.begin(), aliveEnd = commonGenotypeSet.end();
    for (u_int32_t i = 0; i < mMaxBuckets && aliveIt != aliveEnd; ++i, ++aliveIt)
    {
        const InventoryGenotype* curEntry = *aliveIt;
        mData.push_back(data_pair(curEntry->name(), curEntry->numberAlive()));
    }
}


#pragma mark -

void
SizeHistogramDataLogger::collectData(u_int64_t inInstructionCount, const World* inWorld)
{
}




} // namespace MacTierra
