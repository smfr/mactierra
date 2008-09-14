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
 
    // FIXME: this is lame. use streams
    std::string prettyString;
    prettyString.reserve(mData.length() * 3);

    for (u_int32_t i = 0; i < mData.length(); ++i)
    {
        if (i > 0)
            prettyString.push_back(' ');
        prettyString.push_back(hexChars[(mData[i] >> 4) & 0x0F]);
        prettyString.push_back(hexChars[mData[i] & 0x0F]);
    }
    
    return prettyString;
}

static inline char toLower(char c)
{
    if (c >= 'A' && c <= 'Z')
        c += ('a' - 'A');
    return c;
}

void
GenomeData::setFromPrintableGenome(const std::string& inString)
{
    const size_t len = inString.length();

    mData.reserve(len / 3);

    // FIXME: this is lame. use streams
    instruction_t curInst = 0;
    bool gotFirst = false;
    for (size_t i = 0; i < len; ++i)
    {
        const char curChar = toLower(inString[i]);
        if (!isxdigit(curChar))
            continue;
        
        u_int32_t charVal = (curChar < 'a') ? curChar - '0' : curChar - ('a' - 10);
        
        if (!gotFirst)
        {
            curInst = (charVal & 0x0F) << 4;
            gotFirst = true;
        }
        else
        {
            curInst |= charVal & 0x0F;
            mData.push_back(curInst);
            gotFirst = false;
        }
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
