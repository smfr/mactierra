/*
 *  MT_Creature.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_Creature.h"

#include "MT_Inventory.h"
#include "MT_Soup.h"
#include "MT_World.h"       // avoid?

namespace MacTierra {

using namespace std;

Creature::Creature(creature_id inID, Soup* inOwningSoup)
: mID(inID)
, mGenotype(NULL)
, mGenotypeDivergence(0)
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
, mNumIdenticalOffspring(0)
, mGeneration(0)
{
}

Creature::~Creature()
{
    BOOST_ASSERT(!mDaughter);
}

std::string
Creature::creatureName() const
{
    BOOST_ASSERT(mGenotype);
    
    string name(mGenotype->name());
    name.append(min(mGenotypeDivergence, 5U), '\'');

    return name;
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

GenomeData
Creature::genomeData() const
{
    std::string  genotype;
    genotype.reserve(length());
    
    for (u_int32_t i = 0; i < mLength; ++i)
        genotype.push_back(getSoupInstruction(i));
    
    return GenomeData(genotype);
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

bool
Creature::genomeIdenticalToCreature(const Creature& inOther) const
{
    if (length() != inOther.length())
        return false;

    const u_int32_t soupSize = mSoup->soupSize();
    const instruction_t* soupStart = mSoup->soup();
    
    address_t selfOffset = location();
    address_t daughterOffset = inOther.location();

    for (u_int32_t i = 0; i < length(); ++ i)
    {
        if (*(soupStart + selfOffset) != *(soupStart + daughterOffset))
            return false;

        selfOffset     = (selfOffset + 1) % soupSize;
        daughterOffset = (daughterOffset + 1) % soupSize;
    }
    return true;
}

bool
Creature::gaveBirth(Creature* inDaughter)
{
    mMovesToLastOffspring = 0;
    mInstructionsToLastOffspring = mTotalInstructionsExecuted;
    ++mNumOffspring;

    // daughter gets our genotype
    inDaughter->setGeneration(generation() + 1);

    bool identicalCopy = genomeIdenticalToCreature(*inDaughter);
    if (identicalCopy)
        ++mNumIdenticalOffspring;

    return identicalCopy;
}

void
Creature::onBirth(const World& inWorld)
{
    setOriginInstructions(inWorld.timeSlicer().instructionsExecuted());
    mBorn = true;
}

void
Creature::onDeath(const World& inWorld)
{
}

void
Creature::clearDaughter()
{
    mDaughter = NULL;
    mDividing = false;
}

} // namespace MacTierra
