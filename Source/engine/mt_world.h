/*
 *  mt_world.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_world_h
#define mt_world_h

#include <map>
#include "Random.hpp"

#include "mt_engine.h"

#include "mt_reaper.h"
#include "mt_timeslicer.h"

namespace MacTierra {

class Creature;
class ExecutionUnit;
class Soup;

class World
{
public:

	World();
	~World();


	void		initializeSoup(u_int32_t inSoupSize);

	Creature*	createCreature();

	void		addCreatureToSoup(Creature* inCreature);
	void		removeCreatureFromSoup(Creature* inCreature);
	
	
	void		iterate(uint32_t inNumCycles);
	
	RandomLib::Random&	RNG()	{ return mRNG; }

protected:

	creature_id		uniqueCreatureID();

	void			destroyCreatures();

	void			handleBirth(Creature* inParent, Creature* inChild);
	void			handleDeath(Creature* inCreature);

protected:

	RandomLib::Random	mRNG;

	Soup*		mSoup;

	// creature book keeping
	creature_id	mNextCreatureID;

	// creatures hashed by ID
	typedef std::map<creature_id, Creature*>	CreatureIDMap;
	CreatureIDMap		mCreatureIDMap;
	
	// creature space map
	
	
	// settings
	double			mSliceSizeVariance;	// sigma of normal distribution
	
	ExecutionUnit*	mExecution;
	
	TimeSlicer		mTimeSlicer;

	Reaper			mReaper;


	// runtime
	u_int32_t		mCurCreatureCycles;			// fAlive
	u_int32_t		mCurCreatureSliceCycles;	// fCurCpuSliceSize

	double			mSizeSelection;				// size selection
	bool			mLeannessSelection;			// select for "lean" creatures
};







} // namespace MacTierra

#endif // mt_world_h
