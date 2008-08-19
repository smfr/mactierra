/*
 *  mt_creature.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_creature.h"

#include "mt_soup.h"
#include "mt_world.h"       // avoid?

namespace MacTierra {

Creature::Creature(creature_id inID, Soup* inOwningSoup)
: mID(inID)
, mSoup(inOwningSoup)
, mDaughter(NULL)
, mDividing(false)
, mBorn(false)
, mLength(0)
, mLocation(0)
, mSliceSize(0)
, mLastInstruction(0)
, mInstructionsToLastOffspring(0)
, mTotalInstructionsExecuted(0)
, mNumErrors(0)
, mMovesToLastOffspring(0)
, mNumOffspring(0)
{
}

Creature::~Creature()
{
    BOOST_ASSERT(!mDaughter);
}

address_t
Creature::referencedLocation() const
{
    return addressFromOffset(mCPU.mInstructionPointer);
}

void
Creature::setReferencedLocation(u_int32_t inAddress)
{
    mCPU.mInstructionPointer = offsetFromAddress(inAddress);
}

address_t
Creature::addressFromOffset(int32_t inOffset) const
{
#ifdef RELATIVE_ADDRESSING
    const u_int32_t soupSize = mSoup->soupSize();
    return (mLocation + inOffset + soupSize) % soupSize;
#else
    return (inOffset + soupSize) % soupSize;
#endif
}

int32_t
Creature::offsetFromAddress(u_int32_t inAddress) const
{
#ifdef RELATIVE_ADDRESSING
    return (int32_t)inAddress - mLocation;      // wrap to soup size?
#else
    return inAddress;
#endif
}

instruction_t
Creature::getSoupInstruction(int32_t inOffset) const
{
    return mSoup->instructionAtAddress(addressFromOffset(inOffset));
}

void
Creature::getGenome(genome_t& outGenome) const
{
    outGenome.clear();
    
    outGenome.reserve(mLength);
    // not the most efficient

    for (u_int32_t i = 0; i < mLength; ++i)
        outGenome.push_back(getSoupInstruction(i));
}

void
Creature::clearSpace()
{
    for (u_int32_t i = 0; i < mLength; ++i)
        mSoup->setInstructionAtAddress(addressFromOffset(i), 0);
}

void
Creature::startDividing(Creature* inDaughter)
{
    assert(!mDividing && !mDaughter);
    mDaughter = inDaughter;
    mDividing = true;
}

Creature*
Creature::divide(World& inWorld)
{
    if (mDividing && mMovesToLastOffspring > (kMinPropCopied * mDaughter->length()))
    {
        Creature*   offspring = mDaughter;
#ifdef RELATIVE_ADDRESSING
        offspring->mCPU.mInstructionPointer = 0;
#else
        offspring->mCPU.mInstructionPointer = offspring->location();
#endif
        if (inWorld.transferRegistersToOffspring())
        {
            for (int32_t i = 0; i < kNumRegisters; ++i)
                offspring->mCPU.mRegisters[i] = mCPU.mRegisters[i];
        }

        clearDaughter();
        return offspring;
    }
    
    mCPU.setFlag();
    return NULL;
}

void
Creature::gaveBirth()
{
    mMovesToLastOffspring = 0;
    mInstructionsToLastOffspring = mTotalInstructionsExecuted;
    ++mNumOffspring;
}

void
Creature::wasBorn()
{
    mBorn = true;
}

void
Creature::clearDaughter()
{
    mDaughter = NULL;
    mDividing = false;
}



} // namespace MacTierra
