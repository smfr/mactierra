// #include <stdlib.h>
#include <iostream.h>
#include <string.h>
#include <ctype.h>

#include <options.h>

extern "C" {
   void exit(int);
   long  atol(const char *);
}

static const char * const optv[] = {
   "?|?",
   "H|help",
   "f?flags",
   "g+groups <name>",
   "c:count <int>",
   "s?str <string>",
   "x",
   " |hello",
   "-h|hidden",
   NULL
} ;

// I use the following routine when I see the -f option.
// It changes the opt_ctrls used by getopts() to take effect
// for the next option parsed. The -f option is used to test
// the Options::XXXXX flags and should be first on the command-line.
//
void
setflags(const char * flags_str, Options & opts) {
   if (flags_str && *flags_str) {
      unsigned  flags = opts.ctrls();
      for (const char * p = flags_str; *p; p++) {
         switch (*p) {
            case '+' :
               flags |= Options::PLUS;
               break;
            case 'A' : case 'a' :
               flags |= Options::ANYCASE;
               break;
            case 'L' : case 'l' :
               flags |= Options::LONG_ONLY;
               break;
            case 'S' : case 's' :
               flags |= Options::SHORT_ONLY;
               break;
            case 'Q' : case 'q' :
               flags |= Options::QUIET;
               break;
            case 'N' : case 'n' :
               flags |= Options::NOGUESSING;
               break;
            case 'P' : case 'p' :
               flags |= Options::PARSE_POS;
               break;
            default  :
               break;
         }
      }
      opts.ctrls(flags);
   }
}

main(int argc, char * argv[])
{
   int  optchar;
   char * optarg;
   char * str = "default_string";
   int  count = 0, xflag = 0, hello = 0, hidden = 0;
   int  errors = 0;
   int  ngroups = 0;
   int  npos = 0;

   Options  opts(*argv, optv);
   OptArgvIter  iter(--argc, ++argv);

   while( optchar = opts(iter, optarg) ) {
      switch (optchar) {
      case '?' :
      case 'H' :
         opts.usage(cout, "files ...");
         ::exit(0);
         break;

      case 'f' : setflags(optarg, opts); break;

      case 'g' : ++ngroups; break;

      case 'h' : ++hidden; break;

      case 's' : str = optarg; break;

      case 'x' : ++xflag; break;

      case ' ' : ++hello; break;

      case 'c' :
         if (optarg == NULL) {
            ++errors;
         } else {
            count = (int) ::atol(optarg);
         }
         break;

      case Options::POSITIONAL :
            // Push positional arguments to the front
         argv[npos++] = optarg;
         break;

      case Options::BADCHAR :  // bad option ("-%c", *optarg)
      case Options::BADKWD  :  // bad long-option ("--%s", optarg)
      case Options::AMBIGUOUS  :  // ambiguous long-option ("--%s", optarg)
      default :
         ++errors; break;
      } /*switch*/
   }

   int index = iter.index();

   if (errors || ((index == argc) && (npos == 0))) {
      if (! errors) {
         cerr << opts.name() << ": no filenames given." << endl ;
      }
      opts.usage(cerr, "files ...");
      ::exit(1);
   }

   cout << "xflag=" << ((xflag) ? "ON"  : "OFF") << '\n'
        << "hello=" << ((hello) ? "YES" : "NO") << '\n'
        << "count=" << count << '\n'
        << "hidden=" << ((hidden) ? "ON"  : "OFF") << '\n'
        << "string=\"" << ((str) ? str : "No value given!") << "\"" << '\n'
        << "ngroups=" << ngroups << endl ;

   if ((npos > 0) || (index < argc)) {
      cout << "files=" ;
      int  first = (npos > 0) ? 0 : index;
      int  limit = (npos > 0) ? npos : argc;
      for (int i = first ; i < limit ; ++i) {
         cout << "\"" << argv[i] << "\" " ;
      }
      cout << endl ;
   }

   return  0;
}
