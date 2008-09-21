/*
 *  MT_Inventory.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>

#include "MT_Inventory.h"
#include "MT_InventoryListener.h"

namespace MacTierra {

using namespace std;

InventoryGenotype::InventoryGenotype(const std::string& inName, const GenomeData& inGenotype)
: Genotype(inName, inGenotype)
, mNumAlive(0)
, mNumEverLived(0)
, mOriginInstructions(0)
, mOriginGenerations(0)
{
}


#pragma mark -

Inventory::Inventory()
: mNumSpeciesEver(0)
, mNumSpeciesCurrent(0)
, mSpeciationCount(0)
, mExtinctionCount(0)
, mListenerAliveThreshold(10)
{
}

Inventory::~Inventory()
{
    InventoryMap::iterator it, end;
    
    for (it = mInventoryMap.begin(), end = mInventoryMap.end();
         it != end;
         ++it)
    {
        InventoryGenotype* curEntry = it->second;
        delete curEntry;
    }
    mInventoryMap.clear();
}

InventoryGenotype*
Inventory::findGenotype(const GenomeData& inGenotype) const
{
    InventoryMap::const_iterator it = mInventoryMap.find(inGenotype);
    return (it != mInventoryMap.end()) ? it->second  : NULL;
}

bool
Inventory::enterGenotype(const GenomeData& inGenotype, InventoryGenotype*& outGenotype)
{
    InventoryMap::const_iterator it = mInventoryMap.find(inGenotype);
    if (it == mInventoryMap.end())
    {
        // not found. make a new one.
        string newIdentifier = uniqueIdentifierForLength(inGenotype.length());

        InventoryGenotype* newGenotype = new InventoryGenotype(newIdentifier, inGenotype);
        mInventoryMap[inGenotype] = newGenotype;
        mGenotypeSizeMap.insert(pair<u_int32_t, InventoryGenotype*>(inGenotype.length(), newGenotype));

        outGenotype = newGenotype;
        return true;
    }

    // it exists already
    outGenotype = it->second;
    return false;
}

void
Inventory::creatureBorn(InventoryGenotype* inGenotype)
{
    inGenotype->creatureBorn();
    if (inGenotype->numberAlive() > mListenerAliveThreshold)
        notifyListenersForGenotype(inGenotype);
}

void
Inventory::creatureDied(InventoryGenotype* inGenotype)
{
    inGenotype->creatureDied();
}

static std::string incrementString(const std::string& inString)
{
    string tempString(inString);
    
    size_t len = tempString.length();
    size_t pos = len - 1;
    while (pos >= 0)
    {
        if (tempString[pos] < 'z')
        {
            ++tempString[pos];
            break;
        }
        else
        {
            tempString[pos] = 'a';
        }
        --pos;
    }

    return tempString;
}

void
Inventory::printCreatures() const
{
    cout << "Inventory" << endl;
    
    InventoryMap::const_iterator it, end;
    
    for (it = mInventoryMap.begin(), end = mInventoryMap.end();
         it != end;
         ++it)
    {
        const InventoryGenotype* curEntry = it->second;
        cout << curEntry->name() << " alive: " << curEntry->numberAlive() << " total: " << curEntry->numberEverLived() << endl;
    }

}

void
Inventory::writeToStream(std::ostream& inStream) const
{
    InventoryMap::const_iterator it, end;
    
    inStream << "Name\t" << "Length\t" << "Alive\t" << "Ever\t" << "Origin Generations\t" << "Origin Instructions\t" << "Genotype" << endl;

    for (it = mInventoryMap.begin(), end = mInventoryMap.end();
         it != end;
         ++it)
    {
        const InventoryGenotype* curEntry = it->second;
        inStream << curEntry->name() << "\t" << curEntry->length() << "\t" << curEntry->numberAlive() << "\t" << curEntry->numberEverLived() << "\t"
            << curEntry->originGenerations() << "\t" << curEntry->originInstructions() << "\t" << curEntry->genome().printableGenome() << endl;
    }
}

void
Inventory::registerListener(InventoryListener* inListener)
{
    mListeners.push_back(inListener);
}

void
Inventory::unregisterListener(InventoryListener* inListener)
{
    ListenerVector::iterator findIter = find(mListeners.begin(), mListeners.end(), inListener);
    if (findIter != mListeners.end())
        mListeners.erase(findIter);
}

void
Inventory::notifyListenersForGenotype(const InventoryGenotype* inGenotype)
{
    NotifiedGenotypeMap::const_iterator it = mListenerNotifiedGenotypes.find(inGenotype->genome());
    if (it == mListenerNotifiedGenotypes.end())
    {
        for (ListenerVector::const_iterator it = mListeners.begin(), end = mListeners.end(); it != end; ++it)
            (*it)->noteGenotype(inGenotype);
        mListenerNotifiedGenotypes[inGenotype->genome()] = inGenotype;
    }
}

std::string
Inventory::uniqueIdentifierForLength(u_int32_t inLength) const
{
    pair<SizeMap::const_iterator, SizeMap::const_iterator> sizeRange = mGenotypeSizeMap.equal_range(inLength);
    
    if (sizeRange.first == sizeRange.second)
        return "aaaaa";
    
    SizeMap::const_iterator last = sizeRange.second;
    --last;
    const Genotype* lastGenotype = last->second;
    return incrementString(lastGenotype->identifier());
}


} // namespace MacTierra
