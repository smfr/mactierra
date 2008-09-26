/*
 *  mactierra.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser onMT_A 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <stddef.h>

#include <sys/fcntl.h>

#include <fstream>

#include <RandomLib/RandomSeed.hpp>

#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/serialization.hpp>

#include <boost/iostreams/device/file_descriptor.hpp>
#include <boost/iostreams/stream_buffer.hpp>
    
#include "mactierra.h"

#include "options.h"

#include "MT_World.h"
#include "MT_Settings.h"
#include "MT_SoupConfiguration.h"
#include "MT_Ancestor.h"

using namespace MacTierra;
using namespace std;

namespace io = boost::iostreams;

const int32_t kDefaultSoupSize = 1024 * 256;
const int32_t kCycleCount = 200;

// cheesy ostream subclass which holds onto the streambuf
class fileDescStream : public ostream
{
public:
    fileDescStream(int fd)
    : m_streamBuf(fd, true /* close on exit */)
    , ostream(&m_streamBuf)
    {
    }
    
protected:
    io::stream_buffer<io::file_descriptor_sink> m_streamBuf;    
};


static const char * const kOptionsList[] = {
    "?|?",
    "H|help",
    "s:soup-size <number>",     // required
    "d:duration <number>",      // required
    "r:random-seed <number>",   // optional
    "c:configuration-file",     // optional
    "f:in-soup-file",
    "o:out-soup-file",
    "x:xml-format",
    NULL
};

u_int32_t   gSoupSize = kDefaultSoupSize;
u_int32_t   gRandomSeed = 0;
bool        gSeedSet = false;

u_int64_t   gRunDuration = 0;

string      gInputSoupFilePath;
string      gOutputSoupFilePath;
string      gConfigFilePath;

bool        gUseXMLFormat = false;

Settings    gSoupSettings;

static bool readConfigurationFile(const std::string filePath)
{
    std::ifstream fileStream(filePath.c_str());

    SoupConfiguration config;
    
    try
    {
        boost::archive::xml_iarchive xmlArchive(fileStream);
        xmlArchive >> MT_BOOST_MEMBER_SERIALIZATION_NVP("configuration", config);
    }
    catch (std::exception const& e)
    {
        cerr << "Failed to parse configuration file (error " << e.what() << ") " << filePath << endl;
        return false;
    }
    catch (...)
    {
        cerr << "Failed to parse configuration file " << filePath << endl;
        return false;
    }
    
    gSoupSize = config.soupSize();
    gRandomSeed = config.randomSeed();
    gSoupSettings = config.settings();
    
    gSeedSet = true;
    return true;
}

static bool sanityCheckOptions()
{
    if (!gInputSoupFilePath.empty() && !gConfigFilePath.empty())
    {
        cerr << "Provide an input soup path, or configuration file path, but not both." << endl;
        return false;
    }
    
    if (!gInputSoupFilePath.empty())
    {
        // warn if -s or -r are specified
    }
    
    if (gRunDuration == 0)
    {
        cerr << "Run duration not specified, or zero. Use -d to specify the run duration as an instruction count." << endl;
        return false;
    }

    return true;
}

static World::EWorldSerializationFormat formatFromFileExtension(const string& inFileName)
{
    const string xmlFileSuffix = ".mactierra_xml";
    const string binaryFileSuffix = ".mactierra";

    if (inFileName.compare(inFileName.length() - xmlFileSuffix.length(), xmlFileSuffix.length(), xmlFileSuffix) == 0)
        return World::kXML;

    if (inFileName.compare(inFileName.length() - binaryFileSuffix.length(), binaryFileSuffix.length(), binaryFileSuffix) == 0)
        return World::kBinary;

    return World::kAutodetect;
}

