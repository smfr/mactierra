/*
 *  mt_timeslicer.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_timeslicer_h
#define mt_timeslicer_h

#include <boost/intrusive/list.hpp>

#include "mt_engine.h"
#include "mt_creature.h"

namespace MacTierra {

class World;

typedef boost::intrusive::member_hook<Creature, SlicerListHook, &Creature::mSlicerListHook> SlicerMemberHookOption;
typedef boost::intrusive::list<Creature, SlicerMemberHookOption> SlicerList;


class TimeSlicer
{
public:
	TimeSlicer(World& inWorld);
	~TimeSlicer();
	
	u_int32_t		defaultSliceSize() const				{ return mDefaultSliceSize; }
	void			setDefaultSliceSize(u_int32_t inSize)	{ mDefaultSliceSize = inSize; }

	void addCreature(Creature& inCreature);
	void removeCreature(Creature& inCreature);

	Creature*	getFirst() const;

	// returns true if it cycled
	bool		rotate(bool inForwards = true);
	
	void		executedInstruction()
				{
					++mLastCycleInstructions;
					++mTotalInstructions;
				}


	enum ETimeSliceStrategy {
		kConstantSize,
		kProportionalSize
	};
	
	ETimeSliceStrategy timeSliceStrategy() const;

	u_int32_t	initialSliceSizeForCreature(const Creature* inCreature, double inSizeSelection);

	u_int32_t   sizeForThisSlice(const Creature* inCreature, double inSliceSizeVariance);


protected:

	World&		mWorld;

	SlicerList				mSlicerList;
	SlicerList::iterator	mCurrentItem;

	u_int32_t	mDefaultSliceSize;
	
	// number of instructions for the last run through the whole slicer queue
	u_int32_t	mLastCycleInstructions;
	u_int64_t	mTotalInstructions;

};


} // namespace MacTierra


#endif // mt_timeslicer_h
