/*
 *  mt_timeslicer.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <math.h>
#include <algorithm>

#include "NormalDistribution.hpp"

#include "mt_timeslicer.h"

#include "mt_creature.h"
#include "mt_world.h"

namespace MacTierra {


TimeSlicer::TimeSlicer(World& inWorld)
: mWorld(inWorld)
, mDefaultSliceSize(20)
, mLastCycleInstructions(0)
, mTotalInstructions(0)
{
}

TimeSlicer::~TimeSlicer()
{
}

void
TimeSlicer::addCreature(Creature& inCreature)
{
	mSlicerList.push_back(inCreature);
}

void
TimeSlicer::removeCreature(Creature& inCreature)
{
	mSlicerList.erase(mSlicerList.iterator_to(inCreature));
}

Creature*
TimeSlicer::getFirst() const
{
	Creature&	curCreature = *mCurrentItem;
	return &curCreature;
}

bool
TimeSlicer::rotate(bool inForwards /* = true */)
{
	if (mCurrentItem == mSlicerList.end())
	{
		mCurrentItem = mSlicerList.begin();
		return true;
	}
	
	++mCurrentItem;
	return false;
}

TimeSlicer::ETimeSliceStrategy
TimeSlicer::timeSliceStrategy() const
{
	return kProportionalSize;
}

u_int32_t
TimeSlicer::initialSliceSizeForCreature(const Creature* inCreature, double inSizeSelection)
{
	if (timeSliceStrategy() == kConstantSize)
		return mDefaultSliceSize;

/*
	if (self.fLeannessSelection) then
		thisSize := System.Round(thisCreature.fLeanness * fSliceConst * exp(fSizeSelection * ln(thisCreature.fValue/80.0)))
*/
	return lround(mDefaultSliceSize * exp(inSizeSelection * log(inCreature->length() / 80.0)));
}

u_int32_t
TimeSlicer::sizeForThisSlice(const Creature* inCreature, double inSliceSizeVariance)
{
	if (inSliceSizeVariance > 0.0)
	{
		u_int32_t sliceSize = inCreature->sliceSize();
		
		RandomLib::NormalDistribution<double> normdist;
		return std::max(lround(normdist(mWorld.RNG(), sliceSize, inSliceSizeVariance)), 1L);
	}
	
	return inCreature->sliceSize();
}




} // namespace MacTierra
