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

#include <boost/assert.hpp>

#include "MT_Engine.h"
#include "MT_Genotype.h"

namespace MacTierra {


class InventoryGenotype : public Genotype
{
public:
    InventoryGenotype(const std::string& inIdentifier, const genome_t& inGenotype);
    
    void creatureBorn()
    {
        ++mNumAlive;
        ++mNumEverLived;
    }

    void creatureDied() 
    {
        BOOST_ASSERT(mNumAlive > 0);
        --mNumAlive;
    }

    u_int32_t       numberAlive() const         { return mNumAlive; }
    u_int32_t       numberEverLived() const     { return mNumEverLived; }

    u_int64_t       originInstructions() const  { return mOriginInstructions; }
    void            setOriginInstructions(u_int64_t inInstCount) { mOriginInstructions = inInstCount; }

    u_int32_t       originGenerations() const  { return mOriginGenerations; }
    void            setOriginGenerations(u_int32_t inGenerations) { mOriginGenerations = inGenerations; }

protected:

    u_int32_t       mNumAlive;
    u_int32_t       mNumEverLived;
    
    u_int64_t       mOriginInstructions;
    u_int32_t       mOriginGenerations;
};


// The inventory tracks the species that are alive now.
class Inventory
{
public:
    typedef std::map<genome_t, InventoryGenotype*> InventoryMap;
    typedef std::multimap<u_int32_t, InventoryGenotype*>  SizeMap;

    Inventory();
    ~Inventory();

    InventoryGenotype*  findGenotype(const genome_t& inGenotype) const;
    
    // return true if it's new
    bool                enterGenotype(const genome_t& inGenotype, InventoryGenotype*& outGenotype);

    void                printCreatures() const;
    
    const InventoryMap& inventoryMap() const { return mInventoryMap; }

protected:

    std::string         uniqueIdentifierForLength(u_int32_t inLength) const;
    
protected:

    u_int32_t       mNumSpeciesEver;
    u_int32_t       mNumSpeciesCurrent;

    u_int32_t       mSpeciationCount;
    u_int32_t       mExtinctionCount;

    InventoryMap    mInventoryMap;
    SizeMap         mGenotypeSizeMap;

};

} // namespace MacTierra

#endif // MT_Inventory_h
