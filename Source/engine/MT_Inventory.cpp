/*
 *  MT_Inventory.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <sstream>

#include "MT_Inventory.h"

namespace MacTierra {

using namespace std;

Inventory::Inventory()
{
}

Inventory::~Inventory()
{
    // FIXME: delete stuff
}

Genotype*
Inventory::findGenotype(const genotype_t& inGenotype) const
{
    InventoryMap::const_iterator it = mInventoryMap.find(inGenotype);
    return (it != mInventoryMap.end()) ? it->second  : NULL;
}

bool
Inventory::enterGenotype(const genotype_t& inGenotype, Genotype*& outGenotype)
{
    InventoryMap::const_iterator it = mInventoryMap.find(inGenotype);
    if (it == mInventoryMap.end())
    {
        // not found. make a new one.
        string name = uniqueNameForLength(inGenotype.length());

        Genotype* newGenotype = new Genotype(name, inGenotype);
        mInventoryMap[inGenotype] = newGenotype;
        mGenotypeSizeMap.insert(pair<u_int32_t, Genotype*>(inGenotype.length(), newGenotype));

        outGenotype = newGenotype;
        return true;
    }

    // it exists already
    outGenotype = it->second;
    return false;
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
        --pos;
    }

    return tempString;
}

std::string
Inventory::uniqueNameForLength(u_int32_t inLength) const
{
    std::ostringstream formatter;
    formatter << inLength;
    pair<SizeMap::const_iterator, SizeMap::const_iterator> sizeRange = mGenotypeSizeMap.equal_range(inLength);
    
    if (sizeRange.first == sizeRange.second)
    {
        formatter << "aaa";
        return formatter.str();
    }
    
    SizeMap::const_iterator last = sizeRange.second;
    --last;
    const Genotype* lastGenotype = last->second;
    return incrementString(lastGenotype->name());
}


} // namespace MacTierra
