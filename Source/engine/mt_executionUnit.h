/*
 *  mt_executionUnit.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_executionUnit_h
#define mt_executionUnit_h

#include "mt_engine.h"

namespace MacTierra {

class Creature;
class Soup;

// This class runs instructions of a particular instruction set.
class ExecutionUnit
{
public:

	ExecutionUnit();
	~ExecutionUnit();
	
	// flaw is -1, 0, or 1
	// FIXME: get flaw from soup?
	// Returns new creature on divide instruction
	virtual Creature* execute(Creature& inCreature, Soup& inSoup, int32_t inFlaw) = 0;


protected:


};


} // namespace MacTierra


#endif // mt_executionUnit_h
