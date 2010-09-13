About
-----

This is a Macintosh implementation of Tom Ray's Tierra: <http://life.ou.edu/tierra/>

It's an independent implementation by Simon Fraser <smfr at smfr dot org>, who write a Mac OS Classic version many moons ago: <http://www.smfr.org/work/sfi/mactierra/>

This is a Mac OS X rewrite, with a platform-neutral engine, and a Cocoa front-end. It requires Mac OS X 10.5.4 (Leopard) or later.

Please send bugs and feedback to Simon Fraser <smfr at smfr . org>


How to build
------------

Building requires Leopard (10.5.4) and Xcode 3.1 or later.

First, open Source/userinterface/cocoa/3rd party/GraphX/Source/Graph Suite.xcodeproj. Get Info on the Graph Suite item at the top of the Files hierarchy, and change the Build Products location to MacTierra/build (same directory as used by MacTierra.xcodeproj). Build Release and Debug (either target).

Now open MacTierra.xcodeproj, choose the MacTierra target, and build (Release or Debug, as you wish; Release will run much faster).


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


Known issues
------------

Saving soups in XML format crashes sometimes (bug in boost serialization).
Soups may not be compatible between 32- and 64-bit binaries.
