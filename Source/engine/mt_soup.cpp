/*
 *  mt_soup.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_soup.h"

namespace MacTierra {

Soup::Soup(u_int32_t inSize)
: mSoupSize(inSize)
{
}

Soup::~Soup()
{
}

bool
Soup::seachForTemplate(ESearchDirection inDirection, u_int32_t& ioOffset, u_int32_t& outLength)
{
    // FIXME: write this
    return false;
}

instruction_t
Soup::instructionAtAddress(u_int32_t inAddress) const
{
    // FIXME: write this
    return 0;
}

instruction_t
Soup::mutateInstruction(instruction_t inInst, EMutationType inMutationType) const
{
    // FIXME: write this
/*
    switch (mutateType)
    {
        case 0:             //Add or dec
            if (Random() & 0x20)
                *thisInst = (*thisInst == 31) ? 0 : *thisInst + 1;
            else
                *thisInst = (*thisInst == 0) ? 31 : *thisInst - 1;
                
            break;
        case 1:             //Flip one of bits 0 - 4
                *thisInst ^= (1 << RandomIntC(4));
            break;
        case 2:             //Random choice
                *thisInst = RandomIntC(31);
            break;
    }

*/
    return inInst;
}

bool
Soup::copyErrorPending() const
{
    // FIXME: write this
    return false;
}

bool
Soup::globalWritesAllowed() const
{
    // FIXME: write this
    return false;
}

bool
Soup::transferRegistersToOffspring() const
{
    // FIXME: write this
    return false;
}


Soup::EDaughterAllocationStrategy
Soup::daughterAllocationStrategy() const
{
    return kRandomAlloc;
}


} // namespace MacTierra
