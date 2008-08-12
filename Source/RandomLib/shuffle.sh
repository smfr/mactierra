#! /bin/sh
# $Id: shuffle.sh 6423 2008-01-23 02:11:38Z ckarney $
#
#     Usage: shuffle [-h] [-s seed] [-v] [file]
#
# shuffles the lines of file (or standard input).  Requires that
# "RandomPermutation n" produces a random permutation of the integers
# [0,n).  -s seed sets the seed.  -v prints the seed used on standard
# error.  -h prints help.
#
# seed is typically a list of comma-separated numbers, e.g., -s "";
# -s 1234; -s 1,2,3,4; etc.  You can obtain the same shuffling of a file
# by using the form of the seed, printed to standard error with -v, as
# the argument to -s, e.g., -s "[671916,1201036551,9299,562196172,2008]"
#
# Written by by Charles Karney <charles@karney.com> and licensed under
# the GPL.  For more information, see http://charles.karney.info/random/

usage="$0 [-h] [-s seed] [-v] [file]"

VERBOSE=
SEEDGIVEN=
while getopts hs:v c; do
    case $c in
	h ) echo "usage: $usage" 1>&2; exit 0;;
	# SEED can contain spaces or be the empty string 
	s ) SEEDGIVEN=y; SEED="$OPTARG";;
	v ) VERBOSE=-v;;
	* ) echo "usage: $usage" 1>&2; exit 1;;
    esac
done
shift `expr $OPTIND - 1`

case $# in
    0 ) FILE=;;
    1 ) FILE=$1;;
    * ) echo usage: $0 [file] 1>&2; exit 1;;
esac

TEMP=
trap 'trap "" 0; test "$TEMP" && rm -rf "$TEMP"; exit 1' 1 2 3 9 15
trap            'test "$TEMP" && rm -rf "$TEMP"'            0
TEMP=`mktemp -d ${TMPDIR:-/tmp}/shufXXXXXXXX`

if [ $? -ne 0 ]; then
    echo "$0: Can't create temp directory, exiting..." 1>&2
    exit 1
fi

if test -z "$FILE"; then
    FILE=$TEMP/in
    cat > "$FILE"
fi

l=`wc -l < "$FILE"`
# If file doesn't end with a newline, need to increment line count
b="`tail -1c "$FILE"`"
test "$b" = "`echo`" -o "$b" = "" || l=`expr $l + 1`

if test "$SEEDGIVEN"; then
    RandomPermutation -s "$SEED" $VERBOSE $l
else
    RandomPermutation $VERBOSE $l
fi > $TEMP/shuf || exit 1
paste $TEMP/shuf "$FILE" | sort | cut -f2-

exit
