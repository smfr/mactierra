/*
 *  mt_isa.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_isa_h
#define mt_isa_h

namespace MacTierra {

// ISA (Instruction Set Architecture) settings
const int32_t kNumRegisters = 4;
const int32_t kStackSize = 10;

enum {
	k_ax = 0,
	k_bx = 1,
	k_cx = 2,
	k_dx = 3
};



} // namespace MacTierra


#endif // mt_isa_h