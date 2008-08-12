/**
 * \file Random.hpp
 * \brief Header for Random, RandomGenerator.
 *
 * This loads up the header for RandomCanonical, RandomEngine, etc., to
 * provide access to random integers of various sizes, random reals with
 * various precisions, a random probability, etc.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/

#if !defined(RANDOM_HPP)
#define RANDOM_HPP "$Id: Random.hpp 6429 2008-04-28 00:14:02Z ckarney $"


#if defined(_MSC_VER)
#define WINDOWS 1
// Disable throw, precedence, size_t->int warnings
#pragma warning (disable: 4290 4554)
#else
#define WINDOWS 0
#endif

#if defined(__sparc)
#define SUN 1
#else
#define SUN 0
#endif

#if WINDOWS
typedef unsigned uint32_t;
typedef unsigned long long uint64_t;
#else
#include <stdint.h>
#endif
/**
 * The type for 32-bit results
 **********************************************************************/
#define RANDOM_U32_T uint32_t
/**
 * The type for 44-bit results
 **********************************************************************/
#define RANDOM_U64_T uint64_t

#if defined(__GNUC__)
// Suppress "defined but not used" warnings
#define RCSID_DECL(x) namespace \
{ char VAR_ ## x [] __attribute__((unused)) = x; }
#else
/**
 * Insertion of RCS Id strings into the object file.
 **********************************************************************/
#define RCSID_DECL(x) namespace { char VAR_ ## x [] = x; }
#endif

#if !defined(HAVE_SSE2)
#define HAVE_SSE2 0
#endif

#if !defined(HAVE_ALTIVEC)
// arch -> ppc
// machine -> ppc970
// uname -m -> Power Macintosh
// uname -n -> biocvs1.sarnoff.com
// uname -p -> powerpc
// uname -s -> Darwin
// uname -r -> 8.7.0
// uname -v -> Darwin Kernel Version 8.7.0: Fri May 26 15:20:53 PDT 2006; root:xnu-792.6.76.obj~1/RELEASE_PPC
#define HAVE_ALTIVEC 0
#endif

#if !defined(HAVE_BOOST_SERIALIZATION)
/**
 * Use boost serialization?
 **********************************************************************/
#define HAVE_BOOST_SERIALIZATION 0
#endif

#if !defined(RANDOM_LEGACY)
/**
 * Instantiate legacy classes MixerMT0 and MixerMT1?
 **********************************************************************/
#define RANDOM_LEGACY 0
#endif

/**
 * Use table, Power2::power2, for pow2?  This isn't necessary with g++ 4.0
 * because calls to std::pow are optimized.  g++ 4.1 seems to have lost
 * thiscapability though!
 **********************************************************************/
#if defined(__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ == 0
#define RANDOM_POWERTABLE 0
#else
// otherwise use a lookup table
#define RANDOM_POWERTABLE 1
#endif

#if WINDOWS
#define RANDOM_LONGDOUBLEPREC 53
#elif SUN
#define RANDOM_LONGDOUBLEPREC 113
#else
/**
 * The precision of long doubles, used for sizing Power2::power2.  64 on
 * Linux/Intel, 106 on MaxOS/PowerPC
 **********************************************************************/
#define RANDOM_LONGDOUBLEPREC __LDBL_MANT_DIG__
#endif

#if !defined(STATIC_ASSERT)
/**
 * A simple compile-time assert.
 **********************************************************************/
#define STATIC_ASSERT(cond,reason) { enum{ STATIC_ASSERT_ENUM = 1/int(cond) }; }
#endif

/**
 * Are denormalized reals of type RealType supported?
 **********************************************************************/
#define RANDOM_HASDENORM(RealType) 1

#include "RandomLib/RandomCanonical.hpp"

namespace RandomLib {

#if !defined(DEFAULT_GENERATOR)
#define DEFAULT_GENERATOR SRandomGenerator32
#endif

  /**
   * Point Random to one of a specific MT19937 generators.
   **********************************************************************/

  typedef DEFAULT_GENERATOR RandomGenerator;

  /**
   * Hook Random to RandomGenerator
   **********************************************************************/
  typedef RandomCanonical<RandomGenerator> Random;

} // namespace RandomLib

#endif	// RANDOM_HPP
