/*
 *  mt_reaper.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_reaper.h"

#include <iostream>

namespace MacTierra {

using namespace std;

Reaper::Reaper()
{
}

Reaper::~Reaper()
{
}

void
Reaper::addCreature(Creature& inCreature)
{
    assert(!inCreature.mReaperListHook.is_linked());
    mReaperList.push_back(inCreature);
}

void
Reaper::removeCreature(Creature& inCreature)
{
    mReaperList.erase(mReaperList.iterator_to(inCreature));
    assert(!inCreature.mReaperListHook.is_linked());
}

bool
Reaper::conditionalMoveUp(Creature& inCreature)
{
    if (!inCreature.mReaperListHook.is_linked())
        return false;

    ReaperList::iterator entryIt = mReaperList.iterator_to(inCreature);
    if (&(*entryIt) != &inCreature)
        return false;
    if (entryIt != mReaperList.begin())
    {
        ReaperList::iterator prevItem = entryIt;
        --prevItem;
        Creature&   prevCreature = *entryIt;
        if (inCreature.numErrors() >= prevCreature.numErrors())
        {
            // swap them
            mReaperList.erase(entryIt);
            mReaperList.insert(prevItem, inCreature);
            return true;
        }
    }
    
    return false;
}

bool
Reaper::conditionalMoveDown(Creature& inCreature)
{
    if (!inCreature.mReaperListHook.is_linked())
        return false;

    ReaperList::iterator entryIt = mReaperList.iterator_to(inCreature);
    ReaperList::iterator endIt = mReaperList.end();
    --endIt;
    if (entryIt != endIt)
    {
        ReaperList::iterator nextItem = entryIt;
        ++nextItem;
        Creature&   nextCreature = *nextItem;
        if (inCreature.numErrors() < nextCreature.numErrors())
        {
            // swap them
            mReaperList.erase(entryIt);
            ++nextItem;
            mReaperList.insert(nextItem, inCreature);
            return true;
        }
    }
    
    return false;
}

Creature*
Reaper::headCreature()
{
    if (mReaperList.empty())
        return NULL;

    Creature& firstCreature = *(mReaperList.begin());
    return &firstCreature;
}

void
Reaper::printCreatures() const
{
    cout << "Reaper list:" << endl;
    for (ReaperList::const_iterator it = mReaperList.cbegin(); it != mReaperList.cend(); ++it)
    {
        const Creature& curCreature = (*it);
        cout << "Creature " << curCreature.creatureID() << " errors: " << curCreature.numErrors() << endl;
    }
}

} // namespace MacTierra
