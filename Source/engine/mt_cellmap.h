/*
 *  mt_cellmap.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/12/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_cellmap_h
#define mt_cellmap_h

#include "mt_engine.h"

namespace MacTierra {

class Creature;

// The CellMap tracks which bytes of the soup are used by which creature.
class CellMap {
public:
    CellMap(u_int32_t inSize);
    ~CellMap();

    
    
    Creature*   creatureAtAddress(u_int32_t inAddress) const;
    
    bool        spaceAtAddress(u_int32_t inAddress, u_int32_t inLength) const;
    
protected:

    u_int32_t       mSize;
};

} // namespace MacTierra


#endif // mt_cellmap_h

