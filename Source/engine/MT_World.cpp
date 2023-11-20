/*
 *  MT_World.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#define __STDC_LIMIT_MACROS
#include <stdint.h>

#include <map>

#include <sstream>

#include "MT_World.h"

#include "RandomLib/ExponentialDistribution.hpp"

#include <boost/serialization/serialization.hpp>

#include "MT_CellMap.h"
#include "MT_Creature.h"
#include "MT_ExecutionUnit0.h"
#include "MT_Genotype.h"
#include "MT_InstructionSet.h"
#include "MT_Inventory.h"
#include "MT_Soup.h"

namespace MacTierra {

using namespace std;

World::World()
: mRNG(0)
, mSoupSize(0)
, mSoup(NULL)
, mCellMap(NULL)
, mNextCreatureID(1)
, mExecution(NULL)
, mTimeSlicer(this)
, mInventory(NULL)
, mDataCollector(NULL)
, mCurCreatureCycles(0)
, mCurCreatureSliceCycles(0)
, mCopyErrorPending(false)
, mCopiesSinceLastError(0)
, mNextCopyError(0)
, mNextFlawInstruction(0)
, mNextCosmicRayInstruction(0)
{
    mDataCollector = new DataCollector();
}

World::~World()
{
    destroyCreatures();
    delete mSoup;
    delete mCellMap;
    delete mExecution;
    delete mInventory;
    delete mDataCollector;
}

void
World::initializeSoup(u_int32_t inSoupSize)
{
    BOOST_ASSERT(!mSoup && !mCellMap);

    mSoupSize = inSoupSize;
    mSettings.recomputeMutationIntervals(mSoupSize);
    
    mSoup = new Soup(inSoupSize);
    mCellMap = new CellMap(inSoupSize);

    mExecution = new ExecutionUnit0();
    
    mInventory = new Inventory();
    
    computeNextMutationTimes();
}

PassRefPtr<Creature>
World::createCreature(u_int32_t inLength)
{
    if (!mSoup)
        return NULL;

    RefPtr<Creature> theCreature = Creature::create(uniqueCreatureID(), inLength, mSoup);
    // mCreatureIDMap is the ultimate owner of creatures. both adults and embryos are entered
    mCreatureIDMap[theCreature->creatureID()] = theCreature;
    
    //cout << "Created creature " << (void*)theCreature << " id: " << theCreature->creatureID() << endl;
    return theCreature.release();
}

void
World::eradicateCreature(Creature* inCreature)
{
    if (inCreature->isDividing())
    {
        Creature* daughterCreature = const_cast<Creature*>(inCreature->daughterCreature());
        BOOST_ASSERT(daughterCreature);
        
        if (mSettings.clearReapedCreatures())
            daughterCreature->clearSpace();

        mCellMap->removeCreature(daughterCreature);
        //cout << "Deleted daughter creature " << (void*)daughterCreature << " id: " << daughterCreature->creatureID() << endl;
        
        inCreature->clearDaughter();
        
        // remove from id map
        creatureRemoved(daughterCreature);
    }
    
    //mReaper.printCreatures();
    
    if (mSettings.clearReapedCreatures())
        inCreature->clearSpace();

    // remove from cell map
    mCellMap->removeCreature(inCreature);
    //cout << "Deleted creature " << (void*)inCreature << " id: " << inCreature->creatureID() << endl;
    
    // remove from slicer, reaper and id map
    creatureRemoved(inCreature);
    
    // no need to delete here; creatures are refcounted.
}

const Creature*
World::creatureWithID(creature_id inCreatureID) const
{
    CreatureIDMap::const_iterator it = mCreatureIDMap.find(inCreatureID);
    if (it != mCreatureIDMap.end())
        return it->second.get();

    return NULL;
}

u_int32_t
World::numAdultCreatures() const
{
    return mTimeSlicer.numCreatures();
}

double
World::meanCreatureSize() const
{
    u_int32_t numAdults;
    u_int32_t totalSize = mCellMap->totalAdultSize(numAdults);
    return (double)totalSize / numAdults;
}

void
World::printCreatures() const
{
    cout << "Creature ID map" << endl;
    CreatureIDMap::const_iterator theEnd = mCreatureIDMap.end();
    for (CreatureIDMap::const_iterator it = mCreatureIDMap.begin(); it != theEnd; ++it)
    {
        const Creature* curCreature = it->second.get();
        BOOST_ASSERT(it->first == curCreature->creatureID());
        cout << curCreature->creatureID() << " " << curCreature->creatureName() << endl;
    }
}

PassRefPtr<Creature>
World::insertCreature(address_t inAddress, const instruction_t* inInstructions, u_int32_t inLength)
{
    if (!mCellMap->spaceAtAddress(inAddress, inLength))
        return NULL;

    RefPtr<Creature> theCreature = createCreature(inLength);
    theCreature->setLocation(inAddress);
    
    mSoup->injectInstructions(inAddress, inInstructions, inLength);

    InventoryGenotype* theGenotype = NULL;
    bool isNew = mInventory->enterGenotype(theCreature->genomeData(), theGenotype);
    if (isNew)
    {
        theGenotype->setOriginInstructions(mTimeSlicer.instructionsExecuted());
        theGenotype->setOriginGenerations(1);
    }
    BOOST_ASSERT(theGenotype);
    theCreature->setGenotype(theGenotype);
    theCreature->setGeneration(1);
    mInventory->creatureBorn(theGenotype);

    theCreature->setMeanSliceSize(mTimeSlicer.initialSliceSizeForCreature(theCreature.get(), mSettings));
    theCreature->setReferencedLocation(theCreature->location());
    
    bool inserted = mCellMap->insertCreature(theCreature.get());
    BOOST_ASSERT(inserted);

    // add it to the various queues
    creatureAdded(theCreature.get());
    
    theCreature->onBirth(*this);     // IVF, kinda
    return theCreature.release();
}

void
World::iterate(u_int32_t inNumCycles)
{
    u_int32_t   cycles = 0;
    u_int32_t   numCycles = inNumCycles;      // unless tracing
    
    Creature*   curCreature = mTimeSlicer.currentCreature();
    if (!curCreature)
        return;

    if (mCurCreatureCycles == 0)
        mCurCreatureSliceCycles = mTimeSlicer.sizeForThisSlice(curCreature, mSettings.sliceSizeVariance());

    if (mTimeSlicer.instructionsExecuted() == 0 && timeForSlicerCycleDataCollection(mTimeSlicer.cycleCount()))
        mDataCollector->collectCyclicalData(mTimeSlicer.instructionsExecuted(), mTimeSlicer.cycleCount(), this);
    
    BOOST_ASSERT(mCurCreatureSliceCycles > 0);
    while (cycles < numCycles)
    {
        if (mCurCreatureCycles < mCurCreatureSliceCycles)
        {
            const u_int64_t instructionCount = mTimeSlicer.instructionsExecuted();

            // data collection
            if (timeForPeriodicDataCollection(instructionCount))
                mDataCollector->collectPeriodicData(instructionCount, mTimeSlicer.cycleCount(), this);

            // do cosmic rays
            if (timeForCosmicRay(instructionCount))
                cosmicRay(instructionCount);
            
            // decide whether to throw in a flaw
            int32_t flaw = 0;
            if (timeForFlaw(instructionCount))
                flaw = instructionFlaw(instructionCount);
            
            // TODO: track leanness

            // execute the next instruction
            RefPtr<Creature> daughterCreature = mExecution->execute(*curCreature, *this, flaw);
            if (daughterCreature)
                handleBirth(curCreature, daughterCreature.get());
        
            // if there was an error, adjust in the reaper queue
            if (curCreature->cpu().flag())
                mReaper.conditionalMoveUp(*curCreature);
            else if (curCreature->lastInstruction() == k_mal || curCreature->lastInstruction() == k_divide)
                mReaper.conditionalMoveDown(*curCreature);

            // compute next copy error time
            if ((mSettings.copyErrorRate() > 0.0) && (curCreature->lastInstruction() == k_mov_iab))
                noteInstructionCopy();
            
            ++mCurCreatureCycles;
            mTimeSlicer.executedInstruction();

            ++cycles;
        }
        else        // we are at the end of the slice for one creature
        {
            // maybe reap
            if (mCellMap->fullness() > mSettings.reapThreshold())
            {
                //mReaper.printCreatures();
                Creature* doomedCreature = mReaper.headCreature();
                //cout << "Reaping creature " << doomedCreature->creatureID() << " (" << doomedCreature->numErrors() << " errors)" << endl;
                handleDeath(doomedCreature);
            }
            
            // maybe kill off long-lived creatures
            
            
            // rotate the slicer
            bool cycled = mTimeSlicer.advance();
            if (cycled)
            {
                //mInventory->printCreatures();

                if (timeForSlicerCycleDataCollection(mTimeSlicer.cycleCount()))
                    mDataCollector->collectCyclicalData(mTimeSlicer.instructionsExecuted(), mTimeSlicer.cycleCount(), this);
            }
            
            // start on the next creature
            curCreature = mTimeSlicer.currentCreature();
            if (!curCreature)
                break;

            mCurCreatureCycles = 0;
            mCurCreatureSliceCycles = mTimeSlicer.sizeForThisSlice(curCreature, mSettings.sliceSizeVariance());
        }
    }
    
    //cout << "Executed " << mTimeSlicer.instructionsExecuted() << " instructions" << endl;
}

bool
World::stepCreature(const Creature* inCreature)
{
    // if the creature is not in the slicer list, don't do anything
    if (!inCreature->isInSlicerList())
        return false;

    // run until this creature is current
    while (mTimeSlicer.currentCreature() != inCreature)
    {
        iterate(1);
        if (inCreature->isDead())
            return false;
    }

    iterate(1);
    return true;
}

instruction_t
World::mutateInstruction(instruction_t inInst, Settings::EMutationType inMutationType) const
{
    instruction_t resultInst = inInst;

    switch (inMutationType)
    {
        case Settings::kAddOrDec:
            {
                int32_t delta = mRNG.Boolean() ? -1 : 1;
                resultInst = (inInst + kInstructionSetSize + delta) % kInstructionSetSize;
            }
            break;

        case Settings::kBitFlip:
            resultInst ^= (1 << mRNG.Integer(5));
            break;

        case Settings::kRandomChoice:
            resultInst = mRNG.Integer(kInstructionSetSize);
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
        RefPtr<Creature> theCreature = (*it).second.get();
        
        mCellMap->removeCreature(theCreature.get());

        if (theCreature->isInSlicerList())
            mTimeSlicer.removeCreature(*theCreature);

        if (theCreature->isInReaperList())
            mReaper.removeCreature(*theCreature);

        theCreature->clearDaughter();
    }

    mCreatureIDMap.clear();
}

// this allocates space for the daughter in the cell map,
// but does not enter it into any lists or change the parent.
PassRefPtr<Creature>
World::allocateSpaceForOffspring(const Creature& inParent, u_int32_t inDaughterLength)
{
    int32_t     attempts = 0;
    bool        foundLocation = false;
    address_t   location = -1;

    switch (mSettings.daughterAllocationStrategy())
    {
        case Settings::kRandomAlloc:
            {
                // Choose a random location within the addressing range
                while (attempts < kMaxMalAttempts)
                {
                    int32_t maxOffset = min((int32_t)mSoupSize, INT32_MAX);
                    u_int32_t offset = mRNG.IntegerC(-maxOffset, maxOffset);
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

        case Settings::kRandomPackedAlloc:
            {
                // Choose a random location within the addressing range
                int32_t maxOffset = min((int32_t)mSoupSize, INT32_MAX);
                u_int32_t offset = mRNG.IntegerC(-maxOffset, maxOffset);
                location = (inParent.location() + offset) % mSoupSize;
                
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;

        case Settings::kClosestAlloc:
            {
                location = inParent.addressFromOffset(inParent.cpu().mRegisters[k_bx]);     // why bx?
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;

        case Settings::kPreferredAlloc:
            {
                location = inParent.addressFromOffset(inParent.cpu().mRegisters[k_ax]);     // why ax?
                foundLocation = mCellMap->searchForSpace(location, inDaughterLength, kMaxMalSearchRange, CellMap::kBothways);
            }
            break;
    }

    RefPtr<Creature> daughter;
    if (foundLocation)
    {
        daughter = createCreature(inDaughterLength);
        daughter->setLocation(location);
    
        bool added = mCellMap->insertCreature(daughter.get());
        BOOST_ASSERT(added);
#ifndef NDEBUG
        if (!added)
            mCellMap->printCreatures();
#endif
    }
    
    return daughter.release();
}

void
World::computeNextMutationTimes()
{
    u_int64_t instructionCount = mTimeSlicer.instructionsExecuted();
    
    if (mSettings.cosmicRate() > 0.0)
        computeNextCosmicRay(instructionCount);

    if (mSettings.flawRate() > 0.0)
        computeNextInstructionFlaw(instructionCount);

    if (mSettings.copyErrorRate() > 0.0)
        computeNextCopyError();
}

void
World::noteInstructionCopy()
{
    if (mCopyErrorPending)  // just did one
    {
        computeNextCopyError();
        mCopiesSinceLastError = 0;
        mCopyErrorPending = false;
    }
    else
    {
        ++mCopiesSinceLastError;
        mCopyErrorPending = (mCopiesSinceLastError >= mNextCopyError);
    }
}

void
World::computeNextCopyError()
{
    RandomLib::ExponentialDistribution<double> expDist;
    int32_t copyErrorDelay;
    do
    {
        copyErrorDelay = expDist(mRNG, mSettings.meanCopyErrorInterval());
    } while (copyErrorDelay <= 0);
    
    mNextCopyError = copyErrorDelay;
}

void
World::handleBirth(Creature* inParent, Creature* inChild)
{
    inChild->setMeanSliceSize(mTimeSlicer.initialSliceSizeForCreature(inChild, mSettings));
    inChild->setReferencedLocation(inChild->location());

    // add to slicer and reaper
    creatureAdded(inChild);
    
    // collect metabolic data
    
    
    // collect genebank data
    
    
    // inherit leanness?


    bool bredTrue = inParent->gaveBirth(inChild);
    if (bredTrue)
    {
        InventoryGenotype* parentGenotype = NULL;

        // If the parent has not diverged, we could use its genotype. However, this may have changed
        // because of cosmic mutations, being written over etc, so we need to fetch it again.
        if (inParent->genotypeDivergence() == 0)
            parentGenotype = inParent->genotype();

        InventoryGenotype*   foundGenotype = NULL;
        BOOST_ASSERT(inParent->birthGenome().length() > 0);
        // We make the assumption that it's the "birth genome" (genome at birth) of the parent
        // that is important here. However, this isn't necessarily the case; what if a cosmic
        // ray mutation made this creature successful? What is the genome, really?
        if (mInventory->enterGenotype(inParent->birthGenome(), foundGenotype))
        {
            // it's new
            foundGenotype->setOriginInstructions(inParent->originInstructions());
            foundGenotype->setOriginGenerations(inParent->generation());
            
//            cout << "New genotype: " << foundGenotype->genome().printableGenome() << endl;
//            cout << "      parent: " << (parentGenotype ? foundGenotype->genome().printableGenome() : "unclean") << endl;
        }
        else
        {
        }

        if (parentGenotype != foundGenotype)
        {
            if (parentGenotype)
            {
                // cout << "Creature genotype changed between birth and reproduction:" << endl;
                // cout << "was: " << parentGenotype->name() << " " << parentGenotype->printableGenome() << endl;
                // cout << "now: " << foundGenotype->name() << " " << foundGenotype->printableGenome() << endl;
                // old genotype lost a member
                mInventory->creatureDied(parentGenotype);
            }

            inParent->setGenotype(foundGenotype);
            inParent->setGenotypeDivergence(0);
            mInventory->creatureBorn(foundGenotype);  // count the parent
        }

        inChild->setGenotype(foundGenotype);
        inChild->setGenotypeDivergence(0);
        
        inChild->setParentalGenotype(inParent->genotype());
        mInventory->creatureBorn(foundGenotype);  // count the child
    }
    else
    {
        // not bred true
        // FIXME: if the size changed, maybe we should just clear the genotype?
        inChild->setGenotype(inParent->genotype());
        inChild->setParentalGenotype(inParent->genotype());
        inChild->setGenotypeDivergence(inParent->genotypeDivergence() + 1);
    }
    
    inChild->onBirth(*this);
}

void
World::handleDeath(Creature* inCreature)
{
    inCreature->onDeath(*this);

    if (inCreature->genotypeDivergence() == 0)
        mInventory->creatureDied(inCreature->genotype());

    eradicateCreature(inCreature);
}

int32_t
World::instructionFlaw(u_int64_t inInstructionCount)
{
    int32_t theFlaw = mRNG.Boolean() ? 1 : -1;

    computeNextInstructionFlaw(inInstructionCount);
    
    return theFlaw;
}

void
World::computeNextInstructionFlaw(u_int64_t inInstructionCount)
{
    RandomLib::ExponentialDistribution<double> expDist;
    int64_t flawDelay;
    do 
    {
        flawDelay = static_cast<int64_t>(expDist(mRNG, mSettings.meanFlawInterval()));
    } while (flawDelay <= 0);

    mNextFlawInstruction = inInstructionCount + flawDelay;
}

void
World::cosmicRay(u_int64_t inInstructionCount)
{
    address_t   target = mRNG.Integer(mSoupSize);

    instruction_t inst = mSoup->instructionAtAddress(target);
    inst = mutateInstruction(inst, mSettings.mutationType());
    mSoup->setInstructionAtAddress(target, inst);
    
    computeNextCosmicRay(inInstructionCount);
}

void
World::computeNextCosmicRay(u_int64_t inInstructionCount)
{
    RandomLib::ExponentialDistribution<double> expDist;
    int64_t cosmicDelay;
    do
    {
        cosmicDelay = static_cast<int64_t>(expDist(mRNG, mSettings.meanCosmicTimeInterval()));
    } while (cosmicDelay <= 0);

    mNextCosmicRayInstruction = inInstructionCount + cosmicDelay;
}

void
World::creatureAdded(Creature* inCreature)
{
    BOOST_ASSERT(inCreature->soup() == mSoup);

    mTimeSlicer.insertCreature(*inCreature);
    mReaper.addCreature(*inCreature);
}

void
World::creatureRemoved(Creature* inCreature)
{
    BOOST_ASSERT(inCreature && inCreature->soup() == mSoup);

    if (inCreature->isInReaperList())
        mReaper.removeCreature(*inCreature);

    if (inCreature->isInSlicerList())
        mTimeSlicer.removeCreature(*inCreature);

    mCreatureIDMap.erase(inCreature->creatureID());
}

void
World::wasDeserialized()
{
    mDataCollector->setNextCollectionInstructions(mTimeSlicer.instructionsExecuted());
    mDataCollector->setNextCollectionCycle(mTimeSlicer.cycleCount());
}

#pragma mark -

// Settings
void
World::setSettings(const Settings& inSettings)
{
    mSettings = inSettings;
    
    if (mSoupSize > 0)
        mSettings.recomputeMutationIntervals(mSoupSize);
    
    computeNextMutationTimes();
}

void
World::setInitialRandomSeed(u_int32_t inIntialSeed)
{
    mRNG.Reseed(inIntialSeed);
}

u_int32_t
World::initialRandomSeed() const
{
    // this assumes that we seeded with just one word
    const std::vector<RandomLib::RandomSeed::seed_type>& originalSeed = mRNG.Seed();
    BOOST_ASSERT(originalSeed.size() == 1);
    return originalSeed[0];
}

} // namespace MacTierra
