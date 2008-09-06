/*
 *  mactierra.cpp
 *  MacTierra
 *
 *  Created by Simon Fraser onMT_A 8/15/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include <stddef.h>
#import <fstream>

#include "RandomLib/RandomSeed.hpp"

#include "mactierra.h"

#include "options.h"

#include "MT_World.h"
#include "MT_Settings.h"
#include "MT_Ancestor.h"

using namespace MacTierra;
using namespace std;


const int32_t kDefaultSoupSize = 1024 * 256;
const int32_t kCycleCount = 200;


static const char * const kOptionsList[] = {
    "?|?",
    "H|help",
    "s:soup-size <number>",     // required
    "d:duration <number>",      // required
    "r:random-seed <number>",   // optional
    "f:in-soup-file",
    "o:out-soup-file",
    "x:xml-format",
    NULL
};


extern "C" int main(int argc, char* argv[])
{
    Options      opts(*argv, kOptionsList);
    OptArgvIter  iter(--argc, ++argv);

    u_int32_t soupSize = kDefaultSoupSize;
    u_int32_t randomSeed = 0;
    bool seedSet = false;
    u_int64_t duration = 0;
    string  inputSoupFilePath;
    string  outputSoupFilePath;
    bool useXMLFormat = false;

    int  optchar;
    const char * optarg;
    int  errors = 0;
    
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
                    soupSize = strtoul(optarg, NULL, 0);
                break;

            case 'd':
                if (!optarg) 
                    ++errors;
                else
                    duration = strtoull(optarg, NULL, 0);
                break;

            case 'r':
                if (!optarg) 
                    ++errors;
                else
                {
                    randomSeed = strtoul(optarg, NULL, 0);
                    seedSet = true;
                }
                break;

            case 'f':
                if (!optarg) 
                    ++errors;
                else
                    inputSoupFilePath = optarg;
                break;

            case 'o':
                if (!optarg) 
                    ++errors;
                else
                    outputSoupFilePath = optarg;
                break;

            case 'x':
                useXMLFormat = true;
                break;

            default: 
                ++errors;
                break;
        }
    }

    if (errors)
    {
        opts.usage(cerr, "");
        exit(1);
    }

    if (iter.index() < argc) {
        cout << "files=" ;
        for (int i = iter.index() ; i < argc ; i++) {
            cout << "\"" << argv[i] << "\" " ;
        }
        cout << endl;
    }
    
    cout << "Soup size: " << soupSize << endl;
    cout << "Duration: " << duration << endl;
    cout << "Input soup file: " << inputSoupFilePath << endl;
    cout << "Output soup file: " << outputSoupFilePath << endl;

    World*  theWorld = NULL;
    if (inputSoupFilePath.length() > 0)
    {
        std::ifstream fileStream(inputSoupFilePath.c_str());
        // FIXME: sniff the file to determine the type
        theWorld = World::worldFromStream(fileStream, World::kXML);
    }
    else
    {
        if (!seedSet)
            randomSeed = RandomLib::RandomSeed::SeedWord();

        theWorld = new World();
        theWorld->initializeSoup(soupSize);
        theWorld->setSettings(Settings::mediumMutationSettings(soupSize));
        theWorld->setInitialRandomSeed(randomSeed);

        // seed the soup
        theWorld->insertCreature(soupSize / 2, kAncestor80aaa, sizeof(kAncestor80aaa) / sizeof(instruction_t));
    }
    
    for (int32_t i = 0; i < 1; ++i)
    {
        theWorld->iterate(duration);
    }
    
    if (outputSoupFilePath.length() > 0)
    {
        ofstream outputStream(outputSoupFilePath.c_str());
        World::worldToStream(theWorld, outputStream, useXMLFormat ? World::kXML : World::kBinary);
    }
    
    delete theWorld;
    
    return 0;
}
