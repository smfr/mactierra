//
//  MTTimeUtils.c
//  MacTierra
//
//  Created by Simon Fraser on 11/23/23.
//

#include "MTTimeUtils.h"

#include <boost/assert.hpp>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <mutex>

static mach_timebase_info_data_t& machTimebaseInfo()
{
    // Based on listing #2 from Apple QA 1398, but modified to be thread-safe.
    static mach_timebase_info_data_t timebaseInfo;
    static std::once_flag initializeTimerOnceFlag;
    std::call_once(initializeTimerOnceFlag, [] {
        kern_return_t kr = mach_timebase_info(&timebaseInfo);
        BOOST_ASSERT(kr == KERN_SUCCESS);
        BOOST_ASSERT(timebaseInfo.denom);
    });
    return timebaseInfo;
}

CFTimeInterval approximateTime()
{
    auto& info = machTimebaseInfo();
    auto approximateTime = mach_approximate_time();

    return (approximateTime * info.numer) / (1.0e9 * info.denom);
}
