/**
 * \file RandomPermutation.cpp
 * \brief Prints a random permutation of integers
 *
 *   Usage: RandomPermutation [-o] [-d] [-x] [-s seed] [-v] [-h] [num]
 *
 * Print a random permutation of numbers from 0 thru num-1 on standard output.
 * num is supplied on the command line as a decimal number (default is 100).
 * Optional arguments -o, -d, and -x selection octal, decimal, and hexadecimal
 * output base (default decimal). -s seed sets the seed.  -v prints seed on
 * standard error. -h prints this help.
 *
 * seed is typically a list of comma-separated numbers,
 * e.g., -s ""; -s 1234; * -s 1,2,3,4; etc.  You can repeat a permutatoin by
 * using the form of the seed, printed to standard error with -v, as the
 * argument to -s, e.g., -s "[671916,1201036551,9299,562196172,2008]".  If the
 * seed is omitted, a "unique" seed is used.
 *
 * This is used by the "shuffle" script to shuffle the lines of a file.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the GPL.  For more information, see
 * http://charles.karney.info/random/
 **********************************************************************/

#include "RandomLib/Random.hpp"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <vector>

#define RANDOMPERMUTATION_CPP "$Id: RandomPermutation.cpp 6424 2008-01-31 04:03:13Z ckarney $";
RCSID_DECL(RANDOMPERMUTATION_CPP);

void usage(const std::string name, int retval) {
  ( retval == 0 ? std::cout : std::cerr )
    << "Usage: " << name
    << " [-o] [-d] [-x] [-s seed] [-v] [-h] [num]\n\
\n\
Print a random permutation of numbers from 0 thru num-1\n\
on standard output.  num is supplied on the command line\n\
as a decimal number (default is 100).  Optional arguments\n\
-o, -d, and -x selection octal, decimal, and hexadecimal\n\
output base (default decimal). -s seed sets the seed.\n\
-v prints seed on standard error. -h prints this help.\n";
  exit(retval);
}

int main(int argc, char* argv[]) {
  unsigned n = 100;
  unsigned base = 10;
  bool verbose = false;
  bool seedgiven = false;
  std::string seed;
  std::string arg;
  int m = 0;
  while (++m < argc) {
    arg = std::string(argv[m]);
    if (arg[0] != '-')
      break;			// Exit loop if not option
    if (arg == "-o")
      base = 8;
    else if (arg == "-d")
      base = 10;
    else if (arg == "-x")
      base = 16;
    else if (arg == "-v")
      verbose = true;
    else if (arg == "-s") {
      seedgiven = true;
      if (++m == argc)
	usage(argv[0], 1);	// Missing seed
      seed = std::string(argv[m]);
    } else if (arg == "-h")
      usage(argv[0], 0);
    else
      usage(argv[0], 1);	// Unknown option
  }
  if (m == argc - 1) {
    std::istringstream str(arg); // First non-option argument
    str >> n;
  } else if (m != argc)
    usage(argv[0], 1);		// Left over arguments

  unsigned k = 0;		// Figure width of output
  for (unsigned i = n - 1; i; i /= base) k++;

  std::vector<unsigned> a(n);
  for (unsigned i = n; i--;) a[i] = i;

  RandomLib::Random r = seedgiven ? RandomLib::Random(seed) :
    RandomLib::Random(RandomLib::Random::SeedVector());
  if (verbose)
    std::cerr << "Seed: " << r.SeedString() << "\n";
  std::random_shuffle(a.begin(), a.end(), r);

  std::cout << std::setfill('0')
	    << (base == 16 ? std::hex : (base == 8 ? std::oct : std::dec));
  for (unsigned i = n; i--;)
    std::cout << std::setw(k) << a[i] << "\n";

  return 0;
}
