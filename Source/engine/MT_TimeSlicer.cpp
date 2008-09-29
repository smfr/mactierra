/*
 *  MT_Timeslicer.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <math.h>
#include <iostream>
#include <algorithm>

#include "NormalDistribution.hpp"

#include "MT_Timeslicer.h"

#include "MT_Creature.h"
#include "MT_Settings.h"
#include "MT_World.h"

namespace MacTierra {

using namespace std;

TimeSlicer::TimeSlicer(World* inWorld)
: mWorld(inWorld)
, mLastCycleInstructions(0)
, mTotalInstructions(0)
{
}

TimeSlicer::~TimeSlicer()
{
}

void
TimeSlicer::insertCreature(Creature& inCreature)
{
    BOOST_ASSERT(!inCreature.mSlicerListHook.is_linked());
    if (mSlicerList.empty())
    {
        mSlicerList.push_back(inCreature);
        mCurrentItem = mSlicerList.begin();
    }
    else
    {
        // insert before the current item
        mSlicerList.insert(mCurrentItem, inCreature);
    }
}

void
TimeSlicer::removeCreature(Creature& inCreature)
{
    SlicerList::iterator target = mSlicerList.iterator_to(inCreature);
    if (mCurrentItem == target)
        advance();
    mSlicerList.erase(target);
    BOOST_ASSERT(!inCreature.mSlicerListHook.is_linked());
}

Creature*
TimeSlicer::currentCreature() const
{
    if (mSlicerList.empty())
        return NULL;

    Creature&   curCreature = *mCurrentItem;
    return &curCreature;
}

bool
TimeSlicer::advance(bool inForwards /* = true */)
{
    ++mCurrentItem;
    if (mCurrentItem == mSlicerList.end())
    {
        mCurrentItem = mSlicerList.begin();
        return true;
    }
    return false;
}

double
TimeSlicer::initialSliceSizeForCreature(const Creature* inCreature, const Settings& inSettings)
{
    if (inSettings.timeSliceType() == Settings::kConstantSlizeSize)
        return inSettings.constantSliceSize();

    double sliceSize = inSettings.constantSliceSize() * exp(inSettings.sizeSelection() * log(inCreature->length() / 80.0));
    
    if (inSettings.selectForLeanness())
        sliceSize *= inCreature->leanness();

    return sliceSize;
}

u_int32_t
TimeSlicer::sizeForThisSlice(const Creature* inCreature, double inSliceSizeVariance)
{
    if (inSliceSizeVariance > 0.0)
    {
        double sliceSize = inCreature->meanSliceSize();
        
        RandomLib::NormalDistribution<double> normdist;
        return std::max(lround(normdist(mWorld->RNG(), sliceSize, inSliceSizeVariance)), 1L);
    }
    
    return lround(inCreature->meanSliceSize());
}

void
TimeSlicer::printCreatures() const
{
    cout << "Slicer list:" << endl;
    for (SlicerList::const_iterator it = mSlicerList.cbegin(); it != mSlicerList.cend(); ++it)
    {
        const Creature& curCreature = (*it);
        cout << "Creature " << curCreature.creatureID();
        if (it == mCurrentItem)
            cout << " <--- current ";
        cout << endl;
    }
}



} // namespace MacTierra
