/*
 *  mt_world.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#define __STDC_LIMIT_MACROS
#include <stdint.h>

#include <map>
#include <iostream>

#include "RandomLib/Random.hpp"
#include "RandomLib/ExponentialDistribution.hpp"

#include "mt_world.h"

#include "mt_cellmap.h"
#include "mt_creature.h"
#include "mt_executionUnit0.h"
#include "mt_instructionSet.h"
#include "mt_soup.h"

namespace MacTierra {

using namespace std;

World::World()
: mRNG(0)
, mSoupSize(0)
, mSoup(NULL)
, mCellMap(NULL)
, mNextCreatureID(1)
, mSliceSizeVariance(0.3)
, mExecution(NULL)
, mTimeSlicer(*this)
, mCurCreatureCycles(0)
, mCurCreatureSliceCycles(0)
, mCopyErrorRate(0.0)
, mCopyErrorPending(false)
, mCopiesSinceLastError(0)
, mNextCopyError(0)
, mFlawRate(0.0)
, mNextFlawInstruction(0)
, mCosmicRate(0.0)
, mCosmicRayInstruction(0)
, mSizeSelection(1.0)
, mLeannessSelection(false)
, mReapThreshold(0.8)
, mMutationType(kAddOrDec)
, mGlobalWritesAllowed(false)
, mTransferRegistersToOffspring(false)
, mDaughterAllocation(kPreferredAlloc)
{
}

World::~World()
{
    destroyCreatures();
    delete mSoup;
    delete mCellMap;
    delete mExecution;
}

void
World::initializeSoup(u_int32_t inSoupSize)
{
    assert(!mSoup && !mCellMap);
    mSoupSize = inSoupSize;
    
    mSoup = new Soup(inSoupSize);
    mCellMap = new CellMap(inSoupSize);

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
World::eradicateCreature(Creature* inCreature)
{
    // remove from cell map
    mCellMap->removeCreature(inCreature);
    
    // remove from slicer and reaper
    creatureRemoved(inCreature);
}

Creature*
World::insertCreature(address_t inAddress, const instruction_t* inInstructions, u_int32_t inLength)
{
    if (!mCellMap->spaceAtAddress(inAddress, inLength))
        return NULL;

    Creature* theCreature = createCreature();

    theCreature->setLocation(inAddress);
    theCreature->setLength(inLength);
    
    mSoup->injectInstructions(inAddress, inInstructions, inLength);
    
    bool inserted = mCellMap->insertCreature(theCreature);
    assert(inserted);
    
    // add it to the various queues
    creatureAdded(theCreature);
    
    return theCreature;
}

void
World::iterate(u_int32_t inNumCycles)
{
    u_int32_t   cycles = 0;
    bool        tracing = false;
    u_int32_t   numCycles = tracing ? 1 : inNumCycles;      // unless tracing
    
    Creature*   curCreature = mTimeSlicer.currentCreature();
    if (!curCreature)
        return;

    if (mCurCreatureCycles == 0)
        mCurCreatureSliceCycles = mTimeSlicer.sizeForThisSlice(curCreature, mSliceSizeVariance);
    
    while (cycles < numCycles)
    {
        if (mCurCreatureCycles < mCurCreatureSliceCycles)
        {
            // do cosmic rays
            cosmicRay(mTimeSlicer.instructionsExecuted());
            
            // decide whether to throw in a flaw
            int32_t flaw = instructionFlaw(mTimeSlicer.instructionsExecuted());
            
            // track leanness
            
            Creature* daughterCreature = mExecution->execute(*curCreature, *this, flaw);
            if (daughterCreature)
                handleBirth(curCreature, daughterCreature);
        
            // if there was an error, adjust in the reaper queue
            if (curCreature->cpu().flag())
                mReaper.conditionalMoveUp(*curCreature);
            else if (curCreature->lastInstruction() == k_mal || curCreature->lastInstruction() == k_divide)
                mReaper.conditionalMoveDown(*curCreature);

            // compute next copy error time
            if  (mCopyErrorRate > 0.0 & (curCreature->lastInstruction() == k_mov_iab))
            {
                if (mCopyErrorPending)  // just did one
                {
                    RandomLib::ExponentialDistribution<double> expDist;
                    int32_t copyErrorDelay = expDist(mRNG, mCopyErrorRate);
                    assert(copyErrorDelay > 0);
                    mNextCopyError = copyErrorDelay;
                    mCopiesSinceLastError = 0;
                    mCopyErrorPending = false;
                }
                else
                {
                    ++mCopiesSinceLastError;
                    mCopyErrorPending = (mCopiesSinceLastError == mNextCopyError);
                }
            }
            
            ++mCurCreatureCycles;
            mTimeSlicer.executedInstruction();
        }
        else        // we are at the end of the slice for one creature
        {
            
            // maybe reap
            if (mCellMap->fullness() > mReapThreshold)
                eradicateCreature(mReaper.headCreature());
            
            // maybe kill off long-lived creatures
            
            
            // rotate the slicer
            bool cycled = mTimeSlicer.advance();
            if (cycled)
            {
            }
            
            // start on the next creature
            curCreature = mTimeSlicer.currentCreature();
            if (!curCreature)
                break;

            // track the new creature for tracing
            
            mCurCreatureCycles = 0;
            mCurCreatureSliceCycles = mTimeSlicer.sizeForThisSlice(curCreature, mSliceSizeVariance);
        }
    
        ++cycles;
    }
    
    
    cout << "Executed " << mTimeSlicer.instructionsExecuted() << " instructions" << endl;
}

instruction_t
World::mutateInstruction(instruction_t inInst, EMutationType inMutationType) const
{
    RandomLib::Random rng(mRNG);
    instruction_t resultInst = inInst;

    switch (inMutationType)
    {
        case kAddOrDec:
            {
                int32_t delta = rng.Boolean() ? -1 : 1;
                resultInst = (inInst + kInstructionSetSize + delta) % kInstructionSetSize;
            }
            break;

        case kBitFlip:
            resultInst ^= (1 << rng.Integer(5));
            break;

        case kRandomChoice:
            resultInst = rng.Integer(kInstructionSetSize);
            break;
    }
    return resultInst;
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
        
        mCellMap->removeCreature(theCreature);

        mTimeSlicer.removeCreature(*theCreature);
        mReaper.removeCreature(*theCreature);

        delete theCreature;
    }

    mCreatureIDMap.clear();
}

// this allocates space for the daughter in the cell map,
// but does not enter it into any lists or change the parent.
Creature*
World::allocateSpaceForOffspring(const Creature& inParent, u_int32_t inDaughterLength)
{
    int32_t     attempts = 0;
    bool        foundLocation = false;
    address_t   location = -1;

    switch (daughterAllocationStrategy())
    {
        case kRandomAlloc:
            {
                // Choose a random location within the addressing range
                RandomLib::Random rng(mRNG);
                
                while (attempts < kMaxMalAttempts)
                {
                    int32_t maxOffset = min((int32_t)mSoupSize, INT32_MAX);
                    u_int32_t offset = rng.IntegerC(-maxOffset, maxOffset);
                    location = (inParent.location() + offset) % mSoupSize;
                    
                    if (mCellMap->spaceAtAddress(location, inDaughterLength))
                    {
                        foundLocation = true;
                        break;
                    }
                    ++attempts;
                }
            }
            break;

        case kRandomPackedAlloc:
            {
                // Choose a random location within the addressing range
                RandomLib::Random rng(mRNG);
                
                int32_t maxOffset = min((int32_t)mSoupSize, INT32_MAX);
                u_int32_t offset = rng.IntegerC(-maxOffset, maxOffset);
                location = (inParent.location() + offset) % mSoupSize;
                
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;

        case kClosestAlloc:
            {
                location = inParent.addressFromOffset(inParent.cpu().mRegisters[k_bx]);     // why bx?
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;

        case kPreferredAlloc:
            {
                location = inParent.addressFromOffset(inParent.cpu().mRegisters[k_ax]);     // why ax?
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;
    }

    Creature*   daughter = NULL;
    if (foundLocation)
    {
        daughter = createCreature();
        daughter->setLocation(location);
        daughter->setLength(inDaughterLength);
    
        bool added = mCellMap->insertCreature(daughter);
        if (!added)
            cout << "adding daughter failed" << endl;
        assert(added);
    }
    
    return daughter;
}

void
World::handleBirth(Creature* inParent, Creature* inChild)
{
    inChild->setSliceSize(mTimeSlicer.initialSliceSizeForCreature(inChild, mSizeSelection));

    // add to slicer and reaper
    creatureAdded(inChild);
    
    // collect metabolic data
    
    
    // collect genebank data
    
    
    // inherit leanness?


    inParent->noteBirth();
}

void
World::handleDeath(Creature* inCreature)
{
    eradicateCreature(inCreature);
}

int32_t
World::instructionFlaw(u_int64_t inInstructionCount)
{
    if (mFlawRate > 0 && inInstructionCount == mNextFlawInstruction)
    {
        RandomLib::Random rng(mRNG);
        int32_t theFlaw = rng.Boolean() ? 1 : -1;

        RandomLib::ExponentialDistribution<double> expDist;
        int64_t flawDelay = static_cast<int64_t>(expDist(mRNG, mFlawRate));
        assert(flawDelay > 0);
        mNextFlawInstruction = inInstructionCount + flawDelay;
        
        return theFlaw;
    }
    return 0;
}

bool
World::cosmicRay(u_int64_t inInstructionCount)
{
    if (mCosmicRate > 0.0 && inInstructionCount == mCosmicRayInstruction)
    {
        RandomLib::Random rng(mRNG);
        address_t   target = rng.Integer(mSoupSize);

        instruction_t inst = mSoup->instructionAtAddress(target);
        inst = mutateInstruction(inst, mutationType());
        mSoup->setInstructionAtAddress(target, inst);
        
        RandomLib::ExponentialDistribution<double> expDist;
        int64_t cosmicDelay = static_cast<int64_t>(expDist(mRNG, mCosmicRate));
        assert(cosmicDelay > 0);
        mCosmicRayInstruction = inInstructionCount + cosmicDelay;
        return true;
    }
    return false;
}

void
World::creatureAdded(Creature* inCreature)
{
    assert(inCreature->soup() == mSoup);

    mCreatureIDMap[inCreature->creatureID()] = inCreature;
    
    mTimeSlicer.insertCreature(*inCreature);
    mReaper.addCreature(*inCreature);
}

void
World::creatureRemoved(Creature* inCreature)
{
    assert(inCreature && inCreature->soup() == mSoup);

    mReaper.removeCreature(*inCreature);
    mTimeSlicer.removeCreature(*inCreature);

    mCreatureIDMap.erase(inCreature->creatureID());
}

#pragma mark -

// Settings

bool
World::globalWritesAllowed() const
{
    return mGlobalWritesAllowed;
}

void
World::setGlobalWritesAllowed(bool inAllowed)
{
    mGlobalWritesAllowed = inAllowed;
}

bool
World::transferRegistersToOffspring() const
{
    return mTransferRegistersToOffspring;
}

void
World::setTransferRegistersToOffspring(bool inTransfer)
{
    mTransferRegistersToOffspring = inTransfer;
}

World::EDaughterAllocationStrategy
World::daughterAllocationStrategy() const
{
    return mDaughterAllocation;
}

void
World::setDaughterAllocationStrategy(EDaughterAllocationStrategy inStrategy)
{
    mDaughterAllocation = inStrategy;
}



} // namespace MacTierra
