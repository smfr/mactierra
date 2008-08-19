/*
 *  mt_cpu.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_cpu_h
#define mt_cpu_h

#include <string.h>

#include "mt_engine.h"
#include "mt_isa.h"

namespace MacTierra {

class Cpu {

public:

    Cpu();
    
    void push(int32_t);
    int32_t pop();

    void setFlag()      { mFlag = true; }
    void clearFlag()    { mFlag = false; }
    bool flag() const   { return mFlag; }

    void incrementIP(u_int32_t inSoupSize)  { mInstructionPointer = (mInstructionPointer + 1) % inSoupSize; }

    bool operator==(const Cpu& inRHS) const
    {
        return memcmp(mRegisters, inRHS.mRegisters, sizeof(mRegisters)) == 0 &&
               memcmp(mStack, inRHS.mStack, sizeof(mStack)) == 0 &&
               mStackPointer == inRHS.mStackPointer &&
               mInstructionPointer == inRHS.mInstructionPointer &&
               mFlag == inRHS.mFlag;
    }
    
public:

    int32_t     mRegisters[kNumRegisters];

    int32_t     mStack[kStackSize];
    int32_t     mStackPointer;

    int32_t     mInstructionPointer;

    bool        mFlag;
    
};



} // namespace MacTierra


#endif // mt_cpu_h
