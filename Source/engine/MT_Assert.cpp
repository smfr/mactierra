/*
 *  MT_Assert.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <iostream>

#include "MT_Assert.h"

namespace boost
{

using namespace std;

void assertion_failed(char const * expr, char const * function, char const * file, long line)
{
    cout << "Assertion failed: " << expr << " in " << function << "(" << file << ":" << line << ")" << endl;
}

}