/*
 *  MT_WorldArchive.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 10/3/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_WorldArchive_h
#define MT_WorldArchive_h

#include <iosfwd>

namespace MacTierra {

class World;

class WorldArchive
{
public:
    enum EWorldSerializationFormat {
        kBinary,
        kXML,
        kAutodetect     // for open only
    };

    // save/restore
    static void         worldToStream(const World* inWorld, std::ostream& inStream, EWorldSerializationFormat inFormat);
    static World*       worldFromStream(std::istream& inStream, EWorldSerializationFormat inFormat);

};


} // namespace MacTierra


#endif // MT_WorldArchive_h
