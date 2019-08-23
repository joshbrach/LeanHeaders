//
//  CodeBase.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 02/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to represent a codebase.
class CodeBase {
    
    
    // MARK: Reference Constants
    
    private static let headerExtension = "h"
    
    
    // MARK: Stored Properties
    
    private let fileManager = FileManager.`default`
    
    private let xcbLog : XCBIssueReporter
    
    /// Path to the root directory of the codebase.
    let rootDirectory : URL
    
    
    // MARK: - Instance Lifecycle
    
    /// Initializes the object to represent the codebase rooted at the given directory.
    /// Returns nil if the given path is not an existing directory.
    convenience init?(rootDirectoryPath path: String, issueReporter: XCBIssueReporter = .init()) {
        let isDirectory = UnsafeMutablePointer<ObjCBool>.allocate(capacity: 1)
        defer { isDirectory.deallocate() }
        let exists = FileManager.`default`.fileExists(atPath: path, isDirectory: isDirectory)
        
        if exists && isDirectory.pointee.boolValue {
            self.init(rootDirectory: URL(fileURLWithPath: path, isDirectory: true), issueReporter: issueReporter)
        } else {
            issueReporter.reportIssue(withMessage: "Cannot initialize codebase without a root directory path.")
            return nil
        }
    }
    
    /// Initializes the object to represent the codebase rooted at the given directory.
    /// Returns nil if the given path is not an existing directory.
    init?(rootDirectory path: URL, issueReporter: XCBIssueReporter = .init()) {
        xcbLog = issueReporter
        rootDirectory = path
    }
    
    
    // MARK: - Lazily Computed Properties
    
    /// List of all header files within the root directory.
    lazy private(set) var headerFiles : [URL] = {
        do {
            return try fileManager.subpathsOfDirectory(atPath: rootDirectory.path).map {
                URL(fileURLWithPath: $0, relativeTo:rootDirectory)
            }.filter {
                $0.pathExtension == CodeBase.headerExtension
            }
        } catch let e {
            xcbLog.reportIssue(withMessage: "Cannot search root directory of codebase for header files!")
            return []
        }
    }()
    
    private var _typeDeclarations : [String : [TypeDeclaration]]!
    /// List of all declarations of Objective-C Types, by identifier.
    var typeDeclarations : [String : [TypeDeclaration]] {
        if _typeDeclarations == nil {
            initializeParsedLazyProperties()
        }
        return _typeDeclarations!
    }

    private var _typeAvailabilities : [URL : [AvailabilityWithUsage]]!
    /// List of all Objective-C Types which are availabile, along with whether they are actually useful, by the file in which they appear.
    fileprivate(set) var typeAvailabilities : [URL : [AvailabilityWithUsage]] {
        get {
            if _typeAvailabilities == nil {
                initializeParsedLazyProperties()
            }
            return _typeAvailabilities!
        }
        set(newValue) {
            _typeAvailabilities = newValue
        }
    }
    
    private var _typeReferences : [TypeReference]!
    /// List of all references to Objective-C Types.
    var typeReferences : [TypeReference] {
        if _typeReferences == nil {
            initializeParsedLazyProperties()
        }
        return _typeReferences!
    }
    
    
    // MARK: - Parser
    
