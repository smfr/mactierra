/**
 * \file RandomEngine.hpp
 * \brief Header for RandomEngine.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more information, see
 * http://charles.karney.info/random/
 **********************************************************************/

#if !defined(RANDOMENGINE_HPP)
#define RANDOMENGINE_HPP "$Id: RandomEngine.hpp 6429 2008-04-28 00:14:02Z ckarney $"

#include "RandomLib/RandomSeed.hpp"
#include "RandomLib/RandomAlgorithm.hpp"
#include "RandomLib/RandomMixer.hpp"
#include <limits>
#include <string>

#if HAVE_BOOST_SERIALIZATION
#include <boost/serialization/nvp.hpp>
#include <boost/serialization/split_member.hpp>
#include <boost/serialization/vector.hpp>
#endif

namespace RandomLib {
  /**
   * \brief Uniform random number generator.
   *
   * This implements a generic random number generator.  Such a generator
   * requires two data holders RandomSeed, to hold the seed, and RandomEngine,
   * to hold the state.  In addition we need two piece of machinery, a "Mixer"
   * to convert the seed into an initial state and an "Algorithm" to advance the
   * state.
   *
   * RandomSeed is responsible for setting and reporting the seed.
   *
   * Mixer has no state and implements only static methods.  It needs to have
   * the following public interface
   *   - typedef mixer_t: a RandomType giving the output type
   *   - unsigned version: an identifying version number
   *   - static std::string Name(): an identifying name for the mixer
   *   - static method SeedToState: converts a seed into n words of state.
   *
   * Algorithm has no state and implements only static methods.  It needs to have
   * the following public interface
   *   - typedef engine_t: a RandomType giving the output type
   *   - typedef internal_type: a integer type used by Transition.  This is
   *     usually the same as engine_t::type.  However it allows the use of
   *     vector instructions on some platforms.  We require that engine_t::type
   *     and internal_type line up properly in a union so that there is no need
   *     to convert the data explicity between interal_type and engine_t::type.
   *   - unsigned version: an identifying version number
   *   - static std::string Name(): an identifying name for the mixer
   *   - enum N: the size of the state in units of engine_t.
   *   - static method Transition: steps the generator forwards or backwards.
   *   - static method Generate: tempers the state immediately prior to output
   *   - static method NormalizeState: force the initial state (the result of
   *     the Mixer) into a legal state.
   *   - static method CheckState accumulates the checksum for the state into
   *     check.  In addition it throws an exception if the state is bad.
   *
   * RandomEngine is the glue that holds everything together.  It repacks
   * the mixer_t data from Mixer into engine_t if necessary.  It deals with
   * delivering individual random results, stepping the state forwards and
   * backwards, leapfrogging the generator, I/O of the generator, etc.
   *
   * Written by <a href="http://charles.karney.info/"> Charles Karney</a>
   * <charles@karney.com> and licensed under the LGPL.  For more information,
   * see http://charles.karney.info/random/
   **********************************************************************/
  template<class Algorithm, class Mixer>
  class RandomEngine : public RandomSeed {
  private:
    /**
     * The result RandomType (carried over from the \a Algorithm).
     **********************************************************************/
    typedef typename Algorithm::engine_t result_t;
    /**
     * The RandomType used by the \a Mixer.
     **********************************************************************/
    typedef typename Mixer::mixer_t mixer_t;
    /**
     * The internal_type used by the Algorithm::Transition().
     **********************************************************************/
    typedef typename Algorithm::internal_type engine_type;
  public:
    /**
     * The number of random bits produced by Ran().
     **********************************************************************/
    enum {
      width = result_t::width,
    };

    /**
     * A type large enough to hold \e width bits.  This is used for the
     * internal state of the generator and the result returned by Ran().
     **********************************************************************/
    typedef typename result_t::type result_type;

    /**
     * The minimum result returned by Ran().
     **********************************************************************/
    static const result_type min = result_t::min;

    /**
     * The maximum result returned by Ran() = 2<sup><i>w</i></sup> - 1
     **********************************************************************/
    static const result_type max = result_t::max;

  protected:

    /**
     * The mask for the result_t.
     **********************************************************************/
    static const result_type mask = result_t::mask;

  private:
    /**
     * A version number "RandLib0" to ensure safety of Save/Load.  The next 7
     * bytes can be regarded as a "signature" and the 8th byte a version
     * number.
     **********************************************************************/
    static const u64::type version = 0x52616e644c696230ULL; // 'RandLib0'
    /**
     * Marker for uninitialized object
     **********************************************************************/
    static const unsigned UNINIT = 0xffffffffU;
    enum {
      /**
       * The size of the state in units of result_type
       **********************************************************************/
      N = Algorithm::N,
      /**
       * The size of the state in units of mixer_t::type
       **********************************************************************/
      NU = (N * width + mixer_t::width - 1) / mixer_t::width,
      /**
       * The size of the state in units of engine_type.
       **********************************************************************/
      NV = N * sizeof(result_type) / sizeof(engine_type),
    };

