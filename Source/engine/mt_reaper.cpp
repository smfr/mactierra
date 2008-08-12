/*
 *  mt_reaper.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_reaper.h"


namespace MacTierra {

Reaper::Reaper()
{
}

Reaper::~Reaper()
{
}

void
Reaper::addCreature(Creature& inCreature)
{
	mReaperList.push_back(inCreature);
}

void
Reaper::removeCreature(Creature& inCreature)
{
	mReaperList.erase(mReaperList.iterator_to(inCreature));
}

bool
Reaper::conditionalMoveUp(Creature& inCreature)
{
	ReaperList::iterator entryIt = mReaperList.iterator_to(inCreature);
	if (entryIt != mReaperList.begin())
	{
		ReaperList::iterator prevItem = entryIt;
		--prevItem;
		Creature&	prevCreature = *entryIt;
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
	ReaperList::iterator entryIt = mReaperList.iterator_to(inCreature);
	ReaperList::iterator endIt = mReaperList.end();
	--endIt;
	if (entryIt != endIt)
	{
		ReaperList::iterator nextItem = entryIt;
		++nextItem;
		Creature&	nextCreature = *entryIt;
		if (inCreature.numErrors() < nextCreature.numErrors())
		{
			// swap them
			mReaperList.erase(nextItem);
			mReaperList.insert(nextItem, inCreature);
			return true;
		}
	}
	
	return false;
}



} // namespace MacTierra
