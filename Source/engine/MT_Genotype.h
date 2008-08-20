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

typedef std::string genotype_t;

// Represents a set of creatures with the same instructions. Used for
// bookkeeping in the inventory and genebank.
class Genotype
{
public:

    // note that these strings can have embedded null bytes
    Genotype(const std::string& inName, const genotype_t& inGenotype);
    ~Genotype();
        
    const u_int32_t     length() const;
    
    const std::string&  name() const        { return mName; }
    const genotype_t&   genotype() const    { return mGenotype; }

    std::string         printableGenotype() const;
    std::string         prettyPrintedGenotype() const;

    // does this need a hash?

    bool operator < (const Genotype inRHS)
    {
        return mGenotype < inRHS.genotype();
    }
    

protected:

    std::string         mName;
    genotype_t          mGenotype;

};


} // namespace MacTierra

#endif // MT_Genotype_h

