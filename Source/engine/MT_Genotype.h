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

protected:

    std::string         mIdentifier;      // just the letters part
    genome_t            mGenome;

};


} // namespace MacTierra

#endif // MT_Genotype_h

