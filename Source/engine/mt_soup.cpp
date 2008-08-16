/*
 *  mt_soup.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <assert.h>
#include <stdlib.h>
#include <new>

#include "mt_soup.h"

namespace MacTierra {

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

bool
Soup::seachForTemplate(ESearchDirection inDirection, address_t& ioOffset, u_int32_t& outLength)
{
    // FIXME: write this
    return false;
}

instruction_t
Soup::instructionAtAddress(address_t inAddress) const
{
    assert(inAddress < mSoupSize);
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



} // namespace MacTierra
