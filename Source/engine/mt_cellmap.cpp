/*
 *  mt_cellmap.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "mt_cellmap.h"

#include "mt_creature.h"

namespace MacTierra {

CellMap::CellMap(u_int32_t inSize)
: mSize(inSize)
{
}

CellMap::~CellMap()
{
}


Creature*
CellMap::creatureAtAddress(u_int32_t inAddress) const
{

    return NULL;
}




} // namespace MacTierra
