//
//  ClassDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Class Declarations from headers.
class ClassDeclarationHeaderParser : HeaderParser {
    
    private static let idPattern = CommonPatterns.identifierPattern
    private static let idsListPattern = CommonPatterns.list(of: CommonPatterns.identifierPattern)
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ClassDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile class declaration parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C class declaration.
        # It specifically does /not/ match an Objective-C /forward/ class declaration.
        # It allows for root classes, in that case the baseclass capture group will be NotFound.
        @interface \\s++                            # Objective-C keyword for class, extension, & category declarations.
        (?<class>\(idPattern)) \\s*+                # Named capture of the name of the declared class.
                    ### TODO: Generic Args ###
        (?: : \\s*+                                 # Non-capturing optional group: (null | inheritance).
            (?<baseclass>\(idPattern)) \\s*+        # Named capture of the base-class identifier.
        )?                                          # End optional group: (null | inheritance)
        (?: < \\s*+                                 # Non-capturing optional group: (null | conformance).
            (?<conformances>\(idsListPattern))\\s*+ # Named capture of the conformance list.
            > \\s*+                                 # Closing conformance-list delimiter.
        )?                                          # End optional group: (null | conformance)
        (?! [                                       # The next non-whitespace character must not be:
            : <                                     #   one used to start an optional portion of this pattern, nor
            \\(                                     #   one used to indicate an extension | category declaration.
        ])
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var declarations   : [TypeDeclaration] = []
        var references     : [TypeReference]   = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let declarationRange = result.range
            let declarationSource = file.sourceText.substring(with: declarationRange)
            
            let classRange : NSRange
            let baseclassRange : NSRange
            let conformancesRange : NSRange
            if #available(macOS 10.13, *) {
                classRange = result.range(withName: "class")
                baseclassRange = result.range(withName: "baseclass")
                conformancesRange = result.range(withName: "conformances")
            } else {
                classRange = result.range(at: 1)
                baseclassRange = result.range(at: 2)
                conformancesRange = result.range(at: 3)
            }
            
            if classRange.location == NSNotFound {
                let declarationLocation = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from class declaration match.")
            } else {
                let location = file.location(ofRange: classRange)
                declarations.append(
                    TypeDeclaration(location: location,
                                    rawLine: declarationSource,
                                    metatype: .`class`,
                                    identifier: file.sourceText.substring(with: classRange))
                )
            }
            
            if baseclassRange.location == NSNotFound {
                let location = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                   ofSeverity: GlobalOptions.options.rootClassIssue,
                                   withMessage: "Unintentional root class declaration; insert ' : NSObject ' to silence this issue.",
                                   filterableCode: "root-class")
            } else {
                let location = file.location(ofRange: baseclassRange)
                references.append( .implementing(
                    ImplementingReference(location: location,
                                          rawLine: declarationSource,
                                          metatype: .inheritance,
                                          identifier: file.sourceText.substring(with: baseclassRange))
                    ) )
            }
            
            if conformancesRange.location != NSNotFound {
                let location = file.location(ofRange: conformancesRange)
                for conformance in file.sourceText.substring(with: conformancesRange).split(separator: ",") {
                    references.append( .implementing(
                        ImplementingReference(location: location,
                                              rawLine: declarationSource,
                                              metatype: .conformance,
                                              identifier: conformance.trimmingCharacters(in: .whitespacesAndNewlines))
                        ) )
                }
            }
            
        } // end enumerate matches
        
        return (declarations, [], references)
    }
    
}

// EOF
