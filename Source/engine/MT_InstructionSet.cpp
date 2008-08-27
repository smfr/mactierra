/*
 *  MT_InstructionSet.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "MT_Engine.h"
#include "MT_InstructionSet.h"

namespace MacTierra {

#define RETURN_INSTRUCTION_NAME(inst) case k_##inst: return #inst;

const char* nameForInstruction(instruction_t inInst)
{
    switch (inInst)
    {
        RETURN_INSTRUCTION_NAME(nop_0)
        RETURN_INSTRUCTION_NAME(nop_1)
        RETURN_INSTRUCTION_NAME(or1)
        RETURN_INSTRUCTION_NAME(sh1)
        RETURN_INSTRUCTION_NAME(zero)
        RETURN_INSTRUCTION_NAME(if_cz)
        RETURN_INSTRUCTION_NAME(sub_ab)
        RETURN_INSTRUCTION_NAME(sub_ac)
        RETURN_INSTRUCTION_NAME(inc_a)
        RETURN_INSTRUCTION_NAME(inc_b)
        RETURN_INSTRUCTION_NAME(dec_c)
        RETURN_INSTRUCTION_NAME(inc_c)
        RETURN_INSTRUCTION_NAME(push_ax)
        RETURN_INSTRUCTION_NAME(push_bx)
        RETURN_INSTRUCTION_NAME(push_cx)
        RETURN_INSTRUCTION_NAME(push_dx)
        RETURN_INSTRUCTION_NAME(pop_ax)
        RETURN_INSTRUCTION_NAME(pop_bx)
        RETURN_INSTRUCTION_NAME(pop_cx)
        RETURN_INSTRUCTION_NAME(pop_dx)
        RETURN_INSTRUCTION_NAME(jmp)
        RETURN_INSTRUCTION_NAME(jumpb)
        RETURN_INSTRUCTION_NAME(call)
        RETURN_INSTRUCTION_NAME(ret)
        RETURN_INSTRUCTION_NAME(mov_cd)
        RETURN_INSTRUCTION_NAME(mov_ab)
        RETURN_INSTRUCTION_NAME(mov_iab)
        RETURN_INSTRUCTION_NAME(adr)
        RETURN_INSTRUCTION_NAME(adrb)
        RETURN_INSTRUCTION_NAME(adrf)
        RETURN_INSTRUCTION_NAME(mal)
        RETURN_INSTRUCTION_NAME(divide)
    }
    return "";
}



} // namespace MacTierra

