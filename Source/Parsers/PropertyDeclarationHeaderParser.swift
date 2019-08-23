//
//  PropertyDeclarationHeaderParser.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 10/09/2017.
//  Copyright © 2017 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


/// A class to parse Objective-C Property Declarations from headers.
class PropertyDeclarationHeaderParser : HeaderParser {
    
    private let parent : CodeBaseParser
    
    private let engine : NSRegularExpression
    
    private let typeDescriptorParser : TypeDescriptorParser
    
    private let blockDescriptorParser : BlockDescriptorParser
    
    required init?(parent: CodeBaseParser) {
        self.parent = parent
        do {
            engine = try NSRegularExpression(pattern: PropertyDeclarationHeaderParser.pattern,
                                             options: .allowCommentsAndWhitespace)
        } catch _ {
            parent.xcbLog.reportIssue(withMessage: "Cannot compile property declaration parser.")
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
    
    private static let pattern = """
        # This pattern matches an Objective-C property declaration.
        @property                                   # Objective-C keyword for property declarations.
        (?: \\s | \\s*+ \\( \\s*+                   # Non-capturing alternation group for (space | attributes)
            \(CommonPatterns.list(of: CommonPatterns.propertyAttributesPattern))
        \\s*+ \\) )                                 # End alternation group: (space | attributes)
        (?: \\s*+ IB(?: Outlet|Inspectable) \\s )?  # Optional InterfaceBuilder support.
        \\s*+
        (?:                                         # Non-capturing alternation group for (type & identifier | block syntax)
            (?<type>                                # Named capture of the Type Descriptor.
                \(TypeDescriptorParser.pattern(nullabilityIncludedOptionally: nil))
            ) \\s*+                                 # End capture group: type
            \(CommonPatterns.identifierPattern)     # Name of the declared property.
        |                                           # Alternation: (type & identifier | block syntax)
            (?<block>\(BlockDescriptorParser.pattern()))
        )                                           # End alternation group: (type & identifier | block syntax)
        (?:                                         # Non-capturing repitition group for attributes.
             \\s*+ \(CommonPatterns.postfixPropertyAttributeMacrosPattern)
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
                let declarationLocation = file.location(ofRange: declarationRange)
                parent.xcbLog.reportIssue(atSourceCodeLocation: declarationLocation,
                                          ofSeverity: GlobalOptions.options.metaIssues,
                                          withMessage: "Missing non-optional component from property declaration match.")
                return
            }
            
            if typeRange.location != NSNotFound {
                let typeDescriptor = typeDescriptorParser.parseIdentifiers(inRange: typeRange, ofSourceFile: file)
                guard let _ = typeDescriptor else {
                    let location = file.location(ofRange: typeRange)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                              ofSeverity: GlobalOptions.options.metaIssues,
                                              withMessage: "Cannot parse type descriptor from property declaration match.")
                    return
                }
                typeDescriptor!.flatEnumerateAllIdentifiers {
                    references.append( .composition(
                        CompositionReference(location: $0.location,
                                             rawLine: declarationSource,
                                             metatype: .property,
                                             identifier: $0.identifier)
                        ) )
                }
            }
            
            if blockRange.location != NSNotFound {
                let blockDescriptor = blockDescriptorParser.parseIdentifiers(inRange: blockRange, ofSourceFile: file)
                guard let _ = blockDescriptor else {
                    let location = file.location(ofRange: blockRange)
                    parent.xcbLog.reportIssue(atSourceCodeLocation: location,
                                              ofSeverity: GlobalOptions.options.metaIssues,
                                              withMessage: "Cannot parse block descriptor from property declaration match.")
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
            
        } // end enumerate matches
        
        return ([], [], references)
    }
    
}

// EOF

