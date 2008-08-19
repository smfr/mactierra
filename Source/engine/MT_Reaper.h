/*
 *  MT_Reaper.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */



#ifndef MT_Reaper_h
#define MT_Reaper_h

#include <boost/intrusive/list.hpp>

#include "MT_Engine.h"
#include "MT_Creature.h"

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

    void        addCreature(Creature& inCreature);
    void        removeCreature(Creature& inCreature);

    // return true if moved
    bool        conditionalMoveUp(Creature& inCreature);
    bool        conditionalMoveDown(Creature& inCreature);
    
    Creature*   headCreature();
    
    void        reap();
    
    size_t      numberOfCreatures() const { return mReaperList.size(); }

    void        printCreatures() const;
protected:

    ReaperList  mReaperList;
};

} // namespace MacTierra


#endif // MT_Reaper_h
