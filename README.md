# LeanHeaders

 A command-line tool to slim down Objective-C Header files.

LeanHeaders is mostly focussed on reducing the number of unnecessary imports in a codebase.  One thing you'll notice is how few imports are needed!  Most references to a type only need a forward declaration.  Too many imports or a convoluted import-tree can significantly slow down build times.  These convoluted import-trees can sometimes feel like a sticky cobweb that's impossible to unravel — that's where LeanHeaders comes in.  LeanHeaders will analyze  your codebase and tell you exactly what imports are needed in which headers.

LeanHeaders is not called LeanImports because it also includes a few other checks for optimal, best-practice Objective-C Header files, like use of `NS_` macros for enumerations and unintentional root protocol or class declarations.

LeanHeaders outputs its results in the format Xcode uses to pick-up on build issues!  You can run LeanHeaders manually from the command line, but if you run it from a 'Run Script' Build Phase then Xcode will display in the UI the warnings and errors emitted (with the pretty colour-coded banners).  Unfortunately I've asked Apple Engineers at the WWDC Labs and they say there isn't any intention to support emitting custom FixIts from Build Phases.

## Usage

LeanHeaders recognizes most case-permutations and abbreviations of the words `help`  and `version`.

LeanHeaders allows you to control the severity of most issues it reports via command-line arguments.  The possible severities are `error`, `warning`, `note`, and `ignored`.

In order to be more useful in the Xcode Issue Navigator, most issues have a unique 'code' which can be added to the end of the issue message, making filtering easy. 
Xcode has many great search & filter functionality, but the Issue Navigator is not one of them: it can only search 'any of these terms' not 'all of …' and not even '… in this order', so many of the issue messages are degenerate without these unique codes.

| Description | Argument | Codes | 
| --- | --- | --- |
| A needed import directive. | `--missingImport` | `need-import-for-inheritance`, `need-import-for-typedef`, `need-import-not-forward` |
| A needed forward declaration. | `--missingForward` | `need-forward-class`, `need-forward-protocol` |
| An un-needed import directive. | `--redundantImport` | `not-needed-import`, `need-forward-not-import` |
| An un-needed forward declaration. | `--redundantForward` | `not-needed-forward` |
| Use of an include directive in place of an import directive. | `--includeDirective` | `need-import-not-include` |
| An unintentional root class declaration. | `--rootClass` | `root-class` |
| An unintentional root protocol declaration. | `--rootProtocol` | `root-protocol` |
| An arbitrary type-definition which is not uniquely named. | | `typedef-not-unique` |
| An enumeration declaration via the enum keyword instead of the `NS_(ENUM|OPTIONS)` macros. | `--plainEnum` | `missing-enum-macro` |
| An enumeration declaration without a typedef. | `--typedefEnum` | `missing-enum-typedef` |
| Issues regarding enumeration declaration naming (e.g. anonymous or mismatched with typedef). | `--enumName` | `missing-enum-macroname`,  `conflicting-enum-name`, `redundant-enum-name`, `missing-enum-typename`, `conflicting-enum-typename`, `missing-enum-name` |
| A structure declaration without a typedef. | `--typedefStruct` | `missing-struct-typedef` |
| Issues regarding structure declaration naming (e.g. anonymous or mismatched with typedef). | `--structName` | `missing-struct-name`, `missing-struct-typename`, `conflicting-struct-name` |
| Meta-issues regarding LeanHeader's ability to parse the codebase. | `--parsing` | |
| Quickly set all optional severities, override with subsequent options. | `--all` | _All of the above!_ |

If at first you start using LeanHeaders and you're bombarded with hundreds or thousands of errors: turn on the filterable codes and start with all issues ignored, then add and fix each issue argument one at a time.  Most issues you can fix at any time, but removing imports and forwards can cause transitive build failures.  The optimal strategy for not breaking your build in-between rounds is:
1) `--missingImport`, to break transitive header dependencies.
1) `--missingForward`, to make redundant any remaining transitive header dependencies.
2) `--redundantForward`, which are completely not needed.
3) `--redundantImport`, which are both the completely not needed and the not strictly needed imports.

## History

LeanHeaders was mostly written over the span of a few months in late 2017 by Joshua Brach.  It was published as Open-Source Software via GitHub in 2019.
RegEx is not by any means the _best_ tool for the job performed by LeanHeaders, but this project was made both for the 'ends' of having a tool to slim down the Objective-C headers of the codebases in the author's professional life and for the 'means' of achieving a deep understanding of the regex implementation in Apple's Foundation framework at the time.
