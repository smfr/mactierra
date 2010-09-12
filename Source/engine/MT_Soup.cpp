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

static const u_int32_t kMaxSearchDist = 1024;


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
    
    instruction_t   instTemplate[kMaxTemplateLength + 1];
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
Soup::operator==(const Soup& inRHS) const
{
    return (mSoupSize == inRHS.soupSize()) &&
           (memcmp(mSoup, inRHS.soup(), mSoupSize) == 0);
}


static inline bool instructionsMatch(instruction_t* soup, u_int32_t soupSize, address_t inAddress, const instruction_t* inTemplate, u_int32_t inLen)
{
    for (u_int32_t i = 0; i < inLen; ++i)
    {
        address_t addr = (inAddress + i) % soupSize;
        if (*(soup + addr) != inTemplate[i])
            return false;
    }
    return true;
}

static inline bool instructionsMatchNonWrapping(instruction_t* soup, u_int32_t soupSize, address_t inAddress, const instruction_t* inTemplate, u_int32_t inLen)
{
    BOOST_ASSERT(inAddress + inLen < soupSize);
    
    switch (inLen)
    {
        case sizeof(u_int32_t):
            return *(u_int32_t*)(soup + inAddress) == *(u_int32_t*)(inTemplate);

        case sizeof(u_int32_t) - 1:
            return *(u_int16_t*)(soup + inAddress) == *(u_int16_t*)(inTemplate) &&
                   *(soup + inAddress + 2) == *(inTemplate + 2);
    
        case sizeof(u_int16_t):
            return *(u_int16_t*)(soup + inAddress) == *(u_int16_t*)(inTemplate);

        case 1:
            return *(soup + inAddress) == *inTemplate;
    
        default:
            for (u_int32_t i = 0; i < inLen; ++i)
            {
                address_t addr = inAddress + i;
                if (*(soup + addr) != inTemplate[i])
                    return false;
            }
            return true;
    }
    
    BOOST_ASSERT(false);
    return true;
}

bool
Soup::searchForwardsForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset)
{
    address_t startAddress = ioOffset;
    const u_int32_t soupSize = mSoupSize;
    const u_int32_t maxSearchDistance = std::min(soupSize - 1, kMaxSearchDist);
    
    // Do non-wrapping part.
    int32_t curOffset = 0;
    int32_t wrapOffset = std::min(soupSize - startAddress - inTemplateLen, maxSearchDistance);
    while (curOffset < wrapOffset)
    {
        address_t curAddress = startAddress + curOffset;
        if (instructionsMatchNonWrapping(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }
    
    // Do wrapping part.
    int32_t wrapEndOffset = std::min(curOffset + inTemplateLen, maxSearchDistance);
    while (curOffset < wrapEndOffset)
    {
        address_t curAddress = (startAddress + curOffset) % soupSize;
        if (instructionsMatch(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }

    // Do non-wrapping part.
    startAddress -= soupSize;
    while (curOffset < maxSearchDistance)
    {
        address_t curAddress = startAddress + curOffset;
        if (instructionsMatchNonWrapping(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
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
    address_t startAddress = ioOffset;
    const u_int32_t soupSize = mSoupSize;
    const u_int32_t maxSearchDistance = std::min(soupSize - 1, kMaxSearchDist);
    
    int32_t curOffset = 0;

    // Do the non-wrapping part.
    int32_t wrapOffset = std::min(startAddress, maxSearchDistance);
    while (curOffset < wrapOffset)
    {
        address_t curAddress = startAddress - curOffset;
        if (instructionsMatchNonWrapping(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }
    
    // Do the wrapping part.
    int32_t wrapEndOffset = std::min(startAddress + inTemplateLen, maxSearchDistance);
    while (curOffset <= wrapEndOffset)
    {
        address_t curAddress = (startAddress + soupSize - curOffset) % soupSize;
        if (instructionsMatch(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
        {
            ioOffset = curAddress;
            return true;
        }

        ++curOffset;
    }
    
    // Do the non-wrapping part.
    startAddress += soupSize;
    while (curOffset < maxSearchDistance)
    {
        address_t curAddress = startAddress - curOffset;
        if (instructionsMatchNonWrapping(mSoup, soupSize, curAddress, inTemplate, inTemplateLen))
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
    const u_int32_t maxSearchDistance = std::min(soupSize - 1, kMaxSearchDist);
    
    int32_t curOffset = 0;

    // Do the part that doesn't wrap in either direction.
    int32_t forwardWrapOffset = std::min(soupSize - startAddress - inTemplateLen, maxSearchDistance);
    int32_t backwardsWrapOffset = std::min(startAddress, maxSearchDistance);
    int32_t wrapOffset = std::min(forwardWrapOffset, backwardsWrapOffset);
    
    address_t foreAddress = startAddress + curOffset;
    address_t backAddress = startAddress - curOffset;
    
    while (curOffset < wrapOffset)
    {
        // forwards
        if (instructionsMatchNonWrapping(mSoup, soupSize, foreAddress, inTemplate, inTemplateLen))
        {
            ioOffset = foreAddress;
            return true;
        }
        
        // backwards
        if (instructionsMatchNonWrapping(mSoup, soupSize, backAddress, inTemplate, inTemplateLen))
        {
            ioOffset = backAddress;
            return true;
        }

        ++foreAddress;
        --backAddress;
        
        ++curOffset;
    }
    
    // Use slow mode for the rest. This could be optimized.
    while (curOffset < maxSearchDistance)
    {
        // forwards
        address_t foreAddress = (startAddress + curOffset) % soupSize;
        if (instructionsMatch(mSoup, soupSize, foreAddress, inTemplate, inTemplateLen))
        {
            ioOffset = foreAddress;
            return true;
        }
        
        // backwards
        address_t backAddress = (startAddress + soupSize - curOffset) % soupSize;
        if (instructionsMatch(mSoup, soupSize, backAddress, inTemplate, inTemplateLen))
        {
            ioOffset = backAddress;
            return true;
        }

        ++curOffset;
    }
    
    return false;
}



} // namespace MacTierra
