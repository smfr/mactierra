This is a commandline version of the MacTierra engine. You can use it to run MacTierra soups in the background.

To use it, copy mactierra to your hard disk. Run the Terminal application, and use 'cd' to change directory to the directory containing mactierra.

Then run mactierra like this:
./mactierra

If you supply no arguments, it will print out a helpful message and quit:

usage: mactierra [-?|--?] [-H|--help] [-s|--soup-size <number>]
                 [-d|--duration <number>] [-r|--random-seed <number>]
                 [-c|--configuration-file <value>] [-f|--in-soup-file <value>]
                 [-o|--out-soup-file <value>] [-x|--xml-format <value>] 

Soup files are interchangable between the MacTierra application, and mactierra.

Configuration files can be created by the desktop MacTierra application. To create one, make a new soup with the settings you want to use. Then use Export Configuration in the File menu to save the configuration to an XML file. You can then use this file with the --configuration option with mactierra.
