//
//  StructureDefinitionHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 06/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Structure Definitions from headers.
class StructureDefinitionHeaderParser : HeaderParser {
    
    private static let idPattern = CommonPatterns.identifierPattern
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: StructureDefinitionHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile structure definition parser.")
            return nil
        }
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C structure definition.
        # Not all possible combinations of optional components can be matched with valid Objective-C code.
        (?:                                         # Non-capturing optional group: (null | typedef)
            (?<isTypedef>typedef) \\s++             # Named capture will be NotFound if typedef was not used.
        )?                                          # End non-capturing optional group: (null | typedef)
        struct                                      # Keyword for structure definition.
        (?:                                         # Non-capturing optional group: (null | plain name)
            \\s++ (?<plainname>\(idPattern))        # Named capture group for the name of the defined struct, optional if it is defined with typedef.
        )?                                          # End non-capturing optional group: (null | plain name)
        \\s*+ \\{                                   # Opening fields delimiter.
            ### TODO: Fields ###
            [^ \\} ]*+  # WIP: doesn't capture types of fields, which can be custum e.g. enum | structs.
        \\} \\s*+                                   # Closing fields delimiter.
        (?:                                         # Non-capturing optional group: (null | typedef name)
            (?<typename>\(idPattern)) \\s*+         # Named capture group for the name of the defined enum, if it is defined with typedef.
        )?                                          # End non-capturing optional group: (null | typedef name)
        ;                                           # Finalizing semicolon.
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var declarations   : [TypeDeclaration] = []
        //var references     : [TypeReference]   = []
        
        engine.enumerateMatches(in: file.sourceText as String, range: wholeRange) { (result, flags, _) in
            
            guard let result = result else {
                // just reporting progress…
                return
            }
            
            let definitionRange = result.range
            let definitionSource = file.sourceText.substring(with: definitionRange)
            let definitionLocation = file.location(ofRange: definitionRange)
            
            let isTypedefRange : NSRange
            let plainNameRange : NSRange
            let typeNameRange : NSRange
            if #available(macOS 10.13, *) {
                isTypedefRange = result.range(withName: "isTypedef")
                plainNameRange = result.range(withName: "plainname")
                typeNameRange = result.range(withName: "typename")
            } else {
                isTypedefRange = result.range(at: 1)
                plainNameRange = result.range(at: 2)
                typeNameRange = result.range(at: 3)
            }
            
            if isTypedefRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.typedefStructIssue,
                                          withMessage: "Unintentional implicit-type structure definition; insert 'typedef ' to silence this issue.",
                                          filterableCode: "missing-struct-typedef")
                
                if plainNameRange.location == NSNotFound {
                    parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                              ofSeverity: GlobalOptions.options.structNameIssues,
                                              withMessage: "Unintentional anonymous structure definition; add a name to silence this issue.",
                                              filterableCode: "missing-struct-name")
                } else {
                    let location = file.location(ofRange: plainNameRange)
                    declarations.append(
                        TypeDeclaration(location: location,
                                        rawLine: definitionSource,
                                        metatype: .structure,
                                        identifier: file.sourceText.substring(with: plainNameRange))
                    )
                }
                
            } else if isTypedefRange.location != NSNotFound {
                
                if typeNameRange.location == NSNotFound {
                    parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                              ofSeverity: GlobalOptions.options.structNameIssues,
                                              withMessage: "Typedef structure definition missing name argument; add the second name to silence this issue.",
                                              filterableCode: "missing-struct-typename")
                } else if plainNameRange.location != NSNotFound && file.sourceText.substring(with: plainNameRange) != file.sourceText.substring(with: typeNameRange) {
                    let location = file.location(ofRange: plainNameRange)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                              ofSeverity: GlobalOptions.options.structNameIssues,
                                              withMessage: "Unintentional conflicting structre definition name; change the names to silence this issue.",
                                              filterableCode: "conflicting-struct-name")
                } else {
                    let location = file.location(ofRange: typeNameRange)
                    declarations.append(
                        TypeDeclaration(location: location,
                                        rawLine: definitionSource,
                                        metatype: .structure,
                                        identifier: file.sourceText.substring(with: typeNameRange))
                    )
                }
                
            }
            
        } // end enumerate matches
        
        return (declarations, [], [])
    }
    
}

// EOF
