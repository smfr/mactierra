/*
 *  MT_Soup.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdlib.h>
#include <new>

#include <boost/assert.hpp>

#include "MT_Soup.h"

namespace MacTierra {

static const int32_t kMaxSearchDist = 1024;


Soup::Soup(u_int32_t inSize)
: mSoupSize(inSize)
, mSoup(NULL)
{
    mSoup = (instruction_t*)calloc(mSoupSize, sizeof(instruction_t));
    if (!mSoup)
    {
        // bad to throw from ctor, and throwing the wrong exception
        // for a malloc failure.
        throw std::bad_alloc();
    }
}

Soup::~Soup()
{
    free(mSoup);
}

// template is a series of k_nop_0 or k_nop_1 bytes, and we search for the complement
bool
Soup::seachForTemplate(ESearchDirection inDirection, address_t& ioOffset, u_int32_t& outLength)
{
    const int32_t kMaxTemplateLength = 10;
    
    const address_t   templateAddr = ioOffset;
    
    instruction_t   instTemplate[kMaxTemplateLength];
    int32_t i;
    for (i = 0; i <= kMaxTemplateLength; ++i)
    {
        address_t addr = (templateAddr + i) % mSoupSize;
        instruction_t inst = *(mSoup + addr);
        if (inst > 1)
            break;

        instTemplate[i] = inst ^ 1;
    }
    if (i == 0 || i == kMaxTemplateLength)
        return false;
    
    const u_int32_t templateLength = i;
    bool found = false;
    
    switch (inDirection)
    {
        case kBothways:
            found = searchBothWaysForTemplate(instTemplate, templateLength, ioOffset);
            break;
            
        case kBackwards:
            found = searchBackwardsForTemplate(instTemplate, templateLength, ioOffset);
            break;
    
        case kForwards:
            found = searchForwardsForTemplate(instTemplate, templateLength, ioOffset);
            break;
    }
    
    outLength = templateLength;
    return found;
}

instruction_t
Soup::instructionAtAddress(address_t inAddress) const
{
    BOOST_ASSERT(inAddress < mSoupSize);
    return *(mSoup + inAddress);
}


void
Soup::setInstructionAtAddress(address_t inAddress, instruction_t inInst)
{
    if (inAddress < mSoupSize)
    {
        *(mSoup + inAddress) = inInst;
    }
}

void
Soup::injectInstructions(address_t inAddress, const instruction_t* inInstructions, u_int32_t inLength)
{
    for (u_int32_t i = 0; i < inLength; ++i)
        setInstructionAtAddress((inAddress + i) % mSoupSize, inInstructions[i]);
}


bool
Soup::searchForwardsForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset)
{
    const address_t startAddress = ioOffset;
    const u_int32_t soupSize = mSoupSize;
    
    int32_t curOffset = 0;
    while (curOffset < kMaxSearchDist)
    {
        address_t curAddress = (startAddress + curOffset) % soupSize;
        if (instructionsMatch(curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }
    
    return false;
}

bool
Soup::searchBackwardsForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset)
{
    const address_t startAddress = ioOffset;
    const u_int32_t soupSize = mSoupSize;
    
    int32_t curOffset = 0;
    while (curOffset < kMaxSearchDist)
    {
        address_t curAddress = (startAddress + soupSize - curOffset) % soupSize;
        if (instructionsMatch(curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }
    
    return false;
}

bool
Soup::searchBothWaysForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset)
{
    const address_t startAddress = ioOffset;
    const u_int32_t soupSize = mSoupSize;
    
    int32_t curOffset = 0;
    while (curOffset < kMaxSearchDist)
    {
        // forwards
        address_t foreAddress = (startAddress + curOffset) % soupSize;
        if (instructionsMatch(foreAddress, inTemplate, inTemplateLen))
        {
            ioOffset = foreAddress;
            return true;
        }
        
        // backwards
        address_t backAddress = (startAddress + soupSize - curOffset) % soupSize;
        if (instructionsMatch(backAddress, inTemplate, inTemplateLen))
        {
            ioOffset = backAddress;
            return true;
        }

        ++curOffset;
    }
    
    return false;
}



} // namespace MacTierra
