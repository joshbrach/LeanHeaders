//
//  BlockDescriptorParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 14/11/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A structure to encapsulate the relevant identifiers
/// in constituent components of an Objective-C Block Descriptor.
/// - note: The primary identifier can be nil, as it can be nullability,
///         information depending on context.
struct BlockDescriptor {
    /// The primary identifier of the Block.
    let identifier :  ArbitraryIdentifier?
    /// The descriptor of the Block return Type.
    let returnType : TypeDescriptor
    /// The descriptors of the Types of the Block parameters.
    let parameters : [TypeDescriptor]?
    
    func flatEnumerateAllDescriptors(_ process: (ArbitraryIdentifier)->Void) {
        returnType.flatEnumerateAllIdentifiers(process)
        parameters?.forEach { $0.flatEnumerateAllIdentifiers(process) }
    }
}


/// A class to parse Identifiers of Objective-C Block Descriptors.
class BlockDescriptorParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    private let parametersParserEngine : NSRegularExpression
    
    private let typeDescriptorParser : TypeDescriptorParser
    
    /// Initializes the parser with the given parent parser.
    /// Can fail to compile parsing grammar at runtime
    init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: "^\(BlockDescriptorParser.pattern(capture: true))$",
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile block descriptor parser.")
            return nil
        }
        do {
            parametersParserEngine = try NSRegularExpression(pattern: BlockDescriptorParser.parameterPattern(capture: true),
                                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile block descriptor parameters parser.")
            return nil
        }
        if let parser = TypeDescriptorParser(parent: parent) {
            typeDescriptorParser = parser
        } else {
            return nil
        }
    }
    
    /// Generates a pattern for an arbitrary Objective-C block, without embedded capture groups.
    /// - returns: An ICU Pattern which will match a Block, with no leading nor trailing spaces.
    class func pattern() -> String {
        return pattern(capture: false)
    }

    /// Generates a pattern for an arbitrary Objective-C block parameter, with or without embedded capture groups.
    /// - parameters:
    ///    - capture: Idicates whether embedded capture groups should be enabled.
    /// - returns: An ICU Pattern which will match a Block parameter suitable for a block typedef or inline in a method declaration, with no leading nor trailing spaces.
    class func parameterPattern(capture: Bool = false) -> String {
        let typeInContext = TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil)
        let idPattern = CommonPatterns.identifierPattern
        return """
            \(capture ? "(?<type>" : "")            # Conditionally included named capture.
                \(typeInContext)                    # Parameter type.
            \(capture ? ")" : "")                   # End conditionally included named capture.
            (?: \\s*+ \(idPattern) )?               # Parameter identifier, which is optional for signatures!
            (?= \\s*+ [                             # The next non-whitespace character must be:
                , )                                 #   one used as a parameter delimiter
            ])
            """
    }
    
    /// Generates a pattern for an arbitrary Objective-C block, with or without embedded capture groups.
    /// - parameters:
    ///    - capture: Idicates whether embedded capture groups should be enabled.
    /// - returns: An ICU Pattern which will match a Block, with no leading nor trailing spaces.
    private class func pattern(capture: Bool) -> String {
        return """
            (?\(capture ? "<returnType>" : ":")         # Named capture group for the block return type.
                \(TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil))
            ) \\s*+                                     # End capture group: <returnType>
            \\( (?: \\s*+ NS_NOESCAPE)? \\s*+ \\^ \\s*+ # Opening block name delimiter.
            (?: (?:                                     # Non-capturing optional / alternation group: (nullability | name)
                \(CommonPatterns.prefixNullabilitySpecifierPattern)  # Context-specific nullability.
            |                                           # Alternation: (nullability | name)
                \(capture ? "(?<identifier>" : "")      # Named capture group for the name of the block.
                    \(CommonPatterns.identifierPattern) # Defined type name.
                \(capture ? ")" : "")                   # End capture group: <blockName>
            ) \\s*+ )?                                  # End alternation / optional group: (nullability | name)
            \\) \\s*+                                   # Closing block name delimiter.
            \\( \\s*+                                   # Opening block parameters delimiter.
            (?\(capture ? "<parameters>" : ":")         # Named capture group for the block parameter list.
                \(CommonPatterns.list(of: BlockDescriptorParser.parameterPattern()))
            \\s*+ )?                                    # End capture group: <blockParameters>
            \\)                                         # Closing block parameters delimiter.
            \n
            """  // Embedded patterns cannot end with a comment.
    }

    /// Parses Identifiers of Objective-C Type Descriptor components from text matching an arbitrary Objective-C block descriptor.
    /// - parameters:
    ///    - inRange: The range of a single match of a pattern generated by a BlockDescriptorParser.
    ///    - ofSourceFile: The file in which the match was found.
    /// - returns: The identifiers from constituent components of the type.
    /// - warning: Performs recursive RegEx matching, which may degrade overall performance.
    func parseIdentifiers(inRange wholeRange: NSRange, ofSourceFile file: SourceFile) -> BlockDescriptor! {
        guard let match = engine.firstMatch(in: file.sourceText as String, range: wholeRange) else {
            let matchlocation = file.location(ofRange: wholeRange)
            parent.xcbLog.reportIssue(atSourceCodeLocation: matchlocation,
                                      ofSeverity: GlobalOptions.options.metaIssues,
                                      withMessage: """
                                                    Cannot parse block descriptor from range
                                                    '\(file.sourceText.substring(with: wholeRange))'.
                                                    """)
            return nil
        }
        
        var identifier :  ArbitraryIdentifier?
        var returnType :  TypeDescriptor! = nil
        var parameters : [TypeDescriptor]? = nil
        
        let identifierRange : NSRange
        let returnTypeRange : NSRange
        let parametersRange : NSRange
        if #available(macOS 10.13, *) {
            returnTypeRange = match.range(withName: "returnType")
            identifierRange = match.range(withName: "identifier")
            parametersRange = match.range(withName: "parameters")
        } else {
            returnTypeRange = match.range(at: 1)
            identifierRange = match.range(at: 2)
            parametersRange = match.range(at: 3)
        }
        
        if identifierRange.location != NSNotFound {
            let location = file.location(ofRange: identifierRange)
            identifier = ( file.sourceText.substring(with: identifierRange), location )
        }
        
        if returnTypeRange.location == NSNotFound {
            let location = file.location(ofRange: match.range)
            parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                      ofSeverity: GlobalOptions.options.metaIssues,
                                      withMessage: "Missing non-optional component from block descriptor match.")
            return nil
        } else {
            let typeDescriptor = typeDescriptorParser.parseIdentifiers(inRange: returnTypeRange, ofSourceFile: file)
            guard let _ = typeDescriptor else {
                let location = file.location(ofRange: returnTypeRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Cannot parse return type from block descriptor match.")
                return nil
            }
            returnType = typeDescriptor!
        }

        // TODO: optional reporting of arbitrary parameters issue (i.e. `()` rather than `(void)`)
        if parametersRange.location != NSNotFound {
            parameters = []
            parametersParserEngine.enumerateMatches(in: file.sourceText as String, options: [.withTransparentBounds], range: parametersRange) { (result, _, _) in
                
                guard let result = result else {
                    // just reporting progress…
                    return
                }
                
                let typeRange : NSRange
                if #available(macOS 10.13, *) {
                    typeRange = result.range(withName: "type")
                } else {
                    typeRange = result.range(at: 1)
                }
                
                guard typeRange.location != NSNotFound else {
                    let parameterLocation = file.location(ofRange: result.range)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: parameterLocation,
                                              ofSeverity: GlobalOptions.options.metaIssues,
                                              withMessage: "Missing non-optional component from block parameter match.")
                    return
                }
                let typeDescriptors = typeDescriptorParser.safeParseIdentifiers(inRange: typeRange, ofSourceFile: file)
                if let typeDescriptors = typeDescriptors {
                    parameters?.append(contentsOf: typeDescriptors)
                }
                
            } // end nested enumerate matches
        }
        
        return BlockDescriptor(identifier: identifier, returnType: returnType, parameters: parameters)
    }
    
}
    
