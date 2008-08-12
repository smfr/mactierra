/*
 *  mt_creature.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_creature_h
#define mt_creature_h

#include <boost/intrusive/list.hpp>

#include "mt_engine.h"
#include "mt_cpu.h"

namespace MacTierra {

class Soup;

typedef boost::intrusive::list_member_hook<> ReaperListHook;
typedef boost::intrusive::list_member_hook<> SlicerListHook;

class Creature
{
public:
	ReaperListHook	mReaperListHook;
	SlicerListHook	mSlicerListHook;
	
public:
	Creature(creature_id inID, Soup* inOwningSoup);

	// zero out this creature's space in the soup
	creature_id		creatureID() const	{ return mID; }
	
	Soup*			soup() const { return mSoup; }

	// move to soup?
	void			clearSpace();

	int32_t			length() const { return mLength; }
	void			setLength(int32_t inLength) { mLength = inLength; }

	u_int32_t		location() const { return mLocation; }
	void			setLocation(u_int32_t inLocation) { mLocation = inLocation; }

	u_int32_t		sliceSize() const	{ return mSliceSize; }
	void			setSliceSize(u_int32_t inSize) { mSliceSize = inSize; }

	Cpu&			cpu() { return mCPU; }

	// location pointed to by the instruction pointer
	u_int32_t		referencedLocation() const;
	// the the IP to point to the referenced location
	void			setReferencedLocation(u_int32_t inAddress);

	u_int32_t		addressFromOffset(int32_t inOffset) const;
	int32_t			offsetFromAddress(u_int32_t inAddress) const;

	bool			containsAddress(u_int32_t inAddress) const;
	
	instruction_t	getSoupInstruction(int32_t inOffset) const;

	// execute the mal instruction. can set cpu flag
	bool			startDividing();

	// execute the divide instruction. can set cpu flag
	Creature*		divide();
	
	bool			isDividing() const			{ return mDividing; }
	Creature*		daughterCreature() const	{ return mDaughter; }

	void			noteMoveToOffspring()		{ ++mMovesToLastOffspring; }

	void			noteErrors()				{ if (mCPU.mFlag) ++mNumErrors; }
	int32_t			numErrors() const			{ return mNumErrors; }
	// for testing
	void			setNumErrors(int32_t inErrors) { mNumErrors = inErrors; }

	void			executedInstruction(instruction_t inInst)
					{
						mLastInstruction = inInst;
						++mTotalInstructionsExecuted;
					}

	instruction_t	lastInstruction() const		{ return mLastInstruction; }

	void			noteBirth();
	
	bool			operator==(const Creature& inRHS)
					{
						return mID == inRHS.creatureID();
					}
private:
	
	// disallow copy construct and copy
	Creature& operator=(const Creature& inRHS);
	Creature(const Creature& inRHS);
	
protected:

	creature_id		mID;
	
	Cpu				mCPU;
	
	Soup*			mSoup;
	
	Creature*		mDaughter;
	bool			mDividing;
	
	int32_t			mLength;
	
	u_int32_t		mLocation;			// position in soup
	
	u_int32_t		mSliceSize;			// should this be here?
	instruction_t	mLastInstruction;	// ditto
	
	u_int32_t		mInstructionsToLastOffspring;
	u_int32_t		mTotalInstructionsExecuted;
	
	int32_t			mNumErrors;
	int32_t			mMovesToLastOffspring;

	int32_t			mNumOffspring;
	
	// leanness stuff
	
	
};


} // namespace MacTierra

#endif // mt_creature_h
