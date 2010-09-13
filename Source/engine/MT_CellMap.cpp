/*
 *  MT_Cellmap.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>

#include "MT_Cellmap.h"

#include "MT_Creature.h"

namespace MacTierra {

using namespace std;

CellMap::CellMap(u_int32_t inSize)
: mSize(inSize)
, mSpaceUsed(0)
{
}

CellMap::~CellMap()
{
}

Creature*
CellMap::creatureAtAddress(address_t inAddress) const
{
    size_t index;
    if (indexOfCreatureAtAddress(inAddress, index))
        return mCells[index].mData;
    
    return NULL;
}

bool
CellMap::spaceAtAddress(address_t inAddress, u_int32_t inLength) const
{
    size_t index;
    return spaceAtAddress(inAddress, inLength, index);
}

bool
CellMap::spaceAtAddress(address_t inAddress, u_int32_t inLength, size_t& outIndex) const
{
    outIndex = -1;
    BOOST_ASSERT(inAddress < mSize);
    if (mCells.empty() && inLength <= mSize)
    {
        outIndex = 0;
        return true;
    }
    
    const size_t numCreatures = mCells.size();

    // if request wraps
    if (inAddress + inLength > mSize)
    {
        const CreatureRange& lastCreature = mCells[numCreatures - 1];
        if (lastCreature.wraps(mSize))
            return false;

        address_t endAddr = (inAddress + inLength) % mSize;
        if (!(inAddress >= lastCreature.end() && endAddr <= mCells[0].start()))
            return false;
        
        outIndex = numCreatures;
        return true;
    }
    
    address_t requestEnd = inAddress + inLength;
    
    size_t index = indexAtOrBefore(inAddress);
    BOOST_ASSERT(index < mCells.size());
    
    // check range at index
    if (mCells[index].containsOffset(inAddress, mSize))
        return false;

    if (index == 0)  // index = 0 case is special because it covers the range from 0 to the start of the second creature
    {
        // first check tail of the last (maybe wrapping) creature
        if (mCells[numCreatures - 1].containsOffset(inAddress, mSize))
            return false;
        
        // make sure we're in the gap before the first, or between the first and second
        if (requestEnd <= mCells[0].start())
        {
            outIndex = 0;
            return true;
        }
        
        if (inAddress >= mCells[0].end() && ((numCreatures == 1) || requestEnd <= mCells[1].start()))
        {
            outIndex = 1;
            return true;
        }

        return false;
    }
    else
    {
        // check end of range with range after index
        if ((index < numCreatures - 1) && requestEnd > mCells[index + 1].start())
            return false;

        outIndex = index + 1;
    }
    
    return true;
}

bool
CellMap::insertCreature(Creature* inCreature)
{
    size_t insertionIndex;
    if (!spaceAtAddress(inCreature->location(), inCreature->length(), insertionIndex))
        return false;
    
    // insert at the given index
    CreatureList::iterator insertPos = mCells.begin() + insertionIndex;
    mCells.insert(insertPos, CreatureRange(inCreature->location(), inCreature->length(), inCreature));

    BOOST_ASSERT(insertionIndex == 0 || mCells[insertionIndex].start() > mCells[insertionIndex - 1].start());
    BOOST_ASSERT(insertionIndex == mCells.size() - 1 || mCells[insertionIndex].start() < mCells[insertionIndex + 1].start());
    
    mSpaceUsed += inCreature->length();

    return true;
}

void
CellMap::removeCreature(Creature* inCreature)
{
    size_t index;
    if (indexOfCreatureAtAddress(inCreature->location(), index) && mCells[index].mData == inCreature)
    {
        CreatureList::iterator it = mCells.begin() + index;
        mCells.erase(it);
        
        mSpaceUsed -= inCreature->length();
        return;
    }
    
    // This can happen in tests
    //BOOST_ASSERT(0);
}

// distance between start and end going forward (maybe wrapping)
static inline u_int32_t forwardDelta(address_t inStart, address_t inEnd, u_int32_t inSize)
{
    return (inEnd >= inStart) ? inEnd - inStart : (inEnd + inSize) - inStart;
}

// distance between start and end going backwards (maybe wrapping)
static inline u_int32_t backwardDelta(address_t inStart, address_t inEnd, u_int32_t inSize)
{
    return (inStart >= inEnd) ? inStart - inEnd : inStart + inSize - inEnd;
}

bool
CellMap::searchForSpace(address_t& ioAddress, u_int32_t inLength, u_int32_t inMaxRange, ESearchDirection inSearchDirection) const
{
    const address_t startAddress = ioAddress;
    const size_t startIndex = indexAtOrBefore(startAddress);
    const size_t numCreatures = mCells.size();

    if (numCreatures == 0)
        return true;

    size_t curIndex = startIndex;
    bool maxedRange = false;
    bool foundGap = false;
    address_t foundLocation = 0;
    
    switch (inSearchDirection)
    {
        case kBothways:
            {
                size_t forwardIndex = curIndex;
                size_t backIndex = curIndex;
                bool forwardWrapped = false;
                bool backwardsWrapped = false;
                
                while (true)
                {
                    // pick one to advance
                    u_int32_t   forwardOffset  = forwardDelta(startAddress, mCells[forwardIndex].wrappedEnd(mSize), mSize);
                    u_int32_t   backwardOffset = backwardDelta(startAddress, (mCells[backIndex].start() - inLength + mSize) % mSize, mSize);
                
                    if (!forwardWrapped && forwardOffset <= backwardOffset)
                    {
                        if (gapAfterIndex(forwardIndex) >= inLength)
                        {
                            foundGap = true;
                            foundLocation = mCells[forwardIndex].wrappedEnd(mSize);
                            break;
                        }
                        
                        if (++forwardIndex == numCreatures)
                            forwardIndex = 0;
                        forwardWrapped = (forwardIndex == startIndex);
                    }
                    else if (!backwardsWrapped)
                    {
                        if (gapBeforeIndex(backIndex) >= inLength)
                        {
                            foundGap = true;
                            foundLocation = (mCells[backIndex].start() - inLength + mSize) % mSize;
                            break;
                        }
                        if (!--backIndex)
                            backIndex = numCreatures - 1;
                        backwardsWrapped = (backIndex == startIndex);
                    }
                    
                    if ((forwardWrapped && backwardsWrapped) ||
                        (forwardOffset > inMaxRange && backwardOffset > inMaxRange))
                        break;
                }
            }
            break;
            
        case kBackwards:
            {
                // look to start
                for (curIndex = startIndex; curIndex >= 0; --curIndex)
                {
                    if (backwardDelta(startAddress, (mCells[curIndex].start() - inLength + mSize) % mSize, mSize) > inMaxRange)
                    {
                        maxedRange = true;
                        break;
                    }
                    
                    u_int32_t gap = gapBeforeIndex(curIndex);
                    if (gap <= inLength)
                    {
                        foundGap = true;
                        foundLocation = (mCells[curIndex].start() - inLength + mSize) % mSize;
                        break;
                    }
                }
                
                if (maxedRange)
                    break;

                // wrap
                for (curIndex = numCreatures - 1; curIndex > startIndex; --curIndex)
                {
                    if (backwardDelta(startAddress, (mCells[curIndex].start() - inLength + mSize) % mSize, mSize) > inMaxRange)
                    {
                        maxedRange = true;
                        break;
                    }
                    
                    u_int32_t gap = gapBeforeIndex(curIndex);
                    if (gap <= inLength)
                    {
                        foundGap = true;
                        foundLocation = mCells[curIndex].start() - inLength;
                        break;
                    }
                }
            }
            break;
            
        case kForwards:
            {
                // look to end
                for (curIndex = startIndex; curIndex < numCreatures; ++curIndex)
                {
                    if (forwardDelta(startAddress, mCells[curIndex].start(), mSize) > inMaxRange)
                    {
                        maxedRange = true;
                        break;
                    }
                    
                    u_int32_t gap = gapAfterIndex(curIndex);
                    if (gap <= inLength)
                    {
                        foundGap = true;
                        foundLocation = (mCells[curIndex].end() % mSize);
                        break;
                    }
                }
                
                if (maxedRange)
                    break;

                // wrap
                for (curIndex = 0; curIndex < startIndex; ++curIndex)
                {
                    if (forwardDelta(startAddress, mCells[curIndex].start(), mSize) > inMaxRange)
                    {
                        maxedRange = true;
                        break;
                    }
                    
                    u_int32_t gap = gapAfterIndex(curIndex);
                    if (gap <= inLength)
                    {
                        foundGap = true;
                        foundLocation = mCells[curIndex].end();
                        break;
                    }
                }
            }
            break;
    }
    
    if (foundGap)
    {
        ioAddress = foundLocation;
        return true;
    }
    
    return false;
}

double
CellMap::fullness() const
{
    return (double)mSpaceUsed / mSize;
}

u_int32_t
CellMap::totalAdultSize(u_int32_t& outNumAdults) const
{
    u_int32_t totalSize = 0;
    u_int32_t numAdults = 0;
    
    // we could keep running totals if we are notified when creatures are born and die
    for (CreatureList::const_iterator it = mCells.begin();
         it != mCells.end();
         ++it)
    {
        CreatureRange   cell = (*it);
        const Creature*       creature = cell.mData;
        if (!creature->isEmbryo())
        {
            ++numAdults;
            totalSize += cell.length();
        }
    }
    
    outNumAdults = numAdults;
    return totalSize;
}

void
CellMap::printCreatures() const
{
    cout << "Cell Map Creatures" << endl;

    for (CreatureList::const_iterator it = mCells.begin();
         it != mCells.end();
         ++it)
    {
        CreatureRange   cell = (*it);
        Creature*       creature = cell.mData;

        cout << cell.mStart << " creature (" << creature->location() << ", " << creature->length() << ")" << endl;
    }
    
    cout << endl;
}

// return the index at or before the given address
bool
CellMap::indexOfCreatureAtAddress(address_t inAddress, size_t& outIndex) const
{
    outIndex = 0;

    if (mCells.empty())
        return false;

    int32_t  mid, low = 0, high = mCells.size() - 1;

    while (low <= high)
    {
        mid = (low + high) / 2;
        if (inAddress < mCells[mid].start())
            high = mid - 1;
        else if (inAddress >= mCells[mid].end())
            low = mid + 1;
        else
        {
            outIndex = mid;
            return true;
        }
    }
    
    // check for wrapped creature
    if (inAddress < mCells[0].start())
    {
        size_t  lastIndex = mCells.size() - 1;
        if (mCells[lastIndex].containsOffset(inAddress, mSize))
        {
            outIndex = lastIndex;
            return true;
        }
    }
    return false;
}

size_t
CellMap::indexAtOrBefore(address_t inAddress) const
{
    if (mCells.empty())
        return 0;

    const int32_t numCreatures = mCells.size();
    int32_t  mid, low = 0, high = numCreatures - 1;
    int32_t foundIndex = 0;
    
    while (low <= high)
    {
        mid = (low + high) / 2;
        if (inAddress < mCells[mid].start())
        {
            high = mid - 1;
            foundIndex = high;
        }
        else if (inAddress > mCells[mid].start())
        {
            low = mid + 1;
            foundIndex = mid;
        }
        else
        {
            foundIndex = mid;
            break;
        }
    }
    
    // check for wrapped creature
    if (inAddress < mCells[0].start())
    {
        size_t  lastIndex = numCreatures - 1;
        if (mCells[lastIndex].containsOffset(inAddress, mSize))
            foundIndex = lastIndex;
    }
    return min(max(foundIndex, 0), numCreatures - 1);
}


u_int32_t
CellMap::gapBeforeIndex(size_t inIndex) const
{
    BOOST_ASSERT(inIndex < mCells.size());

    if (mCells.empty())
        return mSize;

    const int32_t numCreatures = mCells.size();
    if (numCreatures == 1)
        return mSize - mCells[0].length();

    if (inIndex == 0)
    {
        // last may wrap
        size_t  lastIndex = numCreatures - 1;
        if (mCells[lastIndex].wraps(mSize))
            return mCells[0].start() - (mCells[lastIndex].end() % mSize);

        return (mCells[0].start() + mSize) - mCells[lastIndex].end();
    }

    return mCells[inIndex].start() - mCells[inIndex - 1].end();
}

u_int32_t
CellMap::gapAfterIndex(size_t inIndex) const
{
    BOOST_ASSERT(inIndex < mCells.size());

    if (mCells.empty())
        return mSize;

    const int32_t numCreatures = mCells.size();
    if (numCreatures == 1)
        return mSize - mCells[0].length();

    // last may wrap
    size_t  lastIndex = numCreatures - 1;
    if (inIndex == lastIndex)
    {
        if (mCells[lastIndex].wraps(mSize))
            return mCells[0].start() - (mCells[lastIndex].end() % mSize);

        return (mCells[0].start() + mSize) - mCells[lastIndex].end();
    }

    return mCells[inIndex + 1].start() - mCells[inIndex].end();
}


} // namespace MacTierra
