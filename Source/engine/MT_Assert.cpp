/*
 *  mt_assert.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>

#include "mt_assert.h"

namespace boost
{

using namespace std;

void assertion_failed(char const * expr, char const * function, char const * file, long line)
{
    cout << "Assertion failed: " << expr << " in " << function << "(" << file << ":" << line << ")" << endl;
}

}