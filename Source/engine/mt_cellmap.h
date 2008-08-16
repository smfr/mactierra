/*
 *  mt_cellmap.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_cellmap_h
#define mt_cellmap_h

#include <vector>

#include "mt_engine.h"
#include "mt_creature.h"

namespace MacTierra {

class Creature;

template <class T>
struct cell_range
{
    u_int32_t       mStart;
    u_int32_t       mLength;
    T               mData;

    cell_range(u_int32_t inStart, u_int32_t inLength, T inData)
    : mStart(inStart)
    , mLength(inLength)
    , mData(inData)
    {
    }
    
    u_int32_t       start() const { return mStart; }
    // unwrapped end
    u_int32_t       end() const { return mStart + mLength; }

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
};


// The CellMap tracks which bytes of the soup are used by which creature.
class CellMap {
public:
    CellMap(u_int32_t inSize);
    ~CellMap();

    
    // find creature which overlaps the given address
    Creature*   creatureAtAddress(address_t inAddress) const;
    
    bool        spaceAtAddress(address_t inAddress, u_int32_t inLength) const;
    
    // insert at location specified by creature. Return true if succeeded
    bool        insertCreature(Creature* inCreature);
    void        removeCreature(Creature* inCreature);

    enum ESearchDirection { kBothways, kBackwards, kForwards };
    bool        searchForSpace(address_t inAddress, u_int32_t inLength, ESearchDirection inSearchDirection) const;

    void        printCreatures() const;

    // public for testing
    
    // find if a creature overlaps the given address. If true, outIndex is the index of the creature
    bool        indexOfCreatureAtAddress(address_t inAddress, size_t& outIndex) const;

    // index at which to insert a creature with the given address (does not check ranges)
    size_t      indexAtOrBefore(address_t inAddress) const;

protected:

    bool        spaceAtAddress(address_t inAddress, u_int32_t inLength, size_t& outIndex) const;
    
protected:

    u_int32_t       mSize;
    
    typedef cell_range<Creature*> CreatureCell;
    typedef std::vector<CreatureCell> CreatureList;
    CreatureList    mCells;
};

} // namespace MacTierra


#endif // mt_cellmap_h

