/*
 *  MT_Soup.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_Soup_h
#define MT_Soup_h

#include <string.h>

#include "MT_Engine.h"

namespace MacTierra {

class Soup
{
public:

    Soup(u_int32_t inSize);
    ~Soup();

    u_int32_t       soupSize() const { return mSoupSize; }
    const instruction_t*    soup() const { return mSoup; }
    
    enum ESearchDirection { kBothways, kBackwards, kForwards };
    
    bool            seachForTemplate(ESearchDirection inDirection, address_t& ioOffset, u_int32_t& outLength);
    
    instruction_t   instructionAtAddress(address_t inAddress) const;
    void            setInstructionAtAddress(address_t inAddress, instruction_t inInst);

    void            injectInstructions(address_t inAddress, const instruction_t* inInstructions, u_int32_t inLength);


protected:

    bool            searchForwardsForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset);
    bool            searchBackwardsForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset);
    bool            searchBothWaysForTemplate(const instruction_t* inTemplate, u_int32_t inTemplateLen, address_t& ioOffset);
    
    bool            instructionsMatch(address_t inAddress, const instruction_t* inTemplate, u_int32_t inLen)
                    {
                        if (inAddress + inLen < mSoupSize)
                            return (memcmp(mSoup + inAddress, inTemplate, inLen) == 0);

                        for (u_int32_t i = 0; i < inLen; ++i)
                        {
                            address_t addr = (inAddress + i) % mSoupSize;
                            if (*(mSoup + addr) != inTemplate[i])
                                return false;
                        }
                        return true;
                    }

protected:

    
    u_int32_t       mSoupSize;
    
    instruction_t*  mSoup;

};

} // namespace MacTierra

#endif // MT_Soup_h
