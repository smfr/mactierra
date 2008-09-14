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
#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"
#include "MT_Creature.h"

namespace MacTierra {

class Creature;

typedef ::boost::intrusive::member_hook<Creature, ReaperListHook, &Creature::mReaperListHook> ReaperMemberHookOption;
typedef ::boost::intrusive::list<Creature, ReaperMemberHookOption> ReaperList;

// Reaper queue. Items appended at the end, and move up the more errors they have. Items at the head of
// the list get reaped.
class Reaper : Noncopyable
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

private:
    friend class ::boost::serialization::access;
    template<class Archive> void save(Archive& ar, const unsigned int version) const
    {
        // push a size
        size_t listSize = mReaperList.size();
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("list_size", listSize);

        // save the reaper list by hand (can't work the template fu to do it via serialization)
        for (ReaperList::const_iterator it = mReaperList.cbegin(); it != mReaperList.cend(); ++it)
        {
            const Creature* curCreature = &(*it);
            ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("creature", curCreature);
        }
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        size_t listSize;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("list_size", listSize);
        for (size_t i = 0; i < listSize; ++i)
        {
            Creature* curCreature;
            ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("creature", curCreature);
            mReaperList.push_back(*curCreature);
        }
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }

protected:

    ReaperList  mReaperList;
};

} // namespace MacTierra







#endif // MT_Reaper_h
