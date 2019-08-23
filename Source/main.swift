//
//  LeanHeaders
//  A cmdln tool to lint for unnecessary imports.
//
//  Created by Joshua Brach on 02/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//


// MARK: Known Limitations

/*
 - Does not account for legitimate transitive imports, e.g.:
     - a.h uses c and b and imports b.h which uses c and imports c.h
     - tool will report a.h is missing import of c.h, even tho it's fine without.
 */


// MARK: Dependancies

import Foundation


// MARK: - Global Options

/// Contains the global settings as parsed from command-line arguments.
struct GlobalOptions {

    /// Shared value.
    static fileprivate(set) var options = GlobalOptions()

    /// Whether to add unique codes.
    fileprivate(set) var filterableMessages : Bool = false

    /// Whether it is safe to recognize the short pragma.
    fileprivate(set) var useShortPragma : Bool = true

    /// How to report all missing import directive issues.
    fileprivate(set) var missingImportIssues : XCBIssueReporter.Severity = .error
    /// How to report all missing forward declaration issues.
    fileprivate(set) var missingForwardIssue : XCBIssueReporter.Severity = .error
    /// How to report all redundant import directive issues.
    fileprivate(set) var redundantImportIssues : XCBIssueReporter.Severity = .error
    /// How to report all redundant forward declaration issues.
    fileprivate(set) var redundantForwardIssue : XCBIssueReporter.Severity = .error
    /// How to report use of an include directive in place of an import directive.
    fileprivate(set) var includeDirectiveIssue : XCBIssueReporter.Severity = .warning
    /// How to report an unintentional root class declaration.
    fileprivate(set) var rootClassIssue : XCBIssueReporter.Severity = .error
    /// How to report an unintentional root protocol declaration.
    fileprivate(set) var rootProtoIssue : XCBIssueReporter.Severity = .error
    /// How to report an enumeration declaration via the enum keyword instead of the NS_(ENUM|OPTIONS) macros.
    fileprivate(set) var plainEnumIssue : XCBIssueReporter.Severity = .warning
    /// How to report an enumeration declaration without a typedef.
    fileprivate(set) var typedefEnumIssue : XCBIssueReporter.Severity = .ignored
    /// How to report an enumeration declaration without a missing or conflicting name.
    fileprivate(set) var enumNameIssues : XCBIssueReporter.Severity = .error
    /// How to report a structure declaration without a typedef.
    fileprivate(set) var typedefStructIssue : XCBIssueReporter.Severity = .ignored
    /// How to report a structure declaration without a missing or conflicting name.
    fileprivate(set) var structNameIssues : XCBIssueReporter.Severity = .error
    /// How to report issues in parsing.
    fileprivate(set) var metaIssues : XCBIssueReporter.Severity = .warning

    fileprivate mutating func setAll(_ severity: XCBIssueReporter.Severity) {
        missingImportIssues = severity
        missingForwardIssue = severity
        redundantImportIssues = severity
        redundantForwardIssue = severity
        includeDirectiveIssue = severity
        rootClassIssue = severity
        rootProtoIssue = severity
        plainEnumIssue = severity
        typedefEnumIssue = severity
        enumNameIssues = severity
        typedefStructIssue = severity
        structNameIssues = severity
        metaIssues = severity
    }
}


// MARK: Usage

fileprivate let version = "LeanHeaders version 1.1.1 (GitHub) © J.Brach 2017, 2019"

