# $Id: Makefile 6429 2008-04-28 00:14:02Z ckarney $

TARGET = RandomExample RandomPermutation shuffle

all: $(TARGET)

CPPFLAGS = -I..
CXXFLAGS = -g -Wall -O3 -funroll-loops -finline-functions -fomit-frame-pointer
CC = g++ -g

ifdef DEFAULT_GENERATOR
  CPPFLAGS += -DDEFAULT_GENERATOR=$(DEFAULT_GENERATOR)
endif

HAVE_SSE2 = \
	$(shell grep "flags\b.*\bsse2\b" /proc/cpuinfo 2> /dev/null | \
	tail -1 | wc -l | tr -d ' \t')

HAVE_ALTIVEC = \
	$(shell arch 2> /dev/null | grep ppc | tail -1 | wc -l | tr -d ' \t')

ifeq ($(HAVE_SSE2),1)
  CPPFLAGS += -DHAVE_SSE2
  CXXFLAGS += -msse2
endif

ifeq ($(HAVE_ALTIVEC),1)
  CPPFLAGS += -DHAVE_ALTIVEC
  CXXFLAGS += -faltivec -maltivec
endif

test:
	echo $(HAVE_ALTIVEC) $(CPPFLAGS) $(CXXFLAGS)

HAVE_BOOST_SERIALIZATION = \
	$(if $(wildcard /usr/lib*/libboost_serialization.*),1,0)

ifeq ($(HAVE_BOOST_SERIALIZATION),1)
  CPPFLAGS += -DHAVE_BOOST_SERIALIZATION=1
  LDLIBS = -lboost_serialization
endif

REQUIREDHEADERS = Random.hpp RandomCanonical.hpp RandomPower2.hpp \
	RandomEngine.hpp RandomAlgorithm.hpp RandomMixer.hpp RandomSeed.hpp \
	RandomType.hpp

OTHERHEADERS = NormalDistribution.hpp ExponentialDistribution.hpp \
	LeadingZeros.hpp ExponentialProb.hpp RandomSelect.hpp \
	ExactExponential.hpp ExactPower.hpp RandomNumber.hpp

Random.o: $(REQUIREDHEADERS)

RandomExample.o: $(REQUIREDHEADERS) NormalDistribution.hpp RandomSelect.hpp
RandomExample: Random.o

RandomPermutation.o: $(REQUIREDHEADERS)
RandomPermutation: Random.o

shuffle: shuffle.sh
	install $< $@

clean:
	rm -f *.o

doc: Doxyfile Random.doc \
	$(REQUIREDHEADERS) $(OTHERHEADERS) \
	Random.cpp RandomExample.cpp RandomPermutation.cpp \
	exphist.pdf exphist.png powerhist.pdf powerhist.png
	rm -rf html/*
	doxygen
	cp -p exphist.pdf exphist.png html/
	cp -p powerhist.pdf powerhist.png html/
	touch $@
