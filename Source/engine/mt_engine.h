/*
 *  mt_engine.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_engine_h
#define mt_engine_h

#include <stddef.h>
#include <sys/types.h>

namespace MacTierra {


#define RELATIVE_ADDRESSING


// template search limits
const int32_t kMaxTemplateLength = 10;

// Min proportion of daughter copied in
const float kMinPropCopied  = 0.5f;

// Minimum creature size
const int32_t kMinCreatureSize = 12;

// Max number of attempts to find space for daughter
const int32_t kMaxMalAttempts = 20;



typedef u_int32_t creature_id;
typedef u_int8_t instruction_t;

typedef u_int32_t address_t;



} // namespace MacTierra


#endif // mt_engine_h

