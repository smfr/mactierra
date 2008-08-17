/*
 *  mt_assert.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

namespace boost
{

void assertion_failed(char const * expr, char const * function, char const * file, long line);

}