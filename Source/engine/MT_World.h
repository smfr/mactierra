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

#include <boost/serialization/export.hpp>
#include <boost/serialization/map.hpp>
#include <boost/serialization/serialization.hpp>

#define HAVE_BOOST_SERIALIZATION 1
#include <RandomLib/Random.hpp>

#include "MT_Engine.h"

#include "MT_CellMap.h"
#include "MT_ExecutionUnit.h"
#include "MT_ExecutionUnit0.h"      // needed for serialization registration
#include "MT_Inventory.h"
#include "MT_Reaper.h"
#include "MT_Soup.h"
#include "MT_Timeslicer.h"

namespace MacTierra {

class Creature;

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
    
    double          sliceSizeVariance() const       { return mSliceSizeVariance; }
    void            setSliceSizeVariance(double inVariance) { mSliceSizeVariance = inVariance; }

    double          sizeSelection() const           { return mSizeSelection; }
    void            setSizeSelection(double inSel)  { mSizeSelection = inSel; }

    bool            clearReapedCreatuers() const    { return mClearReapedCreatures; }
    void            setClearReapedCreatuers(bool inClear) { mClearReapedCreatures = inClear; }
    
    double          reapThreshold() const { return mReapThreshold; }
    void            setReapThreshold(double inThreshold) { mReapThreshold = inThreshold; }
    
    double          flawRate() const                { return mFlawRate; }
    void            setFlawRate(double inRate);

    double          cosmicRate() const              { return mCosmicRate; }
    void            setCosmicRate(double inRate);

    double          copyErrorRate() const           { return mCopyErrorRate; }
    void            setCopyErrorRate(double inRate);

    static std::string  stringFromWorld(const World* inWorld);
    static World*       worldFromString(const std::string& inString);

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


private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
//        ar.register_type(static_cast<ExecutionUnit0 *>(NULL));
//        ar.register_type(static_cast<InventoryGenotype *>(NULL));

        ar & BOOST_SERIALIZATION_NVP(mRNG);
        ar & BOOST_SERIALIZATION_NVP(mSoupSize);
        
        ar & BOOST_SERIALIZATION_NVP(mSoup);
        ar & BOOST_SERIALIZATION_NVP(mCellMap);

        ar & BOOST_SERIALIZATION_NVP(mNextCreatureID);
        ar & BOOST_SERIALIZATION_NVP(mCreatureIDMap);

        ar & BOOST_SERIALIZATION_NVP(mSliceSizeVariance);
        ar & BOOST_SERIALIZATION_NVP(mExecution);
        ar & BOOST_SERIALIZATION_NVP(mTimeSlicer);
        ar & BOOST_SERIALIZATION_NVP(mReaper);
        ar & BOOST_SERIALIZATION_NVP(mInventory);

        ar & BOOST_SERIALIZATION_NVP(mCurCreatureCycles);
        ar & BOOST_SERIALIZATION_NVP(mCurCreatureSliceCycles);

        ar & BOOST_SERIALIZATION_NVP(mCopyErrorRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanCopyErrorInterval);
        ar & BOOST_SERIALIZATION_NVP(mCopyErrorPending);
        ar & BOOST_SERIALIZATION_NVP(mCopiesSinceLastError);
        ar & BOOST_SERIALIZATION_NVP(mCurCreatureCycles);
        ar & BOOST_SERIALIZATION_NVP(mNextCopyError);

        ar & BOOST_SERIALIZATION_NVP(mFlawRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanFlawInterval);
        ar & BOOST_SERIALIZATION_NVP(mNextFlawInstruction);

        ar & BOOST_SERIALIZATION_NVP(mCosmicRate);
        ar & BOOST_SERIALIZATION_NVP(mMeanCosmicTimeInterval);
        ar & BOOST_SERIALIZATION_NVP(mCosmicRayInstruction);

        ar & BOOST_SERIALIZATION_NVP(mSizeSelection);
        ar & BOOST_SERIALIZATION_NVP(mLeannessSelection);
        ar & BOOST_SERIALIZATION_NVP(mReapThreshold);

        ar & BOOST_SERIALIZATION_NVP(mLeannessSelection);

        ar & BOOST_SERIALIZATION_NVP(mMutationType);
        ar & BOOST_SERIALIZATION_NVP(mGlobalWritesAllowed);
        ar & BOOST_SERIALIZATION_NVP(mTransferRegistersToOffspring);
        ar & BOOST_SERIALIZATION_NVP(mClearReapedCreatures);

        ar & BOOST_SERIALIZATION_NVP(mDaughterAllocation);
    }


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
