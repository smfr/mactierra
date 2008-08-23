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

#include <boost/serialization/binary_object.hpp>
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/split_member.hpp>

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

    bool            operator==(const Soup& inRHS) const;

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

private:
    friend class ::boost::serialization::access;
    template<class Archive> void save(Archive& ar, const unsigned int version) const
    {
        // mSoupSize is archived separately to allow for construction
        ::boost::serialization::binary_object soupObject = ::boost::serialization::make_binary_object(mSoup, mSoupSize);
        ar << BOOST_SERIALIZATION_NVP(soupObject);
    }

    template<class Archive> void load(Archive& ar, const unsigned int version)
    {
        // mSoupSize is archived separately to allow for construction
        ::boost::serialization::binary_object soupObject(mSoup, mSoupSize);
        ar >> BOOST_SERIALIZATION_NVP(soupObject);
    }

    template<class Archive> void serialize(Archive& ar, const unsigned int file_version)
    {
        ::boost::serialization::split_member(ar, *this, file_version);
    }
    
protected:

    const u_int32_t mSoupSize;
    
    instruction_t*  mSoup;

};

} // namespace MacTierra

namespace boost {
namespace serialization {

template<class Archive>
inline void save_construct_data(Archive& ar, const MacTierra::Soup* inSoup, const unsigned int file_version)
{
    // save data required to construct instance
    u_int32_t soupSize = inSoup->soupSize();
    ar << BOOST_SERIALIZATION_NVP(soupSize);
}

template<class Archive>
inline void load_construct_data(Archive& ar, MacTierra::Soup* inSoup, const unsigned int file_version)
{
    // retrieve data from archive required to construct new instance
    u_int32_t soupSize;
    ar >> BOOST_SERIALIZATION_NVP(soupSize);
    // invoke inplace constructor to initialize instance of my_class
    ::new(inSoup)MacTierra::Soup(soupSize);
}

} // namespace boost
} // namespace serialization

#endif // MT_Soup_h
