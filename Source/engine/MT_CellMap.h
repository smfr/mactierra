/*
 *  MT_Cellmap.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Cellmap_h
#define MT_Cellmap_h

#include <vector>
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/split_member.hpp>

#include "MT_Engine.h"
#include "MT_Creature.h"

namespace MacTierra {

class Creature;

struct CreatureRange
{
    u_int32_t       mStart;
    u_int32_t       mLength;
    Creature*       mData;

    // default ctor for serialization only
    CreatureRange()
    : mStart(0)
    , mLength(0)
    , mData(NULL)
    {
    }
    
    CreatureRange(u_int32_t inStart, u_int32_t inLength, Creature* inData)
    : mStart(inStart)
    , mLength(inLength)
    , mData(inData)
    {
    }
    
    u_int32_t       start() const   { return mStart; }
    u_int32_t       length() const  { return mLength; }

    // unwrapped end
    u_int32_t       end() const     { return mStart + mLength; }

    u_int32_t       wrappedEnd(u_int32_t inSize) const     { return (mStart + mLength) % inSize; }
    
    // takes wrapping into account
    bool            containsOffset(u_int32_t inOffset, u_int32_t inMapLength) const
                    {
                        u_int32_t endOffset = (mStart + mLength) % inMapLength;
                        return (endOffset > mStart) ? (inOffset >= mStart && inOffset < endOffset)
                                                    : (inOffset >= mStart || inOffset < endOffset);     // wrapping case
                    }

    bool            wraps(u_int32_t inMapLength) const
                    {
                        return mStart + mLength > inMapLength;
                    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mStart);
        ar & BOOST_SERIALIZATION_NVP(mLength);
        ar & BOOST_SERIALIZATION_NVP(mData);
    }
    
};

// The CellMap tracks which bytes of the soup are used by which creature.
class CellMap
{
public:
    typedef std::vector<CreatureRange> CreatureList;

    CellMap(u_int32_t inSize);
    ~CellMap();
    
    u_int32_t   size() const { return mSize; }

    // find creature which overlaps the given address
    Creature*   creatureAtAddress(address_t inAddress) const;
    
    bool        spaceAtAddress(address_t inAddress, u_int32_t inLength) const;
    
    // insert at location specified by creature. Return true if succeeded
    bool        insertCreature(Creature* inCreature);
    void        removeCreature(Creature* inCreature);

    const CreatureList& cells() const { return mCells; }
    
    enum ESearchDirection { kBothways, kBackwards, kForwards };
    bool        searchForSpace(address_t& ioAddress, u_int32_t inLength, u_int32_t inMaxRange, ESearchDirection inSearchDirection) const;

    double      fullness() const;
    u_int32_t   numCreatures() const { return mCells.size(); }

    void        printCreatures() const;

    // public for testing
    
    // find if a creature overlaps the given address. If true, outIndex is the index of the creature
    bool        indexOfCreatureAtAddress(address_t inAddress, size_t& outIndex) const;

    // index at which to insert a creature with the given address (does not check ranges)
    size_t      indexAtOrBefore(address_t inAddress) const;

    u_int32_t   gapBeforeIndex(size_t inIndex) const;
    u_int32_t   gapAfterIndex(size_t inIndex) const;

protected:

    bool        spaceAtAddress(address_t inAddress, u_int32_t inLength, size_t& outIndex) const;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        // size is passed in via the ctor
        ar & BOOST_SERIALIZATION_NVP(mSpaceUsed);
        ar & BOOST_SERIALIZATION_NVP(mCells);
    }
    
protected:

    const u_int32_t     mSize;
    u_int32_t           mSpaceUsed;
    
    CreatureList        mCells;
};

} // namespace MacTierra


namespace boost {
namespace serialization {

template<class Archive>
inline void save_construct_data(Archive& ar, const MacTierra::CellMap* inCellMap, const unsigned int file_version)
{
    // save data required to construct instance
    u_int32_t soupSize = inCellMap->size();
    ar << BOOST_SERIALIZATION_NVP(soupSize);
}

template<class Archive>
inline void load_construct_data(Archive& ar, MacTierra::CellMap* inCellMap, const unsigned int file_version)
{
    // retrieve data from archive required to construct new instance
    u_int32_t soupSize;
    ar >> BOOST_SERIALIZATION_NVP(soupSize);
    // invoke inplace constructor to initialize instance of my_class
    ::new(inCellMap)MacTierra::CellMap(soupSize);
}

} // namespace boost
} // namespace serialization


#endif // MT_Cellmap_h

