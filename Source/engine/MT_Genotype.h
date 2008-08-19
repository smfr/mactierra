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

// Represents a set of creatures with the same instructions. Used for
// bookkeeping in the inventory and genebank.
class Genotype
{
public:

    // note that these strings can have embedded null bytes
    Genotype(const std::string& inGenotype);
    ~Genotype();
        
    const u_int32_t     length() const;
    
    const std::string&  genotype() const    { return mGenotype; }

    std::string         printableGenotype() const;
    std::string         prettyPrintedGenotype() const;

    // does this need a hash?

protected:

    std::string         mGenotype;

};


} // namespace MacTierra

#endif // MT_Genotype_h

