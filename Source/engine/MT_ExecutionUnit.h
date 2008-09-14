/*
 *  MT_ExecutionUnit.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_ExecutionUnit_h
#define MT_ExecutionUnit_h

#include <boost/serialization/serialization.hpp>

#include <wtf/PassRefPtr.h>

#include "MT_Engine.h"

namespace MacTierra {

class Creature;
class World;

// This class runs instructions of a particular instruction set.
class ExecutionUnit
{
public:

    ExecutionUnit();
    virtual ~ExecutionUnit();
    
    // flaw is -1, 0, or 1
    // FIXME: get flaw from soup?
    // Returns new creature on divide instruction
    virtual PassRefPtr<Creature> execute(Creature& inCreature, World& inWorld, int32_t inFlaw) = 0;

private:
    friend class ::boost::serialization::access;
    template<class Archive> void serialize(Archive& ar, const unsigned int version)
    {
    }

protected:


};


} // namespace MacTierra


#endif // MT_ExecutionUnit_h