    /**
     * \brief Union for the state.
     *
     * A union to hold the state in the result_type, mixer_t::type, and
     * engine_type representations.
     **********************************************************************/
    union {
      /**
       * the result_type representation returned by Ran()
       **********************************************************************/
      result_type _state[N];
      /**
       * the mixer_t::type representation returned by Mixer::SeedToState.
       **********************************************************************/
      typename mixer_t::type _stateu[NU];
      /**
       * the engine_type representation returned by Algorithm::Transition.
       **********************************************************************/
      engine_type _statev[NV];
    };

    /**
     * The index for the next random value
     **********************************************************************/
    unsigned _ptr;
    /**
     * How many times has Transition() been called
     **********************************************************************/
    long long _rounds;
    /**
     * Stride for leapfrogging
     **********************************************************************/
    unsigned _stride;

  public:

    /** \name Constructors
     **********************************************************************/
    ///@{
    /**
     * Initialize from a vector.  Only the low \e 32 bits of each element are
     * used.
     **********************************************************************/
    template<typename IntType>
    explicit RandomEngine(const std::vector<IntType>& v)
      throw(std::bad_alloc) { Reseed(v); }
    /**
     * Initialize from a pair of iterators setting seed to [\a a, \a b).  The
     * iterator must produce results which can be converted into seed_type.
     * Only the low \e 32 bits of each element are used.
     **********************************************************************/
    template<typename InputIterator>
    RandomEngine(InputIterator a, InputIterator b)
    { Reseed(a, b); }
    /**
     * Initialize with seed [\a n].  Only the low \e width bits of \a n are
     * used.
     **********************************************************************/
    explicit RandomEngine(seed_type n) throw(std::bad_alloc)
    { Reseed(n); }
    /**
     * Initialize with seed [SeedVector()]
     **********************************************************************/
    RandomEngine() throw(std::bad_alloc) { Reseed(); }
    /**
     * Initialize from a string.  See Reseed(const std::string& s)
     **********************************************************************/
    explicit RandomEngine(const std::string& s) throw(std::bad_alloc)
    { Reseed(s); }

    ///@}

    /** \name Functions for returning random data
     **********************************************************************/
    ///@{
    /**
     * Return \e width bits of randomness.  This is the natural unit of random
     * data produced random numnber generator.
     **********************************************************************/
    result_type Ran() throw() {
      if (_ptr >= N)
	Next();
      result_type y = _state[_ptr];
      _ptr += _stride;

      return Algorithm::Generate(y);
    }

    /**
     * Return 32 bits of randomness.
     **********************************************************************/
    u32::type Ran32() throw() {
      //      return width > 32 ? u32::cast(Ran()) : Ran();
      return u32::cast(Ran());
    }

    /**
     * Return 64 bits of randomness.
     **********************************************************************/
    u64::type Ran64() throw() {
      const u64::type x = Ran();
      return width > 32 ? x : u64::cast(Ran()) << 64 - width | x;
    }

    /**
     * Return \e width bits of randomness.  Result is in [0,
     * 2<sup><i>w</i></sup>)
     **********************************************************************/
    result_type operator()() throw() { return Ran(); }
    ///@}

    /** \name Comparing Random objects
     **********************************************************************/
    ///@{
    /**
     * Test equality of two Random objects.  This test that the seeds match and
     * that they have produced the same number of random numbers.
     **********************************************************************/
    bool operator==(const RandomEngine& r) const throw()
    // Ensure that the two Random objects behave the same way.  Note however
    // that the internal states may still be different, e.g., the following all
    // result in Random objects which are == (with Count() == 0) but which all
    // have different internal states:
    //
    // Random r(0);                       _ptr == UNINIT
    // r.StepCount( 1); r.StepCount(-1);  _ptr == 0, _rounds ==  0
    // r.StepCount(-1); r.StepCount( 1);  _ptr == N, _rounds == -1
    { return Count() == r.Count() && _seed == r._seed &&
	_stride == r._stride; }
    /**
     * Test inequality of two Random objects.  See Random::operator==
     **********************************************************************/
    bool operator!=(const RandomEngine& r) const throw()
    { return !operator==(r); }
    ///@}

