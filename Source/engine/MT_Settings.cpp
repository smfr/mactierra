/*
 *  MT_Settings.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/24/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_Settings.h"

namespace MacTierra {

using namespace std;

Settings::Settings()
: mTimeSliceType(kSizeVariableSliceSize)
, mConstantSliceSize(20)
, mSliceSizeVariance(.0)
, mCopyErrorRate(0.0)
, mMeanCopyErrorInterval(0.0)
, mFlawRate(0.0)
, mMeanFlawInterval(0.0)
, mCosmicRate(0.0)
, mMeanCosmicTimeInterval(0.0)
, mSizeSelection(1.0)
, mLeannessSelection(false)
, mReapThreshold(0.8)
, mMutationType(kBitFlip)
, mGlobalWritesAllowed(false)
, mTransferRegistersToOffspring(false)
, mClearDaughterCells(false)
, mClearReapedCreatures(false)
, mDaughterAllocation(kPreferredAlloc)
{
}

void
Settings::updateWithSoupSize(u_int32_t inSoupSize)
{
    mMeanCosmicTimeInterval = (mCosmicRate > 0.0) ? (1.0 / (mCosmicRate * inSoupSize)) : 0.0;
}

void
Settings::setFlawRate(double inRate)
{
    mFlawRate = inRate;
    mMeanFlawInterval = (inRate > 0.0) ? 1.0 / inRate : 0.0;
}

void
Settings::setCosmicRate(double inRate, u_int32_t inSoupSize)
{
    mCosmicRate = inRate;
    mMeanCosmicTimeInterval = (inRate > 0.0) ? (1.0 / (inRate * inSoupSize)) : 0.0;
}

void
Settings::setCopyErrorRate(double inRate)
{
    mCopyErrorRate = inRate;
    mMeanCopyErrorInterval = (inRate > 0.0) ? 1.0 / inRate : 0.0;
}

bool
Settings::globalWritesAllowed() const
{
    return mGlobalWritesAllowed;
}

void
Settings::setGlobalWritesAllowed(bool inAllowed)
{
    mGlobalWritesAllowed = inAllowed;
}

bool
Settings::transferRegistersToOffspring() const
{
    return mTransferRegistersToOffspring;
}

void
Settings::setTransferRegistersToOffspring(bool inTransfer)
{
    mTransferRegistersToOffspring = inTransfer;
}

void
Settings::setMutationType(EMutationType inMutationType)
{
    mMutationType = inMutationType;
}

Settings::EDaughterAllocationStrategy
Settings::daughterAllocationStrategy() const
{
    return mDaughterAllocation;
}

void
Settings::setDaughterAllocationStrategy(EDaughterAllocationStrategy inStrategy)
{
    mDaughterAllocation = inStrategy;
}

void
Settings::recomputeMutationIntervals(u_int32_t inSoupSize)
{
    BOOST_ASSERT(inSoupSize > 0);
    mMeanCosmicTimeInterval = (mCosmicRate > 0.0) ? (1.0 / (mCosmicRate * inSoupSize)) : 0.0;
    mMeanFlawInterval = (mFlawRate > 0.0) ? 1.0 / mFlawRate : 0.0;
    mMeanCopyErrorInterval = (mCopyErrorRate > 0.0) ? 1.0 / mCopyErrorRate : 0.0;
}

} // namespace MacTierra

