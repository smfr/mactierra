$Id: 00README.txt 6430 2008-04-28 02:29:55Z ckarney $

A random number library using the Mersenne Twister random number
generator.

Written by Charles Karney <charles@karney.com> and licensed under
the LGPL.  For more information, see

    http://charles.karney.info/random/

Files

    00README.txt -- this file
    Doxyfile -- Doxygen config file
    Random.doc -- main page of Doxygen documentation
    Random.hpp Random.cpp -- main include file plus implementation
    RandomCanonical.hpp -- Random integers, reals, booleans
    RandomPower2.hpp -- scaling by powers of two
    RandomEngine.hpp -- abstract random number generator
    RandomAlgorithm.hpp -- MT19937 and SFMT19937 random generators
    RandomMixer.hpp -- mixing functions to convert seed to state
    RandomSeed.hpp -- seed management
    RandomType.hpp -- support of unsigned integer types
    NormalDistribution.hpp -- sample from normal distribution
    ExponentialDistribution.hpp -- sample from exponential distribution
    RandomSelect.hpp -- sample from discrete distribution
    LeadingZeros.hpp -- count of leading zeros on random fraction
    ExponentialProb.hpp -- true with probability exp(-p)
    RandomNumber.hpp -- support for infinite precision randoms
    ExactExponential.hpp -- sample exactly from exponential distribution
    exphist.png exphist.pdf -- figures for documentation
    ExactPower.hpp -- sample exactly from power distribution
    powerhist.png powerhist.pdf -- figures for documentation
    Makefile -- Makefile (for Linux + gcc)
    RandomExample.cpp -- example code
    RandomPermutation.cpp -- prints a random permutation of integers
    Random.sln -- MS Visual C++ solution for library + examples
    RandomLib.vcproj -- MS Visual C++ project for library
    RandomExample.vcproj -- MS Visual C++ project for RandomExample
    RandomPermutation.vcproj -- MS Visual C++ project for RandomPermutation
    shuffle.sh -- shuffles the lines of a file

This is the 2008-04 version of the library.

Changes between 2008-01 and 2008-04 versions:

 * Reorganized so random algorithm and mixer can be selected
   independently.  This eliminated a lot of duplicate code.

 * This requires a new, incompatible, output format.  Format is now
   independent of the current base of the stream.

 * Name() now returns more informative name.

 * SFMT19937 init_by_array mixer adopted for MT19937 generators.  This
   is an incompatible change for the MT19937 generators.  However it is
   possible to hook the MT19937 engine with the MixerMT1 mixers to
   recover the previous functionality using
   - RandomEngine<MT19937<Random_u32>, MixerMT1<Random_u32> >
   - RandomEngine<MT19937<Random_u64>, MixerMT1<Random_u64> >

 * The way 32-bit results are glued together for to provide the
   Ran64() result is now LSB ordered.  Previously the 32-bit version
   of MT19937 used MSB ordering here.  This means that certain large
   integer results will be different for
   RandomEngine<MT19937<Random_u32>, MixerMT1<Random_u32> >

 * Support Altivec instructions on PowerPC for SFTM19937.  Also use
   longer long double on PowerPC.

 * Add -s seed option to shuffle and RandomPermutation.

 * Use strtoull (where available) instead of strtoul in convert a
   string seed to numeric form.

 * Switch project files to MS Visual Studio 2005.

 * Use SeedVector() instead of SeedWord() for the default constructor
   for Random.

 * Make 32-bit version of SFMT19937 the default generator.

Changes between 2007-05 and 2008-01 versions:

 * This is a maintenance release in anticipation of a forthcoming major
   restructuring of the code.

 * Use table of powers of two for g++ 4.1.

 * Minor documentation fixes.

Changes between 2007-04 and 2007-05 versions:

 * Add SFMT19937 generators.

 * Introduce RandomGenerator::Name() to identify generator.

 * Change define used to make 64-bit generator the default.

 * Add RandomSelect::Weight.

 * Ensure portability to systems where RandomSeed::u32 is longer than 32
   bits.

Changes between 2006-12 and 2007-04 versions:

 * Add utilities RandomPermutation and shuffle.

 * Implement MSB ordering on binary I/O in a portable way.

Changes between 2006-11 and 2006-12 versions:

 * Add leapfrogging.  The output format needed to be changed to
   accommodate an extra word of data.  However, I/O routines can still
   read the 2006-11 version.

Changes between 2006-10 and 2006-11 versions:

 * Introduce RandomCanonical class which accepts the random generator
   as a template argument.

 * This allows the inclusion of 32-bit and 64-bit versions of mt19937.

 * Include checksum in I/O.

 * Include boost serialization.

Changes between 2006-09 and 2006-10 versions:

 * Make 64-bit ready so a 64-bit version of mt19937 can be dropped in.

 * Fix a bug in the seeding.  (This bug was trigged by seed length of
   624 or greater; so it was unlikely to have been encountered in
   practice.)

 * Stop the special case treatment for
   Random::IntegerC<T>(numeric_limits<T>::max()).  In some cases (e.g.,
   T = int) this now gives different (but equivalent) results.

Changes between 2006-08 and 2006-09 versions:

 * Add ExponentialProb, ExactExponential, ExactPower, and RandomNumber.

 * Fix weakness in the seeding algorithm.  A given seed now gives a
   random sequence different from previous version; so this is an
   incompatible change.

 * Restructure the documentation.

 * Allow constructors to accept vectors of any integral type and
   constructors with a pair of iterators.

Change between 2006-07 and 2006-08 versions:

 * Improve efficiency of Integer(n) where n is a power of two.