    /** \name Writing to and reading from a stream
     **********************************************************************/
    ///@{
    /**
     * Save the state of the Random object to an output stream.  Format is a
     * sequence of unsigned 32-bit integers written either in decimal (\a bin
     * false, text format) or in network order with most significant byte first
     * (\a bin true, binary format).  Data consists of:
     *
     *  - RandomLib magic string + version (2 words)
     *  - Algorithm version (1 word)
     *  - Mixer version (1 word)
     *  - _seed.size() (1 word)
     *  - _seed data (_seed.size() words)
     *  - _ptr (1 word)
     *  - _stride (1 word)
     *  - if _ptr != UNINIT, _rounds (2 words)
     *  - if _ptr != UNINIT, _state (N words or 2 N words)
     *  - checksum
     *
     * Shortest possible saved result consists of 8 words.  This corresponds to
     * RandomSeed() = [] and Count() = 0.
     **********************************************************************/
    void Save(std::ostream& os, bool bin = true) const
      throw(std::ios::failure);
    /**
     * Restore the state of the Random object from an input stream.  If \a bin,
     * read in binary, else use text format.  See documentation of
     * RandomEngine::Save for the format.  Include error checking on date to
     * make sure the input has not been corrupted.  If an error occurs while
     * reading, the Random object is unchanged.
     **********************************************************************/
    void Load(std::istream& is, bool bin = true)
      throw(std::ios::failure, std::out_of_range, std::bad_alloc) {
      // Read state into temporary so as not to change object on error.
      RandomEngine t(is, bin);
      _seed.reserve(t._seed.size());
      *this = t;
    }
    ///@}

    /** \name Basic I/O
     **********************************************************************/
    ///@{
    /**
     * Write the state of a generator to stream \a os as text
     **********************************************************************/
    friend std::ostream& operator<<(std::ostream& os, const RandomEngine& r) {
      r.Save(os, false);
      return os;
    }

    /**
     * Read the state of a generator from stream \a is as text
     **********************************************************************/
    friend std::istream& operator>>(std::istream& is, RandomEngine& r) {
      r.Load(is, false);
      return is;
    }
    ///@}

    /** \name Examining and advancing the Random generator
     **********************************************************************/
    ///@{
    /**
     * Return the number of random numbers used.  This needs to return a long
     * long result since it can reasonably exceed 2<sup>31</sup>.  (On a 1GHz
     * machine, it takes about a minute to produce 2<sup>32</sup> random
     * numbers.)  More precisely this is the (zero-based) index of the next
     * random number to be produced.  (This distinction is important when
     * leapfrogging is in effect.)
     **********************************************************************/
    long long Count() const throw()
    { return _ptr == UNINIT ? 0 : _rounds * N + _ptr; }
    /**
     * Step the generator forwards of backwarks so that the value returned
     * by Count() is \a n
     **********************************************************************/
    void SetCount(long long n) throw() { StepCount(n - Count()); }
    /**
     * Step the generator forward \a n steps.  \a n can be negative.
     **********************************************************************/
    void StepCount(long long n) throw();
    /**
     * Resets the sequence.  Equivalent to SetCount(0), but works by
     * reinitializing the Random object from its seed, rather than by stepping
     * the sequence backwards.  In addition, this undoes leapfrogging.
     **********************************************************************/
    void Reset() throw() { _ptr = UNINIT; _stride = 1; }
    ///@}

    /** \name Leapfrogging
     **********************************************************************/
    ///@{
    /**
     * Set leapfrogging stride to a positive number \a n and increment Count()
     * by \a k < \a n.  If the current Count() is \a i, then normally the next
     * 3 random numbers would have (zero-based) indices \a i, \a i + 1, \a i +
     * 2, and the new Count() is \a i + 2.  However, after SetStride(\a n, \a
     * k) the next 3 random numbers have indices \a i + \a k, \a i + \a k + \a
     * n, \a i + \a k + 2\a n, and the new Count() is \a i + \a k + 3\a n.
     * With leapfrogging in effect, the time to produce raw random numbers is
     * roughly proportional to 1 + (\a n - 1)/2.  Reseed(...) and Reset() both
     * reset the stride back to 1.  See \ref leapfrog "Leapfrogging" for a
     * description of how to use this facility.
     **********************************************************************/
    void SetStride(unsigned n = 1, unsigned k = 0)
      throw(std::invalid_argument) {
      // Limit stride to UNINIT/2.  This catches negative numbers that have
      // been cast into unsigned.  In reality the stride should be no more than
      // 10-100.
      if (n == 0 || n > UNINIT/2)
	throw std::invalid_argument("RandomEngine: Invalid stride");
      if (k >= n)
	throw std::invalid_argument("RandomEngine: Invalid index");
      _stride = n;
      StepCount(k);
    }
    /**
     * Return leapfrogging stride.
     **********************************************************************/
    unsigned GetStride() const throw() { return _stride; }
    ///@}

