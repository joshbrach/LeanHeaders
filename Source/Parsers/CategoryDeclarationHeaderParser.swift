//
//  CategoryDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Category & Extension Declarations from headers.
class CategoryDeclarationHeaderParser : HeaderParser {
    
    private static let idPattern = CommonPatterns.identifierPattern
    private static let idsListPattern = CommonPatterns.list(of: CommonPatterns.identifierPattern)
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: CategoryDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile category declaration parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C category | extension declaration.
        @interface \\s++                            # Objective-C keyword for class, extension, & category declarations.
        (?<baseclass>\(idPattern)) \\s*+            # Named capture of the name of the extended class.
        \\( \\s*+                                   # Opening category | extension indicator delimiter.
            (?: \(idPattern) \\s*+ )?               # Non-capturing optional group: (category name | extension).
        \\) \\s*+                                   # Closing category | extension indicator delimiter.
        (?: < \\s*+                                 # Non-capturing optional group: (null | conformance).
            (?<conformances>\(idsListPattern))\\s*+ # Named capture of the conformance list.
            > \\s*+                                 # Closing conformance-list delimiter.
        )?                                          # End optional group: (null | conformance)
        (?! [                                       # The next non-whitespace character must not be:
            <                                       #   one used to start an optional portion of this pattern.
        ])
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var references     : [TypeReference]   = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let declarationRange = result.range
            let declarationSource = file.sourceText.substring(with: declarationRange)
            
            let baseclassRange : NSRange
            let conformancesRange : NSRange
            if #available(macOS 10.13, *) {
                baseclassRange = result.range(withName: "baseclass")
                conformancesRange = result.range(withName: "conformances")
            } else {
                baseclassRange = result.range(at: 1)
                conformancesRange = result.range(at: 2)
            }
            
            if baseclassRange.location == NSNotFound {
                let declarationLocation = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from class declaration match.")
            } else {
                let location = file.location(ofRange: baseclassRange)
                // Added as an inherritance, since I think the base has to be fully visible,
                // if this isn't the case then it needs to be added as a composition.
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
        
        return ([], [], references)
    }
    
}

// EOF
