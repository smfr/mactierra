/*
 *  MT_Cpu.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Cpu_h
#define MT_Cpu_h

#include <string.h>

#include <boost/serialization/serialization.hpp>

#include "MT_Engine.h"
#include "MT_Isa.h"

namespace MacTierra {

class Cpu {

public:

    Cpu();
    
    void push(int32_t);
    int32_t pop();

    void setFlag()      { mFlag = true; }
    void clearFlag()    { mFlag = false; }
    bool flag() const   { return mFlag; }

    int32_t registerValue(int32_t inRegisterIndex) const
    {
        if (inRegisterIndex < kNumRegisters)
            return mRegisters[inRegisterIndex];
        return -1;
    }

    int32_t stackValue(int32_t inStackIndex) const
    {
        if (inStackIndex < kStackSize)
            return mStack[inStackIndex];
        return -1;
    }
    int32_t stackPointer() const { return mStackPointer; }
    
    int32_t instructionPointer() const { return mInstructionPointer; }
    void incrementIP(u_int32_t inSoupSize)  { mInstructionPointer = (mInstructionPointer + 1) % inSoupSize; }

    bool operator==(const Cpu& inRHS) const
    {
        return memcmp(mRegisters, inRHS.mRegisters, sizeof(mRegisters)) == 0 &&
               memcmp(mStack, inRHS.mStack, sizeof(mStack)) == 0 &&
               mStackPointer == inRHS.mStackPointer &&
               mInstructionPointer == inRHS.mInstructionPointer &&
               mFlag == inRHS.mFlag;
    }

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
        ar & BOOST_SERIALIZATION_NVP(mRegisters);
        ar & BOOST_SERIALIZATION_NVP(mStack);
        ar & BOOST_SERIALIZATION_NVP(mStackPointer);
        ar & BOOST_SERIALIZATION_NVP(mInstructionPointer);
        ar & BOOST_SERIALIZATION_NVP(mFlag);
    }
    
public:

    int32_t     mRegisters[kNumRegisters];

    int32_t     mStack[kStackSize];
    int32_t     mStackPointer;

    int32_t     mInstructionPointer;

    bool        mFlag;
    
};



} // namespace MacTierra


#endif // MT_Cpu_h
