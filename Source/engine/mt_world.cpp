/*
 *  mt_world.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <map>
#include "NormalDistribution.hpp"

#include "mt_world.h"

#include "mt_creature.h"
#include "mt_executionUnit0.h"
#include "mt_instructionSet.h"
#include "mt_soup.h"

namespace MacTierra {

World::World()
: mRNG(0)
, mSoup(NULL)
, mNextCreatureID(1)
, mSliceSizeVariance(0.3)
, mExecution(NULL)
, mTimeSlicer(*this)
, mCurCreatureCycles(0)
, mCurCreatureSliceCycles(0)
, mSizeSelection(1.0)
, mLeannessSelection(false)
{
}

World::~World()
{
    destroyCreatures();
    delete mSoup;
    delete mExecution;
}

void
World::initializeSoup(u_int32_t inSoupSize)
{
    assert(!mSoup);
    mSoup = new Soup(inSoupSize);
    
    mExecution = new ExecutionUnit0();
    
    // FIXME get real number
    mTimeSlicer.setDefaultSliceSize(20);
}

Creature*
World::createCreature()
{
    if (!mSoup)
        return NULL;

    Creature*   theCreature = new Creature(uniqueCreatureID(), mSoup);
    
    return theCreature;
}

void
World::addCreatureToSoup(Creature* inCreature)
{
    assert(inCreature->soup() == mSoup);
    mCreatureIDMap[inCreature->creatureID()] = inCreature;
}

void
World::removeCreatureFromSoup(Creature* inCreature)
{
    assert(inCreature->soup() == mSoup);
    mCreatureIDMap.erase(inCreature->creatureID());
}

void
World::iterate(u_int32_t inNumCycles)
{
    u_int32_t   cycles = 0;
    bool        tracing = false;
    u_int32_t   numCycles = tracing ? 1 : inNumCycles;      // unless tracing
    
    Creature*   curCreature = mTimeSlicer.currentCreature();
    
    if (mCurCreatureCycles == 0)
        mCurCreatureSliceCycles = mTimeSlicer.sizeForThisSlice(curCreature, mSliceSizeVariance);
    
    while (cycles < numCycles)
    {
        if (mCurCreatureCycles < mCurCreatureSliceCycles)
        {
            // do cosmic rays
            
            
            // decide whether to throw in a flaw
            int32_t flaw = 0;

            // track leanness
            
            
            Creature* daughterCreature = mExecution->execute(*curCreature, *mSoup, flaw);
            if (daughterCreature)
                handleBirth(curCreature, daughterCreature);
        
            // if there was an error, adjust in the reaper queue
            if (curCreature->cpu().flag())
                mReaper.conditionalMoveUp(*curCreature);
            else if (curCreature->lastInstruction() == k_mal || curCreature->lastInstruction() == k_divide)
                mReaper.conditionalMoveDown(*curCreature);

            // compute next copy error time
            
            ++mCurCreatureCycles;
            mTimeSlicer.executedInstruction();
            
        }
        else        // we are at the end of the slice for one creature
        {
            
            // maybe reap
            
            
            // maybe kill off long-lived creatures
            
            
            // rotate the slicer
            bool cycled = mTimeSlicer.advance();
            if (cycled)
            {
            }
            
            // check for no creatures left
            
            
            // start on the next creature
            curCreature = mTimeSlicer.currentCreature();

            // track the new creature for tracing
            
            mCurCreatureCycles = 0;
            mCurCreatureSliceCycles = 0;
        }
    
        ++cycles;
    }
    
}


#pragma mark -

creature_id
World::uniqueCreatureID()
{
    creature_id nextID = mNextCreatureID;
    ++mNextCreatureID;
    return nextID;
}

void
World::destroyCreatures()
{
    CreatureIDMap::const_iterator theEnd = mCreatureIDMap.end();
    for (CreatureIDMap::const_iterator it = mCreatureIDMap.begin(); it != theEnd; ++it)
    {
        Creature* theCreature = (*it).second;
        delete theCreature;
    }

    mCreatureIDMap.clear();
}

void
World::handleBirth(Creature* inParent, Creature* inChild)
{
    inChild->setSliceSize(mTimeSlicer.initialSliceSizeForCreature(inChild, mSizeSelection));
    // add to slicer
    
    
    // add to reaper
    mReaper.addCreature(*inChild);
    
    // collect metabolic data
    
    
    // collect genebank data
    
    
    // inherit leanness?


    inParent->noteBirth();
}

void
World::handleDeath(Creature* inCreature)
{

    mReaper.removeCreature(*inCreature);

}

} // namespace MacTierra
