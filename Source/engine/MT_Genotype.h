/*
 *  MT_Genotype.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Genotype_h
#define MT_Genotype_h

#include <string>

#include <boost/serialization/binary_object.hpp>
#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"

namespace MacTierra {

class GenomeData
{
public:

    GenomeData() {}   // default ctor for serialization

    GenomeData(const std::string& inData)
    : mData(inData)
    {
    }
    
    size_t              length() const      { return mData.length(); }

    std::string&        dataString()        { return mData; }
    const std::string&  dataString() const  { return mData; }

    void                setFromPrintableGenome(const std::string& inString);
    std::string         printableGenome() const;

    bool operator < (const GenomeData& inRHS) const
    {
        return mData < inRHS.dataString();
    }

    bool operator == (const GenomeData& inRHS) const
    {
        return mData == inRHS.dataString();
    }
    
private:

    friend class ::boost::serialization::access;
    template<class Archive> void save(Archive& ar, const unsigned int version) const
    {
        size_t  genomeLength = length();
        ar << BOOST_SERIALIZATION_NVP(genomeLength);
        
        std::string data(printableGenome());
        ar << BOOST_SERIALIZATION_NVP(data);
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        size_t  genomeLength;
        ar >> BOOST_SERIALIZATION_NVP(genomeLength);      // we don't use this

        std::string data;
        ar >> BOOST_SERIALIZATION_NVP(data);
        setFromPrintableGenome(data);
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }
    
protected:

    std::string     mData;
};


// Represents a set of creatures with the same instructions. Used for
// book-keeping in the inventory and genebank.
class Genotype
{
public:

    Genotype(const std::string& inIdentifier, const GenomeData& inGenome);
    ~Genotype();
        
    u_int32_t           length() const      { return mGenome.length(); }
    
    // like "80aaa"
    std::string         name() const;
    // like "aaa"
    const std::string&  identifier() const  { return mIdentifier; }

    const GenomeData&   genome() const    { return mGenome; }

    bool operator < (const Genotype& inRHS)
    {
        return mGenome < inRHS.genome();
    }

private:

    friend class InventoryGenotype;
    Genotype() {}   // default ctor for serialization

    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mIdentifier);
        ar & BOOST_SERIALIZATION_NVP(mGenome);
    }

protected:

    std::string         mIdentifier;      // just the letters part
    GenomeData          mGenome;

};

} // namespace MacTierra

/*
namespace boost {
namespace serialization {

template<class Archive>
inline void save_construct_data(Archive& ar, const MacTierra::Genotype* inGenotype, const unsigned int file_version)
{
    // save data required to construct instance
    const std::string& identifier = inGenotype->identifier();
    const MacTierra::GenomeData& genome = inGenotype->genome();
    ar << BOOST_SERIALIZATION_NVP(identifier);
    ar << BOOST_SERIALIZATION_NVP(genome);
}

template<class Archive>
inline void load_construct_data(Archive& ar, MacTierra::Genotype* inGenotype, const unsigned int file_version)
{
    // retrieve data from archive required to construct new instance
    std::string identifier;
    MacTierra::GenomeData genome;
    ar >> BOOST_SERIALIZATION_NVP(identifier);
    ar >> BOOST_SERIALIZATION_NVP(genome);
    // invoke inplace constructor to initialize instance of my_class
    ::new(inGenotype)MacTierra::Genotype(identifier, genome);
}

} // namespace boost
} // namespace serialization
*/

#endif // MT_Genotype_h