    private func initializeParsedLazyProperties() {
        guard _typeDeclarations == nil || _typeAvailabilities == nil || _typeReferences == nil else {
            return
        }
        let parser = CodeBaseParser(issueReporter: xcbLog)

        timingStartTime = Date()
        let (declarations, availabilities, references) = parser.parseCodeBaseTypes(codebase: self)
        reportTiming(forTask: "Parsing")

        _typeDeclarations = declarations.keyed { $0.identifier }
        _typeDeclarations = _typeDeclarations.mapValues { declarationsForIdentifier in
            declarationsForIdentifier.map { declaration in
                if  case .arbitrary(sameAs: let sameAsIdentifier) = declaration.metatype,
                    let sameAsDeclaration = _typeDeclarations[sameAsIdentifier]
                {
                    if sameAsDeclaration.count != 1 {
                        xcbLog.reportIssue(atSourceCodeLocation: declaration.location,
                                           ofSeverity: .error,
                                           withMessage: "Unable to resolve arbitrary type definition with \(sameAsDeclaration.count) candidates.",
                                           filterableCode: "typedef-not-unique")
                    } else {
                        return TypeDeclaration(location: declaration.location,
                                               rawLine: declaration.rawLine,
                                               metatype: sameAsDeclaration.first!.metatype,
                                               identifier: declaration.identifier)
                    }
                }
                return declaration
            }
        }
        _typeAvailabilities = availabilities.filter {
            switch $0 {
                case .`import`(let i):
                    return headerFiles.contains { $0.relativeString.hasSuffix(i.importsFile) }
                case .forward(let f):
                    return _typeDeclarations[f.identifier]?.contains { f.metatype ≈ $0.metatype } ?? false
            }
        }.map { (wrapper: $0, whichIs: .notReferenced) }.keyed { $0.wrapper.sourceCodeRepresentation.location.file }
        _typeReferences = references

        // fast-forward analysis start time to now, since analysis can't have gotten started until after this is done
        timingStartTime = Date()
    }

    /// The time since the last timing was reported or since it was explicitly reset; for timing / profiling / testing purposes.
    fileprivate var timingStartTime : Date!

}


extension CodeBase {
    
    // MARK: - Analysis

    /// Reports the timing since the timingStartTime; for timing / profiling / testing purposes.
    private func reportTiming(forTask task: String) {
        let end = Date()
        xcbLog.reportIssue(ofSeverity: .note, withMessage: "\(task) took \(end.timeIntervalSince(timingStartTime))s.", filterableCode: "timing")
        timingStartTime = end
    }
    
    /// An enumeration to encode the ternary state of an availability match.
    enum AvailabilityUsageLevel : UInt {
        /// The availability is not used by any reference.
        case notReferenced = 0
        /// The availability is used by at least one reference, but a lesser availability would satisfy them.
        case used = 1
        /// The availability is fully required by at least one reference.
        case needed = 2
        