fileprivate let usage = """
    /path/to/LeanHeaders info | ( [options] [issueSeverities] /path/to/codebase/root )
        where info is any one of:
            -?-?h(elp)?
                ↳ Prints this usage and exists.
            --version
                ↳ Prints version and exists.
        options are any of:
            --filterable
                ↳ Adds a code to the end of each issue message which is unique to that type of message.
                    Xcode has many great search & filter functionality, but the Issue Navigator is not one of them:
                    it can only search 'any of these terms' not 'all of …' and not even '… in this order', so many
                    of the issue messages are degenerate.
                    (Does not affect 'cannot parse' issues.)
                ↳ Default is to not do this.
            --uniquePragma
                ↳ Recognizes 'ca.brach.LeanHeaders' rather than 'LeanHeaders' in pragma directives,
                    in case the clang project or some other tool decides to recognize 'LeanHeaders' pragmas.
                ↳ Default is to just recognize 'LeanHeaders'.
        issueSeverities take the form:
            --issueName ( e(rror)? | w(arn(ing)?)? | n(ote)? | (x|i(gnore)?) )
        and are any of:
            --missingImport
                ↳ How to report a needed import directive.
                ↳ Default = \(GlobalOptions.options.missingImportIssues)
            --missingForward
                ↳ How to report a needed forward declaration.
                ↳ Default = \(GlobalOptions.options.missingForwardIssue)
            --redundantImport
                ↳ How to report an un-needed import directive.
                ↳ Default = \(GlobalOptions.options.redundantImportIssues)
            --redundantForward
                ↳ How to report an un-needed forward declaration.
                ↳ Default = \(GlobalOptions.options.redundantForwardIssue)
            --includeDirective
                ↳ How to report use of an include directive in place of an import directive.
                ↳ Default = \(GlobalOptions.options.includeDirectiveIssue)
            --rootClass
                ↳ How to report an unintentional root class declaration.
                ↳ Default = \(GlobalOptions.options.rootClassIssue)
            --rootProtocol
                ↳ How to report an unintentional root protocol declaration.
                ↳ Default = \(GlobalOptions.options.rootProtoIssue)
            --plainEnum
                ↳ How to report an enumeration declaration via the enum keyword instead of the NS_(ENUM|OPTIONS) macros.
                ↳ Default = \(GlobalOptions.options.plainEnumIssue)
            --typedefEnum
                ↳ How to report an enumeration declaration without a typedef.
                ↳ Default = \(GlobalOptions.options.typedefEnumIssue)
            --enumName
                ↳ How to report issues regarding enumeration declaration naming (e.g. anonymous or mismatched with typedef).
                ↳ Default = \(GlobalOptions.options.enumNameIssues)
            --typedefStruct
                ↳ How to report a structure declaration without a typedef.
                ↳ Default = \(GlobalOptions.options.typedefStructIssue)
            --structName
                ↳ How to report issues regarding structure declaration naming (e.g. anonymous or mismatched with typedef).
                ↳ Default = \(GlobalOptions.options.structNameIssues)
            --parsing
                ↳ How to report meta-issues regarding LeanHeader's ability to parse the codebase.
                ↳ Default = \(GlobalOptions.options.structNameIssues)
            --all
                ↳ Quickly set all optional severities, override with subsequent options.
        /path/to/codebase/root
            ↳ The path to the codebase which is to have its imports cleaned.
"""


// MARK: - Main Execution

fileprivate func main() -> Int32 {

    // MARK: CmdLn Args

    func severity(fromCmdLnArg text: String) -> XCBIssueReporter.Severity? {
        switch text {
            case "e", "error":            return .error
            case "w", "warn", "warning":  return .warning
            case "n", "note":             return .note
            case "x", "i", "ignore":      return .ignored
            default:                      return nil
        }
    }

    var argNum = 1
    let argMax = CommandLine.arguments.count
    while argNum < argMax {
        switch CommandLine.arguments[argNum] {
            case "h", "-h", "--h", "help", "-help", "--help":
                print(usage)
                return 0
            case "-v", "--version":
                print(version)
                return 0
            case "--missingImport":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.missingImportIssues = severity
                }
            case "--missingForward":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.missingForwardIssue = severity
                }
            case "--redundantImport":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.redundantImportIssues = severity
                }
            case "--redundantForward":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.redundantForwardIssue = severity
                }
            case "--includeDirective":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.includeDirectiveIssue = severity
                }
            case "--rootClass":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.rootClassIssue = severity
                }
            case "--rootProtocol":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.rootProtoIssue = severity
                }
            case "--plainEnum":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.plainEnumIssue = severity
                }
            case "--typedefEnum":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.typedefEnumIssue = severity
                }
            case "--enumName":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.enumNameIssues = severity
                }
            case "--typedefStruct":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.typedefStructIssue = severity
                }
            case "--structName":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.structNameIssues = severity
                }
            case "--parsing":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.metaIssues = severity
                }
            case "--all":
                argNum += 1
                if argNum < argMax, let severity = severity(fromCmdLnArg: CommandLine.arguments[argNum]) {
                    GlobalOptions.options.setAll(severity)
                }
            case "--filterable":
                GlobalOptions.options.filterableMessages = true
            case "--uniquePragma":
                GlobalOptions.options.useShortPragma = false
            default:
                break
        }
        argNum += 1
    }


    // MARK: Run

    let xcodeBuildIssueReporter = XCBIssueReporter()

    if let path = CommandLine.arguments.last, let codebase = CodeBase(rootDirectoryPath: path, issueReporter: xcodeBuildIssueReporter) {

        codebase.checkIssues()
        XCBIssueReporter.wait()
        return Int32(xcodeBuildIssueReporter.reportedErrorCount)

    } else {

        return -1

    }

}


// MARK: Exit

exit(main())


// EOF
