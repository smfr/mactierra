/*
 *  MT_DataCollectors.h
 *  MacTierra
 *
 *  Created by Simon Fraser on 8/30/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef MT_DataCollectors_h_
#define MT_DataCollectors_h_

#include "MT_DataCollection.h"

namespace MacTierra {

enum ETemporalStatistics {
    kPopulationSize,
    kNumGenotypes,
    kMeanOffspring,
    kCommonestGenotypeFitness
};

enum EFrequencyStatistics {
    kCreatureSizeFrequencies
    
};


class PopulationSizeLogger : public DataLogger
{
public:
    PopulationSizeLogger();
    ~PopulationSizeLogger();

    virtual void collectData(u_int64_t inInstructionCount, const World* inWorld);

    // returns a copy of the data
    std::vector<u_int32_t> data() const { return mPopulationSize; }
    
protected:

    std::vector<u_int32_t> mPopulationSize;

};



} // namespace MacTierra


#endif // MT_DataCollectors_h_