    /**
     * Tests basic engine.  Throws out_of_range errors on bad results.
     **********************************************************************/
    static void SelfTest();

    /**
     * Return the name of the generator.  This incorporates the names of the \a
     * Algorithm and \a Mixer.
     **********************************************************************/
    static std::string Name() throw() {
      return "RandomEngine<" + Algorithm::Name() + "," + Mixer::Name() + ">";
    }

  private:
    /**
     * Compute initial state from seed
     **********************************************************************/
    void Init() throw();
    /**
     * The interface to Transition used by Ran().
     **********************************************************************/
    void Next() throw() {
      if (_ptr == UNINIT)
	Init();
      _rounds += _ptr/N;
      Algorithm::Transition(_ptr/N, _statev);
      _ptr %= N;
    }

    u32::type Check(u64::type v, u32::type e, u32::type m) const
      throw(std::out_of_range);

    static result_type SelfTestResult(unsigned k) throw () {
      return 0;
    }

    /**
     * Read from an input stream.  Potentially corrupts object.  This private
     * constructor is used by RandomEngine::Load so that it can avoid
     * corrupting its state on bad input.
     **********************************************************************/
    explicit RandomEngine(std::istream& is, bool bin)
      throw(std::ios::failure, std::out_of_range, std::bad_alloc);

#if HAVE_BOOST_SERIALIZATION
    friend class boost::serialization::access;
    /**
     * Save to a boost archive.  Boost versioning isn't very robust.  (It
     * allows a RandomGenerator32 to be read back in as a RandomGenerator64.
     * It doesn't interact well with templates.)  So we do our own versioning
     * and supplement this with a checksum.
     **********************************************************************/
    template<class Archive> void save(Archive& ar, const unsigned int) const {
      u64::type _version = version;
      u32::type _eversion = Algorithm::version,
	_mversion = Mixer::version,
	_checksum = Check(_version, _eversion, _mversion);
      ar & boost::serialization::make_nvp("version" , _version )
	&  boost::serialization::make_nvp("eversion", _eversion)
	&  boost::serialization::make_nvp("mversion", _mversion)
	&  boost::serialization::make_nvp("seed"    , _seed    )
	&  boost::serialization::make_nvp("ptr"     , _ptr     )
	&  boost::serialization::make_nvp("stride"  , _stride  );
      if (_ptr != UNINIT)
	ar & boost::serialization::make_nvp("rounds", _rounds  )
	  &  boost::serialization::make_nvp("state" , _state   );
      ar & boost::serialization::make_nvp("checksum", _checksum);
    }
    /**
     * Load from a boost archive.  Do this safely so that the current object is
     * not corrupted if the archive is bogus.
     **********************************************************************/
    template<class Archive> void load(Archive& ar, const unsigned int) {
      u64::type _version;
      u32::type _eversion, _mversion, _checksum;
      ar & boost::serialization::make_nvp("version" , _version  )
	&  boost::serialization::make_nvp("eversion", _eversion )
	&  boost::serialization::make_nvp("mversion", _mversion );
      RandomEngine<Algorithm, Mixer> t(std::vector<seed_type>(0));
      ar & boost::serialization::make_nvp("seed"    , t._seed   )
	&  boost::serialization::make_nvp("ptr"     , t._ptr    )
	&  boost::serialization::make_nvp("stride"  , t._stride );
      if (t._ptr != UNINIT)
	ar & boost::serialization::make_nvp("rounds", t._rounds )
	  &  boost::serialization::make_nvp("state" , t._state  );
      ar & boost::serialization::make_nvp("checksum", _checksum );
      if (t.Check(_version, _eversion, _mversion) != _checksum)
	throw std::out_of_range("RandomEngine: Checksum failure");
      _seed.reserve(t._seed.size());
      *this = t;
    }
    /**
     * Glue the boost save and load functionality together -- a bit of boost
     * magic.
     **********************************************************************/
    template<class Archive>
    void serialize(Archive &ar, const unsigned int file_version)
    { boost::serialization::split_member(ar, *this, file_version); }
#endif

  };

  typedef RandomEngine<MT19937  <Random_u32>, MixerSFMT> MRandomGenerator32;
  typedef RandomEngine<MT19937  <Random_u64>, MixerSFMT> MRandomGenerator64;
  typedef RandomEngine<SFMT19937<Random_u32>, MixerSFMT> SRandomGenerator32;
  typedef RandomEngine<SFMT19937<Random_u64>, MixerSFMT> SRandomGenerator64;

} // namespace RandomLib

#endif	// RANDOMENGINE_HPP
