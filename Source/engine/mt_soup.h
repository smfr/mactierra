/*
 *  mt_soup.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef mt_soup_h
#define mt_soup_h

#include "mt_engine.h"

namespace MacTierra {

class Soup
{
public:

    Soup(u_int32_t inSize);
    ~Soup();

    u_int32_t       soupSize() const { return mSoupSize; }

    
    enum ESearchDirection { kBothways, kBackwards, kForwards };
    
    bool            seachForTemplate(ESearchDirection inDirection, address_t& ioOffset, u_int32_t& outLength);
    
    instruction_t   instructionAtAddress(address_t inAddress) const;
    void            setInstructionAtAddress(address_t inAddress, instruction_t inInst);


protected:

    
    u_int32_t       mSoupSize;
    
    instruction_t*  mSoup;

};

} // namespace MacTierra

#endif // mt_soup_h
