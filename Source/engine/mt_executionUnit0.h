/*
 *  mt_executionUnit0.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef mt_executionUnit0_h
#define mt_executionUnit0_h

#include "mt_executionUnit.h"

#include "mt_soup.h"

namespace MacTierra {

class Creature;
class Cpu;

// Execution unit for instruction set 0
class ExecutionUnit0 : public ExecutionUnit
{
public:

    ExecutionUnit0();
    ~ExecutionUnit0();
    
    virtual Creature* execute(Creature& inCreature, World& inWorld, int32_t inFlaw);


protected:

    void jump(Creature& inCreature, Soup& inSoup, Soup::ESearchDirection inDirection);
    void call(Creature& inCreature, Soup& inSoup);
    void address(Creature& inCreature, Soup& inSoup, Soup::ESearchDirection inDirection);

};


} // namespace MacTierra


#endif // mt_executionUnit0_h
