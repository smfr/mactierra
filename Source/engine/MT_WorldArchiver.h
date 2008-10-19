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
#include <map>
#include <string>
#include <vector>

#include <boost/archive/polymorphic_oarchive.hpp>
#include <boost/archive/polymorphic_iarchive.hpp>

#include <boost/serialization/serialization.hpp>

#include <wtf/RefPtr.h>
#include <wtf/RefCounted.h>

#include "MT_Engine.h"

namespace MacTierra {

class World;

// Pure virtual class, allowing clients to store additional data along with the world.
class WorldArchivingAddition : public RefCounted<WorldArchivingAddition>
{
public:

    virtual ~WorldArchivingAddition() { }

    virtual void registerTypes(boost::archive::polymorphic_oarchive& inArchive) = 0;
    virtual void registerTypes(boost::archive::polymorphic_iarchive& inArchive) = 0;

    virtual void loadAddition(const std::string& inAdditionType, boost::archive::polymorphic_iarchive& inArchive) = 0;
    virtual void saveAddition(const std::string& inAdditionType, boost::archive::polymorphic_oarchive& inArchive) = 0;
    
};

// Takes care of archiving and un-archiving the world, and any addition data added by the application
class WorldArchiver
{
public:
    enum EWorldSerializationFormat {
        kBinary,
        kXML,
        kAutodetect     // for open only
    };

    // register addition. Additions are retained
    void        registerAddition(const std::vector<std::string>& inTypes, WorldArchivingAddition* inAddition);
    
protected:
    
    typedef std::vector<std::string> AdditionsList;
    AdditionsList additionTypes() const;
    
protected:
    typedef std::map<std::string, RefPtr<WorldArchivingAddition> > AdditionsMap;
    AdditionsMap        mAdditions;
};


class WorldExporter : public WorldArchiver
{
public:

    WorldExporter(std::ostream& inStream, EWorldSerializationFormat inFormat);
    ~WorldExporter();
    
    void            saveWorld(const World* inWorld);

protected:

    void            createArchive(std::ostream& inStream, EWorldSerializationFormat inFormat);
    void            saveToArchive(const World* inWorld);

protected:

    boost::archive::polymorphic_oarchive*    mArchive;
};

class WorldImporter : public WorldArchiver
{
public:

    WorldImporter(std::istream& inStream, EWorldSerializationFormat inFormat);
    ~WorldImporter();

    World*          loadWorld();

protected:

    void            createArchive(std::istream& inStream, EWorldSerializationFormat inFormat);
    World*          loadFromArchive();

protected:

    boost::archive::polymorphic_iarchive*   mArchive;

};



} // namespace MacTierra


#endif // MT_WorldArchive_h
