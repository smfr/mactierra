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
#include <boost/serialization/export.hpp>
#include <boost/serialization/map.hpp>
#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"
#include "MT_Genotype.h"

namespace MacTierra {


class InventoryGenotype : public Genotype
{
public:
    InventoryGenotype(const std::string& inIdentifier, const GenomeData& inGenotype);
    
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

private:

    InventoryGenotype() // default ctor for serialization
    : mNumAlive(0)
    , mNumEverLived(0)
    , mOriginInstructions(0)
    , mOriginGenerations(0)
    {
    }

    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_BASE_OBJECT_NVP(Genotype);
        
        ar & BOOST_SERIALIZATION_NVP(mNumAlive);
        ar & BOOST_SERIALIZATION_NVP(mNumEverLived);

        ar & BOOST_SERIALIZATION_NVP(mOriginInstructions);
        ar & BOOST_SERIALIZATION_NVP(mOriginGenerations);
    }

protected:

    u_int32_t       mNumAlive;
    u_int32_t       mNumEverLived;
    
    u_int64_t       mOriginInstructions;
    u_int32_t       mOriginGenerations;
};

} // namespace MacTierra

//BOOST_CLASS_EXPORT_GUID(MacTierra::InventoryGenotype, "InventoryGenotype")


namespace MacTierra {


// The inventory tracks the species that are alive now.
class Inventory
{
public:
    typedef std::map<GenomeData, InventoryGenotype*> InventoryMap;
    typedef std::multimap<u_int32_t, InventoryGenotype*>  SizeMap;

    Inventory();
    ~Inventory();

    InventoryGenotype*  findGenotype(const GenomeData& inGenotype) const;
    
    // return true if it's new
    bool                enterGenotype(const GenomeData& inGenotype, InventoryGenotype*& outGenotype);

    void                printCreatures() const;
    
    const InventoryMap& inventoryMap() const { return mInventoryMap; }

    void            writeToStream(std::ostream& inStream) const;

protected:

    std::string         uniqueIdentifierForLength(u_int32_t inLength) const;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mNumSpeciesEver);
        ar & BOOST_SERIALIZATION_NVP(mNumSpeciesCurrent);

        ar & BOOST_SERIALIZATION_NVP(mSpeciationCount);
        ar & BOOST_SERIALIZATION_NVP(mExtinctionCount);

        ar & BOOST_SERIALIZATION_NVP(mInventoryMap);
        ar & BOOST_SERIALIZATION_NVP(mGenotypeSizeMap);
    }
    
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
