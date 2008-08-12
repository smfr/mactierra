/**
 * \file RandomExample.cpp
 * \brief Example of use of RandomSeed, MT19937, Random, etc.
 *
 * Compile/link with, e.g.,\n
 * g++ -I.. -O2 -funroll-loops -o RandomExample RandomExample.cpp Random.cpp\n
 * ./RandomExample
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include "RandomLib/Random.hpp"
#include "RandomLib/NormalDistribution.hpp"
#include "RandomLib/RandomSelect.hpp"

#define RANDOMEXAMPLE_CPP "$Id: RandomExample.cpp 6431 2008-04-28 02:32:02Z ckarney $"
RCSID_DECL(RANDOMEXAMPLE_CPP);
RCSID_DECL(NORMALDISTRIBUTION_HPP);
RCSID_DECL(RANDOMSELECT_HPP);

int main() {
  RandomLib::Random r;		// r created with random seed
  std::cout << "Using " << r.Name() << "\n"
	    << "with seed " << r.SeedString() << std::endl;
  {
    std::cout << "Estimate pi = ";
    size_t in = 0, num = 10000;
    for (size_t i = 0; i < num; ++i) {
      const double x = r.FixedS(); // r.FixedS() is in the interval (-1/2, 1/2)
      const double y = r.FixedS();
      if (x * x + y * y < 0.25)
	++in;			// Inside the circle
    }
    std::cout << (4.0 * in) / num << std::endl;
  }
  {
    std::cout << "Tossing a coin 20 times: ";
    for (size_t i = 0; i < 20; ++i)
      std::cout << (r.Boolean() ? "H" : "T");
    std::cout << std::endl;
  }
  {
    std::cout << "Throwing a pair of dice 15 times:";
    for (size_t i = 0; i < 15; ++i)
      std::cout << " " << r.IntegerC(1,6) + r.IntegerC(1,6);
    std::cout << std::endl;
  }
  {
    // Weights for throwing a pair of dice
    unsigned w[] = { 0, 0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 };
    // Initialize selection
    RandomLib::RandomSelect<unsigned> sel(w, w + sizeof(w)/sizeof(unsigned));

    std::cout << "Another 20 throws:";
    for (size_t i = 0; i < 20; ++i)
      std::cout << " " << sel(r);
    std::cout << std::endl;
  }
  {
    std::cout << "Draw balls from urn containing 5 red and 5 white balls: ";
    int t = 10, w = 5;
    while (t)
      std::cout << (r.Prob(w, t--) ? w--, "W" : "R");
    std::cout << std::endl;
  }
  {
    std::cout << "Shuffling the digits 0..9: ";
    std::string digits = "0123456789";
    std::random_shuffle(digits.begin(), digits.end(), r);
    std::cout << digits << std::endl;
  }
  {
    std::cout << "Estimate mean and variance of normal distribution: ";
    double m = 0;
    double s = 0;
    int k = 0;
    RandomLib::NormalDistribution<> n;
    while (k++ < 10000) {
      double x = n(r);
      double m1 = m + (x - m)/k;
      s += (x - m) * (x - m1);
      m = m1;
    }
    std::cout << m << ", " << s/(k - 1) << std::endl;
  }
  {
    typedef float real;
    enum { prec = 4 };
    std::cout << "Some low precision reals (1/"
	      << (1<<prec) << "): ";
    for (size_t i = 0; i < 5; ++i)
      std::cout << " " << r.Fixed<real, prec>();
    std::cout << std::endl;
  }
  std::cout << "Used " << r.Count() << " random numbers" << std::endl;
  try {
    // This throws an error if there's a problem
    RandomLib::MRandomGenerator32::SelfTest();
    std::cout << "Self test of " << RandomLib::MRandomGenerator32::Name()
	      << " passed" << std::endl;
    RandomLib::MRandomGenerator64::SelfTest();
    std::cout << "Self test of " << RandomLib::MRandomGenerator64::Name()
	      << " passed" << std::endl;
    RandomLib::SRandomGenerator32::SelfTest();
    std::cout << "Self test of " << RandomLib::SRandomGenerator32::Name()
	      << " passed" << std::endl;
    RandomLib::SRandomGenerator64::SelfTest();
    std::cout << "Self test of " << RandomLib::SRandomGenerator64::Name()
	      << " passed" << std::endl;
  }
  catch (std::out_of_range& e) {
    std::cerr << "Self test FAILED: " << e.what() << std::endl;
    return 1;
  }
}
