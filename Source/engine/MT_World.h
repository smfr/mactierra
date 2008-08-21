/*
 *  MT_World.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_World_h
#define MT_World_h

#include <map>
#include "Random.hpp"

#include "MT_Engine.h"

#include "MT_Reaper.h"
#include "MT_Timeslicer.h"

namespace MacTierra {

class CellMap;
class Creature;
class ExecutionUnit;
class Inventory;
class Soup;

class World
{
friend class ExecutionUnit0;
public:

    World();
    ~World();

    void            initializeSoup(u_int32_t inSoupSize);

    u_int32_t       soupSize() const    { return mSoupSize; }

    Soup*           soup() const        { return mSoup; }
    CellMap*        cellMap() const     { return mCellMap; }

    const TimeSlicer& timeSlicer() const { return mTimeSlicer; }
    const Reaper&   reaper() const  { return mReaper; }
    
    Inventory*      inventory() const   { return mInventory; }
    
    Creature*       createCreature();
    void            eradicateCreature(Creature* inCreature);
    
    Creature*       insertCreature(address_t inAddress, const instruction_t* inInstructions, u_int32_t inLength);
    
    void            iterate(uint32_t inNumCycles);
    
    RandomLib::Random&  RNG()   { return mRNG; }

    bool            copyErrorPending() const { return mCopyErrorPending; }

    enum EMutationType {
        kAddOrDec,
        kBitFlip,
        kRandomChoice
    };
    instruction_t   mutateInstruction(instruction_t inInst, EMutationType inMutationType) const;

    void            cosmicRay();

    // settings

    EMutationType   mutationType() const    { return mMutationType; }

    enum EDaughterAllocationStrategy {
        kRandomAlloc,
        kRandomPackedAlloc,
        kClosestAlloc,
        kPreferredAlloc
    };
    
    EDaughterAllocationStrategy daughterAllocationStrategy() const;
    void            setDaughterAllocationStrategy(EDaughterAllocationStrategy inStrategy);
    
    bool            globalWritesAllowed() const;
    void            setGlobalWritesAllowed(bool inAllowed);

    bool            transferRegistersToOffspring() const;
    void            setTransferRegistersToOffspring(bool inTransfer);
    
    double          sliceSizeVariance() const { return mSliceSizeVariance; }
    void            setSliceSizeVariance(double inVariance) { mSliceSizeVariance = inVariance; }

    bool            clearReapedCreatuers() const { return mClearReapedCreatures; }
    void            setClearReapedCreatuers(bool inClear) { mClearReapedCreatures = inClear; }
    
    double          reapThreshold() const { return mReapThreshold; }
    void            setReapThreshold(double inThreshold) { mReapThreshold = inThreshold; }
    
    double          flawRate() const { return mFlawRate; }
    void            setFlawRate(double inRate);

    double          cosmicRate() const { return mCosmicRate; }
    void            setCosmicRate(double inRate);

    double          copyErrorRate() const { return mCopyErrorRate; }
    void            setCopyErrorRate(double inRate);

protected:

    creature_id     uniqueCreatureID();

    void            destroyCreatures();

    // handle the 'mal' instruction
    Creature*       allocateSpaceForOffspring(const Creature& inParent, u_int32_t inDaughterLength);

    // birth happens on 'divide'
    void            handleBirth(Creature* inParent, Creature* inChild);
    void            handleDeath(Creature* inCreature);

    int32_t         instructionFlaw(u_int64_t inInstructionCount);
    bool            cosmicRay(u_int64_t inInstructionCount);

    // these add and remove from the time slicer and reaper queues.
    void            creatureAdded(Creature* inCreature);
    void            creatureRemoved(Creature* inCreature);


protected:

    mutable RandomLib::Random   mRNG;

    u_int32_t           mSoupSize;

    Soup*               mSoup;
    CellMap*            mCellMap;

    // creature book keeping
    creature_id         mNextCreatureID;

    // creatures hashed by ID
    typedef std::map<creature_id, Creature*>    CreatureIDMap;
    CreatureIDMap       mCreatureIDMap;
    
    // settings
    double          mSliceSizeVariance; // sigma of normal distribution
    
    ExecutionUnit*  mExecution;
    
    TimeSlicer      mTimeSlicer;

    Reaper          mReaper;
    
    Inventory*      mInventory;

    // runtime
    u_int32_t       mCurCreatureCycles;         // fAlive
    u_int32_t       mCurCreatureSliceCycles;    // fCurCpuSliceSize

    // maybe package these up into a "flaws" object?
    double          mCopyErrorRate;
    double          mMeanCopyErrorInterval;
    bool            mCopyErrorPending;
    u_int32_t       mCopiesSinceLastError;
    u_int32_t       mNextCopyError;
    
    double          mFlawRate;
    double          mMeanFlawInterval;
    u_int64_t       mNextFlawInstruction;

    double          mCosmicRate;
    double          mMeanCosmicTimeInterval;
    u_int64_t       mCosmicRayInstruction;
    
    double          mSizeSelection;             // size selection
    bool            mLeannessSelection;         // select for "lean" creatures

    double          mReapThreshold;     // [0, 1)

    // settings
    EMutationType   mMutationType;
    
    bool            mGlobalWritesAllowed;
    bool            mTransferRegistersToOffspring;
    bool            mClearReapedCreatures;
    
    EDaughterAllocationStrategy mDaughterAllocation;
};







} // namespace MacTierra

#endif // MT_World_h
