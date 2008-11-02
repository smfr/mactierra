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

Creature::Creature(creature_id inID, u_int32_t inLength, Soup* inOwningSoup)
: mID(inID)
, mGenotype(NULL)
, mParentalGenotype(NULL)
, mGenotypeDivergence(0)
, mSoup(inOwningSoup)
, mDaughter(NULL)
, mExecutedBits(inLength, 0)
, mDividing(false)
, mBorn(false)
, mDead(false)
, mLength(inLength)
, mLocation(0)
, mMeanSliceSize(0.0)
, mLeanness(0.5)
, mLastInstruction(0)
, mInstructionsToLastOffspring(0)
, mTotalInstructionsExecuted(0)
, mBirthInstructions(0)
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
    if (mGenotype)
    {
        string name(mGenotype->name());
        name.append(min(mGenotypeDivergence, 5U), '\'');
        return name;
    }

    ostringstream str;
    str << "Embryo " << mID;
    return str.str();
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
    const u_int32_t soupSize = mSoup->soupSize();
    return ((inAddress + soupSize) - mLocation) % soupSize;
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

PassRefPtr<Creature>
Creature::divide(World& inWorld)
{
    if (mDividing && mMovesToLastOffspring > (kMinPropCopied * mDaughter->length()))
    {
        RefPtr<Creature> offspring = mDaughter;
#ifdef RELATIVE_ADDRESSING
        offspring->mCPU.mInstructionPointer = 0;
#else
        offspring->mCPU.mInstructionPointer = offspring->location();
#endif
        if (inWorld.settings().transferRegistersToOffspring())
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

    return mBirthGenome == inOther.genomeData();
}

bool
Creature::gaveBirth(Creature* inDaughter)
{
    mMovesToLastOffspring = 0;
    mInstructionsToLastOffspring = mTotalInstructionsExecuted;
    ++mNumOffspring;

    // compute leanness when the creature produces its first offspring
    if (mNumOffspring == 1)
        computeLeanness();
    
    // daughter gets our genotype
    inDaughter->setGeneration(generation() + 1);
    
    // daughter inherits leanness (until its first offspring)
    // only do this if it's a true offspring?
    inDaughter->setLeanness(mLeanness);
    
    bool identicalCopy = genomeIdenticalToCreature(*inDaughter);
    if (identicalCopy)
        ++mNumIdenticalOffspring;

    return identicalCopy;
}

void
Creature::onBirth(const World& inWorld)
{
    mBirthGenome = genomeData();
    setOriginInstructions(inWorld.timeSlicer().instructionsExecuted());
    mBorn = true;
}

void
Creature::onDeath(const World& inWorld)
{
    mDead = true;
}

void
Creature::clearDaughter()
{
    mDaughter.clear();
    mDividing = false;
}

void
Creature::noteMoveToOffspring(address_t inTargetAddress)
{
    ++mMovesToLastOffspring;
}

} // namespace MacTierra
