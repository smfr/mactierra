###
# operating-system dependent stuff
###
#.UNIVERSE=att

###
# target directories
#
#    NOTE: if you change INCDIR and LIBDIR then dont forget to change
#          their corresponding strings at the top of options.3!
###
LOCAL=/usr/local
INCDIR=${LOCAL}/include
LIBDIR=${LOCAL}/lib
MAN3DIR=/usr/man/local_man/man3

###
# compilation options
###
CC=g++
CPLC=g++
INCDIRS = -I.
LIBDIRS = -L.
# OPT=-O
OPT=-g
TEST_DEFS=
USR_DEFS=
DEFINES=${OS_DEFS} ${USR_DEFS} ${TEST_DEFS}
OPTIONS=

CFLAGS=${INCDIRS} ${LIBDIRS} ${DEFINES} ${OPT} ${OPTIONS}
CPLFLAGS=${OPT} ${INCDIRS} ${LIBDIRS} ${DEFINES} ${OPTIONS}

###
# C++ Rules
###
.SUFFIXES : .C
.C.o : 
	${CPLC} ${CPLFLAGS} -c $<

###
# Source files
###
LIBHDRS=options.h
LIBSRCS=options.C
LIBTESTS=testopts.C

SRCS=${LIBHDRS} ${LIBSRCS} ${LIBTESTS}
OBJS=options.o
LIBRARY=liboptions.a
DOCS=options.3


###
# target dependencies
###
all: library test

install: library
	rm -f ${INCDIR}/options.h ${LIBDIR}/${LIBRARY}
	cp options.h ${INCDIR}/options.h
	cp ${LIBRARY} ${LIBDIR}/${LIBRARY}

installman:
	rm -f ${MAN3DIR}/options.3
	cp options.3 ${MAN3DIR}/options.3

library: ${LIBRARY}

${LIBRARY}: ${OBJS}
	ar r $@ ${OBJS}
	ranlib $@

test: testopts

testopts: testopts.o ${LIBRARY}
	${CPLC} ${LIBDIRS} -o $@ testopts.o ${LIBRARY}

###
# maintenance dependencies
###
clean:
	rm -f *.o core .exrc

clobber: clean
	rm -f tags testopts ${LIBRARY}
	
shar:
	shar README MANIFEST ${SRCS} ${DOCS} Makefile >SHAR

###
# object dependencies
###
options.o: options.h

testopts.o: options.h

