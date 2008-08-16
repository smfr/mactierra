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

namespace MacTierra {

Creature::Creature(creature_id inID, Soup* inOwningSoup)
: mID(inID)
, mSoup(inOwningSoup)
, mDaughter(NULL)
, mDividing(false)
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


void
Creature::clearSpace()
{

}


u_int32_t
Creature::referencedLocation() const
{
    return addressFromOffset(mCPU.mInstructionPointer);
}

void
Creature::setReferencedLocation(u_int32_t inAddress)
{
    mCPU.mInstructionPointer = offsetFromAddress(inAddress);
}

u_int32_t
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

bool
Creature::startDividing()
{

    return false;
}

Creature*
Creature::divide()
{
    if (mDividing && mMovesToLastOffspring > (kMinPropCopied * mDaughter->length()))
    {
        Creature*   offspring = mDaughter;
#ifdef RELATIVE_ADDRESSING
        offspring->mCPU.mInstructionPointer = 0;
#else
        offspring->mCPU.mInstructionPointer = offspring->location();
#endif
        if (mSoup->transferRegistersToOffspring())
        {
            for (int32_t i = 0; i < kNumRegisters; ++i)
                offspring->mCPU.mRegisters[i] = mCPU.mRegisters[i];
        }

        mDaughter = NULL;
        mDividing = false;
        return offspring;
    }
    
    mCPU.setFlag();
    return NULL;
}

void
Creature::noteBirth()
{
    mMovesToLastOffspring = 0;
    mInstructionsToLastOffspring = mTotalInstructionsExecuted;
    ++mNumOffspring;
}


} // namespace MacTierra
