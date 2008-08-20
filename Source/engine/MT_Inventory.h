/*
 *  MT_Inventory.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef MT_Inventory_h
#define MT_Inventory_h

#include <map>

#include "MT_Engine.h"
#include "MT_Genotype.h"

namespace MacTierra {


// The inventory tracks the species that are alive now.

class Inventory
{
public:
    Inventory();
    ~Inventory();

    Genotype*       findGenotype(const genotype_t& inGenotype) const;
    
    // return true if it's new
    bool            enterGenotype(const genotype_t& inGenotype, Genotype*& outGenotype);

protected:

    std::string     uniqueNameForLength(u_int32_t inLength) const;
    
protected:

    u_int32_t       mNumSpeciesEver;
    u_int32_t       mNumSpeciesCurrent;

    u_int32_t       mSpeciationCount;
    u_int32_t       mExtinctionCount;

    typedef std::map<genotype_t, Genotype*> InventoryMap;
    typedef std::multimap<u_int32_t, Genotype*>  SizeMap;

    InventoryMap    mInventoryMap;
    SizeMap         mGenotypeSizeMap;

};

} // namespace MacTierra

#endif // MT_Inventory_h
