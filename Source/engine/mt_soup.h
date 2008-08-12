/*
 *  mt_soup.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_soup_h
#define mt_soup_h

#include "mt_engine.h"

namespace MacTierra {

class Soup
{
public:

	Soup(u_int32_t inSize);
	~Soup();

	u_int32_t		soupSize() const { return mSoupSize; }

	
	enum ESearchDirection { kBothways, kBackwards, kForwards };
	
	bool			seachForTemplate(ESearchDirection inDirection, u_int32_t& ioOffset, u_int32_t& outLength);
	
	instruction_t	instructionAtAddress(u_int32_t inAddress) const;
	
	enum EMutationType {
		kAddOrDec,
		kBitFlip,
		kRandomChoice
	};
	EMutationType	mutationType() const	{ return kAddOrDec; } // FIXME

	instruction_t	mutateInstruction(instruction_t inInst, EMutationType inMutationType) const;

	bool			copyErrorPending() const;

	// settings
	bool			globalWritesAllowed() const;
	bool			transferRegistersToOffspring() const;
	
	enum EDaughterAllocationStrategy {
		kRandomAlloc,
		kRandomPackedAlloc,
		kClosestAlloc,
		kPreferredAlloc
	};
	
	EDaughterAllocationStrategy	daughterAllocationStrategy() const;



protected:

	
	u_int32_t	mSoupSize;
	


};

} // namespace MacTierra

#endif // mt_soup_h
