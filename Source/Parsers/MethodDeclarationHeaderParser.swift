//
//  MethodDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 10/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Method Declarations from headers.
class MethodDeclarationHeaderParser : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    private let parametersParserEngine : NSRegularExpression
    
    private let typeDescriptorParser : TypeDescriptorParser
    
    private let blockDescriptorParser : BlockDescriptorParser
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: MethodDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile method declaration parser.")
            return nil
        }
        do {
            let capturingPattern = MethodDeclarationHeaderParser.parameterPattern(capture: true)
            parametersParserEngine = try NSRegularExpression(pattern: capturingPattern,
                                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile method parameter parser.")
            return nil
        }
        if let parser = TypeDescriptorParser(parent: parent) {
            typeDescriptorParser = parser
        } else {
            return nil
        }
        if let parser = BlockDescriptorParser(parent: parent) {
            blockDescriptorParser = parser
        } else {
            return nil
        }
    }
    
    private static func parameterPattern(capture: Bool = false) -> String {
        return """
            \(CommonPatterns.identifierPattern) # Parameter label.
            \\s*+ : \\s*+ \\( \\s*+             # Opening parameter type delimiter.
            (?:                                 # Non-capturing alternation group: (type | block)
                \(capture ? "(?<type>" : "")    # Conditionally included named capture.
                    \(TypeDescriptorParser.pattern())  # Passed type descriptor.
                \(capture ? ")" : "")           # End conditionally included named capture.
            |                                   # Alternation: (type | block)
                \(capture ? "(?<block>" : "")   # Conditionally included named capture.
                    \(BlockDescriptorParser.pattern())  # Passed type descriptor.
                \(capture ? ")" : "")           # End conditionally included named capture.
            )                                   # End alternation group: (type | block)
            \\s*+ \\) \\s*+                     # Closing parameter type delimiter.
            \(CommonPatterns.identifierPattern) # Parameter identifier.
            \n
            """  // Embedded patterns must not end with a commented line.
    }
    
    private static let pattern = """
        # This pattern matches an Objective-C method declaration.
        # It does /not/ match methods with omitted labels.
        # It does /not/ match methods with omitted types (implicitly id).
        (?: \\+ | - ) \\s*+                         # Indicator for type or instance method.
        \\( \\s*+ (?<returntype>                    # Named capture group for the return type of the method.
                ### TODO: context-specific qualifiers ###
                ### e.g.: oneway | in | out | inout | bycopy | byref ###
            \(TypeDescriptorParser.pattern())       # Returned type descriptor.
         ) \\s*+ \\) \\s*+                          # End capture group: returntype
        (?:                                         # Non-capturing alternation group: (single label | parameters)
            \(CommonPatterns.identifierPattern)     # Method name.
        |                                           # Alternation: (single label | parameters)
            (?<parameters>                          # Named capture group for labeled parameters list.
                \(parameterPattern())               # First parameter.
                (?: \\s++ \(parameterPattern()) )*+ # Parameters are space delimited.
            )                                       # End capture group: <parameters>
            (?: \\s*+ , \\s*+ \\.\\.\\. )?          # Optional variadic arguments dentotation.
        )                                           # End alternation group: (single label | parameters)
        (?:                                         # Non-capturing repitition group for attributes.
            \\s*+ \(CommonPatterns.postfixMethodAttributeMacrosPattern)
        |
            \\s*+ \(CommonPatterns.attributePattern)
        )*                                          # End repitition group.
        \\s*+ ;                                     # Finalizing semicolon.
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
            
            let returnRange : NSRange
            let parametersRange : NSRange
            if #available(macOS 10.13, *) {
                returnRange = result.range(withName: "returntype")
                parametersRange = result.range(withName: "parameters")
            } else {
                returnRange = result.range(at: 1)
                parametersRange = result.range(at: 2)
            }
            
            if returnRange.location == NSNotFound {
                let declarationLocation = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          withMessage: "Missing non-optional component from method declaration match.")
            } else if let typeDescriptor = typeDescriptorParser.parseIdentifiers(inRange: returnRange, ofSourceFile: file) {
                typeDescriptor.flatEnumerateAllIdentifiers {
                    references.append( .composition(
                        CompositionReference(location: $0.location,
                                             rawLine: declarationSource,
                                             metatype: .method,
                                             identifier: $0.identifier)
                        ) )
                }
            }
            
            if parametersRange.location != NSNotFound {
                parametersParserEngine.enumerateMatches(in: file.sourceText as String, range: parametersRange) { (result, _, _) in
                    
                    guard let result = result else {
                        // just reporting progress…
                        return
                    }
                    
                    let typeRange : NSRange
                    let blockRange : NSRange
                    if #available(macOS 10.13, *) {
                        typeRange = result.range(withName: "type")
                        blockRange = result.range(withName: "block")
                    } else {
                        typeRange = result.range(at: 1)
                        blockRange = result.range(at: 2)
                    }
                    
                    guard typeRange.location != NSNotFound || blockRange.location != NSNotFound else {
                        let declarationLocation = file.location(ofRange: result.range)
                        parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                                  withMessage: "Missing non-optional component from method parameter match.")
                        return
                    }
                    
                    if typeRange.location != NSNotFound {
                        let typeDescriptor = typeDescriptorParser.parseIdentifiers(inRange: typeRange, ofSourceFile: file)
                        guard let _ = typeDescriptor else {
                            let location = file.location(ofRange: typeRange)
                            parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                                      withMessage: "Cannot parse type descriptor from method parameter match.")
                            return
                        }
                        typeDescriptor!.flatEnumerateAllIdentifiers {
                            references.append( .composition(
                                CompositionReference(location: $0.location,
                                                     rawLine: declarationSource,
                                                     metatype: .method,
                                                     identifier: $0.identifier)
                                ) )
                        }
                    }
                    
                    if blockRange.location != NSNotFound {
                        let blockDescriptor = blockDescriptorParser.parseIdentifiers(inRange: blockRange, ofSourceFile: file)
                        guard let _ = blockDescriptor else {
                            let location = file.location(ofRange: blockRange)
                            parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                                      withMessage: "Cannot parse block descriptor from method parameter match.")
                            return
                            
                        }
                        blockDescriptor!.flatEnumerateAllDescriptors {
                            references.append( .composition(
                                CompositionReference(location: $0.location,
                                                     rawLine: declarationSource,
                                                     metatype: .closure,
                                                     identifier: $0.identifier)
                                ) )
                        }
                    }
                    
                } // end nested enumerate matches
            }
            
        } // end enumerate matches
        
        return ([], [], references)
    }
    
}

// EOF

