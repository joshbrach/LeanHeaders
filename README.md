# LeanHeaders

 A command-line tool to slim down Objective-C Header files.

LeanHeaders is mostly focussed on reducing the number of unnecessary imports in a codebase.  Too many imports or a convoluted import-tree can significantly slow down build times.  These convoluted import-trees can sometimes feel like a sticky cobweb that's impossible to unravel — that's where LeanHeaders comes in.  LeanHeaders will analyze  your codebase and tell you exactly what imports are needed in which headers.

LeanHeaders is not called LeanImports because it also includes a few other checks for optimal, best-practice Objective-C Header files, like use of `NS_` macros for enumerations and unintentional root protocol or class declarations.

## History

LeanHeaders was mostly written over the span of a few months in late 2017 by Joshua Brach.  It was published as Open-Source Software via GitHub in 2019.
RegEx is not by any means the _best_ tool for the job performed by LeanHeaders, but this project was made both for the 'ends' of having a tool to slim down the Objective-C headers of the codebases in the author's professional life and for the 'means' of achieving a deep understanding of the regex implementation in Apple's Foundation framework at the time.
