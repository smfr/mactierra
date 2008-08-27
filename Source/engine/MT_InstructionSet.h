/*
 *  MT_InstructionSet.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_InstructionSet_h
#define MT_InstructionSet_h

namespace MacTierra {


enum {
    k_nop_0     = 0x00,
    k_nop_1     = 0x01,
    k_or1       = 0x02,
    k_sh1       = 0x03,
    k_zero      = 0x04,
    k_if_cz     = 0x05,
    k_sub_ab    = 0x06,
    k_sub_ac    = 0x07,
    k_inc_a     = 0x08,
    k_inc_b     = 0x09,
    k_dec_c     = 0x0A,
    k_inc_c     = 0x0B,
    k_push_ax   = 0x0C,
    k_push_bx   = 0x0D,
    k_push_cx   = 0x0E,
    k_push_dx   = 0x0F,
    k_pop_ax    = 0x10,
    k_pop_bx    = 0x11,
    k_pop_cx    = 0x12,
    k_pop_dx    = 0x13,
    k_jmp       = 0x14,
    k_jumpb     = 0x15,
    k_call      = 0x16,
    k_ret       = 0x17,
    k_mov_cd    = 0x18,
    k_mov_ab    = 0x19,
    k_mov_iab   = 0x1A,
    k_adr       = 0x1B,
    k_adrb      = 0x1C,
    k_adrf      = 0x1D,
    k_mal       = 0x1E,
    k_divide    = 0x1F
};


const int32_t kInstructionSetSize = 32;

const char* nameForInstruction(instruction_t inInst);

} // namespace MacTierra


#endif // MT_InstructionSet_h

