/*
 *  MT_Genotype.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <sstream>

#include "MT_Genotype.h"

namespace MacTierra {

Genotype::Genotype(const std::string& inIdentifier, const std::string& inGenome)
: mIdentifier(inIdentifier)
, mGenome(inGenome)
{
}

Genotype::~Genotype()
{
}

std::string
Genotype::name() const
{
    std::ostringstream formatter;
    formatter << mGenome.length() << mIdentifier;
    return formatter.str();
}

std::string
Genotype::printableGenotype() const
{
    const char hexChars[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
 
    std::string prettyString;
    
    for (u_int32_t i = 0; i < mGenome.length(); ++i)
    {
        if (i > 0)
            prettyString.push_back(' ');
        prettyString.push_back(hexChars[(mGenome[i] >> 4) & 0x0F]);
        prettyString.push_back(hexChars[mGenome[i] & 0x0F]);
    }
    
    return prettyString;
}

std::string
Genotype::prettyPrintedGenotype() const
{
    return "";
}




} // namespace MacTierra
