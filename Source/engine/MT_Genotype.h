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
#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"

namespace MacTierra {

typedef std::string genome_t;

// Represents a set of creatures with the same instructions. Used for
// book-keeping in the inventory and genebank.
class Genotype
{
public:

    Genotype(const std::string& inIdentifier, const genome_t& inGenome);
    ~Genotype();
        
    u_int32_t           length() const      { return mGenome.size(); }
    
    // like "80aaa"
    std::string         name() const;
    // like "aaa"
    const std::string&  identifier() const  { return mIdentifier; }

    const genome_t&     genome() const    { return mGenome; }

    std::string         printableGenotype() const;
    std::string         prettyPrintedGenotype() const;

    bool operator < (const Genotype inRHS)
    {
        return mGenome < inRHS.genome();
    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mIdentifier);
        ar & BOOST_SERIALIZATION_NVP(mGenome);
    }

protected:

    std::string         mIdentifier;      // just the letters part
    genome_t            mGenome;

};

} // namespace MacTierra

namespace boost {
namespace serialization {

template<class Archive>
inline void save_construct_data(Archive& ar, const MacTierra::Genotype* inGenotype, const unsigned int file_version)
{
    // save data required to construct instance
    const std::string& identifier = inGenotype->identifier();
    const MacTierra::genome_t& genome = inGenotype->genome();
    ar << BOOST_SERIALIZATION_NVP(identifier);
    ar << BOOST_SERIALIZATION_NVP(genome);
}

template<class Archive>
inline void load_construct_data(Archive& ar, MacTierra::Genotype* inGenotype, const unsigned int file_version)
{
    // retrieve data from archive required to construct new instance
    std::string identifier;
    MacTierra::genome_t genome;
    ar >> BOOST_SERIALIZATION_NVP(identifier);
    ar >> BOOST_SERIALIZATION_NVP(genome);
    // invoke inplace constructor to initialize instance of my_class
    ::new(inGenotype)MacTierra::Genotype(identifier, genome);
}

} // namespace boost
} // namespace serialization


#endif // MT_Genotype_h