        static func >(lhs: AvailabilityUsageLevel, rhs: AvailabilityUsageLevel) -> Bool {
            return lhs.rawValue > rhs.rawValue
        }
        static func <(lhs: AvailabilityUsageLevel, rhs: AvailabilityUsageLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    typealias AvailabilityWithUsage = (wrapper: TypeAvailablity, whichIs: AvailabilityUsageLevel)
    
    /// Enumerates each availability until one matches, as determined by invoking the given closures;
    /// marks the matching availability as referenced and returns true.
    func enumerateAvailabilities(inFile referenceFile: URL,
                                 importMatches: (Import)->AvailabilityUsageLevel,
                                 forwardMatches: (ForwardDeclaration)->Bool) -> Bool {
        var satisfied = false
        let relevantAvailabilities = typeAvailabilities[referenceFile] ?? []
        for (index, (wrapper: wrapper, whichIs: usage)) in relevantAvailabilities.enumerated() {
            switch wrapper {

                case .`import`(let fullAvailability):
                    switch (importMatches(fullAvailability), usage) {
                        case (.used, .notReferenced):
                            typeAvailabilities[referenceFile]![index].whichIs = .used
                            fallthrough
                        case (.used, _):
                            satisfied = true
                            continue
                        case (.needed, _):
                            typeAvailabilities[referenceFile]![index].whichIs = .needed
                            return true
                        default: // i.e. (.notReferenced, _)
                            continue
                    }
                    // the availability makes available the needed declaration,
                    //  the reference of which either
                    //   requires full availability…
                    //  or
                    //   doesn't itself strictly require full availability…

                case .forward(let shallowAvailability):
                    if forwardMatches(shallowAvailability) {
                        // the availability makes available the needed declaration…
                        typeAvailabilities[referenceFile]![index].whichIs = .needed // all matching forward declarations are needed.
                        return true
                    }

            }
        }
        return satisfied
    }
    
    /// Returns true iff the given declaration is fully available for the given reference.
    func isFull(declaration: TypeDeclaration, availableForReference reference: TypeReference) -> Bool {
        let reference_location = reference.sourceCodeRepresentation.location
        
        guard declaration.location.file != reference_location.file || declaration.location.line > reference_location.line else {
            // trivially available in the same file!
            return true
        }
        
        return enumerateAvailabilities(inFile: reference_location.file, importMatches: { (fullAvailability) -> AvailabilityUsageLevel in
            
            return fullAvailability.importsFile == declaration.location.file.lastPathComponent ? .needed : .notReferenced
            
        }, forwardMatches: { (shallowAvailability) -> Bool in
            
            // still check for match, for more helpful issue message…
            if case .implementing(let implementingReference) = reference,
                shallowAvailability.identifier == implementingReference.identifier && implementingReference.metatype ≈ shallowAvailability.metatype {
                xcbLog.reportIssue(atSourceCodeLocation: shallowAvailability.location,
                                   ofSeverity: GlobalOptions.options.missingImportIssues,
                                   withMessage: """
                                                Found forward declaration when full declaration is needed \
                                                for reference on line \(implementingReference.location.line)
                                                """,
                                   filterableCode: "need-import-not-forward")
            }
            return false
            
        })
    }
    
    /// Returns true iff the given declaration is shallowly available for the given reference.
    func isForward(declaration: TypeDeclaration, availableForReference reference: TypeReference) -> Bool {
        let reference_location = reference.sourceCodeRepresentation.location
        
        guard declaration.location.file != reference_location.file || declaration.location.line > reference_location.line else {
            // trivially available in the same file!
            return true
        }
        
        return enumerateAvailabilities(inFile: reference_location.file, importMatches: { (fullAvailability) -> AvailabilityUsageLevel in
            
            // still check for match, for more helpful issue messages later…
            return fullAvailability.importsFile == declaration.location.file.lastPathComponent ? .used : .notReferenced
            
        }, forwardMatches: { (shallowAvailability) -> Bool in
            
            if case .composition(let compositionReference) = reference,
                shallowAvailability.identifier == compositionReference.identifier && shallowAvailability.metatype ≈ declaration.metatype {
                return true
            } else {
                return false
            }
            
        })
    }
    
    
    // MARK: - Issues
    
    /// Analyses the codebase, reporting issues as they are encountered.
    func checkIssues() {
        timingStartTime = Date()
        
        // MARK: Check References
        
        for referenceWrapper in typeReferences {
            switch referenceWrapper {
                
                case .implementing( let reference ):
                    // Definitely Needs Full Type Declaration

                    if let declaration = typeDeclarations[reference.identifier]?.first(where: { reference.metatype ≈ $0.metatype }) {

                        if !isFull(declaration: declaration, availableForReference: referenceWrapper) {
                            // no import makes available the needed declaration…
                            xcbLog.reportIssue(atSourceCodeLocation: reference.location,
                                               ofSeverity: GlobalOptions.options.missingImportIssues,
                                               withMessage: """
                                                    Missing import of "\(declaration.location.file.lastPathComponent)"
                                                    for \(declaration.metatype) \(reference.identifier) \
                                                    used in \(reference.metatype.rawValue) declaration.
                                                    """,
                                               filterableCode: "need-import-for-inheritance")
                        }

                    }
                
                    // If the reference has no matching declaration within the codebase,
                    // then it is a system or third-party symbol — which is out of scope
                    // for this tool; therefore we simply ignore the reference at this point.
                
                case .composition( let reference ):
                    // Probably Needs Shallow Type Declaration
                    
                    if let declaration = typeDeclarations[reference.identifier]?.first {

                        switch declaration.metatype {

                            case .enumeration, .structure, .closure:
                                // actually needs full import!

                                if !isFull(declaration: declaration, availableForReference: referenceWrapper) {
                                    // no import makes available the needed declaration…
                                    xcbLog.reportIssue(atSourceCodeLocation: reference.location,
                                                       ofSeverity: GlobalOptions.options.missingImportIssues,
                                                       withMessage: """
                                                                    Missing import of "\(declaration.location.file.lastPathComponent)"
                                                                    for \(declaration.metatype) \(reference.identifier) \
                                                                    used as \(reference.metatype.rawValue) type.
                                                                    """,
                                                       filterableCode: "need-import-for-typedef")
                                }

                            case .arbitrary(let sameas):
                                // this was supposed to be taken care of earlier!

                                xcbLog.reportIssue(atSourceCodeLocation: declaration.location,
                                                   ofSeverity: GlobalOptions.options.metaIssues,
                                                   withMessage: """
                                                                Could not find declaration of \(sameas) \
                                                                to deduce metatype of \(declaration.identifier).
                                                                """)

                            case .`class`, .`protocol`:
                                // needs forward…

                                if !isForward(declaration: declaration, availableForReference: referenceWrapper) {
                                    // no forward makes available the needed declaration…
                                    xcbLog.reportIssue(atSourceCodeLocation: reference.location,
                                                       ofSeverity: GlobalOptions.options.missingForwardIssue,
                                                       withMessage: """
                                                                    Missing forward declaration of \(declaration.metatype) \(reference.identifier) \
                                                                    used as \(reference.metatype.rawValue) type.
                                                                    """,
                                                       filterableCode: """
                                                                        need-forward-\
                                                                        \(declaration.metatype == .`class` ? "class" : "protocol")
                                                                        """)
                                }

                        } // end switch on declaration metatype

                    }
                
                    // If the reference has no matching declaration within the codebase,
                    // then it is a system or third-party symbol — which is out of scope
                    // for this tool; therefore we simply ignore the reference at this point.
                
            } // end switch on reference wrapper
        }

        reportTiming(forTask: "Checking References")

        // MARK: Check Availabilities
        
        typeAvailabilities.flatMap { $0.value }.filter { $0.whichIs < .needed }.forEach {
            let location : SourceCodeLocation
            let severity : XCBIssueReporter.Severity
            let message : String
            let code : String
            switch $0 {

                case ( .`import`(let fullAvailability),   .notReferenced ):
                    location = fullAvailability.location
                    severity = GlobalOptions.options.redundantImportIssues
                    message = "Unnecessary import of file \(fullAvailability.importsFile)."
                    code = "not-needed-import"

                case ( .forward(let shallowAvailability), .notReferenced ):
                    location = shallowAvailability.location
                    severity = GlobalOptions.options.redundantForwardIssue
                    message = """
                                Unnecessary forward declaration of \
                                \(shallowAvailability.metatype.rawValue) \(shallowAvailability.identifier).
                                """
                    code = "not-needed-forward"

                case ( .`import`(let fullAvailability),   .used ):
                    location = fullAvailability.location
                    severity = GlobalOptions.options.redundantImportIssues
                    message = """
                                Unnecessary import of file \(fullAvailability.importsFile) \
                                when only forward declarations are needed.
                                """
                    code = "need-forward-not-import"

                default:
                    // (.used, .forward) is not possible, and (.needed, _) is excluded by containing conditional.
                    assert(false, "How did we get ourselves in this situation, then?")
                    return  // leave scope in release builds, don't count as issue

            }
            xcbLog.reportIssue(atSourceCodeLocation: location, ofSeverity: severity, withMessage: message, filterableCode: code)
        }

        reportTiming(forTask: "Checking Availabilities")
    }
    
}


// EOF
