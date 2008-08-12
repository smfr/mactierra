/*
 *  mt_cpu.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_cpu.h"

#include <assert.h>
#include <string.h>

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
	assert(mStackPointer >= 0 && mStackPointer < kStackSize);

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
