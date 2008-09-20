/*
 *  MT_InventoryListener.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/19/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_InventoryListener_h
#define MT_InventoryListener_h


namespace MacTierra {

// Engine clients can subclass InventoryListener and register an instance
// with the inventory to get notified when successful genotypes crop up

class InventoryListener
{
public:

    virtual ~InventoryListener() {}
    
    virtual void noteGenotype(const InventoryGenotype* inGenotype) = 0;

};

} // namespace MacTierra

#endif // MT_InventoryListener_h