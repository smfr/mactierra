/*
 *  serialize_dynamic_bitset.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 9/28/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <string>

#include <boost/dynamic_bitset.hpp>
#include <boost/serialization/serialization.hpp>
#include <boost/serialization/split_free.hpp>

namespace boost { namespace serialization {

template <class Archive, class Block, class Alloc>
void save(Archive &ar, const dynamic_bitset<Block, Alloc> &bs, const unsigned int version)
{
    std::string  bitsetString;
    to_string(bs, bitsetString);
    ar << make_nvp("bits", bitsetString);
}

template <class Archive, class Block, class Alloc>
void load(Archive &ar, dynamic_bitset<Block, Alloc> &bs, const unsigned int version)
{
    std::string  bitsetString;
    ar >> make_nvp("bits", bitsetString);
    bs = dynamic_bitset<Block, Alloc>(bitsetString);
}

template <class Archive, class Block, class Alloc>
void serialize(Archive &ar, dynamic_bitset<Block, Alloc> &bs, const unsigned int version)
{
    boost::serialization::split_free(ar, bs, version);
}

}   // namespace serialization
}   // namespace boost


