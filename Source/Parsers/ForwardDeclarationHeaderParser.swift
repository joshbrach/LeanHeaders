//
//  ForwardDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Forward Declarations from headers.
class ForwardDeclarationHeaderParser : HeaderParser {
    
    private static let idsPattern = CommonPatterns.list(of: CommonPatterns.identifierPattern)
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ForwardDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile forward declaration parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C forward class | protocol declaration.
        @(?<metatype> class | protocol ) \\s++      # Named capture of the Objective-C keywords for forward declarations.
        (?<types>\(idsPattern)) \\s*+               # Named capture of the name of the declared types.
        ;                                           # Forward declarations are differentiated by a finalizing semicolon.
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var availabilities : [TypeAvailablity] = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let declarationRange = result.range
            let declarationSource = file.sourceText.substring(with: declarationRange)
            let declarationLocation = file.location(ofRange: declarationRange)
            
            let metatypeRange : NSRange
            let typesRange : NSRange
            if #available(macOS 10.13, *) {
                metatypeRange = result.range(withName: "metatype")
                typesRange = result.range(withName: "types")
            } else {
                metatypeRange = result.range(at: 1)
                typesRange = result.range(at: 2)
            }
            
            if metatypeRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from forward declaration match.")
            } else if let metatype = ForwardDeclaration.MetaType(rawValue: file.sourceText.substring(with: metatypeRange)) {
                
                if typesRange.location == NSNotFound {
                    parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                              ofSeverity: GlobalOptions.options.metaIssues,
                                              withMessage: "Missing non-optional component from forward declaration match.")
                } else {
                    let location = file.location(ofRange: typesRange)
                    for availability in file.sourceText.substring(with: typesRange).split(separator: ",") {
                        availabilities.append( .forward(
                            ForwardDeclaration(location: location,
                                               rawLine: declarationSource,
                                               metatype: metatype,
                                               identifier: availability.trimmingCharacters(in: .whitespacesAndNewlines))
                            ) )
                    }
                }
                
            } else {
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Cannot determine metatype of forward declaration match.")
            }
            
        } // end enumerate matches
        
        return ([], availabilities, [])
    }
    
}

// EOF
