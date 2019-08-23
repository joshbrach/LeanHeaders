//
//  EnumerationDefinitionHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 05/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Enumeration Definitions from headers.
class EnumerationDefinitionHeaderParser : HeaderParser {
    
    private static let idPattern = CommonPatterns.identifierPattern
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: EnumerationDefinitionHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile enumeration definition parser.")
            return nil
        }
    }
    
    // TODO: There are more enum macros!?  NS_TYPED_[EXTENSIBLE_]ENUM  NS_[EXTENSIBLE_]STRING_ENUM
    //       NS_ENUM_AVAILABLE[_MAC|_IOS](...) NS_ENUM_DEPRECATED[_MAC|_IOS](...)
    private static let pattern = """
        # This pattern matches an Objective-C enumeration definition.
        # Not all possible combinations of optional components can be matched with valid Objective-C code.
        (?:                                         # Non-capturing optional group: (null | typedef)
            (?<isTypedef>typedef) \\s++             # Named capture will be NotFound if typedef was not used.
        )?                                          # End non-capturing optional group: (null | typedef)
        (?: enum                                    # Non-capturing alternation group: (keyword | macro)
            (?: \\s*+                               # Non-capturing optional group: (null | plain name)
                (?<plainname>\(idPattern))          # Named capture group for the name of the defined enum, if it is defined without macro or typedef.
            )?                                      # End non-capturing optional group: (null | plain name)
            (?: \\s*+ : \\s*+ \(idPattern) )?       # Non-capturing optional group: (null | explicit type)
        |                                           # Alternation: (keyword | macro)
            (?<macro> NS_                           # Named capture group for the name of the macro, or NotFound if a macro was not used.
                (?: (?:ERROR_)? ENUM | OPTIONS)     # Foundation provides NS_ ENUM, OPTIONS, & ERROR_ENUM
            )                                       # End named capture group: <macro>
            \\s*+ \\( \\s*+ \(idPattern) \\s*+ ,    # Pre-existing numeric type, assumed to be a Foundation type and thus ignored.
            \\s*+ (?<macroname>\(idPattern))        # Named capture group for the name of the defined enum, if it is defined with a macro.
            \\s*+ \\)                               # Closing delimeter for arguments of function-like macro.
        ) \\s*+                                     # End alternation group: (keyword | macro)
        \\{ \\s*+                                   # Opening cases delimiter.
            [^}]*+                                  # Cases, values, bitflags, comments, & documentation.
        \\} \\s*+                                   # Closing cases delimiter.
        (?: (?<typename>\(idPattern)) \\s*+ )?      # Named capture group for the name of the defined enum, if it is defined with typedef.
        ;                                           # Finalizing semicolon.
        """
    
    func parseTypes(inFile file: SourceFile) -> ([TypeDeclaration], [TypeAvailablity], [TypeReference]) {
        let wholeRange = NSRange(location: 0, length: file.sourceLength)
        
        var declarations   : [TypeDeclaration] = []
        
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
            let macroRange : NSRange
            let macroNameRange : NSRange
            let typeNameRange : NSRange
            if #available(macOS 10.13, *) {
                isTypedefRange = result.range(withName: "isTypedef")
                plainNameRange = result.range(withName: "plainname")
                macroRange = result.range(withName: "macro")
                macroNameRange = result.range(withName: "macroname")
                typeNameRange = result.range(withName: "typename")
            } else {
                isTypedefRange = result.range(at: 1)
                plainNameRange = result.range(at: 2)
                macroRange = result.range(at: 3)
                macroNameRange = result.range(at: 4)
                typeNameRange = result.range(at: 5)
            }
            
            if isTypedefRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.typedefEnumIssue,
                                          withMessage: "Unintentional implicit-type enumeration definition; insert 'typedef ' to silence this issue.",
                                          filterableCode: "missing-enum-typedef")
            }
            
            // macro
            
            if macroRange.location == NSNotFound {
                parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                          ofSeverity: GlobalOptions.options.plainEnumIssue,
                                          withMessage: "Unintentional implicit-size enumeration definition; use 'NS_(ENUM|OPTIONS)' to silence this issue.",
                                          filterableCode: "missing-enum-macro")
            } else if macroNameRange.location == NSNotFound {
                let location = file.location(ofRange: macroRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.enumNameIssues,
                                          withMessage: "Macro enumeration definition missing name argument; add the second argument to silence this issue.",
                                          filterableCode: "missing-enum-macroname")
            } else if typeNameRange.location != NSNotFound && file.sourceText.substring(with: macroNameRange) != file.sourceText.substring(with: typeNameRange) {
                let location = file.location(ofRange: typeNameRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.enumNameIssues,
                                          withMessage: "Unintentional conflicting enumeration definition name; remove the non-macro argument name to silence this issue.",
                                          filterableCode: "conflicting-enum-name")
            } else {
                let location = file.location(ofRange: macroNameRange)
                declarations.append(
                    TypeDeclaration(location: location,
                                    rawLine: definitionSource,
                                    metatype: .enumeration,
                                    identifier: file.sourceText.substring(with: macroNameRange))
                )
            }
            
            if macroNameRange.location != NSNotFound && typeNameRange.location != NSNotFound &&
                file.sourceText.substring(with: macroNameRange) == file.sourceText.substring(with: typeNameRange) {
                let location = file.location(ofRange: typeNameRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.enumNameIssues,
                                          withMessage: "Unintentional redundant enumeration definition name; remove the non-macro argument name to silence this issue.",
                                          filterableCode: "redundant-enum-name")
            }
            
            // keyword
            
            if isTypedefRange.location != NSNotFound && macroRange.location == NSNotFound {
                
                if typeNameRange.location == NSNotFound {
                    parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                              ofSeverity: GlobalOptions.options.enumNameIssues,
                                              withMessage: "Typedef enumeration definition missing name argument; add the second name to silence this issue.",
                                              filterableCode: "missing-enum-typename")
                } else if plainNameRange.location != NSNotFound && file.sourceText.substring(with: plainNameRange) != file.sourceText.substring(with: typeNameRange) {
                    let location = file.location(ofRange: plainNameRange)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                              ofSeverity: GlobalOptions.options.enumNameIssues,
                                              withMessage: "Unintentional deviation of enumeration definition name; change the names to silence this issue.",
                                              filterableCode: "conflicting-enum-typename")
                    // this program will *not* match C compound types (e.g. 'enum Identifier', 'struct Identifier')
                    // since convention dictates that they are never used in Objective-C, replaced with typedef names.
                } else {
                    let location = file.location(ofRange: typeNameRange)
                    declarations.append(
                        TypeDeclaration(location: location,
                                        rawLine: definitionSource,
                                        metatype: .enumeration,
                                        identifier: file.sourceText.substring(with: typeNameRange))
                    )
                }
                
            } else if isTypedefRange.location == NSNotFound && macroRange.location == NSNotFound {
                
                if plainNameRange.location == NSNotFound {
                    parent.xcbLog.reportIssue(atSourceCodeLocation: definitionLocation,
                                              ofSeverity: GlobalOptions.options.enumNameIssues,
                                              withMessage: "Unintentional anonymous enumeration definition; add a name to silence this issue.",
                                              filterableCode: "missing-enum-name")
                } else {
                    let location = file.location(ofRange: plainNameRange)
                    declarations.append(
                        TypeDeclaration(location: location,
                                        rawLine: definitionSource,
                                        metatype: .enumeration,
                                        identifier: file.sourceText.substring(with: plainNameRange))
                    )
                }
                
            }
            
        } // end enumerate matches
        
        return (declarations, [], [])
    }
    
}

// EOF
