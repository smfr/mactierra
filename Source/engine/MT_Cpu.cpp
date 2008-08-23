/*
 *  MT_Cpu.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_Cpu.h"

#include <string.h>

#include <boost/assert.hpp>

namespace MacTierra {

Cpu::Cpu()
: mStackPointer(0)
, mInstructionPointer(0)
, mFlag(false)
{
    memset(mRegisters, 0, sizeof(mRegisters));
    memset(mStack, 0, sizeof(mStack));
}


void
Cpu::push(int32_t d)
{
    BOOST_ASSERT(mStackPointer >= 0 && mStackPointer < kStackSize);

    mStack[mStackPointer] = d;
    mStackPointer = (mStackPointer + 1) % kStackSize;
}

int32_t
Cpu::pop()
{
    mStackPointer = (mStackPointer + kStackSize - 1) % kStackSize;
    return mStack[mStackPointer];
}

} // namespace MacTierra
