/*
 *  MT_Genotype.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/18/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <sstream>
#include <cctype>

#include "MT_Genotype.h"

namespace MacTierra {

std::string
GenomeData::printableGenome() const
{
    const char hexChars[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
 
    std::string prettyString;
    
    for (u_int32_t i = 0; i < mData.length(); ++i)
    {
        if (i > 0)
            prettyString.push_back(' ');
        prettyString.push_back(hexChars[(mData[i] >> 4) & 0x0F]);
        prettyString.push_back(hexChars[mData[i] & 0x0F]);
    }
    
    return prettyString;
}


void
GenomeData::setFromPrintableGenome(const std::string& inString)
{
    instruction_t curInst = 0;
    
    std::string::const_iterator it = inString.begin();
    std::string::const_iterator end = inString.end();
    
    bool gotFirst = false;
    while (it != end)
    {
        if (!isxdigit(*it))
        {
            ++it;
            continue;
        }
        
        if (!gotFirst)
        {
            curInst = ((*it) - '0') << 4;
            gotFirst = true;
        }
        else
            curInst |= ((*it) - '0') & 0x0F;
        
        mData.push_back(curInst);
        ++it;
    }
}


Genotype::Genotype(const std::string& inIdentifier, const GenomeData& inGenome)
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



} // namespace MacTierra
