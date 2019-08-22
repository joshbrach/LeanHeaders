//
//  ImportDirectiveHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Import Directives from headers.
class ImportDirectiveHeaderParser : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: ImportDirectiveHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile import directive parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C pre-processor import directive.
        # It specifically does /not/ match framework imports.
        \\# (?<directive> import | include ) \\s*+  # Objective-C pre-processor import directive.
        "                                           # Opening local file delimiter.
        (?<imports> (?: \\\\" | [^"] )* )           # Named capture of the imported file name, allowing escaped quotes.
        "                                           # Closing local file delimiter.
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var availabilities : [TypeAvailablity] = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let directiveRange = result.range
            let directiveSource = file.sourceText.substring(with: directiveRange)
            let directiveLocation = file.location(ofRange: directiveRange)
            
            let typeRange : NSRange
            let importsFileRange : NSRange
            if #available(macOS 10.13, *) {
                typeRange = result.range(withName: "directive")
                importsFileRange = result.range(withName: "imports")
            } else {
                typeRange = result.range(at: 1)
                importsFileRange = result.range(at: 2)
            }
            
            if typeRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing non-optional component from compiler directive match.")
            } else if file.sourceText.substring(with: typeRange) == "include" {
                let location = file.location(ofRange: directiveRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.includeDirectiveIssue,
                                          withMessage: "Unintentional use of the include compiler directive; switch to import to silence this warning.",
                                          filterableCode: "need-import-not-include")
            }
            
            if importsFileRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: directiveLocation,
                                          withMessage: "Missing non-optional component from import directive match.")
            } else {
                let location = file.location(ofRange: importsFileRange)
                availabilities.append( .`import`(
                    Import(location: location,
                           rawLine: directiveSource,
                           importsFile: file.sourceText.substring(with: importsFileRange))
                    ) )
            }
            
        } // end enumerate matches
        
        return ([], availabilities, [])
    }
    
}

// EOF
