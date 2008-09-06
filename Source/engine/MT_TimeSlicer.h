/*
 *  MT_Timeslicer.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Timeslicer_h
#define MT_Timeslicer_h

#include <boost/intrusive/list.hpp>
#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"
#include "MT_Creature.h"

namespace MacTierra {

class Settings;
class World;

typedef ::boost::intrusive::member_hook<Creature, SlicerListHook, &Creature::mSlicerListHook> SlicerMemberHookOption;
typedef ::boost::intrusive::list<Creature, SlicerMemberHookOption> SlicerList;

// TimeSlicer maintains a list of creatures for time slicing. New creatures are added before the current
// creature so that they get time after a full cycle. Time slicer works down the list, then wraps.
class TimeSlicer
{
public:
    TimeSlicer(World* inWorld);
    ~TimeSlicer();
    
    // creature is added before the current item (so it gets time after a full cycle)
    void        insertCreature(Creature& inCreature);
    void        removeCreature(Creature& inCreature);

    Creature*   currentCreature() const;

    // returns true if it cycled
    bool        advance(bool inForwards = true);
    
    void        executedInstruction()
                {
                    ++mLastCycleInstructions;
                    ++mTotalInstructions;
                }

    u_int64_t   instructionsExecuted() const { return mTotalInstructions; }

    u_int32_t   initialSliceSizeForCreature(const Creature* inCreature, const Settings& inSettings);

    u_int32_t   sizeForThisSlice(const Creature* inCreature, double inSliceSizeVariance);

    u_int32_t   numCreatures() const { return mSlicerList.size(); }

    void        printCreatures() const;

private:

    friend class ::boost::serialization::access;
    template<class Archive> void save(Archive& ar, const unsigned int version) const
    {
        ar & MT_BOOST_MEMBER_SERIALIZATION_NVP("world", mWorld);

        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("last_cycle_instructions", mLastCycleInstructions);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("total_instructions", mTotalInstructions);

        // push a size
        size_t listSize = mSlicerList.size();
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("list_size", listSize);

        // save the reaper list by hand (can't work the template fu to do it via serialization)
        for (SlicerList::const_iterator it = mSlicerList.cbegin(); it != mSlicerList.cend(); ++it)
        {
            const Creature* curCreature = &(*it);
            ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("creature", curCreature);
        }

        // push the current creature
        Creature* currentCreature = &(*mCurrentItem);
        ar << MT_BOOST_MEMBER_SERIALIZATION_NVP("cur_creature", currentCreature);
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("world", mWorld);

        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("last_cycle_instructions", mLastCycleInstructions);
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("total_instructions", mTotalInstructions);

        // read the size
        size_t listSize;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("list_size", listSize);
        
        // rebuild the list
        for (size_t i = 0; i < listSize; ++i)
        {
            Creature* curCreature;
            ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("creature", curCreature);
            mSlicerList.push_back(*curCreature);
        }
        
        // read the current creature
        Creature* currentCreature;
        ar >> MT_BOOST_MEMBER_SERIALIZATION_NVP("cur_creature", currentCreature);
        mCurrentItem = mSlicerList.iterator_to(*currentCreature);
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }

protected:

    World*                  mWorld;

    SlicerList              mSlicerList;
    SlicerList::iterator    mCurrentItem;
    
    // number of instructions for the last run through the whole slicer queue
    u_int32_t   mLastCycleInstructions;
    u_int64_t   mTotalInstructions;

};


} // namespace MacTierra


#endif // MT_Timeslicer_h
