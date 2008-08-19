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


protected:


    u_int32_t       mNumSpeciesEver;
    u_int32_t       mNumSpeciesCurrent;

    u_int32_t       mSpeciationCount;
    u_int32_t       mExtinctionCount;

    class InventoryEntry
    {
    public:
    };
    
    typedef std::map<InventoryEntry*, Genotype> InventoryMap;
    
    

};

} // namespace MacTierra

#endif // MT_Inventory_h