static World* createWorld()
{
    World* theWorld = NULL;
    
    if (gInputSoupFilePath.length() > 0)
    {
        try
        {
            std::ifstream fileStream(gInputSoupFilePath.c_str());
            theWorld = World::worldFromStream(fileStream, formatFromFileExtension(gInputSoupFilePath));
        }
        catch (std::exception const& e)
        {
            cerr << "Failed to parse soup file (error " << e.what() << ") " << gInputSoupFilePath << endl;
            exit(1);
        }
        catch (...)
        {
            cerr << "Failed to open soup file " << gInputSoupFilePath << endl;
            exit(1);
        }
        
        gSoupSize = theWorld->soupSize();
        gRandomSeed = theWorld->initialRandomSeed();
    }
    else
    {
        if (!gSeedSet)
            gRandomSeed = RandomLib::RandomSeed::SeedWord();

        theWorld = new World();
        theWorld->initializeSoup(gSoupSize);
        theWorld->setSettings(gSoupSettings);
        theWorld->setInitialRandomSeed(gRandomSeed);

        // seed the soup
        theWorld->insertCreature(gSoupSize / 2, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    }

    return theWorld;
}

static ostream* uniqueOutputStream(const string& inPrefix, const string& inExtension)
{
    for (u_int32_t counter = 0; counter < 10000; ++counter)
    {
        std::ostringstream nameStream;
        
        nameStream << inPrefix;
        if (counter > 0)
            nameStream << "_" << counter;
        nameStream << ".";
        nameStream << inExtension;
        
        // Ugly gyrations because I don't like the filename patterns
        // of mkstemp, and there's no way to open an ofstream in O_EXCL mode
        // (ios::noreplace is not standard).
        int fd = open(nameStream.str().c_str(), O_RDWR | O_CREAT | O_EXCL, 0644);
        if (fd == -1)
            continue;

        return new fileDescStream(fd);
    }
    
    return NULL;
}

extern "C" int main(int argc, char* argv[])
{
    Options opts(*argv, kOptionsList);

    int  optchar;
    const char * optarg;
    int  errors = 0;
    
    gSoupSettings = Settings::mediumMutationSettings(gSoupSize);

    OptArgvIter  iter(--argc, ++argv);
    while ((optchar = opts(iter, optarg)))
    {
        switch (optchar)
        {
            case '?':
            case 'H':
                opts.usage(cout, "files ...");
                exit(0);

            case 's':
                if (!optarg) 
                    ++errors;
                else
                    gSoupSize = strtoul(optarg, NULL, 0);
                break;

            case 'd':
                if (!optarg) 
                    ++errors;
                else
                    gRunDuration = strtoull(optarg, NULL, 0);
                break;

            case 'c':
                if (!optarg) 
                    ++errors;
                else
                {
                    gConfigFilePath = optarg;
                    if (!readConfigurationFile(gConfigFilePath))
                        exit(1);
                }
                break;

            case 'r':
                if (!optarg) 
                    ++errors;
                else
                {
                    gRandomSeed = strtoul(optarg, NULL, 0);
                    gSeedSet = true;
                }
                break;

            case 'f':
                if (!optarg) 
                    ++errors;
                else
                    gInputSoupFilePath = optarg;
                break;

            case 'o':
                if (!optarg) 
                    ++errors;
                else
                    gOutputSoupFilePath = optarg;
                break;

            case 'x':
                gUseXMLFormat = true;
                break;

            default: 
                ++errors;
                break;
        }
    }

    if (!argc || errors)
    {
        opts.usage(cerr, "");
        exit(1);
    }
    
    if (!sanityCheckOptions())
        exit(1);

    World*  theWorld = createWorld();

    const string outFileExtension(gUseXMLFormat ? "mactierra_xml" : "mactierra");

    ostream* outputStream = NULL;

    if (gOutputSoupFilePath.empty())
    {
        std::ostringstream nameStream;
        nameStream << "output_soup_" << gRandomSeed;
        gOutputSoupFilePath = nameStream.str();
    }
    else
    {
        string fileSuffix = "." + outFileExtension;
        if (gOutputSoupFilePath.compare(gOutputSoupFilePath.length() - fileSuffix.length(), fileSuffix.length(), fileSuffix) == 0)
            gOutputSoupFilePath = string(gOutputSoupFilePath, 0, gOutputSoupFilePath.length() - fileSuffix.length());
    }

    if (!(outputStream = uniqueOutputStream(gOutputSoupFilePath, outFileExtension)))
    {
        cout << "Failed to create output file " << gOutputSoupFilePath << "." << outFileExtension;
        exit(1);
    }
    
    cout << "Soup size: " << gSoupSize << endl;
    cout << "Random seed: " << gRandomSeed << endl;
    cout << "Duration: " << gRunDuration << endl;
    if (!gConfigFilePath.empty())
        cout << "Configuration read from " << gConfigFilePath << endl;
    if (!gInputSoupFilePath.empty())
        cout << "Input soup file: " << gInputSoupFilePath << endl;
    cout << "Output soup file: " << gOutputSoupFilePath << "." << outFileExtension << endl;

    for (int32_t i = 0; i < 1; ++i)
    {
        theWorld->iterate(gRunDuration);
    }
    
    if (outputStream)
        World::worldToStream(theWorld, *outputStream, gUseXMLFormat ? World::kXML : World::kBinary);
    
    delete outputStream;
    delete theWorld;
    
    return 0;
}
