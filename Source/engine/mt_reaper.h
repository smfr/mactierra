/*
 *  mt_reaper.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */



#ifndef mt_reaper_h
#define mt_reaper_h

#include <boost/intrusive/list.hpp>

#include "mt_engine.h"
#include "mt_creature.h"

namespace MacTierra {

class Creature;

typedef boost::intrusive::member_hook<Creature, ReaperListHook, &Creature::mReaperListHook> ReaperMemberHookOption;
typedef boost::intrusive::list<Creature, ReaperMemberHookOption> ReaperList;

// Reaper queue. Items appended at the end, and move up the more errors they have. Items at the head of
// the list get reaped.
class Reaper
{
public:
	Reaper();
	~Reaper();

	void addCreature(Creature& inCreature);
	void removeCreature(Creature& inCreature);

	// return true if moved
	bool conditionalMoveUp(Creature& inCreature);
	bool conditionalMoveDown(Creature& inCreature);
	
	
protected:

	ReaperList	mReaperList;

};

} // namespace MacTierra


#endif // mt_reaper_h
