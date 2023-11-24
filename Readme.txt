About
-----

This is a Macintosh implementation of Tom Ray's Tierra: <http://life.ou.edu/tierra/>

It's an independent implementation by Simon Fraser <smfr at smfr dot org>, who write a Mac OS Classic version many moons ago: <http://www.smfr.org/work/sfi/mactierra/>

This is a Mac OS X rewrite, with a platform-neutral engine, and a Cocoa front-end. It requires macOS 10.12 (Sierra) or later, and runs natively on Intel (x86_64) and Apple Silicon devices.

Please send bugs and feedback to Simon Fraser <smfr at smfr . org>


How to build
------------

Building requires macOS 10.12 (Sierra) and the matching version of Xcode.

Open MacTierra.xcodeproj, choose the MacTierra target, and build (Release or Debug, as you wish; Release will run much faster).

If you want to rebuild the Boost C++ libraries, see Docs/build-boost.sh


Tips & Tricks
-------------

Use Command-Option-N to make a new, empty soup with mutation turned off.


Genebank
--------

MacTierra creates a "genebank" file at ~/Library/Application Support/MacTierra/Genebank.sql, in which it stores successful genotypes. You can view the genebank via the Window->Genebank menu item. Genotypes can be dragged into an empty soup to run them.


Version History
---------------

0.8
    First release of Mac OS X version.
    
1.0
    Rebuilt on Mac OS X 10.6, with Boost 1.44.0
    Built 64-bit. Significantly faster than 0.8
    Mac OS X 10.5 or later is required to run.
    New soup format; soup files not compatible with 0.8.

1.1
    Rebuilt for macOS Sierra (10.12) as an Intel/ARM fat binary.
    Updated Boost to 1.83
    Removed dependency on OpenGL for soup display.

Known issues
------------

Saving soups in XML format crashes sometimes (bug in boost serialization).
Soups may not be compatible between 32- and 64-bit binaries.
